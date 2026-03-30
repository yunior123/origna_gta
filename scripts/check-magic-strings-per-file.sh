#!/bin/bash
# PostToolUse hook: detect magic strings per-file after Edit/Write.
# Exit 0 = warning only. Never blocks.
#
# Detects multiple patterns:
#   1. json!({}) bare keys: json!({"status": x}) → json!({fields::STATUS: x})
#   2. .get("field") lookups: .get("sellerId") → .get(fields::SELLER_ID)
#   3. ["field"] index access: doc["status"] → doc[fields::STATUS]
#   4. format! with field names: format!("...{}...", "sellerId") → fields::SELLER_ID
#   5. Dart map keys: {"status": x} → {Fields.status: x}
#   6. Bare collection names: "orders" → collections::ORDERS

FILE=$(echo "$TOOL_INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('file_path',''))" 2>/dev/null)

[ -z "$FILE" ] || [ ! -f "$FILE" ] && exit 0
echo "$FILE" | grep -qE '\.(rs|dart)$' || exit 0

# Skip definition files, tests, snapshots
echo "$FILE" | grep -qE '(schema_constants\.dart|schema\.rs|constants\.rs|_test\.dart|test_.*\.dart|snapshots/|\.snap$)' && exit 0

BASENAME=$(basename "$FILE")
IS_RUST=false
IS_DART=false
echo "$FILE" | grep -q '\.rs$' && IS_RUST=true
echo "$FILE" | grep -q '\.dart$' && IS_DART=true

# ── Shared field names (both Rust and Dart) ──────────────────────────────
FIELDS='status|orderStatus|paymentStatus|sellerId|buyerId|productId|orderId|userId|createdAt|updatedAt|items|priceCents|quantity|isDigital|stockQuantity|lifecycleStatus|trackingNumber|shippedAt|deliveredAt|cancelledAt|isPerishable|apartment|phoneNumber|warehouseIds|parent_id|token|topic|created_at|updated_at|delivered_at|buyer_id|seller_id|product_id|order_id|user_id|payment_intent_id|stripe_session_id|coupon_code|discount_type|discount_value|min_order_cents|max_uses_total|is_active|expires_at|return_status|refund_amount_cents|refund_reason|license_key|device_id|platform|is_default|postal_code|latitude|longitude|street|city|country|roles|email|name|description|price|weight|category|subcategory|keywords|images|variants|variantId|variantKey|sku|isDefault|notifiedAt|sentAt|attempts|resolved|archived|confirmedByClient|autoConfirmed|suspendReason|disputeId|chargeId|reason|currency|message|body|title|data|type|timestamp|processed'

# ── Exclusion filter (same for all patterns) ─────────────────────────────
exclude_filter() {
    grep -v 'fields::' \
    | grep -v 'Fields\.' \
    | grep -v 'SchemaConstants\.' \
    | grep -v 'collections::' \
    | grep -v 'Collections\.' \
    | grep -v '// ignore-magic' \
    | grep -v '#\[serde' \
    | grep -v 'pub const ' \
    | grep -v 'static const ' \
    | grep -v '/// ' \
    | grep -v '^[[:space:]]*//' \
    | grep -v 'mod tests' \
    | grep -v '#\[cfg(test)\]' \
    | grep -v 'impl.*for' \
    | grep -v 'fn .*(' \
    | grep -v 'struct ' \
    | grep -v 'enum '
}

ALL_HITS=""

# ── Pattern 1: json!({}) bare keys (Rust) ────────────────────────────────
# Matches: json!({"fieldName": value}) or json!({  "fieldName" : value })
if $IS_RUST; then
    P1=$(grep -nE "\"($FIELDS)\"[[:space:]]*:" "$FILE" 2>/dev/null | exclude_filter | head -5)
    [ -n "$P1" ] && ALL_HITS="${ALL_HITS}  [json! key] ────\n${P1}\n"
fi

