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
```

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
