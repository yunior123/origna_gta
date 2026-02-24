# STATE.md



- Playwright E2E tests: run against dev environment to find any broken tests post-changes
- Add more E2E test coverage for:
  - Stock notification subscribe/unsubscribe with variantKey
  - Digital product purchase → license generation flow
  - Async payment (Interac) confirmation flow
  - Multi-seller cart → per-seller payout verification


Now let me read the backend Python files.Now let me check the algolia and product model files.Now I have enough context for a comprehensive audit.

---

```
[CRITICAL] add_product_viewmodel.dart:266 + product_repository.dart:263
PROBLEM: `warehouseStockMap` (per-warehouse stock allocation) is never included in the payload sent to the backend — only the summed `effectiveStock` reaches Firestore. Stock fulfillment per warehouse is permanently lost at write time, making multi-warehouse inventory routing impossible.
FIX: Add `warehouseStockMap` to the `Product` model and include it in the payload:
```dart
// In Product model: add field
final Map<String, int>? warehouseStockMap;
// In ViewModel line ~329:
warehouseStockMap: useWarehouses ? state.warehouseStockMap : null,
```
ALSO: product.py — add `warehouseStockMap: dict[str, int] | None = Field(default=None)` to Product model.

[CRITICAL] products.py:1113
PROBLEM: `create_product_atomic` does NO SKU uniqueness check before the Firestore write — the check only exists in the asynchronous `on_product_created` trigger (line 1167). A race condition allows two concurrent `create_product_atomic` calls with the same `sellerSku` to both write successfully; the trigger then deactivates one silently with no error surfaced to the seller.
FIX: Add a pre-write SKU check inside `create_product_atomic` before `product_ref.set(product_data)`:
```python
seller_sku = product_data.get(Fields.SELLER_SKU)
if seller_sku:
    existing = get_db().collection(Collections.PRODUCTS)\
        .where(Fields.SELLER_ID, "==", user_id)\
        .where(Fields.SELLER_SKU, "==", seller_sku)\
        .where(Fields.LIFECYCLE_STATUS, "!=", ProductLifecycleStatusValues.ARCHIVED)\
        .limit(1).get()
    if existing:
        raise https_fn.HttpsError("already-exists", "A product with this SKU already exists.")
```

[CRITICAL] products.py:1090–1114
PROBLEM: `create_product_atomic` does not set `updatedAt` on product creation. The schema rule requires both `createdAt` and `updatedAt` on every document. All downstream `product_ref.update()` calls in `on_product_created` also fail to set `updatedAt`, leaving the field permanently absent.
FIX: Add to the server-controlled fields block at line 1094:
```python
product_data[Fields.UPDATED_AT] = get_server_timestamp()
```
ALSO: on_product_created — add `Fields.UPDATED_AT: get_server_timestamp()` to every `update()` patches dict.

[HIGH] add_product_viewmodel.dart:122–159
PROBLEM: Address validation (street, city, postal, province, Geoapify verification) is fully bypassed when `selectedWarehouseIds` is non-empty, but no server-side validation confirms the warehouse addresses are still valid/complete at product creation time. A seller could select a warehouse with an incomplete address and the product writes successfully.
FIX: In `create_product_atomic` backend, fetch warehouse docs and assert each has a non-empty `address.city`, `address.country`, and `address.postalCode` before accepting the product:
```python
for wid in warehouse_ids:
    w_doc = get_db().collection(Collections.USERS).doc(user_id)\
        .collection(Collections.WAREHOUSES).document(wid).get()
    if not w_doc.exists:
        raise https_fn.HttpsError("not-found", f"Warehouse {wid} not found")
    addr = (w_doc.to_dict() or {}).get("address", {})
    if not addr.get("city") or not addr.get("country"):
        raise https_fn.HttpsError("invalid-argument", f"Warehouse {wid} has an incomplete address")
```

[HIGH] addproduct_screen.dart (line ~1758) + add_product_viewmodel.dart:108
PROBLEM: `stock` parameter passed to `addProduct()` comes from `int.tryParse(_stockController.text.trim()) ?? 0`. When warehouses are selected, `effectiveStock = sum(warehouseStockMap)`, but the raw `stock` arg from the form controller is still passed (and would be used if `useWarehouses` computation fails or the map is empty). A malicious seller could also enter `stock=0` in the text field while having warehouses selected, triggering the `totalStock == 0` guard that aborts with an error rather than using the sum — confusing UX.
FIX: When `useWarehouses`, ignore the `stock` parameter entirely at the call site:
```dart
stock: state.selectedWarehouseIds.isEmpty
    ? (int.tryParse(_stockController.text.trim()) ?? 0)
    : 0, // always overridden by warehouseStockMap sum in VM
