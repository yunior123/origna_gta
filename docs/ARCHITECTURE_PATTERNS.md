# OrignaGTA -- Architecture Patterns Deep Dive

**Document Purpose**: Explain the "why" and "how things connect" for 10 key architectural patterns. Each section includes verified file paths, key functions, data flow, and gotchas.

Last verified: 2026-03-23

---

## 1. Image Handling: Compression, Upload, Cloudflare R2, and Parallel Flow

### Pattern Overview
Images flow through: **compression (isolate) -> presigned URL request -> parallel HTTP PUT upload -> cleanup on failure**.

### File Paths
- **Compression**: `origna_gta/lib/utils/image_compression_utils.dart`
- **Presigned URL & Upload**: `origna_gta/lib/core/repositories/product_image_helpers.dart` (mixin `ProductImageHelpers`)
- **Product Repository**: `origna_gta/lib/core/repositories/orignabase_product_repository.dart` (uses the mixin)
- **Add Product ViewModel**: `origna_gta/lib/features/products/add_product_viewmodel.dart` (orchestrates compression + upload)
- **Product Image Picker**: `origna_gta/lib/screens/productaddimages_screen.dart`
- **Backend Storage**: `orignabase/crates/ob-storage/src/routes.rs` (presigned URL endpoints)
- **Display**: `CachedNetworkImage` used in `origna_gta/lib/widgets/modern_product_card.dart`, `origna_gta/lib/screens/widgets/product_detail/product_image_gallery.dart`, and others

### Key Functions

**Compression** (`image_compression_utils.dart`):
```dart
// Runs in isolate via compute() -- never blocks UI thread
Uint8List? compressImageIsolate(Uint8List bytes)
  // Max dimension: 2048px (maintains aspect ratio)
  // JPEG quality: 85
  // Returns Uint8List ready for upload

Future<Uint8List?> validateAndCompressImage(Uint8List bytes)
  // Validates size <= 10MB (maxImageSize)
  // Validates decodable format
  // Delegates to compute(compressImageIsolate, bytes)
```

**Presigned URL + Upload** (`product_image_helpers.dart`):
```dart
mixin ProductImageHelpers {
  // Step 1: Get presigned URL
  Future<Map<String, String>?> getUploadUrlInfoImpl(String fileName)
    // POST /storage/presign/upload with path='products/$fileName', ttl=3600s
    // Returns {uploadUrl, publicUrl}

  // Step 2: Upload single image with retry (3 attempts, exponential backoff)
  Future<String?> uploadSingleImage(Uint8List bytes, String productId, int index)
    // Detects MIME type from magic bytes
    // PUT to presigned URL with Content-Type header
    // Retries with delay: attempt * 2 seconds
    // Returns publicUrl on success, null on failure

  // Step 3: Upload all images in parallel
  Future<List<String>> uploadImagesImpl(List<Uint8List> images, String productId)
    // Uses Future.wait() for PARALLEL upload (not sequential!)
    // If ANY upload fails: batch-deletes all successful uploads (cleanup)
    // All-or-nothing: throws if urls.length != images.length
}
```

**MIME Detection** (magic bytes in `ProductImageHelpers.detectImageMimeType`):
```
PNG:  0x89 0x50 0x4E 0x47
JPEG: 0xFF 0xD8 0xFF
WebP: 0x52 0x49 0x46 0x46 ... 0x57 0x45 0x42 0x50
GIF:  0x47 0x49 0x46 0x38
Default: image/jpeg
```

### Data Flow
```
File (User picks via image_picker)
  -> validateAndCompressImage() in isolate
    |
  Uint8List (max 2048px, JPEG q85, <=10MB)
    |
  POST /storage/presign/upload (OrignaBase)
    |
  {uploadUrl, publicUrl, ttl: 3600s}
    |
  PUT binary to uploadUrl (Cloudflare R2)
    |
  200 OK -> store publicUrl in product.imageUrls
  FAIL -> batch-delete all successful uploads via POST /storage/batch-delete
```

### Gotchas
1. **Future.wait on image uploads is all-or-nothing**: If any upload fails, `uploadImagesImpl` cleans up ALL previously uploaded URLs to avoid orphaned objects in R2. The cleanup is best-effort (catch block ignores errors).
2. **MIME type detection via magic bytes**: Don't trust file extension -- validate byte signature with `detectImageMimeType`.
3. **Presigned URL TTL is 3600s**: If user pauses before upload, URL expires. Re-request presigned URLs on retry.
4. **Content-Type header must be set**: R2 requires explicit Content-Type in PUT request.
5. **Isolate pattern for compression**: `compute()` runs compression off-main thread. The `compressImageIsolate` function is a top-level function (required for isolate compatibility).
6. **Review images use separate path**: `uploadReviewImagesImpl` stores in `reviews/$userId/` not `products/`.

---

## 2. Money & Pricing: Integer Cents Flow from Product Creation to Stripe Webhook

### Pattern Overview
**ALL monetary values are integer cents** throughout the entire stack (Rust, Flutter, database, Stripe). Conversion to dollars happens ONLY at display time.

