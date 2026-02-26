


## External Manual Backlog (Future)

Console Firebase — Supprimer l'ancien app iOS com.example.orignaGta, ajouter la nouvelle avec ca.orignagta.app, re-télécharger GoogleService-Info.plist (il manquera le REVERSED_CLIENT_ID pour Google Sign-In)
Apple Developer Portal — Créer l'App ID ca.orignagta.app, activer les capabilities Push Notifications et Associated Domains
APNs — Créer une clé APNs (ou certificat) et l'uploader dans Firebase Console → Project Settings → Cloud Messaging → Apple app
Déployer le AASA — Le fichier apple-app-site-association est dans web/.well-known/ — il sera servi automatiquement si le site est hosté avec Firebase Hosting (ajouter un rewrite dans firebase.json si nécessaire avec Content-Type: application/json)
Google Sign-In — Après régénération du GoogleService-Info.plist, ajouter le REVERSED_CLIENT_ID comme URL scheme supplémentaire dans Info.plist


Voici les 3 entitlements à activer dans le Apple Developer Portal (Identifiers → ca.orignagta.app → Capabilities) :

Capability	Entitlement	Pourquoi
Push Notifications	aps-environment	Firebase Cloud Messaging / notifications de commandes
Associated Domains	com.apple.developer.associated-domains	Universal Links pour les retours Stripe (/payment-success, /seller-return, etc.)
Sign in with Apple	com.apple.developer.applesignin	Obligatoire — Apple rejette les apps qui offrent Google Sign-In sans aussi offrir Sign in with Apple (App Store Review Guideline 4.8)
Étapes dans le portail Apple :
Identifiers → Create/Edit App ID ca.orignagta.app
Cocher : ✅ Push Notifications, ✅ Associated Domains, ✅ Sign in with Apple
Keys → Créer une clé APNs → l'uploader dans Firebase Console (Project Settings → Cloud Messaging)
Profiles → Générer un Provisioning Profile de développement et de distribution avec ces capabilities
Changer aps-environment de development à production avant la soumission App Store
Note importante : Puisque vous offrez Google Sign-In, vous devrez aussi implémenter Sign in with Apple dans l'app Flutter (package sign_in_with_apple) avant de soumettre sur l'App Store — c'est une exigence Apple.

Ce qui nécessite l'Apple Developer Program ($99/an) :
Feature	Pourquoi
Push Notifications	Capability aps-environment
Universal Links (retour auto depuis Stripe)	Capability Associated Domains
Sign in with Apple	Capability + obligatoire pour l'App Store si tu offres Google Sign-In
App Store submission	Distribution via TestFlight ou App Store


cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/origna_gta && sed -i '' '/CODE_SIGN_ENTITLEMENTS = Runner\/Runner.entitlements;/d' ios/Runner.xcodeproj/project.pbxproj
Les 3 références CODE_SIGN_ENTITLEMENTS sont supprimées. Tu peux maintenant relancer flutter run. Le fichier Runner.entitlements reste dans le repo pour plus tard quand tu auras le Apple Developer Program — il suffira de réajouter les lignes dans le pbxproj.
For future manual setup:
0. google mcp integration
1. mcp for api
2. web mcp
3. docs for 1 and 2




10.**Cloud Scheduler frequency** — Cron jobs should run at the minimum effective frequency (e.g. every 5 minutes, not every minute) to reduce invocations while still meeting timing requirements.


11. mcp for store


# Add Product — Full Code Audit
**Files audited:** `Product.json`, `add_product_state.dart`, `add_product_viewmodel.dart`, `addproduct_screen.dart`, `product_repository.dart`, `supplier_config.dart`, `schema_constants.dart`

---

## 🔴 CRITICAL

### C-01 — Schema Enum Mismatch: `lifecycleStatus` missing `draft` and `under_review`
**File:** `Product.json` (line 730) vs `add_product_viewmodel.dart` (line 323)