```

[HIGH] product_models.dart (Product class, ~line 116)
PROBLEM: `Product` model is missing `updatedAt` field entirely. The backend writes `updatedAt` on bulk updates (line 3644), but the Dart model cannot deserialize it, and the add-product flow doesn't include it in `Product.fromFirestore`. This causes silent field loss on every client read of an updated product.
FIX: Add to the Dart `Product` model:
```dart
final DateTime? updatedAt;
```
And deserialize it in `fromFirestore` alongside `createdAt`.

[HIGH] add_product_viewmodel.dart:73–74
PROBLEM: `isDevOrTestRun` bypasses image validation, address verification, and allows placeholder test URLs in `ENVIRONMENT=dev` — but the check reads the dart-define at **compile time** via `const String.fromEnvironment`. In a debug build with no `--dart-define=ENVIRONMENT=dev`, the default is `'production'`, so a debug APK distributed to QA testers silently enforces full prod validation. Conversely, any binary compiled with `ENVIRONMENT=dev` retains this bypass forever regardless of which Firebase project it hits.
FIX: Couple the bypass to both the env constant AND a Firebase project check:
```dart
final isDevOrTestRun = const String.fromEnvironment('ENVIRONMENT') == 'dev'
    || const String.fromEnvironment('ENVIRONMENT') == 'emulator';
// Never allow bypass in staging or production builds regardless of define.
```
Also ensure the backend validates this independently (which it already does at line 1045 via `CURRENT_ENV`).

[HIGH] product_repository.dart:22 + 125
PROBLEM: `addProduct()` and `addProductWithId()` write directly to Firestore from the client, bypassing `create_product_atomic`'s server-controlled fields (sellerId overwrite, lifecycleStatus=draft, createdAt=serverTimestamp). A caller using either method directly could write an active product with a client-controlled `sellerId`, skipping the approval gate entirely.
FIX: Remove or `@Deprecated` both methods and make them throw `UnsupportedError`. The abstract interface at line 651–652 should also remove these signatures to prevent future regressions.

[MEDIUM] products.py:195–212 + 292–310 + 394–410 + 1051–1066
PROBLEM: `get_r2_credentials()` is called fresh inside every handler invocation with no module-level cache. At 100M users/year, this hits Secret Manager thousands of times/minute ($0.03/10k calls × scale = significant cost).
FIX: Cache at module level:
```python
_r2_creds: dict | None = None
def get_cached_r2_credentials() -> dict:
    global _r2_creds
    if _r2_creds is None:
        _r2_creds = get_r2_credentials()
    return _r2_creds
