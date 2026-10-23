import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { loadConfig } from '../src/config/env.js';
import { createTutorService, parseTutorBody } from '../src/modules/tutor/tutor.service.js';

const KEY = 'k'.repeat(40);
const config = { ai: { url: 'http://127.0.0.1:4000', internalKey: KEY, timeoutMs: 1000 } };
const answer = (status, body) => async () => ({ status, ok: status < 300, json: async () => body });
const run = (fetchImpl, body = { question: 'What is a widget?' }, cfg = config) =>
  createTutorService({ config: cfg, fetchImpl }).reply(body);

describe('tutor: request parsing', () => {
  it('rejects empty and over-long questions', () => {
    assert.throws(() => parseTutorBody({ question: '   ' }), (e) => e.code === 'VALIDATION_ERROR');
    assert.throws(() => parseTutorBody({}), (e) => e.statusCode === 422);
    assert.throws(() => parseTutorBody({ question: 'x'.repeat(2001) }), /2000/);
  });

  it('keeps the last 20 history items, drops empty ones and maps roles', () => {
    const history = Array.from({ length: 25 }, (_, i) => ({ role: i % 2 ? 'user' : 'ai', text: `m${i}` }));
    history.push({ role: 'user', text: '   ' });
    const out = parseTutorBody({ question: 'q', history });
    assert.equal(out.history.length, 19);
    assert.ok(out.history.every((m) => m.role === 'user' || m.role === 'tutor'));
  });

  it('forwards only the lesson title and course', () => {
    const out = parseTutorBody({ question: 'q', lesson: { title: 'Widgets', course: 'Flutter', content: 'secret', userId: 7 } });
    assert.deepEqual(out.lesson, { title: 'Widgets', course: 'Flutter' });
  });
});

describe('tutor service', () => {
  it('sends the internal key and returns the reply', async () => {
    let seen;
    const out = await run(async (url, init) => {
      seen = { url, init };
      return { status: 200, ok: true, json: async () => ({ reply: '  A widget is UI.  ' }) };
    });
    assert.deepEqual(out, { reply: 'A widget is UI.' });
    assert.equal(seen.url, 'http://127.0.0.1:4000/v1/tutor/reply');
    assert.equal(seen.init.headers['x-internal-key'], KEY);
  });

  it('answers 503 AI_NOT_CONFIGURED when no key is set, without calling the ai-service', async () => {
    let called = false;
    await assert.rejects(
      run(async () => { called = true; }, undefined, { ai: { ...config.ai, internalKey: '' } }),
      (e) => e.statusCode === 503 && e.code === 'AI_NOT_CONFIGURED',
    );
    assert.equal(called, false);
  });

  it('passes safe ai-service errors through', async () => {
    await assert.rejects(
      run(answer(429, { error: { code: 'AI_RATE_LIMITED', message: 'Busy.' } })),
      (e) => e.statusCode === 429 && e.code === 'AI_RATE_LIMITED' && e.message === 'Busy.',
    );
    await assert.rejects(run(answer(422, { error: { code: 'AI_BLOCKED', message: 'No.' } })), (e) => e.code === 'AI_BLOCKED');
  });

  it('never leaks UNAUTHORIZED from the ai-service (the app would try to refresh the login)', async () => {
    await assert.rejects(
      run(answer(401, { error: { code: 'UNAUTHORIZED', message: 'Invalid internal key.' } })),
      (e) => e.statusCode === 503 && e.code === 'AI_UNAVAILABLE',
    );
  });

  it('maps timeouts, unreachable service and non-JSON bodies', async () => {
    const timeout = Object.assign(new Error('t'), { name: 'TimeoutError' });
    await assert.rejects(run(async () => { throw timeout; }), (e) => e.statusCode === 504 && e.code === 'AI_TIMEOUT');
    await assert.rejects(run(async () => { throw new Error('ECONNREFUSED'); }), (e) => e.statusCode === 502 && e.code === 'AI_UNREACHABLE');
    await assert.rejects(
      run(async () => ({ status: 502, ok: false, json: async () => { throw new Error('html'); } })),
      (e) => e.code === 'AI_UNAVAILABLE',
    );
    await assert.rejects(run(answer(200, { reply: '' })), (e) => e.code === 'AI_EMPTY');
  });
});

describe('tutor config', () => {
  const base = { DATABASE_URL: 'postgresql://u:p@h/db', AUTH_CODE_SECRET: 'x'.repeat(40) };

  it('is optional, with safe defaults', () => {
    const { ai } = loadConfig(base);
    assert.equal(ai.internalKey, '');
    assert.equal(ai.url, 'http://127.0.0.1:4000');
    assert.equal(ai.timeoutMs, 25000);
  });

  it('requires a 32+ character key when set, and trims trailing slashes from the URL', () => {
    assert.throws(() => loadConfig({ ...base, AI_INTERNAL_KEY: 'short' }), /AI_INTERNAL_KEY/);
    assert.equal(loadConfig({ ...base, AI_INTERNAL_KEY: KEY, AI_SERVICE_URL: 'http://ai:4000//' }).ai.url, 'http://ai:4000');
  });
});