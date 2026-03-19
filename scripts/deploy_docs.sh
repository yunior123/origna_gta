#!/bin/bash

# OrignaGTA Docs Deployment Script
# Builds docs site and deploys to VPS at docs.orignagta.ca

set -e

DOCS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/docs-site"
REMOTE_HOST="root@204.168.137.16"
REMOTE_PATH="/var/www/orignagta/docs/current"

echo "📦 Building docs site..."
cd "$DOCS_DIR"
npm run build

if [ ! -d "out" ]; then
  echo "❌ Build failed: out/ directory not found"
  exit 1
fi

echo "🚀 Deploying to VPS (docs.orignagta.ca)..."
rsync -az --delete out/ "$REMOTE_HOST:$REMOTE_PATH/"

echo "✅ Deployment complete!"
echo "📖 Docs site live at: https://docs.orignagta.ca"
