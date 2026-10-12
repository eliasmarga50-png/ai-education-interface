// Runs every repository method against your REAL database, then removes its test data.
//   npm run db:check
import { randomUUID } from 'node:crypto';
import assert from 'node:assert/strict';
import { createPool } from '../src/db/database.js';
import { AuthRepository } from '../src/modules/auth/auth.repository.js';

if (!process.env.DATABASE_URL) {
  console.error('DATABASE_URL is not set. Add it to backend/.env first.');
  process.exit(1);
}

const pool = createPool(process.env.DATABASE_URL, { max: 2 });
const repo = new AuthRepository(pool);

const userId = randomUUID();
const email = `db-check-${Date.now()}@example.invalid`;
const t = Date.now();
let failed = false;

async function step(label, fn) {
  try {
    await fn();
    console.log(`  ok   ${label}`);
  } catch (err) {
    failed = true;
    console.error(`  FAIL ${label}\n       ${err.message}`);
  }
}

console.log('Checking the database through AuthRepository...');

await step('connect', async () => assert.equal((await pool.query('SELECT 1 AS one')).rows[0].one, 1));

await step('createUser returns the row, and a duplicate email returns the SAME row', async () => {
  const a = await repo.createUser({ id: userId, name: 'Db Check', email, passwordHash: 'hash', now: t });
  assert.equal(a.id, userId);
  assert.equal(typeof a.created_at, 'number', 'BIGINT must come back as a number');
  const b = await repo.createUser({ id: randomUUID(), name: 'Other', email, passwordHash: 'x', now: t });
  assert.equal(b.id, userId);
});

await step('findUserByEmail / findUserById', async () => {
  assert.equal((await repo.findUserByEmail(email)).id, userId);
  assert.equal((await repo.findUserById(userId)).email, email);
  assert.equal(await repo.findUserByEmail('nobody@example.invalid'), undefined);
});

await step('setLoginFailures / markVerified', async () => {
  await repo.setLoginFailures(userId, 3, t + 1000, t);
  const u = await repo.findUserById(userId);
  assert.equal(u.failed_login_count, 3);
  assert.equal(u.locked_until, t + 1000);
  await repo.markVerified(userId, t);
  assert.equal((await repo.findUserById(userId)).email_verified_at, t);
});

const code1 = randomUUID();
const code2 = randomUUID();

await step('replaceCode / latestCode / countCodesSince (newest wins, old one retired)', async () => {
  await repo.replaceCode({ id: code1, userId, purpose: 'verify_email', codeHash: 'h1', expiresAt: t + 60000, createdAt: t });
  await repo.replaceCode({ id: code2, userId, purpose: 'verify_email', codeHash: 'h2', expiresAt: t + 60000, createdAt: t });
  assert.equal((await repo.latestCode(userId, 'verify_email')).id, code2);
  assert.equal(await repo.countCodesSince(userId, 'verify_email', t - 1), 2);
  assert.equal(await repo.countCodesSince(userId, 'reset_password', t - 1), 0);
});

await step('claimAttempt stops at the limit, even when guesses run in parallel', async () => {
  const results = await Promise.all(Array.from({ length: 10 }, () => repo.claimAttempt(code2, 5)));
  assert.equal(results.filter((r) => r !== null).length, 5);
  assert.equal(await repo.claimAttempt(code2, 5), null);
});

await step('consumeCode works exactly once', async () => {
  const results = await Promise.all([repo.consumeCode(code2, t), repo.consumeCode(code2, t)]);
  assert.deepEqual(results.sort(), [false, true]);
});

await step('deleteCode', async () => {
  await repo.deleteCode(code1);
});

const sessionId = randomUUID();

await step('createSession / find by access and refresh hash', async () => {
  await repo.createSession({
    id: sessionId, userId, accessHash: `a-${sessionId}`, accessExpiresAt: t + 1000,
    refreshHash: `r-${sessionId}`, refreshExpiresAt: t + 2000, now: t,
  });
  assert.equal((await repo.findSessionByAccessHash(`a-${sessionId}`)).id, sessionId);
  assert.equal((await repo.findSessionByRefreshHash(`r-${sessionId}`)).user_id, userId);
});

await step('rotateSession: one of two parallel refreshes wins; a stale token loses', async () => {
  const next = (n) => ({ accessHash: `a2-${n}-${sessionId}`, accessExpiresAt: t + 3000, refreshHash: `r2-${n}-${sessionId}`, refreshExpiresAt: t + 4000 });
  const results = await Promise.all([
    repo.rotateSession(sessionId, `r-${sessionId}`, next(1)),
    repo.rotateSession(sessionId, `r-${sessionId}`, next(2)),
  ]);
  assert.deepEqual(results.sort(), [false, true]);
  assert.equal(await repo.rotateSession(sessionId, `r-${sessionId}`, next(3)), false);
});

await step('updatePasswordAndRevokeSessions (transaction)', async () => {
  await repo.updatePasswordAndRevokeSessions({ userId, passwordHash: 'new-hash', now: t + 5 });
  const u = await repo.findUserById(userId);
  assert.equal(u.password_hash, 'new-hash');
  assert.equal(u.failed_login_count, 0);
  assert.equal(u.locked_until, null);
  const { rows } = await pool.query('SELECT revoked_at FROM sessions WHERE user_id = $1', [userId]);
  assert.ok(rows.every((r) => r.revoked_at === t + 5));
});

await step('revokeSession / purgeExpired run without error', async () => {
  await repo.revokeSession(sessionId, t);
  await repo.purgeExpired(t + 365 * 24 * 60 * 60 * 1000);
});

await pool.query('DELETE FROM users WHERE id = $1', [userId]).catch(() => {});
await pool.end();

if (failed) {
  console.error('\nSome checks failed. Did you run "npm run db:migrate" first?');
  process.exit(1);
}
console.log('\nAll database checks passed.');