# Schema Constants Reference

> **Single Source of Truth**: All database field names, collection names, and API parameters live in `lib/core/schema/schema_constants.dart`. Never use string literals for field names.

---

## Philosophy

Schema constants eliminate **magic strings** from the codebase:

1. **Compile-time safety** — Typos like `'priceCentz'` fail at compile, not runtime
2. **IDE autocomplete** — `Fields.` shows all available fields
3. **Easy refactoring** — Rename once, propagate everywhere
4. **Cross-stack consistency** — Flutter, Rust, and E2E tests use same constants
5. **Documentation** — Field names are self-documenting

---

## Usage

### ❌ Wrong: Magic Strings

```dart
// WRONG - Magic strings
db.collection('products').where('priceCents', '>', 1000)
doc.get('createdAt')
order['status']
api.post('/orders', {'userId': '123', 'subtotalCents': 7500})
```

### ✅ Right: Schema Constants

```dart
// CORRECT - Schema constants
db.collection(Collections.products).where(Fields.priceCents, '>', 1000)
doc.get(Fields.createdAt)
order[Fields.status]
api.post('/orders', {
  Fields.userId: '123',
  Fields.subtotalCents: 7500,
})
```

---

## Collections

All database collection names:

| Constant | Value | Usage |
|----------|-------|-------|
| `Collections.users` | `'users'` | User profiles |
| `Collections.products` | `'products'` | Product listings |
| `Collections.orders` | `'orders'` | Customer orders |
| `Collections.payouts` | `'payouts'` | Seller payouts |
| `Collections.refunds` | `'refunds'` | Refund records |
| `Collections.productRatings` | `'product_ratings'` | Product reviews |
| `Collections.sellerRatings` | `'seller_ratings'` | Seller performance |
| `Collections.chats` | `'chats'` | Buyer-seller conversations |
| `Collections.chatMessages` | `'messages'` | Chat messages (subcollection) |
| `Collections.subscriptions` | `'subscriptions'` | Premium memberships |
| `Collections.licenses` | `'licenses'` | Digital product licenses |
| `Collections.warehouses` | `'warehouses'` | Seller warehouses (subcollection) |
| `Collections.cart` | `'cart'` | User cart (subcollection) |
| `Collections.favorites` | `'favorites'` | Saved products (subcollection) |
| `Collections.addresses` | `'addresses'` | Saved addresses (subcollection) |
| `Collections.notifications` | `'notifications'` | User notifications (subcollection) |
| `Collections.webhookLogs` | `'webhook_logs'` | Stripe webhook audit |
| `Collections.securityAlerts` | `'security_alerts'` | Fraud/suspension events |
| `Collections.returnRequests` | `'return_requests'` | Return/refund requests |
| `Collections.coupons` | `'coupons'` | Coupon codes |
| `Collections.disputes` | `'disputes'` | Stripe disputes |

### Subcollections

Some collections are subcollections (nested under parent documents):

```dart
// User subcollections
db.collection(Collections.users).doc(userId).collection(Collections.cart)
db.collection(Collections.users).doc(userId).collection(Collections.favorites)
db.collection(Collections.users).doc(userId).collection(Collections.addresses)
db.collection(Collections.users).doc(userId).collection(Collections.warehouses)

// Order subcollections
db.collection(Collections.orders).doc(orderId).collection(Collections.orderEvents)

// Chat subcollections
db.collection(Collections.chats).doc(chatId).collection(Collections.chatMessages)
```

---

## Fields

All database document field names. Organized by entity:

### Common Fields (All Collections)

| Constant | Value | Type | Usage |
|----------|-------|------|-------|
| `Fields.createdAt` | `'createdAt'` | DateTime | Creation timestamp |
| `Fields.updatedAt` | `'updatedAt'` | DateTime | Last modification |
| `Fields.deletedAt` | `'deletedAt'` | DateTime? | Soft delete marker |
| `Fields.deletedBy` | `'deletedBy'` | String? | Deleter user ID |
| `Fields.version` | `'version'` | int | Optimistic concurrency |

**Note**: Use `createdAt` consistently. Legacy `dateCreated` exists for products/cart but `createdAt` is canonical.

### User Fields

