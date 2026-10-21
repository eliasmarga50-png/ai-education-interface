import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
  createParamDecorator,
} from '@nestjs/common';
import type { Request } from 'express';
import { createHash } from 'node:crypto';
import { DatabaseService } from '../database/database.service';

export interface AuthUser {
  id: string;
}

type AuthedRequest = Request & { user?: AuthUser };

const unauthorized = () => new UnauthorizedException('Please log in again.');

/**
 * Accepts the same "Authorization: Bearer <accessToken>" the auth backend hands out.
 *
 * The auth backend stores only the SHA-256 of each access token in the `sessions` table. This
 * service shares that database, so it checks the token the same way instead of calling the
 * auth backend on every request: the hash must exist, not be revoked and not be expired.
 */
@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private readonly db: DatabaseService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest<AuthedRequest>();
    const [scheme, token] = (req.get('authorization') ?? '').split(' ');
    if (scheme?.toLowerCase() !== 'bearer' || !token) throw unauthorized();

    const hash = createHash('sha256').update(token).digest('hex');
    const { rows } = await this.db.query<{ userId: string }>(
      `SELECT s.user_id AS "userId"
         FROM sessions s
         JOIN users u ON u.id = s.user_id
        WHERE s.access_hash = $1 AND s.revoked_at IS NULL AND s.access_expires_at > $2`,
      [hash, Date.now()],
    );
    if (!rows[0]) throw unauthorized();

    req.user = { id: rows[0].userId };
    return true;
  }
}

/** The signed-in student, as set by [AuthGuard]. */
export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): AuthUser => {
    return ctx.switchToHttp().getRequest<AuthedRequest>().user as AuthUser;
  },
);