import { Router } from 'express';
import { authenticate } from '../../middleware/authenticate.js';
import { tutorLimiter } from '../../middleware/rateLimit.js';

/** POST /api/tutor/reply  { question, history: [{role, text}], lesson?: {title, course} }  ->  { reply } */
export function createTutorRouter({ authService, tutorService }) {
  const router = Router();
  router.post('/reply', authenticate(authService), tutorLimiter, async (req, res) => {
    res.json(await tutorService.reply(req.body));
  });
  return router;
}