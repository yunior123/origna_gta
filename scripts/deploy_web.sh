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

case "$ENV" in
  dev)
    ORIGNABASE_URL="https://api.dev.orignagta.ca"
    WEB_APP_URL="https://dev.orignagta.ca"
    TURNSTILE_KEY="1x00000000000000000000AA"
    BUILD_MODE="--profile"
    EXTRA_DART_DEFINES=(--dart-define=FORCE_SEMANTICS=true)
    ;;
  staging)
    ORIGNABASE_URL="https://api.staging.orignagta.ca"
    WEB_APP_URL="https://staging.orignagta.ca"
    TURNSTILE_KEY="0x4AAAAAACmRNCDQqc20J_1T"
    BUILD_MODE="--profile"
    EXTRA_DART_DEFINES=(--dart-define=FORCE_SEMANTICS=true)
    ;;
  production)
    ORIGNABASE_URL="https://api.orignagta.ca"
    WEB_APP_URL="https://orignagta.ca"
    TURNSTILE_KEY="0x4AAAAAACmRNXgZQ1M928iq"
    BUILD_MODE="--release"
  EXTRA_DART_DEFINES=()
  ;;
esac

GOOGLE_WEB_CLIENT_ID_VALUE="${GOOGLE_WEB_CLIENT_ID:-}"
if [ -z "${GOOGLE_WEB_CLIENT_ID_VALUE}" ] && [ "${ALLOW_PLACEHOLDER_GOOGLE_WEB_CLIENT_ID:-0}" != "1" ]; then
  echo "Error: GOOGLE_WEB_CLIENT_ID must be set for web deploys."
  echo "Set ALLOW_PLACEHOLDER_GOOGLE_WEB_CLIENT_ID=1 only for intentionally local/non-OAuth builds."
  exit 1
fi

if [ -z "${GOOGLE_WEB_CLIENT_ID_VALUE}" ]; then
  GOOGLE_WEB_CLIENT_ID_VALUE="__GOOGLE_WEB_CLIENT_ID__"
fi

cd origna_gta
if [ ${#EXTRA_DART_DEFINES[@]} -gt 0 ]; then
  flutter build web ${BUILD_MODE} \
    --dart-define=ENVIRONMENT=${ENV} \
    --dart-define=ORIGNABASE_URL=${ORIGNABASE_URL} \
    "${EXTRA_DART_DEFINES[@]}" \
    --pwa-strategy=none \
    --no-tree-shake-icons
else
flutter build web ${BUILD_MODE} \
--dart-define=ENVIRONMENT=${ENV} \
--dart-define=ORIGNABASE_URL=${ORIGNABASE_URL} \
--pwa-strategy=none \
--no-tree-shake-icons
fi

# Inject Google Sign-In web client ID
sed -i '' "s|__GOOGLE_WEB_CLIENT_ID__|${GOOGLE_WEB_CLIENT_ID_VALUE}|g" build/web/index.html 2>/dev/null || true
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

if [ "${SKIP_SCROLL_REGRESSION_CHECK:-0}" != "1" ]; then
  echo "Running post-deploy scroll/cart regression checks..."
  (
    cd e2e
    bun x tsc --noEmit
    E2E_TARGET_URL="${WEB_APP_URL}" ORIGNABASE_URL="${ORIGNABASE_URL}" bun test specs/phase1-api/dev-product-browse-live.spec.ts
    E2E_TARGET_URL="${WEB_APP_URL}" ORIGNABASE_URL="${ORIGNABASE_URL}" bun test specs/phase4-product-flows/search-filters-sort.spec.ts
    E2E_TARGET_URL="${WEB_APP_URL}" ORIGNABASE_URL="${ORIGNABASE_URL}" bun test specs/phase4-product-flows/subcategory-filtering.spec.ts
    E2E_TARGET_URL="${WEB_APP_URL}" ORIGNABASE_URL="${ORIGNABASE_URL}" bun test specs/phase5-complex-flows/cart-badge-add-to-cart.spec.ts
  )
fi

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