### File Paths
- **Product Creation**: `origna_gta/lib/features/products/add_product_viewmodel.dart`
- **Product Models**: `origna_gta/lib/models/generated/product_models.dart` (contains `priceCents`)
- **Cart Total Display**: `origna_gta/lib/widgets/cart/cart_total_display.dart`
- **Checkout Provider**: `origna_gta/lib/features/checkout/orignabase_checkout_provider.dart`
- **Order Display**: `origna_gta/lib/widgets/order_widgets.dart`
- **Checkout Items Section**: `origna_gta/lib/screens/parts/checkout_items_section.dart`
- **Backend Checkout**: `orignabase/crates/ob-handlers/src/payments/checkout.rs`
- **Backend Refunds**: `orignabase/crates/ob-handlers/src/orders/refunds.rs`
- **Tax Rates**: `origna_gta/lib/utils/utils.dart` (line ~26, `provinceTaxRates` map)

### Key Field Names
```
priceCents             -- product unit price
subtotalCents          -- sum of (priceCents * quantity) per item
taxAmountCents         -- province-based tax
shippingCostCents      -- per-seller shipping
platformFeeTotalCents  -- platform's cut (from subtotal only)
totalAmountCents       -- subtotal + tax + shipping
couponDiscountCents    -- discount from coupon
```

### Province Tax Rates (from `utils.dart`)
```
ON: HST 13%  |  BC: GST 5% + PST 7%  |  QC: GST 5% + QST 9.975%
AB: GST 5%   |  NB/NL/PE: HST 15%    |  NS: HST 14%
SK: GST 5% + PST 6%  |  MB: GST 5% + PST 7%
```

### Display Formatting
```dart
// ONLY at the UI layer -- divide by 100
'\$${(cents / 100).toStringAsFixed(2)}'
// Example: 7500 cents -> "$75.00"
```

### Data Flow
```
User enters price in dollars (e.g., $75.00)
  -> multiply by 100 -> store as 7500 (int priceCents)
    |
  Product created with priceCents: 7500
    |
  Checkout calculates (all integer arithmetic):
    subtotalCents: 7500
    taxAmountCents: 975 (ON HST 13%)
    shippingCostCents: 899
    platformFeeTotalCents: 112 (1.5% of subtotal)
    totalAmountCents: 9374
    |
  Stripe Checkout Session:
    line_items[0].price_data.unit_amount: 7500 (cents)
    application_fee_amount: 112 (cents)
    |
  Buyer pays -> Stripe webhook: payment_intent.succeeded
    |
  Backend verifies amount, confirms order
    |
  UI displays: formatPrice(9374) -> "$93.74"
```

### Gotchas
1. **Money must NEVER be a float/double**: `0.1 + 0.2 != 0.3` in binary. Integer cents eliminates rounding errors.
2. **Platform fee from subtotalCents, NOT totalAmountCents**: Fee is on item cost only, not tax/shipping.
3. **Stripe expects cents**: Stripe's `amount` is always smallest currency unit. Pass directly.
4. **Integer division truncates**: `(subtotalCents * 150) ~/ 10000` -- be aware of truncation vs rounding.
5. **Partial refunds**: Recalculate platform fee for refunded amount. Platform fee is non-refundable.

---

## 3. Authentication Flow: Login, JWT, Token Refresh, and Logout

### Pattern Overview
OrignaBase SDK handles JWT lifecycle internally. Flutter never manually refreshes tokens -- the SDK intercepts 401 responses and refreshes automatically.

### File Paths
- **OrignaBase SDK Auth**: `orignabase/sdks/flutter/orignabase/lib/src/auth.dart` (class `OrignaBaseAuth`)
- **SDK Client**: `orignabase/sdks/flutter/orignabase/lib/src/client.dart` (auto-attaches Bearer token)
- **Flutter Login ViewModel**: `origna_gta/lib/features/auth/login_viewmodel.dart`
- **Auth Repository**: `origna_gta/lib/core/repositories/orignabase_auth_repository.dart`
- **MFA ViewModel**: `origna_gta/lib/features/auth/mfa_viewmodel.dart`
- **Backend Auth Routes**: `orignabase/crates/ob-auth/src/routes.rs`
- **Backend JWT**: `orignabase/crates/ob-auth/src/jwt.rs`
- **Auth Provider**: `origna_gta/lib/features/auth/auth_provider.dart`

### SDK Auth State (from `auth.dart`)
```dart
class AuthState {
  final AuthStatus status;      // authenticated | unauthenticated
  final String? userId;         // from JWT claims['sub']
  final String? email;
  final List<String> roles;     // ['buyer'], ['seller'], ['admin']
  final bool emailVerified;
  final bool mfaRequired;       // true if TOTP challenge pending
  final String? challengeToken; // for MFA verification
}

class OrignaBaseAuth {
  String? _accessToken;   // short-lived
  String? _refreshToken;  // long-lived
  // Token stored in memory, auto-attached to all requests
  Stream<AuthState> get authStateChanges  // broadcast stream
  String? get currentUserId               // from decoded JWT claims
}
```

### Login ViewModel Pattern (from `login_viewmodel.dart`)
```dart
final loginViewModelProvider =
    StateNotifierProvider.autoDispose<LoginViewModel, LoginState>((ref) {
      return LoginViewModel(ref);
    });

class LoginViewModel extends StateNotifier<LoginState> {
  // Maps OrignaBase error codes to i18n keys via _friendlyAuthError()
  // Handles: user-not-found, wrong-password, too-many-requests, etc.
}
```

