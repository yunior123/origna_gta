#!/bin/bash
# Add docs subdomains to Cloudflare DNS
# Usage: CLOUDFLARE_API_TOKEN=xxx ./add-cloudflare-dns.sh

set -euo pipefail

TOKEN="${CLOUDFLARE_API_TOKEN:?Set CLOUDFLARE_API_TOKEN first}"

# Get zone ID for orignagta.ca
  "https://api.cloudflare.com/client/v4/zones?name=orignagta.ca" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['result'][0]['id'])")

echo "Zone ID: $ZONE_ID"

# Add docs.orignagta.ca
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "A",
    "name": "docs",
    "content": "204.168.137.16",
    "ttl": 1,
    "proxied": true
  }' | python3 -c "import sys,json; r=json.load(sys.stdin); print(f'docs.orignagta.ca: {\"OK\" if r[\"success\"] else r[\"errors\"]}')"

# Add mcp.docs.orignagta.ca
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "A",
    "name": "mcp.docs",
    "content": "204.168.137.16",
    "ttl": 1,
    "proxied": true
  }' | python3 -c "import sys,json; r=json.load(sys.stdin); print(f'mcp.docs.orignagta.ca: {\"OK\" if r[\"success\"] else r[\"errors\"]}')"

echo "Done! Both subdomains added with Cloudflare proxy."
