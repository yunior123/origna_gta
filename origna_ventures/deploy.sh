#!/bin/bash
# Deploy OrignaVentures Flutter web + backend to Hetzner VPS
# Usage: ./deploy.sh [--skip-build] [--backend-only] [--frontend-only]
# VPS: root@204.168.137.16
# Frontend: Caddy at /var/www/orignaventures/production/current
# Backend: Docker container origna-ventures-api at api.orignaventures.ca

set -e

VPS="root@204.168.137.16"
VPS_WEB_DIR="/var/www/orignaventures/production/current"
VPS_BACKEND_DIR="/opt/origna_ventures/backend"
SSH_KEY="$HOME/.ssh/id_ed25519"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}▶ $1${NC}"; }
ok() { echo -e "${GREEN}✓ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
fail() { echo -e "${RED}✗ $1${NC}"; exit 1; }

SKIP_BUILD=false
BACKEND_ONLY=false
FRONTEND_ONLY=false
for arg in "$@"; do
  case "$arg" in
    --skip-build) SKIP_BUILD=true ;;
    --backend-only) BACKEND_ONLY=true ;;
    --frontend-only) FRONTEND_ONLY=true ;;
  esac
done

command -v rsync &>/dev/null || fail "rsync not found"
[ -f "$SSH_KEY" ] || fail "SSH key not found at $SSH_KEY"

# ── Frontend ──────────────────────────────────────────────────────────────────
if [[ "$BACKEND_ONLY" != true ]]; then
  cd "$SCRIPT_DIR"
  if [[ "$SKIP_BUILD" != true ]]; then
    command -v flutter &>/dev/null || fail "Flutter not found"
    log "Building Flutter web (release)..."
    flutter pub get
    flutter build web --release \
      --dart-define=ENVIRONMENT=production
    ok "Build complete → build/web/"
  else
    warn "Skipping build (--skip-build)"
  fi
  [ -d "build/web" ] || fail "build/web not found — run without --skip-build"

  log "Deploying frontend to Hetzner VPS ($VPS)..."
  ssh -i "$SSH_KEY" "$VPS" "mkdir -p $VPS_WEB_DIR"
  rsync -az --delete --progress \
    -e "ssh -i $SSH_KEY" \
    build/web/ \
    "$VPS:$VPS_WEB_DIR/"
  ok "Frontend synced to $VPS_WEB_DIR"
fi

# ── Backend ───────────────────────────────────────────────────────────────────
if [[ "$FRONTEND_ONLY" != true ]]; then
  log "Deploying backend to Hetzner VPS ($VPS)..."
  ssh -i "$SSH_KEY" "$VPS" "mkdir -p $VPS_BACKEND_DIR/data/storage"

  rsync -az --progress \
    -e "ssh -i $SSH_KEY" \
    "$SCRIPT_DIR/backend/" \
    "$VPS:$VPS_BACKEND_DIR/" \
    --exclude '__pycache__' \
    --exclude '.pytest_cache' \
    --exclude '.venv' \
    --exclude 'venv' \
    --exclude '.env' \
    --exclude 'data' \
    --exclude '.git'

  log "Rebuilding origna-ventures-api container..."
  ssh -i "$SSH_KEY" "$VPS" bash -s <<'REMOTE'
set -e
cd /opt/origna_ventures/backend
docker compose build origna-ventures-api 2>/dev/null || \
  docker-compose build origna-ventures-api 2>/dev/null
docker compose up -d origna-ventures-api 2>/dev/null || \
  docker-compose up -d origna-ventures-api 2>/dev/null
echo "Waiting for healthcheck..."
sleep 5
python3 - <<'PY'
import urllib.request
print(urllib.request.urlopen('http://127.0.0.1:8083/api/health').read().decode())
PY
REMOTE
  ok "Backend deployed to $VPS_BACKEND_DIR"
fi

# ── Reload Caddy if needed ────────────────────────────────────────────────────
if [[ "$FRONTEND_ONLY" != true ]]; then
  log "Reloading Caddy..."
  ssh -i "$SSH_KEY" "$VPS" \
    "docker exec caddy caddy reload --config /etc/caddy/Caddyfile 2>/dev/null || true"
  ok "Caddy reloaded"
fi

# ── Verify ────────────────────────────────────────────────────────────────────
log "Verifying deployment..."
DEPLOYED_FILES=$(ssh -i "$SSH_KEY" "$VPS" "ls $VPS_WEB_DIR | wc -l" 2>/dev/null || echo "?")
ok "Deployed $DEPLOYED_FILES frontend files"

echo ""
echo -e "${GREEN}OrignaVentures deployed!${NC}"
echo -e "  Frontend:  ${BLUE}https://orignaventures.ca${NC}"
echo -e "  Backend:   ${BLUE}https://api.orignaventures.ca${NC}"
echo -e "  Health:    ${BLUE}https://api.orignaventures.ca/api/health${NC}"
