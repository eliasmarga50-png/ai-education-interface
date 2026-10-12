/** Thin HTTP layer: read the body, call the service, send JSON. Express 5 forwards async errors by itself. */
export function createAuthController(auth) {
  return {
    register: async (req, res) => res.status(201).json(await auth.register(req.body)),
    verifyEmail: async (req, res) => res.json(await auth.verifyEmail(req.body)),
    resendCode: async (req, res) => res.json(await auth.resendCode(req.body)),
    login: async (req, res) => res.json(await auth.login(req.body)),
    refresh: async (req, res) => res.json(await auth.refresh(req.body)),
    logout: async (req, res) => res.json(await auth.logout(req.body)),
    forgotPassword: async (req, res) => res.json(await auth.forgotPassword(req.body)),
    resetPassword: async (req, res) => res.json(await auth.resetPassword(req.body)),
    me: async (req, res) => res.json({ user: req.user }),
  };
}