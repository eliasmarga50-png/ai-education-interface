import { UnprocessableEntityException, ValidationError, ValidationPipe } from '@nestjs/common';

function collect(errors: ValidationError[], prefix = '', out: Record<string, string> = {}) {
  for (const error of errors) {
    const path = prefix ? `${prefix}.${error.property}` : error.property;
    if (error.constraints) out[path] = Object.values(error.constraints)[0];
    if (error.children?.length) collect(error.children, path, out);
  }
  return out;
}

/** Validates and converts input, rejects unknown query params, answers 422 with per-field messages. */
export function createValidationPipe(): ValidationPipe {
  return new ValidationPipe({
    transform: true,
    whitelist: true,
    forbidNonWhitelisted: true,
    exceptionFactory: (errors) => {
      const fields = collect(errors);
      return new UnprocessableEntityException({
        message: Object.values(fields)[0] ?? 'Validation failed.',
        fields,
      });
    },
  });
}