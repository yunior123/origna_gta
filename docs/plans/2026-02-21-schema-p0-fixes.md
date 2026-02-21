# Schema P0 Fixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix all 6 P0 schema issues before launch — broken index, missing variant tracking, no order event log, duplicate delivery status field, missing idempotencyKey, and orderStatus dimension leak.

**Architecture:** Following production patterns from Medusa.js, Saleor, and Shopify — subcollection for events (not embedded array), auto-generated cart item IDs (not productId as key), orthogonal status fields. Cross-stack changes hit Python models + Dart models + schema_constants + database_schema.json atomically.

**Tech Stack:** Python/Pydantic, Dart/Freezed, Firestore, `functions/schema_constants.py` ↔ `origna_gta/lib/core/schema/schema_constants.dart` ↔ `docs/database_schema.json`

**Root files for this plan:**
- `functions/models/order.py`
- `origna_gta/lib/models/generated/order_models.dart`
- `origna_gta/lib/models/models.dart`
- `functions/schema_constants.py`
- `origna_gta/lib/core/schema/schema_constants.dart`
- `origna_gta/lib/core/repositories/cart_repository.dart`
- `origna_gta/lib/features/cart/cart_provider.dart`
- `origna_gta/lib/utils/utils.dart`
- `docs/database_schema.json`
- `functions/tests/conftest.py`

---

## Task 1: Fix broken index field name (`authorizationExpiresAt` → `expiresAt`)

**Files:**
- Modify: `docs/database_schema.json` (line ~1387)

**Context:** The orders index references field `authorizationExpiresAt` but the actual stored field is `expiresAt`. The cron that expires unpaid authorizations queries this index → returns zero results → all expired authorizations silently stay open.

**Step 1: Find and fix the index definition**

In `docs/database_schema.json`, find the composite index block containing `authorizationExpiresAt` (line ~1387) and rename it to `expiresAt`.

Before:
```json
{
  "collectionGroup": "orders",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "paymentStatus", "order": "ASCENDING" },
    { "fieldPath": "authorizationExpiresAt", "order": "ASCENDING" }
  ]
}
```

After:
```json
{
  "collectionGroup": "orders",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "paymentStatus", "order": "ASCENDING" },
    { "fieldPath": "expiresAt", "order": "ASCENDING" }
  ]
}
```

**Step 2: Check if firestore.indexes.json also has this field**

```bash
grep -rn "authorizationExpiresAt" /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/
```

Fix any additional occurrences.

**Step 3: Verify fix**

```bash
grep -rn "authorizationExpiresAt" /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/
```

Expected: zero results.

**Step 4: Commit**

```bash
git add docs/database_schema.json
git commit -m "fix: rename authorizationExpiresAt to expiresAt in order index"
```

---

## Task 2: Add `idempotencyKey` to Order schema fields

