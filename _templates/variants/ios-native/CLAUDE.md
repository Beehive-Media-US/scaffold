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