```

[MEDIUM] products.py:1113 + on_product_created trigger
PROBLEM: `create_product_atomic` sets `lifecycleStatus = draft` at write time, then `on_product_created` trigger overwrites to `under_review` in a separate async update. If the trigger fails (crash, timeout, cold-start memory OOM), the product stays in `draft` forever with no seller notification, no admin alert, and no retry mechanism.
FIX: Set `lifecycleStatus = ProductLifecycleStatusValues.UNDER_REVIEW` directly in `create_product_atomic` after all validation passes, eliminating the trigger's status-flip step. The trigger then only applies patches and sends admin notification.

[MEDIUM] algolia_service.py:196 + products.py:1667
PROBLEM: `admin_approve_product` calls `index_product()` which calls `save_object` (full reindex). At approval time the `product_data` dict has the local copy from line 1661 (`product_data.update({...ACTIVE})`), but `priceCents`, `slug`, `shipFromCity/Province/Country`, and patch fields applied by the trigger may not be present in this dict if the trigger's patches haven't been committed yet (race with async trigger). The Algolia record is indexed with potentially stale/missing fields.
FIX: Re-fetch the product doc after approval before indexing:
```python
product_data = product_ref.get().to_dict() or {}  # fresh read post-patches
index_product(product_id, product_data)
```

[MEDIUM] productaddimages_screen.dart:32–34
PROBLEM: `_imageModels` is initialized from `widget.imageModels` in `initState` only. If the ViewModel resets (success → new form), `widget.imageModels` changes to `[]` but the local `_imageModels` retains the old list because `didUpdateWidget` is not overridden. A new listing would show stale images from the previous submission.
FIX: Override `didUpdateWidget`:
```dart
@override
void didUpdateWidget(ProductAddImages oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (oldWidget.imageModels != widget.imageModels) {
    setState(() => _imageModels = List<ImageModel>.from(widget.imageModels));
  }
}
```

[MEDIUM] add_product_viewmodel.dart:260
PROBLEM: Warehouse stock guard `totalStock == 0` aborts with an error, but the guard also fires when `allHaveStock == false` (some warehouses in `selectedWarehouseIds` have no entry in `warehouseStockMap`). The condition `state.warehouseStockMap.isEmpty || !allHaveStock || totalStock == 0` conflates three different states with one error message, making it impossible for the seller to know which warehouse is missing stock.
FIX: Separate guards with distinct error messages:
```dart
if (state.warehouseStockMap.isEmpty) {
  state = state.copyWith(errorMessage: 'product.warehouse_stock_required'.tr()); return;
}
final missing = state.selectedWarehouseIds.where((id) => !state.warehouseStockMap.containsKey(id)).toList();
if (missing.isNotEmpty) {
  state = state.copyWith(errorMessage: 'product.warehouse_stock_missing_for_some'.tr()); return;
}
if (state.warehouseStockMap.values.fold(0, (a, b) => a + b) == 0) {
  state = state.copyWith(errorMessage: 'product.warehouse_stock_zero'.tr()); return;
}
```

[MEDIUM] add_product_viewmodel.dart:298–299
PROBLEM: `product.createdAt = DateTime.now()` sets a client-side timestamp; even though `sanitizeProductForFirestore` and `createProductAtomic` override it server-side, the `Product` model is serialized with the client timestamp before the override. If `create_product_atomic` backend code ever changes the override order, a client timestamp silently corrupts chronological ordering.
FIX: Pass `createdAt: DateTime.fromMillisecondsSinceEpoch(0)` as a sentinel that is always overridden, and add an assertion in `create_product_atomic` that `createdAt` is always set to `SERVER_TIMESTAMP`.

[LOW] add_product_viewmodel.dart:104
PROBLEM: `compareAtPrice != null && compareAtPrice <= price` rejects equality but allows a `compareAtPrice` of e.g., `0.01` above `price` which is a meaningless discount display and could be used to fake a "sale" badge. No minimum discount threshold is enforced.
FIX: Require at least a 1% or minimum $0.50 difference:
```dart
if (compareAtPrice != null && (compareAtPrice <= price || compareAtPrice - price < 0.50)) {
  state = state.copyWith(errorMessage: 'product.compare_at_price_meaningful_difference'.tr());
  return;
}
```

[LOW] products.py:1270 (on_product_created)
PROBLEM: Backend validates address via Geoapify geocoding on every `on_product_created` trigger, even when the frontend already sent verified lat/lng (Geoapify was called client-side). This is double-billing Geoapify and adding ~500ms latency to every product creation. The Cost Monitor pattern says same address = same coordinates; never re-geocode.
FIX: Use the client-sent `seller_lat`/`seller_lon` directly for range validation (ensure they're within Canada bounding box: lat 41–84, lon -141 to -52) instead of a round-trip geocoding call.

[LOW] product_repository.dart:365–379
PROBLEM: `fetchProductsByIds` uses `whereIn` which has a 30-doc limit, correctly batched. However it filters `lifecycleStatus == active` — a favorited product that is paused/archived will silently disappear from the favorites list with no user feedback.
FIX: Either fetch without the status filter and handle display in UI (show "unavailable"), or return a `FetchResult` with a `missingIds` field so the Dart layer can show "X item no longer available" in the favorites UI.

[BONUS] addproduct_screen.dart:157, 166, 188, 831, 936, 952, 1535, 1556, 1615
PROBLEM: `Colors.white` used directly in 9+ places rather than via `DesignTokens`. If the design system introduces a dark theme, all these hardcoded values break.
FIX: Replace `Colors.white` with `DesignTokens.onPrimary` (or equivalent token) in all cases.

[BONUS] products.py:1486–1503
PROBLEM: Admin notification email inlines `product_name` and `seller_id` directly into the HTML body (`f"...{product_name}..."`) without escaping — a seller with a name containing `<script>` or `"><img src=x onerror=...>` can inject HTML into the admin's email client.
FIX: Escape all interpolated values:
```python
import html as _html
safe_name = _html.escape(product_name)
safe_seller = _html.escape(seller_id)
```

[BONUS] products.py:1671 (admin_approve_product)
PROBLEM: Algolia indexing failure at line 1670 is caught and logged but the function returns `200 OK` to the admin. The product is live in Firestore but invisible in search — no admin alert, no retry, only a dead-letter entry. Admin has no indication the approval was partial.
FIX: Return a warning flag in the response:
```python
return create_success_response({}, message="Product approved but Algolia indexing failed — product may not appear in search immediately")
```

[BONUS] algolia_service.py:64–80
PROBLEM: When Pydantic validation fails in `format_product_for_algolia`, the raw unvalidated dict is used as `data` (line 71) and then passed to Algolia with only name/price sanitized. Other fields like `sellerId`, `categoryId`, `lifecycleStatus` remain unsanitized — a malformed product could corrupt the index.
FIX: On validation failure, either raise and let `_log_sync_failure` handle it, or apply a full field allowlist sanitization before indexing.

[BONUS] add_product_state.dart — missing `condition` field
PROBLEM: `product.py` and `product_models.dart` both define a `condition` field (`new | like_new | good | fair | for_parts`), but `AddProductState`, `AddProductViewModel`, and `addproduct_screen.dart` never collect or send it. Every product is created with `condition: null`, preventing condition-based filtering.
FIX: Add `String? condition` to `AddProductState`, a `setCondition()` method to the ViewModel, and a dropdown/chip selector in the screen's product details section.

