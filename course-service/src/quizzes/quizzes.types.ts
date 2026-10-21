import { Level, ResourceType } from '../courses/courses.types';

export const UNDERSTANDING_LEVELS = [
  'mastered',
  'proficient',
  'developing',
  'needs_review',
] as const;
export type UnderstandingLevel = (typeof UNDERSTANDING_LEVELS)[number];

export interface Understanding {
  level: UnderstandingLevel;
  label: string;
  message: string;
}

export const PASSING_PERCENTAGE = 60;

/** Stored question, including the answer. Never sent to a student before they submit. */
export interface StoredQuestion {
  id: string;
  position: number;
  kind: string;
  prompt: string;
  options: string[];
  correctIndex: number;
  explanation: string;
  topic: string;
}

export interface StoredQuiz {
  id: string;
  courseId: string;
  resourceId: string | null;
  title: string;
  description: string;
  passingPercentage: number;
  generator: string;
  sourceHash: string;
  createdAt: string;
  questions: StoredQuestion[];
}

/** What a student receives: the quiz without the answers. */
export interface PublicQuestion {
  id: string;
  position: number;
  prompt: string;
  options: string[];
  topic: string;
}

export interface PublicQuiz {
  id: string;
  courseId: string;
  resourceId: string | null;
  scope: 'course' | 'resource';
  title: string;
  description: string;
  passingPercentage: number;
  questionCount: number;
  createdAt: string;
  questions: PublicQuestion[];
}

export interface QuizStats {
  attempts: number;
  bestScore: number;
  lastScore: number;
  passed: boolean;
  understanding: Understanding;
  lastAttemptAt: string;
}

export interface QuizSummary {
  id: string;
  courseId: string;
  resourceId: string | null;
  scope: 'course' | 'resource';
  title: string;
  description: string;
  questionCount: number;
  passingPercentage: number;
  stats: QuizStats | null;
}

/** A question as generated, before it is stored (no id yet). */
export interface GeneratedQuestion {
  kind: string;
  prompt: string;
  options: string[];
  correctIndex: number;
  explanation: string;
  topic: string;
}

export interface GeneratedQuiz {
  title: string;
  description: string;
  questions: GeneratedQuestion[];
}

/** Everything the generator may read. Built from the database, so nothing here is hard-coded. */
export interface GeneratorCourse {
  id: string;
  title: string;
  description: string;
  category: string;
  level: Level;
  outcomes: string[];
}

export interface GeneratorResource {
  id: string;
  courseId: string;
  title: string;
  type: ResourceType;
  description: string;
  provider: string;
  difficulty: Level | null;
}

export interface GeneratorSource {
  course: GeneratorCourse;
  /** All resources of [course], in display order. */
  resources: GeneratorResource[];
  /** The resource the quiz is about; null for a course-level quiz. */
  target: GeneratorResource | null;
  /** Other published courses, used for wrong answers. */
  otherCourses: GeneratorCourse[];
  /** Resources of other courses, used for wrong answers. */
  otherResources: GeneratorResource[];
}

export interface AnswerInput {
  questionId: string;
  selectedIndex: number;
}

export interface ReviewItem {
  questionId: string;
  prompt: string;
  options: string[];
  selectedIndex: number;
  correctIndex: number;
  isCorrect: boolean;
  explanation: string;
  topic: string;
}

export interface GradedAnswer {
  questionId: string;
  selectedIndex: number;
  isCorrect: boolean;
}

export interface GradeResult {
  totalQuestions: number;
  correctCount: number;
  scorePercent: number;
  passed: boolean;
  understanding: Understanding;
  answers: GradedAnswer[];
  review: ReviewItem[];
  weakTopics: string[];
}

export interface AttemptResult extends Omit<GradeResult, 'answers'> {
  attemptId: string;
  quizId: string;
  courseId: string;
  resourceId: string | null;
  passingPercentage: number;
  attemptNumber: number;
  previousScore: number | null;
  bestScore: number;
  recommendation: string;
  submittedAt: string;
}

export interface AttemptSummary {
  attemptId: string;
  scorePercent: number;
  correctCount: number;
  totalQuestions: number;
  passed: boolean;
  understanding: Understanding;
  durationSeconds: number | null;
  submittedAt: string;
}

/** One row per (course, resource) the student has attempted. */
export interface ScopeStatsRow {
  courseId: string;
  courseTitle: string;
  resourceId: string | null;
  attempts: number;
  bestScore: number;
  lastScore: number;
  passed: boolean;
  lastAttemptAt: string;
}

export interface WeakTopicRow {
  courseId: string;
  topic: string;
  misses: number;
}

export interface ScopePerformance {
  courseId: string;
  resourceId: string | null;
  attempts: number;
  bestScore: number;
  lastScore: number;
  passed: boolean;
  understanding: Understanding;
  lastAttemptAt: string;
}

export interface CoursePerformance {
  courseId: string;
  courseTitle: string;
  quizzesAvailable: number;
  quizzesAttempted: number;
  quizzesPassed: number;
  averageScore: number;
  understanding: Understanding;
  weakTopics: string[];
}

export interface Performance {
  totalQuizzes: number;
  quizzesAttempted: number;
  quizzesPassed: number;
  totalAttempts: number;
  /** Average of the best score on every quiz the student has attempted. */
  averageBestScore: number | null;
  /** Based on the latest score of every attempted quiz: how well they understand the material now. */
  understanding: Understanding | null;
  courses: CoursePerformance[];
  scopes: ScopePerformance[];
}