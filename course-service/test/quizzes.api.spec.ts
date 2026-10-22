import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { createHash, randomUUID } from 'node:crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';
import { CoursesRepository } from '../src/courses/courses.repository';
import { DatabaseService } from '../src/database/database.service';
import { QuizzesRepository } from '../src/quizzes/quizzes.repository';
import { catalogFixtures } from './helpers/catalog-sources';
import { FakeCoursesRepository } from './helpers/fake-courses.repository';
import { FakeQuizzesRepository } from './helpers/fake-quizzes.repository';

process.env.DATABASE_URL = 'postgresql://test:test@localhost:5432/test';
process.env.THROTTLE_LIMIT = '1000';

const sha = (v: string) => createHash('sha256').update(v).digest('hex');
const SESSIONS: Record<string, string> = {
  [sha('token-ada')]: 'user-ada',
  [sha('token-bob')]: 'user-bob',
};

describe('Quizzes API', () => {
  let app: INestApplication;
  let store: FakeQuizzesRepository;
  const fixtures = catalogFixtures();
  const flutter = fixtures[0];
  const python = fixtures[1];

  beforeEach(async () => {
    store = new FakeQuizzesRepository(fixtures);
    const query = jest.fn(async (text: string, params: unknown[] = []) => ({
      rows:
        text.includes('FROM sessions') && SESSIONS[params[0] as string]
          ? [{ userId: SESSIONS[params[0] as string] }]
          : [],
    }));
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(DatabaseService)
      .useValue({ ping: jest.fn(), query })
      .overrideProvider(CoursesRepository)
      .useValue(new FakeCoursesRepository())
      .overrideProvider(QuizzesRepository)
      .useValue(store)
      .compile();
    app = moduleRef.createNestApplication();
    app.useLogger(false);
    configureApp(app);
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  const http = () => request(app.getHttpServer());
  const as = (token: string) => ({ Authorization: `Bearer ${token}` });
  const ada = as('token-ada');

  /** A student who knows (or does not know) the answers, using what the fake store really holds. */
  const answersFor = (
    quizId: string,
    pick: (correctIndex: number, optionCount: number) => number,
  ) => {
    const quiz = store.quizzes.find((q) => q.id === quizId)!;
    return quiz.questions.map((q) => ({
      questionId: q.id,
      selectedIndex: pick(q.correctIndex, q.options.length),
    }));
  };
  const allCorrect = (c: number) => c;
  const allWrong = (c: number, n: number) => (c + 1) % n;

  describe('authentication', () => {
    it.each([
      ['no token', {}],
      ['an unknown token', as('nope')],
      ['a non-bearer header', { Authorization: 'Basic abc' }],
    ])(
      'rejects %s with 401 UNAUTHORIZED (so the app refreshes its session)',
      async (_n, headers) => {
        const res = await http()
          .get(`/api/courses/${flutter.course.id}/quiz`)
          .set(headers)
          .expect(401);
        expect(res.body.error.code).toBe('UNAUTHORIZED');
      },
    );

    it('protects every quiz route', async () => {
      await http().get('/api/quizzes/performance').expect(401);
      await http().get(`/api/courses/${flutter.course.id}/quizzes`).expect(401);
      await http()
        .post(`/api/quizzes/${randomUUID()}/attempts`)
        .send({ answers: [] })
        .expect(401);
    });
  });

  describe('serving quizzes', () => {
    it('builds the course quiz from the catalogue and hides the answers', async () => {
      const res = await http()
        .get(`/api/courses/${flutter.course.id}/quiz`)
        .set(ada)
        .expect(200);
      const quiz = res.body.data;
      expect(quiz).toMatchObject({
        courseId: flutter.course.id,
        resourceId: null,
        scope: 'course',
        passingPercentage: 60,
      });
      expect(quiz.title).toContain(flutter.course.title);
      expect(quiz.questionCount).toBe(quiz.questions.length);
      expect(quiz.questions.length).toBeGreaterThanOrEqual(3);
      for (const q of quiz.questions) {
        expect(Object.keys(q).sort()).toEqual([
          'id',
          'options',
          'position',
          'prompt',
          'topic',
        ]);
      }
      expect(res.headers['cache-control']).toBe('private, no-store');
    });

    it('builds a quiz tied to one resource of the course', async () => {
      const resource = flutter.resources[1];
      const res = await http()
        .get(`/api/courses/${flutter.course.id}/resources/${resource.id}/quiz`)
        .set(ada)
        .expect(200);
      expect(res.body.data).toMatchObject({
        courseId: flutter.course.id,
        resourceId: resource.id,
        scope: 'resource',
      });
      expect(res.body.data.title).toContain(resource.title);
    });

    it('stores a quiz once and serves the same one every time', async () => {
      const first = await http()
        .get(`/api/courses/${flutter.course.id}/quiz`)
        .set(ada)
        .expect(200);
      const second = await http()
        .get(`/api/courses/${flutter.course.id}/quiz`)
        .set(as('token-bob'))
        .expect(200);
      expect(second.body.data.id).toBe(first.body.data.id);
      expect(second.body.data.questions).toEqual(first.body.data.questions);
      expect(store.quizzes).toHaveLength(1);

      const byId = await http()
        .get(`/api/quizzes/${first.body.data.id}`)
        .set(ada)
        .expect(200);
      expect(byId.body.data.questions).toEqual(first.body.data.questions);
    });

    it('makes a new quiz when the catalogue content changes, keeping the old one', async () => {
      const before = await http()
        .get(`/api/courses/${flutter.course.id}/quiz`)
        .set(ada)
        .expect(200);
      flutter.resources[0].description =
        'A brand new description that changes what this course contains.';
      try {
        const after = await http()
          .get(`/api/courses/${flutter.course.id}/quiz`)
          .set(ada)
          .expect(200);
        expect(after.body.data.id).not.toBe(before.body.data.id);
        expect(store.quizzes).toHaveLength(2);
        await http()
          .get(`/api/quizzes/${before.body.data.id}`)
          .set(ada)
          .expect(200);
      } finally {
        flutter.resources[0].description =
          catalogFixtures()[0].resources[0].description;
      }
    });

    it('answers 404 for an unknown course, a resource of another course, or an unknown quiz', async () => {
      const unknown = '99999999-9999-4999-8999-999999999999';
      await http().get(`/api/courses/${unknown}/quiz`).set(ada).expect(404);
      await http()
        .get(
          `/api/courses/${flutter.course.id}/resources/${python.resources[0].id}/quiz`,
        )
        .set(ada)
        .expect(404);
      const res = await http()
        .get(`/api/quizzes/${unknown}`)
        .set(ada)
        .expect(404);
      expect(res.body.error.code).toBe('NOT_FOUND');
    });

    it('answers 422 for a malformed id', async () => {
      const res = await http()
        .get('/api/courses/not-a-uuid/quiz')
        .set(ada)
        .expect(422);
      expect(res.body.error.code).toBe('VALIDATION_ERROR');
      await http().get('/api/quizzes/not-a-uuid').set(ada).expect(422);
    });

    it('lists the course quiz and one quiz per resource, with no results yet', async () => {
      const res = await http()
        .get(`/api/courses/${flutter.course.id}/quizzes`)
        .set(ada)
        .expect(200);
      const list = res.body.data;
      expect(list).toHaveLength(1 + flutter.resources.length);
      expect(list[0]).toMatchObject({
        scope: 'course',
        resourceId: null,
        stats: null,
      });
      expect(
        list.slice(1).map((q: { resourceId: string }) => q.resourceId),
      ).toEqual(flutter.resources.map((r) => r.id));
      expect(
        list.every((q: { questionCount: number }) => q.questionCount >= 3),
      ).toBe(true);
    });
  });

  describe('submitting answers', () => {
    const open = async (token = 'token-ada') => {
      const res = await http()
        .get(
          `/api/courses/${flutter.course.id}/resources/${flutter.resources[0].id}/quiz`,
        )
        .set(as(token))
        .expect(200);
      return res.body.data as { id: string; questions: { id: string }[] };
    };

    it('grades on the server, saves the attempt and returns a full review', async () => {
      const quiz = await open();
      const res = await http()
        .post(`/api/quizzes/${quiz.id}/attempts`)
        .set(ada)
        .send({ answers: answersFor(quiz.id, allCorrect), durationSeconds: 95 })
        .expect(201);

      const r = res.body.data;
      expect(r).toMatchObject({
        quizId: quiz.id,
        courseId: flutter.course.id,
        resourceId: flutter.resources[0].id,
        scorePercent: 100,
        passed: true,
        attemptNumber: 1,
        previousScore: null,
        bestScore: 100,
        weakTopics: [],
      });
      expect(r.understanding).toMatchObject({
        level: 'mastered',
        label: 'Mastered',
      });
      expect(r.review).toHaveLength(quiz.questions.length);
      expect(r.review[0]).toEqual(
        expect.objectContaining({
          isCorrect: true,
          correctIndex: expect.any(Number),
          explanation: expect.any(String),
        }),
      );
      expect(store.attempts).toHaveLength(1);
      expect(store.attempts[0]).toMatchObject({
        userId: 'user-ada',
        durationSeconds: 95,
      });
    });

    it('fails a quiz answered wrongly and says what to revisit', async () => {
      const quiz = await open();
      const res = await http()
        .post(`/api/quizzes/${quiz.id}/attempts`)
        .set(ada)
        .send({ answers: answersFor(quiz.id, allWrong) })
        .expect(201);
      expect(res.body.data).toMatchObject({
        scorePercent: 0,
        passed: false,
        correctCount: 0,
      });
      expect(res.body.data.understanding.level).toBe('needs_review');
      expect(res.body.data.weakTopics.length).toBeGreaterThan(0);
      expect(res.body.data.recommendation).toContain(
        res.body.data.weakTopics[0],
      );
    });

    it('tracks attempt number, previous score and best score across retakes', async () => {
      const quiz = await open();
      await http()
        .post(`/api/quizzes/${quiz.id}/attempts`)
        .set(ada)
        .send({ answers: answersFor(quiz.id, allCorrect) })
        .expect(201);
      const second = await http()
        .post(`/api/quizzes/${quiz.id}/attempts`)
        .set(ada)
        .send({ answers: answersFor(quiz.id, allWrong) })
        .expect(201);
      expect(second.body.data).toMatchObject({
        attemptNumber: 2,
        previousScore: 100,
        scorePercent: 0,
        bestScore: 100,
      });

      const history = await http()
        .get(`/api/quizzes/${quiz.id}/attempts`)
        .set(ada)
        .expect(200);
      expect(
        history.body.data.map((a: { scorePercent: number }) => a.scorePercent),
      ).toEqual([0, 100]);
    });

    it("keeps each student's results separate", async () => {
      const quiz = await open();
      await http()
        .post(`/api/quizzes/${quiz.id}/attempts`)
        .set(ada)
        .send({ answers: answersFor(quiz.id, allCorrect) })
        .expect(201);

      const bobHistory = await http()
        .get(`/api/quizzes/${quiz.id}/attempts`)
        .set(as('token-bob'))
        .expect(200);
      expect(bobHistory.body.data).toEqual([]);
      const bobPerformance = await http()
        .get('/api/quizzes/performance')
        .set(as('token-bob'))
        .expect(200);
      expect(bobPerformance.body.data).toMatchObject({
        quizzesAttempted: 0,
        totalAttempts: 0,
        averageBestScore: null,
        understanding: null,
      });
    });

    it.each([
      [
        'a missing answer',
        (q: { id: string }[]) =>
          q.slice(1).map((x) => ({ questionId: x.id, selectedIndex: 0 })),
      ],
      [
        'a duplicated answer',
        (q: { id: string }[]) => [
          { questionId: q[0].id, selectedIndex: 0 },
          ...q.map((x) => ({ questionId: x.id, selectedIndex: 0 })),
        ],
      ],
      [
        'a question from elsewhere',
        (q: { id: string }[]) => [
          ...q.slice(1).map((x) => ({ questionId: x.id, selectedIndex: 0 })),
          { questionId: randomUUID(), selectedIndex: 0 },
        ],
      ],
      [
        'an option that does not exist',
        (q: { id: string }[]) =>
          q.map((x) => ({ questionId: x.id, selectedIndex: 5 })),
      ],
    ])('rejects %s with 422 and saves nothing', async (_n, build) => {
      const quiz = await open();
      const res = await http()
        .post(`/api/quizzes/${quiz.id}/attempts`)
        .set(ada)
        .send({ answers: build(quiz.questions) })
        .expect(422);
      expect(res.body.error.code).toBe('VALIDATION_ERROR');
      expect(res.body.error.fields).toHaveProperty('answers');
      expect(store.attempts).toHaveLength(0);
    });

    it.each([
      ['no answers', {}],
      ['an empty list', { answers: [] }],
      [
        'a text index',
        { answers: [{ questionId: randomUUID(), selectedIndex: 'A' }] },
      ],
      [
        'a bad question id',
        { answers: [{ questionId: 'nope', selectedIndex: 0 }] },
      ],
      [
        'an unknown field',
        {
          answers: [{ questionId: randomUUID(), selectedIndex: 0 }],
          score: 100,
        },
      ],
    ])('rejects a body with %s', async (_n, body) => {
      const quiz = await open();
      const res = await http()
        .post(`/api/quizzes/${quiz.id}/attempts`)
        .set(ada)
        .send(body)
        .expect(422);
      expect(res.body.error.code).toBe('VALIDATION_ERROR');
    });

    it('answers 404 when the quiz does not exist', async () => {
      await http()
        .post(`/api/quizzes/${randomUUID()}/attempts`)
        .set(ada)
        .send({ answers: [{ questionId: randomUUID(), selectedIndex: 0 }] })
        .expect(404);
    });
  });

  describe('performance', () => {
    it('summarises scores, understanding and weak topics per course and per quiz', async () => {
      const course = (
        await http()
          .get(`/api/courses/${flutter.course.id}/quiz`)
          .set(ada)
          .expect(200)
      ).body.data;
      const resource = (
        await http()
          .get(
            `/api/courses/${flutter.course.id}/resources/${flutter.resources[0].id}/quiz`,
          )
          .set(ada)
          .expect(200)
      ).body.data;

      await http()
        .post(`/api/quizzes/${course.id}/attempts`)
        .set(ada)
        .send({ answers: answersFor(course.id, allCorrect) })
        .expect(201);
      await http()
        .post(`/api/quizzes/${resource.id}/attempts`)
        .set(ada)
        .send({ answers: answersFor(resource.id, allWrong) })
        .expect(201);

      const res = await http()
        .get('/api/quizzes/performance')
        .set(ada)
        .expect(200);
      const p = res.body.data;
      expect(p).toMatchObject({
        quizzesAttempted: 2,
        quizzesPassed: 1,
        totalAttempts: 2,
        averageBestScore: 50,
        totalQuizzes: fixtures.reduce((n, f) => n + 1 + f.resources.length, 0),
      });
      expect(p.understanding.level).toBe('needs_review');

      const flutterRow = p.courses.find(
        (c: { courseId: string }) => c.courseId === flutter.course.id,
      );
      expect(flutterRow).toMatchObject({
        quizzesAttempted: 2,
        quizzesPassed: 1,
        averageScore: 50,
      });
      expect(flutterRow.weakTopics.length).toBeGreaterThan(0);
      expect(
        p.courses.find(
          (c: { courseId: string }) => c.courseId === python.course.id,
        ).quizzesAttempted,
      ).toBe(0);

      expect(p.scopes).toHaveLength(2);
      expect(
        p.scopes.find(
          (s: { resourceId: string | null }) => s.resourceId === null,
        ),
      ).toMatchObject({ bestScore: 100, lastScore: 100, passed: true });
    });

    it('shows the results next to each quiz in the course list', async () => {
      const resource = (
        await http()
          .get(
            `/api/courses/${flutter.course.id}/resources/${flutter.resources[2].id}/quiz`,
          )
          .set(ada)
          .expect(200)
      ).body.data;
      await http()
        .post(`/api/quizzes/${resource.id}/attempts`)
        .set(ada)
        .send({ answers: answersFor(resource.id, allCorrect) })
        .expect(201);

      const res = await http()
        .get(`/api/courses/${flutter.course.id}/quizzes`)
        .set(ada)
        .expect(200);
      const row = res.body.data.find(
        (q: { resourceId: string | null }) =>
          q.resourceId === flutter.resources[2].id,
      );
      expect(row.stats).toMatchObject({
        attempts: 1,
        bestScore: 100,
        lastScore: 100,
        passed: true,
      });
      expect(row.stats.understanding.level).toBe('mastered');
      expect(
        res.body.data.find(
          (q: { resourceId: string | null }) => q.resourceId === null,
        ).stats,
      ).toBeNull();
    });
  });
});