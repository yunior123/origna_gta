# OrignaGTA MCP vs Industry Standards (2025-2026)

**Date**: March 18, 2026  
**Researched against**: Stripe MCP, Shopify (Catalog/Checkout/Storefront), MCP reference implementations

---

## Executive Summary

OrignaGTA MCP is functional for demos but materially behind 2025-2026 best practices in auth, transport, domain separation, and agent safety. The strongest commerce MCPs (Stripe, Shopify) use:
- **Remote HTTP MCP** with OAuth/short-lived tokens (not stdio + env JWT)
- **Domain-bounded surfaces** (catalog vs checkout vs orders, not monolithic)
- **Idempotency + business-outcome semantics** (not just HTTP error mapping)
- **Cursor pagination** (not offset-based)
- **Agent safeguards** (confirmation, spend limits, scopes, prompt-injection warnings)

OrignaGTA needs a phased evolution, not a rewrite. The core domains are right; the security and UX patterns are the gaps.

---

## Current Status (March 2026)

**What exists**:
- MCP server is functional for demos and internal testing
- Auth system reads env JWT but does NOT verify signatures
- All mutations (add-to-cart, checkout, return) exist in tool definitions
- OrignaBase SDK handles retry logic on the backend

**What is NOT done**:
- OAuth code exists in `src/auth.ts` but is **uncommitted and untested** — cannot be relied upon
- Idempotency keys are **backend-only in OrignaBase SDK**, not in MCP layer — duplicate retries at MCP level create duplicates
- **No agent safeguards** have been implemented (no confirmation flows, no spend limits, no scope enforcement)
- **Error sanitization is partial** — some internal details still leak in error responses
- **The MCP works for demos but is NOT production-grade for third-party agents**

**Clear statement**: This is an internal tool for OrignaGTA's own agents, not a public-facing API. Deploying it for third-party agents without the P0 fixes would be a security risk.

---

## Industry Comparison Table

| Feature | OrignaGTA | Stripe MCP | Shopify Catalog | Shopify Checkout |
|---------|-----------|-----------|-----------------|------------------|
| **Transport** | stdio (local) | HTTP remote | HTTP remote | HTTP remote |
| **Auth** | Env JWT (unverified) | OAuth 2.0 / restricted API keys | Client credentials → JWT (60m TTL) | Client credentials → JWT (60m TTL) |
| **Token lifetime** | Long (hours+) | Depends (OAuth) / restricted key scoping | 60 minutes | 60 minutes |
| **Tool domains** | Monolithic (10 tools) | Ops-focused (customers, invoices, refunds) | Discovery only | Transaction only |
| **Pagination** | Offset (limit/offset) | Offset | Limit + cursor | Limit + cursor |
| **Pagination limit** | 50 default, 100 max | Inherited from API (varies) | 300 max | 50 default |
| **Idempotency** | Backend only (OrignaBase SDK) | Per-tool guidance | Required for mutations | Required (`idempotency_key`) |
| **Error semantics** | HTTP→AppError mapping | Transport errors + resource outcomes | Two-layer (protocol vs business) | Two-layer (protocol vs checkout state) |
| **Caching** | None by design | Not advertised | Conservative (catalog only) | None (fresh only) |
| **Rate limiting** | Basic (429 detection) | API-wide | Per-endpoint | Per-endpoint |
| **Agent safeguards** | None | Human confirmation recommended | Per-tool result bounds | Completion confirmation |
| **Confirmation for mutations** | No | Recommended for sensitive ops | No | Required for checkout |
| **Spend thresholds** | None | None | None | None |

---

## Gap Analysis: Severity & Priority

### P0 — CRITICAL (Block third-party adoption, security risk)

#### 1. **Auth is local-env only, not OAuth/short-lived**
**Current**: `/auth.ts:20` reads `ORIGNABASE_JWT_TOKEN` from env; no signature verification.  
**Gap**: Cannot be used by remote agents without exposing long-lived secrets. Shopify/Stripe use OAuth discovery or short-lived bearer tokens.  
**Impact**: You cannot safely deploy OrignaGTA MCP for external agents.  
**Fix**: 
- Add OAuth 2.0 + PKCE discovery endpoint
- Keep env JWT as fallback for dev/local
- Implement JWT signature verification (RS256)
- Document token lifetime (recommend ≤ 1 hour)

**Effort**: 20-30 hours (OAuth flow, token parsing, PKCE, scope handling, integration testing)

