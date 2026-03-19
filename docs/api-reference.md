# OrignaGTA API Reference

**Backend**: OrignaBase Rust VPS (204.168.137.16)  
**Base URL**: https://api.orignagta.ca (production) | https://api.dev.orignagta.ca (dev)

---

## Authentication Endpoints

### POST /auth/register
Register a new user account.

**Authentication**: Public (Cloudflare Turnstile required in production)

**Request**:
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "displayName": "John Doe",
  "turnstileToken": "0x4AAA..."  // Web only; optional in dev (OB_TEST_MODE=1)
}
```

**Response** (201):
```json
{
  "accessToken": "REDACTED_SECRET",
  "refreshToken": "REDACTED_SECRET",
  "user": {
    "id": "users:abc123xyz",
    "email": "user@example.com",
    "displayName": "John Doe",
    "emailVerified": false,
    "createdAt": 1710691200
  }
}
```

**Errors**:
- `400`: Invalid email, weak password (<8 chars), or email already registered
- `429`: Rate limited (5 registrations per minute per IP)
- `500`: Server error (Turnstile service down)

**Side Effects**:
- User record created in `users` collection
- Verification email sent (if `require_email_verification=true` in config)
- Email-verification token generated and stored (expires in 24h)

---

### POST /auth/login
Authenticate with email and password.

**Authentication**: Public (Cloudflare Turnstile required in production)

**Request**:
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "turnstileToken": "0x4AAA..."
}
```

**Response** (200):
```json
{
  "accessToken": "REDACTED_SECRET",
  "refreshToken": "REDACTED_SECRET",
  "user": {
    "id": "users:abc123xyz",
    "email": "user@example.com",
    "emailVerified": true,
    "createdAt": 1710691200,
    "mfaEnabled": false
  },
  "mfaRequired": false  // true = client must send MFA challenge
}
```

**Errors**:
- `400`: Invalid credentials
- `401`: Email not verified (if required)
- `429`: Rate limited (5 attempts per minute per IP)

**Side Effects**:
- Login timestamp recorded in `login_tracking` collection
- Suspicious login detection (new IP → email alert)
- MFA challenge initiated if `mfaEnabled=true`

---

### POST /auth/refresh
Refresh access token using refresh token.

**Authentication**: Public (no JWT required; refresh token in body)

**Request**:
```json
{
  "refreshToken": "REDACTED_SECRET"
}
```

**Response** (200):
```json
{
  "accessToken": "REDACTED_SECRET",
  "refreshToken": "REDACTED_SECRET"
}
```

**Errors**:
- `401`: Invalid or expired refresh token
- `400`: Malformed token

**Side Effects**: None (stateless)

---

### POST /auth/verify-email
Verify email address using token from verification email.

**Authentication**: Public

**Request**:
```json
{
  "token": "REDACTED_SECRET"
}
```

**Response** (200):
```json
{
  "success": true
}
```

**Errors**:
- `400`: Invalid or expired token
- `404`: User not found

**Side Effects**:
- User's `emailVerified` flag set to `true`
- Verification token deleted

---

### POST /auth/send-verification
Resend verification email.

**Authentication**: JWT (user auth required)

**Request**: (empty body)

**Response** (200):
```json
{
  "success": true,
  "message": "Verification email sent"
}
```

**Errors**:
- `401`: Not authenticated
- `400`: Email already verified

**Side Effects**:
- New verification token generated
- Email sent to user's registered email address

---

### POST /auth/forgot-password
Request password reset via email.

**Authentication**: Public

**Request**:
```json
{
  "email": "user@example.com"
}
```

**Response** (200):
```json
{
  "success": true,
  "message": "If email exists, reset link sent"  // Always returns 200 for security
}
```

**Errors**:
- `429`: Rate limited (3 requests per hour per email)

**Side Effects**:
- Password reset token generated (expires in 1 hour)
- Email sent with reset link (only if email exists, but response never reveals this)

---

### POST /auth/reset-password
Reset password using token from reset email.

**Authentication**: Public

**Request**:
```json
{
  "token": "reset_abc123xyz",
  "newPassword": "NewPassword456!"
}
```

**Response** (200):
```json
{
  "success": true
}
```

**Errors**:
- `400`: Invalid token, expired token, or weak password
- `404`: User not found

**Side Effects**:
- User's password hash updated
- Reset token deleted
- All existing refresh tokens invalidated (forces re-login on all devices)

