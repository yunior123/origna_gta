# OrignaGTA MCP Server

**Model Context Protocol (MCP) server** for the OrignaGTA e-commerce platform. Enables AI agents to search products, build shopping carts, apply coupons, and **purchase items using Stripe** with latest payment features.

## Features

### 14 Production-Ready Tools

**Search & Browse (3 tools)**
- `search_products` — Full-text search with category, price, and sorting filters
- `get_product` — Detailed product info, images, reviews, stock levels
- `check_inventory` — Real-time stock status for inventory-aware agents

**Shopping Cart (3 tools)**
- `add_to_cart` — Add items to cart with quantity validation
- `remove_from_cart` — Remove items from cart
- `get_cart` — Retrieve current cart with totals and tax estimates

**Discounts (1 tool)**
- `apply_coupon` — Apply discount codes with validation

**Checkout & Payments (1 tool - THE AGENT CAN PURCHASE)**
- `create_checkout` — Create Stripe Checkout Session with **latest features**:
  - `ui_mode: 'embedded'` for seamless checkout
  - `automatic_tax: { enabled: true }` for real-time tax calculation
  - `shippingOptions` with real-time rate calculation
  - Multi-currency and payment method support: card, Link, Cash App, Afterpay/Clearpay
  - Idempotent requests via `Idempotency-Key` headers

**Orders (3 tools)**
- `list_orders` — View order history with status filtering
- `get_order` — Detailed order with items, totals, tracking
- `request_return` — Initiate returns/refunds workflow

**Reviews (1 tool)**
- `submit_review` — Post product reviews (1-5 stars)

**Analytics (1 tool - Admin only)**
- `get_analytics` — Sales data, top products, revenue by period

## Stripe Integration

The server leverages **latest Stripe features** for modern checkout:

| Feature | Implementation |
|---------|---|
| **Embedded Checkout** | `ui_mode: 'embedded'` – seamless in-context payments |
| **Automatic Tax** | `automaticTax: { enabled: true }` – handles Canadian HST/GST/PST |
| **Shipping Rates** | Real-time calculation per address and destination |
| **Payment Methods** | Card, Stripe Link, Cash App, Afterpay/Clearpay |
| **Idempotency** | `Idempotency-Key` on all requests for safe retries |
| **Webhook Security** | Signature verification (HMAC) for all incoming webhooks |

## Security & Data Handling

- **No PII in logs** — Email addresses, phone numbers, addresses redacted
- **Integer cents** — All monetary values as integers (no float precision errors)
- **JWT Auth** — Token from `ORIGNABASE_JWT_TOKEN` env var
- **Role-based access** — Admin, Seller, Buyer with proper authorization
- **Input validation** — Price ranges, postal codes (Canadian), phone (E.164), emails
- **Error sanitization** — No internal stack traces or secrets in responses

## Installation

### Prerequisites
- Node.js 18+
- Valid OrignaGTA JWT token

### Setup

```bash
cd mcp-server
npm install
npm run build
```

## Configuration

### Environment Variables

```bash
# Required: OrignaBase API URL and JWT Token
export ORIGNABASE_URL="https://api.dev.orignagta.ca"        # Default: dev
export ORIGNABASE_JWT_TOKEN="REDACTED_SECRET"

# Optional
export NODE_ENV="development"  # dev mode with verbose logging
```

### Environment URLs

| Environment | API URL |
|-------------|---------|
| Development | `https://api.dev.orignagta.ca` |
| Staging | `https://api.staging.orignagta.ca` |
| Production | `https://api.orignagta.ca` |

## Running

### Development (with auto-rebuild)
```bash
npm run dev
```

### Production
```bash
npm run build
npm start
```

## Integration with Claude MCP

Add to your Claude project configuration:

```json
{
  "mcp": {
    "servers": {
      "orignagta": {
        "command": "npm",
        "args": ["start"],
        "cwd": "/path/to/mcp-server",
        "env": {
          "ORIGNABASE_URL": "https://api.dev.orignagta.ca",
          "ORIGNABASE_JWT_TOKEN": "your-jwt-token-here"
        }
      }
    }
  }
}
```

## Schema Reference

### Money & Pricing
- All prices in **integer cents** (e.g., 2999 = $29.99 CAD)
- Fields: `priceCents`, `subtotalCents`, `taxAmountCents`, `totalAmountCents`
- No floats — prevents rounding errors

### Timestamp Fields (Critical!)
| Collection | Field | Format |
|-----------|-------|--------|
| orders, users, payouts, return_requests | `createdAt` | Unix timestamp (seconds) |
| products, cart | `dateCreated` | Unix timestamp (seconds) |
| webhook_events | `timestamp` | Unix timestamp (milliseconds) |

### SurrealDB IDs
- Format: `collection:record_id` (e.g., `products:abc123xyz`)
- Used in Meilisearch with `:` → `_` (e.g., `products_abc123xyz`)

### Order State Machine
```
pending → confirmed → shipped → delivered
       ↘ cancelled
```
Valid transitions only; no state skips.

### Address Validation
- **Canadian postal code**: `[A-Z]\d[A-Z] \d[A-Z]\d` (e.g., `M5V 3A8`)
- **Phone (E.164)**: `+1XXXXXXXXXX` (Canada only)

## Example: Agent Purchase Flow

```
1. search_products(query="laptop", max_price=150000)
   → Returns 5 products matching criteria

2. get_product(id="products:xyz789")
   → Returns full details: price=$1,299 (129900 cents), stock=25

3. add_to_cart(product_id="products:xyz789", quantity=1)
   → Returns updated cart: subtotal=129900, tax=16887, total=146787

4. apply_coupon(code="SAVE15")
   → Returns: discount=19485 cents, new total=127302

5. create_checkout(shipping_address={
     street: "123 Main St",
     city: "Toronto",
     province: "ON",
     postalCode: "M5V 3A8",
     country: "CA",
     phone: "+14165551234"
   })
   → Returns Stripe Checkout Session URL
   → Agent redirects user or embeds checkout iframe

6. Stripe webhook confirms payment → Order created in OrignaBase

7. list_orders(status="confirmed")
   → Agent verifies purchase completed
```

