import { createHash } from 'node:crypto';
import { RESOURCE_TYPES, ResourceType } from '../courses/courses.types';
import {
  GeneratedQuestion,
  GeneratedQuiz,
  GeneratorCourse,
  GeneratorResource,
  GeneratorSource,
} from './quizzes.types';

/**
 * Builds quizzes from the course catalogue that is in the database: course goals, resource
 * titles, descriptions, types, levels and providers. No question text is written by hand, and
 * wrong answers are real content from other courses/resources.
 *
 * It is deterministic: the same catalogue content always produces the same quiz (the random
 * choices are seeded from a hash of that content), so two students who open a quiz at the same
 * moment get the same questions and the database can store one copy.
 *
 * Questions are limited to what the catalogue records. To go deeper (questions about the text
 * of a page or video), add another generator and change GENERATOR_ID.
 */
export const GENERATOR_ID = 'catalog-v1';
export const MAX_QUESTIONS = 5;
export const MIN_QUESTIONS = 3;

const TYPE_LABELS: Record<ResourceType, string> = {
  documentation: 'Documentation',
  tutorial: 'Tutorial',
  video: 'Video',
  course: 'Course',
  article: 'Article',
  book: 'Book',
  interactive: 'Interactive',
};

const LEVEL_OPTIONS = ['Beginner', 'Intermediate', 'Advanced'];

/** Two outcomes sharing this much vocabulary are treated as "could both be true". */
const SIMILARITY_LIMIT = 0.4;

type Rng = () => number;