[BONUS] product_repository.dart:86–89
PROBLEM: Warehouse denormalization in `addProduct()` (the direct client-write path) swallows all exceptions silently (`catch (e) { AppError.log(...) }`). If this path were ever called, a product could be created with no `shipFromCity/Province/Country`, breaking geographic filtering. Since `createProductAtomic` handles this server-side correctly, these methods should be removed entirely (see `[HIGH]` finding above).

[BONUS] products.py:1553–1589 (_notify_premium_users_new_product)
PROBLEM: FCM multicast is capped at 500 tokens per `send_each_for_multicast` call, but the Firestore query only fetches 500 users via `.limit(500)`. If more than 500 premium users have opted in, only the first 500 (by Firestore internal order) are notified — silently drops the rest.
FIX: Use pagination or FCM topics instead:
```python
# Option: Register opted-in users to a topic "new_product_alerts" and use topic messaging.
messaging.send(messaging.Message(topic="new_product_alerts", notification=...))
```

```
[CRITICAL] supplier_config.dart:394-408
PROBLEM: Map key is 'local_canada' but the config's own id field is 'local' — when seller selects this entry, _selectedSupplierType = 'local_canada' is stored and sent to backend, but Python SupplierTypeValues.ALL and Dart SupplierTypeValues.all only contain 'local'. Backend field_validator rejects 'local_canada' with a 400, silently blocking local Canadian suppliers from publishing products.
FIX: Align the map key with the id: change the map key from 'local_canada' to 'local', and add SupplierTypeValues.localCanada = 'local_canada' to schema_constants if you want to keep the distinction, OR change `id: 'local'` to `id: 'local_canada'` and add 'local_canada' to ALL sets in both Dart and Python schema_constants.
```

```
[HIGH] product_repository.dart:34-47
PROBLEM: sellerSku uniqueness check is a TOCTOU race — two concurrent product creates with the same SKU both pass the .where().limit(1).get() read before either write lands, allowing duplicate SKUs for the same seller.
FIX: Move the dedup check server-side inside a Firestore transaction in a Cloud Function, or add a Firestore rule / unique index guard. Client-side reads cannot prevent race conditions.
```

```
[HIGH] addproduct_screen.dart:71, 612, 658
PROBLEM: Magic strings 'aliexpress', 'other', 'USD' used directly in screen state — violates no-magic-strings rule and will silently misfire if constants change.
FIX: Replace with constants:
  String _selectedSupplierType = SupplierTypeValues.aliexpress;
  _selectedSupplierType = v ?? SupplierTypeValues.other;
  _selectedSupplierCurrency = v ?? SupplierCurrencyValues.usd;
ALSO: addproduct_screen.dart:978 — discountType: 'percent' and 'flat_rate' magic strings → use DiscountTypeValues.PERCENT / DiscountTypeValues.FLAT_RATE.
```

```
[HIGH] supplier_config.dart:488 (getSupplierDropdownItems / isActive logic)
PROBLEM: Deactivating a supplier (isActive: false) only hides it from the UI dropdown. Existing products with that supplierType remain indexed in Algolia and visible in search. There is no backend/Algolia filter for supplierPlatform.isActive, so "graceful hiding on deactivation" from checklist item #6 is not enforced.
FIX: Add a supplierDeactivated boolean field to products when a supplier is deactivated (via admin Cloud Function), then filter `lifecycleStatus != active OR supplierDeactivated != true` in Algolia. Alternatively, on supplier deactivation trigger, bulk-update matching products to lifecycleStatus = 'paused'.
```

```
[MEDIUM] supplier_config.dart:23 / schema_constants.dart:1476-1481
PROBLEM: The comment "No other code changes required — the system is fully dynamic" is false. Adding a new supplier to supplierPlatforms also requires manually updating SupplierTypeValues.all in schema_constants.dart (Dart) and the Python equivalent. Omitting this causes backend field_validator to reject the new supplier type.
FIX: Either document the required 3-step checklist (map entry + Dart all set + Python all set), or generate SupplierTypeValues.all dynamically from supplierPlatforms.keys at startup to keep it in sync automatically.
```

```
[MEDIUM] add_product_viewmodel.dart:74
PROBLEM: isDevOrTestRun only checks for ENVIRONMENT == 'dev', missing 'emulator'. Address verification (Geoapify), image requirement, and delivery tier checks are all still enforced in emulator env, breaking local development and integration tests that run against the emulator.
FIX: const env = String.fromEnvironment('ENVIRONMENT', defaultValue: 'production');
final isDevOrTestRun = env == 'dev' || env == 'emulator';
```