#### 2. **Monolithic tool surface (all in one server)**
**Current**: `/index.ts:30` defines 10 tools across search, cart, checkout, orders, reviews, analytics in one server.  
**Gap**: No trust/scope boundary. Agent can reach checkout from search context. Shopify has 3+ separate MCPs (Catalog, Checkout, Storefront).  
**Impact**: Harder to control permissions, increases blast radius of prompt injection.  
**Fix**:
- Split into `@orignagta/catalog-mcp` (search, product detail, reviews) and `@orignagta/checkout-mcp` (cart, checkout, orders, analytics)
- Or: add tool-level scope system (e.g., `scope: "catalog"` vs `scope: "checkout"`)

**Effort**: 24-32 hours (split repo structure, auth per-server, docs, CI/CD updates)

#### 3. **No idempotency keys on mutations**
**Current**: Checkout and order operations rely on OrignaBase SDK retry logic, but MCP server itself has no idempotency tracking.  
**Gap**: If agent retries after timeout, creates duplicate carts/checkout sessions. Shopify requires `idempotency_key` on `complete_checkout`.  
**Impact**: Users get charged twice, orders duplicated.  
**Fix**:
- Add `idempotency_key` parameter to `add_to_cart`, `remove_from_cart`, `create_checkout`, `request_return`
- Track seen keys + results in cache or backend
- Return cached result on replay

**Effort**: 12-16 hours (key validation, cache/DB storage, tool schema updates, testing)

---

### P1 — HIGH (Limits scalability, adoption, performance)

#### 4. **Transport is stdio only; need HTTP MCP for remote deployment**
**Current**: `/index.ts:12` uses `StdioServerTransport`.  
**Gap**: Cannot scale horizontally, can't be deployed as a cloud service. Shopify/Stripe serve remote MCPs.  
**Impact**: Single-threaded, single-instance only. No load balancing.  
**Fix**:
- Add HTTP MCP adapter (Node.js `http` server listening on port)
- Keep stdio as dev mode
- Document deployment patterns (Docker, Vercel, etc.)

**Effort**: 16-24 hours (HTTP transport, CORS, session management, deployment, load testing)

#### 5. **Pagination is offset-based, not cursor**
**Current**: `/index.ts:59` defines `offset` + `limit` for search; `/validation.ts:118` clamps limit to 100.  
**Gap**: Offset breaks when list is mutated mid-pagination. Also, limit mismatch (doc says 50, code clamps 100). Shopify uses cursor pagination.  
**Impact**: Inconsistent UX, potential silent data loss in agent workflows.  
**Fix**:
- Add cursor pagination to `search_products`, `list_orders`
- Document limit bounds clearly (no mismatch)
- Deprecate offset pagination gracefully

**Effort**: 12-18 hours (schema changes, OrignaBase API calls, backwards compat, testing)

#### 6. **No business-outcome semantics (treats everything as exceptions)**
**Current**: `/api-client.ts:196` maps all non-2xx to errors.  
**Gap**: When stock is 0, price changed, coupon invalid, or shipping unavailable, MCP returns error instead of structured outcome. Agent can't reason about "user should pay $5 more" vs "operation failed".  
**Impact**: Agents can't handle common e-commerce scenarios (backorder, surge pricing, etc.).  
**Fix**:
- Return structured outcomes in success responses: `{ status: "success" | "check_required", outcome: { ... } }`
- Document outcome types: `out_of_stock`, `price_changed`, `coupon_invalid`, `shipping_unavailable`, `payment_required`

**Effort**: 20-28 hours (schema design, backend integration, comprehensive testing)

#### 7. **No caching (leaves performance on the table)**
**Current**: `/ARCHITECTURE.md:212` states "No caching (stateless server)".  
**Gap**: Every product search hits the API, every detail request re-fetches. Shopify caches catalog.  
**Impact**: Slower agent responses, higher OrignaBase load.  
**Fix**:
- Add Redis or in-memory TTL caching for `search_products` (5m), `get_product` (10m)
- Never cache `get_cart`, `list_orders`, `create_checkout`
- Document cache behavior

**Effort**: 10-14 hours (cache layer, TTL tuning, cache invalidation logic, testing)

#### 8. **Rate limiting is thin (no agent budgets)**
**Current**: `/api-client.ts:35` detects 429 but no proactive rate limiting.  
**Gap**: No per-agent spend limits, no request budgets. Agents can spam the MCP.  
**Impact**: Potential for DoS abuse, excessive charges from Stripe.  
**Fix**:
- Add per-agent spend limit (e.g., $50/day)
- Add per-tool request budget (e.g., search 1000/min)
- Return `429 Too Many Requests` with `Retry-After` header

**Effort**: 10-14 hours (rate limit middleware, budget tracking, agent identification, testing)

