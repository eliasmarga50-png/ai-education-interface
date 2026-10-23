import rateLimit, { ipKeyGenerator } from 'express-rate-limit';

const handler = (req, res) => {
  res.status(429).json({
    error: { code: 'RATE_LIMITED', message: 'Too many requests. Please wait a few minutes and try again.' },
  });
};

/** Per IP address. Sensitive endpoints (login, codes) get the strict one. */
export const sensitiveLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  standardHeaders: true,
  legacyHeaders: false,
  handler,
});

/** Each tutor answer costs a Gemini request (the free tier is small), so this is per logged-in user. */
export const tutorLimiter = rateLimit({
  windowMs: 60 * 1000,
  limit: 10,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => (req.user?.id ? String(req.user.id) : ipKeyGenerator(req.ip)),
  handler: (req, res) => {
    res.status(429).json({
      error: { code: 'RATE_LIMITED', message: 'You are asking very quickly. Wait a moment and try again.' },
    });
  },
});

export const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 300,
  standardHeaders: true,
  legacyHeaders: false,
  handler,
});