```
[MEDIUM] product_repository.dart:527
PROBLEM: All uploaded images are given a hardcoded .jpg extension regardless of the actual format. A seller uploading a PNG or WebP receives a public URL ending in .jpg — the CDN serves the file with the wrong content-type, breaking image rendering on some clients and violating browser content-sniffing protections.
FIX: Derive extension from the ImageModel mime-type or original file name:
  final ext = model.mimeType?.split('/').last ?? 'jpg';
  final fileName = "product_${productId}_${index}_${DateTime.now().millisecondsSinceEpoch}.$ext";
```

```
[MEDIUM] products.py:3551-3564 (_track_price_history)
PROBLEM: The function reads the product doc, mutates the list in memory, then writes — not inside a transaction. Concurrent price updates lose entries: both reads see the same list, both append, both write, and one update is silently dropped.
FIX: Use ArrayUnion unconditionally (no extra read needed for append); enforce the 30-entry cap with a separate scheduled cleanup or Firestore trigger instead of a read-modify-write:
  prod_ref.update({Fields.PRICE_HISTORY: ArrayUnion([new_entry])})
  # Trim in a separate trigger or accept eventual consistency on the cap.
```

```
[BONUS] product.py:530
PROBLEM: Comment reads "Legacy single-address" — the word "legacy" is explicitly forbidden by CLAUDE.md Rule #2.
FIX: Change to: "Single-address fallback; required if warehouseIds is not provided"
```

```
[BONUS] supplier_config.dart:559
PROBLEM: SupplierPlatformConfig default parameter color: Colors.blue — direct Colors.* usage violates DesignTokens-only rule.
FIX: color: DesignTokens.primary (or a neutral token), never a raw Colors.* reference.
```

```
[BONUS] product.py:87, 93
PROBLEM: SellerDeliveryOption.cost: float and additionalItemCost: float are monetary values stored as floats. At 100M+ scale, float arithmetic accumulates rounding errors (e.g. 0.1 + 0.2 ≠ 0.3). Schema rule: all monetary fields must be int cents.
FIX: Rename to costCents: int and additionalItemCostCents: int throughout Python model, Dart model, and Firestore — divide by 100.0 only at display time.
ALSO: Product.price: float and ProductCreate.price: float have the same issue.
```

```
[BONUS] addproduct_screen.dart:1133, 1156, 363, 369-372, 1644, 1663
PROBLEM: Multiple hardcoded English strings not routed through .tr(): 'Download Links', 'Device limit', 'Leave blank for unlimited', 'Your SKU (optional)', 'e.g. T-SHIRT-BLK-M', 'What is a SKU?', 'Seller SKU', 'Subcategory (optional)', 'Select subcategory'. French sellers see English UI.
FIX: Add keys to the translations file and wrap each string with .tr(). Cross-stack check: add matching keys to the FR translation JSON.
```

```
[BONUS] addproduct_screen.dart:1699-1706
PROBLEM: Discount tier validation (discount5 < discount3) fires only on submit, and surfaces via a raw ScaffoldMessenger SnackBar — bypassing the unified error display pattern used everywhere else in the form. UX inconsistency.
FIX: Add cross-field validator to the relevant TextFormField or move the check into viewModel.addProduct() so it sets state.errorMessage like all other validations.
```

```
[BONUS] product.py:96-98
PROBLEM: Field is named availableInternational but the docstring says "available nationwide across Canada" — the name and description directly contradict each other. This will confuse any developer mapping the field.
FIX: Rename to availableNationwide: bool with docstring "Whether this delivery option ships anywhere in Canada (vs local-only)". Update Dart model and Firestore schema to match.
```

```
[BONUS] product_repository.dart:54-61 (addProduct warehouse denorm)
PROBLEM: Warehouse docs are fetched with Future.wait inside addProduct, which fires N parallel Firestore reads (one per warehouseId). At scale this is an N+1 per product creation. Also identical logic is duplicated verbatim in addProductWithId (lines 153-160) — copy-paste bug risk.
FIX: Extract warehouse denorm into a private _denormalizeWarehouses(product, firestoreData) method called by both paths.
```
Now I have enough context for the full audit. Let me compile findings:---

```
[CRITICAL] product_repository.dart:33-46
PROBLEM: SKU dedup uses read-then-write without a Firestore transaction; two concurrent creates from the same seller with the same SKU both pass the `existing.docs.isNotEmpty` check before either write completes, silently creating duplicate SKUs.
FIX: Wrap the SKU check and `add()` in a Firestore runTransaction, or enforce uniqueness via a composite Firestore security rule `allow create: if !exists(/databases/$(database)/documents/products/$(request.resource.data.sellerId + "_" + request.resource.data.sellerSku))` plus a Cloud Function trigger that deletes duplicates atomically.
ALSO: product_repository.dart:132-147 (same bug in `addProductWithId`)
```

