# OrignaGTA Database Schema Reference

Complete reference for all SurrealDB collections, fields, types, and relationships in OrignaGTA.

---

## Collections Overview

| Collection | Purpose | Primary Key | Timestamp Field |
|---|---|---|---|
| **users** | User accounts (buyers, sellers, admins) | `users:id` | `createdAt` |
| **products** | Product listings | `products:id` | `dateCreated` |
| **orders** | Orders (one per seller per checkout) | `orders:id` | `createdAt` |
| **cart** | Shopping cart items | `cart:id` | `dateCreated` |
| **addresses** | User saved addresses | `addresses:id` | `dateCreated` |
| **seller_profiles** | Seller-specific data (Stripe, payouts) | `seller_profiles:uid` | — |
| **return_requests** | Return/refund requests | `returns:id` | `createdAt` |
| **reviews** | Product reviews | `reviews:id` | `createdAt` |
| **webhook_events** | Stripe webhook event log (idempotency) | `webhook_events:eventId` | `timestamp` |
| **admin_actions** | Admin audit log | `admin_actions:id` | `createdAt` |
| **login_tracking** | Login history (security) | `login_tracking:id` | `createdAt` |

---

## users

User accounts for all roles: buyer, seller, admin.

```javascript
{
  "id": "users:abc123xyz",
  "email": "user@example.com",
  "displayName": "John Doe",
  "role": "buyer" | "seller" | "admin",
  "emailVerified": true,
  "passwordHash": "bcrypt_hash_...",
  "createdAt": 1710691200,
  "lastLoginAt": 1710778800,
  
  // Profile
  "profileImageUrl": "https://r2.cloudflare.com/...",
  "bio": "Product enthusiast",
  "phoneNumber": "+14165551234",
  
  // Address (default)
  "addressId": "addresses:home_abc123" | null,
  
  // Seller info (null for buyers)
  "sellerName": "Tech Shop" | null,
  "sellerDescription": "We sell quality electronics" | null,
  
  // MFA
  "mfaEnabled": false,
  "mfaTotpSecret": "encrypted_secret_...",  // Encrypted at rest
  "mfaBackupCodes": ["abc123...", ...],     // Encrypted at rest
  
  // Status
  "isSuspended": false,
  "suspendedUntil": 1711296000 | null,
  "suspendReason": "Fraudulent activity" | null,
  
  // Compliance
  "acceptedTerms": true,
  "acceptedTermsAt": 1710691200,
  "ageVerified": false,  // For age-restricted products
}
```

### Field Details

| Field | Type | Required | Constraints |
|---|---|---|---|
| `id` | String | ✓ | Format: `users:uuid` |
| `email` | String | ✓ | Unique, lowercase, validated |
| `displayName` | String | ✓ | 1–100 chars |
| `role` | Enum | ✓ | `buyer`, `seller`, `admin` |
| `emailVerified` | Boolean | ✓ | Default: false |
| `passwordHash` | String | ✓ | bcrypt, never returned in API |
| `createdAt` | Integer | ✓ | Unix timestamp |
| `lastLoginAt` | Integer | — | Unix timestamp or null |
| `profileImageUrl` | String | — | HTTPS URL to R2 |
| `mfaEnabled` | Boolean | ✓ | Default: false |
| `isSuspended` | Boolean | ✓ | Default: false |
| `acceptedTerms` | Boolean | ✓ | Required to use platform |

### Row-Level Security (Permissions)

```sql
DEFINE TABLE users PERMISSIONS
  GRANT SELECT ON users WHERE $auth.id = id OR $auth.roles CONTAINS 'admin'
  GRANT UPDATE ON users WHERE $auth.id = id OR $auth.roles CONTAINS 'admin';
```

Buyers can only read/write their own user record. Admins can access all.

---

## products

Product listings created by sellers.