**Files:**
- Modify: `docs/database_schema.json` (orders collection fields section)
- Modify: `functions/schema_constants.py` (already has `IDEMPOTENCY_KEY = "idempotencyKey"` at line 1296 — just verify it's in the Fields class)

**Context:** The orders index uses `userId + idempotencyKey` but `idempotencyKey` is not defined as a field in the orders collection schema. It needs to be formally declared so the index is meaningful.

**Step 1: Add field to database_schema.json orders collection**

Find the orders collection fields section in `docs/database_schema.json` and add:
```json
"idempotencyKey": {
  "type": "string",
  "description": "Client-generated idempotency key to prevent duplicate order creation"
}
```

**Step 2: Verify `IDEMPOTENCY_KEY` is in `Fields` class in schema_constants.py**

```bash
grep -n "IDEMPOTENCY_KEY" /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/functions/schema_constants.py
```

If it's in a different class (e.g., `ApiKeys`), move it to `Fields` or add a mirror in `Fields`.

**Step 3: Verify `idempotencyKey` constant in Dart**

```bash
grep -n "idempotencyKey" /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/origna_gta/lib/core/schema/schema_constants.dart
```

If missing, add to `Fields` class:
```dart
static const idempotencyKey = 'idempotencyKey';
```

**Step 4: Commit**

```bash
git add docs/database_schema.json origna_gta/lib/core/schema/schema_constants.dart
git commit -m "fix: add idempotencyKey to Order schema fields"
```

---

## Task 3: Remove `deliveryStatus` from OrderItem — Python side

**Files:**
- Modify: `functions/models/order.py`
- Modify: `functions/schema_constants.py`
- Modify: `functions/tests/conftest.py`
- Modify: `functions/tests/test_payment_integration.py`
- Modify: `functions/scripts/seed_dev_admin_data.py`
- Modify: `docs/database_schema.json`

**Context:** `OrderItem` has two parallel status fields: `status` (canonical) and `deliveryStatus` (deprecated). Both are written on every update. If one write fails, they diverge permanently. `deliveryStatus` must be removed from the model. `status` is the single source of truth.

**Step 1: Write the failing test**

In `functions/tests/test_payment_integration.py`, add:

```python
def test_order_item_has_no_delivery_status_field():
    """OrderItem model must not have deliveryStatus — use status only."""
    item = OrderItem(
        productId="prod_1",
        name="Test",
        description="",
        price=10.0,
        quantity=1,
        imageUrls=["https://example.com/img.jpg"],
        sellerId="seller_1",
    )
    item_dict = item.model_dump()
    assert "deliveryStatus" not in item_dict, "deliveryStatus must be removed — use status only"
```

**Step 2: Run test to verify it fails**

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/functions
pytest tests/test_payment_integration.py::test_order_item_has_no_delivery_status_field -v
```

Expected: FAIL — `deliveryStatus` currently exists in the model.

**Step 3: Remove `deliveryStatus` from OrderItem Python model**

In `functions/models/order.py`:

Remove from `model_config.json_schema_extra.example`:
```python
Fields.DELIVERY_STATUS: "pending",  # Deprecated — use 'status' instead
```

The `OrderItem` class in `order.py` does NOT currently have a `deliveryStatus` field as a Pydantic field — it only appears in the example config. Verify:

```bash
grep -n "deliveryStatus" /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/functions/models/order.py
```

Remove any remaining references.

**Step 4: Update `DELIVERY_STATUS` constant comment in schema_constants.py**

In `functions/schema_constants.py` line 449, change:
```python
DELIVERY_STATUS = "deliveryStatus"  # Parallel status field (both STATUS and DELIVERY_STATUS are written)
```
to:
```python
DELIVERY_STATUS = "deliveryStatus"  # DEPRECATED — kept for reading legacy documents only. Write 'status' field.
```

**Step 5: Fix conftest.py — remove deliveryStatus from test fixtures**

In `functions/tests/conftest.py`, find all occurrences of `"deliveryStatus": "pending"` (lines ~441, ~510, ~902) and remove them. The fixtures should only use `"status": "pending"`.

**Step 6: Fix test_payment_integration.py**

In `functions/tests/test_payment_integration.py` line 82, change:
```python
{"sellerId": "seller_1", "deliveryStatus": DeliveryStatus.PENDING, ...}
```
to:
```python
{"sellerId": "seller_1", "status": DeliveryStatusValues.PENDING, ...}
```

At line 355, change:
```python
"items": [{"productId": "prod_1", "deliveryStatus": DeliveryStatus.DELIVERED}]
```
to:
```python
"items": [{"productId": "prod_1", "status": DeliveryStatusValues.DELIVERED}]
```

**Step 7: Fix seed_dev_admin_data.py**

In `functions/scripts/seed_dev_admin_data.py` line 197, change:
```python
Fields.DELIVERY_STATUS: "pending",
```
to:
```python
Fields.STATUS: DeliveryStatusValues.PENDING,
```

**Step 8: Remove deliveryStatus from database_schema.json OrderItem fields**

Find `deliveryStatus` in the `orders` collection `items` array field definition and remove it (or mark as deprecated with a comment).

**Step 9: Run test to verify it passes**

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/functions
pytest tests/test_payment_integration.py::test_order_item_has_no_delivery_status_field -v
```

Expected: PASS

**Step 10: Run full backend test suite to catch regressions**

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/functions
pytest tests/ -v --tb=short 2>&1 | tail -30
```

Expected: all previously passing tests still pass.

**Step 11: Commit**

```bash
git add functions/models/order.py functions/schema_constants.py functions/tests/conftest.py functions/tests/test_payment_integration.py functions/scripts/seed_dev_admin_data.py docs/database_schema.json
git commit -m "fix: remove deprecated deliveryStatus from OrderItem — use status only"
```

---

## Task 4: Remove `deliveryStatus` from OrderItem — Dart side

**Files:**
- Modify: `origna_gta/lib/models/generated/order_models.dart`
- Modify: `origna_gta/lib/core/schema/schema_constants.dart`
- Modify: `origna_gta/lib/features/cart/cart_provider.dart`

**Context:** The Dart `OrderItem` Freezed model has `deliveryStatus: DeliveryStatus` (a typed enum) as a parallel to `status: String`. The `_parseOrderItem` function merges them. Both must be removed. After this task, `status: String` is the single source of truth.

**Step 1: Remove `deliveryStatus` field from `OrderItem` Freezed model**

In `origna_gta/lib/models/generated/order_models.dart`, find the `@Freezed` `OrderItem` factory (line ~444-487):

Remove this line:
```dart
@Default(DeliveryStatus.pending) DeliveryStatus deliveryStatus, // Parallel enum field for type-safe access
```

**Step 2: Remove `deliveryStatus` from `_parseOrderItem`**

In `origna_gta/lib/models/generated/order_models.dart` line 56, remove:
```dart
deliveryStatus: _parseDeliveryStatus(map[Fields.deliveryStatus]),
```

Also remove the fallback merge logic at line 52-55:
```dart
status: _safeString(
  (map[Fields.status] == null || map[Fields.status].toString().isEmpty) ? map[Fields.deliveryStatus] : map[Fields.status],
  DeliveryStatusValues.pending,
),
```

Replace with the clean version:
```dart
status: _safeString(map[Fields.status], DeliveryStatusValues.pending),
```

**Step 3: Remove `_parseDeliveryStatus` helper and `DeliveryStatus` enum if unused**

Check if `DeliveryStatus` enum and `_parseDeliveryStatus` are used anywhere else:
```bash
grep -rn "DeliveryStatus\b\|_parseDeliveryStatus" /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/origna_gta/lib/ | grep -v "DeliveryStatusValues"
```

If only used in `order_models.dart`, remove both the `_parseDeliveryStatus` function (lines 26-38) and the `DeliveryStatus` enum from `schema_constants.dart`.

**Step 4: Remove `deliveryStatus` constant from Dart schema_constants**

In `origna_gta/lib/core/schema/schema_constants.dart` line 727:
```dart
static const deliveryStatus = 'deliveryStatus';
```
Change comment to:
```dart
static const deliveryStatus = 'deliveryStatus'; // DEPRECATED — read-only for legacy docs
```

**Step 5: Fix `cart_provider.dart` — remove deliveryStatus usage**

In `origna_gta/lib/features/cart/cart_provider.dart` line 49 and 149, change:
```dart
deliveryStatus: DeliveryStatusValues.pending,
```
Remove these lines entirely (the field no longer exists on `OrderItem`).

**Step 6: Regenerate Freezed files**

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/origna_gta
dart run build_runner build --delete-conflicting-outputs
```

**Step 7: Verify compile**

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/origna_gta
flutter analyze lib/models/generated/order_models.dart lib/features/cart/cart_provider.dart
```

Expected: no errors.

**Step 8: Commit**

```bash
git add origna_gta/lib/models/generated/order_models.dart origna_gta/lib/core/schema/schema_constants.dart origna_gta/lib/features/cart/cart_provider.dart origna_gta/lib/models/generated/order_models.freezed.dart origna_gta/lib/models/generated/order_models.g.dart
git commit -m "fix: remove deprecated deliveryStatus from Dart OrderItem — use status only"
```

---

## Task 5: Add variant fields to `OrderItem` — Python side

**Files:**
- Modify: `functions/models/order.py`
- Modify: `functions/schema_constants.py` (verify constants exist — they do at lines 609-611)
- Modify: `docs/database_schema.json`

**Context:** `OrderItem` has no `variantId`, `variantTitle`, `variantOptions`, or `variantSku` fields. Medusa, Saleor, and Shopify all snapshot these at order creation. Without them, variant purchases are ambiguous — you cannot tell which size/color was purchased from the order record.

**Step 1: Write the failing test**

```python
def test_order_item_stores_variant_snapshot():
    """OrderItem must snapshot variant selection for traceability."""
    item = OrderItem(
        productId="prod_1",
        name="Blue T-Shirt",
        description="",
        price=25.0,
        quantity=1,
        imageUrls=["https://example.com/img.jpg"],
        sellerId="seller_1",
        variantId="var_m_blue",
        variantTitle="Size: M / Color: Blue",
        variantOptions={"Size": "M", "Color": "Blue"},
        variantSku="TSHIRT-M-BLUE",
    )
    assert item.variantId == "var_m_blue"
    assert item.variantOptions == {"Size": "M", "Color": "Blue"}
    assert item.variantSku == "TSHIRT-M-BLUE"

def test_order_item_variant_fields_are_optional():
    """Non-variant products must work without variant fields."""
    item = OrderItem(
        productId="prod_1",
        name="Simple Product",
        description="",
        price=10.0,
        quantity=1,
        imageUrls=["https://example.com/img.jpg"],
        sellerId="seller_1",
    )
    assert item.variantId is None
    assert item.variantOptions is None
```

**Step 2: Run tests to verify they fail**

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/functions
pytest tests/test_payment_integration.py::test_order_item_stores_variant_snapshot tests/test_payment_integration.py::test_order_item_variant_fields_are_optional -v
```

Expected: FAIL — fields don't exist yet.

**Step 3: Add variant fields to `OrderItem` in `order.py`**

In `functions/models/order.py`, after the `taxCode` field (around line 104), add:

```python
# Variant tracking (immutable snapshot at order creation — matches Medusa/Saleor/Shopify pattern)
variantId: str | None = Field(default=None, description="Variant ID at time of purchase")
variantTitle: str | None = Field(default=None, max_length=255, description="Human-readable variant label e.g. 'Size: M / Color: Blue'")
variantOptions: dict[str, str] | None = Field(default=None, description="Variant option key-value map e.g. {'Size': 'M', 'Color': 'Blue'}")
variantSku: str | None = Field(default=None, max_length=100, description="Variant SKU snapshotted at purchase time")
```

**Step 4: Add fields to `database_schema.json` OrderItem**

In the orders collection, inside the `items` array item schema, add:
```json
"variantId": {
  "type": ["string", "null"],
  "description": "Variant ID at time of purchase (null for non-variant products)"
},
"variantTitle": {
  "type": ["string", "null"],
  "description": "Human-readable variant label e.g. 'Size: M / Color: Blue'"
},
"variantOptions": {
  "type": ["object", "null"],
  "description": "Variant option key-value map e.g. {'Size': 'M', 'Color': 'Blue'}"
},
"variantSku": {
  "type": ["string", "null"],
  "description": "Variant SKU snapshotted at purchase time"
}
```

**Step 5: Run tests to verify they pass**

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/functions
pytest tests/test_payment_integration.py::test_order_item_stores_variant_snapshot tests/test_payment_integration.py::test_order_item_variant_fields_are_optional -v
```

Expected: PASS

**Step 6: Commit**

```bash
git add functions/models/order.py docs/database_schema.json
git commit -m "feat: add variantId/variantTitle/variantOptions/variantSku to OrderItem"
```

---

## Task 6: Add variant fields to `OrderItem` — Dart side

**Files:**
- Modify: `origna_gta/lib/models/generated/order_models.dart`

**Context:** Mirror the Python `OrderItem` variant fields in the Dart `OrderItem` Freezed model. The `Fields.variantId` constant already exists in `schema_constants.dart` line 933.

**Step 1: Add variant fields to `OrderItem` Freezed factory**

In `origna_gta/lib/models/generated/order_models.dart`, inside the `OrderItem` factory (after `fulfillmentWarehouseId`), add:

```dart
// Variant snapshot (immutable at order creation — Medusa/Saleor/Shopify pattern)
String? variantId,
String? variantTitle,
Map<String, String>? variantOptions,
String? variantSku,
```

**Step 2: Add parsing to `_parseOrderItem`**

In `_parseOrderItem`, after the `fulfillmentWarehouseId` line, add:

```dart
variantId: map[Fields.variantId] != null ? _safeString(map[Fields.variantId]) : null,
variantTitle: map[Fields.variantTitle] != null ? _safeString(map[Fields.variantTitle]) : null,
variantOptions: map[Fields.variantOptions] != null
    ? Map<String, String>.from(map[Fields.variantOptions] as Map)
    : null,
variantSku: map[Fields.variantSku] != null ? _safeString(map[Fields.variantSku]) : null,
```

**Step 3: Add missing constants to Dart `Fields` if needed**

Check that these exist in `schema_constants.dart`:
```bash
grep -n "variantTitle\|variantOptions\|variantSku" /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/origna_gta/lib/core/schema/schema_constants.dart
```

If missing, add to `Fields` class:
```dart
static const variantTitle = 'variantTitle';
static const variantOptions = 'variantOptions';
static const variantSku = 'variantSku';
```

**Step 4: Regenerate Freezed files**

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/origna_gta
dart run build_runner build --delete-conflicting-outputs
```

**Step 5: Verify compile**

```bash
flutter analyze origna_gta/lib/models/generated/order_models.dart
```

**Step 6: Commit**

```bash
git add origna_gta/lib/models/generated/order_models.dart origna_gta/lib/core/schema/schema_constants.dart origna_gta/lib/models/generated/order_models.freezed.dart origna_gta/lib/models/generated/order_models.g.dart
git commit -m "feat: add variant snapshot fields to Dart OrderItem"
```

---

## Task 7: Add `version: int` to `Order` — Python + Dart

**Files:**
- Modify: `functions/models/order.py`
- Modify: `origna_gta/lib/models/generated/order_models.dart`
- Modify: `functions/schema_constants.py`
- Modify: `origna_gta/lib/core/schema/schema_constants.dart`
- Modify: `docs/database_schema.json`

**Context:** Medusa and Commercetools both put `version: int = 1` on Order for optimistic concurrency control — prevents two simultaneous Cloud Functions (Stripe webhook + cron) from double-processing. Incremented inside every Firestore transaction that mutates order state.

**Step 1: Add `VERSION` constant to `Fields` in schema_constants.py**

In `functions/schema_constants.py`, inside the `Fields` class, add:
```python
VERSION = "version"  # Optimistic concurrency version (Medusa/Commercetools pattern), starts at 1
```

**Step 2: Add `version` to `Order` Pydantic model**

In `functions/models/order.py`, in the `Order` class, add near the top of the fields:
```python
version: int = Field(default=1, ge=1, description="Optimistic concurrency version — increment on every state mutation")
```

**Step 3: Add `version` to `database_schema.json` orders collection**

```json
"version": {
  "type": "integer",
  "minimum": 1,
  "default": 1,
  "description": "Optimistic concurrency version (Medusa/Commercetools pattern) — incremented on every state mutation inside a Firestore transaction"
}
```

**Step 4: Add constant to Dart schema_constants.dart**

```dart
static const version = 'version'; // Optimistic concurrency version, starts at 1
```

**Step 5: Add `version` to Dart `Order` Freezed model**

In `origna_gta/lib/models/generated/order_models.dart`, in the `Order` factory, add:
```dart
@Default(1) int version,
```

And in the `_parseOrder` function, add:
```dart
version: _safeInt(map[Fields.version], 1),
```

**Step 6: Regenerate Freezed**

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/origna_gta
dart run build_runner build --delete-conflicting-outputs
```

**Step 7: Write Python test**

```python
def test_order_has_version_field():
    """Order must have version field starting at 1 for optimistic concurrency."""
    # (build minimal Order using your conftest fixture or build manually)
    # verify version defaults to 1
    from functions.models.order import Order
    # Use conftest create_test_order helper or build manually
    # Example:
    order_data = {... minimal valid order ...}
    order = Order(**order_data)
    assert order.version == 1
```

Note: Use existing test fixtures from conftest.py to build a valid order. Don't hardcode all fields.

**Step 8: Commit**

```bash
git add functions/models/order.py functions/schema_constants.py docs/database_schema.json origna_gta/lib/models/generated/order_models.dart origna_gta/lib/core/schema/schema_constants.dart origna_gta/lib/models/generated/order_models.freezed.dart origna_gta/lib/models/generated/order_models.g.dart
git commit -m "feat: add version field to Order for optimistic concurrency control"
```

---

## Task 8: Restructure cart — auto-generated doc IDs + variant snapshot

**Files:**
- Modify: `origna_gta/lib/models/models.dart` (`CartModel`, `CartItemModel`)
- Modify: `origna_gta/lib/core/repositories/cart_repository.dart`
- Modify: `origna_gta/lib/utils/utils.dart` (`addToCart` function)
- Modify: `origna_gta/lib/features/cart/cart_provider.dart`
- Modify: `functions/schema_constants.py`
- Modify: `origna_gta/lib/core/schema/schema_constants.dart`
- Modify: `docs/database_schema.json`

**Context:** Current cart uses `productId` as the Firestore document ID. This prevents a buyer from adding the same product in two different variants (e.g., "Size M Blue" + "Size L Red"). All production platforms (Medusa, Saleor, Shopify) use auto-generated line item IDs with `variantId` as a field. Also need to add `priceSnapshot` and variant fields.

**Step 1: Add new constants to schema_constants.py**

In `functions/schema_constants.py`, inside `Fields`:
```python
CART_ITEM_ID = "cartItemId"  # Auto-generated cart item doc ID (replaces productId-as-docId)
PRICE_SNAPSHOT = "priceSnapshot"  # Price in cents at time of add-to-cart
VARIANT_TITLE = "variantTitle"
VARIANT_SKU = "variantSku"
VARIANT_OPTIONS = "variantOptions"
```

(Check first — some may already exist. `VARIANT_ID` already exists at line 610.)

**Step 2: Add new constants to Dart schema_constants.dart**

```dart
static const cartItemId = 'cartItemId';
static const priceSnapshot = 'priceSnapshot';
static const variantTitle = 'variantTitle';
static const variantSku = 'variantSku';
static const variantOptions = 'variantOptions';
```

(Check first — `variantId` already exists at line 933.)

**Step 3: Update `CartModel` in `origna_gta/lib/models/models.dart`**

Replace the existing `CartModel` (lines 312-337) with:

```dart
class CartModel {
  final String cartItemId;   // auto-generated Firestore document ID
  final String productId;
  final int quantity;
  final DateTime createdAt;
  final String? variantId;
  final String? variantTitle;
  final Map<String, String>? variantOptions;
  final String? variantSku;
  final int? priceSnapshot; // price in cents at add-to-cart time

  CartModel({
    required this.cartItemId,
    required this.productId,
    this.quantity = 1,
    required this.createdAt,
    this.variantId,
    this.variantTitle,
    this.variantOptions,
    this.variantSku,
    this.priceSnapshot,
  });

  factory CartModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parsedDate;
    final rawDate = map[Fields.createdAt];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else {
      parsedDate = DateTime.now();
    }
    return CartModel(
      cartItemId: docId ?? map[Fields.cartItemId] ?? '',
      productId: map[Fields.productId] ?? '',
      quantity: (map[Fields.quantity] as num?)?.toInt() ?? 1,
      createdAt: parsedDate,
      variantId: map[Fields.variantId] as String?,
      variantTitle: map[Fields.variantTitle] as String?,
      variantOptions: map[Fields.variantOptions] != null
          ? Map<String, String>.from(map[Fields.variantOptions] as Map)
          : null,
      variantSku: map[Fields.variantSku] as String?,
      priceSnapshot: (map[Fields.priceSnapshot] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      Fields.cartItemId: cartItemId,
      Fields.productId: productId,
      Fields.quantity: quantity,
      Fields.createdAt: Timestamp.fromDate(createdAt),
      if (variantId != null) Fields.variantId: variantId,
      if (variantTitle != null) Fields.variantTitle: variantTitle,
      if (variantOptions != null) Fields.variantOptions: variantOptions,
      if (variantSku != null) Fields.variantSku: variantSku,
      if (priceSnapshot != null) Fields.priceSnapshot: priceSnapshot,
    };
  }
}
```

**Step 4: Update `CartItemModel` in `origna_gta/lib/models/models.dart`**

Add variant fields to `CartItemModel` (the display model used by cart_provider):

```dart
class CartItemModel {
  final int quantity;
  final String productId;
  final String cartItemId;  // NEW
  final Timestamp createdAt;
  final String? buyerNote;
  final String? variantId;          // NEW
  final String? variantTitle;       // NEW
  final Map<String, String>? variantOptions; // NEW

  CartItemModel({
    required this.quantity,
    required this.productId,
    required this.cartItemId,
    required this.createdAt,
    this.buyerNote,
    this.variantId,
    this.variantTitle,
    this.variantOptions,
  });

  factory CartItemModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final raw = map[Fields.createdAt];
    Timestamp ts;
    if (raw is Timestamp) {
      ts = raw;
    } else if (raw is String) {
      ts = Timestamp.fromDate(DateTime.parse(raw));
    } else if (raw is DateTime) {
      ts = Timestamp.fromDate(raw);
    } else {
      ts = Timestamp.now();
    }
    return CartItemModel(
      quantity: (map[Fields.quantity] as num?)?.toInt() ?? 0,
      productId: map[Fields.productId] ?? '',
      cartItemId: docId ?? map[Fields.cartItemId] ?? '',
      createdAt: ts,
      buyerNote: map[Fields.buyerNote] as String?,
      variantId: map[Fields.variantId] as String?,
      variantTitle: map[Fields.variantTitle] as String?,
      variantOptions: map[Fields.variantOptions] != null
          ? Map<String, String>.from(map[Fields.variantOptions] as Map)
          : null,
    );
  }
}
```

**Step 5: Update `cart_repository.dart`**

The `addToCart` method currently uses `productId` as the doc ID. Change it to use an auto-generated ID. Modify `FirebaseCartRepository.addToCart`:

```dart
@override
Future<void> addToCart(
  String userId,
  String productId,
  int quantity, {
  String? variantId,
  String? variantTitle,
  Map<String, String>? variantOptions,
  String? variantSku,
  int? priceSnapshot,
}) async {
  if (quantity < minCartItemQuantity) return;

  final cartRef = _firestore
      .collection(Collections.users)
      .doc(userId)
      .collection(Collections.cart);

  await _firestore.runTransaction((transaction) async {
    // Check if this exact product+variant combo already in cart
    final existingQuery = await cartRef
        .where(Fields.productId, isEqualTo: productId)
        .where(Fields.variantId, isEqualTo: variantId)
        .get();

    if (existingQuery.docs.isNotEmpty) {
      // Increment quantity on existing cart item
      final existingDoc = existingQuery.docs.first;
      final currentQty = (existingDoc.data()[Fields.quantity] as num?)?.toInt() ?? 0;
      final newQty = (currentQty + quantity).clamp(minCartItemQuantity, maxCartItemQuantity);
      transaction.update(existingDoc.reference, {Fields.quantity: newQty});
    } else {
      // Create new cart item with auto-generated ID
      final newItemRef = cartRef.doc();
      final clampedQty = quantity.clamp(minCartItemQuantity, maxCartItemQuantity);
      transaction.set(newItemRef, CartModel(
        cartItemId: newItemRef.id,
        productId: productId,
        quantity: clampedQty,
        createdAt: DateTime.now(),
        variantId: variantId,
        variantTitle: variantTitle,
        variantOptions: variantOptions,
        variantSku: variantSku,
        priceSnapshot: priceSnapshot,
      ).toMap());
    }
  });
}
```

Also update `CartRepository` abstract interface to match new signature.

Update `watchCart` to pass `docId` to `CartItemModel.fromMap`:
```dart
return snapshot.docs
    .map((doc) => CartItemModel.fromMap(doc.data(), docId: doc.id))
    .toList();
