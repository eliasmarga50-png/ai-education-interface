import {
  Controller,
  Get,
  Header,
  Param,
  ParseUUIDPipe,
  Query,
  UnprocessableEntityException,
} from '@nestjs/common';
import { CoursesService } from './courses.service';
import { ListCoursesQueryDto } from './dto/list-courses-query.dto';
import { ListResourcesQueryDto } from './dto/list-resources-query.dto';

const COURSE_ID = new ParseUUIDPipe({
  exceptionFactory: () =>
    new UnprocessableEntityException({
      message: 'The course id must be a valid UUID.',
      fields: { id: 'The course id must be a valid UUID.' },
    }),
});

const CACHE = 'public, max-age=60';

@Controller('courses')
export class CoursesController {
  constructor(private readonly courses: CoursesService) {}

  @Get()
  @Header('Cache-Control', CACHE)
  list(@Query() query: ListCoursesQueryDto) {
    return this.courses.list(query);
  }

  @Get(':id')
  @Header('Cache-Control', CACHE)
  async get(@Param('id', COURSE_ID) id: string) {
    return { data: await this.courses.get(id) };
  }

  @Get(':id/resources')
  @Header('Cache-Control', CACHE)
  listResources(@Param('id', COURSE_ID) id: string, @Query() query: ListResourcesQueryDto) {
    return this.courses.listResources(id, query);
  }
}