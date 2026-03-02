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
    prompt "$question [${default}]: "
  else
    prompt "$question: "
  fi
  read -r "$var_name" || true
  local val
  eval val="\$$var_name"
  if [[ -z "$val" && -n "$default" ]]; then
    eval "$var_name='$default'"
  fi
}

read_yes_no() {
  local var_name="$1" question="$2" default="${3:-y}"
  local default_display
  if [[ "$default" == "y" ]]; then default_display="Y/n"; else default_display="y/N"; fi
  prompt "$question [$default_display]: "
  read -r answer || true
  answer="${answer:-$default}"
  if [[ "$answer" =~ ^[Yy] ]]; then
    eval "$var_name=true"
  else
    eval "$var_name=false"
  fi
}

read_choice() {
  local var_name="$1" question="$2"
  shift 2
  local choices=("$@")
  prompt "$question"
  for i in "${!choices[@]}"; do
    echo "  $((i+1)). ${choices[$i]}"
  done
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
  local name="$1"
  if [[ ! "$name" =~ ^[a-z][a-z0-9-]*[a-z0-9]$ ]]; then
    return 1
  fi
  return 0
}

portable_sed() {
  # Cross-platform sed -i (BSD vs GNU)
  if sed --version &>/dev/null 2>&1; then
    sed -i "$@"        # GNU
  else
    sed -i '' "$@"     # BSD/macOS
  fi
}

# ─── Phase 1: Gather inputs ───────────────────────────────────────────────────
header "Phase 1: Project Configuration"

# Project name
while true; do
  read_input PROJECT_NAME "Project name (kebab-case)" ""
  if validate_kebab_case "$PROJECT_NAME"; then
    break
  else
    error "Name must be kebab-case (lowercase letters, numbers, hyphens). Example: my-cool-project"
  fi
done

# Description
read_input PROJECT_DESCRIPTION "One-line description" "A Beehive project"

# Variant
read_choice VARIANT "Architecture variant:" \
  "cf-single (Single Cloudflare Worker)" \
  "cf-multi (Multi-worker Cloudflare — fozzy pattern)" \
  "node-service (Node.js agent/service — colony pattern)" \
  "react-app (Vite + React frontend)"

# Extract just the variant key
VARIANT="${VARIANT%% *}"

# D1 / KV (CF variants only)
ENABLE_D1=false
ENABLE_KV=false
if [[ "$VARIANT" == cf-* ]]; then
  read_yes_no ENABLE_D1 "Enable D1 database?" "y"
  read_yes_no ENABLE_KV "Enable KV namespace?" "y"
fi

# Optional features
read_yes_no ENABLE_CPD "Enable jscpd duplicate-code detection?" "y"
read_yes_no ENABLE_COMMITLINT "Enable commitlint (enforce Conventional Commits)?" "y"

# Node version
read_input NODE_VERSION "Node.js version" "20"

# GitHub org
read_input GITHUB_ORG "GitHub organization (leave blank to skip repo creation)" ""

# Worker name (CF variants)
WORKER_NAME="$PROJECT_NAME"
D1_DATABASE_NAME="${PROJECT_NAME}-db"

