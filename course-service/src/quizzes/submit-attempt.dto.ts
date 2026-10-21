import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsInt,
  IsOptional,
  IsUUID,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';

export class AnswerDto {
  @IsUUID('all', { message: 'questionId must be a valid id' })
  questionId!: string;

  /** Position of the chosen option in the options list the quiz was served with. */
  @IsInt({ message: 'selectedIndex must be a whole number' })
  @Min(0)
  @Max(5)
  selectedIndex!: number;
}

export class SubmitAttemptDto {
  @IsArray()
  @ArrayMinSize(1, { message: 'Answer every question before submitting.' })
  @ArrayMaxSize(20)
  @ValidateNested({ each: true })
  @Type(() => AnswerDto)
  answers!: AnswerDto[];

  /** How long the student spent, in seconds. Optional; only stored. */
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(86_400)
  durationSeconds?: number;
}