### JWT Structure (RS256 signed by OrignaBase)
```json
{
  "sub": "users:abc123xyz",
  "email": "user@example.com",
  "roles": ["buyer"],
  "email_verified": true,
  "iat": 1711000000,
  "exp": 1711000900
}
```

### Data Flow
```
1. User enters email + password on LoginScreen
   |
2. LoginViewModel -> OrignaBaseAuth.signInWithEmail()
   -> POST /auth/login
   |
3. Backend verifies credentials, generates RS256 JWT + refresh token
   |
4. SDK stores _accessToken + _refreshToken in memory
   -> broadcasts AuthState via authStateChanges
   |
5a. If mfaRequired == true:
    -> redirect to MFA challenge screen
    -> POST /auth/mfa/verify with challengeToken + TOTP code
    -> new JWT issued with mfaVerified: true

5b. If mfaRequired == false:
    -> login complete, UI rebuilds
   |
6. Subsequent requests:
   |
7. If 401 response:
   SDK intercepts -> POST /auth/refresh with {refresh_token}
   -> new _accessToken issued -> retries original request
   ALL TRANSPARENT TO FLUTTER
   |
8. Logout:
   OrignaBaseAuth.signOut() -> clears tokens
   -> broadcasts AuthState.unauthenticated
```

### Gotchas
1. **Token refresh is automatic**: Flutter should never call a refresh function. The SDK handles it.
2. **JWT sub is full path "users:xxx"**: When comparing userId in filters, use full path. Short ID vs full path mismatch was a source of 403 errors.
3. **MFA challenge = not yet authenticated**: After login returns `mfaRequired: true`, the user has a challengeToken but no valid JWT. Must complete TOTP verification.
4. **Error code mapping**: `_friendlyAuthError()` in `login_viewmodel.dart` maps raw OrignaBase error codes to i18n translation keys.
5. **authStateChanges is a broadcast stream**: Multiple listeners OK, but Riverpod `ref.watch()` handles lifecycle automatically.
6. **Sign-out doesn't invalidate server-side**: JWT remains valid until expiry. Only client tokens are cleared.

---

## 4. Order State Machine: Transitions, Enforcement, and Notifications

### Pattern Overview
Orders follow a strict state machine enforced at the Rust backend. Invalid transitions are rejected. The actual state machine is more complex than the simplified `pending -> confirmed -> shipped -> delivered` -- it includes payment states, shipping approval, and return handling.

### File Paths
- **Backend Status Handler**: `orignabase/crates/ob-handlers/src/orders/status.rs` (transition validation + handlers)
- **Backend Returns**: `orignabase/crates/ob-handlers/src/orders/returns.rs`
- **Backend Shipping**: `orignabase/crates/ob-handlers/src/orders/shipping.rs`
- **Backend Webhooks**: `orignabase/crates/ob-handlers/src/payments/webhooks.rs`
- **Buyer Orders ViewModel**: `origna_gta/lib/features/orders/buyer_orders_viewmodel.dart`
- **Seller Orders ViewModel**: `origna_gta/lib/features/orders/seller_orders_viewmodel.dart`
- **Shipping Approval ViewModel**: `origna_gta/lib/features/orders/shipping_approval_viewmodel.dart`
- **Return Request ViewModel**: `origna_gta/lib/features/orders/return_request_viewmodel.dart`
- **Schema Constants**: `orignabase/crates/ob-handlers/src/shared/schema.rs` (OrderStatus enum)

### Full State Machine (from `status.rs`)

**Order-level transitions** (`is_valid_order_transition`):
```
PendingPayment -> PaymentAuthorized | Cancelled | Failed
PaymentAuthorized -> Processing | AwaitingShippingApproval | Cancelled
AwaitingShippingApproval -> Processing | Cancelled
Processing -> Shipped | Cancelled
Shipped -> Delivered | ReturnRequested
Delivered -> ReturnRequested | Refunded
ReturnRequested -> ReturnApproved | ReturnRejected
ReturnApproved -> Returned
Returned -> Refunded
```

**Item-level transitions** (`is_valid_item_transition` -- `DeliveryStatus`):
```
Pending -> Shipped
Shipped -> Delivered
Delivered -> Refunded
```

### Key Structs (from `status.rs`)
```rust
pub struct ConfirmItemReceiptRequest {
    pub order_id: String,
    pub product_id: String,
    pub user_id: String,
}

pub struct UpdateOrderStatusRequest {
    pub order_id: String,
    pub new_status: String,
    pub user_id: String,
    pub tracking_number: Option<String>,
    pub carrier: Option<String>,
}
```

### Buyer ViewModel Pattern (from `buyer_orders_viewmodel.dart`)
```dart
// Uses freezed state with confirmingItemId tracking
@freezed
abstract class BuyerOrdersState with _$BuyerOrdersState {
  const factory BuyerOrdersState({
    @Default(false) bool isLoading,
    @Default(false) bool isSuccess,
    String? errorMessage,
    String? confirmingItemId,  // tracks which item receipt is being confirmed
  }) = _BuyerOrdersState;
}

// confirmReceipt extracts productId from itemKey format "orderId_productId"
Future<bool> confirmReceipt(String orderId, String itemKey)
```

