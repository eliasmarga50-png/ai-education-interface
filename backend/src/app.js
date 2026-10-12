import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import { errorHandler, notFound } from './middleware/errorHandler.js';
import { generalLimiter } from './middleware/rateLimit.js';
import { createAuthRouter } from './modules/auth/auth.routes.js';
import { safeEqual } from './utils/crypto.js';

export function createApp({ authService, config }) {
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

  app.use(notFound);
  app.use(errorHandler);
  return app;
}