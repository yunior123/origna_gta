#!/bin/bash
set -euo pipefail

ENV="${1:-production}"
if [ -z "${VPS_HOST:-}" ]; then
  echo "Error: VPS_HOST must be set e.g. VPS_HOST=user@ip"
  echo "Usage: VPS_HOST=user@your-vps-ip $0 [dev|staging|production]"
  exit 1
fi

if [[ ! "$ENV" =~ ^(dev|staging|production)$ ]]; then
  echo "Error: Invalid environment. Must be dev, staging or production."
  exit 1
fi

TIMESTAMP=$(date +%Y%m%d%H%M%S)
REMOTE_BASE="/var/www/orignagta/${ENV}"
RELEASE_DIR="${REMOTE_BASE}/releases/${TIMESTAMP}"
CURRENT_LINK="${REMOTE_BASE}/current"

echo "Deploying web for ${ENV} to ${VPS_HOST} with release ${TIMESTAMP}"

ORIGNABASE_URL="https://api.orignagta.ca"
case "$ENV" in
  dev)        TURNSTILE_KEY="1x00000000000000000000AA" ;;
  staging)    TURNSTILE_KEY="0x4AAAAAACmRNCDQqc20J_1T" ;;
  production) TURNSTILE_KEY="0x4AAAAAACmRNXgZQ1M928iq" ;;
esac

cd origna_gta
flutter build web --release \
  --dart-define=ENVIRONMENT=${ENV} \
  --dart-define=ORIGNABASE_URL=${ORIGNABASE_URL} \
  --pwa-strategy=none \
  --no-tree-shake-icons

# Inject Turnstile site key
sed -i '' "s|__TURNSTILE_SITE_KEY__|${TURNSTILE_KEY}|g" build/web/index.html 2>/dev/null || true
cd ..

ssh "${VPS_HOST}" "mkdir -p ${REMOTE_BASE}/releases && chmod -R 755 ${REMOTE_BASE}"

rsync -avz --delete origna_gta/build/web/ "${VPS_HOST}:${RELEASE_DIR}/"

ssh "${VPS_HOST}" "
  ln -sfn ${RELEASE_DIR} ${CURRENT_LINK}
  echo 'Deployed release ${TIMESTAMP}'
  ls -l ${CURRENT_LINK}
  echo 'Current symlink updated.'
"

echo "Successfully deployed to VPS for ${ENV}. Release: ${TIMESTAMP}"
echo "Current link: ${CURRENT_LINK}"

# ── WebP on Cloudflare R2 ──────────────────────────────────────────────────
# Product images are stored in Cloudflare R2. To enable WebP format:
# 1. Cloudflare R2 serves images as-is — upload WebP variants alongside
#    originals (e.g., product_abc.webp next to product_abc.jpg).
# 2. Use Cloudflare Image Transformations (paid add-on) for automatic WebP
#    conversion via ?format=webp query param or Accept header negotiation.
# 3. Alternatively, convert images to WebP at upload time in OrignaBase
#    using the `image` crate (Rust) before pushing to R2.
# 4. In Flutter, CachedNetworkImage handles any image format transparently.
# ────────────────────────────────────────────────────────────────────────────
