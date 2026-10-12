import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { createMailer } from '../src/services/mail/mailer.js';

const silent = { log() {}, warn() {}, error() {} };
const mail = { to: 'ada@example.com', name: 'Ada <b>', code: '123456', purpose: 'verify_email', expiresInMinutes: 10 };
const resendConfig = { mode: 'resend', from: 'AI Education <no-reply@mail.example.com>', resendApiKey: 're_secret_key_123' };

describe('mailer: resend', () => {
  it('POSTs to the Resend API with the key in the Authorization header and the code in the body', async () => {
    let seen;
    const mailer = createMailer(resendConfig, silent, async (url, init) => {
      seen = { url, init, body: JSON.parse(init.body) };
      return { ok: true, status: 200, json: async () => ({ id: 'abc' }) };
    });

    await mailer.sendCode(mail);

    assert.equal(seen.url, 'https://api.resend.com/emails');
    assert.equal(seen.init.method, 'POST');
    assert.equal(seen.init.headers.Authorization, 'Bearer re_secret_key_123');
    assert.equal(seen.body.from, resendConfig.from);
    assert.deepEqual(seen.body.to, ['ada@example.com']);
    assert.match(seen.body.text, /123456/);
    assert.match(seen.body.html, /123456/);
    assert.ok(!seen.body.html.includes('<b>'), 'the name must be HTML-escaped');
  });

  it('throws a readable error, without the API key, when Resend refuses (unverified domain)', async () => {
    const mailer = createMailer(resendConfig, silent, async () => ({
      ok: false,
      status: 403,
      json: async () => ({ name: 'validation_error', message: 'You can only send testing emails to your own email address' }),
    }));

    await assert.rejects(mailer.sendCode(mail), (err) => {
      assert.match(err.message, /HTTP 403/);
      assert.match(err.message, /only send testing emails/);
      assert.ok(!err.message.includes('re_secret_key_123'));
      return true;
    });
  });

  it('handles a non-JSON error body', async () => {
    const mailer = createMailer(resendConfig, silent, async () => ({
      ok: false,
      status: 502,
      json: async () => { throw new Error('not json'); },
    }));
    await assert.rejects(mailer.sendCode(mail), /HTTP 502/);
  });

  it('reports timeouts and network failures', async () => {
    const timeout = createMailer(resendConfig, silent, async () => { throw Object.assign(new Error('t'), { name: 'TimeoutError' }); });
    await assert.rejects(timeout.sendCode(mail), /did not answer/);

    const offline = createMailer(resendConfig, silent, async () => { throw new Error('getaddrinfo ENOTFOUND'); });
    await assert.rejects(offline.sendCode(mail), /unreachable/);
  });
});

describe('mailer: console', () => {
  it('prints the code in the terminal', async () => {
    const lines = [];
    const mailer = createMailer({ mode: 'console', from: 'x' }, { log: (m) => lines.push(m) });
    await mailer.sendCode(mail);
    assert.match(lines.join('\n'), /123456/);
  });
});