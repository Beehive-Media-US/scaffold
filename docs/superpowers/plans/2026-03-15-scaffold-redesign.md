# Scaffold Redesign Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure the scaffold template repo to support 7 project variants, introduce Colony as an orthogonal opt-in feature layer, and rewrite `init.sh` to apply composable template layers.

**Architecture:** `_templates/` is reorganized into `base/`, `ts-base/`, `variants/`, and `features/` layers applied in sequence by a rewritten `init.sh`. New variants (full-stack, ios-native, expo) are added as new variant directories. Colony is added as `_templates/features/colony/`, containing `.colony/conventions.md`, `colony.config.yaml.example`, and a `CLAUDE.md` block appended at init time.

**Tech Stack:** Bash (init.sh), TypeScript/TSX (variant source templates), YAML (CI/colony configs), JSON (package.json fragments), TOML (wrangler configs)

---

## Chunk 1: Template layer scaffolding

### Task 1: Create `_templates/base/`

**Files:**

- Create: `_templates/base/.github/ISSUE_TEMPLATE/bug_report.md`
- Create: `_templates/base/.github/ISSUE_TEMPLATE/feature_request.md`
- Create: `_templates/base/.github/PULL_REQUEST_TEMPLATE.md`
- Create: `_templates/base/.github/workflows/deploy.yml`
- Create: `_templates/base/.githooks/pre-commit`
- Create: `_templates/base/.githooks/pre-push`
- Create: `_templates/base/.githooks/commit-msg`
- Create: `_templates/base/CLAUDE.md`
- Create: `_templates/base/.prettierrc`
- Create: `_templates/base/commitlint.config.js`
- Create: `_templates/base/docs/ARCHITECTURE.md`
- Create: `_templates/base/.dev.vars.example`

- [ ] **Step 1: Create base directory structure**

```bash
mkdir -p _templates/base/.github/ISSUE_TEMPLATE
mkdir -p _templates/base/.github/workflows
mkdir -p _templates/base/.githooks
mkdir -p _templates/base/docs
```

- [ ] **Step 2: Copy unchanged files from root**

These files are identical to what's already in the repo root — copy them verbatim:

```bash
cp .github/ISSUE_TEMPLATE/bug_report.md _templates/base/.github/ISSUE_TEMPLATE/
cp .github/ISSUE_TEMPLATE/feature_request.md _templates/base/.github/ISSUE_TEMPLATE/
cp .github/PULL_REQUEST_TEMPLATE.md _templates/base/.github/
cp .prettierrc _templates/base/
cp commitlint.config.js _templates/base/
cp docs/ARCHITECTURE.md _templates/base/docs/
```

- [ ] **Step 3: Create `_templates/base/CLAUDE.md`**

```markdown
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
```

- [ ] **Step 4: Create `_templates/base/.githooks/pre-commit`**

```bash
#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"
npm run typecheck
npx lint-staged
```

- [ ] **Step 5: Create `_templates/base/.githooks/pre-push`**

```bash
#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"
npm run format
npm test
npm run cpd
```

- [ ] **Step 6: Create `_templates/base/.githooks/commit-msg`**

```bash
#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"
npx --no -- commitlint --edit "$1"
```

- [ ] **Step 7: Create `_templates/base/.github/workflows/deploy.yml`**

Same content as the current root `.github/workflows/deploy.yml` — copy verbatim:

```bash
cp .github/workflows/deploy.yml _templates/base/.github/workflows/
```

- [ ] **Step 8: Create `_templates/base/.dev.vars.example`**

```bash
cp .dev.vars.example _templates/base/ 2>/dev/null || cat > _templates/base/.dev.vars.example << 'EOF'
# Local development secrets — copy to .dev.vars (gitignored)
ANTHROPIC_API_KEY=
SLACK_BOT_TOKEN=
SLACK_SIGNING_SECRET=
EOF
```

- [ ] **Step 9: Verify structure**

```bash
find _templates/base -type f | sort
```

Expected output:

```
_templates/base/.dev.vars.example
_templates/base/.github/ISSUE_TEMPLATE/bug_report.md
_templates/base/.github/ISSUE_TEMPLATE/feature_request.md
_templates/base/.github/PULL_REQUEST_TEMPLATE.md
_templates/base/.github/workflows/deploy.yml
_templates/base/.githooks/commit-msg
_templates/base/.githooks/pre-commit
_templates/base/.githooks/pre-push
_templates/base/CLAUDE.md
_templates/base/commitlint.config.js
_templates/base/docs/ARCHITECTURE.md
_templates/base/.prettierrc
```

- [ ] **Step 10: Commit**

```bash
git add _templates/base/
git commit -m "feat: add _templates/base/ universal layer"
```

---

### Task 2: Create `_templates/ts-base/`

**Files:**