```javascript
{
  "id": "products:xyz123def",
  "sellerId": "users:seller_abc",
  "title": "MacBook Pro 16\"",
  "description": "Short description",
  "longDescription": "Detailed 2000+ char description",
  "priceCents": 199999,  // Always integer cents, never float
  "currency": "CAD",  // Always CAD for now
  "dateCreated": 1710691200,
  
  // Stock & Type
  "stockQuantity": 5,  // 0 = out of stock
  "isDigital": false,  // Digital products: no shipping
  "isPerishable": false,  // Perishable: local delivery only (<50km)
  
  // Shipping (null for digital)
  "weight": 2.1,  // kg
  "dimensions": {
    "length": 35.97,  // cm
    "width": 24.8,
    "height": 1.55
  },
  
  // Media
  "images": [
    "https://r2.cloudflare.com/orignagta/products/xyz123_1.jpg",
    "https://r2.cloudflare.com/orignagta/products/xyz123_2.jpg"
  ],
  "videoUrl": "https://r2.cloudflare.com/orignagta/products/xyz123_video.mp4" | null,
  
  // Categorization
  "categories": ["electronics", "computers"],
  "tags": ["apple", "laptop", "pro"],
  "specifications": {
    "processor": "Apple M4 Max",
    "ram": "36GB",
    "storage": "1TB SSD"
  },
  
  // Status & Lifecycle
  "lifecycleStatus": "draft" | "active" | "inactive" | "deleted",
  
  // Search & Discovery
  "keywords": "macbook laptop computer",
  "searchRelevance": 0.95,  // Auto-computed for ranking
  
  // Ratings
  "rating": 4.7,  // Aggregate 1–5
  "reviewCount": 24,
  "salesCount": 142,
  
  // Metadata
  "sku": "SKU-ABC123",  // Seller's SKU, optional
  "externalUrl": "https://seller.com/product",  // Seller's own site
}
```

### Field Details

| Field | Type | Required | Constraints |
|---|---|---|---|
| `id` | String | ✓ | Format: `products:uuid` |
| `sellerId` | String | ✓ | Foreign key to `users.id` |
| `title` | String | ✓ | 1–200 chars |
| `description` | String | ✓ | 10–500 chars |
| `longDescription` | String | — | 0–5000 chars |
| `priceCents` | Integer | ✓ | 100 to 10,000,000 (≤$100k CAD) |
| `stockQuantity` | Integer | ✓ | ≥0 |
| `isDigital` | Boolean | ✓ | Default: false |
| `isPerishable` | Boolean | ✓ | Default: false |
| `images` | Array[String] | ✓ | 1–5 URLs, HTTPS only |
| `categories` | Array[String] | ✓ | 1+ valid category IDs |
| `lifecycleStatus` | Enum | ✓ | `draft`, `active`, `inactive`, `deleted` |

### Status Transitions

```
draft → active (seller manually publishes)
active → inactive (seller hides or runs out of stock)
inactive → active (seller republishes)
* → deleted (soft delete by seller or admin)
```

### Search Integration

- **Indexed in Meilisearch** with ID format `products_xyz123` (`:` → `_`)
- **Searchable fields**: `title`, `description`, `keywords`, `categories`
- **Filterable**: `lifecycleStatus`, `priceCents`, `sellerId`, `isPerishable`
- **Sortable**: `priceCents`, `dateCreated`, `salesCount`

---

## orders

One order per seller per checkout. If buyer buys from 2 sellers, creates 2 order records.

```javascript
{
  "id": "orders:ord_abc123",
  "buyerId": "users:buyer_xyz",
  "sellerId": "users:seller_abc",
  
  // Status Machine
  "status": "pending" | "confirmed" | "shipped" | "delivered" | "cancelled",
  
  // Timeline
  "createdAt": 1710691200,
  "confirmedAt": 1710604800 | null,
  "shippedAt": 1710518400 | null,
  "deliveredAt": 1710432000 | null,
  "cancelledAt": null,
  "cancelReason": null,
  
  // Items (snapshot at creation)
  "items": [
    {
      "productId": "products:xyz123",
      "name": "MacBook Pro 16\"",
      "quantity": 1,
      "unitPriceCents": 199999,
      "imageUrl": "https://r2.cloudflare.com/...",
      "isDigital": false,
      "licenseKey": null  // For digital products
    }
  ],
  
  // Pricing (all integer cents)
  "subtotalCents": 199999,  // Sum of items
  "taxAmountCents": 25999,  // Calculated per province
  "shippingCostCents": 0,  // 0 if free shipping (subtotal >= $75)
  "platformFeeTotalCents": 5000,  // 2.5% of subtotal
  "totalAmountCents": 225998,  // subtotal + tax + shipping - (platform fee already in subtotal)
  
  // Shipping
  "shippingAddress": {
    "street": "123 Main St",
    "city": "Toronto",
    "province": "ON",
    "postalCode": "M5H 2N2",
    "country": "CA",
    "phoneNumber": "+14165551234"
  },
  "shippingMethod": "standard" | "express" | "local_pickup",
  "trackingNumber": "1Z999AA10123456784" | null,
  "trackingUrl": "https://www.ups.com/track?..." | null,
  
  // Payment
  "paymentIntentId": "pi_abc123xyz",  // Stripe
  "captured": true,  // Payment captured?
  "refundedCents": 0,  // Total refunded
  
  // Notes
  "buyerNotes": "Please gift wrap",
  "sellerNotes": "Process ASAP",
}
```

