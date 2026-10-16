import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Pool, QueryResult, QueryResultRow } from 'pg'; 

import { AppConfig } from '../config/configuration';

@Injectable()
export class DatabaseService implements OnModuleDestroy {
  private readonly logger = new Logger(DatabaseService.name);
  private readonly pool: Pool;

  constructor(config: ConfigService<{ app: AppConfig }, true>) {
    const { url, poolMax } = config.get('app', { infer: true }).database;
    this.pool = new Pool({
      connectionString: url,
      max: poolMax,
      connectionTimeoutMillis: 10_000,
      idleTimeoutMillis: 30_000,
      statement_timeout: 5_000,
    });
    this.pool.on('error', (err: Error) => this.logger.error(`Idle database client error: ${err.message}`));
  }

  query<T extends QueryResultRow>(text: string, params: unknown[] = []): Promise<QueryResult<T>> {
    return this.pool.query<T>(text, params);
  }

  async ping(): Promise<void> {
    await this.pool.query('SELECT 1');
  }

  async onModuleDestroy(): Promise<void> {
    await this.pool.end();
  }
}