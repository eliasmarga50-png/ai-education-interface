-- Quizzes generated from the course catalogue, plus each student's attempts.
-- Applied once by `npm run db:migrate` (tracked in course_service_migrations).

-- Lets a quiz point at (resource, course) together, so a quiz can never be attached
-- to a resource that belongs to a different course.
ALTER TABLE course_resources
  ADD CONSTRAINT uq_resources_id_course UNIQUE (id, course_id);

CREATE TABLE quizzes (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id          UUID NOT NULL REFERENCES courses (id) ON DELETE CASCADE,
  -- NULL = quiz about the whole course; set = quiz about one learning resource.
  resource_id        UUID,
  title              TEXT NOT NULL,
  description        TEXT NOT NULL,
  passing_percentage INTEGER NOT NULL DEFAULT 60 CHECK (passing_percentage BETWEEN 1 AND 100),
  -- Which generator wrote the questions (e.g. 'catalog-v1'); lets an AI generator be added later.
  generator          TEXT NOT NULL,
  -- Hash of the catalogue content the questions were built from. When the catalogue changes,
  -- the next request creates a new quiz; old quizzes stay so past attempts keep their questions.
  source_hash        TEXT NOT NULL,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (resource_id, course_id) REFERENCES course_resources (id, course_id) ON DELETE CASCADE
);
CREATE UNIQUE INDEX uq_quizzes_scope_hash
  ON quizzes (course_id, COALESCE(resource_id, '00000000-0000-0000-0000-000000000000'::uuid), source_hash);
CREATE INDEX idx_quizzes_scope ON quizzes (course_id, resource_id, created_at DESC);

CREATE TABLE quiz_questions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id       UUID NOT NULL REFERENCES quizzes (id) ON DELETE CASCADE,
  position      INTEGER NOT NULL CHECK (position >= 1),
  kind          TEXT NOT NULL,
  prompt        TEXT NOT NULL,
  options       JSONB NOT NULL CHECK (jsonb_typeof(options) = 'array' AND jsonb_array_length(options) BETWEEN 3 AND 6),
  correct_index INTEGER NOT NULL CHECK (correct_index >= 0),
  explanation   TEXT NOT NULL,
  -- What to revisit when this question is missed (a resource title or a course outcome).
  topic         TEXT NOT NULL,
  UNIQUE (quiz_id, position),
  CHECK (correct_index < jsonb_array_length(options))
);

CREATE TABLE quiz_attempts (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id          UUID NOT NULL REFERENCES quizzes (id) ON DELETE CASCADE,
  -- users.id from the auth backend (same database). Deliberately not a foreign key, so this
  -- migration does not depend on the auth tables existing first.
  user_id          TEXT NOT NULL,
  -- Copied from the quiz so a student's history per course/resource survives a quiz regeneration.
  course_id        UUID NOT NULL REFERENCES courses (id) ON DELETE CASCADE,
  resource_id      UUID,
  total_questions  INTEGER NOT NULL CHECK (total_questions > 0),
  correct_count    INTEGER NOT NULL CHECK (correct_count >= 0),
  score_percent    NUMERIC(5, 2) NOT NULL CHECK (score_percent BETWEEN 0 AND 100),
  passed           BOOLEAN NOT NULL,
  understanding    TEXT NOT NULL CHECK (understanding IN ('mastered', 'proficient', 'developing', 'needs_review')),
  duration_seconds INTEGER CHECK (duration_seconds >= 0),
  submitted_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (correct_count <= total_questions),
  FOREIGN KEY (resource_id, course_id) REFERENCES course_resources (id, course_id) ON DELETE CASCADE
);
CREATE INDEX idx_attempts_user_quiz  ON quiz_attempts (user_id, quiz_id, submitted_at DESC);
CREATE INDEX idx_attempts_user_scope ON quiz_attempts (user_id, course_id, resource_id, submitted_at DESC);

CREATE TABLE quiz_attempt_answers (
  attempt_id     UUID NOT NULL REFERENCES quiz_attempts (id) ON DELETE CASCADE,
  question_id    UUID NOT NULL REFERENCES quiz_questions (id) ON DELETE CASCADE,
  selected_index INTEGER NOT NULL CHECK (selected_index >= 0),
  is_correct     BOOLEAN NOT NULL,
  PRIMARY KEY (attempt_id, question_id)
);

-- Same reason as the other tables: close Supabase's public REST API.
ALTER TABLE quizzes              ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_questions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempts        ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempt_answers ENABLE ROW LEVEL SECURITY;