| Constant | Value | Type | Usage |
|----------|-------|------|-------|
| `Fields.uid` | `'uid'` | String | User ID (primary key) |
| `Fields.email` | `'email'` | String | User email |
| `Fields.name` | `'name'` | String | Display name |
| `Fields.roles` | `'roles'` | List<String> | User roles (admin/seller/buyer) |
| `Fields.sellerProfile` | `'sellerProfile'` | Map? | Seller-specific data |
| `Fields.stripeAccountId` | `'stripeAccountId'` | String? | Stripe Connect account |
| `Fields.payoutsEnabled` | `'payoutsEnabled'` | bool | Can receive payouts |
| `Fields.suspended` | `'suspended'` | bool | Account suspended |
| `Fields.mfaEnabled` | `'mfaEnabled'` | bool | MFA active |

### Product Fields

| Constant | Value | Type | Usage |
|----------|-------|------|-------|
| `Fields.productId` | `'productId'` | String | Product ID |
| `Fields.sellerId` | `'sellerId'` | String | Owner user ID |
| `Fields.name` | `'name'` | String | Product name |
| `Fields.description` | `'description'` | String | Product description |
| `Fields.priceCents` | `'priceCents'` | int | Price in cents |
| `Fields.compareAtPrice` | `'compareAtPrice'` | int? | Original/sale price |
| `Fields.stockQuantity` | `'stockQuantity'` | int | Available inventory |
| `Fields.imageUrls` | `'imageUrls'` | List<String> | Product images |
| `Fields.videoUrl` | `'videoUrl'` | String? | Product video |
| `Fields.categoryId` | `'categoryId'` | int | Category ID |
| `Fields.rating` | `'rating'` | double | Average rating |
| `Fields.ratingCount` | `'ratingCount'` | int | Number of reviews |
| `Fields.isDigital` | `'isDigital'` | bool | Digital product flag |
| `Fields.digitalType` | `'digitalType'` | String? | 'software' or 'book' |
| `Fields.weightKg` | `'weightKg'` | double? | Shipping weight |
| `Fields.isTrending` | `'isTrending'` | bool | Trending flag |

### Order Fields

| Constant | Value | Type | Usage |
|----------|-------|------|-------|
| `Fields.orderId` | `'orderId'` | String | Order ID |
| `Fields.userId` | `'userId'` | String | Buyer user ID |
| `Fields.sellerIds` | `'sellerIds'` | List<String> | Sellers in order |
| `Fields.items` | `'items'` | List<Map> | Order items |
| `Fields.subtotalCents` | `'subtotalCents'` | int | Pre-tax subtotal |
| `Fields.taxAmountCents` | `'taxAmountCents'` | int | Tax total |
| `Fields.shippingCostCents` | `'shippingCostCents'` | int | Shipping cost |
| `Fields.totalAmountCents` | `'totalAmountCents'` | int | Final total |
| `Fields.currency` | `'currency'` | String | 'cad' |
| `Fields.status` | `'status'` | String | Order status |
| `Fields.paymentStatus` | `'paymentStatus'` | String | Payment status |
| `Fields.shippingAddress` | `'shippingAddress'` | Map | Delivery address |
| `Fields.stripeSessionId` | `'stripeSessionId'` | String | Stripe Checkout ID |
| `Fields.stripePaymentIntentId` | `'stripePaymentIntentId'` | String | Stripe PaymentIntent |

### Order Item Fields

| Constant | Value | Type | Usage |
|----------|-------|------|-------|
| `Fields.productId` | `'productId'` | String | Product ID |
| `Fields.quantity` | `'quantity'` | int | Quantity ordered |
| `Fields.priceCents` | `'priceCents'` | int | Price at purchase |
| `Fields.trackingNumber` | `'trackingNumber'` | String? | Shipping tracking |
| `Fields.carrier` | `'carrier'` | String? | Shipping carrier |
| `Fields.shippedAt` | `'shippedAt'` | DateTime? | Ship timestamp |
| `Fields.deliveredAt` | `'deliveredAt'` | DateTime? | Delivery timestamp |

### Address Fields

| Constant | Value | Type | Usage |
|----------|-------|------|-------|
| `Fields.street` | `'street'` | String | Street address |
| `Fields.apartment` | `'apartment'` | String? | Unit/apartment |
| `Fields.city` | `'city'` | String | City |
| `Fields.state` | `'state'` | String | Province |
| `Fields.postalCode` | `'postalCode'` | String | Postal code |
| `Fields.country` | `'country'` | String | Country |
| `Fields.phoneNumber` | `'phoneNumber'` | String | Contact phone |
| `Fields.isDefault` | `'isDefault'` | bool | Default address |
| `Fields.latitude` | `'latitude'` | double? | GPS latitude |
| `Fields.longitude` | `'longitude'` | double? | GPS longitude |

