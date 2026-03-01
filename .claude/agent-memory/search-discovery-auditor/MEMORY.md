# Search & Discovery Auditor Memory

## Architecture (verified 2026-03-01)
- Backend index name: `AlgoliaConfig.get_index_name()` in `functions/config.py` lines 214-222
  - emulator → `products_emulator`, dev → `products_dev`, staging → `products_staging`, prod → `products`
- Frontend index name: `EnvConfig().algoliaIndexName` in `origna_gta/lib/utils/env_config.dart` lines 113-118 — identical mapping
- Backend write key: `get_algolia_write_api_key()` from APP_SECRETS Secret Manager (`algolia.write_api_key`)
- Frontend search key: Firebase Remote Config key `algolia_search_api_key` (read-only, safe)
- No admin/write key ever sent to frontend — confirmed clean

## availableInCanada (SRCH-H1)
- Computed in `format_product_for_algolia()` lines 90-97: `(not is_local_only) or is_canadian_seller`
- Country comparison: `seller_country in ("CA", "CANADA")` — uppercased — ok
- Listed as `filterOnly(availableInCanada)` in `attributesForFaceting` (line 427) — filters only, not searchable
- Listed in `attributesToRetrieve` (line 464) — available to client
- Frontend applies `Filter.facet('availableInCanada', true)` in Algolia search path (`algolia_service.dart` line 36)
- NOT applied on Firestore fallback path — known gap (Firestore fallback has no Canada filter)

## Inactive Product Filtering
- Backend `index_product()` line 189: only indexes `lifecycleStatus == ACTIVE`; deactivated products trigger delete
- `on_product_updated` line 2299: non-active status → `algolia_delete_product()` immediately
- `on_product_deleted` line 2623: always calls `algolia_delete_product()`
- Frontend Algolia path: `Filter.facet(Fields.lifecycleStatus, ProductLifecycleStatusValues.active)` — double-enforced
- Frontend Firestore fallback: `where(Fields.lifecycleStatus, isEqualTo: active)` — correctly filtered

## Known Bugs Found
1. DEAD CODE (HIGH): `on_product_updated` line 2434-2435 — `_address_changed` assignment is unreachable (falls after `return` on line 2433). `_address_changed` is always `False`, so geocoding is NEVER re-run on address updates.
2. PRICE RANGE FACETING MISSING (MEDIUM): `price` is NOT in `attributesForFaceting` — no numeric range filter possible client-side.
3. `shipFromProvince` NOT in `attributesForFaceting` — province filtering cannot be applied as a facet filter.
4. `_previousLifecycleStatus` key in `index_product()` line 190: never set by any caller — always `None`, so deactivated-product delete path never fires from `index_product()` directly (but `on_product_updated` handles it).

## Sync Triggers (confirmed complete)
- Create: `on_product_created` — does NOT index; approval flow only indexes via `admin_approve_product` (correct by design)
- Update: `on_product_updated` — indexes or deletes based on lifecycleStatus
- Delete: `on_product_deleted` — always deletes from Algolia
- Approval: `admin_approve_product` — indexes fresh doc after admin approval
- Suspension: `deactivate_supplier_platform` — batch partial update with paused status
- Monitoring: `monitor_algolia_sync` cron every 15 min — alerts on >5% mismatch

## Environment Isolation
- Both backend and frontend use identical index-name mapping per environment
- Isolation is compile-time (dart-define / IS_EMULATOR env var) — correct