### Field Details

| Field | Type | Required | Constraints |
|---|---|---|---|
| `id` | String | ✓ | Format: `orders:uuid` |
| `buyerId` | String | ✓ | Foreign key to `users.id` |
| `sellerId` | String | ✓ | Foreign key to `users.id` |
| `status` | Enum | ✓ | Must follow state machine |
| `createdAt` | Integer | ✓ | Unix timestamp |
| `items` | Array[Object] | ✓ | 1+ items |
| `subtotalCents` | Integer | ✓ | ≥100 |
| `taxAmountCents` | Integer | ✓ | ≥0 |
| `shippingCostCents` | Integer | ✓ | 0–50,000 |
| `totalAmountCents` | Integer | ✓ | ≥100 |
| `paymentIntentId` | String | — | Only after payment |
| `captured` | Boolean | ✓ | Default: false |

### Status State Machine

```
pending ──[payment.succeeded]──> confirmed ──[seller ships]──> shipped ──[buyer confirms]──> delivered
  ↓                                ↓
[payment.failed/cancelled]      [seller cancels]
  ↓                                ↓
cancelled                      cancelled
```

**Terminal states**: `delivered`, `cancelled` (no further transitions)

---

## cart

Shopping cart items. Automatically synced with real-time updates.

```javascript
{
  "id": "cart:abc123",
  "buyerId": "users:buyer_xyz",
  "productId": "products:xyz123",
  "quantity": 2,
  "dateCreated": 1710691200,
  
  // Cached for instant display
  "productName": "MacBook Pro 16\"",
  "priceCents": 199999,
  "imageUrl": "https://r2.cloudflare.com/...",
  "sellerId": "users:seller_abc",
}
```

### Notes

- No explicit cart "document" — just collection of cart items
- Real-time subscription keeps UI in sync
- Items auto-removed if product deleted
- Stock validation at checkout

---

## addresses

Saved shipping addresses for quick checkout.

```javascript
{
  "id": "addresses:home_abc123",
  "userId": "users:buyer_xyz",
  "label": "Home" | "Work" | "Other",
  "street": "123 Main St",
  "city": "Toronto",
  "province": "ON",
  "postalCode": "M5H 2N2",
  "country": "CA",
  "phoneNumber": "+14165551234",
  "isDefault": true,
  "dateCreated": 1710691200,
}
```

### Field Details

| Field | Type | Required | Constraints |
|---|---|---|---|
| `id` | String | ✓ | Format: `addresses:uuid` |
| `userId` | String | ✓ | Foreign key to `users.id` |
| `label` | Enum | ✓ | `Home`, `Work`, `Other` |
| `postalCode` | String | ✓ | Format: `A1A 1A1` (Canada) |
| `province` | String | ✓ | 2-letter code (ON, BC, AB, etc.) |

---

## seller_profiles

Extended seller information (not in `users`).

