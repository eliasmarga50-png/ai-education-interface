import { Module } from '@nestjs/common';
import { AuthGuard } from '../auth/auth.guard';
import { QuizzesController } from './quizzes.controller';
import { QuizzesRepository } from './quizzes.repository';
import { QuizzesService } from './quizzes.service';

@Module({
  controllers: [QuizzesController],
  providers: [QuizzesService, QuizzesRepository, AuthGuard],
})
export class QuizzesModule {}