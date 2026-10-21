import { Injectable } from '@nestjs/common';
import { DatabaseService, Queryable } from '../database/database.service';
import {
  AttemptSummary,
  GeneratedQuiz,
  GeneratorCourse,
  GeneratorResource,
  GradeResult,
  ScopeStatsRow,
  StoredQuestion,
  StoredQuiz,
  WeakTopicRow,
} from './quizzes.types';
import { understandingFor } from './quiz-grading';

const NO_RESOURCE = '00000000-0000-0000-0000-000000000000';

const QUIZ_SELECT = `
  SELECT q.id, q.course_id AS "courseId", q.resource_id AS "resourceId", q.title, q.description,
         q.passing_percentage AS "passingPercentage", q.generator, q.source_hash AS "sourceHash",
         q.created_at AS "createdAt",
         COALESCE((
           SELECT json_agg(json_build_object(
                    'id', x.id, 'position', x.position, 'kind', x.kind, 'prompt', x.prompt,
                    'options', x.options, 'correctIndex', x.correct_index,
                    'explanation', x.explanation, 'topic', x.topic) ORDER BY x.position)
             FROM quiz_questions x WHERE x.quiz_id = q.id
         ), '[]'::json) AS questions
    FROM quizzes q
    JOIN courses c ON c.id = q.course_id AND c.is_published`;

type QuizRow = Omit<StoredQuiz, 'createdAt' | 'questions'> & {
  createdAt: Date;
  questions: StoredQuestion[];
};

function toQuiz(row: QuizRow): StoredQuiz {
  return { ...row, createdAt: row.createdAt.toISOString() };
}

export interface PriorStats {
  attempts: number;
  best: number | null;
  last: number | null;
}

export interface SavedAttempt {
  attemptId: string;
  submittedAt: string;
  attemptNumber: number;
  previousScore: number | null;
  bestScore: number;
}

@Injectable()
export class QuizzesRepository {
  constructor(private readonly db: DatabaseService) {}

  // ---- content the generator reads ---------------------------------------

  async loadCourse(
    courseId: string,
  ): Promise<{
    course: GeneratorCourse;
    resources: GeneratorResource[];
  } | null> {
    const courses = await this.db.query<GeneratorCourse>(
      `SELECT id, title, description, category, level, outcomes
         FROM courses WHERE id = $1 AND is_published = TRUE`,
      [courseId],
    );
    if (!courses.rows[0]) return null;
    const resources = await this.db.query<GeneratorResource>(
      `SELECT id, course_id AS "courseId", title, type, description, provider, difficulty
         FROM course_resources WHERE course_id = $1 ORDER BY position, id`,
      [courseId],
    );
    return { course: courses.rows[0], resources: resources.rows };
  }

  /** Other published courses and their resources: the pool the wrong answers are drawn from. */
  async loadPeers(
    courseId: string,
  ): Promise<{
    otherCourses: GeneratorCourse[];
    otherResources: GeneratorResource[];
  }> {
    const [courses, resources] = await Promise.all([
      this.db.query<GeneratorCourse>(
        `SELECT id, title, description, category, level, outcomes
           FROM courses WHERE is_published = TRUE AND id <> $1 ORDER BY position, id`,
        [courseId],
      ),
      this.db.query<GeneratorResource>(
        `SELECT r.id, r.course_id AS "courseId", r.title, r.type, r.description, r.provider, r.difficulty
           FROM course_resources r
           JOIN courses c ON c.id = r.course_id AND c.is_published = TRUE
          WHERE r.course_id <> $1
          ORDER BY c.position, r.position, r.id
          LIMIT 300`,
        [courseId],
      ),
    ]);
    return { otherCourses: courses.rows, otherResources: resources.rows };
  }

  // ---- quizzes -------------------------------------------------------------

  async findQuizBySource(
    courseId: string,
    resourceId: string | null,
    sourceHash: string,
  ): Promise<StoredQuiz | null> {
    const { rows } = await this.db.query<QuizRow>(
      `${QUIZ_SELECT}
        WHERE q.course_id = $1
          AND COALESCE(q.resource_id, '${NO_RESOURCE}'::uuid) = COALESCE($2::uuid, '${NO_RESOURCE}'::uuid)
          AND q.source_hash = $3`,
      [courseId, resourceId, sourceHash],
    );
    return rows[0] ? toQuiz(rows[0]) : null;
  }

