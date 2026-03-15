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

# ─── Phase 2: Resolve layers ──────────────────────────────────────────────────
header "Phase 2: Resolving template layers"

LAYERS=("_templates/base")
if [[ "$VARIANT" != "ios-native" ]]; then
  LAYERS+=("_templates/ts-base")
fi
LAYERS+=("_templates/variants/$VARIANT")
# Note: colony is intentionally NOT added to LAYERS — it has per-variant selection
# logic handled entirely in Phase 4. All other future features can use LAYERS.

success "Layer order: ${LAYERS[*]}"
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
# ─── Phase 5: Configure git hooks ────────────────────────────────────────────
header "Phase 5: Configuring git hooks"

git config core.hooksPath .githooks
chmod +x .githooks/* 2>/dev/null || true
success "Registered .githooks as git hooks path"

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
