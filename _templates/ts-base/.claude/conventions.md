# {{PROJECT_NAME}} — Conventions

Detailed conventions for LLM agents working on this codebase.
These supplement CLAUDE.md with specifics that reduce ambiguity.

---

## ID Strategy

- All entity IDs are ULIDs generated via `ulidx`: `import { ulid } from 'ulidx'`
- IDs are stored as strings in TypeScript
- Never use auto-increment integers or UUIDs

## Module Structure

```
src/
├── modules/      # Feature modules — each owns its domain (CRUD + business logic)
├── utils/        # Shared pure utilities — no side effects
└── test/         # Test helpers only (fixtures, setup)
```

- **Modules** own their domain. One module per feature area (e.g., `users/`, `orders/`)
- **Utils** are stateless helpers. Search here before writing new helpers.

## Naming Conventions

- Files: `kebab-case.ts`
- Functions: `camelCase`
- Types/Interfaces: `PascalCase`
- Constants: `SCREAMING_SNAKE_CASE`
- Environment variables: `SCREAMING_SNAKE_CASE`

## TypeScript

- Strict mode is non-negotiable (`"strict": true` in tsconfig)
- Prefer `type` over `interface` for data shapes; use `interface` only for extension
- No `any` — use `unknown` and narrow, or define a proper type
- Exported functions must have explicit return types
- Use discriminated unions over optional fields where possible

## Error Handling

- Never `throw` in module functions unless it's truly unrecoverable
- Return `{ data, error }` discriminated results at module boundaries
- Log errors with enough context to reproduce: include IDs, input shape

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
