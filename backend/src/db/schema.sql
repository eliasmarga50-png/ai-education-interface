-- PostgreSQL schema for the AI Education backend (Neon, Supabase, or any Postgres 12+).
-- Safe to run more than once.
--
-- Timestamps are epoch MILLISECONDS stored as BIGINT, exactly like the old SQLite
-- version, so the auth service did not have to change its time handling.

CREATE TABLE IF NOT EXISTS users (
  id                 TEXT    PRIMARY KEY,
  name               TEXT    NOT NULL,
  email              TEXT    NOT NULL UNIQUE,
  password_hash      TEXT    NOT NULL,
  email_verified_at  BIGINT,
  failed_login_count INTEGER NOT NULL DEFAULT 0,
  locked_until       BIGINT,
  created_at         BIGINT  NOT NULL,
  updated_at         BIGINT  NOT NULL
);

CREATE TABLE IF NOT EXISTS verification_codes (
  id          TEXT   PRIMARY KEY,
  -- Insertion order, used to pick the newest code when two share a millisecond.
  seq         BIGINT GENERATED ALWAYS AS IDENTITY,
  user_id     TEXT   NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  purpose     TEXT   NOT NULL CHECK (purpose IN ('verify_email', 'reset_password')),
  code_hash   TEXT   NOT NULL,
  expires_at  BIGINT NOT NULL,
  attempts    INTEGER NOT NULL DEFAULT 0,
  consumed_at BIGINT,
  created_at  BIGINT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_codes_lookup
  ON verification_codes (user_id, purpose, created_at, seq);

CREATE TABLE IF NOT EXISTS sessions (
  id                 TEXT   PRIMARY KEY,
  user_id            TEXT   NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  access_hash        TEXT   NOT NULL UNIQUE,
  access_expires_at  BIGINT NOT NULL,
  refresh_hash       TEXT   NOT NULL UNIQUE,
  refresh_expires_at BIGINT NOT NULL,
  created_at         BIGINT NOT NULL,
  revoked_at         BIGINT
);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions (user_id);

-- Supabase publishes every table in the "public" schema through its REST API.
-- Turning row level security on with NO policies closes that door. The backend
-- connects as the database owner, which is not affected. On Neon this is harmless.
ALTER TABLE users              ENABLE ROW LEVEL SECURITY;
ALTER TABLE verification_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions           ENABLE ROW LEVEL SECURITY;