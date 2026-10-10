# TRUSTD

TRUSTD is a static friendship quiz and leaderboard app that lets you create playful “Who knows me best?” quizzes and share them with friends.

## Features

- Responsive layout for mobile and desktop
- English, Hindi, and Hinglish interface options
- Custom quiz builder with 10, 15, and 20-question options
- Editable question bank and question templates
- Compact, shareable quiz links stored under short IDs in Supabase (legacy inline links still work)
- Score calculation and certificate generator
- Saved quizzes in browser storage
- Supabase leaderboard support
- Friendly empty/error states when the backend is not configured

## Project structure

- `index.html` — the complete TRUSTD app
- `README.md` — set up and deployment instructions
- `.gitignore` — project ignores
- `supabase/setup.sql` — Supabase schema, indexes, and RLS configuration

## Local preview

Because this is a static HTML app, you can preview it locally with any local web server:

```bash
cd /path/to/trustd
python3 -m http.server 8000
```

Then open:

```text
http://localhost:8000
```

## Supabase setup

The app is designed to use the public project URL and anonymous/publishable key already embedded in the browser code:

```text
https://fbagsiysuvcnshorribo.supabase.co
```

This app is intentionally designed to work without a secret backend key. It uses only the public Supabase key in the browser.

Important security note:

- Do not expose a service-role key or database password in the browser.
- Client-side leaderboard scores can be manipulated.
- Treat the leaderboard as a fun public ranking, not a trusted verification system.
- Quiz link rows are public to anyone with the link and have no expiration in this setup; do not add sensitive questions or answers.
- If the updated `shared_quizzes` table has not been created, the app falls back to a longer inline link.
- For production-grade trusted scoring, validate the score server-side before storing it.

Run the current SQL in `supabase/setup.sql` inside the Supabase SQL Editor. This creates leaderboard storage and short-link storage. If you ran an older version, run the updated file again; its setup is safe to re-run.

## Vercel deployment

1. Open the GitHub repo: https://github.com/RajeshwarPathak/trustd_quizz
2. In Vercel, click Add Project and import this repository.
3. Use the default static-site settings:
   - Framework: None / Static
   - Build command: leave empty
   - Output directory: `.`
4. Click Deploy.
5. After the deployment completes, verify the page loads and that the quiz works.

## Custom domain

After the app is deployed:

1. Open the Vercel project.
2. Go to Settings → Domains.
3. Add the custom domain.
4. Update the DNS records with the values Vercel provides.

## Notes

- This is a front-end static app; no package install or framework is required.
- The leaderboard has live support when the database table is configured and the app can reach Supabase.
- If Supabase is unavailable, the app keeps working and shows an explanatory message instead of failing silently.

## Security and limitations

Because the score is generated in the browser, it is not cheat-proof. If you want a trusted ranking, move score validation to a secure serverless endpoint or backend and store only verified values.

## Contact

Made by **Raj_Pathak** · [pathak.r.rajeshwar@gmail.com](mailto:pathak.r.rajeshwar@gmail.com) · Instagram: [@raj_pathak._](https://www.instagram.com/raj_pathak._/)