### Payout Fields

| Constant | Value | Type | Usage |
|----------|-------|------|-------|
| `Fields.amountCents` | `'amountCents'` | int | Payout amount |
| `Fields.platformFeeCents` | `'platformFeeCents'` | int | Platform fee |
| `Fields.netAmountCents` | `'netAmountCents'` | int | Seller receives |
| `Fields.stripeTransferId` | `'stripeTransferId'` | String | Stripe Transfer ID |
| `Fields.payoutDate` | `'payoutDate'` | DateTime | Payout date |

---

## ApiKeys

Backend API request parameters and response keys. **NOT database fields** — these are the contract between Flutter and OrignaBase.

### Request Parameters

| Constant | Value | Usage |
|----------|-------|-------|
| `ApiKeys.turnstileToken` | `'turnstileToken'` | Cloudflare Turnstile token |
| `ApiKeys.eulaAccepted` | `'eulaAccepted'` | EULA acceptance flag |
| `ApiKeys.idempotencyKey` | `'idempotencyKey'` | Idempotency key for checkout |
| `ApiKeys.productId` | `'productId'` | Product ID parameter |
| `ApiKeys.subtotalCents` | `'subtotalCents'` | Subtotal parameter |
| `ApiKeys.newStatus` | `'newStatus'` | Status update parameter |

### Response Keys

| Constant | Value | Usage |
|----------|-------|-------|
| `ApiKeys.success` | `'success'` | Operation success flag |
| `ApiKeys.checkoutUrl` | `'checkoutUrl'` | Stripe Checkout URL |
| `ApiKeys.sessionId` | `'sessionId'` | Checkout session ID |
| `ApiKeys.hasChanges` | `'hasChanges'` | Price verification result |
| `ApiKeys.priceChanges` | `'priceChanges'` | Price change details |
| `ApiKeys.stockChanges` | `'stockChanges'` | Stock change details |

---

## BusinessRules

Platform-wide business constants:

### Financial Rules

| Constant | Value | Usage |
|----------|-------|-------|
| `BusinessRules.platformFeePercent` | `2.5` | Platform fee (2.5%) |
| `BusinessRules.freeShippingThresholdCents` | `7500` | Free shipping at $75 |
| `BusinessRules.maxShippingCostCad` | `500` | Max shipping $500 |
| `BusinessRules.minCheckoutTotalCents` | `100` | Min order $1.00 |
| `BusinessRules.premiumSubscriptionPriceCents` | `786` | Premium $7.86/month |

### Order Rules

| Constant | Value | Usage |
|----------|-------|-------|
| `BusinessRules.autoConfirmDays` | `5` | Auto-confirm after 5 days |
| `BusinessRules.authorizationExpiryDays` | `6` | Auth expires in 6 days |
| `BusinessRules.returnWindowDays` | `30` | 30-day return window |
| `BusinessRules.maxCaptureAttempts` | `3` | Max payment capture attempts |

### Seller Rules

| Constant | Value | Usage |
|----------|-------|-------|
| `BusinessRules.sellerDisputeRateThreshold` | `0.05` | 5% dispute rate threshold |
| `BusinessRules.sellerRefundRateThreshold` | `0.10` | 10% refund rate threshold |
| `BusinessRules.sellerProductsPageSize` | `200` | Products per page |

### Shipping Rules

| Constant | Value | Usage |
|----------|-------|-------|
| `BusinessRules.localDeliveryRadiusKm` | `50.0` | Local delivery 50km radius |
| `BusinessRules.ordersPageSize` | `50` | Orders per page |

### Content Rules

| Constant | Value | Usage |
|----------|-------|-------|
| `BusinessRules.maxProductImages` | `5` | Max images per product |
| `BusinessRules.maxVideoBytes` | `104857600` | 100MB max video |
| `BusinessRules.maxVideoDurationSeconds` | `60` | 60s max video |
| `BusinessRules.maxMessageLength` | `1000` | Max chat message length |
| `BusinessRules.minMessageLength` | `10` | Min chat message length |

### Tax Rates

```dart
// Canadian tax rates by province
BusinessRules.taxRates = {
  'AB': {'GST': 5.0},
  'BC': {'GST': 5.0, 'PST': 7.0},
  'MB': {'GST': 5.0, 'PST': 7.0},
  'NB': {'HST': 15.0},
  'NL': {'HST': 15.0},
  'NS': {'HST': 14.0},  // Changed April 1, 2025
  'NT': {'GST': 5.0},
  'NU': {'GST': 5.0},
  'ON': {'HST': 13.0},
  'PE': {'HST': 15.0},
  'QC': {'GST': 5.0, 'QST': 9.975},
  'SK': {'GST': 5.0, 'PST': 6.0},
  'YT': {'GST': 5.0},
}
```

