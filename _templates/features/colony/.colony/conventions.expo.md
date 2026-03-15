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

```
src/
  components/  ← reusable UI components
  screens/     ← screen-level components (one per route)
  hooks/       ← custom React hooks
  __tests__/   ← test files
app.json       ← Expo config (name, slug, bundle ID)
eas.json       ← EAS Build configuration
```

## Setup

```bash
npm install && npx expo install
```

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
