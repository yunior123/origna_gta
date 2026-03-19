# OrignaGTA Developer Documentation

Complete documentation for the OrignaGTA e-commerce platform. Start with the guide that matches your role.

---

## For API Consumers (Backend Developers, Integrations)

- **[API Reference](./api-reference.md)** — Complete endpoint documentation with request/response schemas, error codes, and examples
- **[Webhook Documentation](./webhooks.md)** — Stripe webhook handling, signature verification, event types, and retry policies
- **[Schema Reference](./schema-reference.md)** — SurrealDB collection definitions, field types, relationships, and constraints

### Quick Start

```bash
# Initialize SDK
curl -X POST https://api.orignagta.ca/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePassword123!",
    "turnstileToken": "0x4AAA..."
  }'
```

---

## For Flutter Developers

- **[Flutter SDK Quick Start](./flutter-sdk-quickstart.md)** — Installation, initialization, authentication, CRUD operations, subscriptions, and best practices

### Quick Start

```dart
// Initialize
await OrignaBase.initialize(url: 'https://api.dev.orignagta.ca');

// Login
final result = await OrignaBase.auth.login(
  email: 'user@example.com',
  password: 'SecurePassword123!',
);

// Query products
final products = await OrignaBase.collection('products')
  .where('lifecycleStatus', '==', 'active')
  .limit(20)
  .get();
```

---

## For New Sellers

- **[Seller Onboarding Guide](./seller-guide.md)** — Step-by-step instructions for account setup, product listing, order management, payouts, and returns

### Steps

1. Create account at https://orignagta.ca
2. Complete seller registration (Stripe Connect onboarding)
3. Set up store profile and add products
4. Manage orders and process shipments
5. View earnings and receive payouts

---

## Environment URLs

| Environment | Web | API | Webhooks |
|---|---|---|---|
| **Production** | https://orignagta.ca | https://api.orignagta.ca | https://api.orignagta.ca/stripe/webhook |
| **Staging** | https://staging.orignagta.ca | https://api.staging.orignagta.ca | https://api.staging.orignagta.ca/stripe/webhook |
| **Development** | https://dev.orignagta.ca | https://api.dev.orignagta.ca | https://api.dev.orignagta.ca/stripe/webhook |

**Test Accounts** (Dev only):
- Admin: `e2e-admin@test.origna.ca` / `REDACTED_TEST_PASSWORD`
- Seller: `e2e-seller@test.origna.ca` / `REDACTED_TEST_PASSWORD`
- Buyer: `e2e-buyer@test.origna.ca` / `REDACTED_TEST_PASSWORD`

---

## Key Concepts

### Authentication
- JWT-based auth (RS256 access tokens, HS256 refresh tokens)
- Cloudflare Turnstile bot protection (production only)
- Optional 2FA (TOTP) for account security
- Automatic token refresh via SDK

### Money
- **All monetary values in integer cents** (never float)
- Subtotal: sum of item prices
- Tax: calculated per Canadian province
- Platform fee: 2.5% of subtotal
- Free shipping: orders ≥ $75 subtotal

### Order Lifecycle
```
pending ──[payment.succeeded]──> confirmed ──[ship]──> shipped ──[deliver]──> delivered
         ──[payment.failed]─┬──> cancelled
                           └─[timeout]──> cancelled
```

### Real-Time Data
- Subscribe to collection changes: `.onSnapshot()`
- Automatic sync when connection restored
- Offline-first capability (write while offline)

### Search
- Meilisearch integration for full-text search
- Filterable fields: `lifecycleStatus`, `priceCents`, `sellerId`
- Sortable: `priceCents`, `dateCreated`

---

## Architecture

```
Flutter App (Web/Mobile)
        ↓
OrignaBase SDK
        ↓
OrignaBase API (Rust, Axum)
        ↓
    ┌───┴────┬──────────┬─────────┐
    ↓        ↓          ↓         ↓
SurrealDB  Meilisearch Stripe  Cloudflare R2
(NoSQL)    (Search)   (Payments) (CDN)
```

