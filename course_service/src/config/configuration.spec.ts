import { loadConfig } from './configuration';

const base = { DATABASE_URL: 'postgresql://u:p@localhost:5432/db' };

describe('loadConfig', () => {
  it('applies defaults', () => {
    const config = loadConfig({ ...base });
    expect(config.port).toBe(3001);
    expect(config.database.poolMax).toBe(5);
    expect(config.corsOrigins).toEqual([]);
    expect(config.logLevel).toBe('log');
    expect(config.throttle).toEqual({ limit: 120, ttlMs: 60_000 });
  });

  it('requires a PostgreSQL DATABASE_URL', () => {
    expect(() => loadConfig({})).toThrow(/DATABASE_URL/);
    expect(() => loadConfig({ DATABASE_URL: 'mysql://x' })).toThrow(/DATABASE_URL/);
  });

  it('rejects invalid numbers and log levels', () => {
    expect(() => loadConfig({ ...base, PORT: 'abc' })).toThrow(/PORT/);
    expect(() => loadConfig({ ...base, DB_POOL_MAX: '0' })).toThrow(/DB_POOL_MAX/);
    expect(() => loadConfig({ ...base, LOG_LEVEL: 'loud' })).toThrow(/LOG_LEVEL/);
  });

  it('parses comma-separated CORS origins and forbids * in production', () => {
    expect(loadConfig({ ...base, CORS_ORIGIN: 'https://a.com, https://b.com' }).corsOrigins).toEqual([
      'https://a.com',
      'https://b.com',
    ]);
    expect(() => loadConfig({ ...base, NODE_ENV: 'production', CORS_ORIGIN: '*' })).toThrow(/CORS_ORIGIN/);
  });
});