```
[CRITICAL] models/product.py (Product class, price field)
PROBLEM: `price`, `compareAtPrice`, and `cost` are stored as `float`, not integer cents — violates Schema Sync rule "Money as cents". Floating-point arithmetic at scale causes silent $0.01 rounding errors in Stripe conversions, tax calculations, and promo comparisons.
FIX: Replace `price: float` with `priceCents: int` (store as cents) across the Python model, Dart Freezed model, and Algolia formatter, and recompute `double get price => priceCents / 100.0` as a derived getter. All Stripe calls must use `priceCents` directly.
ALSO: models/generated/product_models.dart (double price field), algolia_service.py:88 (Fields.PRICE indexed as float)
```

```
[CRITICAL] products.py — `on_product_created` Firestore trigger (missing SKU uniqueness enforcement)
PROBLEM: The Dart repo comment "on_product_created trigger is 2nd layer" implies a backend trigger enforces sellerId+sellerSku uniqueness, but no such trigger is present in products.py — if the client-side check is bypassed (direct Firestore write via admin SDK or race), duplicate SKUs persist silently.
FIX: Add a Firestore trigger:
```python
@firestore_fn.on_document_created(document="products/{productId}", **FIRESTORE_TRIGGER_OPTIONS)
def on_product_created(event):
    data = event.data.to_dict() or {}
    seller_id = data.get(Fields.SELLER_ID)
    seller_sku = data.get(Fields.SELLER_SKU)
    if seller_sku and seller_id:
        dupes = get_db().collection(Collections.PRODUCTS)\
            .where(Fields.SELLER_ID, "==", seller_id)\
            .where(Fields.SELLER_SKU, "==", seller_sku).limit(2).get()
        if len(dupes) > 1:
            event.data.reference.delete()
            raise Exception(f"Duplicate SKU {seller_sku} for seller {seller_id}")
```

```
[CRITICAL] algolia_service.py:241-247 (partial_update_product)
PROBLEM: `bulk_update_products` calls `algolia_partial_update(act_pid, {Fields.LIFECYCLE_STATUS: ACTIVE})` but does NOT update `Fields.IS_ACTIVE` in the same partial update. Algolia's IS_ACTIVE facet (used for filtering search results) stays `False` after a seller re-activates a product until the next full reindex via trigger.
FIX:
```python
algolia_partial_update(act_pid, {
    Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.ACTIVE,
    Fields.IS_ACTIVE: True,  # sync computed facet
})
# And for pause/archive actions, set IS_ACTIVE: False in batch.update payload
```

```
[HIGH] product_repository.dart:466-474
PROBLEM: `updateProduct` writes directly to Firestore but never re-denormalizes `shipFromCity`, `shipFromProvince`, `shipFromCountry` when warehouseIds change. Product cards show stale location data after a seller updates their warehouse assignment.
FIX: In `updateProduct`, detect if `data` contains `Fields.warehouseIds`; if so, re-run the warehouse fetch + denormalization block (same as in `addProduct` lines 50-88) and merge the resulting `shipFrom*` fields into the sanitized map before writing.
```

```
[HIGH] models/product.py:569
PROBLEM: `validate_shipping_source` only rejects "neither sellerAddress nor warehouseIds"; it silently accepts BOTH provided simultaneously — undefined behavior at product display time (which address wins?).
FIX:
```python
@model_validator(mode="after")
def validate_shipping_source(self) -> "ProductCreate":
    if not self.isDigital:
        has_addr = bool(self.sellerAddress)
        has_wh = bool(self.warehouseIds)
        if has_addr and has_wh:
            raise ValueError("Provide either sellerAddress OR warehouseIds, not both")
        if not has_addr and not has_wh:
            raise ValueError("A product must have either a sellerAddress or at least one warehouseId")
    return self
```

```
[HIGH] algolia_service.py:36-39
PROBLEM: Algolia client is initialized at module level on cold start. If `get_algolia_app_id()` or `get_algolia_write_api_key()` returns `None` (Secret Manager not ready), `algolia_client` silently becomes `None` and ALL subsequent index/delete calls are no-ops, failing open without any alerting.
FIX: Raise a hard error on None credentials, or use lazy initialization:
```python
_algolia_client = None
def _get_algolia_client():
    global _algolia_client
    if _algolia_client is None:
        app_id, api_key = get_algolia_app_id(), get_algolia_write_api_key()
        if not app_id or not api_key:
            raise RuntimeError("Algolia credentials not configured")
        _algolia_client = SearchClient(app_id, api_key)
    return _algolia_client
```

```
[HIGH] products.py:3526-3565 (_track_price_history)
PROBLEM: Function does a read (`prod_snap = prod_ref.get()`) then a write outside any transaction. Under concurrent product updates, two triggers can read the same priceHistory list, both append, and one silently overwrites the other — losing a price change record.
FIX: Use a Firestore transaction:
```python
@firestore.transactional
def _update_history(transaction, prod_ref, new_entry):
    snap = prod_ref.get(transaction=transaction)
    existing = list((snap.to_dict() or {}).get(Fields.PRICE_HISTORY, []))
    existing.append(new_entry)
    transaction.update(prod_ref, {Fields.PRICE_HISTORY: existing[-30:]})
