import { CATALOG } from '../../src/catalog/catalog.data';
import {
  GeneratorCourse,
  GeneratorResource,
  GeneratorSource,
} from '../../src/quizzes/quizzes.types';

/** Stable UUID-shaped ids so fixtures can be sent through the validated HTTP API. */
export const uuid = (kind: 'c' | 'r', n: number): string =>
  `${kind === 'c' ? 'cccccccc' : 'rrrrrrrr'.replace(/r/g, 'a')}-0000-4000-8000-${String(n).padStart(12, '0')}`;

export interface CatalogFixture {
  course: GeneratorCourse;
  resources: GeneratorResource[];
}

/** The real catalogue (src/catalog/catalog.data.ts) as the generator sees it after loading from the database. */
export function catalogFixtures(): CatalogFixture[] {
  let r = 0;
  return CATALOG.map((c, i) => {
    const course: GeneratorCourse = {
      id: uuid('c', i + 1),
      title: c.title,
      description: c.description,
      category: c.category,
      level: c.level,
      outcomes: c.outcomes,
    };
    const resources: GeneratorResource[] = c.resources.map((x) => ({
      id: uuid('r', ++r),
      courseId: course.id,
      title: x.title,
      type: x.type,
      description: x.description,
      provider: x.provider,
      difficulty: x.difficulty ?? null,
    }));
    return { course, resources };
  });
}

export function sourceFor(
  fixtures: CatalogFixture[],
  courseIndex: number,
  resourceIndex: number | null,
): GeneratorSource {
  const mine = fixtures[courseIndex];
  const others = fixtures.filter((_, i) => i !== courseIndex);
  return {
    course: mine.course,
    resources: mine.resources,
    target: resourceIndex === null ? null : mine.resources[resourceIndex],
    otherCourses: others.map((f) => f.course),
    otherResources: others.flatMap((f) => f.resources),
  };
}