---

### POST /auth/mfa-setup
Initialize MFA (TOTP) setup.

**Authentication**: JWT (user auth required)

**Request**: (empty body)

**Response** (200):
```json
{
  "secret": "REDACTED_SECRET",
  "qrCodeUrl": "otpauth://totp/orignabase@user%40example.com?secret=JBSWY3DPEBLW64TMMQ%3D%3D%3D%3D%3D%3D&issuer=OrignaGTA",
  "backupCodes": [
    "abc123def456",
    "ghi789jkl012",
    "mno345pqr678",
    "stu901vwx234",
    "yza567bcd890"
  ]
}
```

**Errors**:
- `401`: Not authenticated
- `409`: MFA already enabled

**Side Effects**:
- Secret encrypted and stored temporarily (not yet active)
- Backup codes generated

---

### POST /auth/mfa-verify-setup
Confirm MFA setup by providing TOTP code.

**Authentication**: JWT

**Request**:
```json
{
  "code": "123456"  // 6-digit TOTP code
}
```

**Response** (200):
```json
{
  "success": true,
  "backupCodes": [
    "abc123def456",
    "ghi789jkl012"
  ]
}
```

**Errors**:
- `400`: Invalid TOTP code
- `401`: Not authenticated

**Side Effects**:
- MFA enabled for user
- `mfaEnabled` flag set to `true`
- Previous backup codes destroyed if re-setup

---

### POST /auth/mfa-challenge
Submit TOTP code during login (only if `mfaRequired=true` in login response).

**Authentication**: Public (uses temporary session token from login)

**Request**:
```json
{
  "code": "123456",
  "sessionToken": "sess_abc123xyz"
}
```

**Response** (200):
```json
{
  "accessToken": "REDACTED_SECRET",
  "refreshToken": "REDACTED_SECRET"
}
```

**Errors**:
- `400`: Invalid code
- `401`: Expired session token

**Side Effects**:
- Full access tokens issued
- Temporary session token invalidated

---

### POST /auth/mfa-recovery
Use backup code if TOTP device is lost.

**Authentication**: Public (uses temporary session token)

**Request**:
```json
{
  "backupCode": "abc123def456",
  "sessionToken": "sess_abc123xyz"
}
```

**Response** (200):
```json
{
  "accessToken": "...",
  "refreshToken": "...",
  "newBackupCodes": [
    "ghi789jkl012",
    "mno345pqr678"
  ]
}
```

**Errors**:
- `400`: Invalid backup code
- `401`: Expired session

**Side Effects**:
- Backup code marked as used
- New backup codes generated

---

### POST /auth/mfa-disable
Disable MFA on account.

**Authentication**: JWT + MFA challenge required (if enabled)

**Request**: (empty body)

**Response** (200):
```json
{
  "success": true
}
```

**Errors**:
- `401`: Not authenticated or MFA challenge failed

**Side Effects**:
- MFA disabled
- All backup codes destroyed

---

### GET /auth/providers
List available authentication providers.

**Authentication**: Public

**Request**: (no body)

**Response** (200):
```json
{
  "providers": [
    {
      "name": "google",
      "enabled": true,
      "clientId": "xxx-yyy.apps.googleusercontent.com"
    },
    {
      "name": "apple",
      "enabled": true
    },
    {
      "name": "oidc",
      "enabled": false
    }
  ]
}
```

**Errors**: None

---

### POST /auth/google/start
Initiate Google OAuth flow.

**Authentication**: Public

**Request**:
```json
{
  "redirectUrl": "https://app.orignagta.ca/auth/callback"
}
```

**Response** (200):
```json
{
  "authorizationUrl": "https://accounts.google.com/o/oauth2/v2/auth?client_id=...",
  "state": "state_abc123xyz"  // Store this for callback validation
}
```

**Errors**:
- `500`: Google OAuth not configured

---

### POST /auth/google/callback
Google OAuth callback handler.

**Authentication**: Public

**Request**:
```json
{
  "code": "4/0AY1...",
  "state": "state_abc123xyz"
}
```

**Response** (200):
```json
{
  "accessToken": "...",
  "refreshToken": "...",
  "user": { ... },
  "isNewUser": false  // true if created during OAuth
}
```

**Errors**:
- `400`: Invalid auth code or mismatched state
- `401`: Google API error

