import { RESOURCE_TYPES } from '../courses/courses.types';
import { CATALOG } from './catalog.data';

describe('catalogue seed data', () => {
  it('contains the five required courses', () => {
    expect(CATALOG.map((c) => c.title)).toEqual([
      'Flutter Development',
      'Python Programming',
      'UI/UX Design',
      'Machine Learning',
      'Web Development',
    ]);
    expect(new Set(CATALOG.map((c) => c.slug)).size).toBe(CATALOG.length);
  });

  it.each(CATALOG.map((c) => [c.title, c] as const))('%s has well-formed resources', (_title, course) => {
    expect(course.resources.length).toBeGreaterThanOrEqual(5);
    expect(course.outcomes.length).toBeGreaterThan(0);
    const urls = course.resources.map((r) => r.url);
    expect(new Set(urls).size).toBe(urls.length);

    for (const resource of course.resources) {
      const url = new URL(resource.url);
      expect(url.protocol).toBe('https:');
      expect(url.hostname).not.toMatch(/example\.|localhost|placeholder/i);
      expect(resource.title.trim()).not.toBe('');
      expect(resource.description.trim().length).toBeGreaterThan(20);
      expect(resource.provider.trim()).not.toBe('');
      expect(RESOURCE_TYPES).toContain(resource.type);
    }
  });
});