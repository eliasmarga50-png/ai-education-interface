export function loadConfig(env = process.env) {
  const need = (key) => {
    if (!env[key]) throw new Error(`${key} is required.`);
    return env[key];
  };
  const internalKey = need('INTERNAL_API_KEY');
  if (internalKey.length < 32) throw new Error('INTERNAL_API_KEY must be at least 32 characters.');

  return Object.freeze({
    port: Number(env.PORT) || 4000,
    internalApiKey: internalKey,
    gemini: Object.freeze({
      apiKey: need('GEMINI_API_KEY'),
      model: env.GEMINI_MODEL || 'gemini-3.5-flash-lite',
      timeoutMs: Number(env.GEMINI_TIMEOUT_MS) || 20000,
    }),
  });
}