`Product.json` defines `lifecycleStatus` enum as:
```json
["active", "inactive", "pending_review", "rejected", "archived"]
```
The code creates products with `ProductLifecycleStatusValues.draft` (`"draft"`) — **not in the schema enum**.
The code also uses `"under_review"` (in schema_constants), but the schema has `"pending_review"` instead.

**Fix:** Align the `Product.json` enum to match `ProductLifecycleStatusValues`:
```json
"enum": ["draft", "under_review", "approved", "active", "paused", "archived", "rejected"]
```
Remove `"inactive"` and `"pending_review"` — they are the old model and already deprecated in schema_constants.

---

### C-02 — Memory Leak: `_compareAtPriceController` never disposed
**File:** `addproduct_screen.dart` (line 32 declared, lines 772–807 `dispose()`)

`_compareAtPriceController` is created but completely absent from `dispose()`. All 25 other controllers are disposed. This leaks memory every time the screen is entered.

**Fix:** Add to `dispose()`:
```dart
_compareAtPriceController.dispose();
```

---

### C-03 — MVVM Violation: Business logic state in screen
**File:** `addproduct_screen.dart` (lines 71–79)

The following fields live as `setState` variables in the screen — a direct violation of the "Screens = 0 logic" architecture rule:
- `_inventoryManaged`, `_trackQuantity`, `_allowBackorder`, `_lowStockAlertEnabled` — inventory config
- `_selectedSupplierType`, `_selectedSupplierCurrency`, `_hasTracking` — supplier state
- `_selectedCategoryId`, `_selectedSubcategory` — category selection
- `_activeStep`, `_hasAttemptedSubmit`, `_discountTierError` — form flow state

These all need to move to `AddProductState` with corresponding setters on the ViewModel. The screen should only call `viewModel.setX()` and read `state.x`.

---

## 🟠 HIGH

### H-01 — compareAtPrice validation inconsistency between screen and ViewModel
**Files:** `addproduct_screen.dart` (line 292), `add_product_viewmodel.dart` (line 109)

Screen validator passes when `cap > price` (any positive margin). ViewModel rejects when `compareAtPrice - price < 0.50` (must differ by ≥ $0.50). A user entering $10.30 price with $10.60 compare-at passes the form validator but gets a ViewModel error snackbar. The UX is broken — the inline validator should enforce the same $0.50 rule as the ViewModel.

**Fix in screen validator:**
```dart
if (cap - currentPrice < 0.50) return 'product.compare_at_price_must_be_higher'.tr();
```

---

### H-02 — Magic strings: hardcoded English in screen
**File:** `addproduct_screen.dart`

Multiple places use hardcoded English instead of translation keys:
- Line 883: `labelText: 'Category'` → use `'product.category'.tr()`
- Line 924: `validator: (v) => v == null ? 'Required' : null` → use `'common.required'.tr()`
- Lines 350–358: SKU label, hint, and info text all hardcoded in English with no `.tr()` keys

This breaks i18n (French for Quebec per Canadian compliance requirements).

---

### H-03 — `freeShippingAt10Plus` is dead state that never persists
**Files:** `add_product_state.dart`, `add_product_viewmodel.dart` (line 427), `addproduct_screen.dart` (line 1494)

The field exists in `AddProductState`, has a setter in the ViewModel, is referenced in the screen (line 1008 builds a delivery option for it), but the comment at line 1494 says "removed — never stored/used on the backend." The Product schema has no `freeShippingAt10Plus` field. The state field and ViewModel setter are dead code producing confusion.

**Fix:** Remove `freeShippingAt10Plus` from `AddProductState`, `copyWith()`, and the ViewModel setter. Keep the comment in screen explaining the deferred feature.

---

### H-04 — `status` parameter in `addProduct()` is dead parameter
**File:** `add_product_viewmodel.dart` (line 72)

The method accepts a `status` parameter but:
1. The screen never passes it (line 1800)
2. It's never used inside `addProduct()` — it's not assigned to the Product model

**Fix:** Remove the parameter entirely since `lifecycleStatus` is set server-side.

