#!/usr/bin/env bash
set -euo pipefail

VPS_HOST="${VPS_HOST:-root@204.168.137.16}"
VPS_DIR="/opt/origna_ventures"
LOCAL_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Origna Ventures Backend Deploy ==="
echo "Target: ${VPS_HOST}:${VPS_DIR}"

echo "[1/5] Validating local syntax..."
python3 -c "import py_compile; py_compile.compile('${LOCAL_DIR}/app.py', doraise=True)"
echo "  OK"

echo "[2/5] Syncing backend source to VPS..."
ssh "${VPS_HOST}" "mkdir -p ${VPS_DIR}/backend/data/storage"
rsync -az --delete \
  --exclude '__pycache__' \
  --exclude '*.pyc' \
  --exclude '.venv' \
  --exclude 'data/' \
  --exclude '.env' \
  "${LOCAL_DIR}/" "${VPS_HOST}:${VPS_DIR}/backend/"

echo "[3/5] Ensuring .env exists on VPS..."
ssh "${VPS_HOST}" "test -f ${VPS_DIR}/backend/.env || cp ${VPS_DIR}/backend/.env.example ${VPS_DIR}/backend/.env && echo '  .env present'"

echo "[4/5] Rebuilding and restarting container on VPS..."
ssh "${VPS_HOST}" bash -s <<REMOTE_SCRIPT
set -euo pipefail
cd ${VPS_DIR}/backend

# Stop old container if running (from manual docker run, not compose)
OLD_ID=\$(docker ps -q --filter name=origna-ventures-api 2>/dev/null || true)
if [ -n "\$OLD_ID" ]; then
  echo "  Stopping old container: \$OLD_ID"
  docker stop "\$OLD_ID" || true
  docker rm "\$OLD_ID" || true
fi

# Build and start with docker compose
docker compose up -d --build

echo "  Waiting for health check..."
for i in \$(seq 1 12); do
  if curl -sf http://localhost:8083/health > /dev/null 2>&1; then
    echo "  Health: OK"
    break
  fi
  if [ "\$i" -eq 12 ]; then
    echo "  Health: FAILED (timeout)"
    docker compose logs --tail=30
    exit 1
  fi
  sleep 5
done

# Verify external access via Caddy
sleep 3
EXTERNAL=\$(curl -sf https://api.orignagta.ca/ventures/health 2>/dev/null || echo "failed")
echo "  External health: \${EXTERNAL}"
REMOTE_SCRIPT

echo "[5/5] Cleanup old Docker images..."
ssh "${VPS_HOST}" "docker image prune -f 2>/dev/null || true"

echo "=== Deploy complete ==="
