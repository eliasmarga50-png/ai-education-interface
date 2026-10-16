export const LEVELS = ['Beginner', 'Intermediate', 'Advanced'] as const;
export type Level = (typeof LEVELS)[number];

export const RESOURCE_TYPES = [
  'documentation',
  'tutorial',
  'video',
  'course',
  'article',
  'book',
  'interactive',
] as const;
export type ResourceType = (typeof RESOURCE_TYPES)[number];

export const COURSE_SORTS = ['position', 'title', 'rating'] as const;
export type CourseSort = (typeof COURSE_SORTS)[number];
export type SortOrder = 'asc' | 'desc';

export interface Course {
  id: string;
  slug: string;
  title: string;
  description: string;
  category: string;
  level: Level;
  lessonCount: number;
  rating: number | null;
  imageUrl: string | null;
  outcomes: string[];
  resourceCount: number;
  updatedAt: string;
}

export interface CourseResource {
  id: string;
  courseId: string;
  title: string;
  url: string;
  type: ResourceType;
  description: string;
  provider: string;
  language: string;
  difficulty: Level | null;
  position: number;
}

export interface PageMeta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export interface Page<T> {
  data: T[];
  meta: PageMeta;
}

export interface ListResult<T> {
  items: T[];
  total: number;
}

export interface CourseFilters {
  page: number;
  limit: number;
  category?: string;
  level?: Level;
  q?: string;
  sort: CourseSort;
  order: SortOrder;
}

export interface ResourceFilters {
  page: number;
  limit: number;
  type?: ResourceType;
  difficulty?: Level;
  language?: string;
}