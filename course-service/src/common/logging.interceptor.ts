import { CallHandler, ExecutionContext, HttpException, Injectable, Logger, NestInterceptor } from '@nestjs/common';
import type { Request, Response } from 'express';
import { Observable, tap } from 'rxjs';

/** One line per request: METHOD /path STATUS 12ms. Query strings are logged as sent (no secrets travel there). */
@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const http = context.switchToHttp();
    const req = http.getRequest<Request>();
    const started = Date.now();
    const line = (status: number) =>
      this.logger.log(`${req.method} ${req.originalUrl} ${status} ${Date.now() - started}ms`);

    return next.handle().pipe(
      tap({
        next: () => line(http.getResponse<Response>().statusCode),
        error: (err: unknown) => line(err instanceof HttpException ? err.getStatus() : 500),
      }),
    );
  }
}