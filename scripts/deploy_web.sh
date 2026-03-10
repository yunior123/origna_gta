#!/usr/bin/env bash
set -euo pipefail

# Deploy Flutter web build to Hetzner VPS
# Usage: ./scripts/deploy_web.sh [dev|staging|prod]

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$REPO_ROOT/origna_gta"
REMOTE_USER="${REMOTE_USER:-root}"
REMOTE_HOST="${REMOTE_HOST:-204.168.137.16}"
REMOTE_DIR="${REMOTE_DIR:-/var/www/orignagta}"
SSH_TARGET="${REMOTE_USER}@${REMOTE_HOST}"
ENV="${1:-dev}"

echo "=== Building Flutter web ($ENV) ==="
cd "$APP_DIR"
flutter build web --release --dart-define=ENVIRONMENT="$ENV"

echo "=== Deploying to $SSH_TARGET:$REMOTE_DIR ==="
ssh "$SSH_TARGET" "mkdir -p '$REMOTE_DIR'"

rsync -avz --delete \
  "$APP_DIR/build/web/" \
  "$SSH_TARGET:$REMOTE_DIR/"

ssh "$SSH_TARGET" "find '$REMOTE_DIR' -type d -exec chmod 755 {} \; && find '$REMOTE_DIR' -type f -exec chmod 644 {} \;"

echo "=== Deploy complete ==="
echo "Site: https://www.orignagta.ca"
echo "API:  https://api.orignagta.ca"