---

## Enum Values

### Order Status

| Constant | Value | Usage |
|----------|-------|-------|
| `OrderStatusValues.pending` | `'pending'` | Order created |
| `OrderStatusValues.confirmed` | `'confirmed'` | Payment confirmed |
| `OrderStatusValues.shipped` | `'shipped'` | Items shipped |
| `OrderStatusValues.delivered` | `'delivered'` | Items delivered |
| `OrderStatusValues.cancelled` | `'cancelled'` | Order cancelled |

### Delivery Status

| Constant | Value | Usage |
|----------|-------|-------|
| `DeliveryStatusValues.pending` | `'pending'` | Awaiting shipment |
| `DeliveryStatusValues.shipped` | `'shipped'` | In transit |
| `DeliveryStatusValues.delivered` | `'delivered'` | Delivered |
| `DeliveryStatusValues.refunded` | `'refunded'` | Refunded |

### Payment Status

| Constant | Value | Usage |
|----------|-------|-------|
| `PaymentStatusValues.pending` | `'pending'` | Awaiting payment |
| `PaymentStatusValues.paid` | `'paid'` | Payment complete |
| `PaymentStatusValues.failed` | `'failed'` | Payment failed |
| `PaymentStatusValues.refunded` | `'refunded'` | Refunded |

### Delivery Type

| Constant | Value | Usage |
|----------|-------|-------|
| `DeliveryTypeValues.pickup` | `'pickup'` | Local pickup |
| `DeliveryTypeValues.standard` | `'standard'` | Standard shipping |
| `DeliveryTypeValues.express` | `'express'` | Express shipping |
| `DeliveryTypeValues.sameDay` | `'same_day'` | Same-day delivery |
| `DeliveryTypeValues.localDelivery` | `'local_delivery'` | Local delivery (50km) |
| `DeliveryTypeValues.international` | `'international'` | International shipping |

### Carrier Values

| Constant | Value | Usage |
|----------|-------|-------|
| `CarrierValues.ups` | `'ups'` | UPS |
| `CarrierValues.fedex` | `'fedex'` | FedEx |
| `CarrierValues.canadaPost` | `'canada_post'` | Canada Post |
| `CarrierValues.purolator` | `'purolator'` | Purolator |
| `CarrierValues.dhl` | `'dhl'` | DHL |

---

## CloudFunctionEndpoints

Backend API endpoint names:

### Auth Endpoints

| Constant | Value | Usage |
|----------|-------|-------|
| `CloudFunctionEndpoints.deleteAccount` | `'delete_account'` | Delete user account |
| `CloudFunctionEndpoints.createUserProfile` | `'create_user_profile'` | Create profile |
| `CloudFunctionEndpoints.exportUserData` | `'export_my_data'` | GDPR export |

### Product Endpoints

| Constant | Value | Usage |
|----------|-------|-------|
| `CloudFunctionEndpoints.createProductAtomic` | `'create_product_atomic'` | Create product |
| `CloudFunctionEndpoints.updateProduct` | `'update_product'` | Update product |
| `CloudFunctionEndpoints.deleteProduct` | `'delete_product'` | Delete product |
| `CloudFunctionEndpoints.toggleFavorite` | `'toggle_favorite'` | Toggle favorite |

### Order Endpoints

| Constant | Value | Usage |
|----------|-------|-------|
| `CloudFunctionEndpoints.updateOrderStatus` | `'update_order_status'` | Update status |
| `CloudFunctionEndpoints.cancelOrder` | `'cancel_order'` | Cancel order |
| `CloudFunctionEndpoints.refundOrderItem` | `'refund_order_item'` | Refund item |

### Payment Endpoints

| Constant | Value | Usage |
|----------|-------|-------|
| `CloudFunctionEndpoints.createCheckoutSession` | `'create_checkout_session'` | Stripe Checkout |
| `CloudFunctionEndpoints.verifyCartPrices` | `'verify_cart_prices'` | Price verification |
| `CloudFunctionEndpoints.capturePayment` | `'capture_payment'` | Capture payment |

---

## Complete Usage Example

