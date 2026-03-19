# MCP Server Setup Guide

## Quick Start

### 1. Install Dependencies
```bash
cd mcp-server
npm install
```

### 2. Build
```bash
npm run build
```

### 3. Get JWT Token
Login to OrignaBase dev environment:
```bash
curl -X POST https://api.dev.orignagta.ca/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "your-email@example.com",
    "password": "your-password"
  }'
```

Extract the `token` from the response.

### 4. Configure Environment
```bash
cp .env.example .env
# Edit .env and set:
# - ORIGNABASE_URL
# - ORIGNABASE_JWT_TOKEN (from step 3)
```

### 5. Run Server
```bash
# Development (with hot reload)
npm run dev

# Production
npm run build && npm start
```

## Integration with Claude

### Option A: Claude Desktop (claude_desktop_config.json)

Add to `~/.claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "orignagta": {
      "command": "node",
      "args": ["/path/to/mcp-server/dist/index.js"],
      "env": {
        "ORIGNABASE_URL": "https://api.dev.orignagta.ca",
        "ORIGNABASE_JWT_TOKEN": "your-jwt-token-here"
      }
    }
  }
}
```

Restart Claude Desktop and the server will be available.

### Option B: Claude Web (MCP Client Config)

In your Claude project settings:

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

### Option C: Run Standalone with stdio

```bash
npm run build
node dist/index.js
```

Then pipe MCP protocol JSON to stdin. Example:
```bash
echo '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":1}' | node dist/index.js
```

## Verify Installation

Test that the server is running correctly:

```bash
# Check tools are available
curl -X POST http://localhost:3000/tools/list

# Or test with a simple tool call (if server is running)
npm run dev &
# Send a test request...
```

## Test Accounts (Dev Environment)

```
Admin:   e2e-admin@test.origna.ca / REDACTED_TEST_PASSWORD
Seller:  e2e-seller@test.origna.ca / REDACTED_TEST_PASSWORD
Buyer:   e2e-buyer@test.origna.ca / REDACTED_TEST_PASSWORD
```

## Troubleshooting

### JWT Token Expired
The JWT token expires after a period of time. Get a new one:
```bash
curl -X POST https://api.dev.orignagta.ca/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"...","password":"..."}'
```

### Connection Refused
- Check `ORIGNABASE_URL` is correct and reachable
- Verify OrignaBase API is running on that host
- Check firewall/VPN access

### Authentication Error
- Verify `ORIGNABASE_JWT_TOKEN` is set correctly
- Ensure token hasn't expired
- Check token is from the correct environment

### TypeScript Compilation Errors
```bash
npm run clean
npm install
npm run build
```

## File Structure

```
mcp-server/
├── src/
│   ├── index.ts              # Main server + tool dispatcher
│   ├── types.ts              # TypeScript type definitions
│   ├── api-client.ts         # OrignaBase HTTP client
│   ├── auth.ts               # JWT auth & role validation
│   ├── tools/
│   │   ├── products.ts       # search_products, get_product, check_inventory
│   │   ├── orders.ts         # list_orders, get_order, request_return
│   │   ├── cart.ts           # add_to_cart, remove_from_cart, get_cart
│   │   ├── checkout.ts       # create_checkout, apply_coupon
│   │   ├── reviews.ts        # submit_review
│   │   └── analytics.ts      # get_analytics (admin only)
│   └── utils/
│       ├── errors.ts         # Custom error classes
│       ├── logger.ts         # Structured JSON logging
│       └── validation.ts     # Input validation utilities
├── dist/                     # Compiled JavaScript (generated)
├── package.json
├── tsconfig.json
├── .env.example
├── README.md                 # Full documentation
└── SETUP.md                  # This file
```

## Production Deployment

### Checklist
- [ ] Set `ORIGNABASE_URL` to production endpoint
- [ ] Use a service account JWT token (not a personal user token)
- [ ] Store JWT in a secrets manager (AWS Secrets Manager, Vault, etc.)
- [ ] Enable monitoring/alerting on error logs
- [ ] Configure log aggregation (Sentry, CloudWatch, etc.)
- [ ] Test end-to-end before deploying to production
- [ ] Rotate JWT tokens regularly

### Docker Deployment

Create `Dockerfile`:
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY dist ./dist
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

Build and run:
```bash
docker build -t orignagta-mcp:latest .
docker run -e ORIGNABASE_URL=https://api.orignagta.ca \
           -e ORIGNABASE_JWT_TOKEN=$JWT_TOKEN \
           orignagta-mcp:latest
```

## Next Steps

1. Read the full [README.md](./README.md) for tool documentation
2. Explore individual tool files in `src/tools/` for implementation details
3. Check `src/utils/validation.ts` for input validation rules
4. Review `src/api-client.ts` for API client implementation

## Support

For issues or questions:
1. Check environment variables are set correctly
2. Verify OrignaBase API endpoint is reachable
3. Review server logs for error details
4. Consult README.md for tool-specific documentation

---

Last updated: March 2026
