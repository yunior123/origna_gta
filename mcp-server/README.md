# OrignaGTA MCP Server

Model Context Protocol (MCP) server for the OrignaGTA e-commerce platform. Provides AI assistants with programmatic access to products, orders, users, analytics, and inventory data.

## Overview

This MCP server exposes 7 core tools for interacting with the OrignaGTA platform:

- **search_products** — Full-text search across product catalog
- **get_product** — Fetch detailed product information
- **get_order** — Retrieve order details and status
- **list_orders** — List user orders with filtering
- **get_user** — Fetch user profile information
- **get_analytics** — Get sales analytics for a time period
- **check_inventory** — Check real-time stock levels

## Requirements

- Node.js 18+
- npm or yarn
- Valid OrignaGTA API credentials (JWT token or API key)

## Installation

```bash
cd mcp-server
npm install
npm run build
```

## Configuration

Set environment variables before running:

```bash
export ORIGNABASE_URL="https://api.dev.orignagta.ca"        # Default: dev environment
export ORIGNABASE_JWT_TOKEN="your-jwt-token"               # OR use API key below
export ORIGNABASE_API_KEY="your-api-key"                    # Alternative to JWT
```

### Authentication

The server supports two authentication methods (in priority order):

1. **JWT Token** (`ORIGNABASE_JWT_TOKEN`) — Recommended for user-specific queries
2. **API Key** (`ORIGNABASE_API_KEY`) — For service-to-service access

If neither is provided, requests are made without authentication (read-only public data only).

### Environment URLs

| Environment | URL |
|-------------|-----|
| Development | `https://api.dev.orignagta.ca` |
| Staging | `https://api.staging.orignagta.ca` |
| Production | `https://api.orignagta.ca` |

## Usage

### Running the Server

```bash
# Development mode (auto-rebuilds on changes)
npm run dev

# Production mode
npm run build
npm start
```

### Standalone Testing

```bash
# Search for products
node dist/index.js search_products --query "laptop" --category "electronics"

# Get product details
node dist/index.js get_product --id "products:abc123"

# Check inventory
node dist/index.js check_inventory --product_id "products:def456"
```

### Claude Integration

Add to your Claude project configuration:

```json
{
  "mcp": {
    "servers": {
      "orignagta": {
        "command": "npm",
        "args": ["start"],
        "cwd": "/path/to/mcp-server"
      }
    }
  }
}
```

Then use tools in your Claude prompts:

```
Using the OrignaGTA MCP tools:
1. Search for "gaming laptop" products under $2000
2. Get details on the top 3 results
3. Check their current inventory levels
```

## Tool Reference

### search_products

Search the product catalog by query, category, or price range.

**Parameters:**
- `query` (string, required) — Search term
- `category` (string, optional) — Category filter
- `min_price` (number, optional) — Minimum price in cents
- `max_price` (number, optional) — Maximum price in cents
- `limit` (number, optional) — Results per page (default: 20, max: 100)
- `offset` (number, optional) — Pagination offset (default: 0)

**Returns:** Array of products matching search criteria

**Example:**
```
search_products(query="laptop", category="electronics", max_price=300000)
```

### get_product

Get complete details for a specific product.

**Parameters:**
- `id` (string, required) — Product ID (e.g., `products:abc123`)

**Returns:** Product details including price, stock, seller, images, lifecycle status

**Example:**
```
get_product(id="products:abc123")
```

### get_order

Retrieve full order details including items, status, and timestamps.

**Parameters:**
- `id` (string, required) — Order ID (e.g., `orders:xyz789`)

**Returns:** Order with items, status, amounts, buyer/seller IDs, dates

**Example:**
```
get_order(id="orders:xyz789")
```

### list_orders

List orders for a specific user with optional filtering.

**Parameters:**
- `user_id` (string, required) — User ID (e.g., `users:user123`)
- `status` (string, optional) — Filter by status: `pending`, `confirmed`, `shipped`, `delivered`, `cancelled`
- `limit` (number, optional) — Results per page (default: 20)
- `offset` (number, optional) — Pagination offset (default: 0)

**Returns:** Array of orders matching filters

**Example:**
```
list_orders(user_id="users:user123", status="delivered", limit=10)
```

### get_user

Fetch user profile information.

**Parameters:**
- `id` (string, required) — User ID (e.g., `users:user123`)

**Returns:** User profile with email, display name, role, creation date

**Example:**
```
get_user(id="users:user123")
```

### get_analytics

Get sales analytics for a specified time period.

**Parameters:**
- `period` (string, optional) — Time range: `day`, `week`, `month`, `year` (default: `week`)

**Returns:** Analytics object with revenue, order count, average order value, top products

**Example:**
```
get_analytics(period="month")
```

### check_inventory

Check current stock levels for a product.

**Parameters:**
- `product_id` (string, required) — Product ID (e.g., `products:abc123`)

**Returns:** Inventory status with quantity and availability flag

**Example:**
```
check_inventory(product_id="products:abc123")
```

## Error Handling

All tools return errors in the following format:

```json
{
  "content": [
    {
      "type": "text",
      "text": "Error: Failed to fetch product: 404 Not Found"
    }
  ],
  "isError": true
}
```

Common error codes:
- **401 Unauthorized** — Invalid or missing credentials
- **403 Forbidden** — Insufficient permissions for the resource
- **404 Not Found** — Resource does not exist
- **422 Unprocessable Entity** — Invalid request parameters
- **429 Too Many Requests** — Rate limit exceeded
- **500 Internal Server Error** — Backend service error

## Development

### Type Checking

```bash
npm run typecheck
```

### Build

```bash
npm run build
```

Generated files go to `./dist/`

## Security & Privacy

- Never commit `.env` files with credentials
- Use JWT tokens for user-specific data queries
- Respect API rate limits (5 req/s recommended)
- All data returned respects row-level security from OrignaBase backend
- User addresses are filtered (not exposed to unauthorized parties)

## Troubleshooting

**Connection refused:**
```
Error: Failed to search products: connect ECONNREFUSED 127.0.0.1:8080
```
→ Verify `ORIGNABASE_URL` is set and the backend is running

**Authentication failed:**
```
Error: Failed to fetch user: 401 Unauthorized
```
→ Check JWT token validity and `ORIGNABASE_JWT_TOKEN` environment variable

**Rate limited:**
```
Error: Failed to search products: 429 Too Many Requests
```
→ Implement exponential backoff; maximum 5 requests/second

## Architecture

```
MCP Server (index.ts)
├── Tool Definitions (ListToolsRequestSchema)
├── Tool Handlers (CallToolRequestSchema)
└── OrignaBase API Client
    ├── axios HTTP client
    ├── Authentication headers
    └── Error handling
```

## Contributing

When adding new tools:

1. Define the tool schema in `ListToolsRequestSchema` handler
2. Implement the handler function in `CallToolRequestSchema`
3. Add TypeScript interfaces for request/response types
4. Document in README with examples

## License

Proprietary — OrignaGTA

## Support

For issues or feature requests, contact the OrignaGTA development team at support@orignagta.ca.