- Create: `_templates/ts-base/tsconfig.json`
- Create: `_templates/ts-base/eslint.config.js`
- Create: `_templates/ts-base/vitest.config.ts`
- Create: `_templates/ts-base/jscpd.json`
- Create: `_templates/ts-base/.claude/conventions.md`
- Create: `_templates/ts-base/package.json`
- Create: `_templates/ts-base/.github/workflows/ci.yml`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p _templates/ts-base/.claude
mkdir -p _templates/ts-base/.github/workflows
```

- [ ] **Step 2: Copy unchanged config files**

```bash
cp tsconfig.json _templates/ts-base/
cp eslint.config.js _templates/ts-base/
cp vitest.config.ts _templates/ts-base/
cp jscpd.json _templates/ts-base/
cp .claude/conventions.md _templates/ts-base/.claude/
```

- [ ] **Step 3: Copy CI workflow**

```bash
cp .github/workflows/ci.yml _templates/ts-base/.github/workflows/
```

- [ ] **Step 4: Create `_templates/ts-base/package.json`**

Core TypeScript tooling — no Cloudflare-specific deps. Each variant will deep-merge its own additions on top.

```json
{
  "name": "{{PROJECT_NAME}}",
  "version": "0.1.0",
  "description": "{{PROJECT_DESCRIPTION}}",
  "type": "module",
  "scripts": {
    "dev": "echo '# TODO: configure dev command'",
    "test": "vitest --run",
    "typecheck": "tsc --noEmit",
    "lint": "eslint src --max-warnings=0",
    "lint:fix": "eslint src --fix",
    "format": "prettier --check src",
    "format:fix": "prettier --write src",
    "cpd": "jscpd src",
    "prepare": "git config core.hooksPath .githooks"
  },
  "lint-staged": {
    "src/**/*.{ts,tsx}": ["eslint --fix", "prettier --write"],
    "{vitest,eslint,commitlint}.config.{ts,js}": ["eslint --fix", "prettier --write"],
    "**/*.{json,md}": ["prettier --write"]
  },
  "devDependencies": {
    "@commitlint/cli": "^19.6.1",
    "@commitlint/config-conventional": "^19.6.0",
    "@commitlint/types": "^19.5.0",
    "@eslint/js": "^9.18.0",
    "@typescript-eslint/eslint-plugin": "^8.22.0",
    "@typescript-eslint/parser": "^8.22.0",
    "eslint": "^9.18.0",
    "jscpd": "^4.0.5",
    "lint-staged": "^15.4.3",
    "prettier": "^3.4.2",
    "typescript": "^5.7.3",
    "ulidx": "^2.3.0",
    "vitest": "^3.0.5"
  }
}
```

- [ ] **Step 5: Verify**

```bash
find _templates/ts-base -type f | sort
node -e "JSON.parse(require('fs').readFileSync('_templates/ts-base/package.json','utf8'))" && echo "valid JSON"
```

Expected: 7 files, "valid JSON"

- [ ] **Step 6: Commit**

```bash
git add _templates/ts-base/
git commit -m "feat: add _templates/ts-base/ TypeScript tooling layer"
```

---

### Task 3: Restructure existing variants into `_templates/variants/`

**Files:**

- Move: `_templates/cf-single/` → `_templates/variants/cf-single/`
- Move: `_templates/cf-multi/` → `_templates/variants/cf-multi/`
- Move: `_templates/node-service/` → `_templates/variants/node-service/`
- Move: `_templates/react-app/` → `_templates/variants/react-app/`
- Create: `_templates/variants/cf-single/package.json`
- Create: `_templates/variants/cf-multi/package.json`
- Create: `_templates/variants/node-service/package.json`
- Create: `_templates/variants/node-service/tsconfig.json`
- Create: `_templates/variants/react-app/package.json`

- [ ] **Step 1: Move existing variant directories**

```bash
mkdir -p _templates/variants
git mv _templates/cf-single _templates/variants/cf-single
git mv _templates/cf-multi _templates/variants/cf-multi
git mv _templates/node-service _templates/variants/node-service
git mv _templates/react-app _templates/variants/react-app
```

- [ ] **Step 2: Create `_templates/variants/cf-single/package.json`**

Adds CF-specific deps on top of ts-base (deep-merged by init.sh):

```json
{
  "devDependencies": {
    "@cloudflare/vitest-pool-workers": "^0.8.0",
    "@cloudflare/workers-types": "^4.20250224.0",
    "wrangler": "^4.4.0"
  }
}
```

- [ ] **Step 3: Create `_templates/variants/cf-multi/package.json`**

Same CF deps as cf-single:

```json
{
  "devDependencies": {
    "@cloudflare/vitest-pool-workers": "^0.8.0",
    "@cloudflare/workers-types": "^4.20250224.0",
    "wrangler": "^4.4.0"
  }
}
```

- [ ] **Step 4: Create `_templates/variants/node-service/tsconfig.json`**

Overrides ts-base's tsconfig — Node16 module resolution with outDir:

```json
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "Node16",
    "moduleResolution": "Node16",
    "outDir": "dist",
    "rootDir": "src",
    "strict": true,
    "skipLibCheck": true,
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

- [ ] **Step 5: Create `_templates/variants/node-service/package.json`**

Adds Node types, overrides build script:

```json
{
  "scripts": {
    "build": "tsc",
    "dev": "node --import tsx/esm src/index.ts"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "tsx": "^4.7.0"
  }
}
```

- [ ] **Step 6: Create `_templates/variants/react-app/package.json`**

