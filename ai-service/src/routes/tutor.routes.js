import { Router } from 'express';
import { buildTutorSystemPrompt } from '../prompts/tutor.prompt.js';
import { parseTutorRequest } from '../validation/tutorRequest.js';

export function createTutorRouter(provider) {
  return Router().post('/v1/tutor/reply', async (req, res) => {
    const { question, history, lesson } = parseTutorRequest(req.body);
    const reply = await provider.reply({ system: buildTutorSystemPrompt(lesson), history, question });
    res.json({ reply });
  });
}