```javascript
{
  "id": "seller_profiles:uid",  // uid from users.id
  "sellerId": "users:seller_abc",
  
  // Legal
  "businessName": "Tech Shop Inc.",
  "businessType": "sole_proprietor" | "corporation" | "partnership",
  "taxId": "123456789",  // SSN or BN
  
  // Stripe Connect
  "stripeConnectAccountId": "acct_abc123xyz",
  "stripeCustomerId": "cus_abc123xyz",
  "detailsSubmitted": true,  // Onboarding complete?
  "chargesEnabled": true,  // Can accept payments?
  
  // Payout
  "bankAccountId": "ba_abc123xyz",  // Stripe
  "payoutCycle": "daily" | "weekly" | "monthly",
  "nextPayoutAt": 1710778800,
  
  // Analytics
  "totalSalesCount": 142,
  "totalEarningsCents": 28500000,  // Cumulative
  "averageRating": 4.8,
  "disputeRate": 0.02,  // 2% disputes
  "refundRate": 0.05,  // 5% refunds
  
  // Settings
  "description": "Quality electronics since 2024",
  "returnPolicy": "30-day money back guarantee",
  "shippingPolicy": "Free shipping on orders >$75",
}
```

### Notes

- **Not a direct sub-collection** of `users` — separate document
- Keyed by seller's UID (not full `users:uid` path)
- Updated whenever Stripe account status changes
- Stripe webhooks update this in real-time

---

## return_requests

Return/refund requests from buyers.

```javascript
{
  "id": "returns:ret_abc123",
  "orderId": "orders:ord_abc123",
  "buyerId": "users:buyer_xyz",
  "sellerId": "users:seller_abc",
  
  // Status
  "status": "pending" | "approved" | "rejected" | "completed",
  
  // Reason
  "reason": "Defective" | "NotAsDescribed" | "ChangedMind",
  "description": "Screen flickering on startup",
  
  // Evidence
  "photos": [
    "https://r2.cloudflare.com/orignagta/return_photo_1.jpg"
  ],
  
  // Refund Details
  "refundAmountCents": 199999,  // Can be partial
  "returnLabel": {
    "carrier": "UPS",
    "trackingNumber": "1Z999AA...",
    "labelUrl": "https://r2.cloudflare.com/return_label.pdf"
  },
  
  // Timeline
  "createdAt": 1710691200,
  "approvedAt": 1710604800 | null,
  "expiresAt": 1711296000,  // Seller must respond within 7 days
  
  // Messages
  "buyerMessage": "Item arrived damaged",
  "sellerResponse": "Approved. Return label sent.",
}
```

### Field Details

| Field | Type | Required | Constraints |
|---|---|---|---|
| `orderId` | String | ✓ | Foreign key to `orders.id` |
| `reason` | Enum | ✓ | `Defective`, `NotAsDescribed`, `ChangedMind` |
| `refundAmountCents` | Integer | ✓ | ≤ original order total |
| `status` | Enum | ✓ | Must follow workflow |

### Status Workflow

```
pending ──[seller approves]──> approved ──[refund processed]──> completed
  ↓
[seller rejects or expires]
  ↓
rejected
```

---

## reviews

Product reviews from buyers who purchased.

```javascript
{
  "id": "reviews:rev_abc123",
  "productId": "products:xyz123",
  "buyerId": "users:buyer_xyz",
  "orderId": "orders:ord_abc123",  // Proof of purchase
  
  "rating": 5,  // 1–5 stars
  "title": "Excellent laptop",
  "text": "Very satisfied with purchase. Great performance.",
  "photos": [
    "https://r2.cloudflare.com/orignagta/review_photo_1.jpg"
  ],
  
  "createdAt": 1710691200,
  "updatedAt": 1710691200,
  "helpfulCount": 12,  // Buyer count
  
  // Seller response
  "sellerResponse": "Thank you for the review!",
  "sellerResponseAt": 1710604800 | null,
}
```

### Field Details

| Field | Type | Required | Constraints |
|---|---|---|---|
| `rating` | Integer | ✓ | 1–5 |
| `title` | String | ✓ | 1–100 chars |
| `text` | String | ✓ | 10–1000 chars |
| `orderId` | String | ✓ | Proof of genuine purchase |
| `photos` | Array[String] | — | 0–5 images |

---

## webhook_events

Stripe webhook event log (prevents duplicate processing).

