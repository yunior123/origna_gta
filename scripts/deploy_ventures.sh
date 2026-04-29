#!/bin/bash
set -euo pipefail

ENV="${1:-production}"
if [ -z "${VPS_HOST:-}" ]; then
  echo "Error: VPS_HOST must be set e.g. VPS_HOST=user@ip"
  echo "Usage: VPS_HOST=user@your-vps-ip $0 [production]"
  exit 1
fi

TIMESTAMP=$(date +%Y%m%d%H%M%S)
REMOTE_BASE="/var/www/orignaventures/${ENV}"
RELEASE_DIR="${REMOTE_BASE}/releases/${TIMESTAMP}"
CURRENT_LINK="${REMOTE_BASE}/current"

echo "Deploying OrignaVentures web for ${ENV} to ${VPS_HOST} with release ${TIMESTAMP}"

cd origna_ventures
flutter build web --release --no-tree-shake-icons
cd ..

ssh "${VPS_HOST}" "mkdir -p ${REMOTE_BASE}/releases && chmod -R 755 ${REMOTE_BASE}"

rsync -avz --delete origna_ventures/build/web/ "${VPS_HOST}:${RELEASE_DIR}/"

ssh "${VPS_HOST}" "
  if [ -d ${CURRENT_LINK} ] && [ ! -L ${CURRENT_LINK} ]; then
    mv ${CURRENT_LINK} ${CURRENT_LINK}.directory-backup-${TIMESTAMP}
  fi
  ln -sfnT ${RELEASE_DIR} ${CURRENT_LINK}
  echo 'Deployed release ${TIMESTAMP}'
  ls -l ${CURRENT_LINK}
  echo 'Current symlink updated.'
"

echo "Successfully deployed OrignaVentures to VPS for ${ENV}. Release: ${TIMESTAMP}"
