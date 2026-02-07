---
paths:
  - "functions/**"
---

# Python Backend Rules

## Architecture
- Entry: `functions/main.py` — all Cloud Functions registered here
- Handlers: `functions/handlers/` — domain-specific business logic
- Models: `functions/models/` — Pydantic models
- All handlers receive `request` and return JSON responses

## Code Safety
- **Idempotency required** for all payment operations (use event_id dedup)
- **Validate ALL inputs server-side** — never trust frontend data
- **Re-fetch prices from Firestore** — never use client-sent prices for payment
- **Atomic Firestore transactions** for stock operations
- **Webhook signature verification** via `stripe.Webhook.construct_event()`
- **Rate limiting** on auth endpoints via `rate_limiter.py`

## Schema Constants
- `functions/schema_constants.py` is the Python source of truth for field names
- **Must stay in sync** with `origna_gta/lib/core/schema/schema_constants.dart` (Dart mirror)
- **Must match** `docs/database_schema.json` (overall source of truth)
- Run `./scripts/validate_schema_consistency.sh` after any schema change

## Testing
- 288 tests in `functions/tests/`
- Use `conftest.py` fixtures for Firebase mocking
- Run: `cd functions && source venv/bin/activate && pytest -v`

## Cross-Stack Rule
- When editing ANY handler, check the corresponding Dart provider/viewmodel that calls it
- When changing a response format, update the Dart repository that parses it
- When adding/removing a field, update: schema_constants.py + schema_constants.dart + database_schema.json + Freezed models
