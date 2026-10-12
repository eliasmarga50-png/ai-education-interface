import express from 'express';
import { loadConfig } from './config/env.js';
import { internalAuth } from './middleware/internalAuth.js';
import { createGeminiProvider, AiProviderError } from './providers/gemini.provider.js';
import { healthRouter } from './routes/health.routes.js';
import { createTutorRouter } from './routes/tutor.routes.js';

let config;
try {
  config = loadConfig();
} catch (err) {
  console.error(`\nConfiguration error: ${err.message}\n`);
  process.exit(1);
}

const app = express();
app.disable('x-powered-by');
app.use(express.json({ limit: '64kb' }));

app.use(healthRouter);
app.use(internalAuth(config.internalApiKey), createTutorRouter(createGeminiProvider(config.gemini)));

app.use((req, res) => res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Route not found.' } }));
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  if (err instanceof AiProviderError) {
    return res.status(err.status).json({ error: { code: err.code, message: err.message } });
  }
  if (err?.type === 'entity.parse.failed') {
    return res.status(400).json({ error: { code: 'INVALID_JSON', message: 'Body is not valid JSON.' } });
  }
  console.error('[unhandled]', err);
  res.status(500).json({ error: { code: 'SERVER_ERROR', message: 'Unexpected error.' } });
});

// Bound to localhost: only the backend on the same machine should reach it.
const server = app.listen(config.port, '127.0.0.1');
server.once('listening', () =>
  console.log(`AI service on http://127.0.0.1:${config.port} (model: ${config.gemini.model})`),
);
server.once('error', (err) => {
  console.error(
    err.code === 'EADDRINUSE'
      ? `\nPort ${config.port} is already in use by another program.\n`
      : `\nAI service failed to start: ${err.message}\n`,
  );
  process.exit(1);
});