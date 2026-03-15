# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Commands

| Command             | Description                    |
| ------------------- | ------------------------------ |
| `npm run dev`       | Start development server       |
| `npm test`          | Run tests                      |
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

- **No DDL in tests.** Use `applySchema(env.DB)` from `@/test/db` in `beforeAll`.
- **No logic duplication.** Tests call real exported functions only.
- **No code duplication.** Check `src/utils/` and `src/modules/` before writing helpers.

## GitHub Workflow

- Branch naming: `feat/issue-N-short-description` or `fix/issue-N-short-description`
- PRs must reference their source issue ("Closes #N") in the body

## Absolute Rules

- **NO PARTIAL IMPLEMENTATION** — finish what you start or leave a `// TODO:` with a GitHub issue reference
- **NO LOGIC DUPLICATION** — search before writing; if it exists, use it
- **NO DEAD CODE** — delete unused code, don't comment it out
- **NO OVER-ENGINEERING** — minimum complexity for the current task
- **ZERO LINT ERRORS** — typecheck + lint must pass before committing
