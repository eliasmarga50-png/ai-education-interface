import { createApp } from './app.js';
import { loadConfig } from './config/env.js';
import { createPool } from './db/database.js';
import { AuthRepository } from './modules/auth/auth.repository.js';
import { createAuthService } from './modules/auth/auth.service.js';
import { createEmailChecker } from './modules/auth/emailCheck.js';
import { ProfileRepository } from './modules/profile/profile.repository.js';
import { createProfileService } from './modules/profile/profile.service.js';
import { createTutorService } from './modules/tutor/tutor.service.js';
import { createMailer } from './services/mail/mailer.js';

const onVercel = Boolean(process.env.VERCEL);

let config;
let pool;
let authService;
let app;

try {
  config = loadConfig();
  pool = createPool(config.databaseUrl, { max: config.dbPoolMax });
  authService = createAuthService({
    repo: new AuthRepository(pool),
    mailer: createMailer(config.mail),
    emailChecker: createEmailChecker(),
    config,
  });
  app = createApp({
    authService,
    profileService: createProfileService({ repo: new ProfileRepository(pool) }),
    tutorService: createTutorService({ config }),
    config,
  });

} catch (err) {
  console.error(`\nConfiguration error: ${err.message}\n`);
  if (!onVercel) process.exit(1);

  // Exiting would only show Vercel's generic crash page. Answer every request with a
  // clear error instead; the real reason is in the function logs.
  app = (req, res) => {
    res.statusCode = 500;
    res.setHeader('Content-Type', 'application/json');
    res.end(
      JSON.stringify({
        error: { code: 'SERVER_MISCONFIGURED', message: 'The server is not configured correctly. See the Vercel function logs.' },
      }),
    );
  };
}

export default app;

if (!onVercel) {
  // Fail fast with a readable message instead of a 500 on the first request.
  try {
    await pool.query('SELECT 1');
  } catch (err) {
    console.error(`\nCould not connect to the database: ${err.message}\nCheck DATABASE_URL in backend/.env.\n`);
    process.exit(1);
  }

  // Express 5 passes a listen error (for example "port already in use") to the
  // callback of app.listen, so a "listening" message there could be false.
  // Listen for the real events instead.
  const server = app.listen(config.port, '0.0.0.0');

  server.once('listening', () => {
    console.log(`API listening on http://0.0.0.0:${config.port}  (env: ${config.nodeEnv}, mail: ${config.mail.mode})`);
  });

  server.once('error', async (err) => {
    if (err.code === 'EADDRINUSE') {
      console.error(`\nPort ${config.port} is already in use by another program.\nStop it, or set PORT=<another number> in backend/.env.\n`);
    } else {
      console.error('\nServer failed to start:', err.message, '\n');
    }
    await pool.end().catch(() => {});
    process.exit(1);
  });

  // Housekeeping: drop expired sessions, old codes and abandoned unverified accounts.
  const purge = () => authService.purgeExpired().catch((err) => console.error('[purge] failed:', err.message));
  purge();
  setInterval(purge, 60 * 60 * 1000).unref();

  const shutdown = (signal) => {
    console.log(`\n${signal} received, shutting down...`);
    server.close(async () => {
      await pool.end().catch(() => {});
      process.exit(0);
    });
    setTimeout(() => process.exit(1), 5000).unref();
  };
  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
}