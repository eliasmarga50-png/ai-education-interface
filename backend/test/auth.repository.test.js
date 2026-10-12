import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { loadConfig } from '../src/config/env.js';
import { AuthRepository } from '../src/modules/auth/auth.repository.js';


function fakePool({ rows = [], rowCount = 1, failOn } = {}) {
  const log = [];
  const run = (sql, params = []) => {
    log.push({ sql, params });
    if (failOn && sql.includes(failOn)) return Promise.reject(new Error('boom'));
    return Promise.resolve({ rows, rowCount });
  };
  const released = [];
  return {
    log,
    released,
    query: run,
    connect: async () => ({ query: run, release: (destroy) => released.push(destroy) }),
  };
}

const placeholders = (sql) => [...new Set(sql.match(/\$\d+/g) ?? [])].map((p) => Number(p.slice(1))).sort((a, b) => a - b);

function assertPlaceholdersMatch(log) {
  for (const { sql, params } of log) {
    if (/^(BEGIN|COMMIT|ROLLBACK)$/.test(sql)) continue;
    const used = placeholders(sql);
    assert.deepEqual(
      used,
      params.map((_, i) => i + 1),
      `placeholders ${JSON.stringify(used)} do not match ${params.length} parameter(s) in:\n${sql}`,
    );
  }
}

const session = { id: 's1', userId: 'u1', accessHash: 'a', accessExpiresAt: 2, refreshHash: 'r', refreshExpiresAt: 3, now: 1 };
const code = { id: 'c1', userId: 'u1', purpose: 'verify_email', codeHash: 'h', expiresAt: 9, createdAt: 1 };
const tokens = { accessHash: 'a2', accessExpiresAt: 5, refreshHash: 'r2', refreshExpiresAt: 6 };

describe('AuthRepository (PostgreSQL wiring)', () => {
  it('every statement has exactly the placeholders its parameters need', async () => {
    const pool = fakePool({ rows: [{ n: 0, attempts: 1, id: 'u1' }] });
    const repo = new AuthRepository(pool);

    await repo.findUserByEmail('a@b.co');
    await repo.findUserById('u1');
    await repo.createUser({ id: 'u1', name: 'A', email: 'a@b.co', passwordHash: 'h', now: 1 });
    await repo.markVerified('u1', 1);
    await repo.setLoginFailures('u1', 1, null, 1);
    await repo.updatePasswordAndRevokeSessions({ userId: 'u1', passwordHash: 'h', now: 1 });
    await repo.latestCode('u1', 'verify_email');
    await repo.countCodesSince('u1', 'verify_email', 0);
    await repo.replaceCode(code);
    await repo.deleteCode('c1');
    await repo.claimAttempt('c1', 5);
    await repo.consumeCode('c1', 1);
    await repo.createSession(session);
    await repo.findSessionByAccessHash('a');
    await repo.findSessionByRefreshHash('r');
    await repo.rotateSession('s1', 'r', tokens);
    await repo.revokeSession('s1', 1);
    await repo.purgeExpired(10 * 24 * 60 * 60 * 1000);

    assert.ok(pool.log.length >= 20);
    assertPlaceholdersMatch(pool.log);
  });

  it('maps results the way the service expects', async () => {
    const one = (opts) => new AuthRepository(fakePool(opts));

    assert.equal(await one({ rows: [{ n: 3 }] }).countCodesSince('u', 'verify_email', 0), 3);
    assert.equal(await one({ rows: [{ attempts: 4 }] }).claimAttempt('c', 5), 4);
    assert.equal(await one({ rows: [] }).claimAttempt('c', 5), null);
    assert.equal(await one({ rowCount: 1 }).consumeCode('c', 1), true);
    assert.equal(await one({ rowCount: 0 }).consumeCode('c', 1), false);
    assert.equal(await one({ rowCount: 1 }).rotateSession('s', 'r', tokens), true);
    assert.equal(await one({ rowCount: 0 }).rotateSession('s', 'r', tokens), false);
    assert.equal(await one({ rows: [] }).findUserByEmail('x@y.co'), undefined);
  });

  it('createUser falls back to the existing row when the email is already taken', async () => {
    const queries = [];
    const pool = {
      query: async (sql, params) => {
        queries.push(sql);
        return sql.startsWith('INSERT') ? { rows: [], rowCount: 0 } : { rows: [{ id: 'existing' }], rowCount: 1 };
      },
    };
    const user = await new AuthRepository(pool).createUser({ id: 'new', name: 'A', email: 'a@b.co', passwordHash: 'h', now: 1 });
    assert.equal(user.id, 'existing');
    assert.match(queries[0], /ON CONFLICT \(email\) DO NOTHING/);
  });

  it('transactions BEGIN, COMMIT and always release the connection', async () => {
    const pool = fakePool();
    await new AuthRepository(pool).replaceCode(code);

    const sqls = pool.log.map((q) => q.sql);
    assert.equal(sqls[0], 'BEGIN');
    assert.equal(sqls.at(-1), 'COMMIT');
    assert.deepEqual(pool.released, [false]);
  });

  it('a failing statement rolls back and does not commit', async () => {
    const pool = fakePool({ failOn: 'INSERT INTO verification_codes' });
    await assert.rejects(new AuthRepository(pool).replaceCode(code), /boom/);

    const sqls = pool.log.map((q) => q.sql);
    assert.ok(sqls.includes('ROLLBACK'));
    assert.ok(!sqls.includes('COMMIT'));
    assert.deepEqual(pool.released, [false]);
  });

  it('a broken connection is destroyed instead of being returned to the pool', async () => {
    const released = [];
    const client = {
      query: async (sql) => {
        if (sql === 'ROLLBACK') throw new Error('connection lost');
        if (sql.startsWith('INSERT')) throw new Error('boom');
        return { rows: [], rowCount: 1 };
      },
      release: (destroy) => released.push(destroy),
    };
    await assert.rejects(new AuthRepository({ connect: async () => client }).replaceCode(code), /boom/);
    assert.deepEqual(released, [true]);
  });
});

describe('config: DATABASE_URL', () => {
  const base = { AUTH_CODE_SECRET: 'x'.repeat(40), MAIL_MODE: 'console' };

  it('is required and must be a PostgreSQL address', () => {
    assert.throws(() => loadConfig(base), /DATABASE_URL/);
    assert.throws(() => loadConfig({ ...base, DATABASE_URL: 'mysql://u:p@h/db' }), /DATABASE_URL/);
    assert.throws(() => loadConfig({ ...base, DATABASE_URL: './data/app.db' }), /DATABASE_URL/);
  });

  it('accepts Neon and Supabase style URLs', () => {
    const neon = 'postgresql://alex:pw@ep-cool-123-pooler.us-east-2.aws.neon.tech/db?sslmode=require&channel_binding=require';
    const supa = 'postgres://postgres.abc:pw@aws-0-eu-central-1.pooler.supabase.com:6543/postgres';
    assert.equal(loadConfig({ ...base, DATABASE_URL: neon }).databaseUrl, neon);
    assert.equal(loadConfig({ ...base, DATABASE_URL: supa }).dbPoolMax, 5);
  });

  it('still refuses console mail mode in production', () => {
    assert.throws(
      () => loadConfig({ ...base, NODE_ENV: 'production', DATABASE_URL: 'postgresql://u:p@h/db', CORS_ORIGIN: 'https://a.example' }),
      /not allowed in production/,
    );
  });
});