/** An error whose message is safe to show to the user. */
export class AppError extends Error {
  constructor(statusCode, code, message, extra = {}) {
    super(message);
    this.name = 'AppError';
    this.statusCode = statusCode;
    this.code = code;
    this.extra = extra;
  }

  /** fields: { email: 'message', password: 'message' } */
  static validation(fields) {
    return new AppError(422, 'VALIDATION_ERROR', Object.values(fields)[0], { fields });
  }
}