### Data Flow
```
1. Checkout -> creates order with status: PendingPayment
   |
2. Stripe webhook: payment_intent.succeeded
   -> PendingPayment -> PaymentAuthorized
   -> stock decremented (atomic transaction)
   -> notifications sent to buyer + seller
   |
3. If perishable items:
   -> PaymentAuthorized -> AwaitingShippingApproval
   -> seller has 24h to confirm address
   -> timeout -> auto-cancel
   |
4. Seller processes:
   -> PaymentAuthorized/AwaitingShippingApproval -> Processing
   -> Processing -> Shipped (with tracking number)
   |
5. Buyer confirms receipt:
   -> Shipped -> Delivered (per-item: Shipped -> Delivered)
   -> payout scheduled after all items delivered
   |
6. Return flow (within 30 days of delivery):
   -> Delivered -> ReturnRequested
   -> ReturnRequested -> ReturnApproved/ReturnRejected
   -> ReturnApproved -> Returned
   -> Returned -> Refunded (stock restored + Stripe refund)
```

### Gotchas
1. **Transactions must be atomic**: Stock decrement happens inside the confirm transaction. Rollback restores stock.
2. **Stock restoration on cancellation**: Uses PostgreSQL `UPDATE SET quantity = quantity + $qty` in transaction. Must also be atomic.
3. **Notifications are outside the transaction**: Sent after commit. If notification fails, order is still confirmed.
4. **Per-item delivery tracking**: `confirmReceipt` accepts `product_id` to confirm individual items. `all_delivered` flag in response indicates when the entire order is complete.
5. **Multi-seller orders are independent**: Each seller's order has its own state machine instance.
6. **Shipping approval for perishable**: 24h hard deadline via cron job in `orignabase/crates/ob-handlers/src/cron/mod.rs`.

---

## 5. Multi-Seller Checkout: Single Checkout -> Multiple Orders

### Pattern Overview
A single checkout creates **one Order per seller**. The OrignaBase backend splits the cart by `sellerId`, creates orders atomically, and creates one Stripe Checkout Session for the grand total.

### File Paths
- **Checkout Provider**: `origna_gta/lib/features/checkout/orignabase_checkout_provider.dart` (class `OrignaBaseCheckoutNotifier`)
- **Checkout State**: `origna_gta/lib/features/checkout/checkout_state.dart`
- **Cart Provider**: `origna_gta/lib/features/cart/cart_provider.dart`
- **Backend Checkout Handler**: `orignabase/crates/ob-handlers/src/payments/checkout.rs`
- **Circuit Breakers**: Used in checkout provider for shipping and Stripe calls

### Key Structures (from `checkout.rs`)
```rust
pub struct CreateCheckoutRequest {
    pub items: Vec<CartItem>,
    pub shipping_address: ShippingAddress,
    pub user_id: Option<String>,
    pub subtotal_cents: i64,
    pub coupon_code: Option<String>,
    pub eula_accepted: bool,
    pub age_verification_accepted: bool,
    pub idempotency_key: Option<String>,
    pub turnstile_token: Option<String>,
}

pub struct CheckoutResponse {
    pub session_id: String,
    pub order_id: String,
    pub checkout_url: Option<String>,
    pub success: bool,
}
```

### Checkout Provider Pattern (from `orignabase_checkout_provider.dart`)
```dart
final checkoutStateProvider =
    StateNotifierProvider.autoDispose<OrignaBaseCheckoutNotifier, CheckoutState>((ref) {
      return OrignaBaseCheckoutNotifier(ref);
    });

class OrignaBaseCheckoutNotifier extends StateNotifier<CheckoutState> {
  // Uses circuit breakers for resilience:
  static final _shippingCircuitBreaker = CircuitBreakerRegistry.get('ob_shipping_calc');
  static final _stripeCircuitBreaker = CircuitBreakerRegistry.get('ob_stripe_checkout');

  // Coupon validation via POST to ApiEndpoints.couponsApply
  Future<void> applyCoupon(String code, int subtotalCents, {List<String>? sellerIds})
}
```

### Data Flow
```
CartItems (flat list with sellerId per item):
  [{productId: prod1, sellerId: seller_a, qty: 2, price: 5000},
   {productId: prod2, sellerId: seller_b, qty: 1, price: 3000}]
  |
Backend groups by sellerId:
  seller_a: [prod1 x2] -> subtotal: 10000
  seller_b: [prod2 x1] -> subtotal: 3000
  |
Creates N Order records (1 per seller) in single transaction
All share same stripe_session_id
  |
Single Stripe Checkout Session:
  Grand total: 13000 + shipping + tax
  metadata: {order_ids, session_id}
  |
Buyer pays once -> payment_intent.succeeded webhook
  |
Backend confirms ALL orders with matching stripe_session_id
Stock decremented for all items atomically
  |
Each seller sees only their order in dashboard
Buyer sees N orders in "My Orders"
```

### Gotchas
1. **One payment, N orders**: Stripe sees one PaymentIntent. Backend maps it to multiple orders via `stripe_session_id`.
2. **Stock decrement is atomic across all orders**: If any stock decrement fails, entire transaction rolls back.
3. **Shipping calculated per seller**: Each seller has their own warehouse. Different shipping costs to same destination.
4. **Refunds are per-order**: Refunding seller_a's order does not affect seller_b's.
5. **Circuit breakers**: Shipping calculation and Stripe calls use circuit breakers to prevent cascading failures.
6. **Idempotency key**: `CreateCheckoutRequest` includes optional `idempotency_key` to prevent duplicate orders on retry.
7. **Turnstile token**: Bot protection via Cloudflare Turnstile validated server-side.

