#!/bin/bash
# PostToolUse hook: check a single file for magic string KEYS in json!({}) blocks.
# Called after each Edit/Write with TOOL_INPUT containing the file path.
#
# Detects bare string keys like "token", "topic", "created_at" that should
# use fields::* (Rust) or Fields.* (Dart) constants.
#
# Exit 0 = pass (warning only). Never blocks.

# Extract file path from TOOL_INPUT JSON
FILE=$(echo "$TOOL_INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('file_path',''))" 2>/dev/null)

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    exit 0
fi

# Only check .rs and .dart files
echo "$FILE" | grep -qE '\.(rs|dart)$' || exit 0

# Skip schema/constant definition files and test files
echo "$FILE" | grep -qE '(schema_constants\.dart|schema\.rs|constants\.rs|_test\.dart|test_.*\.dart|snapshots/)' && exit 0

# ── Magic string KEYS to detect ──────────────────────────────────────────
# These are field names that should use constants, NOT bare strings.
# Pattern matches: "fieldName": (as a json key, left side of colon)
FIELD_KEYS='"\b(status|orderStatus|paymentStatus|sellerId|buyerId|productId|orderId|userId|createdAt|updatedAt|items|priceCents|quantity|isDigital|stockQuantity|lifecycleStatus|trackingNumber|shippedAt|deliveredAt|cancelledAt|isPerishable|apartment|phoneNumber|warehouseIds|parent_id|token|topic|created_at|updated_at|delivered_at|buyer_id|seller_id|product_id|order_id|user_id|payment_intent_id|stripe_session_id|coupon_code|discount_type|discount_value|min_order_cents|max_uses_total|is_active|expires_at|return_status|refund_amount_cents|refund_reason|license_key|device_id|platform|is_default|postal_code|latitude|longitude|street|city|country|roles|email|name|description|price|weight|category|subcategory|keywords|images|variants|variantId|variantKey|sku|isDefault|stockQuantity|notifiedAt|sentAt|attempts|resolved|archived|confirmedByClient|autoConfirmed|suspendReason|disputeId|chargeId|reason|currency|message|body|title|data|type|timestamp|processed)\b":'

# Check the file for bare string keys
HITS=$(grep -nE "$FIELD_KEYS" "$FILE" 2>/dev/null \
    | grep -v 'fields::' \
    | grep -v 'Fields\.' \
    | grep -v 'SchemaConstants\.' \
    | grep -v '// ignore-magic' \
    | grep -v '#\[serde' \
    | grep -v 'pub const ' \
    | grep -v 'static const ' \
    | grep -v '/// ' \
    | grep -v '// ' \
    | grep -v 'mod tests' \
    | grep -v '#\[cfg(test)\]' \
    | head -8)

if [ -n "$HITS" ]; then
    # Count how many hits (for severity)
    COUNT=$(echo "$HITS" | wc -l | tr -d ' ')
    BASENAME=$(basename "$FILE")
    echo ""
    echo ">>> MAGIC STRINGS DETECTED in $BASENAME ($COUNT hits):"
    echo "$HITS" | while IFS= read -r line; do
        echo "  $line"
    done
    echo ""
    echo "  Replace bare string keys with fields::* (Rust) or Fields.* (Dart) constants."
    echo "  Add '// ignore-magic' to suppress false positives."
    echo ""
fi

exit 0