```dart
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:orignabase/orignabase.dart';

class ProductRepository {
  final OrignaBase ob;

  ProductRepository(this.ob);

  /// Fetch products with filters
  Future<List<Product>> fetchProducts({
    String? sellerId,
    int? minPriceCents,
    int? maxPriceCents,
    int limit = 20,
  }) async {
    // Build query using schema constants
    var query = ob.collection(Collections.products);
    
    if (sellerId != null) {
      query = query.where(Fields.sellerId, '==', sellerId);
    }
    
    if (minPriceCents != null) {
      query = query.where(Fields.priceCents, '>=', minPriceCents);
    }
    
    if (maxPriceCents != null) {
      query = query.where(Fields.priceCents, '<=', maxPriceCents);
    }
    
    query = query.orderBy(Fields.createdAt, descending: true);
    query = query.limit(limit);
    
    final snapshot = await query.get();
    
    return snapshot.docs.map((doc) {
      return Product(
        id: doc.id,
        name: doc.get(Fields.name),
        priceCents: doc.get(Fields.priceCents),
        sellerId: doc.get(Fields.sellerId),
        createdAt: doc.get(Fields.createdAt),
        stockQuantity: doc.get(Fields.stockQuantity) ?? 0,
      );
    }).toList();
  }

  /// Create order with proper field names
  Future<Order> createOrder({
    required String userId,
    required List<CartItem> items,
    required int subtotalCents,
    required int taxAmountCents,
    required int shippingCostCents,
    required Address shippingAddress,
  }) async {
    final orderData = {
      Fields.userId: userId,
      Fields.items: items.map((item) => item.toMap()).toList(),
      Fields.subtotalCents: subtotalCents,
      Fields.taxAmountCents: taxAmountCents,
      Fields.shippingCostCents: shippingCostCents,
      Fields.totalAmountCents: subtotalCents + taxAmountCents + shippingCostCents,
      Fields.currency: BusinessRules.defaultCurrency,
      Fields.status: OrderStatusValues.pending,
      Fields.paymentStatus: PaymentStatusValues.pending,
      Fields.shippingAddress: shippingAddress.toMap(),
      Fields.createdAt: DateTime.now(),
      Fields.sellerIds: items.map((i) => i.sellerId).toSet().toList(),
    };

    final docRef = await ob.collection(Collections.orders).add(orderData);
    
    return Order.fromMap(orderData, id: docRef.id);
  }
}
```

---

## Common Mistakes to Avoid

### ❌ Using string literals

```dart
// WRONG - Magic strings
doc.get('priceCents')
db.collection('products')
order['status'] == 'confirmed'
```

### ✅ Using schema constants

```dart
// CORRECT - Schema constants
doc.get(Fields.priceCents)
db.collection(Collections.products)
order[Fields.status] == OrderStatusValues.confirmed
```

---

### ❌ Inconsistent naming

```dart
// WRONG - Inconsistent (different from DB)
doc.get('price')  // DB field is 'priceCents'
doc.get('created_at')  // DB field is 'createdAt'
```

### ✅ Matching database schema

```dart
// CORRECT - Matches DB exactly
doc.get(Fields.priceCents)  // Matches 'priceCents'
doc.get(Fields.createdAt)   // Matches 'createdAt'
```

---

### ❌ Hardcoding business rules

```dart
// WRONG - Magic numbers
if (subtotal >= 7500) { /* free shipping */ }
if (orderAge > 5) { /* auto-confirm */ }
```

### ✅ Using business constants

```dart
// CORRECT - Business rules
if (subtotal >= BusinessRules.freeShippingThresholdCents) { /* free shipping */ }
if (orderAge > BusinessRules.autoConfirmDays) { /* auto-confirm */ }
```

---

## Quick Reference

| Category | Prefix | Example |
|----------|--------|---------|
| Collections | `Collections.` | `Collections.products` |
| Fields | `Fields.` | `Fields.priceCents` |
| API Keys | `ApiKeys.` | `ApiKeys.checkoutUrl` |
| Business Rules | `BusinessRules.` | `BusinessRules.platformFeePercent` |
| Order Status | `OrderStatusValues.` | `OrderStatusValues.confirmed` |
| Delivery Status | `DeliveryStatusValues.` | `DeliveryStatusValues.shipped` |
| Payment Status | `PaymentStatusValues.` | `PaymentStatusValues.paid` |
| Carriers | `CarrierValues.` | `CarrierValues.canadaPost` |
| Endpoints | `CloudFunctionEndpoints.` | `CloudFunctionEndpoints.createProductAtomic` |

---

*Last updated: 2026-03-25 | Source: `lib/core/schema/schema_constants.dart`*