function mulberry32(seed: number): Rng {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function shuffle<T>(items: readonly T[], rng: Rng): T[] {
  const out = [...items];
  for (let i = out.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [out[i], out[j]] = [out[j], out[i]];
  }
  return out;
}

const norm = (s: string): string => s.trim().toLowerCase().replace(/\s+/g, ' ');
const stripEnd = (s: string): string => s.trim().replace(/[.!\s]+$/, '');

function words(s: string): Set<string> {
  return new Set(s.toLowerCase().match(/[a-z0-9]{4,}/g) ?? []);
}

function similarity(a: string, b: string): number {
  const wa = words(a);
  const wb = words(b);
  if (wa.size === 0 || wb.size === 0) return 0;
  let shared = 0;
  for (const w of wa) if (wb.has(w)) shared++;
  return shared / (wa.size + wb.size - shared);
}

/**
 * One correct answer plus up to 3 wrong ones taken from [pool] in order (callers put the most
 * convincing wrong answers first). Wrong answers equal to the right one, or repeated, are dropped.
 * Returns null when fewer than 2 wrong answers exist, because a 2-option question is a coin flip.
 */
function buildOptions(
  correct: string,
  pool: readonly string[],
  rng: Rng,
): { options: string[]; correctIndex: number } | null {
  const seen = new Set([norm(correct)]);
  const wrong: string[] = [];
  for (const candidate of pool) {
    const key = norm(candidate);
    if (!key || seen.has(key)) continue;
    seen.add(key);
    wrong.push(candidate);
    if (wrong.length === 3) break;
  }
  if (wrong.length < 2) return null;
  const options = shuffle([correct, ...wrong], rng);
  return { options, correctIndex: options.indexOf(correct) };
}

/** Same-course items first (they are the believable mistakes), then the rest. */
function ordered<T>(near: readonly T[], far: readonly T[], rng: Rng): T[] {
  return [...shuffle(near, rng), ...shuffle(far, rng)];
}

// ---------------------------------------------------------------------------
// Question builders. Each returns null when the catalogue cannot support it.
// ---------------------------------------------------------------------------

/** Resources whose description is close to [r]'s could be mistaken for it, so they are never offered as wrong answers. */
const distinctFrom = (r: GeneratorResource) => (x: GeneratorResource) =>
  x.id !== r.id && similarity(x.description, r.description) < SIMILARITY_LIMIT;

function aboutResource(
  r: GeneratorResource,
  s: GeneratorSource,
  rng: Rng,
): GeneratedQuestion | null {
  const near = s.resources.filter(distinctFrom(r)).map((x) => x.description);
  const far = s.otherResources
    .filter(distinctFrom(r))
    .map((x) => x.description);
  const built = buildOptions(r.description, ordered(near, far, rng), rng);
  if (!built) return null;
  return {
    kind: 'resource_description',
    prompt: `What is “${r.title}” mainly about?`,
    ...built,
    explanation: `“${r.title}” (${r.provider}): ${r.description}`,
    topic: r.title,
  };
}

function matchResource(
  r: GeneratorResource,
  s: GeneratorSource,
  rng: Rng,
): GeneratedQuestion | null {
  const near = s.resources.filter(distinctFrom(r)).map((x) => x.title);
  const far = s.otherResources.filter(distinctFrom(r)).map((x) => x.title);
  const built = buildOptions(r.title, ordered(near, far, rng), rng);
  if (!built) return null;
  return {
    kind: 'resource_title',
    prompt: `Which learning resource is described like this? “${stripEnd(r.description)}.”`,
    ...built,
    explanation: `That description belongs to “${r.title}” (${r.provider}).`,
    topic: r.title,
  };
}

function courseOutcome(
  c: GeneratorCourse,
  outcome: string,
  s: GeneratorSource,
  rng: Rng,
): GeneratedQuestion | null {
  // A goal of another course that is nearly the same as one of this course's goals would
  // make the question unfair, so those are never offered as wrong answers.
  const foreign = s.otherCourses
    .flatMap((o) => o.outcomes)
    .filter((o) =>
      c.outcomes.every((own) => similarity(o, own) < SIMILARITY_LIMIT),
    );
  const built = buildOptions(outcome, shuffle(foreign, rng), rng);
  if (!built) return null;
  return {
    kind: 'course_outcome',
    prompt: `Which of these is a learning goal of the “${c.title}” course?`,
    ...built,
    explanation: `One of the goals of “${c.title}” is to: ${stripEnd(outcome)}.`,
    topic: stripEnd(outcome),
  };
}

function resourceType(
  r: GeneratorResource,
  s: GeneratorSource,
  rng: Rng,
): GeneratedQuestion | null {
  const correct = TYPE_LABELS[r.type];
  const pool = shuffle(
    RESOURCE_TYPES.filter((t) => t !== r.type).map((t) => TYPE_LABELS[t]),
    rng,
  );
  const built = buildOptions(correct, pool, rng);
  if (!built) return null;
  return {
    kind: 'resource_type',
    prompt: `What kind of learning resource is “${r.title}”?`,
    ...built,
    explanation: `“${r.title}” is listed as a ${correct.toLowerCase()} from ${r.provider}.`,
    topic: r.title,
  };
}

function resourceLevel(
  r: GeneratorResource,
  s: GeneratorSource,
  rng: Rng,
): GeneratedQuestion | null {
  if (!r.difficulty) return null;
  const built = buildOptions(r.difficulty, LEVEL_OPTIONS, rng);
  if (!built) return null;
  return {
    kind: 'resource_level',
    prompt: `Which level is “${r.title}” aimed at?`,
    ...built,
    explanation: `“${r.title}” is aimed at ${r.difficulty.toLowerCase()} learners.`,
    topic: r.title,
  };
}

function resourceProvider(
  r: GeneratorResource,
  s: GeneratorSource,
  rng: Rng,
): GeneratedQuestion | null {
  // "Who provides 'freeCodeCamp curriculum'?" answers itself.
  if (
    norm(r.title).includes(norm(r.provider)) ||
    norm(r.provider).includes(norm(r.title))
  )
    return null;
  const near = s.resources.filter((x) => x.id !== r.id).map((x) => x.provider);
  const far = s.otherResources.map((x) => x.provider);
  const built = buildOptions(r.provider, ordered(near, far, rng), rng);
  if (!built) return null;
  return {
    kind: 'resource_provider',
    prompt: `Who provides “${r.title}”?`,
    ...built,
    explanation: `“${r.title}” is provided by ${r.provider}.`,
    topic: r.title,
  };
}

// ---------------------------------------------------------------------------

/** Fingerprint of everything the generator reads. A catalogue edit changes it, which makes a new quiz. */
export function computeSourceHash(s: GeneratorSource): string {
  const byId = <T extends { id: string }>(items: T[]): T[] =>
    [...items].sort((a, b) => a.id.localeCompare(b.id));
  const payload = {
    generator: GENERATOR_ID,
    course: s.course,
    resources: s.resources,
    target: s.target?.id ?? null,
    otherCourses: byId(s.otherCourses).map((c) => ({
      id: c.id,
      title: c.title,
      outcomes: c.outcomes,
    })),
    otherResources: byId(s.otherResources).map((r) => ({
      id: r.id,
      title: r.title,
      description: r.description,
      provider: r.provider,
    })),
  };
  return createHash('sha256').update(JSON.stringify(payload)).digest('hex');
}

type Maker = () => GeneratedQuestion | null;

/**
 * Returns null when the catalogue has too little content for a meaningful quiz
 * (fewer than MIN_QUESTIONS questions could be built).
 */
export function generateQuiz(
  s: GeneratorSource,
  sourceHash: string,
): GeneratedQuiz | null {
  const rng = mulberry32(parseInt(sourceHash.slice(0, 8), 16));
  const { course, target } = s;
  const outcomes = shuffle(course.outcomes, rng);

  let primary: Maker[];
  let fillers: Maker[];
  let title: string;
  let description: string;

  if (target) {
    title = `${target.title}: quiz`;
    description = `Check what you took away from “${target.title}” (${TYPE_LABELS[target.type]}, ${target.provider}).`;
    primary = [
      () => aboutResource(target, s, rng),
      () => (outcomes[0] ? courseOutcome(course, outcomes[0], s, rng) : null),
    ];
    fillers = [
      () => resourceType(target, s, rng),
      () => resourceLevel(target, s, rng),
      () => resourceProvider(target, s, rng),
    ];
  } else {
    title = `${course.title}: course quiz`;
    description = `Check how well you understand “${course.title}”: its goals and the learning resources that go with it.`;
    const resources = shuffle(s.resources, rng);
    // Each resource and each goal is used by one question only, so no prompt gives away another answer.
    primary = [
      () => (outcomes[0] ? courseOutcome(course, outcomes[0], s, rng) : null),
      () => (resources[0] ? matchResource(resources[0], s, rng) : null),
      () => (outcomes[1] ? courseOutcome(course, outcomes[1], s, rng) : null),
      () => (resources[1] ? matchResource(resources[1], s, rng) : null),
      () => (resources[2] ? aboutResource(resources[2], s, rng) : null),
    ];
    fillers = [
      () => (resources[3] ? aboutResource(resources[3], s, rng) : null),
      () => (outcomes[2] ? courseOutcome(course, outcomes[2], s, rng) : null),
      () => (resources[4] ? matchResource(resources[4], s, rng) : null),
    ];
  }

  const questions: GeneratedQuestion[] = [];
  const asked = new Set<string>();
  for (const make of [...primary, ...fillers]) {
    if (questions.length >= MAX_QUESTIONS) break;
    const q = make();
    if (!q) continue;
    // Two goal questions share a prompt, so the right answer is part of the identity.
    const identity = `${norm(q.prompt)}|${norm(q.options[q.correctIndex])}`;
    if (asked.has(identity)) continue;
    asked.add(identity);
    questions.push(q);
  }

  return questions.length >= MIN_QUESTIONS
    ? { title, description, questions }
    : null;
}