Adds React + Vite, overrides scripts (react-app already has its own tsconfig.json):

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@types/react": "^18.3.18",
    "@types/react-dom": "^18.3.5",
    "@vitejs/plugin-react": "^4.3.4",
    "vite": "^6.0.11"
  }
}
```

- [ ] **Step 7: Verify JSON validity**

```bash
for f in _templates/variants/*/package.json; do
  node -e "JSON.parse(require('fs').readFileSync('$f','utf8'))" && echo "OK: $f"
done
```

Expected: `OK:` for each file, no errors.

- [ ] **Step 8: Commit**

```bash
git add _templates/variants/
git commit -m "feat: restructure existing variants into _templates/variants/"
```

---

## Chunk 2: New variant templates

### Task 4: Create `_templates/variants/full-stack/`

**Files:**

- Create: `_templates/variants/full-stack/wrangler.toml`
- Create: `_templates/variants/full-stack/index.html`
- Create: `_templates/variants/full-stack/vite.config.ts`
- Create: `_templates/variants/full-stack/tsconfig.json`
- Create: `_templates/variants/full-stack/package.json`
- Create: `_templates/variants/full-stack/src/workers/api.ts`
- Create: `_templates/variants/full-stack/src/frontend/main.tsx`
- Create: `_templates/variants/full-stack/src/frontend/App.tsx`
- Create: `_templates/variants/full-stack/src/frontend/components/.gitkeep`

- [ ] **Step 1: Create directories**

```bash
mkdir -p _templates/variants/full-stack/src/workers
mkdir -p _templates/variants/full-stack/src/frontend/components
```

- [ ] **Step 2: Create `_templates/variants/full-stack/wrangler.toml`**

```toml
name = "{{WORKER_NAME}}"
main = "src/workers/api.ts"
compatibility_date = "2025-01-01"
compatibility_flags = ["nodejs_compat"]

[assets]
directory = "./dist/assets"
```

- [ ] **Step 3: Create `_templates/variants/full-stack/index.html`**

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>{{PROJECT_NAME}}</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/frontend/main.tsx"></script>
  </body>
</html>
```

- [ ] **Step 4: Create `_templates/variants/full-stack/vite.config.ts`**

```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';

export default defineConfig({
  plugins: [react()],
  build: {
    outDir: 'dist/assets',
    emptyOutDir: true,
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
    },
  },
});
```

- [ ] **Step 5: Create `_templates/variants/full-stack/tsconfig.json`**

Full replacement — supports JSX for frontend while keeping Bundler resolution:

```json
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "lib": ["ESNext", "DOM", "DOM.Iterable"],
    "jsx": "react-jsx",
    "strict": true,
    "noEmit": true,
    "skipLibCheck": true,
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

- [ ] **Step 6: Create `_templates/variants/full-stack/package.json`**

Deep-merged on top of ts-base — adds CF + React deps, overrides scripts:

```json
{
  "scripts": {
    "dev": "wrangler dev",
    "build": "npm run build:frontend && npm run build:worker",
    "build:frontend": "vite build",
    "build:worker": "wrangler deploy --dry-run --outdir dist"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@cloudflare/vitest-pool-workers": "^0.8.0",
    "@cloudflare/workers-types": "^4.20250224.0",
    "@types/react": "^18.3.18",
    "@types/react-dom": "^18.3.5",
    "@vitejs/plugin-react": "^4.3.4",
    "vite": "^6.0.11",
    "wrangler": "^4.4.0"
  }
}
```

- [ ] **Step 7: Create `_templates/variants/full-stack/src/workers/api.ts`**

```typescript
export interface Env {
  // Add bindings here
}

export default {
  async fetch(request: Request, _env: Env, _ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname === '/api/health') {
      return Response.json({ status: 'ok' });
    }

    // All non-API routes are handled by the Assets binding (React frontend)
    return new Response('Not Found', { status: 404 });
  },
} satisfies ExportedHandler<Env>;
```

- [ ] **Step 8: Create `_templates/variants/full-stack/src/frontend/main.tsx`**

```typescript
import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App.js';

const root = document.getElementById('root');
if (!root) throw new Error('Root element not found');

createRoot(root).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
```

- [ ] **Step 9: Create `_templates/variants/full-stack/src/frontend/App.tsx`**

```typescript
export default function App() {
  return (
    <main>
      <h1>{{PROJECT_NAME}}</h1>
      <p>{{PROJECT_DESCRIPTION}}</p>
    </main>
  );
}
```

- [ ] **Step 10: Create `.gitkeep`**

```bash
touch _templates/variants/full-stack/src/frontend/components/.gitkeep
```

- [ ] **Step 11: Verify**

```bash
find _templates/variants/full-stack -type f | sort
node -e "JSON.parse(require('fs').readFileSync('_templates/variants/full-stack/package.json','utf8'))" && echo "valid JSON"
```

- [ ] **Step 12: Commit**

```bash
git add _templates/variants/full-stack/
git commit -m "feat: add full-stack variant template (CF Workers Assets + React)"
```

---

### Task 5: Create `_templates/variants/ios-native/`

Thin scaffold wrapper — no source files (generator provides those). Overrides base's git hooks and CI workflow with iOS-specific versions, adds SwiftLint config and iOS CLAUDE.md.

**Files:**

- Create: `_templates/variants/ios-native/.github/workflows/ci.yml`
- Create: `_templates/variants/ios-native/.githooks/pre-commit`
- Create: `_templates/variants/ios-native/.githooks/pre-push`
- Create: `_templates/variants/ios-native/.swiftlint.yml`
- Create: `_templates/variants/ios-native/CLAUDE.md`

- [ ] **Step 1: Create directories**

```bash
mkdir -p _templates/variants/ios-native/.github/workflows
mkdir -p _templates/variants/ios-native/.githooks
```

- [ ] **Step 2: Create `_templates/variants/ios-native/.github/workflows/ci.yml`**

```yaml
name: CI

on:
  pull_request:
    branches: [main]

jobs:
  lint:
    name: SwiftLint
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install SwiftLint
        run: brew install swiftlint
      - name: Lint
        run: swiftlint lint --strict

  test:
    name: Test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build and Test
        run: |
          xcodebuild test \
            -scheme {{SCHEME}} \
            -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
            -resultBundlePath TestResults.xcresult \
            | xcpretty || exit 1
```

- [ ] **Step 3: Create `_templates/variants/ios-native/.githooks/pre-commit`**

```bash
#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"
swiftlint lint --strict
```

- [ ] **Step 4: Create `_templates/variants/ios-native/.githooks/pre-push`**

```bash
#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"
xcodebuild test \
  -scheme {{SCHEME}} \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  | xcpretty || exit 1
```

- [ ] **Step 5: Create `_templates/variants/ios-native/.swiftlint.yml`**

```yaml
disabled_rules:
  - trailing_whitespace

opt_in_rules:
  - empty_count
  - closure_spacing

excluded:
  - Pods
  - .build
  - DerivedData
```

- [ ] **Step 6: Create `_templates/variants/ios-native/CLAUDE.md`**

This replaces base's CLAUDE.md — iOS projects don't use npm commands:

```markdown
# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Commands

| Command                                  | Description          |
| ---------------------------------------- | -------------------- |
| `xcodebuild build -scheme {{SCHEME}}`    | Build the project    |
| `xcodebuild test -scheme {{SCHEME}}`     | Run tests            |
| `swiftlint lint --strict`                | Lint Swift code      |
| `xcodebuild -resolvePackageDependencies` | Resolve SPM packages |

## Architecture

TODO: table or ASCII diagram. See `docs/ARCHITECTURE.md` for detail.

## Key Conventions

- Language: Swift 5.x, SwiftUI
- Target: iOS 17+, Xcode scheme: `{{SCHEME}}`
- Dependency manager: Swift Package Manager only (no CocoaPods)
- No force unwrapping — use guard/if-let with explanation if unavoidable

## Testing Conventions

- XCTest for unit tests; ViewInspector or snapshot tests for UI
- Test files mirror source structure in a `Tests/` target
- Test behaviors, not implementations — never rewrite source logic in a test

## GitHub Workflow

- Branch naming: `feat/issue-N-short-description` or `fix/issue-N-short-description`
- PRs must reference their source issue ("Closes #N") in the body

## Absolute Rules

- **NO PARTIAL IMPLEMENTATION** — finish what you start or leave a `// TODO:` with a GitHub issue reference
- **NO LOGIC DUPLICATION** — search before writing; if it exists, use it
- **NO DEAD CODE** — delete unused code, don't comment it out
- **ZERO LINT ERRORS** — swiftlint must pass before committing
```

- [ ] **Step 7: Verify**

```bash
find _templates/variants/ios-native -type f | sort
```

Expected: 5 files (ci.yml, pre-commit, pre-push, .swiftlint.yml, CLAUDE.md)

- [ ] **Step 8: Commit**

```bash
git add _templates/variants/ios-native/
git commit -m "feat: add ios-native variant template (thin scaffold wrapper)"
```

---

### Task 6: Create `_templates/variants/expo/`

Thin scaffold wrapper — `create-expo-app` provides source files. Provides tsconfig override, expo-specific package.json, EAS config, app.json.

**Files:**

- Create: `_templates/variants/expo/tsconfig.json`
- Create: `_templates/variants/expo/package.json`
- Create: `_templates/variants/expo/eas.json`
- Create: `_templates/variants/expo/app.json`
- Create: `_templates/variants/expo/src/components/.gitkeep`
- Create: `_templates/variants/expo/src/__tests__/.gitkeep`

- [ ] **Step 1: Create directories**

```bash
mkdir -p _templates/variants/expo/src/components
mkdir -p _templates/variants/expo/src/__tests__
```

- [ ] **Step 2: Create `_templates/variants/expo/tsconfig.json`**

Full replacement of ts-base's tsconfig — uses Expo's base:

```json
{
  "extends": "expo/tsconfig.base",
  "compilerOptions": {
    "strict": true,
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["**/*.ts", "**/*.tsx", ".expo/types/**/*.ts", "expo-env.d.ts"]
}
```

- [ ] **Step 3: Create `_templates/variants/expo/package.json`**

Deep-merged on top of ts-base. Note: `"vitest": null` removes vitest (Expo uses Jest):

```json
{
  "name": "{{APP_SLUG}}",
  "scripts": {
    "dev": "npx expo start",
    "build": "npx eas build",
    "test": "jest --passWithNoTests",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "expo": "~52.0.0",
    "react": "18.3.1",
    "react-native": "0.76.5"
  },
  "devDependencies": {
    "@babel/core": "^7.24.0",
    "@testing-library/react-native": "^13.0.0",
    "@types/react": "~18.3.0",
    "jest": "^29.7.0",
    "jest-expo": "~52.0.0",
    "vitest": null
  },
  "jest": {
    "preset": "jest-expo"
  }
}
```

- [ ] **Step 4: Create `_templates/variants/expo/eas.json`**

```json
{
  "cli": {
    "version": ">= 10.0.0"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal"
    },
    "preview": {
      "distribution": "internal"
    },
    "production": {
      "autoIncrement": true
    }
  },
  "submit": {
    "production": {}
  }
}
```

- [ ] **Step 5: Create `_templates/variants/expo/app.json`**

```json
{
  "expo": {
    "name": "{{PROJECT_NAME}}",
    "slug": "{{APP_SLUG}}",
    "version": "1.0.0",
    "orientation": "portrait",
    "userInterfaceStyle": "automatic",
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "com.example.{{APP_SLUG}}"
    },
    "android": {
      "adaptiveIcon": {
        "backgroundColor": "#ffffff"
      },
      "package": "com.example.{{APP_SLUG}}"
    }
  }
}
```

- [ ] **Step 6: Create `.gitkeep` files**

```bash
touch _templates/variants/expo/src/components/.gitkeep
touch _templates/variants/expo/src/__tests__/.gitkeep
```

- [ ] **Step 7: Verify JSON**

```bash
for f in _templates/variants/expo/*.json; do
  node -e "JSON.parse(require('fs').readFileSync('$f','utf8'))" && echo "OK: $f"
done
```

Expected: `OK:` for each file.

- [ ] **Step 8: Commit**

```bash
git add _templates/variants/expo/
git commit -m "feat: add expo variant template (Expo cross-platform wrapper)"
```

---

## Chunk 3: Colony feature layer

### Task 7: Create `_templates/features/colony/`

**Files:**

- Create: `_templates/features/colony/.colony/conventions.ts.md`
- Create: `_templates/features/colony/.colony/conventions.expo.md`
- Create: `_templates/features/colony/.colony/conventions.ios.md`
- Create: `_templates/features/colony/colony.config.ts.yaml.example`
- Create: `_templates/features/colony/colony.config.ts-build.yaml.example`
- Create: `_templates/features/colony/colony.config.expo.yaml.example`
- Create: `_templates/features/colony/colony.config.ios.yaml.example`
- Create: `_templates/features/colony/CLAUDE.md.colony-block`

- [ ] **Step 1: Create directories**

```bash
mkdir -p _templates/features/colony/.colony
```

- [ ] **Step 2: Create `_templates/features/colony/.colony/conventions.ts.md`**

Used for all TypeScript variants except Expo (cf-single, cf-multi, node-service, react-app, full-stack):

```markdown
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
workers/ ← entry points (thin: parse request, call module, return response)
modules/ ← domain logic (one directory per feature area)
utils/ ← pure stateless helpers (no side effects, no DB access)
test/ ← test helpers only (applySchema, fixtures)

````

## Setup

```bash
npm install
````

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

````

- [ ] **Step 3: Create `_templates/features/colony/.colony/conventions.expo.md`**

```markdown
# {{PROJECT_NAME}} — Colony Conventions

This file teaches Colony agents how to work effectively in this codebase.

## Tech Stack

- Language: TypeScript, React Native
- Framework: Expo ~52
- Package manager: npm + `npx expo install` for native deps
- Testing: Jest + React Native Testing Library (`npm test`)
- Linting: ESLint zero warnings + Prettier
- Builds: EAS Build (`eas build`)

## Project Structure

````

src/
components/ ← reusable UI components
screens/ ← screen-level components (one per route)
hooks/ ← custom React hooks
**tests**/ ← test files
app.json ← Expo config (name, slug, bundle ID)
eas.json ← EAS Build configuration

