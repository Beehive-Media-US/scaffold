# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Commands

| Command             | Description                    |
| ------------------- | ------------------------------ |
| `npm run dev`       | TODO: configure dev command    |
| `npm test`          | Run vitest                     |
| `npm run typecheck` | tsc --noEmit                   |
| `npm run lint`      | ESLint (zero warnings)         |
| `npm run format`    | Prettier check                 |
| `npm run deploy`    | TODO: configure deploy command |

## Architecture

TODO: table or ASCII diagram. See `docs/ARCHITECTURE.md` for detail.

## Key Conventions

- IDs: ULID via `ulidx`
- Path alias: `@/*` → `src/*`
- TypeScript strict mode, ESNext target, Bundler module resolution
- See `.claude/conventions.md` for detailed conventions

## Environment

Copy `.dev.vars.example` to `.dev.vars` for local secrets (gitignored).

## Testing Conventions

- **No DDL in tests.** Use `applySchema(env.DB)` from `@/test/db` in `beforeAll` — it runs the actual migration file. Never copy table definitions into tests.
- **No logic duplication.** Tests call the real exported functions. Never reimplement business logic inside a test to verify it.
- **No code duplication.** Before writing a helper, check if it already exists in `src/utils/` or `src/modules/`. Extract shared logic there, not into tests.

## GitHub Workflow

- Branch naming: `feat/issue-N-short-description` or `fix/issue-N-short-description`
- PRs must reference their source issue ("Closes #N") in the body

## Absolute Rules

- **NO PARTIAL IMPLEMENTATION** — finish what you start or leave a `// TODO:` with a GitHub issue reference
- **NO LOGIC DUPLICATION** — search before writing; if it exists, use it
- **NO DEAD CODE** — delete unused code, don't comment it out
- **NO OVER-ENGINEERING** — minimum complexity for the current task; three similar lines beat a premature abstraction
- **ZERO LINT ERRORS** — typecheck + lint must pass before committing
