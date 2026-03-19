# OrignaGTA MCP Server — Quick Start

## 5-Minute Setup

### 1. Navigate to Directory
```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/mcp-server
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Get JWT Token
```bash
curl -X POST https://api.dev.orignagta.ca/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "e2e-admin@test.origna.ca",
    "password": "REDACTED_TEST_PASSWORD"
  }'
```

Copy the `token` from response.

### 4. Set Environment
```bash
export ORIGNABASE_URL="https://api.dev.orignagta.ca"
export ORIGNABASE_JWT_TOKEN="eyJhbGc..."  # Paste your token here
```

### 5. Build & Run
```bash
npm run build
npm start
```

Server is ready on stdio.

## Claude Desktop Integration

Edit `~/.claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "orignagta": {
      "command": "node",
      "args": ["/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/mcp-server/dist/index.js"],
      "env": {
        "ORIGNABASE_URL": "https://api.dev.orignagta.ca",
        "ORIGNABASE_JWT_TOKEN": "your-jwt-token-here"
      }
    }
  }
}
```

Restart Claude Desktop.

## Test an Agent Purchase

Ask Claude:
```
Search for a laptop under $1,500. Add it to cart, apply coupon "SAVE15", 
then create a checkout session to Toronto, ON M5V 3A8.
```

Claude will:
1. Call `search_products(query="laptop", max_price=150000)`
2. Call `add_to_cart(product_id="products:...", quantity=1)`
3. Call `apply_coupon(code="SAVE15")`
4. Call `create_checkout(shipping_address={...})`

Returns Stripe Checkout Session URL!

## Documentation

- **README.md** — Full API docs (14 tools)
- **SETUP.md** — Detailed installation
- **ARCHITECTURE.md** — Design & flows

## Common Issues

**JWT Token Expired**
```bash
curl -X POST https://api.dev.orignagta.ca/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"e2e-admin@test.origna.ca","password":"REDACTED_TEST_PASSWORD"}'
# Get new token, update ORIGNABASE_JWT_TOKEN
```

**Connection Error**
- Check `ORIGNABASE_URL` is reachable
- Verify OrignaBase API is running

**Compilation Error**
```bash
npm run clean
npm install
npm run build
```

## Test Accounts (Dev)

```
Admin:   e2e-admin@test.origna.ca / REDACTED_TEST_PASSWORD
Seller:  e2e-seller@test.origna.ca / REDACTED_TEST_PASSWORD
Buyer:   e2e-buyer@test.origna.ca / REDACTED_TEST_PASSWORD
```

## Commands

```bash
npm install         # Install deps
npm run build       # Compile TypeScript
npm run dev         # Dev mode (hot reload)
npm start           # Production mode
npm run typecheck   # Type check only
npm run clean       # Remove dist/
npm audit           # Security audit
```

---

**Ready to enable agents to purchase products!** 🚀