  async findQuizById(id: string): Promise<StoredQuiz | null> {
    const { rows } = await this.db.query<QuizRow>(
      `${QUIZ_SELECT} WHERE q.id = $1`,
      [id],
    );
    return rows[0] ? toQuiz(rows[0]) : null;
  }

  /**
   * Stores a generated quiz and its questions in one transaction. Returns null when another
   * request stored the same quiz first (the unique index on course + resource + content hash);
   * the caller then reads that copy.
   */
  async insertQuiz(
    courseId: string,
    resourceId: string | null,
    quiz: GeneratedQuiz,
    meta: { sourceHash: string; generator: string; passingPercentage: number },
  ): Promise<string | null> {
    return this.db.transaction(async (tx) => {
      const inserted = await tx.query<{ id: string }>(
        `INSERT INTO quizzes (course_id, resource_id, title, description, passing_percentage, generator, source_hash)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         ON CONFLICT DO NOTHING
         RETURNING id`,
        [
          courseId,
          resourceId,
          quiz.title,
          quiz.description,
          meta.passingPercentage,
          meta.generator,
          meta.sourceHash,
        ],
      );
      const quizId = inserted.rows[0]?.id;
      if (!quizId) return null;

      const params: unknown[] = [];
      const tuples = quiz.questions.map((q, i) => {
        params.push(
          quizId,
          i + 1,
          q.kind,
          q.prompt,
          JSON.stringify(q.options),
          q.correctIndex,
          q.explanation,
          q.topic,
        );
        const b = i * 8;
        return `($${b + 1}, $${b + 2}, $${b + 3}, $${b + 4}, $${b + 5}::jsonb, $${b + 6}, $${b + 7}, $${b + 8})`;
      });
      await tx.query(
        `INSERT INTO quiz_questions (quiz_id, position, kind, prompt, options, correct_index, explanation, topic)
         VALUES ${tuples.join(', ')}`,
        params,
      );
      return quizId;
    });
  }

  // ---- attempts -------------------------------------------------------------

  private async priorStats(
    tx: Queryable,
    userId: string,
    courseId: string,
    resourceId: string | null,
  ): Promise<PriorStats> {
    const { rows } = await tx.query<PriorStats>(
      `SELECT count(*)::int AS attempts,
              max(score_percent)::float8 AS best,
              (array_agg(score_percent ORDER BY submitted_at DESC, id DESC))[1]::float8 AS last
         FROM quiz_attempts
        WHERE user_id = $1 AND course_id = $2 AND resource_id IS NOT DISTINCT FROM $3::uuid`,
      [userId, courseId, resourceId],
    );
    return rows[0];
  }

  /** Saves the attempt and every answer atomically, and reports how it compares with earlier tries. */
  async saveAttempt(input: {
    userId: string;
    quiz: StoredQuiz;
    grade: GradeResult;
    durationSeconds: number | null;
  }): Promise<SavedAttempt> {
    const { userId, quiz, grade, durationSeconds } = input;
    return this.db.transaction(async (tx) => {
      const prior = await this.priorStats(
        tx,
        userId,
        quiz.courseId,
        quiz.resourceId,
      );

      const inserted = await tx.query<{ id: string; submittedAt: Date }>(
        `INSERT INTO quiz_attempts
           (quiz_id, user_id, course_id, resource_id, total_questions, correct_count,
            score_percent, passed, understanding, duration_seconds)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
         RETURNING id, submitted_at AS "submittedAt"`,
        [
          quiz.id,
          userId,
          quiz.courseId,
          quiz.resourceId,
          grade.totalQuestions,
          grade.correctCount,
          grade.scorePercent,
          grade.passed,
          grade.understanding.level,
          durationSeconds,
        ],
      );
      const attempt = inserted.rows[0];

      const params: unknown[] = [];
      const tuples = grade.answers.map((a, i) => {
        params.push(attempt.id, a.questionId, a.selectedIndex, a.isCorrect);
        const b = i * 4;
        return `($${b + 1}, $${b + 2}, $${b + 3}, $${b + 4})`;
      });
      await tx.query(
        `INSERT INTO quiz_attempt_answers (attempt_id, question_id, selected_index, is_correct)
         VALUES ${tuples.join(', ')}`,
        params,
      );

      return {
        attemptId: attempt.id,
        submittedAt: attempt.submittedAt.toISOString(),
        attemptNumber: prior.attempts + 1,
        previousScore: prior.last,
        bestScore: Math.max(prior.best ?? 0, grade.scorePercent),
      };
    });
  }

