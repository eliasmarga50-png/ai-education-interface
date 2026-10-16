export const LOG_LEVELS = ['error', 'warn', 'log', 'debug', 'verbose'] as const;
export type AppLogLevel = (typeof LOG_LEVELS)[number];

export interface AppConfig {
  nodeEnv: string;
  isProd: boolean;
  port: number;
  database: { url: string; poolMax: number };
  corsOrigins: string[];
  trustProxy: number;
  throttle: { limit: number; ttlMs: number };
  logLevel: AppLogLevel;
}

function readInt(
  env: NodeJS.ProcessEnv,
  name: string,
  fallback: number,
  min: number,
  max: number,
): number {
  const raw = env[name];
  if (raw === undefined || raw === '') return fallback;
  const value = Number(raw);
  if (!Number.isInteger(value) || value < min || value > max) {
    throw new Error(`${name} must be a whole number between ${min} and ${max}.`);
  }
  return value;
}

/** Reads and validates the environment. Throws a readable error so the app fails fast. */
export function loadConfig(env: NodeJS.ProcessEnv = process.env): AppConfig {
  const nodeEnv = env.NODE_ENV || 'development';
  const isProd = nodeEnv === 'production';

  const url = env.DATABASE_URL || '';
  if (!/^postgres(ql)?:\/\//i.test(url)) {
    throw new Error(
      'DATABASE_URL is missing or is not a PostgreSQL address, e.g. ' +
        'postgresql://user:password@host/dbname?sslmode=require',
    );
  }

  const corsOrigins = (env.CORS_ORIGIN || '')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);
  if (isProd && corsOrigins.includes('*')) {
    throw new Error('CORS_ORIGIN=* is not allowed in production. List your real origins.');
  }

  const logLevel = (env.LOG_LEVEL || 'log') as AppLogLevel;
  if (!LOG_LEVELS.includes(logLevel)) {
    throw new Error(`LOG_LEVEL must be one of: ${LOG_LEVELS.join(', ')}.`);
  }

  return Object.freeze({
    nodeEnv,
    isProd,
    port: readInt(env, 'PORT', 3001, 1, 65535),
    database: { url, poolMax: readInt(env, 'DB_POOL_MAX', 5, 1, 50) },
    corsOrigins,
    trustProxy: readInt(env, 'TRUST_PROXY', 0, 0, 5),
    throttle: {
      limit: readInt(env, 'THROTTLE_LIMIT', 120, 1, 100_000),
      ttlMs: readInt(env, 'THROTTLE_TTL_SECONDS', 60, 1, 3600) * 1000,
    },
    logLevel,
  });
}

/** Loaded by ConfigModule; read with config.get('app', { infer: true }). */
export const configuration = () => ({ app: loadConfig() });