---

## 6. Shipping Calculation: Distance Tiers, Perishable Limit, and Free Shipping

### Pattern Overview
Shipping cost is calculated server-side using distance-based tiers, weight/volumetric surcharges, and express multipliers. Perishable items have a hard distance limit. Free shipping applies when subtotal meets threshold.

### File Paths
- **Shipping Calculator**: `orignabase/crates/ob-handlers/src/shipping_calc/mod.rs`
- **Business Rules**: `origna_gta/lib/utils/constants.dart` (contains `BusinessRules` class)
- **Checkout Provider**: `origna_gta/lib/features/checkout/orignabase_checkout_provider.dart`
- **Checkout Helper in utils**: `origna_gta/lib/utils/utils.dart` (contains `calculateShippingCost`)

### Shipping Tier Constants (from `shipping_calc/mod.rs`)
```rust
const DISTANCE_TIERS: &[(f64, f64)] = &[
    (5.0,    4.99),   // hyper-local
    (15.0,   6.99),   // local
    (50.0,   8.99),   // city
    (150.0,  11.99),  // regional
    (500.0,  14.99),  // provincial
    (1000.0, 17.99),  // interprovincial
];
const NATIONAL_CEILING: f64 = 21.99;

const ADDITIONAL_ITEM_RATE: f64 = 0.35;
const DEFAULT_WEIGHT_KG: f64 = 0.5;
const VOLUMETRIC_DIVISOR: f64 = 5000.0;
const WEIGHT_SURCHARGE_THRESHOLD_KG: f64 = 5.0;
const WEIGHT_SURCHARGE_PER_KG: f64 = 1.50;

// Express multipliers by distance band
const EXPRESS_HYPER_LOCAL: f64 = 1.3;
const EXPRESS_LOCAL: f64 = 1.5;
const EXPRESS_REGIONAL: f64 = 1.8;
const EXPRESS_DEFAULT: f64 = 2.0;

// Same-day multipliers
const SAME_DAY_HYPER_LOCAL: f64 = 2.0;
const SAME_DAY_LOCAL: f64 = 2.5;
const SAME_DAY_REGIONAL: f64 = 3.0;
const SAME_DAY_DEFAULT: f64 = 3.5;

// Province fallback costs
const FALLBACK_SAME_PROVINCE: f64 = 8.99;
const FALLBACK_ADJACENT: f64 = 11.99;
const FALLBACK_SAME_REGION: f64 = 14.99;
```

### Province Adjacency (from `adjacent_provinces` function)
The backend knows which provinces border each other for fallback pricing when geocoding is unavailable:
```
BC <-> AB, YT, NT  |  AB <-> BC, SK, NT  |  ON <-> MB, QC  |  QC <-> ON, NB, NL
```

### Key Rules
- **Perishable limit**: Items with `isPerishable: true` cannot ship beyond distance threshold (tested as 200km in tests)
- **Free shipping**: When `subtotalCents >= freeShippingThresholdCents` (7500 = $75 CAD)
- **Digital products**: No shipping at all (`isDigital: true`)
- **Weight surcharge**: Extra $1.50/kg above 5kg threshold
- **Volumetric weight**: `(L * W * H) / 5000` compared against actual weight; higher value used

### Data Flow
```
Checkout with items + destination address
  |
Backend fetches seller warehouse coordinates
  |
Calculates distance (Geoapify geocoding or province fallback)
  |
Checks perishable constraint (hard fail if over limit)
  |
Checks free shipping threshold
  |
Calculates: distance tier + weight surcharge + volumetric + express multiplier
  |
Converts dollars to cents: (dollars * 100.0) as i64
  |
Returns shippingCostCents to Flutter
```

### Gotchas
1. **Perishable is a hard limit**: Not a soft warning. Orders fail at checkout, not after payment.
2. **Free shipping overrides all calculation**: If threshold met, return 0 immediately.
3. **Province fallback**: If geocoding fails, falls back to province-based pricing (same, adjacent, or same region).
4. **Cents conversion**: `dollars_to_cents()` is a const function: `(dollars * 100.0) as i64`. Watch for floating-point edge cases.
5. **Express/same-day multipliers**: Applied on top of base distance tier cost. Can make shipping 2-3.5x more expensive.

---

## 7. Platform Fee: Calculation, Stripe Collection, and Seller Payout Split

### Pattern Overview
Platform fee is a percentage of **subtotal only** (not tax or shipping). Stripe collects it via `application_fee_amount`. Non-refundable on buyer refunds.

### File Paths
- **Business Rules**: `origna_gta/lib/utils/constants.dart` (`BusinessRules.platformFeePercentage`)
- **Checkout Provider**: `origna_gta/lib/features/checkout/orignabase_checkout_provider.dart`
- **Backend Checkout**: `orignabase/crates/ob-handlers/src/payments/checkout.rs`
- **Backend Schema**: `orignabase/crates/ob-handlers/src/shared/schema.rs` (field constants)
- **Cron Payouts**: `orignabase/crates/ob-handlers/src/cron/mod.rs`
- **MCP Admin Tools**: `orignabase/crates/ob-mcp/src/tools/admin.rs` (platform fee references)

