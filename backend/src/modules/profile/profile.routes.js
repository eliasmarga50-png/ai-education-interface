import { Router } from 'express';
import { authenticate } from '../../middleware/authenticate.js';
import { profileLimiter } from '../../middleware/rateLimit.js';

/**
 * Everything here needs a logged-in user and only ever touches THAT user's row (req.user.id);
 * there is no id in any URL, so one student can never read or edit another one's profile.
 *
 *   GET    /api/profile              -> { profile }
 *   PATCH  /api/profile              { name?, bio? }            -> { profile }
 *   PATCH  /api/profile/preferences  { learningGoal?, preferredDifficulty?, aiAssistance?,
 *                                      dailyReminders?, dailyGoalMinutes? } -> { profile }
 *   GET    /api/profile/avatar       -> { avatar: { contentType, data (base64), updatedAt } } | 404 NO_AVATAR
 *   PUT    /api/profile/avatar       { contentType, data (base64, max 300 KB) } -> { avatar: { updatedAt } }
 *   DELETE /api/profile/avatar       -> { ok }
 */
export function createProfileRouter({ authService, profileService }) {
  const router = Router();
  router.use(authenticate(authService), profileLimiter);

  router.get('/', async (req, res) => res.json(await profileService.getProfile(req.user.id)));
  router.patch('/', async (req, res) => res.json(await profileService.updateProfile(req.user.id, req.body)));
  router.patch('/preferences', async (req, res) =>
    res.json(await profileService.updatePreferences(req.user.id, req.body)),
  );

  router.get('/avatar', async (req, res) => res.json(await profileService.getAvatar(req.user.id)));
  router.put('/avatar', async (req, res) => res.json(await profileService.setAvatar(req.user.id, req.body)));
  router.delete('/avatar', async (req, res) => res.json(await profileService.deleteAvatar(req.user.id)));

  return router;
}