````

## Setup

```bash
npm install && npx expo install
````

## Running Checks

```bash
npm test            # Jest tests
npm run typecheck   # TypeScript strict check
npm run lint        # ESLint (zero warnings)
```

## Key Constraints

- Use `npx expo install <package>` (not `npm install`) for packages with native modules — Expo manages compatible versions
- No direct `react-native` imports for platform-specific behavior — use Expo SDK equivalents
- `app.json` bundle identifiers follow `com.example.{{APP_SLUG}}` pattern

## Commit Format

Conventional Commits with issue reference:

```
type(scope): subject

Closes #N
```

## What Colony Must NOT Do

- Run `npm install` for native packages — always use `npx expo install`
- Modify `app.json` slug or bundle identifier without confirming with the team
- Leave `console.log` in production code

````

- [ ] **Step 4: Create `_templates/features/colony/.colony/conventions.ios.md`**

```markdown
# {{PROJECT_NAME}} — Colony Conventions

## Tech Stack

- Language: Swift 5.x, SwiftUI
- Dependency manager: Swift Package Manager
- Testing: XCTest
- Linting: SwiftLint (`--strict`)
- Xcode scheme: `{{SCHEME}}`

## Setup

```bash
xcodebuild -resolvePackageDependencies
````

## Running Checks

```bash
xcodebuild test -scheme {{SCHEME}} -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'
swiftlint lint --strict
```

## Code Style

- Follow Apple Swift API Design Guidelines
- Prefer value types (struct/enum) over reference types (class) where appropriate
- No force unwrapping — use `guard let` / `if let`; document exceptions

## Project Structure

See Xcode project navigator. Tests are in a separate `*Tests` target mirroring source structure.

## Commit Format

Conventional Commits with issue reference:

```
type(scope): subject

Closes #N
```

## What Colony Must NOT Do

- Modify the Xcode project file (`.xcodeproj`) unless strictly necessary for adding a new target
- Use CocoaPods — SPM only
- Leave debug print statements in production code

````

- [ ] **Step 5: Create `_templates/features/colony/colony.config.ts.yaml.example`**

For cf-single, cf-multi, node-service (no build step):

```yaml
# Colony configuration for {{PROJECT_NAME}}
# Rename to colony.config.yaml and fill in values before running `colony start`

github:
  owner: {{GITHUB_OWNER}}
  repo: {{GITHUB_REPO}}
  # token_env: GITHUB_TOKEN  # or use GitHub App auth

workspace:
  repo_dir: /tmp/colony/repos
  base_dir: /tmp/colony/workspaces
  setup_command: "npm install"

