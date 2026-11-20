# Floriety – what changed & how to set up

## 1. "AI service is not configured on the server"
`GROQ_API_KEY` is empty where `server.py` runs. Set it:
- Hosted (Render/Railway/etc.): add it under Environment, then redeploy.
- Local: copy `.env.example` to `.env`, fill it in, `pip install -r requirements.txt`
  (the server now loads `.env` automatically), then `python server.py`.
Check: open `<server-url>/health` -> `"ai": true`.

## 2. "Account doesn't show on Supabase"
The app keeps its own `users` table (it does NOT use Supabase Auth), so accounts are in:
**Supabase -> Table Editor -> users** (not Authentication -> Users).
1. Run `floriety.sql` once in Supabase -> SQL Editor (creates all tables + the photo bucket).
2. Make sure `DATABASE_URL` points at the SAME Supabase project you are looking at.
3. Verify with (admin key required):
   `curl -H "X-Admin-Key: YOUR_ADMIN_KEY" <server-url>/api/admin/diagnostics`
   It shows the DB host, which tables exist and their row counts, and which settings are missing.

## Other fixes
- Secrets are trimmed (pasted keys with a trailing space/newline no longer break).
- Clear AI errors (missing key 503, invalid key, rate limit 429) instead of one generic message.
- AI model names can be overridden: GROQ_TEXT_MODEL / GROQ_VISION_MODEL.
- floriety.sql enables Row Level Security so the public anon key can't read password hashes.
- Debug Android builds may use http:// (emulator 10.0.2.2 / adb reverse); release stays HTTPS only.
- Scan screen now tells you when a scan/photo couldn't be saved instead of failing silently.
