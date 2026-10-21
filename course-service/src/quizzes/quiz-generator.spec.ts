import { catalogFixtures, sourceFor } from '../../test/helpers/catalog-sources';
import {
  computeSourceHash,
  generateQuiz,
  MAX_QUESTIONS,
  MIN_QUESTIONS,
} from './quiz-generator';

const fixtures = catalogFixtures();

/** Every quiz the app can ask for: one per course plus one per resource. */
const targets = fixtures.flatMap((f, ci) => [
  { name: `${f.course.title} (course)`, ci, ri: null as number | null },
  ...f.resources.map((r, ri) => ({
    name: `${f.course.title} / ${r.title}`,
    ci,
    ri: ri as number | null,
  })),
]);

describe('quiz generator (built from the real catalogue)', () => {
  it('has courses and resources to work with', () => {
    expect(fixtures.length).toBeGreaterThan(1);
    expect(targets.length).toBeGreaterThan(fixtures.length);
  });

  it.each(targets.map((t) => [t.name, t] as const))(
    'builds a valid quiz for %s',
    (_name, t) => {
      const source = sourceFor(fixtures, t.ci, t.ri);
      const quiz = generateQuiz(source, computeSourceHash(source));

      expect(quiz).not.toBeNull();
      const questions = quiz!.questions;
      expect(questions.length).toBeGreaterThanOrEqual(MIN_QUESTIONS);
      expect(questions.length).toBeLessThanOrEqual(MAX_QUESTIONS);

      for (const q of questions) {
        expect(q.prompt.length).toBeGreaterThan(10);
        expect(q.options.length).toBeGreaterThanOrEqual(3);
        expect(q.options.length).toBeLessThanOrEqual(4);
        expect(new Set(q.options.map((o) => o.toLowerCase())).size).toBe(
          q.options.length,
        );
        expect(q.correctIndex).toBeGreaterThanOrEqual(0);
        expect(q.correctIndex).toBeLessThan(q.options.length);
        expect(q.explanation.length).toBeGreaterThan(0);
        expect(q.topic.length).toBeGreaterThan(0);
      }

      // No question may hand over the answer to another one.
      for (const [i, a] of questions.entries()) {
        const answer = a.options[a.correctIndex];
        if (answer.length < 12) continue;
        questions.forEach((b, j) => {
          if (i !== j) expect(b.prompt).not.toContain(answer);
        });
      }
    },
  );

  it('is deterministic: the same content always gives the same quiz', () => {
    const source = sourceFor(fixtures, 0, 0);
    const hash = computeSourceHash(source);
    expect(generateQuiz(source, hash)).toEqual(generateQuiz(source, hash));
    expect(computeSourceHash(sourceFor(fixtures, 0, 0))).toBe(hash);
  });

  it('ties a resource quiz to its resource and a course quiz to its course', () => {
    const resourceQuiz = generateQuiz(
      sourceFor(fixtures, 0, 0),
      computeSourceHash(sourceFor(fixtures, 0, 0)),
    )!;
    const resource = fixtures[0].resources[0];
    expect(resourceQuiz.title).toContain(resource.title);
    const about = resourceQuiz.questions.find(
      (q) => q.kind === 'resource_description',
    )!;
    expect(about.options[about.correctIndex]).toBe(resource.description);

    const courseQuiz = generateQuiz(
      sourceFor(fixtures, 0, null),
      computeSourceHash(sourceFor(fixtures, 0, null)),
    )!;
    expect(courseQuiz.title).toContain(fixtures[0].course.title);
    const goal = courseQuiz.questions.find((q) => q.kind === 'course_outcome')!;
    expect(fixtures[0].course.outcomes).toContain(
      goal.options[goal.correctIndex],
    );
  });

  it("draws wrong answers from other content, never from this course's own goals", () => {
    const course = fixtures[0].course;
    const source = sourceFor(fixtures, 0, null);
    const quiz = generateQuiz(source, computeSourceHash(source))!;
    for (const q of quiz.questions.filter((x) => x.kind === 'course_outcome')) {
      q.options.forEach((o, i) => {
        if (i !== q.correctIndex) expect(course.outcomes).not.toContain(o);
      });
    }
  });

  it('creates a different quiz (new hash) when the catalogue content changes', () => {
    const before = computeSourceHash(sourceFor(fixtures, 0, 0));
    const edited = catalogFixtures();
    edited[0].resources[0].description =
      'A completely different description of this resource.';
    expect(computeSourceHash(sourceFor(edited, 0, 0))).not.toBe(before);
  });

  it('returns null when the catalogue has too little content', () => {
    const lonely = catalogFixtures()[0];
    const source = {
      course: { ...lonely.course, outcomes: [] },
      resources: [],
      target: null,
      otherCourses: [],
      otherResources: [],
    };
    expect(generateQuiz(source, computeSourceHash(source))).toBeNull();
  });
});