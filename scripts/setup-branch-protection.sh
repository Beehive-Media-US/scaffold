#!/usr/bin/env bash
# scripts/setup-branch-protection.sh
# Configure branch protection rules for main via gh CLI
set -euo pipefail

GITHUB_ORG="${1:-}"
REPO_NAME="${2:-}"

if [[ -z "$GITHUB_ORG" || -z "$REPO_NAME" ]]; then
  echo "Usage: $0 <github-org> <repo-name>"
  exit 1
fi

if ! command -v gh &>/dev/null; then
  echo "gh CLI not found. Install from https://cli.github.com/"
  exit 1
fi

REPO="$GITHUB_ORG/$REPO_NAME"

echo "Configuring branch protection for $REPO (main)..."

gh api \
  --method PUT \
  "repos/$REPO/branches/main/protection" \
  --input - <<'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["Typecheck", "Lint", "Security audit", "Test"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 0
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true
}
EOF

echo "✓ Branch protection configured for $REPO:main"
