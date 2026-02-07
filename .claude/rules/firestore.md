---
paths:
  - "firestore.*"
  - "**/schema_constants*"
  - "docs/database_schema.json"
  - "docs/json_schemas/**"
  - "**/repository*"
  - "**/repositories/**"
---

# Firestore & Schema Rules

## Source of Truth Chain
```
docs/database_schema.json          ← ULTIMATE SOURCE
  ↓ mirrors to
functions/schema_constants.py      ← Python field names & enums
origna_gta/lib/core/schema/schema_constants.dart  ← Dart mirror
  ↓ used by
functions/models/*.py              ← Python Pydantic models
origna_gta/lib/models/generated/*.dart  ← Dart Freezed models
  ↓ enforced by
firestore.rules                    ← Security rules
firestore.indexes.json             ← Composite indexes
```

## When Changing Schema
1. Update `docs/database_schema.json` FIRST
2. Update `functions/schema_constants.py`
3. Update `origna_gta/lib/core/schema/schema_constants.dart`
4. Update relevant Python model in `functions/models/`
5. Update relevant Freezed model in `origna_gta/lib/models/generated/`
6. Update `firestore.rules` if security affected
7. Update `firestore.indexes.json` if queries affected
8. Run `./scripts/validate_schema_consistency.sh`
9. Run `./scripts/generate_dart_models.sh` if Freezed changes

## Cost Rules
- Reads are more expensive than writes
- Avoid collection group queries unless justified
- Cache aggressively when safe
- Index cost matters — don't create unnecessary composite indexes
- Database is currently EMPTY — no migration needed
