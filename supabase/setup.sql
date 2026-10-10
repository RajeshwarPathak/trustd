-- TRUSTD leaderboard setup
-- Run this in Supabase Dashboard → SQL Editor.

create table if not exists public.quiz_submissions (
  id bigint generated always as identity primary key,
  quiz_id text not null check (char_length(quiz_id) between 1 and 80),
  quiz_title text not null default '' check (char_length(quiz_title) <= 100),
  creator_name text not null default '' check (char_length(creator_name) <= 40),
  player_name text not null check (char_length(player_name) between 1 and 24),
  score integer not null check (score >= 0),
  total integer not null check (total between 1 and 20 and score <= total),
  created_at timestamptz not null default now()
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
  );

drop policy if exists "Anyone can read TRUSTD leaderboard scores" on public.quiz_submissions;
create policy "Anyone can read TRUSTD leaderboard scores"
  on public.quiz_submissions for select to anon, authenticated
  using (true);

grant select, insert on public.quiz_submissions to anon, authenticated;


-- Short quiz links: quiz payloads are public by design, as recipients can take
-- the quiz. Never put private information in a shared quiz.
create table if not exists public.shared_quizzes (
  id text primary key check (id ~ '^[a-f0-9]{18}$'),
  quiz_data jsonb not null check (
    jsonb_typeof(quiz_data) = 'object'
    and octet_length(quiz_data::text) <= 24000
    and case when jsonb_typeof(quiz_data->'questions') = 'array' then jsonb_array_length(quiz_data->'questions') between 3 and 20 else false end
  ),
  created_at timestamptz not null default now()
);

alter table public.shared_quizzes enable row level security;
drop policy if exists "Anyone can create TRUSTD quiz links" on public.shared_quizzes;
create policy "Anyone can create TRUSTD quiz links"
  on public.shared_quizzes for insert to anon, authenticated
  with check (
    id ~ '^[a-f0-9]{18}$'
    and jsonb_typeof(quiz_data) = 'object'
    and octet_length(quiz_data::text) <= 24000
    and jsonb_typeof(quiz_data->'questions') = 'array'
  );
drop policy if exists "Anyone can read TRUSTD quiz links" on public.shared_quizzes;
create policy "Anyone can read TRUSTD quiz links"
  on public.shared_quizzes for select to anon, authenticated
  using (true);
grant select, insert on public.shared_quizzes to anon, authenticated;
