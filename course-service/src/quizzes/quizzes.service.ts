import {
  Injectable,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { SubmitAttemptDto } from './dto/submit-attempt.dto';
import {
  computeSourceHash,
  GENERATOR_ID,
  generateQuiz,
} from './quiz-generator';
import {
  buildPerformance,
  GradingError,
  gradeAnswers,
  recommendationFor,
  understandingFor,
} from './quiz-grading';
import { QuizzesRepository } from './quizzes.repository';
import {
  AttemptResult,
  AttemptSummary,
  GeneratorSource,
  PASSING_PERCENTAGE,
  Performance,
  PublicQuiz,
  QuizSummary,
  ScopeStatsRow,
  StoredQuiz,
} from './quizzes.types';

function toPublic(quiz: StoredQuiz): PublicQuiz {
  return {
    id: quiz.id,
    courseId: quiz.courseId,
    resourceId: quiz.resourceId,
    scope: quiz.resourceId ? 'resource' : 'course',
    title: quiz.title,
    description: quiz.description,
    passingPercentage: quiz.passingPercentage,
    questionCount: quiz.questions.length,
    createdAt: quiz.createdAt,
    // The answers and explanations stay on the server until the student submits.
    questions: quiz.questions.map((q) => ({
      id: q.id,
      position: q.position,
      prompt: q.prompt,
      options: q.options,
      topic: q.topic,
    })),
  };
}

const notEnoughContent = () =>
  new NotFoundException(
    'There is not enough course content to build this quiz yet.',
  );

@Injectable()
export class QuizzesService {
  constructor(private readonly repo: QuizzesRepository) {}

  // ---- serving quizzes -------------------------------------------------------

  /** The quiz about a whole course. Built from the catalogue on first request, then reused. */
  async getCourseQuiz(courseId: string): Promise<PublicQuiz> {
    const source = await this.loadSource(courseId, null);
    return toPublic(await this.ensureQuiz(source));
  }

  /** The quiz about one learning resource of a course. */
  async getResourceQuiz(
    courseId: string,
    resourceId: string,
  ): Promise<PublicQuiz> {
    const source = await this.loadSource(courseId, resourceId);
    return toPublic(await this.ensureQuiz(source));
  }

  async getQuiz(quizId: string): Promise<PublicQuiz> {
    return toPublic(await this.requireQuiz(quizId));
  }

  /** Every quiz of a course (the course quiz plus one per resource) with the student's results. */
  async listForCourse(
    userId: string,
    courseId: string,
  ): Promise<QuizSummary[]> {
    const base = await this.repo.loadCourse(courseId);
    if (!base) throw new NotFoundException(`Course ${courseId} was not found.`);
    const peers = await this.repo.loadPeers(courseId);

    const sources: GeneratorSource[] = [null, ...base.resources].map(
      (target) => ({ ...base, ...peers, target }),
    );
    const quizzes = (
      await Promise.all(sources.map((s) => this.tryEnsureQuiz(s)))
    ).filter((q): q is StoredQuiz => q !== null);

    const stats = await this.repo.scopeStats(userId, courseId);
    const statsFor = (resourceId: string | null): ScopeStatsRow | undefined =>
      stats.find((s) => s.resourceId === resourceId);

    return quizzes.map((quiz) => {
      const row = statsFor(quiz.resourceId);
      return {
        id: quiz.id,
        courseId: quiz.courseId,
        resourceId: quiz.resourceId,
        scope: quiz.resourceId ? 'resource' : 'course',
        title: quiz.title,
        description: quiz.description,
        questionCount: quiz.questions.length,
        passingPercentage: quiz.passingPercentage,
        stats: row
          ? {
              attempts: row.attempts,
              bestScore: row.bestScore,
              lastScore: row.lastScore,
              passed: row.passed,
              understanding: understandingFor(row.lastScore),
              lastAttemptAt: row.lastAttemptAt,
            }
          : null,
      };
    });
  }

  // ---- results ------------------------------------------------------------------

  /** Grades on the server, saves the attempt and every answer, and returns the full review. */
  async submitAttempt(
    userId: string,
    quizId: string,
    dto: SubmitAttemptDto,
  ): Promise<AttemptResult> {
    const quiz = await this.requireQuiz(quizId);

    let grade;
    try {
      grade = gradeAnswers(quiz.questions, dto.answers, quiz.passingPercentage);
    } catch (err) {
      if (err instanceof GradingError) {
        throw new UnprocessableEntityException({
          message: err.message,
          fields: { answers: err.message },
        });
      }
      throw err;
    }

    const saved = await this.repo.saveAttempt({
      userId,
      quiz,
      grade,
      durationSeconds: dto.durationSeconds ?? null,
    });

    return {
      totalQuestions: grade.totalQuestions,
      correctCount: grade.correctCount,
      scorePercent: grade.scorePercent,
      passed: grade.passed,
      understanding: grade.understanding,
      review: grade.review,
      weakTopics: grade.weakTopics,
      attemptId: saved.attemptId,
      quizId: quiz.id,
      courseId: quiz.courseId,
      resourceId: quiz.resourceId,
      passingPercentage: quiz.passingPercentage,
      attemptNumber: saved.attemptNumber,
      previousScore: saved.previousScore,
      bestScore: saved.bestScore,
      recommendation: recommendationFor(grade, quiz.title),
      submittedAt: saved.submittedAt,
    };
  }

  async listAttempts(
    userId: string,
    quizId: string,
  ): Promise<AttemptSummary[]> {
    await this.requireQuiz(quizId);
    return this.repo.listAttempts(userId, quizId);
  }

  async performance(userId: string): Promise<Performance> {
    const [scopes, weakTopics, courseQuizCounts] = await Promise.all([
      this.repo.scopeStats(userId),
      this.repo.weakTopics(userId),
      this.repo.courseQuizCounts(),
    ]);
    return buildPerformance({ scopes, weakTopics, courseQuizCounts });
  }

  // ---- internals --------------------------------------------------------------------

  private async requireQuiz(quizId: string): Promise<StoredQuiz> {
    const quiz = await this.repo.findQuizById(quizId);
    if (!quiz) throw new NotFoundException(`Quiz ${quizId} was not found.`);
    return quiz;
  }

  private async loadSource(
    courseId: string,
    resourceId: string | null,
  ): Promise<GeneratorSource> {
    const base = await this.repo.loadCourse(courseId);
    if (!base) throw new NotFoundException(`Course ${courseId} was not found.`);

    let target = null;
    if (resourceId) {
      target = base.resources.find((r) => r.id === resourceId) ?? null;
      if (!target)
        throw new NotFoundException(
          `Resource ${resourceId} was not found in this course.`,
        );
    }
    return { ...base, ...(await this.repo.loadPeers(courseId)), target };
  }

  private async ensureQuiz(source: GeneratorSource): Promise<StoredQuiz> {
    const quiz = await this.tryEnsureQuiz(source);
    if (!quiz) throw notEnoughContent();
    return quiz;
  }

  /**
   * Finds the quiz for this exact catalogue content, or generates and stores it. When the
   * catalogue changed since the last quiz, a new quiz is made and the old one is kept, so earlier
   * attempts still point at the questions the student actually saw.
   */
  private async tryEnsureQuiz(
    source: GeneratorSource,
  ): Promise<StoredQuiz | null> {
    const resourceId = source.target?.id ?? null;
    const sourceHash = computeSourceHash(source);

    const existing = await this.repo.findQuizBySource(
      source.course.id,
      resourceId,
      sourceHash,
    );
    if (existing) return existing;

    const generated = generateQuiz(source, sourceHash);
    if (!generated) return null;

    const insertedId = await this.repo.insertQuiz(
      source.course.id,
      resourceId,
      generated,
      {
        sourceHash,
        generator: GENERATOR_ID,
        passingPercentage: PASSING_PERCENTAGE,
      },
    );
    // null = another request stored the same quiz a moment ago; read that copy.
    return insertedId
      ? this.repo.findQuizById(insertedId)
      : this.repo.findQuizBySource(source.course.id, resourceId, sourceHash);
  }
}