import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import { errorHandler, notFound } from './middleware/errorHandler.js';
import { generalLimiter } from './middleware/rateLimit.js';
import { createAuthRouter } from './modules/auth/auth.routes.js';
import { createProfileRouter } from './modules/profile/profile.routes.js';
import { createTutorRouter } from './modules/tutor/tutor.routes.js';
import { safeEqual } from './utils/crypto.js';

export function createApp({ authService, profileService, tutorService, config }) {
  const app = express();

  app.disable('x-powered-by');
  // Number of proxies in front of us (1 on Vercel). Needed so req.ip, and therefore the
  // per-IP rate limit, sees the real client instead of the proxy.
  if (config.trustProxy > 0) app.set('trust proxy', config.trustProxy);

  app.use(helmet());
  if (config.corsOrigin) {
    const origins = config.corsOrigin === '*' ? true : config.corsOrigin.split(',').map((o) => o.trim());
    app.use(cors({ origin: origins }));
  }
  // Chat history is larger than a login body. Parsed first, so the 10kb parser below skips it.
  app.use('/api/tutor', express.json({ limit: '64kb' }));
  // A profile photo travels as base64 (max 300 KB decoded, about 400 KB encoded).
  app.use('/api/profile/avatar', express.json({ limit: '600kb' }));
  app.use(express.json({ limit: '10kb' }));
  app.use(generalLimiter);

  app.get('/health', (req, res) => res.json({ status: 'ok' }));

  // Called daily by Vercel Cron (vercel.json). Vercel sends "Authorization: Bearer <CRON_SECRET>".
  // Without CRON_SECRET the route does not exist.
  app.get('/api/internal/purge', async (req, res) => {
    if (!config.cronSecret) return notFound(req, res);
    if (!safeEqual(req.get('authorization') || '', `Bearer ${config.cronSecret}`)) {
      return res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Invalid cron secret.' } });
    }
    await authService.purgeExpired();
    res.json({ ok: true });
  });
  app.use('/api/auth', createAuthRouter(authService));
  if (profileService) app.use('/api/profile', createProfileRouter({ authService, profileService }));
  if (tutorService) app.use('/api/tutor', createTutorRouter({ authService, tutorService }));

  app.use(notFound);
  app.use(errorHandler);
  return app;
}