### Calculation
```
platformFeeTotalCents = subtotalCents * platformFeeRate / 100

Stripe receives:
  amount: subtotalCents + taxAmountCents + shippingCostCents
  application_fee_amount: platformFeeTotalCents

Seller receives after delivery:
  subtotalCents - platformFeeTotalCents + shippingCostCents
  (Tax is seller's responsibility to remit)

On refund:
  Buyer refund: totalAmountCents (full)
  Platform keeps: platformFeeTotalCents (non-refundable)
  Seller charged: totalAmountCents - platformFeeTotalCents
```

### Gotchas
1. **Fee from subtotal ONLY**: Never use totalAmountCents. This is the most common mistake.
2. **application_fee_amount must be fixed cents**: Not a percentage. Calculate exact cents.
3. **Non-refundable**: Business decision -- platform keeps fee even on full refund.
4. **Shipping passed through**: Seller keeps 100% of shipping.
5. **Payout delayed until delivered**: Never initiate payout before order reaches `delivered` state.
6. **Connected Account required**: Seller's Stripe Connect account must be linked in `seller_profiles`.

---

## 8. Search & Meilisearch Synchronization: ID Sanitization and Real-Time Indexing

### Pattern Overview
Meilisearch syncs products from PostgreSQL via an event-driven `SearchSyncer`. Product IDs are used directly as Meilisearch document IDs.

### File Paths
- **Search Syncer**: `orignabase/crates/ob-search/src/sync.rs` (struct `SearchSyncer`, `SearchSyncEvent`)
- **Search Client**: `orignabase/crates/ob-search/src/client.rs` (Meilisearch operations + `record_id` restoration)
- **Search Crate Entry**: `orignabase/crates/ob-search/src/lib.rs`
- **Product CRUD (triggers sync)**: `orignabase/crates/ob-handlers/src/products/crud.rs`

### ID Sanitization (from `sync.rs`)
```rust
fn sanitize_document_id(document_id: &str) -> String {
    document_id.chars().map(|ch| {
        if ch.is_ascii_alphanumeric() || ch == '-' || ch == '_' { ch }
        else { '_' }
    }).collect()
}
// "products:abc123" -> "products_abc123"
```

### Document Normalization (from `sync.rs`)
```rust
fn normalize_document_for_indexing(document_id: &str, data: &Value) -> Value {
    let search_id = sanitize_document_id(document_id);
    // Inserts "id" (sanitized) and "record_id" (original PostgreSQL ID)
    // into the document for Meilisearch indexing
}
```

**IMPORTANT**: The field preserving the original PostgreSQL ID is `record_id`, NOT `origId` as previously documented.

### Search Syncer Architecture (from `sync.rs`)
```rust
pub struct SearchSyncEvent {
    pub action: SearchAction,   // Upsert | Delete
    pub index: String,          // e.g., "products"
    pub document_id: String,    // PostgreSQL ID
    pub data: Value,            // document content
}

pub struct SearchSyncer {
    client: SearchClient,
    receiver: mpsc::Receiver<SearchSyncEvent>,
}
// Channel-based: producers send events, syncer consumes and flushes to Meilisearch
// mpsc channel with capacity 1024
```

### record_id Restoration (from `client.rs`)
When search results come back, the client restores the original PostgreSQL ID:
```rust
// In search results, replace sanitized "id" with original "record_id"
let record_id = hit.get("record_id").and_then(|v| v.as_str());
if let Some(record_id) = record_id {
    obj.insert("id".to_string(), Value::String(record_id));
}
```

### Meilisearch Index Configuration
- **Searchable**: name, description, keywords, subcategory
- **Filterable**: lifecycleStatus, categoryId, priceCents, sellerId, isPerishable
- **Sortable**: priceCents, createdAt

### Data Flow
```
Product created/updated in PostgreSQL
  |
Handler sends SearchSyncEvent via mpsc channel
  action: Upsert, document_id: "products:abc123", data: {...}
  |
SearchSyncer.run() receives event
  |
normalize_document_for_indexing():
  sanitize: "products:abc123" -> "products_abc123"
  inject: {id: "products_abc123", record_id: "products:abc123", ...fields}
  |
client.upsert_documents("products", [normalized_doc])
  |
Search query returns hits with record_id
  |
client restores: hit.id = hit.record_id ("products:abc123")
  |
Full product fetched from PostgreSQL using restored ID
```

### Gotchas
1. **record_id (not origId)**: The field storing the original PostgreSQL ID is `record_id`. Code referencing `origId` is outdated.
2. **Sanitization is broader than colon**: Any non-alphanumeric, non-dash, non-underscore char becomes `_`.
3. **Sync is async and eventual**: mpsc channel with 1024 capacity. Under heavy load, events may queue.
4. **Delete uses sanitized ID**: `delete_document` also sanitizes the document_id before calling Meilisearch.
5. **Filterable fields must be configured**: Filtering on a non-filterable field silently returns no results.
6. **Search does not enforce authorization**: Meilisearch returns all matching docs. Backend must filter by `lifecycleStatus: "active"` and access rules.

---

