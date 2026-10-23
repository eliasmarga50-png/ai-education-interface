import { AppError } from '../../utils/AppError.js';

const MAX_QUESTION = 2000;
const MAX_HISTORY = 20;
const MAX_TEXT = 4000;

// Errors the ai-service is allowed to show to the app. Everything else becomes a generic 502.
const PASS_THROUGH = new Set([
  'AI_RATE_LIMITED',
  'AI_TIMEOUT',
  'AI_UNREACHABLE',
  'AI_UPSTREAM_ERROR',
  'AI_BLOCKED',
  'AI_EMPTY',
  'VALIDATION_ERROR',
]);

const bad = (message) => new AppError(422, 'VALIDATION_ERROR', message);

/** Only learning content is forwarded: never the user's id, name or email. */
export function parseTutorBody(body = {}) {
  const question = typeof body.question === 'string' ? body.question.trim() : '';
  if (!question) throw bad('Type a question first.');
  if (question.length > MAX_QUESTION) throw bad(`Questions can be at most ${MAX_QUESTION} characters.`);

  const history = (Array.isArray(body.history) ? body.history : [])
    .slice(-MAX_HISTORY)
    .map((m) => ({
      role: m?.role === 'user' ? 'user' : 'tutor',
      text: typeof m?.text === 'string' ? m.text.trim().slice(0, MAX_TEXT) : '',
    }))
    .filter((m) => m.text);

  const lesson =
    body.lesson && typeof body.lesson.title === 'string' && body.lesson.title.trim()
      ? {
          title: body.lesson.title.trim().slice(0, 200),
          course: typeof body.lesson.course === 'string' ? body.lesson.course.trim().slice(0, 200) : undefined,
        }
      : undefined;

  return { question, history, lesson };
}

/** Backend -> ai-service -> Gemini. The Gemini key never leaves the ai-service. */
export function createTutorService({ config, fetchImpl = fetch }) {
  const { url, internalKey, timeoutMs } = config.ai;

  async function reply(body) {
    const payload = parseTutorBody(body);

    if (!internalKey) {
      throw new AppError(503, 'AI_NOT_CONFIGURED', 'The AI tutor is not set up on the server yet.');
    }

    let res;
    try {
      res = await fetchImpl(`${url}/v1/tutor/reply`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', 'x-internal-key': internalKey },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(timeoutMs),
      });
    } catch (err) {
      if (err?.name === 'TimeoutError' || err?.name === 'AbortError') {
        throw new AppError(504, 'AI_TIMEOUT', 'The tutor took too long to answer. Please try again.');
      }
      console.error('[tutor] ai-service unreachable:', err?.message);
      throw new AppError(502, 'AI_UNREACHABLE', 'The tutor is unreachable right now. Please try again soon.');
    }

    let data = {};
    try {
      data = await res.json();
    } catch {
      // Not JSON: handled below.
    }

    if (res.ok) {
      if (typeof data.reply === 'string' && data.reply.trim()) return { reply: data.reply.trim() };
      throw new AppError(502, 'AI_EMPTY', 'The tutor returned an empty answer. Please rephrase.');
    }

    const code = data?.error?.code;
    if (PASS_THROUGH.has(code)) {
      const status = [422, 429, 502, 504].includes(res.status) ? res.status : 502;
      throw new AppError(status, code, data.error.message || 'The tutor could not answer right now.');
    }

    // Includes 401 (key mismatch): never reuse the code UNAUTHORIZED, the app would try to refresh the login.
    console.error(`[tutor] ai-service answered HTTP ${res.status} (${code || 'no code'})`);
    throw new AppError(503, 'AI_UNAVAILABLE', 'The AI tutor is not available right now. Please try again later.');
  }

  return { reply };
}