### Backend Stack
- **Language**: Rust (Axum web framework)
- **Database**: SurrealDB v2 (NoSQL, real-time)
- **Search**: Meilisearch v1.12 (full-text search)
- **Payments**: Stripe API + Stripe Connect
- **Storage**: Cloudflare R2 (S3-compatible)
- **Infrastructure**: VPS (204.168.137.16) with Docker Compose

---

## Common Tasks

### Create a New Endpoint

1. Add route handler in `crates/ob-handlers/src/`
2. Define request/response types (serde)
3. Implement auth checks (JWT, admin role)
4. Add rate limiting if needed
5. Handle errors with `Result<T, Error>`
6. Add webhook logging for auditing
7. Test with E2E (Playwright)

### Modify Database Schema

1. Update SurrealDB migration in `crates/orignabase/migrations/`
2. Update `DEFINE TABLE` and `DEFINE INDEX` statements
3. Update Dart schema constants in `lib/core/schema/schema_constants.dart`
4. Test with seed data
5. Deploy to dev, staging, then production

### Add a New Stripe Event

1. Add handler in `crates/ob-handlers/src/payments/webhooks.rs`
2. Extract event metadata
3. Check `webhook_events` for idempotency
4. Update order/seller state atomically
5. Send notifications
6. Log event with `info!()`
7. Test with Stripe CLI: `stripe trigger {event_type}`

---

## Testing

### Unit Tests
```bash
cd origna_gta
flutter test
```

### Integration Tests
```bash
flutter test --exclude-tags=golden
```

### E2E Tests (Playwright/Bun)
```bash
cd e2e
bun test
```

### Webhook Testing (Local)
```bash
stripe listen --forward-to localhost:8080/stripe/webhook
stripe trigger payment_intent.succeeded
```

---

## Debugging

### Check API Logs
```bash
ssh -i ~/.ssh/id_ed25519 root@204.168.137.16
docker compose -f /opt/orignabase/docker-compose.yml logs orignabase-dev | grep error
```

### Test an Endpoint
```bash
curl -X POST https://api.dev.orignagta.ca/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"REDACTED_TEST_PASSWORD"}'
```

### Check Webhook History
1. Stripe Dashboard > Developers > Webhooks
2. Click endpoint
3. View recent deliveries and response codes

### Database Query
```bash
ssh root@204.168.137.16
surreal sql
SELECT * FROM products WHERE sellerId = 'users:seller_abc' LIMIT 10;
```

---

## Support

| Issue | Contact | Response Time |
|---|---|---|
| Bug report | support@orignagta.ca | 24–48 hours |
| Integration help | support@orignagta.ca | 24 hours |
| Seller support | Seller dashboard chat | 1–2 hours (business hours) |
| Security issue | security@orignagta.ca | Immediate |

---

## Further Reading

- **Security Best Practices**: `.claude/rules/security.md`
- **Backend Architecture**: `vps_multi_env_setup_2026-03-17.md` (memory)
- **Order State Machine**: `.claude/rules/orders.md`
- **Payment Processing**: `.claude/rules/payments.md`
- **Flutter Coding Standards**: `.claude/rules/flutter.md`
- **Testing Rules**: `.claude/rules/testing.md`

---

## Glossary

| Term | Definition |
|---|---|
| **SurrealDB** | NoSQL database with real-time subscriptions and row-level security |
| **Meilisearch** | Full-text search engine for products and content |
| **Stripe Connect** | Payment processor for seller payouts |
| **Turnstile** | Cloudflare's bot protection (replaces reCAPTCHA) |
| **R2** | Cloudflare's S3-compatible object storage (CDN) |
| **Idempotency** | Operation safe to retry multiple times without side effects |
| **JWT** | JSON Web Token (stateless authentication) |
| **RLS** | Row-Level Security (database-enforced access control) |
| **Webhook** | HTTP POST callback from Stripe to our backend |

---

**Last Updated**: March 18, 2026  
**Documentation Version**: 1.0  
**Status**: Production

For technical questions, check the API Reference first, then contact support@orignagta.ca.