```

**Step 6: Update `cart_provider.dart`**

The `cartItemQuantityProvider` and related providers use `productId` as the doc reference key. These must be updated to look up by `productId` field query instead of direct doc reference.

`cartItemQuantityProvider` currently does:
```dart
.doc(productId).snapshots()
```

Change to query by `productId` field:
```dart
.where(Fields.productId, isEqualTo: productId).snapshots().map((snap) {
  return snap.docs.fold(0, (total, doc) => total + ((doc.data()[Fields.quantity] as num?)?.toInt() ?? 0));
});
```

**Step 7: Update `addToCart` in `origna_gta/lib/utils/utils.dart`**

The standalone `addToCart` function (line ~159) uses `productId` as the doc ID. Update to use the new repository pattern. Replace the inline Firestore call with `FirebaseCartRepository(FirebaseFirestore.instance).addToCart(...)`.

**Step 8: Update `database_schema.json` cart subcollection**

Change cart schema from:
```json
"cart": {
  "docId": "{productId}",
  "fields": { "productId": ..., "quantity": ..., "createdAt": ... }
}
```
to:
```json
"cart": {
  "docId": "{cartItemId} (auto-generated)",
  "description": "Cart line items. One doc per product+variant combination. Doc ID is auto-generated.",
  "fields": {
    "cartItemId": { "type": "string", "description": "Auto-generated document ID" },
    "productId": { "type": "string" },
    "variantId": { "type": ["string", "null"] },
    "variantTitle": { "type": ["string", "null"] },
    "variantOptions": { "type": ["object", "null"] },
    "variantSku": { "type": ["string", "null"] },
    "priceSnapshot": { "type": ["integer", "null"], "description": "Price in cents at add-to-cart time" },
    "quantity": { "type": "integer" },
    "createdAt": { "type": "string", "format": "date-time" },
    "buyerNote": { "type": ["string", "null"] }
  }
}
```

**Step 9: Verify compile**

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/origna_gta
flutter analyze lib/models/models.dart lib/core/repositories/cart_repository.dart lib/features/cart/cart_provider.dart lib/utils/utils.dart
```

