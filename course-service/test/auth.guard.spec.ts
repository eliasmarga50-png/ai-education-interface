import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { createHash } from 'node:crypto';
import { AuthGuard } from '../src/auth/auth.guard';

const sha = (v: string) => createHash('sha256').update(v).digest('hex');

function context(authorization?: string) {
  const req: {
    user?: { id: string };
    get: (name: string) => string | undefined;
  } = {
    get: (name) =>
      name.toLowerCase() === 'authorization' ? authorization : undefined,
  };
  return {
    req,
    ctx: {
      switchToHttp: () => ({ getRequest: () => req }),
    } as unknown as ExecutionContext,
  };
}

describe('AuthGuard', () => {
  it('looks up the SHA-256 of the token among live sessions and sets the user', async () => {
    const query = jest.fn().mockResolvedValue({ rows: [{ userId: 'user-1' }] });
    const { req, ctx } = context('Bearer secret-token');

    await expect(
      new AuthGuard({ query } as never).canActivate(ctx),
    ).resolves.toBe(true);

    expect(req.user).toEqual({ id: 'user-1' });
    const [sql, params] = query.mock.calls[0];
    expect(sql).toContain('revoked_at IS NULL');
    expect(sql).toContain('access_expires_at >');
    expect(params[0]).toBe(sha('secret-token')); // the raw token is never sent to the database
    expect(Math.abs((params[1] as number) - Date.now())).toBeLessThan(5_000);
  });

  it('accepts the scheme in any letter case', async () => {
    const query = jest.fn().mockResolvedValue({ rows: [{ userId: 'u' }] });
    await expect(
      new AuthGuard({ query } as never).canActivate(context('bearer abc').ctx),
    ).resolves.toBe(true);
  });

  it.each([[undefined], [''], ['Bearer'], ['Basic abc'], ['Bearer ']])(
    'rejects the header %j without touching the database',
    async (header) => {
      const query = jest.fn();
      await expect(
        new AuthGuard({ query } as never).canActivate(context(header).ctx),
      ).rejects.toBeInstanceOf(UnauthorizedException);
      expect(query).not.toHaveBeenCalled();
    },
  );

  it('rejects a token with no live session', async () => {
    const query = jest.fn().mockResolvedValue({ rows: [] });
    await expect(
      new AuthGuard({ query } as never).canActivate(
        context('Bearer expired').ctx,
      ),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });
});