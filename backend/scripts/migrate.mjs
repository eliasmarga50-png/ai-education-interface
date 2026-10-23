// Creates the tables. Safe to run again.   npm run db:migrate
import { readFileSync } from 'node:fs';
import pg from 'pg';

// Schema changes are best sent over the provider's DIRECT connection when you have
// one (Neon: the non-pooled string). Plain CREATE TABLE also works through the pooler.
const url = process.env.DATABASE_URL_DIRECT || process.env.DATABASE_URL;
if (!url) {
  console.error('DATABASE_URL is not set. Add it to backend/.env first.');
  process.exit(1);
}

const sql = readFileSync(new URL('../src/db/schema.sql', import.meta.url), 'utf8');
const client = new pg.Client({ connectionString: url, connectionTimeoutMillis: 15_000 });

try {
  await client.connect();
  await client.query(sql);
  const { rows } = await client.query(
    `SELECT table_name FROM information_schema.tables
      WHERE table_schema = 'public' AND table_name IN ('users', 'verification_codes', 'sessions', 'user_avatars')
      ORDER BY table_name`,
  );
  console.log('Tables ready:', rows.map((r) => r.table_name).join(', '));
  if (rows.length !== 4) process.exitCode = 1;
} catch (err) {
  console.error('Migration failed:', err.message);
  process.exitCode = 1;
} finally {
  await client.end().catch(() => {});
}