## 9. Riverpod MVVM: Patterns & 3 Canonical Examples

### Pattern Overview
**MVVM Architecture**: Screens are dumb UI. All logic lives in ViewModels (StateNotifier or AsyncNotifier). Riverpod providers are the single source of truth. Screens watch providers and rebuild reactively.

### File Paths
- **Core Providers**: `origna_gta/lib/core/providers.dart`
- **OrignaBase Provider**: `origna_gta/lib/core/orignabase_provider.dart`

### Canonical Example 1: StateNotifier with Freezed State (Login)

**Files**: `origna_gta/lib/features/auth/login_viewmodel.dart`, `origna_gta/lib/features/auth/login_state.dart`

```dart
final loginViewModelProvider =
    StateNotifierProvider.autoDispose<LoginViewModel, LoginState>((ref) {
      return LoginViewModel(ref);
    });

class LoginViewModel extends StateNotifier<LoginState> {
  final Ref _ref;
  LoginViewModel(this._ref) : super(const LoginState());

  // Error mapping: OrignaBaseAuthException codes -> i18n keys
  // via _friendlyAuthError() helper function
}
```

**Key Pattern**: Error code mapping via `_friendlyAuthError()` translates raw backend errors (`user-not-found`, `wrong-password`, `too-many-requests`, etc.) to localized strings.

### Canonical Example 2: StateNotifier with Freezed + Repository (Buyer Orders)

**Files**: `origna_gta/lib/features/orders/buyer_orders_viewmodel.dart`

```dart
@freezed
abstract class BuyerOrdersState with _$BuyerOrdersState {
  const factory BuyerOrdersState({
    @Default(false) bool isLoading,
    @Default(false) bool isSuccess,
    String? errorMessage,
    String? confirmingItemId,  // tracks ongoing operation
  }) = _BuyerOrdersState;
}

class BuyerOrdersViewModel extends StateNotifier<BuyerOrdersState> {
  final Ref _ref;

  Future<bool> confirmReceipt(String orderId, String itemKey) async {
    // Guard: if already confirming, bail
    if (state.confirmingItemId != null) return false;
    state = state.copyWith(isLoading: true, confirmingItemId: itemKey);
    try {
      // Extract productId from "orderId_productId" format
      await _ref.read(orderRepositoryProvider).confirmReceipt(orderId, productId: productId);
      state = state.copyWith(isLoading: false, isSuccess: true, confirmingItemId: null);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e, 'Failed to confirm order receipt'),
        confirmingItemId: null,
      );
      return false;
    }
  }
}
```

**Key Pattern**: Uses `confirmingItemId` to track which specific item is being processed -- prevents double-submit and enables per-item loading UI.

### Canonical Example 3: StateNotifier with Circuit Breakers (Checkout)

**Files**: `origna_gta/lib/features/checkout/orignabase_checkout_provider.dart`, `origna_gta/lib/features/checkout/checkout_state.dart`

```dart
final checkoutStateProvider =
    StateNotifierProvider.autoDispose<OrignaBaseCheckoutNotifier, CheckoutState>((ref) {
      return OrignaBaseCheckoutNotifier(ref);
    });

class OrignaBaseCheckoutNotifier extends StateNotifier<CheckoutState> {
  // Circuit breakers for resilience
  static final _shippingCircuitBreaker = CircuitBreakerRegistry.get('ob_shipping_calc');
  static final _stripeCircuitBreaker = CircuitBreakerRegistry.get('ob_stripe_checkout');

  OrignaBase get _ob => _ref.read(orignabaseProvider);

  Future<void> applyCoupon(String code, int subtotalCents, {List<String>? sellerIds}) async {
    state = state.copyWith(isCouponLoading: true, couponError: null);
    try {
      final result = await _ob.request('POST', ApiEndpoints.couponsApply, body: {
        Fields.couponCode: trimmed,
        ApiKeys.cartSubtotalCents: subtotalCents,
        Fields.sellerIds: sellerIds ?? [],
      });
      // ... update state with discount
    } catch (e) { /* ... */ }
  }
}
```

**Key Pattern**: Uses `CircuitBreakerRegistry` for shipping and Stripe calls. Uses `ApiEndpoints` and `Fields` from `schema_constants.dart` -- no magic strings.

### Canonical Example: Profile ViewModel with SDK

**File**: `origna_gta/lib/features/profile/orignabase_profile_viewmodel.dart`

```dart
class OrignaBaseProfileViewModel extends StateNotifier<ProfileState> {
  OrignaBase get _ob => _ref.read(orignabaseProvider);

  Future<void> updateLanguage(String langCode) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _ref.read(userRepositoryProvider).updatePreferredLanguage(userId, langCode);
      state = state.copyWith(isLoading: false, successMessage: 'profile.language_updated'.tr());
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e, 'Failed to update language'),
      );
    }
  }
}
```

**Key Pattern**: ViewModel -> Repository -> OrignaBase SDK. Error messages via `AppError.getMessage()`. Success messages via i18n `.tr()`.

### Common Riverpod Patterns
- `ref.watch()` for reactive state in build methods
- `ref.read()` for one-time actions (button presses)
- `ref.listen()` for side effects (SnackBars) without rebuilding
- `.select()` to avoid unnecessary rebuilds: `ref.watch(provider.select((s) => s.field))`
- `autoDispose` on all screen-level providers to prevent memory leaks