**Step 10: Commit**

```bash
git add origna_gta/lib/models/models.dart origna_gta/lib/core/repositories/cart_repository.dart origna_gta/lib/features/cart/cart_provider.dart origna_gta/lib/utils/utils.dart origna_gta/lib/core/schema/schema_constants.dart functions/schema_constants.py docs/database_schema.json
git commit -m "feat: restructure cart — auto-generated IDs + variant snapshot (Medusa/Saleor pattern)"
```

---

## Task 9: Add `orders/{id}/events` subcollection

**Files:**
- Create: `functions/models/order_event.py`
- Modify: `functions/schema_constants.py`
- Modify: `origna_gta/lib/core/schema/schema_constants.dart`
- Modify: `docs/database_schema.json`
- Modify: `functions/handlers/orders.py` (write events on status transitions)
- Modify: `functions/handlers/payment_stripe.py` (write events on payment transitions)

**Context:** No production platform uses an embedded `statusHistory[]` array. Saleor uses `OrderEvent` table, Medusa uses `OrderChange` collection, Shopify uses `events` connection. Google's Firestore docs explicitly recommend subcollections for growing lists. This subcollection grows independently without bloating the order document.

**Step 1: Add constants to schema_constants.py**

In `functions/schema_constants.py`, inside `Collections`:
```python
ORDER_EVENTS = "events"  # Subcollection under orders/{orderId}/events/{eventId}
```

