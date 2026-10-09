# TRUSTD 💜

A playful friendship quiz app. Create a quiz, share the link, compare scores, and print a just-for-fun certificate.

## Run locally

Open `index.html` in a browser or serve this repository with any static web server. No build step is required.

## Configure the leaderboard (optional)

1. Create a Supabase project.
2. Run [supabase/setup.sql](supabase/setup.sql) in the SQL Editor.
3. Copy your Project URL and **publishable/anon key** into `config.js`. Both values are visible to every browser user by design.
4. Deploy the repository to Vercel as a static site with the repository root as the project root.

Never place a Supabase service-role key in this app, `.env`, browser code, or Vercel client variables. The service-role key bypasses row-level security.

Without Supabase configured, quiz creation, share links, results, certificates, and browser-saved quizzes continue to work; shared leaderboard reads and writes are unavailable.

## Privacy and limitations

Quiz answers are encoded into the share URL so friends can play without accounts. Encoding is not encryption: anyone with the link can inspect the correct answers. Saved quizzes are kept in that browser's local storage.

Leaderboard submissions are sent from the browser. Scores, names, and quiz metadata can be spoofed, and anonymous users can submit repeatedly. Treat the leaderboard as casual entertainment, not a trusted record. Do not collect sensitive personal information.

## Deploy to Vercel

Import this GitHub repository in Vercel and deploy using the default static settings. No server-side secrets or build command are needed. Set the public Supabase URL and publishable key in `config.js` before deployment if you want shared leaderboards.

## Features

- Quiz creation with 10, 15, or 20 questions and editable answer keys
- Shareable links and quiz play/results
- Optional Supabase leaderboard
- Printable certificates
- Local saved quizzes