---

## 10. Error Handling: Rust Backend -> SDK -> Flutter UI

### Pattern Overview
Errors flow through 3 layers: Rust `Error` enum (with HTTP status codes) -> SDK `OrignaBaseException` -> Flutter `AppError` class + `AppLogger` for Sentry. Each layer sanitizes and never leaks internals.

### File Paths
- **Rust Error Type**: `orignabase/crates/ob-core/src/error.rs` (enum `Error`)
- **Flutter AppError**: `origna_gta/lib/utils/utils.dart` (line ~852, class `AppError`)
- **Flutter AppLogger**: `origna_gta/lib/utils/app_logger.dart` (class `AppLogger`)
- **Error Codes**: `origna_gta/lib/core/errors/error_codes.dart` (class `ErrorCodes`)
- **SDK Exceptions**: `orignabase/sdks/flutter/orignabase/lib/src/client.dart` (OrignaBaseException)

### Rust Error Enum (from `ob-core/src/error.rs`)
```rust
#[derive(Debug, thiserror::Error)]
pub enum Error {
    Config(String),             // 500
    Database(String),           // 500
    Auth(String),               // 401
    Forbidden(String),          // 403
    NotFound(String),           // 404
    Validation(String),         // 400
    UnsupportedMediaType(String), // 415
    Internal(String),           // 500
}

impl IntoResponse for Error {
    fn into_response(self) -> Response {
        // CRITICAL: Database/Internal/Config errors return generic "Internal server error"
        // NEVER leak internal details to clients
        let message = match &self {
            Error::Database(_) | Error::Internal(_) | Error::Config(_) =>
                "Internal server error".to_string(),
            _ => self.to_string(),
        };
        // Returns JSON: {"error": {"code": 500, "message": "..."}}
    }
}
```

### Flutter AppError (from `utils.dart`)
```dart
class AppError {
  static String getMessage(dynamic error, [String? fallback, String? code]) {
    // OrignaBaseException: uses backend message (already sanitized)
    //   EXCEPT: filters "FailedPrecondition" and index errors -> generic message
    // OrignaBaseAuthException: always returns generic "service unavailable"
    // Everything else: returns fallback, NEVER exposes raw e.toString()

    // Error code appending:
    //   If backend already embedded [ORIGNA-XXX], don't double-append
    //   Otherwise, infer code from error type via _inferCode()
    //   Example output: "Card declined [ORIGNA-PAY-001]"
  }

  static void log(dynamic error, {StackTrace? stackTrace, String? context}) {
    // Delegates to AppLogger for Sentry capture
  }
}
```

### Flutter AppLogger (from `app_logger.dart`)
```dart
class AppLogger {
  static void d(String message, {String? tag})  // debug only (kDebugMode)
  static void i(String message, {String? tag})  // info only (kDebugMode)
  static void w(String message, {String? tag})  // warning: prints + Sentry breadcrumb
  static void e(String message, {String? tag, Object? error, StackTrace? stackTrace})
    // error: prints in debug + captures to Sentry in release
}
```

### Error Codes (from `error_codes.dart`)
```dart
abstract final class ErrorCodes {
  // AUTH domain
  static const authEmailInUse        = 'ORIGNA-AUTH-001';
  static const authWrongPassword     = 'ORIGNA-AUTH-002';
  static const authUserNotFound      = 'ORIGNA-AUTH-003';
  // ...

  // PAY domain (Stripe)
  static const payCardDeclined       = 'ORIGNA-PAY-001';
  static const payInsufficientFunds  = 'ORIGNA-PAY-002';
  // ...

  // ORD domain (orders)
  // ... additional domains
}
// Users see: "Card declined [ORIGNA-PAY-001]" and can quote code to support
```

### Data Flow
```
1. Rust handler encounters error:
   Error::Validation("Invalid postal code format")
   |
2. IntoResponse converts to HTTP 400:
   {"error": {"code": 400, "message": "Validation error: Invalid postal code format"}}
   |
3. SDK receives HTTP error:
   throws OrignaBaseException(statusCode: 400, message: "Validation error: ...")
   |
4. Flutter ViewModel catches:
   AppError.getMessage(e, 'Failed to save address')
   |
5. AppError.getMessage returns:
   "Validation error: Invalid postal code format [ORIGNA-ADDR-001]"
   (or fallback if message is unsafe)
   |
6. UI displays:
   Transient error -> SnackBar
   Form error -> inline under field
   |
7. AppLogger.e() captures to Sentry in release mode
```

### Gotchas
1. **NEVER print() or println!()**: Use `AppLogger` (Flutter) or `tracing::*` (Rust).
2. **NEVER unwrap() in handlers**: Always return `Result<_, Error>`.
3. **NEVER expose raw error.toString()**: `AppError.getMessage()` filters unsafe messages.
4. **Database errors are always generic**: Backend returns "Internal server error" for DB/Config/Internal errors.
5. **Error codes are user-facing**: Users quote `[ORIGNA-XXX-NNN]` to support for debugging.
6. **Sentry captures in release only**: Debug mode prints to console. Release captures to Sentry via `AppLogger.e()`.
7. **Double code prevention**: If backend already embedded `[ORIGNA-...]` in the message, `AppError.getMessage` won't append another code.