Inside `Fields`:
```python
ACTOR = "actor"          # UID string or 'system' or 'stripe_webhook'
ACTOR_TYPE = "actorType" # 'seller' | 'buyer' | 'admin' | 'system'
FROM_STATUS = "fromStatus"
TO_STATUS = "toStatus"
```

Inside a new `OrderEventTypes` class:
```python
class OrderEventTypes:
    STATUS_CHANGED = "status_changed"
    PAYMENT_AUTHORIZED = "payment_authorized"
    PAYMENT_CAPTURED = "payment_captured"
    PAYMENT_FAILED = "payment_failed"
    REFUND_ISSUED = "refund_issued"
    ITEM_SHIPPED = "item_shipped"
    ITEM_DELIVERED = "item_delivered"
    CANCELLATION_CONFIRMED = "cancellation_confirmed"
    NOTE_ADDED = "note_added"
    ALL: frozenset[str] = frozenset({
        STATUS_CHANGED, PAYMENT_AUTHORIZED, PAYMENT_CAPTURED, PAYMENT_FAILED,
        REFUND_ISSUED, ITEM_SHIPPED, ITEM_DELIVERED, CANCELLATION_CONFIRMED, NOTE_ADDED,
    })
```

**Step 2: Add constants to Dart schema_constants.dart**

