import { ArgumentsHost, Catch, ExceptionFilter, HttpException, Logger } from '@nestjs/common';
import type { Request, Response } from 'express';

const CODES: Record<number, string> = {
  400: 'BAD_REQUEST',
  401: 'UNAUTHORIZED',
  403: 'FORBIDDEN',
  404: 'NOT_FOUND',
  422: 'VALIDATION_ERROR',
  429: 'RATE_LIMITED',
  503: 'SERVICE_UNAVAILABLE',
};

/** Same envelope as the auth backend: { error: { code, message, fields? } }. */
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger('Exceptions');

  catch(exception: unknown, host: ArgumentsHost): void {
    const http = host.switchToHttp();
    const res = http.getResponse<Response>();
    const req = http.getRequest<Request>();

    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const raw = exception.getResponse();
      const body = (typeof raw === 'string' ? { message: raw } : raw) as {
        message?: unknown;
        fields?: Record<string, string>;
      };
      const message = Array.isArray(body.message)
        ? String(body.message[0])
        : typeof body.message === 'string'
          ? body.message
          : exception.message;

      if (status >= 500) this.logger.error(`${req.method} ${req.originalUrl} -> ${status}: ${message}`);

      res.status(status).json({
        error: { code: CODES[status] ?? 'SERVER_ERROR', message, ...(body.fields ? { fields: body.fields } : {}) },
      });
      return;
    }

    const detail = exception instanceof Error ? (exception.stack ?? exception.message) : String(exception);
    this.logger.error(`${req.method} ${req.originalUrl} -> unhandled: ${detail}`);
    res.status(500).json({
      error: { code: 'SERVER_ERROR', message: 'Something went wrong on our side. Please try again.' },
    });
  }
}