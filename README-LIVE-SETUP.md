# O Level Digital Textbook V10 — Online Database Edition

This build keeps the approved V9 textbook/practice/test UI and adds a real Supabase database + Supabase Auth admin path.

## What is online-ready
- Public students can read active questions from Supabase.
- Admin users can add, edit, duplicate and delete questions.
- CSV/JSON import can add questions to the online bank.
- Supabase Auth handles sign-in; admin access is controlled by `admin_users`.
- The browser only uses a publishable/anon key. Never put a Supabase secret/service-role key in `config.js`.

Supabase's current JavaScript client supports browser initialization with the project URL and publishable key, and its RLS system should be used to protect exposed tables. [Supabase JS docs](https://supabase.com/docs/reference/javascript/initializing)

## 1. Create the database
1. Create a Supabase project. The current Free plan is $0/month and includes a Postgres database; Supabase notes that free projects can pause after 1 week of inactivity.
2. Open **SQL Editor**.
3. Run `supabase-schema.sql`.
4. Run `supabase-seed-ch2.sql`.

## 2. Create your Admin account
1. Open the website after configuring `config.js`.
2. Click **Admin Login → Create Account**.
3. Finish email confirmation if your Supabase Auth settings require it, then sign in.
4. In Supabase SQL Editor, find the user's UUID in Auth users and run:

```sql
insert into public.admin_users (user_id)
select id from auth.users where email = 'YOUR_EMAIL_HERE'
on conflict (user_id) do nothing;
```

5. Sign out and sign in again. The **Admin** button will then appear.

## 3. Connect the website
Open `config.js` and paste the project URL and **publishable key** from Supabase:

```js
window.SUPABASE_CONFIG = {
  url: 'https://YOUR_PROJECT.supabase.co',
  publishableKey: 'YOUR_PUBLISHABLE_KEY'
};
```

Do NOT use a secret/service-role key in the browser.

## 4. Put it live on GitHub Pages
Upload the contents of this folder to a GitHub repository. In **Settings → Pages**, choose **Deploy from a branch**, select `main`, and use the root folder. GitHub documents branch-based Pages publishing and the resulting site URL.

## Files
- `index.html` — full website
- `config.js` — only file you need to fill with Supabase URL/key
- `supabase-schema.sql` — database tables, RLS, admin authorization
- `supabase-seed-ch2.sql` — Chapter 2 starter questions/topics

## Important security note
The browser can safely use the Supabase publishable key only when RLS/grants are correctly configured. The secret/service-role key must stay server-side.