```dart
abstract final class OrderEventTypes {
  static const statusChanged = 'status_changed';
  static const paymentAuthorized = 'payment_authorized';
  static const paymentCaptured = 'payment_captured';
  static const paymentFailed = 'payment_failed';
  static const refundIssued = 'refund_issued';
  static const itemShipped = 'item_shipped';
  static const itemDelivered = 'item_delivered';
  static const cancellationConfirmed = 'cancellation_confirmed';
  static const noteAdded = 'note_added';
}
```

Also add subcollection constant in `Collections`:
```dart
static const orderEvents = 'events'; // subcollection under orders/{orderId}
```

**Step 3: Create `functions/models/order_event.py`**

```python
"""
OrderEvent model — tracks every status transition for an order.
Stored in subcollection: orders/{orderId}/events/{eventId}
Pattern: Saleor OrderEvent / Medusa OrderChange
"""

from datetime import UTC, datetime
from pydantic import BaseModel, Field
from schema_constants import Fields, OrderEventTypes


class OrderEvent(BaseModel):
    """Immutable record of a state transition on an order."""

    eventType: str = Field(..., description="One of OrderEventTypes.*")
    fromStatus: str | None = Field(default=None, description="Status before transition")
    toStatus: str | None = Field(default=None, description="Status after transition")
    actor: str = Field(..., description="UID of user who triggered event, or 'system' or 'stripe_webhook'")
    actorType: str = Field(..., description="'seller' | 'buyer' | 'admin' | 'system'")
    metadata: dict = Field(default_factory=dict, description="Event-type-specific payload")
    createdAt: datetime = Field(default_factory=lambda: datetime.now(UTC))

    @staticmethod
    def write(
        batch_or_db,
        order_id: str,
        event_type: str,
        actor: str,
        actor_type: str,
        from_status: str | None = None,
        to_status: str | None = None,
        metadata: dict | None = None,
    ) -> None:
        """Write an event document to orders/{order_id}/events (auto-ID)."""
        from firebase_admin import firestore
        db = batch_or_db if hasattr(batch_or_db, 'collection') else firestore.client()
        event_ref = (
            db.collection("orders")
            .document(order_id)
            .collection("events")
            .document()
        )
        event = OrderEvent(
            eventType=event_type,
            fromStatus=from_status,
            toStatus=to_status,
            actor=actor,
            actorType=actor_type,
            metadata=metadata or {},
        )
        if hasattr(batch_or_db, 'set'):
            # It's a WriteBatch — add to batch
            batch_or_db.set(event_ref, event.model_dump())
        else:
            event_ref.set(event.model_dump())
```

