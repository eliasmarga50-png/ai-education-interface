import { AppError } from '../utils/AppError.js';

/** Protects a route: requires "Authorization: Bearer <accessToken>" and sets req.user. */
export function authenticate(authService) {
  return async (req, res, next) => {
    const header = req.get('authorization') || '';
    const [scheme, token] = header.split(' ');
    if (scheme?.toLowerCase() !== 'bearer' || !token) {
      return next(new AppError(401, 'UNAUTHORIZED', 'Please log in again.'));
    }
    try {
      req.user = await authService.authenticate(token);
      next();
    } catch (err) {
      next(err);
    }
  };
}