---

### P2 — MEDIUM (Nice-to-have, improves UX)

#### 9. **No agent safeguards (no confirmation, spend thresholds, scopes)**
**Current**: Tools execute immediately. No human confirmation, no spend cap, no prompt-injection warnings.  
**Gap**: Stripe docs explicitly recommend human confirmation for sensitive ops. MCP can't enforce per-tool scopes.  
**Fix**:
- Add tool metadata: `requiresConfirmation: true` for `create_checkout`, `request_return`
- Return a confirmation-required response; agent must re-call with confirmation token
- Document safe defaults (e.g., max $500 per checkout without confirmation)

**Effort**: 14-18 hours (confirmation token system, tool metadata, UI integration, testing)

#### 10. **Error messages leak internal details**
**Current**: `/api-client.ts` can expose SurrealDB error details, OrignaBase stack traces.  
**Gap**: Bad for security and debug clarity.  
**Fix**:
- Sanitize all error responses (remove stack, query details, internal IDs)
- Log full errors server-side only
- Return clean user-facing messages

**Effort**: 6-8 hours (centralize error sanitization, audit all error paths)

#### 11. **No observability/logging for agent actions**
**Current**: Basic logging in `/utils/logger.ts` but no audit trail of agent purchases.  
**Gap**: Can't track which agent made which purchase, no compliance trail.  
**Fix**:
- Log all mutations with agent ID, timestamp, result, outcome
- Structure logs for audit queries

**Effort**: 8-12 hours (structured logging, audit schema, testing)

#### 12. **Tool schemas are verbose, could be tighter**
**Current**: Input schemas are JSON Schema but not documented with examples.  
**Gap**: Agents have to infer behavior.  
**Fix**:
- Add `examples` to all tool input schemas
- Add return type schema to all tools
- Document error cases (when agent should expect 4xx vs outcome)

**Effort**: 6-10 hours (schema enrichment, documentation, review)

---

## Recommended Roadmap

### Phase 1 (Weeks 1-3): P0 - Security & Core Trust
- [ ] Add OAuth 2.0 + PKCE discovery endpoint
- [ ] Implement idempotency key tracking for mutations
- [ ] Add JWT signature verification (RS256)
- [ ] Document auth flows and deploy patterns

### Phase 2 (Weeks 4-6): P0 - Domain Separation
- [ ] Split into catalog and checkout MCPs (or add scopes)
- [ ] Update tool metadata with domain/scope info
- [ ] Re-design permission model (per-server or per-tool)

### Phase 3 (Weeks 7-9): P1 - HTTP Transport & Scale
- [ ] Add HTTP MCP adapter (remote server)
- [ ] Deploy to cloud (Vercel, Railway, etc.)
- [ ] Implement load balancing

### Phase 4 (Weeks 10-12): P1 - Data & Business Logic
- [ ] Add cursor pagination
- [ ] Implement business-outcome semantics (stock, pricing, shipping)
- [ ] Add caching layer (Redis)

### Phase 5 (Weeks 13-15): P1 - Safety & Observability
- [ ] Rate limiting + spend budgets
- [ ] Audit logging for all mutations
- [ ] Agent safeguard metadata

### Phase 6 (Weeks 16-18): P2 - Polish
- [ ] Confirmation flows
- [ ] Error sanitization
- [ ] Schema enrichment (examples, return types)

**Total estimated effort**: 8-12 weeks part-time (assuming 10-15h/week; 3-4 months full-time).

---

## What NOT to Do

- ❌ Don't switch to a different e-commerce platform's MCP (Shopify, Stripe) — they don't fit OrignaGTA's domain
- ❌ Don't add "prompts" or "resources" yet (MCP feature scope creep) — focus on fixing tools first
- ❌ Don't introduce database migrations for caching/audit until design is locked
- ❌ Don't break backwards compatibility on tool schemas without a migration period
- ❌ Don't claim P0 items are "done" or "shipped" — they are in-progress at best and need production-grade testing

---

## Sources

- **Stripe MCP**: https://docs.stripe.com/mcp, https://github.com/mcp/com.stripe/mcp
- **Shopify Catalog MCP**: https://shopify.dev/docs/agents/catalog/catalog-mcp
- **Shopify Checkout MCP**: https://shopify.dev/docs/agents/checkout/mcp
- **Shopify Storefront MCP**: https://shopify.dev/docs/agents/catalog/storefront-mcp
- **MCP Auth Patterns**: https://apps.extensions.modelcontextprotocol.io/api/documents/authorization.html
- **MCP Example Remote Server**: https://github.com/modelcontextprotocol/example-remote-server
