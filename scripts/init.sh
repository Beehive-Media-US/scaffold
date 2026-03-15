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
for feature in "${FEATURES[@]}"; do
  LAYERS+=("_templates/features/$feature")
done

success "Layer order: ${LAYERS[*]}"
