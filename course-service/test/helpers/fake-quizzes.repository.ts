import { randomUUID } from 'node:crypto';
import { understandingFor } from '../../src/quizzes/quiz-grading';
import { SavedAttempt } from '../../src/quizzes/quizzes.repository';
import {
  AttemptSummary,
  GeneratedQuiz,
  GeneratorCourse,
  GeneratorResource,
  GradeResult,
  ScopeStatsRow,
  StoredQuiz,
  WeakTopicRow,
} from '../../src/quizzes/quizzes.types';
import { CatalogFixture } from './catalog-sources';

interface AttemptRecord {
  id: string;
  userId: string;
  quiz: StoredQuiz;
  grade: GradeResult;
  durationSeconds: number | null;
  submittedAt: Date;
}

/** Same behaviour as the SQL repository (unique quiz per content hash, per-scope stats), kept in memory. */
export class FakeQuizzesRepository {
  quizzes: StoredQuiz[] = [];
  attempts: AttemptRecord[] = [];
  private clock = Date.parse('2026-01-01T00:00:00Z');

  constructor(private readonly fixtures: CatalogFixture[]) {}

  async loadCourse(
    courseId: string,
  ): Promise<{
    course: GeneratorCourse;
    resources: GeneratorResource[];
  } | null> {
    return this.fixtures.find((f) => f.course.id === courseId) ?? null;
  }

  async loadPeers(courseId: string) {
    const others = this.fixtures.filter((f) => f.course.id !== courseId);
    return {
      otherCourses: others.map((f) => f.course),
      otherResources: others.flatMap((f) => f.resources),
    };
  }

  async findQuizBySource(
    courseId: string,
    resourceId: string | null,
    sourceHash: string,
  ): Promise<StoredQuiz | null> {
    return (
      this.quizzes.find(
        (q) =>
          q.courseId === courseId &&
          q.resourceId === resourceId &&
          q.sourceHash === sourceHash,
      ) ?? null
    );
  }

  async findQuizById(id: string): Promise<StoredQuiz | null> {
    return this.quizzes.find((q) => q.id === id) ?? null;
  }

  async insertQuiz(
    courseId: string,
    resourceId: string | null,
    quiz: GeneratedQuiz,
    meta: { sourceHash: string; generator: string; passingPercentage: number },
  ): Promise<string | null> {
    if (await this.findQuizBySource(courseId, resourceId, meta.sourceHash))
      return null;
    const id = randomUUID();
    this.quizzes.push({
      id,
      courseId,
      resourceId,
      title: quiz.title,
      description: quiz.description,
      passingPercentage: meta.passingPercentage,
      generator: meta.generator,
      sourceHash: meta.sourceHash,
      createdAt: new Date(this.clock).toISOString(),
      questions: quiz.questions.map((q, i) => ({
        ...q,
        id: randomUUID(),
        position: i + 1,
      })),
    });
    return id;
  }

  async saveAttempt(input: {
    userId: string;
    quiz: StoredQuiz;
    grade: GradeResult;
    durationSeconds: number | null;
  }): Promise<SavedAttempt> {
    const { userId, quiz, grade, durationSeconds } = input;
    const sameScope = this.attempts.filter(
      (a) =>
        a.userId === userId &&
        a.quiz.courseId === quiz.courseId &&
        a.quiz.resourceId === quiz.resourceId,
    );
    const record: AttemptRecord = {
      id: randomUUID(),
      userId,
      quiz,
      grade,
      durationSeconds,
      submittedAt: new Date((this.clock += 60_000)),
    };
    this.attempts.push(record);
    return {
      attemptId: record.id,
      submittedAt: record.submittedAt.toISOString(),
      attemptNumber: sameScope.length + 1,
      previousScore: sameScope.length
        ? sameScope[sameScope.length - 1].grade.scorePercent
        : null,
      bestScore: Math.max(
        grade.scorePercent,
        ...sameScope.map((a) => a.grade.scorePercent),
      ),
    };
  }

  async listAttempts(
    userId: string,
    quizId: string,
  ): Promise<AttemptSummary[]> {
    return this.attempts
      .filter((a) => a.userId === userId && a.quiz.id === quizId)
      .reverse()
      .map((a) => ({
        attemptId: a.id,
        scorePercent: a.grade.scorePercent,
        correctCount: a.grade.correctCount,
        totalQuestions: a.grade.totalQuestions,
        passed: a.grade.passed,
        understanding: understandingFor(a.grade.scorePercent),
        durationSeconds: a.durationSeconds,
        submittedAt: a.submittedAt.toISOString(),
      }));
  }

  async scopeStats(
    userId: string,
    courseId?: string,
  ): Promise<ScopeStatsRow[]> {
    const mine = this.attempts.filter(
      (a) => a.userId === userId && (!courseId || a.quiz.courseId === courseId),
    );
    const keys = [
      ...new Set(mine.map((a) => `${a.quiz.courseId}|${a.quiz.resourceId}`)),
    ];
    return keys.map((key) => {
      const rows = mine.filter(
        (a) => `${a.quiz.courseId}|${a.quiz.resourceId}` === key,
      );
      const last = rows[rows.length - 1];
      const course = this.fixtures.find(
        (f) => f.course.id === last.quiz.courseId,
      )!.course;
      return {
        courseId: course.id,
        courseTitle: course.title,
        resourceId: last.quiz.resourceId,
        attempts: rows.length,
        bestScore: Math.max(...rows.map((r) => r.grade.scorePercent)),
        lastScore: last.grade.scorePercent,
        passed: rows.some((r) => r.grade.passed),
        lastAttemptAt: last.submittedAt.toISOString(),
      };
    });
  }

  async weakTopics(userId: string): Promise<WeakTopicRow[]> {
    const latest = new Map<string, AttemptRecord>();
    for (const a of this.attempts.filter((x) => x.userId === userId))
      latest.set(`${a.quiz.courseId}|${a.quiz.resourceId}`, a);
    const counts = new Map<string, WeakTopicRow>();
    for (const a of latest.values()) {
      for (const r of a.grade.review.filter((x) => !x.isCorrect)) {
        const key = `${a.quiz.courseId}|${r.topic}`;
        const row = counts.get(key) ?? {
          courseId: a.quiz.courseId,
          topic: r.topic,
          misses: 0,
        };
        row.misses++;
        counts.set(key, row);
      }
    }
    return [...counts.values()];
  }

  async courseQuizCounts() {
    return this.fixtures.map((f) => ({
      courseId: f.course.id,
      courseTitle: f.course.title,
      quizzes: 1 + f.resources.length,
    }));
  }
}