import { Router } from 'express';

export const healthRouter = Router().get('/health', (req, res) => res.json({ status: 'ok' }));