---

### H-05 — `taxCode` passes empty string instead of null
**File:** `addproduct_screen.dart` (line 1819)

```dart
taxCode: _taxCodeController.text.trim(),
```
When the field is empty, this passes `""` (empty string) to the ViewModel and then to the Product model. The viewmodel `isValidTaxCode("")` needs to accept empty as null-equivalent OR the screen should normalize:
```dart
taxCode: _taxCodeController.text.trim().isEmpty ? null : _taxCodeController.text.trim(),
```

---

## 🟡 MEDIUM

### M-01 — Pagination false positive on exact-count pages
**File:** `product_repository.dart` (line 180)

```dart
final hasMore = snapshot.docs.length >= pageSize;
```
If exactly `pageSize` documents match, `hasMore = true` even if there are no more pages. This triggers an empty network request on the next page load.

**Fix:** Fetch `pageSize + 1`, set `hasMore = docs.length > pageSize`, then trim to `pageSize` before returning.

---

### M-02 — `sellerAddress: null` for warehouse products violates schema required field
**File:** `add_product_viewmodel.dart` (lines 307–318)

When `useWarehouses == true`, `sellerAddress: null` is passed to `models.Product()`. But the schema marks `sellerAddress` as required. The Cloud Function must handle this explicitly (denormalize from warehouse address). This should be documented with an explicit comment AND the schema should mark `sellerAddress` as nullable when `warehouseIds` is present — or use a different field (e.g. `warehouseAddress`).

---

### M-03 — `bookSourceUrl` has no length or format validation
**File:** `add_product_viewmodel.dart` (lines 207–214)

Only checks for `https://` prefix. No max length check (could be thousands of characters), no URL format validation. A malformed or excessively long URL would reach the backend.

**Fix:**
```dart
if (state.bookSourceUrl!.length > 500) {
  state = state.copyWith(errorMessage: 'product.book_url_too_long'.tr());
  return;
}
// Optional: add Uri.tryParse() validation
```

---

### M-04 — `approvalStatus` and `isActive` dead fields remain in `Product.json`
**File:** `Product.json` (lines 512–530)

`schema_constants.dart` marks both `isActive` (line 626) and `approvalStatus` (line 627) as `DEPRECATED — use lifecycleStatus`. Yet both fields are still fully defined in the schema. This creates confusion about which field is authoritative and risks new code accidentally using them.

**Fix:** Remove `approvalStatus` and `isActive` from `Product.json`. Remove `ProductApprovalStatusValues` and `ProductStatusValues` from `schema_constants.dart` since they're already marked deprecated and `ProductLifecycleStatusValues` covers all states.

---

### M-05 — Dialog TextEditingControllers never disposed
**File:** `addproduct_screen.dart` (lines 2412–2413, 2580–2581)

`_showAddDialog()` and `_showEditDialog()` create `TextEditingController` instances inline without ever calling `.dispose()`. While Flutter will eventually GC them, best practice is to dispose in the dialog's close action or use `addPostFrameCallback`.

**Fix:** Dispose controllers when dialog is popped:
```dart
.then((_) { nameCtrl.dispose(); valuesCtrl.dispose(); });
```

---

### M-06 — `_compressImages` runs sequentially, not in parallel
**File:** `add_product_viewmodel.dart` (lines 621–628)

```dart
for (var model in imageModels) {
  final compressed = await _validateAndCompressImage(model.bytes);
  ...
}
```
Images are compressed one-by-one. Since each uses `compute()` (isolate), they could safely run in parallel.

**Fix:**
```dart
final results = await Future.wait(
  imageModels.map((m) => _validateAndCompressImage(m.bytes)),
);
return results.whereType<Uint8List>().toList();
```

---

## 🟢 LOW / BONUS

### L-01 — `testImageUrls` bypass not validated in Cloud Function
**File:** `product_repository.dart` (lines 89–91), `add_product_viewmodel.dart` (line 251)

