import { timingSafeEqual } from 'node:crypto';

/** Only the Node.js backend may call this service: it must send x-internal-key. */
export function internalAuth(expectedKey) {
  const expected = Buffer.from(expectedKey);
  return (req, res, next) => {
    const given = Buffer.from(req.get('x-internal-key') || '');
    if (given.length !== expected.length || !timingSafeEqual(given, expected)) {
      return res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Invalid internal key.' } });
    }
    next();
  };
}