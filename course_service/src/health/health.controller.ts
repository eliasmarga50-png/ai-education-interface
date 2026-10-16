import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { DatabaseService } from '../database/database.service';

@Controller('health')
export class HealthController {
  constructor(private readonly db: DatabaseService) {}

  @Get()
  async check() {
    try {
      await this.db.ping();
    } catch {
      throw new ServiceUnavailableException('The database is unreachable.');
    }
    return { status: 'ok' };
  }
}