The `testImageUrls` bypass is gated on `isDevOrTestRun` in the ViewModel before the call, but the repository sends `testImageUrls` to the Cloud Function regardless. Verify the Cloud Function also checks environment (`ENVIRONMENT != production`) before accepting `testImageUrls` to prevent sellers from bypassing image upload on prod.

---

### L-02 — `Oberlo` deprecated entry adds confusion
**File:** `supplier_config.dart` (line 163–179)

`Oberlo` is listed with `isActive: false` and `deprecationNote: 'Permanently shut down by Shopify in June 2022.'`. Since `getSupplierDropdownItems()` filters by `isActive`, it never shows. But it still clutters the registry. Remove it entirely — sellers seeing it in source code is misleading for a new app that hasn't launched.

---

### L-03 — `fetchProductById` silently returns null for non-active products
**File:** `product_repository.dart` (line 123)

```dart
if (data[Fields.lifecycleStatus] != ProductLifecycleStatusValues.active) return null;
```
Admins and sellers need to fetch products in `under_review`, `draft`, etc. states. This single method silently hides them, which may cause confusing "product not found" errors in admin/seller flows. Add an optional `bypassLifecycleFilter` parameter for privileged callers.

---

### L-04 — `getUploadUrlInfo` makes one Cloud Function call per image
**File:** `product_repository.dart` (lines 234–244)

Each `_uploadSingleImage` call triggers a separate Cloud Function invocation to get a single upload URL. The Cloud Function (`uploadProductImages`) already accepts an array of `fileNames`. Batch all URLs in one call, then upload in parallel.

---

### L-05 — Step indicator hardcoded to 5 steps
**File:** `addproduct_screen.dart` (line 192)

```dart
List.generate(5, (i) { ... })
```
The number of sections is hardcoded. When sections are added/removed, this silently stays at 5. Extract to a constant or compute from section count.

---

## Summary Table

| ID | Severity | File | Issue |
|----|----------|------|-------|
| C-01 | 🔴 Critical | Product.json | lifecycleStatus enum missing `draft`/`under_review` |
| C-02 | 🔴 Critical | addproduct_screen.dart | `_compareAtPriceController` never disposed |
| C-03 | 🔴 Critical | addproduct_screen.dart | MVVM violation: ~10 business state vars in screen |
| H-01 | 🟠 High | screen + viewmodel | compareAtPrice validation inconsistency ($0.50 rule) |
| H-02 | 🟠 High | addproduct_screen.dart | Magic strings not using translation keys |
| H-03 | 🟠 High | state + viewmodel + screen | `freeShippingAt10Plus` is dead unreachable code |
| H-04 | 🟠 High | add_product_viewmodel.dart | `status` parameter is dead, never used |
| H-05 | 🟠 High | addproduct_screen.dart | taxCode passes `""` instead of `null` |
| M-01 | 🟡 Medium | product_repository.dart | Pagination `hasMore` false positive |
| M-02 | 🟡 Medium | add_product_viewmodel.dart | `sellerAddress: null` for warehouse products |
| M-03 | 🟡 Medium | add_product_viewmodel.dart | `bookSourceUrl` no length/format validation |
| M-04 | 🟡 Medium | Product.json + schema_constants | Dead `approvalStatus` + `isActive` fields in schema |
| M-05 | 🟡 Medium | addproduct_screen.dart | Dialog TextEditingControllers never disposed |
| M-06 | 🟡 Medium | add_product_viewmodel.dart | Sequential image compression (should be parallel) |
| L-01 | 🟢 Low | repository + viewmodel | `testImageUrls` bypass not server-validated |
| L-02 | 🟢 Low | supplier_config.dart | Oberlo dead entry clutters registry |
| L-03 | 🟢 Low | product_repository.dart | `fetchProductById` blocks admin/seller access |
| L-04 | 🟢 Low | product_repository.dart | One Cloud Function call per image URL |
| L-05 | 🟢 Low | addproduct_screen.dart | Stepper count hardcoded to 5 |