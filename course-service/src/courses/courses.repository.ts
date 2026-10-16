import { Injectable } from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import {
  Course,
  CourseFilters,
  CourseResource,
  CourseSort,
  ListResult,
  ResourceFilters,
} from './courses.types';

const COURSE_COLUMNS = `
  c.id, c.slug, c.title, c.description, c.category, c.level,
  c.lesson_count AS "lessonCount", c.rating::float8 AS rating, c.image_url AS "imageUrl",
  c.outcomes, c.updated_at AS "updatedAt",
  (SELECT count(*)::int FROM course_resources r WHERE r.course_id = c.id) AS "resourceCount"`;

const SORT_COLUMNS: Record<CourseSort, string> = {
  position: 'c.position',
  title: 'lower(c.title)',
  rating: 'c.rating',
};

type CourseRow = Omit<Course, 'updatedAt'> & { updatedAt: Date; total?: number };
type ResourceRow = CourseResource & { total?: number };

export function escapeLike(value: string): string {
  return value.replace(/[\\%_]/g, '\\$&');
}

function toCourse(row: CourseRow): Course {
  return {
    id: row.id,
    slug: row.slug,
    title: row.title,
    description: row.description,
    category: row.category,
    level: row.level,
    lessonCount: row.lessonCount,
    rating: row.rating,
    imageUrl: row.imageUrl,
    outcomes: row.outcomes,
    resourceCount: row.resourceCount,
    updatedAt: row.updatedAt.toISOString(),
  };
}

function toResource(row: ResourceRow): CourseResource {
  return {
    id: row.id,
    courseId: row.courseId,
    title: row.title,
    url: row.url,
    type: row.type,
    description: row.description,
    provider: row.provider,
    language: row.language,
    difficulty: row.difficulty,
    position: row.position,
  };
}

@Injectable()
export class CoursesRepository {
  constructor(private readonly db: DatabaseService) {}

  async findMany(f: CourseFilters): Promise<ListResult<Course>> {
    const where = ['c.is_published = TRUE'];
    const params: unknown[] = [];

    if (f.category) {
      params.push(f.category);
      where.push(`lower(c.category) = lower($${params.length})`);
    }
    if (f.level) {
      params.push(f.level);
      where.push(`c.level = $${params.length}`);
    }
    if (f.q) {
      params.push(`%${escapeLike(f.q)}%`);
      where.push(`(c.title ILIKE $${params.length} OR c.description ILIKE $${params.length})`);
    }
    const whereSql = where.join(' AND ');

    const direction = f.order === 'desc' ? 'DESC' : 'ASC';
    const nulls = f.sort === 'rating' ? ' NULLS LAST' : '';
    const orderBy = `${SORT_COLUMNS[f.sort]} ${direction}${nulls}, c.position ASC, c.id ASC`;

    const filterParams = [...params];
    params.push(f.limit, (f.page - 1) * f.limit);

    const { rows } = await this.db.query<CourseRow>(
      `SELECT ${COURSE_COLUMNS}, count(*) OVER()::int AS total
         FROM courses c
        WHERE ${whereSql}
        ORDER BY ${orderBy}
        LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params,
    );

    let total = rows[0]?.total ?? 0;
    if (rows.length === 0 && f.page > 1) {
      // Page past the end: the window count has no rows to ride on.
      const counted = await this.db.query<{ total: number }>(
        `SELECT count(*)::int AS total FROM courses c WHERE ${whereSql}`,
        filterParams,
      );
      total = counted.rows[0].total;
    }
    return { items: rows.map(toCourse), total };
  }

  async findById(id: string): Promise<Course | null> {
    const { rows } = await this.db.query<CourseRow>(
      `SELECT ${COURSE_COLUMNS} FROM courses c WHERE c.id = $1 AND c.is_published = TRUE`,
      [id],
    );
    return rows[0] ? toCourse(rows[0]) : null;
  }

  async exists(id: string): Promise<boolean> {
    const { rowCount } = await this.db.query(
      'SELECT 1 FROM courses WHERE id = $1 AND is_published = TRUE',
      [id],
    );
    return (rowCount ?? 0) > 0;
  }

  async findResources(courseId: string, f: ResourceFilters): Promise<ListResult<CourseResource>> {
    const where = ['r.course_id = $1'];
    const params: unknown[] = [courseId];

    if (f.type) {
      params.push(f.type);
      where.push(`r.type = $${params.length}`);
    }
    if (f.difficulty) {
      params.push(f.difficulty);
      where.push(`r.difficulty = $${params.length}`);
    }
    if (f.language) {
      params.push(f.language);
      where.push(`r.language = $${params.length}`);
    }
    const whereSql = where.join(' AND ');

    const filterParams = [...params];
    params.push(f.limit, (f.page - 1) * f.limit);

    const { rows } = await this.db.query<ResourceRow>(
      `SELECT r.id, r.course_id AS "courseId", r.title, r.url, r.type, r.description,
              r.provider, r.language, r.difficulty, r.position, count(*) OVER()::int AS total
         FROM course_resources r
        WHERE ${whereSql}
        ORDER BY r.position ASC, r.id ASC
        LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params,
    );

    let total = rows[0]?.total ?? 0;
    if (rows.length === 0 && f.page > 1) {
      const counted = await this.db.query<{ total: number }>(
        `SELECT count(*)::int AS total FROM course_resources r WHERE ${whereSql}`,
        filterParams,
      );
      total = counted.rows[0].total;
    }
    return { items: rows.map(toResource), total };
  }
}