# /check-schema-sync — Verify all schema layers are in sync

**Usage**: `/check-schema-sync`

## What it verifies
All field names and data types are consistent between:
1. `lib/core/schema/schema_constants.dart` (Dart constants)
2. Freezed model definitions (`lib/models/`)
3. OrignaBase API response shapes
4. PostgreSQL table fields

## Critical Timestamp Rules
| Collection | Field | NOT |
|------------|-------|-----|
| `orders`, `users`, `payouts`, `return_requests` | `createdAt` | `dateCreated` |
| `products`, `cart` | `dateCreated` | `createdAt` |
| `webhook_events` | `timestamp` | either above |

## Quick Checks
```bash
# Find hardcoded timestamp field references (should use schema_constants)
grep -r '"createdAt"\|"dateCreated"\|"timestamp"' origna_gta/lib/services/ 2>/dev/null

# Find money fields without Cents suffix
grep -r '"price"\b\|"total"\b\|"amount"\b' origna_gta/lib/services/ 2>/dev/null | grep -v "Cents"

# Find hardcoded order status strings (should use schema_constants)
grep -r '"pending"\|"confirmed"\|"shipped"\|"delivered"\|"cancelled"' origna_gta/lib/ --include="*.dart" 2>/dev/null | grep -v "schema_constants\|//\|rules"

# Find hardcoded lifecycle status strings
grep -r '"draft"\|"active"\|"inactive"\|"deleted"' origna_gta/lib/ --include="*.dart" 2>/dev/null | grep -v "schema_constants\|//\|rules"
```

## If out of sync
1. Update `schema_constants.dart` to add the correct constant
2. Replace all raw string literals with the constant
3. Run `flutter analyze --no-fatal-infos` to verify
4. Run the `schema-sync-checker` agent for a deep audit: `Use schema-sync-checker`
