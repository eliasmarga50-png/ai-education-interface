import {
  Course,
  CourseFilters,
  CourseResource,
  ListResult,
  ResourceFilters,
} from '../../src/courses/courses.types';

export const IDS = {
  flutter: '11111111-1111-4111-8111-111111111111',
  python: '22222222-2222-4222-8222-222222222222',
  design: '33333333-3333-4333-8333-333333333333',
  unknown: '99999999-9999-4999-8999-999999999999',
};

const course = (over: Partial<Course> & Pick<Course, 'id' | 'slug' | 'title'>): Course => ({
  description: 'A course.',
  category: 'Programming',
  level: 'Beginner',
  lessonCount: 10,
  rating: 4.5,
  imageUrl: null,
  outcomes: [],
  resourceCount: 0,
  updatedAt: '2026-01-01T00:00:00.000Z',
  ...over,
});

const COURSES: Course[] = [
  course({ id: IDS.flutter, slug: 'flutter', title: 'Flutter Development', description: 'Build apps.', rating: 4.9, resourceCount: 3 }),
  course({ id: IDS.python, slug: 'python', title: 'Python Programming', description: 'Learn Python.', rating: 4.8 }),
  course({ id: IDS.design, slug: 'design', title: 'UI/UX Design', category: 'Design', level: 'Intermediate', rating: 4.7 }),
];

const resource = (n: number, over: Partial<CourseResource>): CourseResource => ({
  id: `00000000-0000-4000-8000-00000000000${n}`,
  courseId: IDS.flutter,
  title: `Resource ${n}`,
  url: `https://docs.example.org/${n}`,
  type: 'documentation',
  description: 'A resource.',
  provider: 'Docs',
  language: 'en',
  difficulty: 'Beginner',
  position: n,
  ...over,
});

const RESOURCES: CourseResource[] = [
  resource(1, {}),
  resource(2, { type: 'video' }),
  resource(3, { difficulty: 'Advanced' }),
];

const page = <T>(items: T[], f: { page: number; limit: number }): ListResult<T> => ({
  items: items.slice((f.page - 1) * f.limit, f.page * f.limit),
  total: items.length,
});

/** Stands in for the SQL repository so the HTTP layer, validation and service are tested without a database. */
export class FakeCoursesRepository {
  async findMany(f: CourseFilters): Promise<ListResult<Course>> {
    let rows = COURSES.filter(
      (c) =>
        (!f.category || c.category.toLowerCase() === f.category.toLowerCase()) &&
        (!f.level || c.level === f.level) &&
        (!f.q || `${c.title} ${c.description}`.toLowerCase().includes(f.q.toLowerCase())),
    );
    const key = f.sort === 'title' ? 'title' : f.sort === 'rating' ? 'rating' : null;
    if (key) {
      rows = [...rows].sort((a, b) => String(a[key]).localeCompare(String(b[key]), undefined, { numeric: true }));
      if (f.order === 'desc') rows.reverse();
    }
    return page(rows, f);
  }

  async findById(id: string): Promise<Course | null> {
    return COURSES.find((c) => c.id === id) ?? null;
  }

  async exists(id: string): Promise<boolean> {
    return COURSES.some((c) => c.id === id);
  }

  async findResources(_courseId: string, f: ResourceFilters): Promise<ListResult<CourseResource>> {
    const rows = RESOURCES.filter((r) => (!f.type || r.type === f.type) && (!f.difficulty || r.difficulty === f.difficulty));
    return page(rows, f);
  }
}