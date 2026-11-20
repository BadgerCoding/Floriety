-- Floriety database schema for Supabase Postgres.
-- Run once in: Supabase Dashboard -> SQL Editor -> New query -> paste -> Run.
-- Safe to re-run (everything uses IF NOT EXISTS).

CREATE TABLE IF NOT EXISTS public.users (
    id             BIGSERIAL PRIMARY KEY,
    email          TEXT NOT NULL UNIQUE,
    password_hash  TEXT NOT NULL,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.profiles (
    id            BIGSERIAL PRIMARY KEY,
    user_id       BIGINT NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
    name          TEXT NOT NULL DEFAULT '',
    nickname      TEXT NOT NULL DEFAULT '',
    description   TEXT NOT NULL DEFAULT '',
    avatar_index  INTEGER NOT NULL DEFAULT 1,
    is_dark       BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS public.sessions (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    token_hash  TEXT NOT NULL UNIQUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS sessions_user_idx ON public.sessions(user_id);

CREATE TABLE IF NOT EXISTS public.scan_history (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    flower_name         TEXT NOT NULL DEFAULT '',
    scientific          TEXT NOT NULL DEFAULT '',
    family              TEXT NOT NULL DEFAULT '',
    variety_appearance  TEXT NOT NULL DEFAULT '',
    origin              TEXT NOT NULL DEFAULT '',
    habitat             TEXT NOT NULL DEFAULT '',
    allergen            TEXT NOT NULL DEFAULT '',
    disease             TEXT NOT NULL DEFAULT '',
    care_list           TEXT NOT NULL DEFAULT '',
    description         TEXT NOT NULL DEFAULT '',
    image_url           TEXT NOT NULL DEFAULT '',
    is_favorite         BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS scan_history_user_idx ON public.scan_history(user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS public.feedback (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    gmail       TEXT NOT NULL DEFAULT '',
    subject     TEXT NOT NULL,
    message     TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.chat_history (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title       TEXT NOT NULL DEFAULT '',
    messages    JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS chat_history_user_idx ON public.chat_history(user_id, updated_at DESC);

-- SECURITY: Supabase exposes public tables through its REST API using the public
-- "anon" key. Turning on Row Level Security (with no policies) blocks that
-- route, so password hashes can't be read by anyone. The Flask server connects
-- directly as the database owner, which bypasses RLS, so the app keeps working.
ALTER TABLE public.users          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scan_history   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feedback       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_history   ENABLE ROW LEVEL SECURITY;

-- Public bucket for flower photos (the server uploads with the secret key).
INSERT INTO storage.buckets (id, name, public)
VALUES ('flower-images', 'flower-images', TRUE)
ON CONFLICT (id) DO NOTHING;
