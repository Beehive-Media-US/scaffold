# {{PROJECT_NAME}} — Conventions

Detailed conventions for LLM agents working on this codebase.
These supplement CLAUDE.md with specifics that reduce ambiguity.

---

## ID Strategy

- All entity IDs are ULIDs generated via `ulidx`: `import { ulid } from 'ulidx'`
- IDs are stored as `TEXT` in D1 / as strings in TypeScript
- Never use auto-increment integers or UUIDs

## Module Structure

```
src/
├── workers/      # Cloudflare Worker entry points (one per worker)
├── modules/      # Feature modules — each owns its domain (CRUD + business logic)
├── utils/        # Shared pure utilities — no side effects, no DB access
└── test/         # Test helpers only (applySchema, fixtures)
```

- **Workers** are thin: parse request, call module, return response
- **Modules** own their domain. One module per feature area (e.g., `commitments/`, `users/`)
- **Utils** are stateless helpers. Search here before writing new helpers.

## Naming Conventions

- Files: `kebab-case.ts`
- Functions: `camelCase`
- Types/Interfaces: `PascalCase`
- Constants: `SCREAMING_SNAKE_CASE`
- Database columns: `snake_case`
- Environment variables: `SCREAMING_SNAKE_CASE`

## TypeScript

- Strict mode is non-negotiable (`"strict": true` in tsconfig)
- Prefer `type` over `interface` for data shapes; use `interface` only for extension
- No `any` — use `unknown` and narrow, or define a proper type
- Exported functions must have explicit return types
- Use discriminated unions over optional fields where possible

## Error Handling

- Workers return HTTP errors via `Response` with appropriate status codes
- Never `throw` in module functions unless it's truly unrecoverable
- Return `{ data, error }` discriminated results at module boundaries
- Log errors with enough context to reproduce: include IDs, input shape

## Database (D1)

- All DDL lives in `src/db/schema.sql` — never in application code or tests
- Migrations go in `src/db/migrations/` with sequential numeric prefix
- Tests use `applySchema(env.DB)` from `@/test/db` — never copy DDL into tests
- Queries use parameterized statements — never string interpolation

## Commit Format

Conventional Commits enforced by commitlint:

```
type(scope): subject

body (optional)

Closes #N
```

Types: `feat`, `fix`, `chore`, `docs`, `style`, `refactor`, `test`, `ci`, `revert`

- Subject: imperative, lower-case, no period, max 100 chars
- Body: explain _why_, not _what_
- Always reference the source issue when one exists

## What Not To Do

- Do not add logging for "debugging" then leave it in — delete it
- Do not create helper functions for one-time use — inline it
- Do not design for hypothetical future requirements — YAGNI
- Do not add error handling for scenarios that can't happen
- Do not duplicate logic — search `src/utils/` and `src/modules/` first
