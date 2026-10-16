import { CATALOG } from '../src/catalog/catalog.data';
import { connect } from './db';

/**
 * Idempotent: upserts courses by slug and resources by (course, url).
 *   npm run db:seed          add and update
 *   npm run db:seed:prune    also delete resources/courses that are no longer in catalog.data.ts
 * is_published is never touched, so a course hidden by hand stays hidden.
 */
async function main(): Promise<void> {
  const prune = process.argv.includes('--prune');
  const client = await connect();
  let resourceCount = 0;

  try {
    await client.query('BEGIN');

    for (const [index, course] of CATALOG.entries()) {
      const { rows } = await client.query<{ id: string }>(
        `INSERT INTO courses
           (slug, title, description, category, level, lesson_count, rating, outcomes, position)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8::text[], $9)
         ON CONFLICT (slug) DO UPDATE SET
           title = EXCLUDED.title, description = EXCLUDED.description,
           category = EXCLUDED.category, level = EXCLUDED.level,
           lesson_count = EXCLUDED.lesson_count, rating = EXCLUDED.rating,
           outcomes = EXCLUDED.outcomes, position = EXCLUDED.position,
           updated_at = now()
         RETURNING id`,
        [
          course.slug,
          course.title,
          course.description,
          course.category,
          course.level,
          course.lessonCount,
          course.rating,
          course.outcomes,
          index,
        ],
      );
      const courseId = rows[0].id;

      for (const [position, r] of course.resources.entries()) {
        await client.query(
          `INSERT INTO course_resources
             (course_id, title, url, type, description, provider, language, difficulty, position)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
           ON CONFLICT (course_id, url) DO UPDATE SET
             title = EXCLUDED.title, type = EXCLUDED.type, description = EXCLUDED.description,
             provider = EXCLUDED.provider, language = EXCLUDED.language,
             difficulty = EXCLUDED.difficulty, position = EXCLUDED.position,
             updated_at = now()`,
          [courseId, r.title, r.url, r.type, r.description, r.provider, r.language ?? 'en', r.difficulty ?? null, position],
        );
        resourceCount++;
      }

      if (prune) {
        await client.query(
          'DELETE FROM course_resources WHERE course_id = $1 AND NOT (url = ANY($2::text[]))',
          [courseId, course.resources.map((r) => r.url)],
        );
      }
    }

    if (prune) {
      await client.query('DELETE FROM courses WHERE NOT (slug = ANY($1::text[]))', [
        CATALOG.map((c) => c.slug),
      ]);
    }

    await client.query('COMMIT');
    console.log(`Seeded ${CATALOG.length} courses and ${resourceCount} resources${prune ? ' (pruned)' : ''}.`);
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    await client.end();
  }
}

main().catch((err) => {
  console.error('Seeding failed:', err instanceof Error ? err.message : err);
  process.exit(1);
});