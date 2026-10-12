const num = (value, fallback) => {
  if (value === undefined || value === '') return fallback;
  const n = Number(value);
  return Number.isFinite(n) ? n : fallback;
};

/**
 * TRUST_PROXY = how many reverse proxies sit in front of the app (0 = none).
 * Behind Vercel it must be 1, otherwise every user looks like the same IP address
 * and the per-IP rate limit blocks everybody together. "true" is refused on purpose:
 * it trusts any X-Forwarded-For header, which lets a client fake its IP.
 */
function parseTrustProxy(raw, onVercel) {
  if (raw === undefined || raw === '') return onVercel ? 1 : 0;
  const hops = Number(raw);
  if (!Number.isInteger(hops) || hops < 0 || hops > 5) {
    throw new Error(
      'TRUST_PROXY must be a whole number of proxies (0 = none, 1 = one proxy such as Vercel).\n' +
        '"true" is not accepted because it lets clients fake their IP address.',
    );
  }
  return hops;
}

/**
 * Chooses how verification codes are delivered.
 *   MAIL_MODE=resend   Resend HTTP API   (needs RESEND_API_KEY, MAIL_FROM)
 *   MAIL_MODE=smtp     any SMTP server   (needs SMTP_HOST, SMTP_USER, SMTP_PASS, MAIL_FROM)
 *   MAIL_MODE=console  prints the code in the terminal (development only)
 * When MAIL_MODE is empty it is detected: a Resend key wins, then SMTP settings, then console.
 */
function resolveMail(env, isProd) {
  const hasResend = Boolean(env.RESEND_API_KEY);
  const hasSmtp = Boolean(env.SMTP_HOST && env.SMTP_USER && env.SMTP_PASS);

  let mode = (env.MAIL_MODE || '').trim().toLowerCase();
  if (!mode) mode = hasResend ? 'resend' : hasSmtp ? 'smtp' : 'console';

  if (!['console', 'smtp', 'resend'].includes(mode)) {
    throw new Error('MAIL_MODE must be "console", "smtp" or "resend".');
  }

  if (mode === 'console' && isProd) {
    throw new Error(
      'No email provider is configured, and console mode is not allowed in production ' +
        '(the codes would be printed to the logs).\n' +
        'Set RESEND_API_KEY (MAIL_MODE=resend) or SMTP_HOST, SMTP_USER and SMTP_PASS (MAIL_MODE=smtp), plus MAIL_FROM.',
    );
  }

  const required = { resend: ['RESEND_API_KEY', 'MAIL_FROM'], smtp: ['SMTP_HOST', 'SMTP_USER', 'SMTP_PASS', 'MAIL_FROM'], console: [] }[mode];
  for (const key of required) {
    if (!env[key]) throw new Error(`${key} is required when MAIL_MODE=${mode}.`);
  }

  return Object.freeze({
    mode,
    from: env.MAIL_FROM || 'AI Education <no-reply@localhost>',
    resendApiKey: env.RESEND_API_KEY,
    host: env.SMTP_HOST,
    port: num(env.SMTP_PORT, 465),
    user: env.SMTP_USER,
    pass: env.SMTP_PASS,
  });
}

export function loadConfig(env = process.env) {
  const nodeEnv = env.NODE_ENV || 'development';
  const isProd = nodeEnv === 'production';
  const onVercel = Boolean(env.VERCEL);

  const databaseUrl = env.DATABASE_URL || '';
  if (!/^postgres(ql)?:\/\//i.test(databaseUrl)) {
    throw new Error(
      'DATABASE_URL is missing or is not a PostgreSQL address.\n' +
        'Create a free database (Neon or Supabase) and copy its connection string into backend/.env:\n' +
        '  DATABASE_URL=postgresql://user:password@host/dbname?sslmode=require',
    );
  }

  const codeSecret = env.AUTH_CODE_SECRET || '';
  if (codeSecret.length < 32) {
    throw new Error(
      'AUTH_CODE_SECRET is missing or shorter than 32 characters.\n' +
        'Generate one with:\n' +
        `  node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"`,
    );
  }

  if (isProd && (env.CORS_ORIGIN || '') === '*') {
    throw new Error('CORS_ORIGIN=* is not allowed in production. List your real origins (native apps need none).');
  }

  // Optional: lets Vercel Cron call /api/internal/purge. Vercel sends it as a Bearer token.
  const cronSecret = env.CRON_SECRET || '';
  if (cronSecret && cronSecret.length < 16) {
    throw new Error('CRON_SECRET must be at least 16 characters.');
  }

  return Object.freeze({
    nodeEnv,
    isProd,
    onVercel,
    port: num(env.PORT, 3000),
    databaseUrl,
    dbPoolMax: num(env.DB_POOL_MAX, onVercel ? 3 : 5),
    trustProxy: parseTrustProxy(env.TRUST_PROXY, onVercel),
    corsOrigin: env.CORS_ORIGIN || '',
    cronSecret,
    mail: resolveMail(env, isProd),
    auth: Object.freeze({
      codeSecret,
      codeTtlMs: 10 * 60 * 1000,
      maxCodeAttempts: 5,
      resendCooldownMs: 60 * 1000,
      maxCodesPerHour: 5,
      maxFailedLogins: 5,
      lockMs: 15 * 60 * 1000,
      accessTtlMs: num(env.ACCESS_TOKEN_TTL_MIN, 15) * 60 * 1000,
      refreshTtlMs: num(env.REFRESH_TOKEN_TTL_DAYS, 30) * 24 * 60 * 60 * 1000,
    }),
  });
}