---

---

## Payment Endpoints

### POST /payments/checkout
Create a Stripe Checkout Session for order payment.

**Authentication**: JWT (buyer auth required)

**Request**:
```json
{
  "items": [
    {
      "productId": "products:xyz123",
      "quantity": 2,
      "sellerId": "users:seller_abc"
    }
  ],
  "shippingAddress": {
    "street": "123 Main St",
    "city": "Toronto",
    "province": "ON",
    "postalCode": "M5H 2N2",
    "country": "CA"
  },
  "shippingMethod": "standard",
  "idempotencyKey": "checkout_unique_identifier_123"
}
```

**Response** (200):
```json
{
  "checkoutUrl": "https://checkout.stripe.com/pay/cs_live_abc123...",
  "sessionId": "cs_live_abc123def456"
}
```

**Errors**:
- `400`: Invalid cart, missing address, or invalid postal code
- `401`: Not authenticated
- `403`: One or more products out of stock
- `422`: Invalid shipping method for items (e.g., perishable cross-province)
- `500`: Stripe API error

**Side Effects**:
- Stripe Checkout Session created
- Order(s) created in `pending` status
- Cart items reserved temporarily
- Webhook will confirm order on successful payment

**Critical Fields**:
- **idempotencyKey**: Prevents duplicate checkout sessions if retried
- **shippingAddress**: Must match Stripe's returned address for AML compliance
- **priceCents**: All prices in integer cents (no floats)

---

### GET /payments/checkout/{sessionId}
Retrieve checkout session details (debugging only).

**Authentication**: JWT

**Request**: (no body)

**Response** (200):
```json
{
  "sessionId": "cs_live_abc123...",
  "status": "open",
  "paymentStatus": "unpaid",
  "totalAmountCents": 15750,
  "expiresAt": 1710778800,
  "items": [...]
}
```

**Errors**:
- `401`: Not authenticated
- `404`: Session not found
- `403`: Not authorized to view this session

---

### POST /payments/capture
Manually capture a payment (admin only).

**Authentication**: JWT + Admin role

**Request**:
```json
{
  "paymentIntentId": "pi_abc123xyz",
  "idempotencyKey": "capture_unique_key_123"
}
```

**Response** (200):
```json
{
  "success": true,
  "capturedAt": 1710691200
}
```

**Errors**:
- `400`: Invalid payment intent
- `401`: Not authenticated
- `403`: Not admin
- `409`: Already captured or expired

**Side Effects**:
- Payment captured from Stripe
- Order status advanced to `confirmed`
- Stock decremented

---

### POST /stripe/webhook
Stripe webhook handler (signature-verified events only).

**Authentication**: Public (HMAC-SHA256 signature verification required)

**Request** (from Stripe):
```json
{
  "id": "evt_abc123",
  "type": "payment_intent.succeeded",
  "data": {
    "object": {
      "id": "pi_abc123xyz",
      "metadata": {
        "orderId": "orders:ord_abc123"
      }
    }
  }
}
```

**Response** (200): Always return 200 (webhook processed)

**Verification**:
```
Stripe-Signature: t=timestamp,v1=signature_hex
```
- Verify using webhook secret
- Reject unsigned or tampered events

**Events Handled**:
1. **payment_intent.succeeded**: Order confirmed, stock decremented
2. **payment_intent.failed**: Order cancelled, cart restored
3. **payment_intent.canceled**: Order cancelled
4. **charge.refunded**: Refund processed, stock restored
5. **customer.created/updated/deleted**: Seller Connect account sync

**Side Effects** (per event):
- Order status transitions
- Stock updates (atomic with SurrealDB transaction)
- Email notifications sent
- Webhook event recorded in `webhook_events` with idempotency deduplication

**Error Handling**:
- Invalid signature → silently log, return 200 (never 403, prevents attacker enumeration)
- Duplicate event (idempotency) → silently skip
- Database error → return 500 (Stripe will retry after exponential backoff)

---

---

## Product Endpoints

### GET /products
List products with filtering and search.

**Authentication**: Public

**Query Parameters**:
```
?search=laptop                    # Meilisearch query
&category=electronics             # Exact match on categoryId
&maxPrice=500000                  # Max price in cents
&sellerId=users:seller_xyz        # Filter by seller
&lifecycleStatus=active           # draft|active|inactive|deleted
&sortBy=price                     # price|createdAt|relevance
&limit=20                         # Page size (default 20)
&offset=0                         # Pagination offset
&filters[isPerishable]=true       # Faceted filters
```

