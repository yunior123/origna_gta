#!/bin/bash
# Check for magic strings in modified Rust and Dart files
# Exit 0 = pass (warning only), Exit 1 = block

CHANGED_FILES=$(git diff --name-only --diff-filter=AM HEAD 2>/dev/null | grep -E '\.(rs|dart)$')
if [ -z "$CHANGED_FILES" ]; then
    exit 0
fi

MAGIC_PATTERNS='"(status|orderStatus|paymentStatus|sellerId|buyerId|productId|orderId|userId|createdAt|updatedAt|items|priceCents|quantity|isDigital|stockQuantity|lifecycleStatus|apartment|phoneNumber|warehouseIds|parent_id|shippedAt|deliveredAt|cancelledAt|trackingNumber|isPerishable|state|type|label)"'

FOUND=0
for f in $CHANGED_FILES; do
    if [ ! -f "$f" ]; then
        continue
    fi

    # Skip test files, schema constants, and field definition files
    if echo "$f" | grep -qE '(_test\.dart|test_.*\.dart|schema_constants\.dart|fields\.rs|constants\.rs)'; then
        continue
    fi

    HITS=$(grep -nE "$MAGIC_PATTERNS" "$f" 2>/dev/null \
        | grep -v 'fields::' \
        | grep -v 'Fields\.' \
        | grep -v 'SchemaConstants\.' \
        | grep -v '// ignore-magic' \
        | grep -v '#\[test\]' \
        | grep -v '#\[cfg(test)\]' \
        | grep -v 'serde' \
        | grep -v 'deserialize' \
        | grep -v 'serialize' \
        | grep -v 'pub const' \
        | grep -v 'static const' \
        | grep -v 'pub fn' \
        | grep -v '/// ' \
        | grep -v '// ' \
        | head -5)

    if [ -n "$HITS" ]; then
        echo "WARNING: Magic strings in $f:"
        echo "$HITS"
        FOUND=1
    fi
done

if [ $FOUND -eq 1 ]; then
    echo ""
    echo "Replace bare strings with fields::* (Rust) or Fields.*/SchemaConstants.* (Dart) constants."
    echo "Add '// ignore-magic' comment to suppress false positives."
fi
exit 0
