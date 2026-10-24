/**
 * In-memory stand-in for ProfileRepository. It reads and writes the SAME user rows as the
 * MemoryAuthRepository it is given, like the real tables share one database.
 */
export class MemoryProfileRepository {
  constructor(authRepo) {
    this.authRepo = authRepo;
    this.avatars = new Map();
    authRepo.avatars = this.avatars;
  }

  async getProfileRow(userId) {
    const u = this.authRepo.users.get(userId);
    if (!u) return undefined;
    return {
      id: u.id,
      name: u.name,
      email: u.email,
      email_verified_at: u.email_verified_at,
      bio: u.bio ?? '',
      preferences: u.preferences ?? {},
      created_at: u.created_at,
      avatar_updated_at: this.avatars.get(userId)?.updated_at ?? null,
    };
  }

  async updateIdentity(userId, { name, bio, now }) {
    const u = this.authRepo.users.get(userId);
    if (name != null) u.name = name;
    if (bio != null) u.bio = bio;
    u.updated_at = now;
  }

  async mergePreferences(userId, patch, now) {
    const u = this.authRepo.users.get(userId);
    u.preferences = { ...(u.preferences ?? {}), ...patch };
    u.updated_at = now;
  }

  async getAvatar(userId) {
    return this.avatars.get(userId);
  }

  async saveAvatar({ userId, contentType, data, now }) {
    this.avatars.set(userId, { content_type: contentType, data, updated_at: now });
  }

  async deleteAvatar(userId) {
    this.avatars.delete(userId);
  }
}