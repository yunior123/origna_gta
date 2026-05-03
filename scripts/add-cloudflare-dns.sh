#!/bin/bash
# Enable Cloudflare proxy (DDoS protection) for all Origna domains
# Usage: CLOUDFLARE_API_TOKEN=xxx ./add-cloudflare-dns.sh [--ventures-only] [--gta-only]

set -euo pipefail

TOKEN="${CLOUDFLARE_API_TOKEN:?Set CLOUDFLARE_API_TOKEN first}"
VPS_IP="${VPS_IP:-204.168.137.16}"
MODE="${1:---all}"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

ok() { echo -e "${GREEN}✓ $1${NC}"; }
fail() { echo -e "${RED}✗ $1${NC}"; exit 1; }

require_cf_success() {
    local context="$1"
    python3 -c '
import json
import sys

context = sys.argv[1]
try:
    data = json.load(sys.stdin)
except json.JSONDecodeError as exc:
    print(f"{context}: invalid Cloudflare JSON response: {exc}", file=sys.stderr)
    sys.exit(1)

if not data.get("success", False):
    errors = data.get("errors") or []
    messages = []
    for error in errors:
        code = error.get("code")
        message = error.get("message", "unknown error")
        messages.append(f"{code}: {message}" if code else message)
    print(f"{context}: {'; '.join(messages) or 'Cloudflare request failed'}", file=sys.stderr)
    sys.exit(1)

json.dump(data, sys.stdout)
' "$context"
}

verify_token() {
    local response
        "https://api.cloudflare.com/client/v4/user/tokens/verify")
    echo "$response" | require_cf_success "Cloudflare token verification" >/dev/null
}

# Upsert a DNS record: create if missing, update if exists with different content/proxied
upsert_record() {
    local zone_id="$1" zone_name="$2" name="$3" rtype="$4" content="$5" proxied="$6"

    local fqdn="${name}.${zone_name}"
    [ "$name" = "@" ] && fqdn="$zone_name"

    local existing
        "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?name=$fqdn&type=$rtype" \
        | require_cf_success "Lookup $fqdn")

    local record_id
    record_id=$(echo "$existing" | python3 -c "
import sys, json
data = json.load(sys.stdin)
results = data.get('result', [])
if results:
    print(results[0]['id'])
else:
    print('')
" 2>/dev/null)

    if [ -n "$record_id" ]; then
        local current_proxied
        current_proxied=$(echo "$existing" | python3 -c "
import sys, json
print(str(json.load(sys.stdin)['result'][0].get('proxied', False)).lower())
" 2>/dev/null)
        local current_content
        current_content=$(echo "$existing" | python3 -c "
import sys, json
print(json.load(sys.stdin)['result'][0].get('content', ''))
" 2>/dev/null)

        if [ "$current_proxied" = "$proxied" ] && [ "$current_content" = "$content" ]; then
            ok "$fqdn already correct (proxied=$proxied, $content)"
            return 0
        fi

        curl -sS -X PATCH "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$record_id" \
            -H "Content-Type: application/json" \
            --data "{\"content\":\"$content\",\"proxied\":$proxied}" \
            | require_cf_success "Update $fqdn" \
            | python3 -c "
import sys, json
r = json.load(sys.stdin)
print(f'  $fqdn: {\"OK\" if r[\"success\"] else r[\"errors\"]}')" 2>/dev/null
        ok "$fqdn updated → proxied=$proxied"
    else
        curl -sS -X POST "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"$rtype\",\"name\":\"$name\",\"content\":\"$content\",\"ttl\":1,\"proxied\":$proxied}" \
            | require_cf_success "Create $fqdn" \
            | python3 -c "
import sys, json
r = json.load(sys.stdin)
print(f'  $fqdn: {\"OK\" if r[\"success\"] else r[\"errors\"]}')" 2>/dev/null
        ok "$fqdn created → proxied=$proxied"
    fi
}

# ── OrignaGTA zone ──────────────────────────────────────────────────────────────

if [ "$MODE" = "--all" ] || [ "$MODE" = "--gta-only" ]; then
    echo -e "${BLUE}▶ Setting up orignagta.ca zone...${NC}"
    verify_token
        "https://api.cloudflare.com/client/v4/zones?name=orignagta.ca" \
        | require_cf_success "Lookup orignagta.ca zone" \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['result'][0]['id'])")
    echo "  Zone ID: $GTA_ZONE"

    upsert_record "$GTA_ZONE" "orignagta.ca" "@" "A" "$VPS_IP" "true"
    upsert_record "$GTA_ZONE" "orignagta.ca" "www" "A" "$VPS_IP" "true"
    upsert_record "$GTA_ZONE" "orignagta.ca" "api" "A" "$VPS_IP" "true"
    upsert_record "$GTA_ZONE" "orignagta.ca" "dev" "A" "$VPS_IP" "true"
    upsert_record "$GTA_ZONE" "orignagta.ca" "staging" "A" "$VPS_IP" "true"
    upsert_record "$GTA_ZONE" "orignagta.ca" "docs" "A" "$VPS_IP" "true"
    upsert_record "$GTA_ZONE" "orignagta.ca" "mcp.docs" "A" "$VPS_IP" "true"
    upsert_record "$GTA_ZONE" "orignagta.ca" "signatures" "A" "$VPS_IP" "true"
    # Cloudflare Universal SSL covers *.orignagta.ca, not nested *.dev.orignagta.ca.
    upsert_record "$GTA_ZONE" "orignagta.ca" "signatures.dev" "A" "$VPS_IP" "false"
    upsert_record "$GTA_ZONE" "orignagta.ca" "signatures.staging" "A" "$VPS_IP" "false"
fi

# ── OrignaVentures zone ─────────────────────────────────────────────────────────

if [ "$MODE" = "--all" ] || [ "$MODE" = "--ventures-only" ]; then
    echo -e "${BLUE}▶ Setting up orignaventures.ca zone...${NC}"
    verify_token
        "https://api.cloudflare.com/client/v4/zones?name=orignaventures.ca" \
        | require_cf_success "Lookup orignaventures.ca zone" \
        | python3 -c "import sys,json; zones=json.load(sys.stdin)['result']; print(zones[0]['id'] if zones else '')" 2>/dev/null || echo "")

    if [ -z "$VENTURES_ZONE" ]; then
        echo -e "${RED}⚠ orignaventures.ca zone not found in Cloudflare. Create it first:${NC}"
        echo "  1. Log into Cloudflare dashboard"
        echo "  2. Add site orignaventures.ca"
        echo "  3. Select Free plan"
        echo "  4. Re-run this script with --ventures-only"
    else
        echo "  Zone ID: $VENTURES_ZONE"
        upsert_record "$VENTURES_ZONE" "orignaventures.ca" "@" "A" "$VPS_IP" "true"
        upsert_record "$VENTURES_ZONE" "orignaventures.ca" "www" "A" "$VPS_IP" "true"
        upsert_record "$VENTURES_ZONE" "orignaventures.ca" "api" "A" "$VPS_IP" "true"
    fi
fi

echo ""
echo -e "${GREEN}Done! Cloudflare proxy (DDoS protection) enabled for all domains.${NC}"
echo -e "  Note: SSL/TLS mode must be 'Full (strict)' in Cloudflare dashboard."
echo -e "  Note: Caddy already has Let's Encrypt certs — CF will validate origin."
