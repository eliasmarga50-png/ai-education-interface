import {
  buildPerformance,
  GradingError,
  gradeAnswers,
  recommendationFor,
  understandingFor,
} from './quiz-grading';
import { StoredQuestion } from './quizzes.types';

const q = (
  n: number,
  correctIndex: number,
  topic = `Topic ${n}`,
): StoredQuestion => ({
  id: `00000000-0000-4000-8000-00000000000${n}`,
  position: n,
  kind: 'test',
  prompt: `Question ${n}?`,
  options: ['A', 'B', 'C', 'D'],
  correctIndex,
  explanation: `Because ${n}.`,
  topic,
});
const questions = [q(1, 0), q(2, 1), q(3, 2), q(4, 3)];
const answer = (question: StoredQuestion, selectedIndex: number) => ({
  questionId: question.id,
  selectedIndex,
});

describe('understandingFor', () => {
  it.each([
    [100, 'mastered'],
    [90, 'mastered'],
    [89.99, 'proficient'],
    [75, 'proficient'],
    [74, 'developing'],
    [60, 'developing'],
    [59.99, 'needs_review'],
    [0, 'needs_review'],
  ])('%s%% is %s', (percent, level) => {
    expect(understandingFor(percent).level).toBe(level);
  });
});

describe('gradeAnswers', () => {
  it('scores a perfect attempt', () => {
    const g = gradeAnswers(
      questions,
      questions.map((x) => answer(x, x.correctIndex)),
      60,
    );
    expect(g).toMatchObject({
      correctCount: 4,
      totalQuestions: 4,
      scorePercent: 100,
      passed: true,
    });
    expect(g.understanding.level).toBe('mastered');
    expect(g.weakTopics).toEqual([]);
  });

  it('uses the stored answers, not anything the client claims', () => {
    const g = gradeAnswers(
      questions,
      [
        answer(questions[0], 0),
        answer(questions[1], 0),
        answer(questions[2], 0),
        answer(questions[3], 0),
      ],
      60,
    );
    expect(g.correctCount).toBe(1);
    expect(g.review.map((r) => r.isCorrect)).toEqual([
      true,
      false,
      false,
      false,
    ]);
    expect(g.review[1]).toMatchObject({
      selectedIndex: 0,
      correctIndex: 1,
      explanation: 'Because 2.',
    });
  });

  it('marks pass/fail against the passing percentage and lists weak topics (max 3)', () => {
    const wrong = [
      answer(questions[0], 3),
      answer(questions[1], 3),
      answer(questions[2], 3),
      answer(questions[3], 3),
    ];
    const g = gradeAnswers(questions, wrong, 60);
    expect(g).toMatchObject({
      correctCount: 1,
      scorePercent: 25,
      passed: false,
    });
    expect(g.understanding.level).toBe('needs_review');
    expect(g.weakTopics).toEqual(['Topic 1', 'Topic 2', 'Topic 3']);

    const half = gradeAnswers(
      questions,
      [
        answer(questions[0], 0),
        answer(questions[1], 1),
        answer(questions[2], 0),
        answer(questions[3], 0),
      ],
      50,
    );
    expect(half).toMatchObject({ scorePercent: 50, passed: true });
  });

  it('rounds the score to two decimals', () => {
    const three = [q(1, 0), q(2, 0), q(3, 0)];
    const g = gradeAnswers(
      three,
      [answer(three[0], 0), answer(three[1], 1), answer(three[2], 1)],
      60,
    );
    expect(g.scorePercent).toBe(33.33);
  });

  it.each([
    [
      'an unknown question',
      () => [
        ...questions.slice(1).map((x) => answer(x, 0)),
        {
          questionId: '99999999-9999-4999-8999-999999999999',
          selectedIndex: 0,
        },
      ],
    ],
    [
      'a duplicate answer',
      () => [
        answer(questions[0], 0),
        answer(questions[0], 1),
        answer(questions[2], 0),
        answer(questions[3], 0),
      ],
    ],
    ['a missing answer', () => questions.slice(1).map((x) => answer(x, 0))],
    [
      'an option that does not exist',
      () => [
        answer(questions[0], 4),
        ...questions.slice(1).map((x) => answer(x, 0)),
      ],
    ],
    [
      'a negative option',
      () => [
        answer(questions[0], -1),
        ...questions.slice(1).map((x) => answer(x, 0)),
      ],
    ],
  ])('rejects %s', (_name, build) => {
    expect(() => gradeAnswers(questions, build(), 60)).toThrow(GradingError);
  });
});

describe('recommendationFor', () => {
  it('points at the weak topics when understanding is low', () => {
    const text = recommendationFor(
      { understanding: understandingFor(20), weakTopics: ['Widgets'] },
      'Flutter: quiz',
    );
    expect(text).toContain('Widgets');
    expect(text).toContain('Flutter: quiz');
  });

  it('suggests moving on when the material is mastered', () => {
    expect(
      recommendationFor(
        { understanding: understandingFor(100), weakTopics: [] },
        'x',
      ),
    ).toMatch(/next resource/i);
  });
});

describe('buildPerformance', () => {
  const scope = (
    over: Partial<Parameters<typeof buildPerformance>[0]['scopes'][number]>,
  ) => ({
    courseId: 'c1',
    courseTitle: 'Course 1',
    resourceId: null,
    attempts: 1,
    bestScore: 80,
    lastScore: 80,
    passed: true,
    lastAttemptAt: '2026-01-01T00:00:00.000Z',
    ...over,
  });
  const counts = [
    { courseId: 'c1', courseTitle: 'Course 1', quizzes: 4 },
    { courseId: 'c2', courseTitle: 'Course 2', quizzes: 3 },
  ];

  it('reports empty performance before any attempt', () => {
    const p = buildPerformance({
      scopes: [],
      weakTopics: [],
      courseQuizCounts: counts,
    });
    expect(p).toMatchObject({
      totalQuizzes: 7,
      quizzesAttempted: 0,
      quizzesPassed: 0,
      totalAttempts: 0,
      averageBestScore: null,
      understanding: null,
    });
    expect(p.courses.map((c) => c.quizzesAttempted)).toEqual([0, 0]);
  });

  it('averages best scores but judges understanding by the latest score', () => {
    const p = buildPerformance({
      scopes: [
        scope({
          resourceId: 'r1',
          attempts: 3,
          bestScore: 100,
          lastScore: 60,
          passed: true,
        }),
        scope({
          resourceId: 'r2',
          attempts: 1,
          bestScore: 40,
          lastScore: 40,
          passed: false,
        }),
      ],
      weakTopics: [
        { courseId: 'c1', topic: 'Navigation', misses: 1 },
        { courseId: 'c1', topic: 'State', misses: 2 },
      ],
      courseQuizCounts: counts,
    });
    expect(p).toMatchObject({
      quizzesAttempted: 2,
      quizzesPassed: 1,
      totalAttempts: 4,
      averageBestScore: 70,
    });
    expect(p.understanding?.level).toBe('needs_review'); // latest scores average 50
    expect(p.courses[0]).toMatchObject({
      quizzesAttempted: 2,
      quizzesPassed: 1,
      averageScore: 70,
      weakTopics: ['State', 'Navigation'],
    });
    expect(p.courses[1].quizzesAttempted).toBe(0);
    expect(p.scopes[0]).toMatchObject({
      resourceId: 'r1',
      bestScore: 100,
      lastScore: 60,
    });
    expect(p.scopes[0].understanding.level).toBe('developing');
  });
});