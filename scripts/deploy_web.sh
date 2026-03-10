#!/usr/bin/env bash
set -euo pipefail

# Deploy Flutter web build to Hetzner VPS using staged releases + atomic cutover.
# Usage: ./scripts/deploy_web.sh [dev|staging|prod]

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$REPO_ROOT/origna_gta"
REMOTE_USER="${REMOTE_USER:-root}"
REMOTE_HOST="${REMOTE_HOST:-204.168.137.16}"
REMOTE_DIR="${REMOTE_DIR:-/var/www/orignagta}"
SSH_TARGET="${REMOTE_USER}@${REMOTE_HOST}"
ENV="${1:-dev}"
RELEASE_ID="${RELEASE_ID:-$(date -u +%Y%m%d%H%M%S)}"
REMOTE_RELEASES_DIR="$REMOTE_DIR/releases"
REMOTE_RELEASE_DIR="$REMOTE_RELEASES_DIR/$RELEASE_ID"
REMOTE_CURRENT_LINK="$REMOTE_DIR/current"

echo "=== Building Flutter web ($ENV) ==="
cd "$APP_DIR"
flutter build web --release --dart-define=ENVIRONMENT="$ENV"

echo "=== Preparing release $RELEASE_ID on $SSH_TARGET ==="
ssh "$SSH_TARGET" "mkdir -p '$REMOTE_RELEASES_DIR'"

rsync -avz --delete \
  "$APP_DIR/build/web/" \
  "$SSH_TARGET:$REMOTE_RELEASE_DIR/"

ssh "$SSH_TARGET" "
  set -euo pipefail
  test -f '$REMOTE_RELEASE_DIR/index.html'
  find '$REMOTE_RELEASE_DIR' -type d -exec chmod 755 {} \\;
  find '$REMOTE_RELEASE_DIR' -type f -exec chmod 644 {} \\;
  ln -sfn '$REMOTE_RELEASE_DIR' '$REMOTE_CURRENT_LINK.tmp'
  mv -Tf '$REMOTE_CURRENT_LINK.tmp' '$REMOTE_CURRENT_LINK'
  find '$REMOTE_RELEASES_DIR' -mindepth 1 -maxdepth 1 -type d | sort | head -n -5 | xargs -r rm -rf
"

echo "=== Deploy complete ==="
echo "Release: $RELEASE_ID"
echo "Live dir: $REMOTE_CURRENT_LINK"
echo "Site: https://www.orignagta.ca"
echo "API:  https://api.orignagta.ca"