review:
  checks:
    typecheck: "npm run typecheck"
    lint: "npm run lint"
    test: "npm test"

agents:
  sprint_master:
    poll_interval: 30
    health_port: 3001
  analyzer:
    poll_interval: 30
    health_port: 3002
  developer:
    poll_interval: 60
    health_port: 3003
  reviewer:
    poll_interval: 30
    health_port: 3004
  merger:
    poll_interval: 30
    health_port: 3005
````

- [ ] **Step 6: Create `_templates/features/colony/colony.config.ts-build.yaml.example`**

For react-app and full-stack (adds build step):

```yaml
# Colony configuration for {{PROJECT_NAME}}
# Rename to colony.config.yaml and fill in values before running `colony start`

github:
  owner: { { GITHUB_OWNER } }
  repo: { { GITHUB_REPO } }
  # token_env: GITHUB_TOKEN  # or use GitHub App auth

workspace:
  repo_dir: /tmp/colony/repos
  base_dir: /tmp/colony/workspaces
  setup_command: 'npm install'

review:
  checks:
    typecheck: 'npm run typecheck'
    lint: 'npm run lint'
    test: 'npm test'
    build: 'npm run build'

agents:
  sprint_master:
    poll_interval: 30
    health_port: 3001
  analyzer:
    poll_interval: 30
    health_port: 3002
  developer:
    poll_interval: 60
    health_port: 3003
  reviewer:
    poll_interval: 30
    health_port: 3004
  merger:
    poll_interval: 30
    health_port: 3005
```

- [ ] **Step 7: Create `_templates/features/colony/colony.config.expo.yaml.example`**

```yaml
# Colony configuration for {{PROJECT_NAME}}
# Rename to colony.config.yaml and fill in values before running `colony start`

github:
  owner: { { GITHUB_OWNER } }
  repo: { { GITHUB_REPO } }
  # token_env: GITHUB_TOKEN  # or use GitHub App auth

workspace:
  repo_dir: /tmp/colony/repos
  base_dir: /tmp/colony/workspaces
  setup_command: 'npm install && npx expo install'

review:
  checks:
    typecheck: 'npm run typecheck'
    lint: 'npm run lint'
    test: 'npm test'

agents:
  sprint_master:
    poll_interval: 30
    health_port: 3001
  analyzer:
    poll_interval: 30
    health_port: 3002
  developer:
    poll_interval: 60
    health_port: 3003
  reviewer:
    poll_interval: 30
    health_port: 3004
  merger:
    poll_interval: 30
    health_port: 3005
```

- [ ] **Step 8: Create `_templates/features/colony/colony.config.ios.yaml.example`**

```yaml
# Colony configuration for {{PROJECT_NAME}}
# Rename to colony.config.yaml and fill in values before running `colony start`
# Requires: macOS host with Xcode and SwiftLint installed

github:
  owner: { { GITHUB_OWNER } }
  repo: { { GITHUB_REPO } }
  # token_env: GITHUB_TOKEN  # or use GitHub App auth

workspace:
  repo_dir: /tmp/colony/repos
  base_dir: /tmp/colony/workspaces
  setup_command: 'xcodebuild -resolvePackageDependencies -scheme {{SCHEME}}'

review:
  checks:
    lint: 'swiftlint lint --strict'
    test: "xcodebuild test -scheme {{SCHEME}} -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' | xcpretty"

agents:
  sprint_master:
    poll_interval: 30
    health_port: 3001
  analyzer:
    poll_interval: 30
    health_port: 3002
  developer:
    poll_interval: 60
    health_port: 3003
  reviewer:
    poll_interval: 30
    health_port: 3004
  merger:
    poll_interval: 30
    health_port: 3005
```

- [ ] **Step 9: Create `_templates/features/colony/CLAUDE.md.colony-block`**

This file is appended (not copied) to `CLAUDE.md` by `init.sh` when colony is selected:

````markdown
## Colony Integration

