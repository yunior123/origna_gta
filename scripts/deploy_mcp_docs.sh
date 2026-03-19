#!/bin/bash
# Deploy MCP documentation site to VPS
# Usage: ./scripts/deploy_mcp_docs.sh [environment]
# Example: ./scripts/deploy_mcp_docs.sh dev

set -e

ENVIRONMENT="${1:-dev}"
VPS_HOST="204.168.137.16"
VPS_USER="root"
VPS_DOCS_DIR="/var/www/orignagta/mcp-docs"
LOCAL_DOCS_DIR="$(cd "$(dirname "$0")/.." && pwd)/mcp-docs"

if [ ! -d "$LOCAL_DOCS_DIR" ]; then
    echo "Error: MCP docs directory not found at $LOCAL_DOCS_DIR"
    exit 1
fi

echo "Deploying MCP documentation site to $ENVIRONMENT environment..."
echo "Host: $VPS_HOST"
echo "Source: $LOCAL_DOCS_DIR"
echo "Destination: $VPS_DOCS_DIR/$ENVIRONMENT/current"
echo ""

# Create destination directory on VPS if it doesn't exist
echo "Creating destination directory..."
ssh -i ~/.ssh/id_ed25519 "$VPS_USER@$VPS_HOST" "mkdir -p $VPS_DOCS_DIR/$ENVIRONMENT/current"

# Sync files with rsync
echo "Syncing files..."
rsync -az \
    --delete \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='.env' \
    --exclude='.DS_Store' \
    -e "ssh -i ~/.ssh/id_ed25519" \
    "$LOCAL_DOCS_DIR/" \
    "$VPS_USER@$VPS_HOST:$VPS_DOCS_DIR/$ENVIRONMENT/current/"

echo ""
echo "✓ Deployment complete!"
echo ""
echo "Access the documentation at:"
case "$ENVIRONMENT" in
    dev)
        echo "  https://mcp.docs.dev.orignagta.ca"
        ;;
    staging)
        echo "  https://mcp.docs.staging.orignagta.ca"
        ;;
    prod)
        echo "  https://mcp.docs.orignagta.ca"
        ;;
    *)
        echo "  https://mcp.docs.$ENVIRONMENT.orignagta.ca"
        ;;
esac

echo ""
echo "Caddy configuration: /etc/caddy/Caddyfile"
echo "Reload Caddy: caddy reload --config /etc/caddy/Caddyfile"
