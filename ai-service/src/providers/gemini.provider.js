export class AiProviderError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

/** Gemini wants alternating turns starting with "user". Merge repeats, drop a leading model turn. */
export function toGeminiContents(history, question) {
  const turns = [];
  for (const item of [...history, { role: 'user', text: question }]) {
    const role = item.role === 'user' ? 'user' : 'model';
    const last = turns.at(-1);
    if (last && last.role === role) last.parts[0].text += `\n${item.text}`;
    else turns.push({ role, parts: [{ text: item.text }] });
  }
  while (turns.length && turns[0].role !== 'user') turns.shift();
  return turns;
}

export function createGeminiProvider({ apiKey, model, timeoutMs }, fetchImpl = fetch) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`;

  return {
    async reply({ system, history, question }) {
      let res;
      try {
        res = await fetchImpl(url, {
          method: 'POST',
          headers: { 'content-type': 'application/json', 'x-goog-api-key': apiKey },
          body: JSON.stringify({
            systemInstruction: { parts: [{ text: system }] },
            contents: toGeminiContents(history, question),
            generationConfig: { temperature: 0.6, maxOutputTokens: 1024 },
          }),
          signal: AbortSignal.timeout(timeoutMs),
        });
      } catch (err) {
        if (err?.name === 'TimeoutError' || err?.name === 'AbortError') {
          throw new AiProviderError(504, 'AI_TIMEOUT', 'The tutor took too long to answer. Please try again.');
        }
        throw new AiProviderError(502, 'AI_UNREACHABLE', 'The tutor is unreachable right now.');
      }

      if (res.status === 429) {
        throw new AiProviderError(429, 'AI_RATE_LIMITED', 'The tutor is busy (free-tier limit). Try again in a minute.');
      }
      if (!res.ok) {
        // Do not forward Google's error body: it can contain request details.
        console.error(`[gemini] HTTP ${res.status}`);
        throw new AiProviderError(502, 'AI_UPSTREAM_ERROR', 'The tutor could not answer right now.');
      }

      const data = await res.json();
      const text = (data.candidates?.[0]?.content?.parts ?? [])
        .map((p) => p.text)
        .filter(Boolean)
        .join('')
        .trim();

      if (!text) {
        const blocked = data.promptFeedback?.blockReason;
        throw new AiProviderError(
          422,
          blocked ? 'AI_BLOCKED' : 'AI_EMPTY',
          blocked ? 'I cannot help with that question.' : 'The tutor returned an empty answer. Please rephrase.',
        );
      }
      return text;
    },
  };
}