# ── Pattern 2: .get("field") lookups (Rust) ──────────────────────────────
# Matches: .get("sellerId"), .get("status"), doc["items"]
if $IS_RUST; then
    P2=$(grep -nE '\.get\("('"$FIELDS"')"\)' "$FILE" 2>/dev/null | exclude_filter | head -5)
    [ -n "$P2" ] && ALL_HITS="${ALL_HITS}  [.get()] ────\n${P2}\n"
fi

# ── Pattern 3: ["field"] index access (Rust) ─────────────────────────────
# Matches: doc["status"], item["priceCents"], order["items"]
if $IS_RUST; then
    P3=$(grep -nE '\["('"$FIELDS"')"\]' "$FILE" 2>/dev/null | exclude_filter | head -5)
    [ -n "$P3" ] && ALL_HITS="${ALL_HITS}  [index[]] ────\n${P3}\n"
fi

# ── Pattern 4: data->>'field' in format! (Rust) ─────────────────────────
# OK pattern — but if the field name is a literal instead of fields::CONST, flag it
if $IS_RUST; then
    P4=$(grep -nE "data->>'($FIELDS)'" "$FILE" 2>/dev/null | exclude_filter | grep -v 'format!.*fields::' | head -3)
    [ -n "$P4" ] && ALL_HITS="${ALL_HITS}  [data->>] ────\n${P4}\n"
fi

# ── Pattern 5: Dart map literal keys ─────────────────────────────────────
# Matches: {'status': value}, {"sellerId": value} in Dart
if $IS_DART; then
    P5=$(grep -nE "['\"]($FIELDS)['\"][[:space:]]*:" "$FILE" 2>/dev/null | exclude_filter | head -5)
    [ -n "$P5" ] && ALL_HITS="${ALL_HITS}  [map key] ────\n${P5}\n"
fi

# ── Pattern 6: Dart map['field'] access ──────────────────────────────────
if $IS_DART; then
    P6=$(grep -nE "\['($FIELDS)'\]|\[\"($FIELDS)\"\]" "$FILE" 2>/dev/null | exclude_filter | grep -v 'Fields\.' | head -5)
    [ -n "$P6" ] && ALL_HITS="${ALL_HITS}  [map[]] ────\n${P6}\n"
fi

# ── Pattern 7: Bare collection names (Rust) ──────────────────────────────
# Matches: "orders", "products", "users" as standalone strings (not in format! with collections::)
COLLECTIONS='orders|products|users|cart|coupons|subscriptions|webhook_events|seller_profiles|payouts|return_requests|notifications|messages|chats|favorites|reviews|warehouses|disputes|licenses|_push_tokens|_pending_notifications|_cron_locks|_cron_failures|security_alerts|rate_limits'
if $IS_RUST; then
    P7=$(grep -nE '"('"$COLLECTIONS"')"' "$FILE" 2>/dev/null \
        | grep -v 'collections::' \
        | grep -v 'pub const' \
        | grep -v '/// ' \
        | grep -v '^[[:space:]]*//' \
        | grep -v '// ignore-magic' \
        | grep -v 'mod tests' \
        | grep -v '#\[cfg(test)\]' \
        | head -3)
    [ -n "$P7" ] && ALL_HITS="${ALL_HITS}  [collection] ────\n${P7}\n"
fi

# ── Output ───────────────────────────────────────────────────────────────
if [ -n "$ALL_HITS" ]; then
    COUNT=$(echo -e "$ALL_HITS" | grep -c '^[[:space:]]*[0-9]')
    echo ""
    echo ">>> MAGIC STRINGS in $BASENAME ($COUNT hits):"
    echo -e "$ALL_HITS"
    if $IS_RUST; then
        echo "  Fix: use fields::* for keys, collections::* for table names."
    else
        echo "  Fix: use Fields.* or SchemaConstants.* for keys."
    fi
    echo "  Suppress: add '// ignore-magic' on the line."
    echo ""
fi

exit 0