```javascript
{
  "id": "webhook_events:evt_abc123xyz",
  "eventId": "evt_abc123xyz",  // Stripe event ID (unique)
  "eventType": "payment_intent.succeeded",
  
  "payload": {
    // Full Stripe event object
    "type": "payment_intent.succeeded",
    "data": { ... }
  },
  
  "processed": true,
  "processedAt": 1710691201,
  "orderId": "orders:ord_abc123",  // Extracted from metadata
  
  "timestamp": 1710691200,  // Stripe event timestamp
  "createdAt": 1710691200,  // When we logged it
}
```

### Notes

- **Timestamp field is `timestamp`**, not `createdAt` (for Stripe event time)
- Checked before processing any webhook
- Acts as idempotency log

---

## admin_actions

Audit log for admin operations.

```javascript
{
  "id": "admin_actions:act_abc123",
  "adminId": "users:admin_xyz",
  "action": "suspend_user" | "refund_order" | "delete_product" | "update_taxes",
  "resourceType": "user" | "order" | "product",
  "resourceId": "users:buyer_123",
  "details": {
    "reason": "Fraudulent activity",
    "duration": 7
  },
  "createdAt": 1710691200,
}
```

---

## login_tracking

Login history for security.

```javascript
{
  "id": "login_tracking:log_abc123",
  "userId": "users:buyer_xyz",
  "timestamp": 1710691200,
  
  "ipAddress": "hash_of_ip",  // Hashed for privacy
  "userAgent": "Mozilla/5.0...",
  "country": "CA",
  "city": "Toronto",
  
  "successful": true,
  "failureReason": null | "invalid_credentials",
  
  "isSuspicious": false,  // True if new IP
  "alerted": false,
}
```

---

## Field Type Reference

| Type | Example | Notes |
|---|---|---|
| **String** | `"Hello"` | UTF-8, max 65536 chars |
| **Integer** | `1710691200` | 64-bit signed |
| **Float** | `4.7` | ❌ NEVER for money (use cents as integer) |
| **Boolean** | `true` | |
| **Array** | `["a", "b"]` | Heterogeneous values ok |
| **Object** | `{"key": "value"}` | Nested objects ok |
| **Datetime** | `1710691200` | Unix timestamp (integer), not ISO string |
| **null** | `null` | Represents missing value |

---

## Common Patterns

### Money (CRITICAL)

❌ **WRONG**: `priceCents: 19.99` (float → rounding errors)

✓ **RIGHT**: `priceCents: 1999` (integer cents)

Display: `\$${cents / 100}`

### Timestamps

❌ **WRONG**: `"2024-03-18T12:00:00Z"` (ISO string)

✓ **RIGHT**: `1710691200` (Unix timestamp, integer)

### Foreign Keys

Use full SurrealDB ID format: `users:abc123`, not just `abc123`

### Arrays in Meilisearch

- Meilisearch ID: `products_xyz123` (`:` → `_`)
- Keep `origId` field with original `products:xyz123`

---

## Indexing Strategy

**SurrealDB Indexes** (for WHERE clauses):
```sql
DEFINE INDEX idx_orders_buyer ON orders COLUMNS buyerId;
DEFINE INDEX idx_orders_status ON orders COLUMNS status;
DEFINE INDEX idx_products_seller ON products COLUMNS sellerId;
DEFINE INDEX idx_cart_buyer ON cart COLUMNS buyerId;
```

**Meilisearch Indexes** (for full-text search):
- `products` → `products_index` (searchable, filterable, sortable)

---

## Row-Level Security

All sensitive tables have PERMISSIONS:

```sql
-- Users can only read their own profile
DEFINE TABLE users PERMISSIONS
  GRANT SELECT ON users WHERE $auth.id = id OR $auth.roles CONTAINS 'admin';

-- Sellers can only read their own products
DEFINE TABLE products PERMISSIONS
  GRANT SELECT ON products
  GRANT CREATE ON products WHERE $auth.id = sellerId
  GRANT UPDATE ON products WHERE $auth.id = sellerId;

-- Buyers can only read their own orders
DEFINE TABLE orders PERMISSIONS
  GRANT SELECT ON orders WHERE $auth.id IN [buyerId, sellerId] OR $auth.roles CONTAINS 'admin';
```

---

**Last Updated**: March 18, 2026  
**Schema Version**: 1.0  
**SurrealDB Version**: 2.0+
