import { AiProviderError } from '../providers/gemini.provider.js';

const bad = (message) => new AiProviderError(422, 'VALIDATION_ERROR', message);

/** Validates the request. Only learning content is accepted: no user identity is ever sent to Gemini. */
export function parseTutorRequest(body = {}) {
  const question = typeof body.question === 'string' ? body.question.trim() : '';
  if (!question || question.length > 2000) throw bad('Question must be 1-2000 characters.');

  const rawHistory = Array.isArray(body.history) ? body.history.slice(-20) : [];
  const history = rawHistory.map((m) => {
    const text = typeof m?.text === 'string' ? m.text.trim().slice(0, 4000) : '';
    if (!text) throw bad('History items need text.');
    return { role: m.role === 'user' ? 'user' : 'tutor', text };
  });

  const lesson =
    body.lesson && typeof body.lesson.title === 'string'
      ? {
          title: body.lesson.title.slice(0, 200),
          course: typeof body.lesson.course === 'string' ? body.lesson.course.slice(0, 200) : undefined,
        }
      : undefined;

  return { question, history, lesson };
}