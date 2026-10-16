import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';
import { CoursesRepository } from '../src/courses/courses.repository';
import { DatabaseService } from '../src/database/database.service';
import { FakeCoursesRepository, IDS } from './helpers/fake-courses.repository';

process.env.DATABASE_URL = 'postgresql://test:test@localhost:5432/test';
process.env.THROTTLE_LIMIT = '1000';

describe('Courses API', () => {
  let app: INestApplication;
  const ping = jest.fn();

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(DatabaseService)
      .useValue({ ping, query: jest.fn() })
      .overrideProvider(CoursesRepository)
      .useValue(new FakeCoursesRepository())
      .compile();

    app = moduleRef.createNestApplication();
    app.useLogger(false);
    configureApp(app);
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  const http = () => request(app.getHttpServer());

  describe('GET /api/courses', () => {
    it('lists courses with pagination metadata and a cache header', async () => {
      const res = await http().get('/api/courses').expect(200);
      expect(res.body.data).toHaveLength(3);
      expect(res.body.meta).toEqual({ page: 1, limit: 20, total: 3, totalPages: 1 });
      expect(res.headers['cache-control']).toBe('public, max-age=60');
    });

    it('paginates', async () => {
      const res = await http().get('/api/courses?limit=2&page=2').expect(200);
      expect(res.body.data).toHaveLength(1);
      expect(res.body.meta).toEqual({ page: 2, limit: 2, total: 3, totalPages: 2 });
    });

    it('filters by category (case-insensitive), level and search text', async () => {
      const byCategory = await http().get('/api/courses?category=design').expect(200);
      expect(byCategory.body.data.map((c: { slug: string }) => c.slug)).toEqual(['design']);

      const byLevel = await http().get('/api/courses?level=Intermediate').expect(200);
      expect(byLevel.body.meta.total).toBe(1);

      const bySearch = await http().get('/api/courses?q=python').expect(200);
      expect(bySearch.body.data[0].slug).toBe('python');
    });

    it('sorts', async () => {
      const res = await http().get('/api/courses?sort=title&order=desc').expect(200);
      expect(res.body.data.map((c: { title: string }) => c.title)).toEqual([
        'UI/UX Design',
        'Python Programming',
        'Flutter Development',
      ]);
    });

    it.each([
      ['limit above the maximum', '?limit=500', 'limit'],
      ['non-numeric page', '?page=abc', 'page'],
      ['unknown level', '?level=Expert', 'level'],
      ['unknown sort', '?sort=price', 'sort'],
      ['unknown parameter', '?foo=1', 'foo'],
    ])('rejects %s with 422 and field details', async (_name, query, field) => {
      const res = await http().get(`/api/courses${query}`).expect(422);
      expect(res.body.error.code).toBe('VALIDATION_ERROR');
      expect(typeof res.body.error.message).toBe('string');
      expect(res.body.error.fields).toHaveProperty(field);
    });
  });

  describe('GET /api/courses/:id', () => {
    it('returns the course', async () => {
      const res = await http().get(`/api/courses/${IDS.flutter}`).expect(200);
      expect(res.body.data).toMatchObject({ id: IDS.flutter, title: 'Flutter Development', lessonCount: 10 });
    });

    it('returns 404 for an unknown course', async () => {
      const res = await http().get(`/api/courses/${IDS.unknown}`).expect(404);
      expect(res.body.error.code).toBe('NOT_FOUND');
    });

    it('returns 422 for a malformed id', async () => {
      const res = await http().get('/api/courses/not-a-uuid').expect(422);
      expect(res.body.error.code).toBe('VALIDATION_ERROR');
    });
  });

  describe('GET /api/courses/:id/resources', () => {
    it('lists resources in order', async () => {
      const res = await http().get(`/api/courses/${IDS.flutter}/resources`).expect(200);
      expect(res.body.data.map((r: { title: string }) => r.title)).toEqual(['Resource 1', 'Resource 2', 'Resource 3']);
      expect(res.body.meta.total).toBe(3);
      expect(res.body.data[0]).toEqual(
        expect.objectContaining({ title: 'Resource 1', url: 'https://docs.example.org/1', provider: 'Docs', type: 'documentation' }),
      );
    });

    it('filters by type and difficulty', async () => {
      const videos = await http().get(`/api/courses/${IDS.flutter}/resources?type=video`).expect(200);
      expect(videos.body.data).toHaveLength(1);

      const advanced = await http().get(`/api/courses/${IDS.flutter}/resources?difficulty=Advanced`).expect(200);
      expect(advanced.body.data[0].title).toBe('Resource 3');
    });

    it('rejects an unknown type', async () => {
      await http().get(`/api/courses/${IDS.flutter}/resources?type=podcast`).expect(422);
    });

    it('returns 404 when the course does not exist', async () => {
      const res = await http().get(`/api/courses/${IDS.unknown}/resources`).expect(404);
      expect(res.body.error.code).toBe('NOT_FOUND');
    });
  });

  describe('platform', () => {
    it('reports healthy when the database answers', async () => {
      ping.mockResolvedValueOnce(undefined);
      const res = await http().get('/health').expect(200);
      expect(res.body).toEqual({ status: 'ok' });
    });

    it('reports 503 when the database is down', async () => {
      ping.mockRejectedValueOnce(new Error('down'));
      const res = await http().get('/health').expect(503);
      expect(res.body.error.code).toBe('SERVICE_UNAVAILABLE');
    });

    it('answers unknown routes with the same error envelope', async () => {
      const res = await http().get('/api/nope').expect(404);
      expect(res.body.error.code).toBe('NOT_FOUND');
    });
  });
});