**Response** (200):
```json
{
  "products": [
    {
      "id": "products:xyz123",
      "title": "MacBook Pro 16\"",
      "description": "2024 model...",
      "priceCents": 199999,  // $1999.99
      "currency": "CAD",
      "sellerId": "users:seller_abc",
      "sellerName": "Tech Shop",
      "images": [
        "https://r2.cloudflare.com/orignagta/prod_xyz123_1.jpg"
      ],
      "stockQuantity": 5,
      "isDigital": false,
      "isPerishable": false,
      "categories": ["electronics", "computers"],
      "rating": 4.7,
      "reviewCount": 24,
      "dateCreated": 1710691200,
      "lifecycleStatus": "active"
    }
  ],
  "total": 1243,
  "limit": 20,
  "offset": 0
}
```

**Errors**:
- `400`: Invalid search query or filter syntax
- `429`: Rate limited on search (30 per minute per IP)

**Search via Meilisearch**:
- Searchable fields: `title`, `description`, `keywords`, `categoryName`
- Filterable: `lifecycleStatus`, `priceCents`, `sellerId`, `isPerishable`, `categoryId`
- Sortable: `priceCents`, `dateCreated`

---

### GET /products/{productId}
Get single product details.

**Authentication**: Public

**Response** (200):
```json
{
  "id": "products:xyz123",
  "title": "MacBook Pro 16\"",
  "description": "2024 model with M4...",
  "longDescription": "Full detailed description...",
  "priceCents": 199999,
  "currency": "CAD",
  "sellerId": "users:seller_abc",
  "sellerName": "Tech Shop",
  "sellerRating": 4.8,
  "sellerReviewCount": 142,
  "images": [
    "https://r2.cloudflare.com/orignagta/prod_xyz123_1.jpg",
    "https://r2.cloudflare.com/orignagta/prod_xyz123_2.jpg"
  ],
  "stockQuantity": 5,
  "isDigital": false,
  "isPerishable": false,
  "weight": 2.1,  // kg
  "dimensions": { "length": 35.97, "width": 24.8, "height": 1.55 },
  "categories": ["electronics", "computers"],
  "tags": ["laptop", "apple", "pro"],
  "rating": 4.7,
  "reviewCount": 24,
  "dateCreated": 1710691200,
  "lifecycleStatus": "active",
  "specifications": {
    "processor": "Apple M4 Max",
    "ram": "36GB",
    "storage": "1TB SSD"
  },
  "reviews": [
    {
      "id": "reviews:rev_abc",
      "rating": 5,
      "title": "Excellent laptop",
      "text": "Very satisfied with purchase",
      "authorName": "John D.",
      "createdAt": 1710604800
    }
  ]
}
```

**Errors**:
- `404`: Product not found
- `410`: Product deleted

---

### POST /products
Create a new product (seller or admin).

**Authentication**: JWT (seller or admin)

**Request**:
```json
{
  "title": "MacBook Pro 16\"",
  "description": "Short description",
  "longDescription": "Full detailed description...",
  "priceCents": 199999,
  "weight": 2.1,
  "dimensions": { "length": 35.97, "width": 24.8, "height": 1.55 },
  "stockQuantity": 10,
  "isDigital": false,
  "isPerishable": false,
  "categories": ["electronics", "computers"],
  "tags": ["laptop", "apple"],
  "specifications": {
    "processor": "Apple M4 Max",
    "ram": "36GB"
  },
  "images": [
    "https://r2.cloudflare.com/orignagta/upload_temp_abc123_1.jpg"
  ]
}
```

**Response** (201):
```json
{
  "id": "products:xyz123",
  "title": "MacBook Pro 16\"",
  ...
  "lifecycleStatus": "draft",
  "dateCreated": 1710691200
}
```

**Errors**:
- `400`: Missing required fields or invalid data
- `401`: Not authenticated
- `403`: Not a seller
- `413`: Payload too large (>2MB)

**Side Effects**:
- Product created in `draft` status
- Indexed in Meilisearch (invisible until `active`)
- Image URLs stored (must be pre-uploaded to R2)

---

### PUT /products/{productId}
Update product (seller or admin).

