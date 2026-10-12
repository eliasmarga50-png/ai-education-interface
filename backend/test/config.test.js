import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { loadConfig } from '../src/config/env.js';

const base = {
  DATABASE_URL: 'postgresql://u:p@ep-x-pooler.neon.tech/db?sslmode=require',
  AUTH_CODE_SECRET: 'x'.repeat(40),
};
const prod = { ...base, NODE_ENV: 'production' };

describe('config: email provider', () => {
  it('development defaults to console', () => {
    assert.equal(loadConfig(base).mail.mode, 'console');
  });

  it('a Resend key switches to resend without MAIL_MODE (and does NOT trip the production console error)', () => {
    const cfg = loadConfig({ ...prod, RESEND_API_KEY: 're_x', MAIL_FROM: 'App <a@mail.example.com>' });
    assert.equal(cfg.mail.mode, 'resend');
    assert.equal(cfg.mail.resendApiKey, 're_x');
  });

  it('SMTP settings switch to smtp without MAIL_MODE', () => {
    const cfg = loadConfig({
      ...prod, SMTP_HOST: 'smtp.gmail.com', SMTP_USER: 'me@gmail.com', SMTP_PASS: 'app-pass', MAIL_FROM: 'me@gmail.com',
    });
    assert.equal(cfg.mail.mode, 'smtp');
    assert.equal(cfg.mail.port, 465);
  });

  it('explicit MAIL_MODE wins, and its settings are required', () => {
    assert.throws(() => loadConfig({ ...base, MAIL_MODE: 'resend', MAIL_FROM: 'a@b.co' }), /RESEND_API_KEY/);
    assert.throws(() => loadConfig({ ...base, MAIL_MODE: 'resend', RESEND_API_KEY: 're_x' }), /MAIL_FROM/);
    assert.throws(() => loadConfig({ ...base, MAIL_MODE: 'smtp', MAIL_FROM: 'a@b.co' }), /SMTP_HOST/);
    assert.throws(() => loadConfig({ ...base, MAIL_MODE: 'pigeon' }), /MAIL_MODE/);
  });

  it('production with no provider is refused with a message that says what to set', () => {
    assert.throws(() => loadConfig(prod), /RESEND_API_KEY/);
    assert.throws(() => loadConfig({ ...prod, MAIL_MODE: 'console' }), /not allowed in production/);
  });
});

describe('config: TRUST_PROXY', () => {
  it('defaults to 0 locally and 1 on Vercel', () => {
    assert.equal(loadConfig(base).trustProxy, 0);
    assert.equal(loadConfig({ ...base, VERCEL: '1' }).trustProxy, 1);
  });

  it('accepts a number of proxies and lets it override the Vercel default', () => {
    assert.equal(loadConfig({ ...base, TRUST_PROXY: '1' }).trustProxy, 1);
    assert.equal(loadConfig({ ...base, TRUST_PROXY: '2' }).trustProxy, 2);
    assert.equal(loadConfig({ ...base, TRUST_PROXY: '0', VERCEL: '1' }).trustProxy, 0);
  });

  it('refuses "true", negatives and junk (they would let clients fake their IP)', () => {
    for (const bad of ['true', 'yes', '-1', '1.5', '99', 'abc']) {
      assert.throws(() => loadConfig({ ...base, TRUST_PROXY: bad }), /TRUST_PROXY/, bad);
    }
  });
});

describe('config: deployment settings', () => {
  it('uses a smaller connection pool on Vercel', () => {
    assert.equal(loadConfig(base).dbPoolMax, 5);
    assert.equal(loadConfig({ ...base, VERCEL: '1' }).dbPoolMax, 3);
    assert.equal(loadConfig({ ...base, VERCEL: '1', DB_POOL_MAX: '2' }).dbPoolMax, 2);
  });

  it('CRON_SECRET is optional but must be long enough', () => {
    assert.equal(loadConfig(base).cronSecret, '');
    assert.equal(loadConfig({ ...base, CRON_SECRET: 'c'.repeat(20) }).cronSecret.length, 20);
    assert.throws(() => loadConfig({ ...base, CRON_SECRET: 'short' }), /CRON_SECRET/);
  });

  it('production refuses wildcard CORS but accepts an empty or explicit origin', () => {
    const withMail = { ...prod, RESEND_API_KEY: 're_x', MAIL_FROM: 'a@mail.example.com' };
    assert.throws(() => loadConfig({ ...withMail, CORS_ORIGIN: '*' }), /CORS_ORIGIN/);
    assert.equal(loadConfig({ ...withMail, CORS_ORIGIN: '' }).corsOrigin, '');
    assert.equal(loadConfig({ ...withMail, CORS_ORIGIN: 'https://app.example.com' }).corsOrigin, 'https://app.example.com');
  });

  it('every required secret has a clear error', () => {
    assert.throws(() => loadConfig({ ...base, AUTH_CODE_SECRET: 'short' }), /AUTH_CODE_SECRET/);
    assert.throws(() => loadConfig({ AUTH_CODE_SECRET: base.AUTH_CODE_SECRET }), /DATABASE_URL/);
  });
});