This project is managed by [Colony](https://github.com/beehive-media-us/colony), an autonomous AI development pipeline.

Colony reads `.colony/conventions.md` to understand how to work in this repo. To start Colony:

```bash
colony start
```
````

Colony manages issues end-to-end: it analyzes new issues, implements solutions in git worktrees, runs the review checks defined in `colony.config.yaml`, and prepares PRs for human review.

See `colony.config.yaml` for agent configuration and review check setup.

````

- [ ] **Step 10: Verify structure**

```bash
find _templates/features/colony -type f | sort
````

Expected: 8 files (3 conventions, 4 colony configs, 1 CLAUDE.md block).

- [ ] **Step 11: Commit**

```bash
git add _templates/features/
git commit -m "feat: add colony feature layer (conventions, config, CLAUDE.md block)"
```

---

## Chunk 4: `init.sh` rewrite

### Task 8: Rewrite `init.sh` — skeleton + Phase 1 (gather config)

**Files:**

- Modify: `scripts/init.sh`

- [ ] **Step 1: Write the new `scripts/init.sh` — header and helpers**

Replace the entire file with the following. Note: the spec's `{{CI_STEPS}}`, `{{TEST_CMD}}`, and `{{LINT_CMD}}` placeholders are intentionally **not** implemented — all TS variants use identical npm commands in their hooks and CI, so parameterization adds no value. The `ios-native` variant overrides git hooks and CI entirely via its own files in `_templates/variants/ios-native/`.

```bash
#!/usr/bin/env bash
# scripts/init.sh — Scaffold project initializer
# Run this once after cloning the template. It self-destructs after use.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

header() { echo -e "\n${BLUE}${BOLD}=== $1 ===${NC}\n"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $1"; }
error()   { echo -e "${RED}✗${NC}  $1" >&2; }
prompt()  { echo -e "${BOLD}$1${NC}"; }

# ─── Helpers ──────────────────────────────────────────────────────────────────
read_input() {
  local var_name="$1" question="$2" default="${3:-}"
  if [[ -n "$default" ]]; then
    prompt "$question [$default]: "
  else
    prompt "$question: "
  fi
  read -r "$var_name" || true
  local val; eval val="\$$var_name"
  if [[ -z "$val" && -n "$default" ]]; then
    eval "$var_name='$default'"
  fi
}

read_yes_no() {
  local var_name="$1" question="$2" default="${3:-y}"
  local disp; [[ "$default" == "y" ]] && disp="Y/n" || disp="y/N"
  prompt "$question [$disp]: "
  read -r answer || true
  answer="${answer:-$default}"
  [[ "$answer" =~ ^[Yy] ]] && eval "$var_name=true" || eval "$var_name=false"
}

read_choice() {
  local var_name="$1" question="$2"
  shift 2
  local choices=("$@")
  prompt "$question"
  for i in "${!choices[@]}"; do echo "  $((i+1)). ${choices[$i]}"; done
  prompt "Choice [1]: "
  read -r choice || true
  choice="${choice:-1}"
  if [[ "$choice" -ge 1 && "$choice" -le "${#choices[@]}" ]]; then
    eval "$var_name='${choices[$((choice-1))]}'"
  else
    eval "$var_name='${choices[0]}'"
  fi
}

validate_kebab_case() {
  [[ "$1" =~ ^[a-z][a-z0-9-]*[a-z0-9]$ ]]
}

portable_sed() {
  if sed --version &>/dev/null 2>&1; then
    sed -i "$@"
  else
    sed -i '' "$@"
  fi
}

# Apply all files from a layer directory onto the project root.
# package.json is deep-merged; all other files are copied (overwrite).
apply_layer() {
  local layer="$1"
  [[ -d "$layer" ]] || return 0

  find "$layer" -type f | while read -r src; do
    local rel="${src#$layer/}"
    local dst="./$rel"
    mkdir -p "$(dirname "$dst")"

    if [[ "$rel" == "package.json" && -f "$dst" ]]; then
      cp "$src" /tmp/_scaffold_pkg_overlay.json
      # Inline the deep merge with actual paths substituted
      node --input-type=module << JSEOF
import { readFileSync, writeFileSync } from 'fs';
function deepMerge(base, over) {
  const result = { ...base };
  for (const [k, v] of Object.entries(over)) {
    if (v === null) { delete result[k]; }
    else if (v && typeof v === 'object' && !Array.isArray(v)) {
      result[k] = deepMerge(result[k] || {}, v);
    } else { result[k] = v; }
  }
  return result;
}
const base = JSON.parse(readFileSync('$dst', 'utf8'));
const over = JSON.parse(readFileSync('/tmp/_scaffold_pkg_overlay.json', 'utf8'));
writeFileSync('$dst', JSON.stringify(deepMerge(base, over), null, 2) + '\n');
JSEOF
    else
      cp "$src" "$dst"
    fi
  done
}

# Substitute all {{PLACEHOLDERS}} in a file.
substitute_file() {
  local file="$1"
  portable_sed \
    -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
    -e "s|{{PROJECT_DESCRIPTION}}|$PROJECT_DESCRIPTION|g" \
    -e "s|{{VARIANT}}|$VARIANT|g" \
    -e "s|{{WORKER_NAME}}|$WORKER_NAME|g" \
    -e "s|{{D1_DATABASE_NAME}}|$D1_DATABASE_NAME|g" \
    -e "s|{{NODE_VERSION}}|$NODE_VERSION|g" \
    -e "s|{{SCHEME}}|$SCHEME|g" \
    -e "s|{{APP_SLUG}}|$APP_SLUG|g" \
    -e "s|{{GITHUB_OWNER}}|$GITHUB_OWNER|g" \
    -e "s|{{GITHUB_REPO}}|$GITHUB_REPO|g" \
    "$file"
}
```

- [ ] **Step 2: Add Phase 1 — Gather Config**

Append to `scripts/init.sh`:

```bash
# ─── Phase 1: Gather config ───────────────────────────────────────────────────
header "Phase 1: Project Configuration"

# Project name
while true; do
  read_input PROJECT_NAME "Project name (kebab-case)" ""
  if validate_kebab_case "$PROJECT_NAME"; then break
  else error "Name must be kebab-case (e.g. my-cool-project)"; fi
done

# Description
read_input PROJECT_DESCRIPTION "One-line description" "A Beehive project"

# Variant
read_choice VARIANT "Architecture variant:" \
  "cf-single   (Single Cloudflare Worker)" \
  "cf-multi    (Multi-worker Cloudflare — fozzy pattern)" \
  "node-service (Node.js agent/service — colony pattern)" \
  "react-app   (Vite + React frontend)" \
  "full-stack  (CF Workers Assets + React frontend)" \
  "ios-native  (iOS native app — requires Xcode)" \
  "expo        (Expo cross-platform iOS + Android)"
VARIANT="${VARIANT%% *}"  # strip display label

# Variant-specific prompts
SCHEME=""
APP_SLUG=""
if [[ "$VARIANT" == "ios-native" ]]; then
  read_input SCHEME "Xcode scheme name" "$PROJECT_NAME"
elif [[ "$VARIANT" == "expo" ]]; then
  read_input APP_SLUG "Expo app slug (lowercase, no spaces)" "$PROJECT_NAME"
fi

# Colony feature
read_yes_no ENABLE_COLONY "Enable Colony integration?" "n"
GITHUB_OWNER=""
GITHUB_REPO=""
COLONY_CONFIG_NOW=false
if [[ "$ENABLE_COLONY" == "true" ]]; then
  read_yes_no COLONY_GITHUB "Is this repo already on GitHub?" "n"
  if [[ "$COLONY_GITHUB" == "true" ]]; then
    read_input GITHUB_OWNER "GitHub owner (org or user)" ""
    GITHUB_REPO="$PROJECT_NAME"
  fi
  read_yes_no COLONY_CONFIG_NOW "Write colony.config.yaml now (vs .example only)?" "n"
fi

# Optional features
read_yes_no ENABLE_CPD     "Enable jscpd duplicate-code detection?" "y"
read_yes_no ENABLE_COMMITLINT "Enable commitlint (Conventional Commits)?" "y"

# Node version (TS variants only)
NODE_VERSION="20"
if [[ "$VARIANT" != "ios-native" ]]; then
  read_input NODE_VERSION "Node.js version" "20"
fi

# GitHub org for repo creation (optional)
read_input GITHUB_ORG "GitHub org for repo creation (blank to skip)" ""

# Derived values
WORKER_NAME="$PROJECT_NAME"
D1_DATABASE_NAME="${PROJECT_NAME}-db"

# Features array
FEATURES=()
[[ "$ENABLE_COLONY" == "true" ]] && FEATURES+=("colony")
```

- [ ] **Step 3: Add Phase 2 — Resolve Layers**

Append to `scripts/init.sh`:

```bash
# ─── Phase 2: Resolve layers ──────────────────────────────────────────────────
header "Phase 2: Resolving template layers"

LAYERS=("_templates/base")
if [[ "$VARIANT" != "ios-native" ]]; then
  LAYERS+=("_templates/ts-base")
fi
LAYERS+=("_templates/variants/$VARIANT")
for feature in "${FEATURES[@]}"; do
  LAYERS+=("_templates/features/$feature")
done

success "Layer order: ${LAYERS[*]}"
```

- [ ] **Step 4: Verify syntax**

```bash
bash -n scripts/init.sh && echo "syntax OK"
```

Expected: `syntax OK`

- [ ] **Step 5: Commit**

```bash
git add scripts/init.sh
git commit -m "feat(init): rewrite Phase 1 (gather config) and Phase 2 (resolve layers)"
```

---

### Task 9: Rewrite `init.sh` — Phase 3 (generator) + Phase 4 (apply layers)

- [ ] **Step 1: Append Phase 3 — Generator Wrapper**

```bash
# ─── Phase 3: Generator wrapper (iOS and Expo only) ──────────────────────────
if [[ "$VARIANT" == "ios-native" ]]; then
  header "Phase 3: Running iOS generator"
  if ! command -v xcodegen &>/dev/null && ! command -v swift &>/dev/null; then
    error "Xcode command-line tools not found."
    error "Install Xcode from the App Store, then run: xcode-select --install"
    exit 1
  fi
  # Verify Xcode CLI tools are installed
  if ! xcode-select -p &>/dev/null; then
    error "Xcode CLI tools not configured. Run: xcode-select --install"
    exit 1
  fi
  if command -v xcodegen &>/dev/null; then
    # xcodegen requires a project.yml — scaffold layers provide it if present
    warn "xcodegen found — run 'xcodegen generate' after customising project.yml"
  else
    swift package init --name "$PROJECT_NAME" --type executable
    success "Swift package initialized"
  fi

elif [[ "$VARIANT" == "expo" ]]; then
  header "Phase 3: Running Expo generator"
  if ! command -v npx &>/dev/null; then
    error "npx not found — install Node.js first: https://nodejs.org"
    exit 1
  fi
  # create-expo-app requires an empty directory; move existing files aside temporarily
  tmpdir=$(mktemp -d)
  shopt -s dotglob
  mv _templates scripts "$tmpdir/" 2>/dev/null || true
  shopt -u dotglob

  npx create-expo-app@latest . --template blank-typescript --no-install
  success "Expo project generated"

  # Restore scaffold files
  shopt -s dotglob
  mv "$tmpdir"/* . 2>/dev/null || true
  shopt -u dotglob
  rm -rf "$tmpdir"
else
  header "Phase 3: Generator wrapper (skipped — not iOS or Expo)"
  success "No upstream generator needed for $VARIANT"
fi
```

- [ ] **Step 2: Append Phase 4 — Apply Layers**

```bash
# ─── Phase 4: Apply template layers ──────────────────────────────────────────
header "Phase 4: Applying template layers"

for layer in "${LAYERS[@]}"; do
  if [[ -d "$layer" ]]; then
    apply_layer "$layer"
    success "Applied layer: $layer"
  else
    warn "Layer directory not found (skipped): $layer"
  fi
done

# Special: colony CLAUDE.md block (append, not overwrite)
if [[ "$ENABLE_COLONY" == "true" ]]; then
  cat "_templates/features/colony/CLAUDE.md.colony-block" >> CLAUDE.md
  success "Appended colony block to CLAUDE.md"

  # Select the right colony conventions file
  mkdir -p .colony
  if [[ "$VARIANT" == "ios-native" ]]; then
    cp "_templates/features/colony/.colony/conventions.ios.md" ".colony/conventions.md"
  elif [[ "$VARIANT" == "expo" ]]; then
    cp "_templates/features/colony/.colony/conventions.expo.md" ".colony/conventions.md"
  else
    cp "_templates/features/colony/.colony/conventions.ts.md" ".colony/conventions.md"
  fi
  success "Installed .colony/conventions.md"

  # Select right colony config template
  colony_config_src=""
  if [[ "$VARIANT" == "ios-native" ]]; then
    colony_config_src="_templates/features/colony/colony.config.ios.yaml.example"
  elif [[ "$VARIANT" == "react-app" || "$VARIANT" == "full-stack" ]]; then
    colony_config_src="_templates/features/colony/colony.config.ts-build.yaml.example"
  elif [[ "$VARIANT" == "expo" ]]; then
    colony_config_src="_templates/features/colony/colony.config.expo.yaml.example"
  else
    colony_config_src="_templates/features/colony/colony.config.ts.yaml.example"
  fi

  if [[ "$COLONY_CONFIG_NOW" == "true" ]]; then
    cp "$colony_config_src" "colony.config.yaml"
    success "Created colony.config.yaml (fill in values before use)"
  else
    cp "$colony_config_src" "colony.config.yaml.example"
    success "Created colony.config.yaml.example (rename to colony.config.yaml when ready)"
  fi
fi

# Substitute all placeholders in all project files.
# Two passes: (1) files by extension, (2) extensionless git hook files explicitly.
success "Substituting placeholders..."
find . -type f \
  \( -name "*.ts" -o -name "*.tsx" -o -name "*.toml" -o -name "*.sql" \
     -o -name "*.html" -o -name "*.json" -o -name "*.md" -o -name "*.yaml" \
     -o -name "*.yml" -o -name "*.sh" -o -name "*.txt" \) \
  ! -path "./.git/*" \
  ! -path "./_templates/*" \
  ! -path "./node_modules/*" \
  ! -path "./DerivedData/*" \
  ! -path "./.build/*" | while read -r file; do
    substitute_file "$file"
done

# Explicitly substitute extensionless git hook files (e.g. {{SCHEME}} in iOS pre-push)
for hook in .githooks/pre-commit .githooks/pre-push .githooks/commit-msg; do
  [[ -f "$hook" ]] && substitute_file "$hook"
done

# Update .nvmrc (TS variants only)
if [[ "$VARIANT" != "ios-native" ]]; then
  echo "$NODE_VERSION" > .nvmrc
  success "Updated .nvmrc → Node $NODE_VERSION"
fi

# Handle optional feature toggles
if [[ "$ENABLE_CPD" == "false" ]]; then
  portable_sed '/npm run cpd/d' .githooks/pre-push 2>/dev/null || true
  node --input-type=module << JSEOF
import { readFileSync, writeFileSync } from 'fs';
try {
  const pkg = JSON.parse(readFileSync('package.json', 'utf8'));
  delete pkg.devDependencies?.jscpd;
  delete pkg.scripts?.cpd;
  writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
} catch {}
JSEOF
  rm -f jscpd.json
  warn "cpd disabled — removed hook entry, dep, and jscpd.json"
fi

if [[ "$ENABLE_COMMITLINT" == "false" ]]; then
  rm -f .githooks/commit-msg
  node --input-type=module << JSEOF
import { readFileSync, writeFileSync } from 'fs';
try {
  const pkg = JSON.parse(readFileSync('package.json', 'utf8'));
  delete pkg.devDependencies?.['@commitlint/cli'];
  delete pkg.devDependencies?.['@commitlint/config-conventional'];
  delete pkg.devDependencies?.['@commitlint/types'];
  writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
} catch {}
JSEOF
  rm -f commitlint.config.js
  warn "commitlint disabled — removed hook, deps, and commitlint.config.js"
fi
```

- [ ] **Step 3: Verify syntax**

```bash
bash -n scripts/init.sh && echo "syntax OK"
```

Expected: `syntax OK`

- [ ] **Step 4: Commit**

```bash
git add scripts/init.sh
git commit -m "feat(init): add Phase 3 (generator wrapper) and Phase 4 (apply layers)"
```

---

### Task 10: Rewrite `init.sh` — Phases 5–8 + final wiring

- [ ] **Step 1: Append Phase 5 — Configure Git Hooks**

```bash
# ─── Phase 5: Configure git hooks ────────────────────────────────────────────
header "Phase 5: Configuring git hooks"

git config core.hooksPath .githooks
chmod +x .githooks/* 2>/dev/null || true
success "Registered .githooks as git hooks path"
```

- [ ] **Step 2: Append Phase 6 — Install Dependencies**

```bash
# ─── Phase 6: Install dependencies ───────────────────────────────────────────
if [[ "$VARIANT" == "ios-native" ]]; then
  header "Phase 6: Resolving Swift package dependencies"
  if xcode-select -p &>/dev/null; then
    xcodebuild -resolvePackageDependencies 2>/dev/null || \
      warn "No Swift Package Manager manifest found — skipping dependency resolution"
  fi
else
  header "Phase 6: Installing npm dependencies"
  npm install
  success "npm install complete"
fi
```

- [ ] **Step 3: Append Phase 7 — Initial Commit**

```bash
# ─── Phase 7: Initial commit ─────────────────────────────────────────────────
header "Phase 7: Creating initial commit"

# Write template.config.json
FEATURES_JSON="["
for i in "${!FEATURES[@]}"; do
  [[ $i -gt 0 ]] && FEATURES_JSON+=","
  FEATURES_JSON+="\"${FEATURES[$i]}\""
done
FEATURES_JSON+="]"

cat > template.config.json << EOF
{
  "_comment": "Written by scripts/init.sh — documents how this project was initialized.",
  "projectName": "$PROJECT_NAME",
  "projectDescription": "$PROJECT_DESCRIPTION",
  "variant": "$VARIANT",
  "features": $FEATURES_JSON,
  "nodeVersion": "$NODE_VERSION",
  "initializedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
success "Wrote template.config.json"

git add -A
git commit -m "chore: init project from scaffold template"
success "Initial commit created"
```

- [ ] **Step 4: Append Phase 8 — GitHub Repo Creation + Self-Cleanup**

```bash
# ─── Phase 8: Optional GitHub repo creation + self-cleanup ───────────────────
header "Phase 8: Finishing up"

if [[ -n "$GITHUB_ORG" ]]; then
  if command -v gh &>/dev/null; then
    gh repo create "$GITHUB_ORG/$PROJECT_NAME" --public --source=. --push
    success "Created github.com/$GITHUB_ORG/$PROJECT_NAME"
    if [[ -f "scripts/setup-branch-protection.sh" ]]; then
      bash scripts/setup-branch-protection.sh "$GITHUB_ORG" "$PROJECT_NAME"
    fi
  else
    warn "gh CLI not found — skipping GitHub repo creation"
    warn "Run manually: gh repo create $GITHUB_ORG/$PROJECT_NAME --public --source=. --push"
  fi
fi

# Self-cleanup — remove init.sh BEFORE the commit so it's included in the cleanup commit
rm -rf _templates/
rm -f scripts/init.sh
[[ -z "$(ls -A scripts/ 2>/dev/null)" ]] && rmdir scripts/ 2>/dev/null || true
git add -A
git commit -m "chore: remove scaffold templates and init script" || true

# Print next steps
echo ""
echo -e "${GREEN}${BOLD}✓ $PROJECT_NAME initialized successfully!${NC}"
echo ""
echo "Next steps:"
echo "  1. Review TODOs in CLAUDE.md and docs/ARCHITECTURE.md"
echo "  2. Copy .dev.vars.example → .dev.vars and fill in secrets"
if [[ "$VARIANT" == cf-* || "$VARIANT" == "full-stack" ]]; then
  echo "  3. Create Cloudflare resources, set GitHub vars: CF_D1_DATABASE_ID, CF_ACCOUNT_ID"
  echo "     CF_API_TOKEN (secret)"
fi
if [[ "$VARIANT" == "ios-native" ]]; then
  echo "  3. Open the Xcode project and configure your team/signing"
fi
if [[ "$VARIANT" == "expo" ]]; then
  echo "  3. Run: npx expo start"
fi
if [[ "$ENABLE_COLONY" == "true" ]]; then
  echo ""
  echo "  Colony: fill in colony.config.yaml then run: colony start"
fi
echo ""
echo "  npm run dev       # start development"
echo "  npm test          # run tests"
echo "  npm run typecheck # check types"
echo ""
```

- [ ] **Step 5: Final syntax check**

```bash
bash -n scripts/init.sh && echo "syntax OK"
```

Expected: `syntax OK`

- [ ] **Step 6: Smoke test — verify the layer structure is self-consistent**

```bash
# Confirm all variant directories exist
for v in cf-single cf-multi node-service react-app full-stack ios-native expo; do
  test -d "_templates/variants/$v" && echo "OK: $v" || echo "MISSING: $v"
done

# Confirm colony feature exists
test -d "_templates/features/colony" && echo "OK: colony feature" || echo "MISSING: colony feature"

# Confirm base and ts-base exist
test -d "_templates/base" && echo "OK: base" || echo "MISSING: base"
test -d "_templates/ts-base" && echo "OK: ts-base" || echo "MISSING: ts-base"
```

Expected: All lines print `OK:`.

- [ ] **Step 7: Validate all package.json fragments are valid JSON**

```bash
find _templates -name "package.json" | while read -r f; do
  node -e "JSON.parse(require('fs').readFileSync('$f','utf8'))" && echo "OK: $f" || echo "INVALID: $f"
done
```

Expected: All print `OK:`.

- [ ] **Step 8: Final commit**

```bash
git add scripts/init.sh
git commit -m "feat(init): add Phases 5–8 (hooks, deps, commit, cleanup) — init.sh rewrite complete"
```

---

## Final Verification

- [ ] **Run shellcheck on init.sh (if available)**

```bash
command -v shellcheck && shellcheck scripts/init.sh || warn "shellcheck not installed — skipping"
```

- [ ] **Confirm old flat \_templates/ structure is gone**

```bash
# These directories should NOT exist at _templates/ root anymore
for d in cf-single cf-multi node-service react-app; do
  test -d "_templates/$d" && echo "ERROR: still exists at root" || echo "OK: $d moved"
done
```

Expected: All print `OK:`.

- [ ] **Confirm full file count**

```bash
find _templates -type f | wc -l
```

Expected: approximately 45–55 files total across all layers.

- [ ] **Final commit if any cleanup needed**

```bash
git status
# If clean, nothing to do. If dirty, commit any final tweaks.
```