**Step 4: Add OrderEvent to `functions/models/__init__.py`**

```python
from .order_event import OrderEvent
```

**Step 5: Write test for OrderEvent model**

```python
def test_order_event_model_validates():
    """OrderEvent must validate required fields."""
    from functions.models.order_event import OrderEvent
    event = OrderEvent(
        eventType="status_changed",
        fromStatus="confirmed",
        toStatus="shipped",
        actor="seller_uid_123",
        actorType="seller",
    )
    assert event.eventType == "status_changed"
    assert event.fromStatus == "confirmed"
    assert event.toStatus == "shipped"
    assert event.metadata == {}

def test_order_event_requires_actor():
    """OrderEvent must reject missing actor."""
    from pydantic import ValidationError
    with pytest.raises(ValidationError):
        OrderEvent(
            eventType="status_changed",
            actor_type="seller",
            # actor is missing
        )
```

**Step 6: Run tests**

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/functions
pytest tests/ -k "order_event" -v
```

**Step 7: Add `events` subcollection to `database_schema.json`**

Under the `orders` collection, add a subcollections section:
```json
"subcollections": {
  "events": {
    "docId": "{eventId} (auto-generated)",
    "description": "Immutable event log for every status transition. Pattern: Saleor OrderEvent. Never bloats order document.",
    "fields": {
      "eventType": { "type": "string", "description": "One of OrderEventTypes" },
      "fromStatus": { "type": ["string", "null"] },
      "toStatus": { "type": ["string", "null"] },
      "actor": { "type": "string", "description": "UID or 'system' or 'stripe_webhook'" },
      "actorType": { "type": "string", "enum": ["seller", "buyer", "admin", "system"] },
      "metadata": { "type": "object" },
      "createdAt": { "type": "string", "format": "date-time" }
    }
  }
}
```

**Step 8: Wire events into `orders.py` handler — status transitions**

In `functions/handlers/orders.py`, find every call that updates `orderStatus` or item `status`. After each status update inside a batch, add:

```python
OrderEvent.write(
    batch,
    order_id=order_id,
    event_type=OrderEventTypes.STATUS_CHANGED,
    from_status=old_status,
    to_status=new_status,
    actor=actor_uid or "system",
    actor_type="seller" if actor_uid else "system",
)
```

**Step 9: Wire events into `payment_stripe.py` — payment transitions**

In `functions/handlers/payment_stripe.py`, find payment capture and authorization code. After each payment status change, add:

```python
OrderEvent.write(
    batch,
    order_id=order_id,
    event_type=OrderEventTypes.PAYMENT_CAPTURED,
    actor="stripe_webhook",
    actor_type="system",
    metadata={"stripePaymentIntentId": payment_intent_id, "amountCents": amount},
)
```

**Step 10: Run full test suite**

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/functions
pytest tests/ -v --tb=short 2>&1 | tail -30
```

