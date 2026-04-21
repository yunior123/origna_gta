#!/bin/bash
# Deploy OrignaVentures Flutter web to Hetzner VPS
# Usage: ./deploy.sh [--skip-build]
# VPS: root@204.168.137.16 | Served by Caddy at /var/www/orignaventures/production/current

set -e

VPS="root@204.168.137.16"
VPS_DIR="/var/www/orignaventures/production/current"
SSH_KEY="$HOME/.ssh/id_ed25519"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${BLUE}▶ $1${NC}"; }
ok()   { echo -e "${GREEN}✓ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
fail() { echo -e "${RED}✗ $1${NC}"; exit 1; }

# ── Pre-flight ────────────────────────────────────────────────────────────────
command -v flutter &>/dev/null || fail "Flutter not found"
command -v rsync   &>/dev/null || fail "rsync not found"
[ -f "$SSH_KEY" ]              || fail "SSH key not found at $SSH_KEY"

cd "$SCRIPT_DIR"

# ── Build ─────────────────────────────────────────────────────────────────────
if [[ "$1" != "--skip-build" ]]; then
  log "Building Flutter web (release)..."
  flutter pub get
  flutter build web --release \
    --dart-define=ENVIRONMENT=production
  ok "Build complete → build/web/"
else
  warn "Skipping build (--skip-build)"
fi

[ -d "build/web" ] || fail "build/web not found — run without --skip-build"

# ── Deploy ────────────────────────────────────────────────────────────────────
log "Deploying to Hetzner VPS ($VPS)..."
ssh -i "$SSH_KEY" "$VPS" "mkdir -p $VPS_DIR"
rsync -az --delete --progress \
  -e "ssh -i $SSH_KEY" \
  build/web/ \
  "$VPS:$VPS_DIR/"
ok "Files synced to $VPS_DIR"

# ── Verify ────────────────────────────────────────────────────────────────────
log "Verifying deployment..."
DEPLOYED_FILES=$(ssh -i "$SSH_KEY" "$VPS" "ls $VPS_DIR | wc -l")
ok "Deployed $DEPLOYED_FILES files"

echo ""
echo -e "${GREEN}🎉 OrignaVentures deployed!${NC}"
echo -e "   Live at: ${BLUE}https://orignaventures.ca${NC}"
echo -e "   Check Cloudflare DNS: orignaventures.ca A → 204.168.137.16 (proxied=false)"
