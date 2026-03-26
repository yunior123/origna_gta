---
name: mcp-audit
description: "Audit the OrignaBase MCP server (ob-mcp crate). Covers JSON-RPC 2.0 transport, tool definitions, auth, safeguards, spend limits, idempotency, and injection risks. Use when asked to 'audit MCP', 'check MCP server', 'review AI tools', or similar."
---

# MCP Audit — OrignaBase

Audit of the `ob-mcp` crate that exposes marketplace operations as MCP tools for AI agents.

## Files to Read

```
orignabase/crates/ob-mcp/src/lib.rs              # Entry point
orignabase/crates/ob-mcp/src/server.rs           # JSON-RPC 2.0 server (OrignaGtaMcp)
orignabase/crates/ob-mcp/src/transport.rs        # HTTP/SSE/stdio transport
orignabase/crates/ob-mcp/src/auth.rs             # JWT auth
orignabase/crates/ob-mcp/src/safeguards.rs       # Spend limits, idempotency, confirmation
orignabase/crates/ob-mcp/src/errors.rs           # Error types
orignabase/crates/ob-mcp/src/tools/mod.rs        # Tool registry
orignabase/crates/ob-mcp/src/tools/catalog.rs    # search_products, get_product, check_inventory
orignabase/crates/ob-mcp/src/tools/shopping.rs   # get_cart, add_to_cart, remove_from_cart, apply_coupon
orignabase/crates/ob-mcp/src/tools/orders.rs     # list_orders, get_order, request_return, create_checkout
orignabase/crates/ob-mcp/src/tools/admin.rs      # get_analytics, create_review
orignabase/crates/ob-mcp/Cargo.toml              # Dependencies
orignabase/tests/mcp_integration_test.rs          # Integration tests
```

## Checkpoints

### 1. JSON-RPC 2.0 Compliance
- [ ] Request validation: `jsonrpc: "2.0"` enforced?
- [ ] `id` field required for requests?
- [ ] `method` field validated against allowed methods?
- [ ] `params` schema validated per method?
- [ ] Error responses follow JSON-RPC 2.0 error format (`code`, `message`, `data`)?
- [ ] Batch requests handled correctly?

### 2. Tool Injection & Input Validation
- [ ] Tool parameters sanitized before DB queries?
- [ ] `search_products` query string: can it inject SurrealQL?
- [ ] `add_to_cart` quantity: can it be negative? Overflow?
- [ ] `apply_coupon` code: can it access other users' coupons?
- [ ] `create_checkout` — does it go through the same validation as REST checkout?
- [ ] `create_review` — can it bypass product ownership checks?
- [ ] All numeric params checked for overflow/negative?

### 3. Auth & Authorization
- [ ] JWT validated on every authenticated tool call?
- [ ] Unauthenticated tools (`search_products`, `get_product`, `check_inventory`) correctly open?
- [ ] Authenticated tools (`get_cart`, `add_to_cart`, `list_orders`, etc.) require valid JWT?
- [ ] Admin tools (`get_analytics`) restricted to admin role?
- [ ] Can a user access another user's cart/orders via MCP?
- [ ] IDOR: can `get_order` fetch another user's order by changing orderId?

### 4. Safeguards
- [ ] Spend limits enforced? ($1M CAD per request, $10M per 24h)
- [ ] Idempotency keys prevent duplicate operations?
- [ ] Confirmation tokens expire after 1h?
- [ ] Rate limiting per user?
- [ ] `create_checkout` spend limit matches REST endpoint?
- [ ] Confirmation token scoped to user + operation?

### 5. Transport Security
- [ ] HTTP transport: TLS enforced?
- [ ] SSE transport: auth on connection?
- [ ] Stdio transport: only for local/dev?
- [ ] CORS configured correctly?
- [ ] Request size limits enforced?

### 6. Error Handling
- [ ] Tool errors return user-friendly messages?
- [ ] No internal errors leaked (stack traces, DB errors)?
- [ ] SurrealDB errors handled gracefully?
- [ ] Stripe errors mapped to MCP error codes?

### 7. Data Leakage
- [ ] `get_product` returns only public fields?
- [ ] `list_orders` filtered to current user?
- [ ] `get_analytics` doesn't expose other users' data?
- [ ] No PII in error messages?
- [ ] Confirmation tokens not logged?

## Report Format
```
═══════════════════════════════════════
MCP AUDIT REPORT
═══════════════════════════════════════
Tools: 13
JSON-RPC COMPLIANCE:  [PASS/FAIL]
INPUT VALIDATION:     [PASS/FAIL]
AUTH/ACCESS CONTROL:  [PASS/FAIL]
SAFEGUARDS:           [PASS/FAIL]
TRANSPORT SECURITY:   [PASS/FAIL]
ERROR HANDLING:       [PASS/FAIL]
DATA LEAKAGE:         [PASS/FAIL]

FINDINGS:
[CRITICAL/HIGH/MEDIUM/LOW] [file:line] Description
═══════════════════════════════════════
```
