import { Transform } from 'class-transformer';
import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';
import { COURSE_SORTS, CourseSort, LEVELS, Level, SortOrder } from '../courses.types';
import { PaginationQueryDto } from './pagination-query.dto';

export class ListCoursesQueryDto extends PaginationQueryDto {
  @IsOptional()
  @IsString()
  @MaxLength(60)
  category?: string;

  @IsOptional()
  @IsIn(LEVELS)
  level?: Level;

  /** Case-insensitive search in title and description. */
  @IsOptional()
  @Transform(({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MaxLength(100)
  q?: string;

  @IsOptional()
  @IsIn(COURSE_SORTS)
  sort: CourseSort = 'position';

  @IsOptional()
  @IsIn(['asc', 'desc'])
  order: SortOrder = 'asc';
}