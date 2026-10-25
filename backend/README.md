# Backend (Express + PostgreSQL)

```bash
cp .env.example .env     # fill in DATABASE_URL and AUTH_CODE_SECRET
npm install
npm run db:migrate       # creates / updates the tables (safe to repeat)
npm start
npm test                 # unit tests, no database needed
npm run db:check         # checks every repository method against your database
```

## Endpoints

| Method and path | Auth | Purpose |
| --- | --- | --- |
| `POST /api/auth/register` `verify-email` `resend-code` `login` `refresh` `logout` `forgot-password` `reset-password` | no | Sign-up and session |
| `GET /api/auth/me` | yes | The signed-in account |
| `POST /api/auth/change-password` `{currentPassword, newPassword}` | yes | New password; other devices signed out; returns fresh tokens |
| `POST /api/auth/logout-all` | yes | Ends every session |
| `POST /api/auth/delete-account` `{password}` | yes | Deletes the account (cascades to sessions, codes, photo) |
| `GET /api/profile` | yes | `{ profile: { id, name, email, isVerified, bio, avatar: {updatedAt}\|null, preferences, createdAt } }` |
| `PATCH /api/profile` `{name?, bio?}` | yes | Name (2-60 letters) and bio (max 160 characters) |
| `PATCH /api/profile/preferences` | yes | `learningGoal`, `preferredDifficulty`, `aiAssistance`, `dailyReminders`, `dailyGoalMinutes` (5-240) |
| `GET / PUT / DELETE /api/profile/avatar` | yes | Photo as base64 JSON (JPEG, PNG or WebP, max 300 KB) |
| `POST /api/tutor/reply` | yes | AI Tutor (see docs/ai-tutor-setup.md) |

Profile endpoints never take a user id: they always act on the account that owns the access token.
Errors look like `{ "error": { "code": "VALIDATION_ERROR", "message": "..." } }`.