# ─── Write template.config.json ───────────────────────────────────────────────
cat > template.config.json <<EOF
{
  "_comment": "Written by scripts/init.sh — documents how this project was initialized.",
  "projectName": "$PROJECT_NAME",
  "projectDescription": "$PROJECT_DESCRIPTION",
  "variant": "$VARIANT",
  "enableD1": $ENABLE_D1,
  "enableKV": $ENABLE_KV,
  "enableCpd": $ENABLE_CPD,
  "enableCommitlint": $ENABLE_COMMITLINT,
  "nodeVersion": "$NODE_VERSION",
  "githubOrg": "$GITHUB_ORG",
  "initializedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
success "Wrote template.config.json"

# ─── Phase 2: Substitute placeholders ─────────────────────────────────────────
header "Phase 2: Substituting placeholders"

FILES_TO_SUBSTITUTE=(
  "package.json"
  "CLAUDE.md"
  "README.md"
  "docs/ARCHITECTURE.md"
  ".claude/conventions.md"
)

# Add wrangler files if CF variant
if [[ "$VARIANT" == cf-* ]]; then
  for f in wrangler*.toml; do
    [[ -f "$f" ]] && FILES_TO_SUBSTITUTE+=("$f")
  done
fi

for file in "${FILES_TO_SUBSTITUTE[@]}"; do
  if [[ -f "$file" ]]; then
    portable_sed \
      -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
      -e "s|{{PROJECT_DESCRIPTION}}|$PROJECT_DESCRIPTION|g" \
      -e "s|{{WORKER_NAME}}|$WORKER_NAME|g" \
      -e "s|{{D1_DATABASE_NAME}}|$D1_DATABASE_NAME|g" \
      -e "s|{{NODE_VERSION}}|$NODE_VERSION|g" \
      "$file"
    success "Substituted $file"
  fi
done

# Update .nvmrc
echo "$NODE_VERSION" > .nvmrc
success "Updated .nvmrc → $NODE_VERSION"

# ─── Phase 3: Overlay architecture variant ────────────────────────────────────
header "Phase 3: Applying variant overlay ($VARIANT)"

TEMPLATE_DIR="_templates/$VARIANT"
if [[ ! -d "$TEMPLATE_DIR" ]]; then
  error "Template directory not found: $TEMPLATE_DIR"
  exit 1
fi

# Clear existing src/
rm -rf src/
mkdir -p src/

# Copy template files
cp -r "$TEMPLATE_DIR/." .

# Substitute placeholders in newly copied files
find src -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.toml" -o -name "*.sql" -o -name "*.html" \) | while read -r file; do
  portable_sed \
    -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
    -e "s|{{PROJECT_DESCRIPTION}}|$PROJECT_DESCRIPTION|g" \
    -e "s|{{WORKER_NAME}}|$WORKER_NAME|g" \
    -e "s|{{D1_DATABASE_NAME}}|$D1_DATABASE_NAME|g" \
    -e "s|{{NODE_VERSION}}|$NODE_VERSION|g" \
    "$file"
done

success "Overlaid $VARIANT template"

# Adjust tsconfig for Node variants
if [[ "$VARIANT" == "node-service" ]]; then
  cat > tsconfig.json <<'TSEOF'
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
  "exclude": ["node_modules", "dist", "_templates"]
}
TSEOF
  success "Adjusted tsconfig.json for Node16"
fi

# Prune unused deps from package.json
if [[ "$VARIANT" == "node-service" || "$VARIANT" == "react-app" ]]; then
  # Remove CF-specific deps
  if command -v node &>/dev/null; then
    node -e "
      const fs = require('fs');
      const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
      const cfDeps = ['@cloudflare/vitest-pool-workers', '@cloudflare/workers-types', 'wrangler'];
      cfDeps.forEach(d => delete pkg.devDependencies[d]);
      fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
    "
    success "Pruned CF-specific deps from package.json"
  fi
fi

if [[ "$VARIANT" == "react-app" ]]; then
  if command -v node &>/dev/null; then
    node -e "
      const fs = require('fs');
      const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
      // Add React deps
      pkg.dependencies = pkg.dependencies || {};
      pkg.dependencies['react'] = '^18.3.1';
      pkg.dependencies['react-dom'] = '^18.3.1';
      pkg.devDependencies['@vitejs/plugin-react'] = '^4.3.4';
      pkg.devDependencies['@types/react'] = '^18.3.18';
      pkg.devDependencies['@types/react-dom'] = '^18.3.5';
      pkg.devDependencies['vite'] = '^6.0.11';
      // Update dev script
      pkg.scripts.dev = 'vite';
      pkg.scripts.build = 'vite build';
      pkg.scripts.preview = 'vite preview';
      fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
    "
    success "Added React deps to package.json"
  fi
fi