**Step 11: Commit**

```bash
git add functions/models/order_event.py functions/models/__init__.py functions/schema_constants.py functions/handlers/orders.py functions/handlers/payment_stripe.py origna_gta/lib/core/schema/schema_constants.dart docs/database_schema.json
git commit -m "feat: add orders/events subcollection — immutable event log per Saleor/Medusa pattern"
```

---

## Task 10: Clean up `orderStatus` dimension leak

**Files:**
- Modify: `functions/schema_constants.py`
- Modify: `origna_gta/lib/core/schema/schema_constants.dart`
- Modify: `functions/handlers/orders.py`
- Modify: `functions/handlers/payment_stripe.py`

**Context:** `orderStatus` currently contains `refunded` and `partially_refunded` which are payment outcomes. Saleor's canonical pattern: `status` = lifecycle only, `charge_status` = payment dimension. In OrignaGTA: `refunded`/`partially_refunded` in `orderStatus` should only live in `paymentStatus`.

**Step 1: Audit all places that set `orderStatus = "refunded"` or `"partially_refunded"`**

```bash
grep -rn '"refunded"\|"partially_refunded"\|REFUNDED\|PARTIALLY_REFUNDED' /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/functions/handlers/ | grep -i "order_status\|orderStatus"
```

List every location.

**Step 2: For each location — move to paymentStatus instead**

Replace any code that sets `orderStatus` to `refunded`/`partially_refunded` with:
```python
# Instead of: order.orderStatus = OrderStatusValues.REFUNDED
# Do both:
update_data[Fields.PAYMENT_STATUS] = PaymentStatusValues.REFUNDED   # canonical
# Leave orderStatus as "delivered" or "completed" — the lifecycle state
```

**Step 3: Update `VALID_TRANSITIONS` in `OrderStatusValues` to remove refunded/partially_refunded**

In `functions/schema_constants.py`, `OrderStatusValues.VALID_TRANSITIONS`:

Remove `refunded` and `partially_refunded` from the transitions map. These are now payment states only.

Update `ALL` frozenset to remove them.

**Step 4: Mirror in Dart `schema_constants.dart`**

In `OrderStatusValues.validTransitions` in Dart, remove `refunded` and `partiallyRefunded`.

**Step 5: Write transition tests to verify**

```python
def test_order_status_has_no_payment_values():
    """refunded and partially_refunded must not be orderStatus values — they belong in paymentStatus."""
    assert "refunded" not in OrderStatusValues.ALL
    assert "partially_refunded" not in OrderStatusValues.ALL

def test_payment_status_has_refunded_values():
    """refunded and partially_refunded must be in paymentStatus."""
    assert PaymentStatusValues.REFUNDED in PaymentStatusValues.ALL
    assert PaymentStatusValues.PARTIALLY_REFUNDED in PaymentStatusValues.ALL
```

**Step 6: Run test suite**

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/functions
pytest tests/test_schema_contract.py tests/test_payment_integration.py -v --tb=short
```

**Step 7: Commit**

```bash
git add functions/schema_constants.py origna_gta/lib/core/schema/schema_constants.dart functions/handlers/orders.py functions/handlers/payment_stripe.py
git commit -m "fix: remove refunded/partially_refunded from orderStatus — payment dimension only in paymentStatus"
```

---

## Task 11: Final schema sync verification

**Step 1: Run schema-sync-checker agent**

Per CLAUDE.md rule: after editing `schema_constants`, run `schema-sync-checker` immediately.

Verify:
- `functions/schema_constants.py` ↔ `origna_gta/lib/core/schema/schema_constants.dart` — all new constants present in both
- `docs/database_schema.json` — all new fields present
- `functions/models/order.py` ↔ `origna_gta/lib/models/generated/order_models.dart` — field parity

**Step 2: Run full backend test suite**

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/functions
pytest tests/ -v --tb=short 2>&1 | tail -50
```

Expected: all tests passing (or only tests that were already failing before this work).

**Step 3: Run Flutter analyze**

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/origna_gta
flutter analyze
```

Expected: no new errors.

**Step 4: Final commit**

```bash
git add docs/plans/2026-02-21-schema-p0-fixes-design.md docs/plans/2026-02-21-schema-p0-fixes.md
git commit -m "docs: add schema P0 fixes design doc and implementation plan"
```

---

## Summary — Task Order

| # | Task | Risk | Files Touched |
|---|------|------|--------------|
| 1 | Fix authorizationExpiresAt index | Low | database_schema.json |
| 2 | Add idempotencyKey to schema | Low | database_schema.json, schema_constants |
| 3 | Remove deliveryStatus — Python | Medium | order.py, conftest, tests |
| 4 | Remove deliveryStatus — Dart | Medium | order_models.dart, cart_provider |
| 5 | Add variant fields — Python | Low | order.py, database_schema.json |
| 6 | Add variant fields — Dart | Low | order_models.dart |
| 7 | Add version to Order | Low | order.py, order_models.dart |
| 8 | Restructure cart | High | models.dart, cart_repository, cart_provider, utils |
| 9 | Add order events subcollection | Medium | new order_event.py, handlers |
| 10 | orderStatus dimension cleanup | Medium | schema_constants, handlers |
| 11 | Final sync verification | Low | Verification only |