## Tool Definitions

### search_products
Search catalog with filters.

**Parameters:**
- `query` (required): Search string
- `category`: Category filter
- `min_price`, `max_price`: Price range in cents
- `sort`: `price_asc` | `price_desc` | `newest` | `popular`
- `limit`: Results per page (1-100, default 20)
- `offset`: Pagination offset

**Response:**
```json
{
  "items": [
    {
      "id": "products:abc123",
      "title": "Laptop Pro",
      "priceCents": 129900,
      "imageUrls": ["..."],
      "stockQuantity": 25,
      "categoryId": "electronics"
    }
  ],
  "total": 45,
  "limit": 20,
  "offset": 0
}
```

### create_checkout
Create Stripe Checkout Session — **THE TOOL FOR AGENTS TO PURCHASE**.

**Parameters:**
- `shipping_address` (required): Address object with street, city, province, postalCode, country, phone
- `coupon`: Optional discount code

**Response:**
```json
{
  "sessionId": "cs_test_...",
  "sessionUrl": "https://checkout.stripe.com/pay/cs_test_...",
  "clientSecret": "...",
  "publishableKey": "pk_test_...",
  "totalCents": 127302,
  "status": "ready_for_payment"
}
```

### get_order
Retrieve order details (buyer/seller scoped).

**Parameters:**
- `id` (required): Order ID

**Response:**
```json
{
  "id": "orders:order123",
  "buyerId": "users:buyer456",
  "status": "confirmed",
  "items": [
    {
      "productId": "products:xyz",
      "name": "Laptop Pro",
      "quantity": 1,
      "unitPriceCents": 129900
    }
  ],
  "subtotalCents": 129900,
  "taxAmountCents": 16887,
  "shippingCostCents": 0,
  "totalAmountCents": 146787,
  "createdAt": 1710763200
}
```

## Error Handling

All errors return standard JSON with code and message:

```json
{
  "error": "Product 'products:invalid' not found",
  "code": "NOT_FOUND",
  "statusCode": 404
}
```

**Common error codes:**
- `VALIDATION_ERROR` — Invalid input (400)
- `AUTH_ERROR` — Missing JWT token (401)
- `AUTHZ_ERROR` — Insufficient permissions (403)
- `NOT_FOUND` — Resource doesn't exist (404)
- `CONFLICT` — Business logic violation (409)
- `RATE_LIMIT` — Too many requests (429)
- `STRIPE_ERROR` — Stripe API error (400)
- `INTERNAL_ERROR` — Server error (500)

## Logging

Server outputs **structured JSON logs** with:
- `timestamp`: ISO 8601
- `level`: DEBUG, INFO, WARN, ERROR
- `message`: Human-readable summary
- `requestId`: Unique request UUID
- `duration`: Milliseconds elapsed
- Sanitized metadata (no PII)

Example:
```json
{
  "timestamp": "2026-03-18T14:30:45.123Z",
  "level": "INFO",
  "message": "create_checkout succeeded",
  "requestId": "550e8400-e29b-41d4-a716-446655440000",
  "tool": "create_checkout",
  "duration": 312,
  "sessionId": "cs_test_..."
}
```

## Architecture

```
mcp-server/
├── src/
│   ├── index.ts              # MCP server + tool routing
│   ├── types.ts              # TypeScript interfaces (Product, Order, etc.)
│   ├── api-client.ts         # OrignaBase HTTP client
│   ├── auth.ts               # JWT parsing & role checks
│   ├── tools/
│   │   ├── products.ts       # search_products, get_product, check_inventory
│   │   ├── orders.ts         # list_orders, get_order, request_return
│   │   ├── cart.ts           # add_to_cart, remove_from_cart, get_cart
│   │   ├── checkout.ts       # create_checkout, apply_coupon
│   │   ├── reviews.ts        # submit_review
│   │   └── analytics.ts      # get_analytics (admin)
│   └── utils/
│       ├── errors.ts         # Custom error classes
│       ├── logger.ts         # Structured logging
│       └── validation.ts     # Input validation
├── dist/                     # Compiled JavaScript
├── package.json
└── tsconfig.json
```

## Development

### Type Checking
```bash
npm run typecheck
```

### Clean Build
```bash
npm run clean
npm run build
```

## Production Checklist

- [ ] JWT token securely injected (env var, not hardcoded)
- [ ] OrignaBase URL set to production: `https://api.orignagta.ca`
- [ ] Stripe key(s) configured on OrignaBase side
- [ ] Webhook endpoint registered with Stripe
- [ ] Rate limiting configured on OrignaBase (429 handling)
- [ ] Monitoring/alerting enabled for errors and latency
- [ ] Logs aggregated to centralized system (Sentry, CloudWatch, etc.)
- [ ] Test purchase flow end-to-end before going live

## Testing

No built-in test suite yet, but tools can be tested via:

```bash
# Example: curl to local MCP stdio server (advanced)
npm run dev &
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | nc localhost 3000
```

Or integrate with Claude/other MCP clients and test interactively.

## Support

For issues or questions:
1. Check `ORIGNABASE_JWT_TOKEN` is set and valid
2. Verify OrignaBase API is reachable
3. Check server logs for error details
4. Review docs at `/docs` in main project

## License

MIT

---

**Built for OrignaGTA e-commerce platform**  
Last updated: March 2026