**Authentication**: JWT (seller or admin)

**Request**: (same schema as POST, only changed fields required)

**Response** (200): Updated product object

**Errors**:
- `401`: Not authenticated
- `403`: Not owner or admin
- `404`: Product not found
- `409`: Product already confirmed (cannot edit after first sale)

**Side Effects**:
- Product updated in SurrealDB and Meilisearch
- If price/stock changed: cart validation triggered
- If status changed to `active`: indexed for search

---

### POST /products/{productId}/images
Upload product images.

**Authentication**: JWT (seller of product)

**Request**: multipart/form-data
```
Content-Type: multipart/form-data; boundary=----

------
Content-Disposition: form-data; name="image"; filename="product.jpg"
Content-Type: image/jpeg

[binary JPEG data]
------
```

**Response** (201):
```json
{
  "urls": [
    "https://r2.cloudflare.com/orignagta/products/prod_xyz123_1.jpg"
  ]
}
```

**Errors**:
- `400`: Invalid image format (only JPEG, PNG, GIF allowed)
- `413`: File too large (>5MB per image)
- `403`: Not owner of product

**Side Effects**:
- Images uploaded to Cloudflare R2
- URLs stored in product record
- Previous images preserved (no auto-delete)

---

---

## Order Endpoints

### GET /orders
List buyer's orders.

**Authentication**: JWT (buyer)

**Query Parameters**:
```
?status=confirmed              # pending|confirmed|shipped|delivered|cancelled
&sortBy=createdAt              # createdAt|totalAmountCents
&limit=20
&offset=0
```

**Response** (200):
```json
{
  "orders": [
    {
      "id": "orders:ord_abc123",
      "buyerId": "users:buyer_xyz",
      "sellerId": "users:seller_abc",
      "status": "shipped",
      "items": [
        {
          "productId": "products:xyz123",
          "name": "MacBook Pro 16\"",
          "quantity": 1,
          "unitPriceCents": 199999,
          "imageUrl": "https://r2.cloudflare.com/..."
        }
      ],
      "subtotalCents": 199999,
      "taxAmountCents": 25999,
      "shippingCostCents": 0,
      "platformFeeTotalCents": 5000,
      "totalAmountCents": 225998,
      "shippingAddress": {
        "street": "123 Main St",
        "city": "Toronto",
        "province": "ON",
        "postalCode": "M5H 2N2",
        "country": "CA"
      },
      "trackingNumber": "1Z999AA10123456784",
      "trackingUrl": "https://www.ups.com/track?tracknum=1Z999AA10123456784",
      "createdAt": 1710691200,
      "confirmedAt": 1710604800,
      "shippedAt": 1710518400,
      "deliveredAt": null,
      "cancelledAt": null,
      "cancelReason": null
    }
  ],
  "total": 15,
  "limit": 20,
  "offset": 0
}
```

**Errors**:
- `401`: Not authenticated

---

### GET /orders/{orderId}
Get single order details.

**Authentication**: JWT (buyer or seller of order, or admin)

**Response** (200): Single order object (same schema as list)

**Errors**:
- `401`: Not authenticated
- `403`: Not involved in this order
- `404`: Order not found

---

### POST /orders/{orderId}/confirm
Buyer confirms order delivery (after shipping).

**Authentication**: JWT (buyer)

**Request**: (empty body)

**Response** (200):
```json
{
  "success": true,
  "updatedAt": 1710691200
}
```

**Errors**:
- `400`: Order not in `shipped` status
- `401`: Not authenticated
- `403`: Not the buyer

**Side Effects**:
- Order status changed to `delivered`
- `deliveredAt` timestamp set
- Seller payout scheduled (if configured)
- Notification sent to seller

---

### POST /orders/{orderId}/cancel
Buyer or seller cancels order.

**Authentication**: JWT (buyer or seller)

**Request**:
```json
{
  "reason": "Changed my mind",
  "requestRefund": true
}
```

**Response** (200):
```json
{
  "success": true,
  "refundInitiated": true,
  "estimatedRefundDays": 3
}
```

**Errors**:
- `400`: Cannot cancel (order already delivered or previously cancelled)
- `401`: Not authenticated
- `403`: Not buyer or seller

**Side Effects**:
- Order status changed to `cancelled`
- Stock restored (atomic transaction)
- Stripe refund initiated (if payment captured)
- Notifications sent to both parties
- Refund appears in buyer's account in 3–5 business days