txn = get_db().transaction()
_update_history(txn, prod_ref, new_entry)
```

```
[HIGH] product_repository.dart:466-474
PROBLEM: `updateProduct` does not strip `sellerId`, `createdAt`, or `lifecycleStatus` from the update map — a malicious or buggy client could change ownership or override admin-set lifecycle status via a direct `.update()` if Firestore rules are misconfigured.
FIX: In `sanitizeProductForFirestore` (or at the start of `updateProduct`), always remove server-controlled fields:
```dart
const _serverControlledFields = [Fields.sellerId, Fields.createdAt, Fields.lifecycleStatus, Fields.rating, Fields.ratingCount];
for (final f in _serverControlledFields) { sanitized.remove(f); }
```
Then enforce the same list in Firestore rules.
```

```
[MEDIUM] algolia_service.py:321-350 (batch_index_products)
PROBLEM: A single `save_objects()` failure drops the entire batch — no per-item retry, no partial success tracking, and no DLQ logging for the failed batch. At 100M+ products/year, silent batch failures are high-cost.
FIX: Wrap per-item or use Algolia's batch response to detect individual failures, then log each failed objectID to the DLQ via `_log_sync_failure`.
```

```
[MEDIUM] product_repository.dart:50-89 (addProduct warehouse denorm)
PROBLEM: The warehouse fetch is wrapped in a try/catch that swallows errors silently (line 86-88: `AppError.log(e, ...)`). If all warehouse docs are missing (e.g., seller deleted warehouses mid-create), the product is written with null `shipFromCity/Province/Country`, causing broken location display on cards with no user-visible error.
FIX: If `warehouseIds` is non-empty and all fetches return non-existent docs, throw:
```dart
if (primaryData == null) {
  throw Exception('None of the specified warehouses were found. Please update your warehouse selection.');
}
```

```
[MEDIUM] edit_product_viewmodel.dart:~215 (updateProduct)
PROBLEM: `freeShippingAt10Plus` state is tracked in `EditProductState` but never written into the `updateMap` / `updatedProduct.copyWith()` call — the quantity discount that grants free shipping for 10+ items is silently dropped on every product edit, reverting sellers' shipping promotions.
FIX: Include `freeShippingAt10Plus` in the delivery options rebuild logic when constructing `sanitizedDeliveryOptions`, mirroring the same pattern used in `AddProductViewModel`.
```

```
[MEDIUM] add_product_viewmodel.dart:306
PROBLEM: `estimatedShipDays` is set from `sanitizedDeliveryOptions.first.estimatedDays` — if the seller's first delivery option is "express" (1 day), the product-level estimated ship days shows 1, misleading buyers who choose standard shipping.
FIX: Derive `estimatedShipDays` from the standard delivery option specifically:
```dart
estimatedShipDays: sanitizedDeliveryOptions
    .firstWhereOrNull((o) => o.type == DeliveryTypeValues.standard)
    ?.estimatedDays ?? (sanitizedDeliveryOptions.isNotEmpty ? sanitizedDeliveryOptions.first.estimatedDays : 0),
```

```
[MEDIUM] productaddimages_screen.dart:79, 117, 122
PROBLEM: Max image count `5` is a magic integer literal in three places — violates schema rule "No magic strings/values". If the limit changes, these won't be caught by schema sync.
FIX: Replace with `BusinessRules.maxProductImages` (define in schema_constants) everywhere:
```dart
if (_imageModels.length >= BusinessRules.maxProductImages)
if (_imageModels.length < BusinessRules.maxProductImages)
```

```
[MEDIUM] product_rating_viewmodel.dart:55-58
PROBLEM: Orphaned review images after rating submission failure are only logged, never cleaned up. The TODO comment acknowledges this but leaves permanent R2 cost accumulation.
FIX: Extract image upload into the backend `submit_rating` Cloud Function — the server should receive raw image bytes (or presigned URL upload first, then pass URLs to the function which writes atomically to Firestore and doesn't return until images are confirmed referenced). Frontend should not call two separate network operations.
```

```
[LOW] models/product.py:530
PROBLEM: `sellerAddress` field description contains the word "Legacy" — violates CLAUDE.md rule #2 ("Using the word legacy is forbidden").
FIX: Change `"Legacy single-address; required if warehouseIds is not provided"` to `"Seller address; required if warehouseIds is not provided"`.
```

```
[LOW] products_provider.dart:510-512
PROBLEM: `watchFavorites` stream has a hard `.limit(BusinessRules.favoritesPageSize)` — users who favorited more products than this limit silently see a truncated favorites list with no indication that items are missing.
FIX: Either paginate favorites with a cursor, or remove the limit and add a composite index + Firestore query pagination. Alternatively, show a "Load more" CTA when `snapshot.docs.length == BusinessRules.favoritesPageSize`.
```