  async listAttempts(
    userId: string,
    quizId: string,
    limit = 20,
  ): Promise<AttemptSummary[]> {
    const { rows } = await this.db.query<{
      attemptId: string;
      scorePercent: number;
      correctCount: number;
      totalQuestions: number;
      passed: boolean;
      understanding: AttemptSummary['understanding']['level'];
      durationSeconds: number | null;
      submittedAt: Date;
    }>(
      `SELECT id AS "attemptId", score_percent::float8 AS "scorePercent", correct_count AS "correctCount",
              total_questions AS "totalQuestions", passed, understanding,
              duration_seconds AS "durationSeconds", submitted_at AS "submittedAt"
         FROM quiz_attempts
        WHERE user_id = $1 AND quiz_id = $2
        ORDER BY submitted_at DESC, id DESC
        LIMIT $3`,
      [userId, quizId, limit],
    );
    return rows.map((r) => ({
      attemptId: r.attemptId,
      scorePercent: r.scorePercent,
      correctCount: r.correctCount,
      totalQuestions: r.totalQuestions,
      passed: r.passed,
      understanding: understandingFor(r.scorePercent),
      durationSeconds: r.durationSeconds,
      submittedAt: r.submittedAt.toISOString(),
    }));
  }

  // ---- performance ----------------------------------------------------------

  /** One row per quiz scope (a course, or one of its resources) the student has attempted. */
  async scopeStats(
    userId: string,
    courseId?: string,
  ): Promise<ScopeStatsRow[]> {
    const { rows } = await this.db.query<
      Omit<ScopeStatsRow, 'lastAttemptAt'> & { lastAttemptAt: Date }
    >(
      `WITH mine AS (
         SELECT a.*,
                row_number() OVER (PARTITION BY a.course_id, a.resource_id
                                   ORDER BY a.submitted_at DESC, a.id DESC) AS rn
           FROM quiz_attempts a
           JOIN courses c ON c.id = a.course_id AND c.is_published = TRUE
          WHERE a.user_id = $1 AND ($2::uuid IS NULL OR a.course_id = $2::uuid)
       )
       SELECT m.course_id AS "courseId", c.title AS "courseTitle", m.resource_id AS "resourceId",
              count(*)::int AS attempts,
              max(m.score_percent)::float8 AS "bestScore",
              max(m.score_percent) FILTER (WHERE m.rn = 1)::float8 AS "lastScore",
              bool_or(m.passed) AS passed,
              max(m.submitted_at) AS "lastAttemptAt"
         FROM mine m
         JOIN courses c ON c.id = m.course_id
        GROUP BY m.course_id, c.title, m.resource_id
        ORDER BY m.course_id, m.resource_id NULLS FIRST`,
      [userId, courseId ?? null],
    );
    return rows.map((r) => ({
      ...r,
      lastAttemptAt: r.lastAttemptAt.toISOString(),
    }));
  }

  /** Topics missed in the most recent attempt of each quiz scope, counted per course. */
  async weakTopics(userId: string): Promise<WeakTopicRow[]> {
    const { rows } = await this.db.query<WeakTopicRow>(
      `WITH latest AS (
         SELECT DISTINCT ON (course_id, resource_id) id, course_id
           FROM quiz_attempts
          WHERE user_id = $1
          ORDER BY course_id, resource_id, submitted_at DESC, id DESC
       )
       SELECT l.course_id AS "courseId", q.topic, count(*)::int AS misses
         FROM latest l
         JOIN quiz_attempt_answers x ON x.attempt_id = l.id AND x.is_correct = FALSE
         JOIN quiz_questions q ON q.id = x.question_id
        GROUP BY l.course_id, q.topic`,
      [userId],
    );
    return rows;
  }

  /** Every published course, with how many quizzes it can have: one for the course plus one per resource. */
  async courseQuizCounts(): Promise<
    { courseId: string; courseTitle: string; quizzes: number }[]
  > {
    const { rows } = await this.db.query<{
      courseId: string;
      courseTitle: string;
      quizzes: number;
    }>(
      `SELECT c.id AS "courseId", c.title AS "courseTitle",
              (1 + (SELECT count(*) FROM course_resources r WHERE r.course_id = c.id))::int AS quizzes
         FROM courses c
        WHERE c.is_published = TRUE
        ORDER BY c.position, c.id`,
    );
    return rows;
  }
}