---

### POST /orders/{orderId}/ship
Seller marks order as shipped.

**Authentication**: JWT (seller of order)

**Request**:
```json
{
  "trackingNumber": "1Z999AA10123456784",
  "carrier": "UPS"
}
```

**Response** (200):
```json
{
  "success": true,
  "trackingUrl": "https://www.ups.com/track?tracknum=1Z999AA10123456784"
}
```

**Errors**:
- `400`: Order not in `confirmed` status or invalid tracking format
- `401`: Not authenticated
- `403`: Not the seller

**Side Effects**:
- Order status changed to `shipped`
- `shippedAt` timestamp set
- Email sent to buyer with tracking info
- Shipping widget activated in buyer's order view

---

---

## Return & Refund Endpoints

### POST /returns/request
Request a return (within 30 days of delivery).

**Authentication**: JWT (buyer)

**Request**:
```json
{
  "orderId": "orders:ord_abc123",
  "reason": "Defective",
  "description": "Screen flickering on startup",
  "photos": [
    "https://r2.cloudflare.com/orignagta/return_photo_1.jpg"
  ]
}
```

**Response** (201):
```json
{
  "id": "returns:ret_abc123",
  "orderId": "orders:ord_abc123",
  "status": "pending",
  "reason": "Defective",
  "createdAt": 1710691200,
  "expiresAt": 1711296000  // 7 days for seller to respond
}
```

**Errors**:
- `400`: Order not `delivered` or outside 30-day window
- `401`: Not authenticated
- `403`: Not the buyer
- `404`: Order not found

**Side Effects**:
- Return request created in `pending` status
- Seller notified via email and dashboard
- Buyer instructed to await return label/instructions

---

### POST /returns/{returnId}/approve
Seller approves return (seller endpoint).

**Authentication**: JWT (seller)

**Request**:
```json
{
  "refundAmountCents": 199999,  // Can be partial
  "message": "Approved. Please ship to return address on email."
}
```

**Response** (200):
```json
{
  "success": true,
  "returnLabel": {
    "carrier": "UPS",
    "labelUrl": "https://r2.cloudflare.com/orignagta/return_label_abc.pdf"
  },
  "refundInitiated": true
}
```

**Errors**:
- `400`: Refund amount exceeds original order total
- `401`: Not authenticated
- `403`: Not the seller

**Side Effects**:
- Return status changed to `approved`
- Return label generated and sent to buyer
- Stripe refund initiated (async)
- Stock restored (if applicable)
- Seller account updated (dispute tracking)

---

### POST /returns/{returnId}/reject
Seller rejects return.

**Authentication**: JWT (seller)

**Request**:
```json
{
  "reason": "Not defective — normal wear"
}
```

**Response** (200):
```json
{
  "success": true
}
```

**Errors**:
- `401`: Not authenticated
- `403`: Not the seller

**Side Effects**:
- Return status changed to `rejected`
- Buyer notified via email
- Return dispute logged

---

---

## Admin Endpoints

All admin endpoints require `admin` role claim in JWT.

### GET /admin/users
List all users.

**Authentication**: JWT + Admin role

**Query Parameters**:
```
?search=john                   # Search name/email
&role=seller                   # seller|buyer|admin
&createdAfter=1710604800
&limit=50
&offset=0
```

**Response** (200):
```json
{
  "users": [
    {
      "id": "users:abc123",
      "email": "seller@example.com",
      "displayName": "John Doe",
      "role": "seller",
      "emailVerified": true,
      "createdAt": 1710691200,
      "lastLoginAt": 1710778800,
      "isSuspended": false
    }
  ],
  "total": 1523
}
```

---

### POST /admin/users/{userId}/suspend
Suspend a user account (fraud, ToS violation).

**Authentication**: JWT + Admin role

**Request**:
```json
{
  "reason": "Suspicious payment activity",
  "duration": 7  // days; null = permanent
}
```

**Response** (200):
```json
{
  "success": true,
  "suspendedUntil": 1711296000
}
```

**Side Effects**:
- User's `isSuspended` flag set
- All active sessions invalidated
- Listings hidden (if seller)
- Notifications sent to user

---

### GET /admin/orders
List all orders (with filtering).

**Authentication**: JWT + Admin role