```
[BONUS] productaddimages_screen.dart:195-203 (Image.memory inside _ImageTile)
PROBLEM: `Image.memory(imageModel.bytes, ...)` has no `Semantics` wrapper and no `excludeSemantics`, violating frontend auditor rule #10 ("Every Image must be wrapped in `Semantics(label: '...')`").
FIX:
```dart
Semantics(
  label: isPrimary ? 'Cover photo' : 'Product photo ${index + 1}',
  child: Image.memory(imageModel.bytes, ...),
)
```

```
[BONUS] algolia_service.py:191-193
PROBLEM: When `lifecycleStatus != ACTIVE`, `index_product` calls `delete_product()` — but if the product was NEVER active (i.e., it's in `draft` state on first trigger fire), this calls Algolia delete for a non-existent objectID, wasting an API call and generating a misleading log entry.
FIX: Add a guard — only call delete if the product was previously indexed:
```python
if product_data.get(Fields.LIFECYCLE_STATUS) != ProductLifecycleStatusValues.ACTIVE:
    # Only delete if it was previously active (avoid no-op API call)
    if product_data.get("_previousLifecycleStatus") == ProductLifecycleStatusValues.ACTIVE:
        delete_product(product_id)
    return True
```
Or check this in the Firestore `on_document_updated` trigger using `event.data.before`.
```

```
[BONUS] product_repository.dart:524-527
PROBLEM: Image filename `"product_{productId}_{index}_{timestamp}.jpg"` is predictable and guessable — a malicious actor who knows a product ID can enumerate all image filenames and guess R2 object paths if the bucket has any direct access.
FIX: Add a random component using `uuid`:
```dart
final fileName = "product_${productId}_${const Uuid().v4()}.jpg";
```
Also ensure R2 bucket public access requires CDN token signing.
```

```
[BONUS] add_product_viewmodel.dart:73-74
PROBLEM: Environment check `const String.fromEnvironment('ENVIRONMENT', defaultValue: 'production') == 'dev'` in ViewModel is a backdoor that bypasses address verification and image requirements in dev mode — but this env check evaluates at compile-time (`const`). If a dev build is shipped accidentally, these bypasses are active in production APK.
FIX: Use `EnvConfig.instance.environment == Environment.dev` (runtime check) instead of `const String.fromEnvironment`, and ensure production build scripts enforce `ENVIRONMENT=production` via `--dart-define`.
```

```
[BONUS] edit_product_viewmodel.dart:93-94 (EditProductState init)
PROBLEM: `bookSourceUrl: null` hardcoded in `EditProductViewModel` constructor with comment "server-side only, seller must re-enter". If a seller edits an unrelated field (e.g., price), saves, and forgets to re-enter the book URL, the existing `bookSourceUrl` in Firestore is preserved only because `updateMap` doesn't include it when empty. But if seller enters an empty string, `state.bookSourceUrl!.isNotEmpty` returns false and the existing URL is silently NOT overwritten — correct, but fragile and untestable. The UX should explicitly tell the seller "Book URL not shown for security — leave blank to keep existing".
FIX: Add a UI hint in `editproduct_screen.dart` for book products: show a placeholder `TextField(hintText: 'Leave blank to keep existing book URL')` and document the behavior in a tooltip.
```

```
[BONUS] algolia_service.py:62-81 (ValidationError fallback in format_product_for_algolia)
PROBLEM: When Pydantic validation fails, the code falls back to indexing raw unvalidated dict data with only name/price sanitized. A malicious seller could craft a product document that passes Firestore but fails Pydantic validation, injecting unsanitized `description`, `keywords`, or `imageUrls` into Algolia and then to search result UIs.
FIX: On ValidationError, reject indexing entirely (return empty dict / raise) rather than sanitizing only two fields:
```python
except ValidationError as e:
    logger.error(f"Product {product_id} failed validation, skipping Algolia index: {e}")
    _log_sync_failure(product_id, "index", f"ValidationError: {e}", 0)
    return {}
# Caller checks if returned object is empty and skips save_object
```

```
[BONUS] products_provider.dart:33-36 (favoritedProductsProvider)
PROBLEM: `repository.fetchProductsByIds(favoriteIds.toList())` — no batch size limit. A user with 500 favorites triggers 500 parallel Firestore reads (or one `get_all` of 500 docs), costing $0.06 per read batch at scale. No pagination.
FIX: Chunk to 30 IDs per batch and paginate:
```dart
final chunks = [for (var i = 0; i < ids.length; i += 30) ids.sublist(i, min(i + 30, ids.length))];
final results = await Future.wait(chunks.map((c) => repository.fetchProductsByIds(c)));
return results.expand((x) => x).toList();
```

1. solve dart errors, fix all playwright, fix flutter integration tests, python tests, unit dart tests, then push to github main