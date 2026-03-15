import { readFileSync } from 'fs';
import { resolve } from 'path';

/**
 * Apply the canonical schema to the test D1 database.
 * Call this in beforeAll — never copy DDL into tests directly.
 */
export async function applySchema(db: D1Database): Promise<void> {
  const schemaPath = resolve(__dirname, '../../db/schema.sql');
  const sql = readFileSync(schemaPath, 'utf8');

  // Split on statement boundaries and execute each
  const statements = sql
    .split(';')
    .map((s) => s.trim())
    .filter(Boolean);

  for (const statement of statements) {
    await db.exec(statement);
  }
}
