-- TRUSTD database setup
-- Safe to run again in Supabase Dashboard → SQL Editor.
-- Public quiz links and leaderboard names/scores are visible to people with a quiz link.
-- Detailed answer choices are available only with the creator's private owner key.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.quiz_submissions (
  id bigint generated always as identity primary key,
  quiz_id text not null check (char_length(quiz_id) between 1 and 80),
  quiz_title text not null default '' check (char_length(quiz_title) <= 100),
  creator_name text not null default '' check (char_length(creator_name) <= 40),
  player_name text not null check (char_length(player_name) between 1 and 24),
  score integer not null check (score >= 0),
  total integer not null check (total between 1 and 20 and score <= total),
  answer_indices jsonb not null default '[]'::jsonb
    check (
      jsonb_typeof(answer_indices) = 'array'
      and jsonb_array_length(answer_indices) between 0 and 20
    ),
  created_at timestamptz not null default now()
);

alter table public.quiz_submissions
  add column if not exists answer_indices jsonb not null default '[]'::jsonb
  check (
    jsonb_typeof(answer_indices) = 'array'
    and jsonb_array_length(answer_indices) between 0 and 20
  );

create index if not exists quiz_submissions_leaderboard_idx
  on public.quiz_submissions (quiz_id, score desc, created_at asc);

alter table public.quiz_submissions enable row level security;

drop policy if exists "Anyone can submit TRUSTD quiz scores" on public.quiz_submissions;
create policy "Anyone can submit TRUSTD quiz scores"
  on public.quiz_submissions for insert to anon, authenticated
  with check (
    char_length(player_name) between 1 and 24
    and score >= 0
    and total between 1 and 20
    and score <= total
    and jsonb_typeof(answer_indices) = 'array'
    and jsonb_array_length(answer_indices) between 0 and 20
  );

drop policy if exists "Anyone can read TRUSTD leaderboard scores" on public.quiz_submissions;
create policy "Anyone can read TRUSTD leaderboard scores"
  on public.quiz_submissions for select to anon, authenticated
  using (true);

-- Public clients may read leaderboard fields, but not submitted answer choices.
revoke select on public.quiz_submissions from anon, authenticated;
grant select (quiz_id, player_name, score, total, created_at)
  on public.quiz_submissions to anon, authenticated;
grant insert on public.quiz_submissions to anon, authenticated;


create table if not exists public.shared_quizzes (
  id text primary key check (id ~ '^[a-f0-9]{18}$'),
  owner_key_hash text check (
    owner_key_hash is null or owner_key_hash ~ '^[a-f0-9]{64}$'
  ),
  quiz_data jsonb not null check (
    jsonb_typeof(quiz_data) = 'object'
    and octet_length(quiz_data::text) <= 24000
    and case
      when jsonb_typeof(quiz_data->'questions') = 'array'
      then jsonb_array_length(quiz_data->'questions') between 3 and 20
      else false
    end
  ),
  created_at timestamptz not null default now()
);

-- Adds the owner-key column to projects that already have short-link storage.
alter table public.shared_quizzes
  add column if not exists owner_key_hash text;

alter table public.shared_quizzes enable row level security;

drop policy if exists "Anyone can create TRUSTD quiz links" on public.shared_quizzes;
create policy "Anyone can create TRUSTD quiz links"
  on public.shared_quizzes for insert to anon, authenticated
  with check (
    id ~ '^[a-f0-9]{18}$'
    and owner_key_hash ~ '^[a-f0-9]{64}$'
    and jsonb_typeof(quiz_data) = 'object'
    and octet_length(quiz_data::text) <= 24000
    and case
      when jsonb_typeof(quiz_data->'questions') = 'array'
      then jsonb_array_length(quiz_data->'questions') between 3 and 20
      else false
    end
  );

drop policy if exists "Anyone can read TRUSTD quiz links" on public.shared_quizzes;
create policy "Anyone can read TRUSTD quiz links"
  on public.shared_quizzes for select to anon, authenticated
  using (true);

-- The owner key hash is deliberately excluded from public column reads.
revoke select on public.shared_quizzes from anon, authenticated;
grant select (id, quiz_data, created_at) on public.shared_quizzes to anon, authenticated;
grant insert on public.shared_quizzes to anon, authenticated;


-- Checks the creator's high-entropy key before returning answer details.
create or replace function public.trustd_get_quiz_attempts(
  p_quiz_id text,
  p_owner_key text
)
returns table (
  player_name text,
  score integer,
  total integer,
  answer_indices jsonb,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  stored_hash text;
begin
  if p_quiz_id is null or p_owner_key is null or char_length(p_owner_key) < 32 then
    raise exception 'Not authorized to view quiz responses';
  end if;

  select q.owner_key_hash
    into stored_hash
    from public.shared_quizzes as q
   where q.id = p_quiz_id;

  if stored_hash is null
     or stored_hash <> encode(
       extensions.digest(convert_to(p_owner_key, 'UTF8'), 'sha256'),
       'hex'
     ) then
    raise exception 'Not authorized to view quiz responses';
  end if;

  return query
    select s.player_name, s.score, s.total, s.answer_indices, s.created_at
      from public.quiz_submissions as s
     where s.quiz_id = p_quiz_id
     order by s.created_at desc
     limit 100;
end;
$function$;

revoke all on function public.trustd_get_quiz_attempts(text, text) from public;
grant execute on function public.trustd_get_quiz_attempts(text, text)
  to anon, authenticated;