# Handle D1/KV toggles for CF variants
if [[ "$VARIANT" == cf-* ]]; then
  if [[ "$ENABLE_D1" == "false" ]]; then
    for f in wrangler*.toml; do
      [[ -f "$f" ]] && portable_sed '/^\[\[d1_databases\]\]/,/^$/d' "$f"
    done
    warn "D1 disabled — removed [[d1_databases]] from wrangler configs"
  fi
  if [[ "$ENABLE_KV" == "false" ]]; then
    for f in wrangler*.toml; do
      [[ -f "$f" ]] && portable_sed '/^\[\[kv_namespaces\]\]/,/^$/d' "$f"
    done
    warn "KV disabled — removed [[kv_namespaces]] from wrangler configs"
  fi
fi

# ─── Phase 4: Configure git hooks ─────────────────────────────────────────────
header "Phase 4: Configuring git hooks"

git config core.hooksPath .githooks
chmod +x .githooks/*
success "Registered .githooks path"

if [[ "$ENABLE_COMMITLINT" == "false" ]]; then
  rm -f .githooks/commit-msg
  if command -v node &>/dev/null; then
    node -e "
      const fs = require('fs');
      const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
      delete pkg.devDependencies['@commitlint/cli'];
      delete pkg.devDependencies['@commitlint/config-conventional'];
      delete pkg.devDependencies['@commitlint/types'];
      fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
    "
  fi
  warn "commitlint disabled — removed hook and deps"
fi

if [[ "$ENABLE_CPD" == "false" ]]; then
  # Remove cpd from pre-push hook
  portable_sed '/npm run cpd/d' .githooks/pre-push
  if command -v node &>/dev/null; then
    node -e "
      const fs = require('fs');
      const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
      delete pkg.devDependencies['jscpd'];
      delete pkg.scripts['cpd'];
      fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
    "
  fi
  rm -f jscpd.json
  warn "cpd disabled — removed hook entry, dep, and jscpd.json"
fi

# ─── Phase 5: Install dependencies ────────────────────────────────────────────
header "Phase 5: Installing dependencies"

npm install
success "npm install complete"

# ─── Phase 6: Initialize git and first commit ─────────────────────────────────
header "Phase 6: Git init and initial commit"

if [[ ! -d ".git" ]]; then
  git init
  success "git init"
fi

git add .
git commit -m "chore: init project from scaffold template"
success "Initial commit created"

# ─── Phase 7: Optional GitHub repo creation ───────────────────────────────────
if [[ -n "$GITHUB_ORG" ]]; then
  header "Phase 7: Creating GitHub repository"
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
else
  header "Phase 7: GitHub repo creation"
  warn "No GitHub org provided — skipping repo creation"
fi

# ─── Phase 8: Self-cleanup ────────────────────────────────────────────────────
header "Phase 8: Cleanup"

rm -rf _templates/
success "Removed _templates/"

# Commit cleanup
git add -A
git commit -m "chore: remove scaffold templates and init script" || true

# Self-destruct
rm -f scripts/init.sh
if [[ -z "$(ls -A scripts/ 2>/dev/null)" ]]; then
  rmdir scripts/ 2>/dev/null || true
fi

echo ""
echo -e "${GREEN}${BOLD}✓ Project initialized successfully!${NC}"
echo ""
echo "Next steps:"
echo "  1. Review and complete TODOs in CLAUDE.md and docs/ARCHITECTURE.md"
echo "  2. Copy .dev.vars.example to .dev.vars and fill in secrets"
if [[ "$VARIANT" == cf-* ]]; then
  echo "  3. Create Cloudflare resources and set GitHub vars/secrets"
  echo "     - CF_D1_DATABASE_ID, CF_KV_NAMESPACE_ID, CF_ACCOUNT_ID"
  echo "     - CF_API_TOKEN (secret)"
fi
echo ""
echo "  npm run dev       # start development"
echo "  npm test          # run tests"
echo "  npm run typecheck # check types"
echo ""
