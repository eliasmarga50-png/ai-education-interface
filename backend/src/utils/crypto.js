import {
  createHash,
  createHmac,
  randomBytes,
  randomInt,
  scrypt,
  timingSafeEqual,
} from 'node:crypto';
import { promisify } from 'node:util';

const scryptAsync = promisify(scrypt);
const N = 16384;
const R = 8;
const P = 1;
const KEY_LEN = 64;
const MAXMEM = 64 * 1024 * 1024;

/** scrypt is built into Node: memory-hard, and nothing to compile on Termux. */
export async function hashPassword(password) {
  const salt = randomBytes(16);
  const hash = await scryptAsync(password, salt, KEY_LEN, { N, r: R, p: P, maxmem: MAXMEM });
  return `scrypt$${N}$${R}$${P}$${salt.toString('base64')}$${hash.toString('base64')}`;
}

export async function verifyPassword(password, stored) {
  const parts = String(stored).split('$');
  if (parts.length !== 6 || parts[0] !== 'scrypt') return false;
  const [, n, r, p, saltB64, hashB64] = parts;
  const expected = Buffer.from(hashB64, 'base64');
  const actual = await scryptAsync(password, Buffer.from(saltB64, 'base64'), expected.length, {
    N: Number(n),
    r: Number(r),
    p: Number(p),
    maxmem: MAXMEM,
  });
  return timingSafeEqual(actual, expected);
}

/** Opaque random token (sent to the client) */
export const randomToken = (bytes = 32) => randomBytes(bytes).toString('base64url');

/** Only the hash of a token is stored, so a database leak cannot be replayed. */
export const sha256Hex = (value) => createHash('sha256').update(value).digest('hex');

/** 6-digit code from a CSPRNG (not Math.random). */
export const generateCode = () => String(randomInt(0, 1_000_000)).padStart(6, '0');

/** Codes are small (1,000,000 options), so they are HMAC'd with a server secret and bound to user + purpose. */
export const hmacCode = (code, secret, userId, purpose) =>
  createHmac('sha256', secret).update(`${userId}:${purpose}:${code}`).digest('hex');

export function safeEqual(a, b) {
  const x = Buffer.from(a);
  const y = Buffer.from(b);
  return x.length === y.length && timingSafeEqual(x, y);
}