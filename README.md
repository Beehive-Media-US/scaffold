# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

> Initialized from [Beehive-Media-US/scaffold](https://github.com/Beehive-Media-US/scaffold).

## Getting Started

```bash
# Install dependencies (also registers git hooks)
npm install

# Copy local secrets
cp .dev.vars.example .dev.vars
# Edit .dev.vars with your values

# Start development
npm run dev
```

## Commands

| Command              | Description                    |
| -------------------- | ------------------------------ |
| `npm run dev`        | Start local development server |
| `npm test`           | Run test suite                 |
| `npm run typecheck`  | TypeScript type checking       |
| `npm run lint`       | ESLint (zero warnings)         |
| `npm run lint:fix`   | ESLint with auto-fix           |
| `npm run format`     | Prettier check                 |
| `npm run format:fix` | Prettier auto-format           |
| `npm run cpd`        | Duplicate code detection       |

## Architecture

See [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md).

## Contributing

1. Branch from `main`: `git checkout -b feat/issue-N-short-description`
2. Make changes, commit often — git hooks run typecheck + lint on each commit
3. Push — git hooks run tests + format check
4. Open a PR, reference the source issue ("Closes #N")

## Initialization

This project was initialized using `scripts/init.sh` from the scaffold template.
Configuration choices are recorded in `template.config.json`.
