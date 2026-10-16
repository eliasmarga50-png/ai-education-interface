import { IsIn, IsOptional, Matches } from 'class-validator';
import { LEVELS, Level, RESOURCE_TYPES, ResourceType } from '../courses.types';
import { PaginationQueryDto } from './pagination-query.dto';

export class ListResourcesQueryDto extends PaginationQueryDto {
  @IsOptional()
  @IsIn(RESOURCE_TYPES)
  type?: ResourceType;

  @IsOptional()
  @IsIn(LEVELS)
  difficulty?: Level;

  @IsOptional()
  @Matches(/^[a-z]{2,3}(-[A-Za-z0-9]{2,8})?$/, { message: 'language must be a code such as "en" or "pt-BR"' })
  language?: string;
}