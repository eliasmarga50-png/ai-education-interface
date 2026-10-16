-- Course catalogue. Applied once by `npm run db:migrate` (tracked in course_service_migrations).

CREATE TABLE courses (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug         TEXT NOT NULL UNIQUE CHECK (char_length(slug) BETWEEN 1 AND 80),
  title        TEXT NOT NULL,
  description  TEXT NOT NULL,
  category     TEXT NOT NULL,
  level        TEXT NOT NULL CHECK (level IN ('Beginner', 'Intermediate', 'Advanced')),
  lesson_count INTEGER NOT NULL DEFAULT 0 CHECK (lesson_count >= 0),
  rating       NUMERIC(2, 1) CHECK (rating BETWEEN 0 AND 5),
  image_url    TEXT,
  outcomes     TEXT[] NOT NULL DEFAULT '{}',
  position     INTEGER NOT NULL DEFAULT 0,
  is_published BOOLEAN NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_courses_listing ON courses (position, id) WHERE is_published;
CREATE INDEX idx_courses_category ON courses (lower(category));

CREATE TABLE course_resources (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id   UUID NOT NULL REFERENCES courses (id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  url         TEXT NOT NULL CHECK (url ~* '^https?://'),
  type        TEXT NOT NULL CHECK (type IN
                ('documentation', 'tutorial', 'video', 'course', 'article', 'book', 'interactive')),
  description TEXT NOT NULL,
  provider    TEXT NOT NULL,
  language    TEXT NOT NULL DEFAULT 'en',
  difficulty  TEXT CHECK (difficulty IN ('Beginner', 'Intermediate', 'Advanced')),
  position    INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (course_id, url)
);
CREATE INDEX idx_resources_course_position ON course_resources (course_id, position, id);

-- Same reason as the auth tables: close Supabase's public REST API. The backend
-- connects as the database owner, which is not affected.
ALTER TABLE courses          ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_resources ENABLE ROW LEVEL SECURITY;