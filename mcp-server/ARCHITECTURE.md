# OrignaGTA MCP Server — Architecture & Design

## Overview

The MCP server enables AI agents to interact with the OrignaGTA e-commerce platform with full purchase capability through Stripe integration. It provides 14 production-ready tools organized by domain.

## Design Principles

1. **Type Safety**: Full TypeScript with strict mode enabled
2. **Security**: JWT auth, role-based access, input validation, no PII logging
3. **Money**: All prices in integer cents (no float precision errors)
4. **Modularity**: One tool file per domain (products, orders, cart, checkout, etc.)
5. **Error Handling**: Custom error classes with proper HTTP status codes
6. **Observability**: Structured JSON logging with request context

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  MCP Client (Claude, etc.)                  │
└────────────────────────┬────────────────────────────────────┘
                         │ MCP Protocol (stdio)
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    MCP Server (index.ts)                    │
│  • Tool dispatcher                                          │
│  • Error handling & logging                                 │
│  • Request/response marshaling                              │
└────────────────────────┬────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
    ┌────────────┐ ┌────────────┐ ┌──────────────┐
    │  Products  │ │   Orders   │ │     Cart     │
    │   Tools    │ │   Tools    │ │    Tools     │
    └────────┬───┘ └────────┬───┘ └──────┬───────┘
             │              │            │
             │     ┌────────┼────────┐   │
             │     ▼        ▼        ▼   │
             │  ┌─────────────────────┐  │
             │  │   Validation.ts     │  │
             │  │   • price cents     │  │
             │  │   • postal codes    │  │
             │  │   • phone numbers   │  │
             │  │   • string lengths  │  │
             │  └─────────────────────┘  │
             │           ▲                │
             ├───────────┤                │
             │           ▼                │
             │  ┌─────────────────────┐  │
             │  │   Auth.ts           │  │
             │  │   • JWT parsing     │  │
             │  │   • Role checks     │  │
             │  │   • User context    │  │
             │  └─────────────────────┘  │
             │           ▲                │
             ├───────────┤                │
             │           ▼                │
             │  ┌─────────────────────┐  │
             │  │  Logger.ts          │  │
             │  │  • Structured logs  │  │
             │  │  • PII sanitization │  │
             │  │  • Request tracking │  │
             │  └─────────────────────┘  │
             │           ▲                │
             ├───────────┤                │
             │           ▼                │
             │  ┌─────────────────────┐  │
             │  │  Errors.ts          │  │
             │  │  • Custom classes   │  │
             │  │  • Status codes     │  │
             │  │  • Safe responses   │  │
             │  └─────────────────────┘  │
             └───────────┬────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │ Checkout Tools                │ Analytics Tools
         │ + Stripe Integration          │ (admin only)
         ▼                               ▼
    ┌────────────┐                  ┌────────────┐
    │Stripe API  │                  │ OrignaBase │
    │• Sessions  │                  │   Admin    │
    │• Payment   │                  │  Endpoint  │
    │  Links     │                  └────────────┘
    │• Embed UI  │
    │• Tax calc  │
    └────────────┘
         ▲
         │
         └────────────────────┐
                              │
                 ┌────────────┴────────────┐
                 │                         │
            ┌────────────────────────┐   ┌────────────────────────┐
            │   OrignaBase VPS        │   │   SurrealDB            │
            │   204.168.137.16:8081   │   │   Collections:         │
            │   (dev environment)     │   │   • products           │
            │                         │   │   • orders             │
            │ APIs:                   │   │   • users              │
            │ • /products/*           │   │   • cart               │
            │ • /orders/*             │   │   • reviews            │
            │ • /cart/*               │   │   • return_requests    │
            │ • /checkout             │   │   • seller_profiles    │
            │ • /stripe/webhook       │   │   • webhook_events     │
            │ • /analytics            │   │   • payouts            │
            └────────────────────────┘   └────────────────────────┘
```

## Module Structure

### Core Modules

#### `index.ts` (Main Server)
- MCP server initialization
- Tool registration & dispatcher
- Request/response handling
- Error catch-all

#### `types.ts`
- Product, Order, Cart, Address, Review, etc.
- Tool parameter interfaces (SearchProductsParams, etc.)
- Stripe response types
- API response shapes

#### `auth.ts`
- JWT token extraction from env
- JWT payload parsing (client-side)
- Role validation (admin, seller, buyer)
- User context enrichment

#### `api-client.ts`
- Axios HTTP client with auth headers
- OrignaBase endpoint methods
- Error handling & rate limit detection
- Idempotency key generation

### Tool Modules

#### `tools/products.ts` (3 tools)
- `search_products()` — Meilisearch integration
- `get_product()` — Product details with reviews
- `check_inventory()` — Real-time stock status

#### `tools/orders.ts` (3 tools)
- `list_orders()` — Paginated order list with filtering
- `get_order()` — Order details with scope checking
- `request_return()` — Return workflow initiation

#### `tools/cart.ts` (3 tools)
- `get_cart()` — Current cart contents & totals
- `add_to_cart()` — Quantity validation
- `remove_from_cart()` — Item removal

#### `tools/checkout.ts` (2 tools)
- `create_checkout()` — **AGENT PURCHASE POINT** — Stripe Checkout with latest features
- `apply_coupon()` — Discount code handling

#### `tools/reviews.ts` (1 tool)
- `submit_review()` — Product review posting (buyer only)

#### `tools/analytics.ts` (1 tool)
- `get_analytics()` — Sales data (admin only)

### Utility Modules

#### `utils/validation.ts`
Input validation with error handling:
- `priceCents()` — 0 to 10,000,000 cents ($0-$100k CAD)
- `quantity()` — 1 to 10,000
- `rating()` — 1 to 5
- `postalCode()` — Canadian postal code format
- `phone()` — E.164 format (+1XXXXXXXXXX)
- `email()` — Basic email validation
- `surrealId()` — SurrealDB ID format validation
- `pagination()` — Default limit=20, max=100
- Custom validators for coupon codes, return reasons, etc.

#### `utils/logger.ts`
Structured logging:
- `LogContext` — Request ID, tool name, duration, user ID
- Automatic PII redaction (email, phone, password)
- JSON output for log aggregation
- No console.log (using stdout for logging)

#### `utils/errors.ts`
Error hierarchy:
- `AppError` — Base class with code, message, statusCode
- `ValidationError` (400)
- `AuthenticationError` (401)
- `AuthorizationError` (403)
- `NotFoundError` (404)
- `ConflictError` (409)
- `RateLimitError` (429)
- `StripeError` (400)
- `InternalServerError` (500)

## Data Flow: Agent Purchase

```
Agent: "I want to buy a laptop for $1,299.99 and ship to Toronto"
       │
       ├─> [1] search_products(query="laptop", max_price=150000)
       │       └─> ValidationError if price > 10000000
       │       └─> OrignaBase /search/products
       │       └─> Return: [{ id, title, priceCents, images, ... }]
       │
       ├─> [2] add_to_cart(product_id="products:xyz", quantity=1)
       │       └─> Validation.quantity(1) ✓
       │       └─> OrignaBase POST /cart/items
       │       └─> Return: { subtotalCents: 129900, tax: 16887, ... }
       │
       ├─> [3] apply_coupon(code="SAVE15")
       │       └─> Validation.couponCode("SAVE15") ✓
       │       └─> OrignaBase POST /coupons/apply
       │       └─> Return: { discountCents: 19485, newTotalCents: 127302 }
       │
       └─> [4] create_checkout(
           shipping_address={
             street: "123 Main St",
             city: "Toronto",
             province: "ON",
             postalCode: "M5V 3A8",
             phone: "+14165551234"
           }
         )
         ├─> Validation.postalCode() ✓
         ├─> Validation.phone() ✓
         ├─> OrignaBase POST /checkout
         │   └─> Stripe Checkout Session creation:
         │       • ui_mode: "embedded"
         │       • automatic_tax: true
         │       • payment_method_types: ["card", "link", "cashapp", "afterpay_clearpay"]
         │       • shipping_options: { type: "shipping_address_collection" }
         │       • Idempotency-Key: {request-id}
         │
         └─> Return: {
           sessionId: "cs_test_...",
           sessionUrl: "https://checkout.stripe.com/pay/...",
           totalCents: 127302,
           status: "ready_for_payment"
         }

Agent redirects user to sessionUrl → Payment page → Success → Order created
```

## Security Model

### Authentication
- JWT from `ORIGNABASE_JWT_TOKEN` env var
- Token parsed client-side (signature verified server-side)
- Expiration checked on each request
- User ID extracted and added to logs

### Authorization
```
Buyer:   search_products, get_product, add_to_cart, remove_from_cart,
         create_checkout, apply_coupon, list_orders (own), get_order (own),
         request_return, submit_review

Seller:  search_products, get_product, check_inventory, list_orders (own),
         get_order (own), submit_review, request_return

Admin:   All tools + get_analytics
```

### Input Validation
- All parameters validated before API calls
- Business rule checks (e.g., max price $100k)
- Format checks (postal codes, phone numbers)
- Length limits (product names, review text)
- Integer type checks for money

### Error Sanitization
- No stack traces in production
- No internal error details exposed
- Generic "An unexpected error occurred" for unknown errors
- HTTP status codes match error type

### Logging Security
- PII fields redacted: password, token, secret, key, ssn, creditCard
- Email partially obscured: m***@example.com
- JWT sub field stored as short ID (suffix only)
- Request duration tracked for performance monitoring

## Stripe Integration (Latest Features)

### Checkout Sessions
```javascript
{
  "ui_mode": "embedded",           // New embedded checkout
  "automatic_tax": {
    "enabled": true                 // Canadian HST/GST/PST auto-calc
  },
  "payment_method_types": [
    "card",                         // Credit/debit card
    "link",                         // Stripe Link (one-click)
    "cashapp",                      // Cash App (US/UK)
    "afterpay_clearpay"             // Buy now, pay later
  ],
  "shipping_options": {
    "type": "shipping_address_collection"  // Real-time rate calc
  },
  "metadata": {
    "order_id": "orders:abc123"     // Webhook linkage
  }
}
```

### Idempotency
All Stripe requests include `Idempotency-Key` header:
```
Idempotency-Key: {request-id}-{action}
Example: 550e8400-e29b-41d4-a716-446655440000-checkout
```

Prevents duplicate charges on retry.

### Webhook Verification
(Server-side in OrignaBase, not in MCP server)
- HMAC signature on `Stripe-Signature` header
- Webhook event stored in `webhook_events` collection
- Idempotent processing: check for duplicate event IDs first

## Money Handling

All monetary values in **integer cents**:
- `priceCents`: 2999 = $29.99 CAD
- `subtotalCents`: 129900 = $1,299.00 CAD
- `taxAmountCents`: 16887 = $168.87 CAD (HST on $1,299)
- `totalAmountCents`: 146787 = $1,467.87 CAD

No floats — prevents precision errors from accumulating.

Stripe API also uses cents, so values pass through directly without conversion.

## Pagination

Default: limit=20, offset=0
Max limit: 100

Example:
```
GET /orders?limit=50&offset=100
→ Results 100-149 (50 items)
→ For page 3, offset = (page - 1) * limit = (3 - 1) * 20 = 40
```

## Error Response Format

All errors return JSON:
```json
{
  "error": "Product 'products:xyz' not found",
  "code": "NOT_FOUND",
  "statusCode": 404
}
```

Error codes:
- `VALIDATION_ERROR` — Input validation failed
- `AUTH_ERROR` — Missing/invalid JWT
- `AUTHZ_ERROR` — Insufficient permissions
- `NOT_FOUND` — Resource doesn't exist
- `CONFLICT` — Business logic violation
- `RATE_LIMIT` — 429 Too Many Requests
- `STRIPE_ERROR` — Stripe API error
- `INTERNAL_ERROR` — Unexpected server error

## Logging Format

All logs are JSON (no console.log):
```json
{
  "timestamp": "2026-03-18T14:30:45.123Z",
  "level": "INFO",
  "message": "create_checkout succeeded",
  "requestId": "550e8400-e29b-41d4-a716-446655440000",
  "tool": "create_checkout",
  "method": "create_checkout",
  "duration": 312,
  "userId": "abc123",
  "sessionId": "cs_test_...",
  "email": "m***@example.com"
}
```

## Testing

No built-in test suite (should be added). Manual testing approach:
1. Set `ORIGNABASE_JWT_TOKEN` in env
2. `npm run build && npm start`
3. Connect via Claude or stdio-based MCP client
4. Test tool calls interactively

Integration points to test:
- [ ] search_products with all filters
- [ ] add → remove → checkout flow
- [ ] Admin-only tools (get_analytics)
- [ ] Error cases (invalid price, missing auth, etc.)
- [ ] Stripe session creation with latest features
- [ ] Rate limiting (429 handling)

## Performance

- Axios timeout: 10 seconds per request
- Structured logging (minimal overhead)
- Request context tracking (UUID per request)
- No caching (stateless MCP server)
- Idempotency keys prevent duplicate Stripe charges

## Future Enhancements

1. **Caching**: In-memory cache for search results (with TTL)
2. **Batch Operations**: Bulk add-to-cart, bulk return requests
3. **Webhooks**: Receive and process Stripe/OrignaBase webhooks
4. **Payment Links**: `create_payment_link()` for one-click URLs
5. **Test Suite**: Jest + mocked OrignaBase API
6. **Metrics**: Prometheus-style metrics export
7. **Rate Limiting**: Client-side rate limiter for API calls

---

**Architecture Document**  
Created: March 2026  
Last Updated: March 18, 2026
