import pg from 'pg';

const { Pool, types } = pg;

// node-postgres returns BIGINT (and COUNT(*)) as strings because they can exceed
// JavaScript's safe integer range. Ours are epoch milliseconds and small counters,
// which are far below 2^53, so convert them to numbers.
types.setTypeParser(20, (value) => Number(value));

/**
 * One pool per process. Keep it small: on serverless every running instance has
 * its own pool, and the provider's pooled connection string (Neon "-pooler",
 * Supabase transaction pooler) does the real sharing.
 */
export function createPool(databaseUrl, { max = 5 } = {}) {
  const pool = new Pool({
    connectionString: databaseUrl,
    max,
    idleTimeoutMillis: 10_000,
    connectionTimeoutMillis: 10_000,
  });

  // Without this handler a dropped idle connection would crash the whole process.
  pool.on('error', (err) => console.error('[db] idle connection error:', err.message));
  return pool;
}