**Query Parameters**:
```
?status=pending
&buyerId=users:abc
&sellerId=users:xyz
&createdAfter=1710604800
&limit=50
```

**Response** (200): Array of all orders (unrestricted)

---

### POST /admin/orders/{orderId}/capture
Manually capture a payment that failed to authorize.

**Authentication**: JWT + Admin role

**Request**:
```json
{
  "reason": "Customer confirmed retry"
}
```

**Response** (200):
```json
{
  "success": true,
  "capturedAt": 1710691200
}
```

---

---

## Storage / Upload Endpoints

### POST /storage/upload
Upload a file to Cloudflare R2 (user or admin).

**Authentication**: JWT

**Request**: multipart/form-data
```
Content-Type: multipart/form-data; boundary=----

------
Content-Disposition: form-data; name="file"; filename="image.jpg"
Content-Type: image/jpeg

[binary data]
------
```

**Response** (200):
```json
{
  "url": "https://r2.cloudflare.com/orignagta/uploads/temp_abc123.jpg",
  "key": "uploads/temp_abc123.jpg"
}
```

**Errors**:
- `400`: Invalid file type
- `413`: File too large (>5MB)

---

### GET /storage/signed-url/{key}
Get a signed download URL for a private file.

**Authentication**: JWT

**Request**: (no body)

**Response** (200):
```json
{
  "url": "https://r2.cloudflare.com/orignagta/...?X-Amz-Signature=...",
  "expiresIn": 3600  // seconds
}
```

---

---

## Error Response Format

All errors follow this schema:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid email address",
    "details": {
      "field": "email",
      "reason": "Not a valid email format"
    },
    "requestId": "req_abc123xyz"  // For debugging
  }
}
```

### Common Error Codes

| Code | HTTP | Meaning |
|------|------|---------|
| `VALIDATION_ERROR` | 400 | Invalid input |
| `UNAUTHORIZED` | 401 | Not authenticated or JWT expired |
| `FORBIDDEN` | 403 | Authenticated but not permitted |
| `NOT_FOUND` | 404 | Resource doesn't exist |
| `CONFLICT` | 409 | State conflict (e.g., already cancelled) |
| `RATE_LIMITED` | 429 | Too many requests; check `Retry-After` header |
| `UNPROCESSABLE` | 422 | Business logic error (e.g., out of stock) |
| `INTERNAL_ERROR` | 500 | Server error; check `requestId` in logs |

---

## Rate Limiting

All endpoints enforce IP-based rate limiting:

| Category | Limit | Window |
|----------|-------|--------|
| Auth (login/register) | 5 | 1 minute |
| Password reset | 3 | 1 hour |
| Search | 30 | 1 minute |
| Checkout | 10 | 1 minute |
| General API | 100 | 1 minute |

**Response Headers**:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1710691260
```

When rate limited, the response includes `Retry-After: 60` (seconds to wait).

---

## Authentication

### JWT Format
Issued by `/auth/login` and `/auth/register`:
```
```

**Access Token Claims** (RS256, 15 min expiry):
```json
{
  "sub": "users:abc123",
  "email": "user@example.com",
  "roles": ["seller"],
  "iat": 1710691200,
  "exp": 1710692100
}
```

**Refresh Token** (HS256, 7 day expiry): Used only at `/auth/refresh`.

### Role-Based Access Control

| Role | Permissions |
|------|-------------|
| `buyer` | Create orders, manage own orders, leave reviews |
| `seller` | Create/edit products, manage own orders, withdraw earnings |
| `admin` | All permissions + user suspension, analytics, payment overrides |

---

## Idempotency

Endpoints that modify state support idempotency via the `idempotencyKey` parameter:

```json
{
  "action": "...",
  "idempotencyKey": "REDACTED_SECRET"
}
```

The server returns the same response if called twice with the same key within 24 hours. This prevents duplicate charges or orders if a network error occurs.

---

## Pagination

List endpoints use offset-based pagination:

```
/products?limit=20&offset=40
```

Returns:
```json
{
  "items": [...],
  "total": 1243,
  "limit": 20,
  "offset": 40,
  "hasMore": true
}
```

For large result sets (>10,000 items), cursor pagination will be added in future versions.

---

## Webhooks

See `webhooks.md` for complete webhook documentation (signatures, events, retry policies).

---

**Last Updated**: March 18, 2026  
**API Version**: 1.0  
**Status**: Production
