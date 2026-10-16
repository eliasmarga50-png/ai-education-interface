import { Client } from '../node_modules/@types/pg';

/** Loads .env if present; real environment variables always win. */
export function loadEnv(): void {
  try {
    process.loadEnvFile();
  } catch (err) {
    if ((err as NodeJS.ErrnoException).code !== 'ENOENT') throw err;
  }
}

export async function connect(): Promise<Client> {
  loadEnv();
  // Schema changes prefer the provider's direct (non-pooled) connection when you have one.
  const url = process.env.DATABASE_URL_DIRECT || process.env.DATABASE_URL;
  if (!url) {
    console.error('DATABASE_URL is not set. Copy .env.example to .env and fill it in.');
    process.exit(1);
  }
  const client = new Client({ connectionString: url, connectionTimeoutMillis: 15_000 });
  await client.connect();
  return client;
}