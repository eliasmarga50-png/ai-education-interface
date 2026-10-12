import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { AiProviderError, createGeminiProvider, toGeminiContents } from '../src/providers/gemini.provider.js';
import { parseTutorRequest } from '../src/validation/tutorRequest.js';

const cfg = { apiKey: 'k', model: 'gemini-3.5-flash-lite', timeoutMs: 1000 };
const json = (status, body) => async () => ({ status, ok: status < 300, json: async () => body });

describe('toGeminiContents', () => {
  it('maps roles, merges repeats and starts with a user turn', () => {
    const out = toGeminiContents(
      [{ role: 'tutor', text: 'Hi!' }, { role: 'user', text: 'a' }, { role: 'user', text: 'b' }, { role: 'tutor', text: 'ok' }],
      'next',
    );
    assert.deepEqual(out.map((t) => t.role), ['user', 'model', 'user']);
    assert.equal(out[0].parts[0].text, 'a\nb');
  });
});

describe('gemini provider', () => {
  it('returns the text and sends the key in a header, not the URL', async () => {
    let seen;
    const p = createGeminiProvider(cfg, async (url, init) => {
      seen = { url, init };
      return { status: 200, ok: true, json: async () => ({ candidates: [{ content: { parts: [{ text: 'Hello ' }, { text: 'there' }] } }] }) };
    });
    assert.equal(await p.reply({ system: 's', history: [], question: 'q' }), 'Hello there');
    assert.ok(!seen.url.includes('key='));
    assert.equal(seen.init.headers['x-goog-api-key'], 'k');
    assert.match(seen.url, /gemini-3\.5-flash-lite:generateContent$/);
  });

  it('maps 429, 5xx, blocked and empty answers to safe errors', async () => {
    const run = (status, body) => createGeminiProvider(cfg, json(status, body)).reply({ system: 's', history: [], question: 'q' });
    await assert.rejects(run(429, {}), (e) => e instanceof AiProviderError && e.code === 'AI_RATE_LIMITED');
    await assert.rejects(run(500, {}), (e) => e.code === 'AI_UPSTREAM_ERROR');
    await assert.rejects(run(200, { promptFeedback: { blockReason: 'SAFETY' } }), (e) => e.code === 'AI_BLOCKED');
    await assert.rejects(run(200, { candidates: [] }), (e) => e.code === 'AI_EMPTY');
  });

  it('maps a timeout to 504', async () => {
    const p = createGeminiProvider(cfg, async () => { throw Object.assign(new Error('t'), { name: 'TimeoutError' }); });
    await assert.rejects(p.reply({ system: 's', history: [], question: 'q' }), (e) => e.status === 504);
  });
});

describe('parseTutorRequest', () => {
  it('validates and trims', () => {
    const r = parseTutorRequest({ question: '  what is a widget? ', history: [{ role: 'user', text: 'hi' }], lesson: { title: 'Widgets', email: 'x@y.z' } });
    assert.equal(r.question, 'what is a widget?');
    assert.deepEqual(r.lesson, { title: 'Widgets', course: undefined }); // extra fields (like email) are dropped
    assert.throws(() => parseTutorRequest({ question: '' }), (e) => e.code === 'VALIDATION_ERROR');
  });
});