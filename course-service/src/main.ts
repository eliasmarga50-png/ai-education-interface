import 'reflect-metadata';
import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { configureApp } from './app.setup';
import { AppConfig, LOG_LEVELS } from './config/configuration';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create<NestExpressApplication>(AppModule, { bufferLogs: true });
  const config = app.get<ConfigService<{ app: AppConfig }, true>>(ConfigService).get('app', { infer: true });

  app.useLogger([...LOG_LEVELS].slice(0, LOG_LEVELS.indexOf(config.logLevel) + 1));
  if (config.trustProxy > 0) app.set('trust proxy', config.trustProxy);
  app.use(helmet());
  if (config.corsOrigins.length > 0) {
    app.enableCors({ origin: config.corsOrigins.includes('*') ? true : config.corsOrigins });
  }
  configureApp(app);
  app.enableShutdownHooks();

  await app.listen(config.port, '0.0.0.0');
  Logger.log(`Course service listening on port ${config.port} (env: ${config.nodeEnv})`, 'Bootstrap');
}

bootstrap().catch((err: unknown) => {
  console.error(`\nCourse service failed to start: ${err instanceof Error ? err.message : err}\n`);
  process.exit(1);
});