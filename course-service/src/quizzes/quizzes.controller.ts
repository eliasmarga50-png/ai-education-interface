import {
  Body,
  Controller,
  Get,
  Header,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Post,
  UnprocessableEntityException,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { AuthGuard, AuthUser, CurrentUser } from '../auth/auth.guard';
import { SubmitAttemptDto } from './dto/submit-attempt.dto';
import { QuizzesService } from './quizzes.service';

const uuid = (field: string) =>
  new ParseUUIDPipe({
    exceptionFactory: () =>
      new UnprocessableEntityException({
        message: `The ${field} must be a valid UUID.`,
        fields: { [field]: `The ${field} must be a valid UUID.` },
      }),
  });

const COURSE_ID = uuid('courseId');
const RESOURCE_ID = uuid('resourceId');
const QUIZ_ID = uuid('quizId');

/** Results belong to one student, so nothing here may be cached by a shared proxy. */
const PRIVATE = 'private, no-store';

@Controller()
@UseGuards(AuthGuard)
export class QuizzesController {
  constructor(private readonly quizzes: QuizzesService) {}

  /** All quizzes of a course (course quiz + one per resource) with the student's results. */
  @Get('courses/:courseId/quizzes')
  @Header('Cache-Control', PRIVATE)
  async listForCourse(
    @CurrentUser() user: AuthUser,
    @Param('courseId', COURSE_ID) courseId: string,
  ) {
    return { data: await this.quizzes.listForCourse(user.id, courseId) };
  }

  @Get('courses/:courseId/quiz')
  @Header('Cache-Control', PRIVATE)
  async courseQuiz(@Param('courseId', COURSE_ID) courseId: string) {
    return { data: await this.quizzes.getCourseQuiz(courseId) };
  }

  @Get('courses/:courseId/resources/:resourceId/quiz')
  @Header('Cache-Control', PRIVATE)
  async resourceQuiz(
    @Param('courseId', COURSE_ID) courseId: string,
    @Param('resourceId', RESOURCE_ID) resourceId: string,
  ) {
    return { data: await this.quizzes.getResourceQuiz(courseId, resourceId) };
  }

  // Declared before ':quizId' so "performance" is not read as a quiz id.
  @Get('quizzes/performance')
  @Header('Cache-Control', PRIVATE)
  async performance(@CurrentUser() user: AuthUser) {
    return { data: await this.quizzes.performance(user.id) };
  }

  @Get('quizzes/:quizId')
  @Header('Cache-Control', PRIVATE)
  async quiz(@Param('quizId', QUIZ_ID) quizId: string) {
    return { data: await this.quizzes.getQuiz(quizId) };
  }

  @Get('quizzes/:quizId/attempts')
  @Header('Cache-Control', PRIVATE)
  async attempts(
    @CurrentUser() user: AuthUser,
    @Param('quizId', QUIZ_ID) quizId: string,
  ) {
    return { data: await this.quizzes.listAttempts(user.id, quizId) };
  }

  @Post('quizzes/:quizId/attempts')
  @HttpCode(201)
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  async submit(
    @CurrentUser() user: AuthUser,
    @Param('quizId', QUIZ_ID) quizId: string,
    @Body() body: SubmitAttemptDto,
  ) {
    return { data: await this.quizzes.submitAttempt(user.id, quizId, body) };
  }
}