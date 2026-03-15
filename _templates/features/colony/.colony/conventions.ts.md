# {{PROJECT_NAME}} — Colony Conventions

This file teaches Colony agents how to work effectively in this codebase.

## Tech Stack

- Language: TypeScript (variant: `{{VARIANT}}`)
- Runtime: Node {{NODE_VERSION}}
- Package manager: npm
- Testing: Vitest (`npm test`)
- Linting: ESLint zero warnings + Prettier

## Project Structure

```
src/
  workers/   ← entry points (thin: parse request, call module, return response)
  modules/   ← domain logic (one directory per feature area)
  utils/     ← pure stateless helpers (no side effects, no DB access)
  test/      ← test helpers only (applySchema, fixtures)
```

## Setup

```bash
npm install
```

## Running Checks

```bash
npm test            # run all tests
npm run typecheck   # TypeScript strict check
npm run lint        # ESLint (zero warnings)
npm run format      # Prettier check
```

## ID Strategy

All entity IDs are ULIDs: `import { ulid } from 'ulidx'`. Never auto-increment integers or UUIDs.

## Module Boundaries

Functions at module boundaries return `{ data, error }` discriminated results. Never throw across module boundaries.

## Database (when applicable)

- DDL lives in `src/db/schema.sql` only — never in tests or application code
- Migrations in `src/db/migrations/` with sequential numeric prefix
- Tests use `applySchema(env.DB)` from `@/test/db`
- Parameterized queries only — no string interpolation

## Commit Format

Conventional Commits with issue reference:

```
type(scope): subject

Closes #N
```

Types: feat, fix, chore, docs, style, refactor, test, ci, revert

## What Colony Must NOT Do

- Modify `src/db/schema.sql` without a matching migration file
- Leave `console.log` in production code
- Add dependencies without explaining the reason in the commit body
- Use `any` in TypeScript — use `unknown` and narrow
