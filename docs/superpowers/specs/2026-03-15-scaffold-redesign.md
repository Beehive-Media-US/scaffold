# Scaffold Redesign: Layered Templates + Colony + New Variants

**Date:** 2026-03-15
**Status:** Approved

## Overview

Restructure the scaffold template repo to support 7 project variants (up from 4), introduce Colony as an orthogonal opt-in feature axis, and make `init.sh` composable via layered template application.

## Goals

- Any project type can optionally be Colony-managed (colony is not required)
- New variants: full-stack (CF Workers + React), ios-native, expo
- Eliminate template file duplication via layered composition
- `init.sh` remains a single interactive script; no new tooling dependencies

## Non-Goals

- Colony is not a dependency — scaffold does not install or run colony
- No breaking changes to existing initialized projects
- No new runtime languages or package managers (beyond what iOS/Expo require)

---

## Architecture

### Template Layer Structure

`_templates/` is reorganized into three explicit layers applied in sequence:

```
_templates/
  base/           ← universal to ALL variants
  ts-base/        ← TypeScript tooling shared by all non-iOS variants
  variants/
    cf-single/
    cf-multi/
    node-service/
    react-app/
    full-stack/
    ios-native/
    expo/
  features/
    colony/
```

**Application order:** `base` → `ts-base` (if not iOS) → `variants/<name>` → `features[]`

Later layers overwrite earlier layers for identical file paths. `package.json` is the one exception: it is deep-merged (scripts + dependencies accumulated across layers) rather than overwritten.

### `base/` Contents

Universal across all project types:

- `.github/ISSUE_TEMPLATE/` (bug report, feature request)
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/workflows/ci.yml` (stub with `{{CI_STEPS}}` placeholder)
- `.github/workflows/deploy.yml` (stub)
- `.githooks/pre-commit`, `pre-push`, `commit-msg` (use `{{TEST_CMD}}`, `{{LINT_CMD}}` placeholders)
- `CLAUDE.md` (with `{{PROJECT_NAME}}`, `{{PROJECT_DESCRIPTION}}`, `{{VARIANT}}` placeholders)
- `.prettierrc`
- `commitlint.config.js`
- `docs/ARCHITECTURE.md` (template)
- `.dev.vars.example`

### `ts-base/` Contents

Applied to all variants except `ios-native`:

- `tsconfig.json` (strict, ESNext, Bundler resolution, `@/*` alias)
- `eslint.config.js`
- `vitest.config.ts`
- `jscpd.json`
- `.claude/conventions.md`
- `package.json` (core scripts: typecheck, lint, format, test, cpd; core devDeps: typescript, eslint, prettier, vitest, commitlint, lint-staged, ulidx)

### Variants

| Variant        | Key additions over base + ts-base                                                                                                               |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `cf-single`    | `wrangler.toml`, `src/workers/index.ts`, `src/test/db.ts`, CF deps (wrangler, @cloudflare/\*)                                                   |
| `cf-multi`     | dual `wrangler.toml` files, `src/workers/{gateway,agent-core}.ts`, `src/db/schema.sql`, migrations, CF deps                                     |
| `node-service` | `src/index.ts`, `src/agent.ts`, `src/types.ts`, tsconfig patched to Node16 + `outDir: dist`, removes CF deps                                    |
| `react-app`    | `index.html`, `src/main.tsx`, `src/App.tsx`, `vite.config.ts`, tsconfig JSX patch, React 18 + Vite deps                                         |
| `full-stack`   | `wrangler.toml` (Assets binding), `src/workers/api.ts`, `src/frontend/{main.tsx,App.tsx}`, `vite.config.ts` (dual build), CF + React deps       |
| `expo`         | calls `npx create-expo-app` as subprocess, then layers Expo tsconfig, `eas.json`, RN test setup                                                 |
| `ios-native`   | calls `xcodegen`/`swift package init` as subprocess, then layers iOS CI workflow, SwiftLint config, iOS git hooks override, iOS CLAUDE.md block |

#### Full-Stack Variant Detail

Structure: one CF Worker serves both `/api/*` routes and bundled React static files via CF Workers Assets binding. Single `wrangler deploy`. Vite builds frontend to `dist/assets/`; esbuild bundles worker to `dist/worker.js`.

```
src/
  workers/api.ts        ← handles /api/* routes
  frontend/
    main.tsx
    App.tsx
    components/
wrangler.toml           ← [assets] binding → dist/assets/
vite.config.ts          ← builds frontend; worker bundled separately via package.json script
```

#### iOS Native Variant Detail

Thin scaffold wrapper. `init.sh` calls the upstream generator before applying the variant layer. If the generator binary is missing, `init.sh` prints installation instructions and exits cleanly.

CI workflow uses a `macos-latest` GitHub Actions runner with `xcodebuild test` and SwiftLint. Git hooks override calls `xcodebuild test` instead of `npm test`.

#### Expo Variant Detail

Thin scaffold wrapper. `init.sh` calls `npx create-expo-app@latest . --template blank-typescript`, then applies the variant layer (Expo-compatible tsconfig, `eas.json`, React Native Testing Library setup).

---

## Colony Feature Layer

`_templates/features/colony/` contains three additions:

### 1. `.colony/conventions.md`

Parameterized by `{{VARIANT}}`. Teaches Colony agents how to work in this repo:

- **TS variants:** tech stack, module structure, test patterns, migration conventions, ULID IDs, `{data, error}` result pattern
- **ios-native:** Swift conventions, XCTest patterns, target structure, `xcodebuild` commands
- **expo:** React Native conventions, EAS build, Jest + RNTL test patterns

### 2. `colony.config.yaml.example`

Pre-configured review commands per variant:

| Variant              | `workspace.setup_command`                | `review.checks`                                   |
| -------------------- | ---------------------------------------- | ------------------------------------------------- |
| cf-single / cf-multi | `npm install`                            | typecheck, lint, test                             |
| node-service         | `npm install`                            | typecheck, lint, test                             |
| react-app            | `npm install`                            | typecheck, lint, test, build                      |
| full-stack           | `npm install`                            | typecheck, lint, test, build                      |
| expo                 | `npm install && npx expo install`        | typecheck, lint, test                             |
| ios-native           | `xcodebuild -resolvePackageDependencies` | `xcodebuild test -scheme {{SCHEME}}`, `swiftlint` |

Written as `colony.config.yaml` if user chooses to configure now; as `.example` otherwise.

### 3. CLAUDE.md Colony Block

Short appended section explaining colony manages this repo, where `.colony/conventions.md` lives, and how to run colony locally.

---

## `init.sh` Rewrite

### Phase 1 — Gather Config

```
Project name:     [text]
Description:      [text]
Variant:          cf-single | cf-multi | node-service | react-app |
                  full-stack | ios-native | expo
Features:         [ ] colony   (multi-select; more in future)
```

Variant-specific additional prompts:

- `ios-native`: Xcode scheme name (used in CI + colony config)
- `expo`: App slug (used in `app.json`)

Colony additional prompts (if selected):

- "Is this repo already on GitHub?" → capture `owner/repo`
- "Configure colony now or later?" → writes `colony.config.yaml` or `.example`

### Phase 2 — Resolve Layers

```bash
LAYERS=("_templates/base")
if [[ "$VARIANT" != "ios-native" ]]; then
  LAYERS+=("_templates/ts-base")
fi
LAYERS+=("_templates/variants/$VARIANT")
for feature in "${FEATURES[@]}"; do
  LAYERS+=("_templates/features/$feature")
done
```

### Phase 3 — Generator Wrapper (iOS and Expo only)

Run upstream generator **before** layer application so scaffold files land on top of generator output:

- iOS: `xcodegen generate` or `swift package init --type executable`
- Expo: `npx create-expo-app@latest . --template blank-typescript`

Missing generator → print installation instructions + clean exit (no partial scaffold produced).

### Phase 4 — Apply Layers

For each layer in order, for each file:

- `package.json` → deep JSON merge (accumulate scripts + deps across all layers; if the same key appears in multiple layers, the later layer's value wins)
- All other files → copy, overwriting any previously applied version of that file

The Expo variant's `tsconfig.json` is a **full replacement file** (not a patch) — it overwrites `ts-base/tsconfig.json` via the normal overwrite rule.

Then substitute all `{{PLACEHOLDERS}}` across all copied files (including `.example` files) using the canonical placeholder list:

| Placeholder               | Source                                                                         |
| ------------------------- | ------------------------------------------------------------------------------ |
| `{{PROJECT_NAME}}`        | Phase 1 input                                                                  |
| `{{PROJECT_DESCRIPTION}}` | Phase 1 input                                                                  |
| `{{VARIANT}}`             | Phase 1 selection                                                              |
| `{{CI_STEPS}}`            | Resolved from variant (e.g., `npm run typecheck`, `npm run lint`, `npm test`)  |
| `{{TEST_CMD}}`            | Resolved from variant (e.g., `npm test`, `xcodebuild test -scheme {{SCHEME}}`) |
| `{{LINT_CMD}}`            | Resolved from variant (e.g., `npm run lint`, `swiftlint`)                      |
| `{{SCHEME}}`              | Phase 1 input (iOS only) — substituted in CI workflow AND colony config        |
| `{{APP_SLUG}}`            | Phase 1 input (Expo only)                                                      |
| `{{GITHUB_OWNER_REPO}}`   | Phase 1 input (colony only, if configured now)                                 |

### Phase 5 — Configure Git Hooks

Set `core.hooksPath = .githooks` via `git config`. For `ios-native`, git hook configuration still runs (the hooks call `xcodebuild` instead of `npm test`); Xcode CLI presence is verified in Phase 3 before the generator runs.

### Phase 6 — Install Dependencies

Run `npm install`. Skipped for `ios-native`.

### Phase 7 — Initial Commit

Stage all files, commit with message `chore: init project from scaffold template`. Write `template.config.json` to the repo root at this point.

### Phase 8 — Optional GitHub Repo Creation + Self-Cleanup

Optionally create GitHub repo via `gh repo create`. Then self-cleanup: remove `_templates/`, `scripts/init.sh`. `template.config.json` remains for future `scripts/add-feature.sh` use.

### `template.config.json` Schema

Gains a `features` array, enabling a future `scripts/add-feature.sh`:

```json
{
  "variant": "node-service",
  "features": ["colony"],
  "projectName": "my-project",
  "initializedAt": "2026-03-15"
}
```

---

## Future Extensibility

The `features/` layer is designed to absorb future optional add-ons without touching existing variant code:

- `features/auth/` — OAuth/JWT setup
- `features/db/` — D1 schema + migration tooling
- `scripts/add-feature.sh` — applies a feature layer post-init using `template.config.json`

---

## Out of Scope

- Automated tests for `init.sh` itself (manual verification sufficient for a one-time script)
- Support for non-GitHub remotes
- Deno/Bun variants
- npm library / CLI tool variants (can be added later as new variant folders)
