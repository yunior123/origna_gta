#!/usr/bin/env bash
# local-dev.sh — Start all local dev services and verify health
# Usage: ./scripts/local-dev.sh [--stripe] [--seed] [--stop]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOCKER_DIR="$PROJECT_ROOT/docker"
STRIPE_CLI="/opt/homebrew/bin/stripe"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[local-dev]${NC} $*"; }
warn() { echo -e "${YELLOW}[local-dev]${NC} $*"; }
err()  { echo -e "${RED}[local-dev]${NC} $*" >&2; }

# --- Parse args ---
ENABLE_STRIPE=false
ENABLE_SEED=false
STOP_MODE=false

for arg in "$@"; do
  case "$arg" in
    --stripe) ENABLE_STRIPE=true ;;
    --seed)   ENABLE_SEED=true ;;
    --stop)   STOP_MODE=true ;;
    --help|-h)
      echo "Usage: $0 [--stripe] [--seed] [--stop]"
      echo ""
      echo "  --stripe  Start Stripe CLI webhook forwarding"
      echo "  --seed    Run seed script after services are healthy"
      echo "  --stop    Stop all local services and exit"
      echo ""
      echo "Services started:"
      echo "  SurrealDB    → localhost:8000"
      echo "  Meilisearch  → localhost:7700"
      echo "  OrignaBase   → localhost:8080"
      echo "  Caddy        → localhost:80/443"
      echo "  ChromaDB     → localhost:8100 (if image exists)"
      echo "  Stripe CLI   → forwards webhooks to localhost:8080 (with --stripe)"
      exit 0
      ;;
  esac
done

# --- Stop mode ---
if $STOP_MODE; then
  log "Stopping all local services..."
  cd "$DOCKER_DIR"
  docker compose down 2>/dev/null || true
  docker stop chromadb 2>/dev/null || true
  pkill -f "stripe listen" 2>/dev/null || true
  log "All services stopped."
  exit 0
fi

# --- Preflight checks ---
log "Preflight checks..."

# Check colima/Docker
if ! docker info >/dev/null 2>&1; then
  warn "Docker not running. Starting colima..."
  colima start 2>&1 | tail -3
fi

# Check .env exists
if [[ ! -f "$DOCKER_DIR/.env" ]]; then
  if [[ -f "$DOCKER_DIR/.env.dev" ]]; then
    log "Copying .env.dev → .env"
    cp "$DOCKER_DIR/.env.dev" "$DOCKER_DIR/.env"
  else
    err "No .env file found in $DOCKER_DIR"
    err "Create one from .env.local.example: cp docker/.env.local.example docker/.env"
    exit 1
  fi
fi

# --- Start Docker services ---
log "Starting Docker services..."
cd "$DOCKER_DIR"
docker compose up -d

# --- Wait for health ---
wait_for_health() {
  local name="$1" url="$2" max_wait="${3:-60}"
  local elapsed=0
  while ! curl -sf "$url" >/dev/null 2>&1; do
    sleep 2
    elapsed=$((elapsed + 2))
    if [[ $elapsed -ge $max_wait ]]; then
      err "$name failed to become healthy after ${max_wait}s"
      return 1
    fi
  done
  log "$name healthy (${elapsed}s)"
}

log "Waiting for services to become healthy..."
wait_for_health "SurrealDB"   "http://localhost:8000/health" 60
wait_for_health "Meilisearch" "http://localhost:7700/health" 60
wait_for_health "OrignaBase"  "http://localhost:8080/health" 90

# --- ChromaDB (optional — only if image exists) ---
if docker image inspect chromadb/chroma:latest >/dev/null 2>&1; then
  if ! docker ps --format '{{.Names}}' | grep -q chromadb; then
    log "Starting ChromaDB..."
    docker run -d --name chromadb -p 8100:8000 chromadb/chroma:latest 2>/dev/null || true
    wait_for_health "ChromaDB" "http://localhost:8100/api/v2/heartbeat" 30 || warn "ChromaDB failed to start (non-fatal)"
  else
    log "ChromaDB already running"
  fi
fi

# --- Stripe CLI (optional) ---
if $ENABLE_STRIPE; then
  if [[ ! -x "$STRIPE_CLI" ]]; then
    err "Stripe CLI not found at $STRIPE_CLI"
    err "Install: brew install stripe/stripe-cli/stripe"
  else
    # Check if already listening
    if pgrep -f "stripe listen" >/dev/null 2>&1; then
      warn "Stripe CLI already listening"
    else
      log "Starting Stripe CLI webhook forwarding..."
      "$STRIPE_CLI" listen \
        --forward-to localhost:8080/api/webhooks/stripe \
        --log-level warn \
        2>&1 | while IFS= read -r line; do
          # Capture and display the webhook signing secret
          if echo "$line" | grep -q "whsec_"; then
            WHSEC=$(echo "$line" | grep -oE 'whsec_[a-zA-Z0-9]+')
            echo ""
            echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
            echo -e "${YELLOW}  Stripe webhook signing secret:${NC}"
            echo -e "${GREEN}  $WHSEC${NC}"
            echo -e "${YELLOW}  Add to .env: OB_SECRETS__STRIPE_WEBHOOK_SECRET=$WHSEC${NC}"
            echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
            echo ""
          fi
          echo "$line"
        done &
      sleep 3
      log "Stripe CLI forwarding webhooks → localhost:8080"
    fi
  fi
fi

# --- Seed (optional) ---
if $ENABLE_SEED; then
  SEED_SCRIPT="$PROJECT_ROOT/scripts/seed_orignabase.py"
  if [[ -f "$SEED_SCRIPT" ]]; then
    log "Seeding dev database..."
    python3 "$SEED_SCRIPT" --url http://localhost:8080 2>&1 | tail -5
    log "Seed complete"
  else
    warn "Seed script not found: $SEED_SCRIPT"
  fi
fi

# --- Summary ---
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Local dev environment ready!${NC}"
echo ""
echo "  SurrealDB    http://localhost:8000"
echo "  Meilisearch  http://localhost:7700"
echo "  OrignaBase   http://localhost:8080"
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q chromadb; then
  echo "  ChromaDB     http://localhost:8100"
fi
if pgrep -f "stripe listen" >/dev/null 2>&1; then
  echo "  Stripe CLI   forwarding → localhost:8080"
fi
echo ""
echo "  Flutter:  cd origna_gta && flutter run --dart-define=ENVIRONMENT=emulator"
echo "  Tests:    flutter test --dart-define=RUN_ORIGNABASE_LIVE_TESTS=true --dart-define=ENVIRONMENT=emulator"
echo "  Rust:     OB_TEST_URL=http://localhost:8080 cargo test -- --ignored"
echo "  Stop:     $0 --stop"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
