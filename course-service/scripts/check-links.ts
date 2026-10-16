import { CATALOG } from '../src/catalog/catalog.data';

type Outcome = 'ok' | 'warn' | 'fail';
interface Result {
  outcome: Outcome;
  detail: string;
}

const HEADERS = {
  'user-agent': 'ai-education-link-checker/1.0',
  accept: 'text/html,application/xhtml+xml,*/*',
};

async function check(url: string): Promise<Result> {
  for (const method of ['HEAD', 'GET'] as const) {
    try {
      const res = await fetch(url, {
        method,
        headers: HEADERS,
        redirect: 'follow',
        signal: AbortSignal.timeout(15_000),
      });
      if (res.ok) return { outcome: 'ok', detail: String(res.status) };
      if (res.status === 404 || res.status === 410) return { outcome: 'fail', detail: String(res.status) };
      if (method === 'GET') {
        // Some sites block scripts with 403/429 although the page works in a browser.
        const bot = res.status === 403 || res.status === 429;
        return { outcome: bot ? 'warn' : 'fail', detail: String(res.status) };
      }
    } catch (err) {
      if (method === 'GET') return { outcome: 'fail', detail: err instanceof Error ? err.message : String(err) };
    }
  }
  return { outcome: 'fail', detail: 'unreachable' };
}

async function main(): Promise<void> {
  const urls = CATALOG.flatMap((c) => c.resources.map((r) => ({ course: c.title, title: r.title, url: r.url })));
  let failures = 0;

  for (let i = 0; i < urls.length; i += 5) {
    const batch = urls.slice(i, i + 5);
    const results = await Promise.all(batch.map((u) => check(u.url)));
    batch.forEach((u, j) => {
      const { outcome, detail } = results[j];
      if (outcome === 'fail') failures++;
      console.log(`${outcome.toUpperCase().padEnd(4)} ${detail.padEnd(6)} ${u.course} / ${u.title}\n           ${u.url}`);
    });
  }

  console.log(`\n${urls.length} links checked, ${failures} failed.`);
  process.exit(failures > 0 ? 1 : 0);
}

main();