import { Injectable, NotFoundException } from '@nestjs/common';
import { ListCoursesQueryDto } from './dto/list-courses-query.dto';
import { ListResourcesQueryDto } from './dto/list-resources-query.dto';
import { CoursesRepository } from './courses.repository';
import { Course, CourseResource, ListResult, Page } from './courses.types';

function toPage<T>(result: ListResult<T>, page: number, limit: number): Page<T> {
  return {
    data: result.items,
    meta: { page, limit, total: result.total, totalPages: Math.max(1, Math.ceil(result.total / limit)) },
  };
}

@Injectable()
export class CoursesService {
  constructor(private readonly repo: CoursesRepository) {}

  async list(query: ListCoursesQueryDto): Promise<Page<Course>> {
    const result = await this.repo.findMany({
      page: query.page,
      limit: query.limit,
      category: query.category,
      level: query.level,
      q: query.q || undefined,
      sort: query.sort,
      order: query.order,
    });
    return toPage(result, query.page, query.limit);
  }

  async get(id: string): Promise<Course> {
    const course = await this.repo.findById(id);
    if (!course) throw new NotFoundException(`Course ${id} was not found.`);
    return course;
  }

  async listResources(courseId: string, query: ListResourcesQueryDto): Promise<Page<CourseResource>> {
    if (!(await this.repo.exists(courseId))) {
      throw new NotFoundException(`Course ${courseId} was not found.`);
    }
    const result = await this.repo.findResources(courseId, {
      page: query.page,
      limit: query.limit,
      type: query.type,
      difficulty: query.difficulty,
      language: query.language,
    });
    return toPage(result, query.page, query.limit);
  }
}