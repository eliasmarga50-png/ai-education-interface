import { Router } from 'express';
import { authenticate } from '../../middleware/authenticate.js';
import { sensitiveLimiter } from '../../middleware/rateLimit.js';
import { createAuthController } from './auth.controller.js';

export function createAuthRouter(authService) {
  const c = createAuthController(authService);
  const router = Router();

  router.post('/register', sensitiveLimiter, c.register);
  router.post('/verify-email', sensitiveLimiter, c.verifyEmail);
  router.post('/resend-code', sensitiveLimiter, c.resendCode);
  router.post('/login', sensitiveLimiter, c.login);
  router.post('/forgot-password', sensitiveLimiter, c.forgotPassword);
  router.post('/reset-password', sensitiveLimiter, c.resetPassword);

  router.post('/refresh', c.refresh);
  router.post('/logout', c.logout);
  router.get('/me', authenticate(authService), c.me);

  // Signed-in account actions (Profile > Privacy).
  router.post('/change-password', authenticate(authService), sensitiveLimiter, c.changePassword);
  router.post('/logout-all', authenticate(authService), c.logoutAll);
  router.post('/delete-account', authenticate(authService), sensitiveLimiter, c.deleteAccount);

  return router;
}