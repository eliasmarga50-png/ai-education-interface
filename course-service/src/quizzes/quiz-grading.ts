import {
  AnswerInput,
  CoursePerformance,
  GradeResult,
  Performance,
  ScopePerformance,
  ScopeStatsRow,
  StoredQuestion,
  Understanding,
  UnderstandingLevel,
  WeakTopicRow,
} from './quizzes.types';

/** Thrown for answers that cannot be graded (the controller turns it into a 422). */
export class GradingError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'GradingError';
  }
}

const round2 = (n: number): number => Math.round(n * 100) / 100;

const UNDERSTANDING: Record<
  UnderstandingLevel,
  Omit<Understanding, 'level'>
> = {
  mastered: {
    label: 'Mastered',
    message:
      'You answered almost everything correctly. You clearly understand this material.',
  },
  proficient: {
    label: 'Proficient',
    message:
      'You understand most of this material. A quick look at the questions you missed will close the gaps.',
  },
  developing: {
    label: 'Developing',
    message:
      'You grasp the basics, but some key ideas are still shaky. Review the material and try again.',
  },
  needs_review: {
    label: 'Needs review',
    message:
      'The core ideas have not landed yet. Go back to the material, then take the quiz again.',
  },
};

/** The one place that turns a percentage into "how well do you understand this". */
export function understandingFor(percent: number): Understanding {
  const level: UnderstandingLevel =
    percent >= 90
      ? 'mastered'
      : percent >= 75
        ? 'proficient'
        : percent >= 60
          ? 'developing'
          : 'needs_review';
  return { level, ...UNDERSTANDING[level] };
}

/**
 * Checks the answers against the stored questions. Every question must be answered exactly once
 * with an option that exists. The correct answers come from the database, never from the client.
 */
export function gradeAnswers(
  questions: readonly StoredQuestion[],
  answers: readonly AnswerInput[],
  passingPercentage: number,
): GradeResult {
  const byId = new Map(questions.map((q) => [q.id, q]));
  const given = new Map<string, number>();

  for (const answer of answers) {
    const question = byId.get(answer.questionId);
    if (!question)
      throw new GradingError(
        'One of the answers is for a question that is not in this quiz.',
      );
    if (given.has(answer.questionId))
      throw new GradingError('A question was answered more than once.');
    if (
      !Number.isInteger(answer.selectedIndex) ||
      answer.selectedIndex < 0 ||
      answer.selectedIndex >= question.options.length
    ) {
      throw new GradingError('One of the answers is not one of the options.');
    }
    given.set(answer.questionId, answer.selectedIndex);
  }
  if (given.size !== questions.length)
    throw new GradingError('Answer every question before submitting.');

  const graded = questions.map((q) => {
    const selectedIndex = given.get(q.id) as number;
    return { q, selectedIndex, isCorrect: selectedIndex === q.correctIndex };
  });
  const correctCount = graded.filter((g) => g.isCorrect).length;
  const scorePercent = round2((correctCount / questions.length) * 100);

  const weakTopics: string[] = [];
  for (const g of graded) {
    if (!g.isCorrect && !weakTopics.includes(g.q.topic))
      weakTopics.push(g.q.topic);
  }

  return {
    totalQuestions: questions.length,
    correctCount,
    scorePercent,
    passed: scorePercent >= passingPercentage,
    understanding: understandingFor(scorePercent),
    answers: graded.map((g) => ({
      questionId: g.q.id,
      selectedIndex: g.selectedIndex,
      isCorrect: g.isCorrect,
    })),
    review: graded.map((g) => ({
      questionId: g.q.id,
      prompt: g.q.prompt,
      options: g.q.options,
      selectedIndex: g.selectedIndex,
      correctIndex: g.q.correctIndex,
      isCorrect: g.isCorrect,
      explanation: g.q.explanation,
      topic: g.q.topic,
    })),
    weakTopics: weakTopics.slice(0, 3),
  };
}

/** What to do next, in plain words, based on how the attempt went. */
export function recommendationFor(
  grade: Pick<GradeResult, 'understanding' | 'weakTopics'>,
  quizTitle: string,
): string {
  const topics = grade.weakTopics.map((t) => `“${t}”`).join(', ');
  switch (grade.understanding.level) {
    case 'mastered':
      return 'Great work. Move on to the next resource, or take the course quiz to see the bigger picture.';
    case 'proficient':
      return topics
        ? `Almost there. Take another look at ${topics}, then retake the quiz for a perfect score.`
        : 'Almost there. Review the questions you missed and retake the quiz.';
    case 'developing':
      return topics
        ? `You passed, but ${topics} still needs work. Revisit it and try again.`
        : 'You passed, but some ideas still need work. Revisit the material and try again.';
    default:
      return topics
        ? `Go back to the material for ${topics}, then retake “${quizTitle}”.`
        : `Go back through the material, then retake “${quizTitle}”.`;
  }
}

function average(values: number[]): number {
  return values.length === 0
    ? 0
    : round2(values.reduce((a, b) => a + b, 0) / values.length);
}

export interface PerformanceInput {
  scopes: ScopeStatsRow[];
  weakTopics: WeakTopicRow[];
  /** Published courses and how many quizzes each can have (1 for the course + 1 per resource). */
  courseQuizCounts: {
    courseId: string;
    courseTitle: string;
    quizzes: number;
  }[];
}

/**
 * Turns the raw per-quiz rows into the summaries the app shows.
 * Understanding is based on the LATEST score of each attempted quiz (how well you know it now);
 * the average is based on the BEST score (your achievement).
 */
export function buildPerformance({
  scopes,
  weakTopics,
  courseQuizCounts,
}: PerformanceInput): Performance {
  const scopePerf: ScopePerformance[] = scopes.map((s) => ({
    courseId: s.courseId,
    resourceId: s.resourceId,
    attempts: s.attempts,
    bestScore: s.bestScore,
    lastScore: s.lastScore,
    passed: s.passed,
    understanding: understandingFor(s.lastScore),
    lastAttemptAt: s.lastAttemptAt,
  }));

  const courses: CoursePerformance[] = courseQuizCounts.map((c) => {
    const mine = scopes.filter((s) => s.courseId === c.courseId);
    return {
      courseId: c.courseId,
      courseTitle: c.courseTitle,
      quizzesAvailable: c.quizzes,
      quizzesAttempted: mine.length,
      quizzesPassed: mine.filter((s) => s.passed).length,
      averageScore: average(mine.map((s) => s.bestScore)),
      understanding: understandingFor(average(mine.map((s) => s.lastScore))),
      weakTopics: weakTopics
        .filter((w) => w.courseId === c.courseId)
        .sort((a, b) => b.misses - a.misses || a.topic.localeCompare(b.topic))
        .slice(0, 3)
        .map((w) => w.topic),
    };
  });

  return {
    totalQuizzes: courseQuizCounts.reduce((sum, c) => sum + c.quizzes, 0),
    quizzesAttempted: scopes.length,
    quizzesPassed: scopes.filter((s) => s.passed).length,
    totalAttempts: scopes.reduce((sum, s) => sum + s.attempts, 0),
    averageBestScore:
      scopes.length === 0 ? null : average(scopes.map((s) => s.bestScore)),
    understanding:
      scopes.length === 0
        ? null
        : understandingFor(average(scopes.map((s) => s.lastScore))),
    courses,
    scopes: scopePerf,
  };
}