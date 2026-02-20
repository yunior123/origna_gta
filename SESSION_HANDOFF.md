# SESSION HANDOFF — 2026-02-19

> Read `STATE.md` for the full 11-task plan details.
> This file tracks exact done/in-progress/todo state at context handoff.

---

## ✅ COMPLETED TASKS

### TASK 04 — BUG-4: status ↔ isActive atomic sync ✅
- Added `_compute_is_active(status, approval_status) -> bool` helper in `functions/handlers/products.py`
- Applied STATUS writes at every product write path (create, approve, reject, update)
- Added `Fields.STATUS` to `_SKIP_VALIDATION_FIELDS` with IS_ACTIVE sync
- 10 new tests added; all 34 tests pass

### TASK 01 — BUG-1: allowBackorder in checkout ✅
- `functions/handlers/payment_stripe.py`: skip stock check when `allowBackorder=True` at TWO locations:
  - Pre-validation loop (~line 654)
  - `reserve_stock_transaction` Firestore transaction
- Added constants `ALLOW_BACKORDER`, `LOW_STOCK_THRESHOLD`, `TRACK_QUANTITY`, `RESERVATION_HOLD_MINUTES` to `functions/schema_constants.py` AND `origna_gta/lib/core/schema/schema_constants.dart`
- 2 new tests added; all 57 tests pass

### TASK 02 — BUG-2: warehouseStock sync on purchase ✅
- `reserve_stock_transaction`: drain-fullest-warehouse-first strategy using Firestore dot-notation patches (`"warehouseStock.wh_id"`)
- `_rollback_checkout`: restore emptiest-first on rollback
- 4 new pure-logic tests; 480/481 tests pass (1 pre-existing unrelated failure in test_handlers_digital.py)

### TASK 03 — BUG-3: lowStockThreshold cron ✅ (PARTIAL — 3 items remain)
- `functions/handlers/cron_jobs.py`: `check_low_stock_alerts` cron added (every 24h, 23h cooldown, threshold=0 = opt-out)
- `functions/schema_constants.py`: `LAST_LOW_STOCK_ALERT_AT` added
- `origna_gta/lib/core/schema/schema_constants.dart`: `lastLowStockAlertAt` added
- Tests added in `functions/tests/test_handlers_admin_cron.py`
- **❌ STILL MISSING (3 items):**
  1. `functions/main.py` — `check_low_stock_alerts` NOT yet imported/registered
     - Add to the `from handlers.cron_jobs import (...)` block (alphabetical order between `check_expired_authorizations` and `cleanup_orphaned_r2_images`)
  2. `origna_gta/lib/screens/addproduct_screen.dart` — low stock alert toggle NOT yet in UI
     - State var `bool _lowStockAlertEnabled = false;` was ADDED (line ~76)
     - Toggle widget + conditional threshold field ADDED at lines ~674-690 (after allowBackorder toggle)
     - Submit action UPDATED: `lowStockThreshold: _lowStockAlertEnabled ? (int.tryParse(...) ?? 5) : 0`
     - **BUT `editproduct_screen.dart` has NOT been updated yet** — it only shows a stock quantity field, no inventory config section at all. Needs same toggle added.
  3. `origna_gta/lib/screens/editproduct_screen.dart` — needs the same `_lowStockAlertEnabled` toggle + threshold field in the inventory section. Currently editproduct_screen has no inventory config toggles at all — check if it should mirror addproduct or if inventory config is intentionally not editable in edit mode (check the `viewModel.editProduct()` call to see if `inventoryConfig` is passed).

---

## ⏳ PENDING TASKS (in execution order)

### TASK 08 — FEAT: compareAtPrice strikethrough pricing
- Add `compareAtPrice: number?` to `docs/database_schema.json` (products)
- Add `COMPARE_AT_PRICE = "compareAtPrice"` to `functions/schema_constants.py` Fields
- Mirror in `origna_gta/lib/core/schema/schema_constants.dart`
- Add `compareAtPrice: float | None` with validator `compareAtPrice > price` to `functions/models/product.py`
- Add `@Default(null) double? compareAtPrice` to `ProductSummary` + `Product` in `origna_gta/lib/models/generated/product_models.dart`
- Run `dart run build_runner build` to regenerate `.freezed.dart` and `.g.dart`
- Update `firestore.rules` to allow `compareAtPrice` in product write rules
- Add compare-at-price input to `addproduct_screen.dart` and `editproduct_screen.dart`
- Show strikethrough price in `origna_gta/lib/widgets/modern_product_card.dart`
- Add validation tests to `functions/tests/test_pydantic_models.py`

### TASK 05 — FEAT: Buyer address book
- See `STATE.md` for full file list

### TASK 06 — FEAT: Photo reviews
- See `STATE.md` for full file list

### TASK 07 — FEAT: Back-in-stock notifications
- See `STATE.md` for full file list

### TASK 09 — FEAT: Product Q&A section
- See `STATE.md` for full file list

### TASK 10 — FEAT: Abandoned cart recovery emails
- See `STATE.md` for full file list

### TASK 11 — FEAT: Seller health metrics tracking
- See `STATE.md` for full file list

---

## 🔑 CRITICAL CONTEXT FOR NEXT AI

### How to run tests
```bash
cd functions && python -m pytest tests/ -v --tb=short 2>&1 | tail -20
```

### How to check Flutter compilation
```bash
cd origna_gta && flutter analyze --dart-define=ENVIRONMENT=dev 2>&1 | head -30
```

### Regenerate Dart freezed models (after editing product_models.dart)
```bash
cd origna_gta && dart run build_runner build --delete-conflicting-outputs
```

### Key invariants (DO NOT BREAK)
- `isActive = (status == 'active' AND approvalStatus == 'approved')` — enforced by `_compute_is_active()`
- `stockQuantity = sum(warehouseStock.values())` — maintained by drain-fullest-first in `reserve_stock_transaction`
- `lowStockThreshold = 0` means "opt-out" (cron skips, UI shows toggle as off)
- All money in **integer cents** (`subtotalCents`, `taxAmountCents`, `totalAmountCents`)
- No hardcoded strings — use constants from `schema_constants.py` / `schema_constants.dart`

### Current test status
- Backend: 480/481 pass (1 pre-existing failure in `test_handlers_digital.py`, unrelated)
- Flutter: not checked this session

### Files modified this session
```
functions/handlers/products.py          — TASK 04 (status/isActive sync)
functions/handlers/payment_stripe.py    — TASK 01 (backorder) + TASK 02 (warehouseStock)
functions/handlers/cron_jobs.py         — TASK 03 (low stock cron)
functions/schema_constants.py           — TASK 01+03 (new field constants)
functions/main.py                       — TASK 03 partial (check_low_stock_alerts import ADDED)
origna_gta/lib/core/schema/schema_constants.dart  — TASK 01+03 constants synced
origna_gta/lib/screens/addproduct_screen.dart     — TASK 03 toggle added
functions/tests/test_handlers_products_orders.py  — TASK 04 tests
functions/tests/test_handlers_payment_stripe.py   — TASK 01+02 tests
functions/tests/test_handlers_admin_cron.py        — TASK 03 tests
```

### Next immediate action
1. Verify `check_low_stock_alerts` is now imported in `main.py` (was just added — confirm grep finds it)
2. Verify `addproduct_screen.dart` compiles (added toggle + conditional field + submit logic)
3. Decide: does `editproduct_screen.dart` need inventory config toggles? Check `editProduct()` call signature
4. Then proceed to TASK 08 (compareAtPrice) — most impactful UX feature
