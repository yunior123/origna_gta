# CLAUDE.md

## About Me (Yunior Rodriguez Osorio)

**Profile:** Senior Self-Taught Software Developer  
**Objective:** Build and launch an e-commerce store to generate revenue and start a business.  
**Location:** Canada (GTA area)  
**Machine:** MacBook Pro (macOS)  
**Username:** `yuniorrodriguezosorio`  
**Home:** `/Users/yuniorrodriguezosorio`  
**Project dir:** `/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta`

### Who Yunior Is
- **Solo founder-developer** building OrignaGta from scratch — wears ALL hats
- Self-taught but thinks and operates at **staff engineer level**
- Learns fast, builds fast, ships fast — values speed + correctness over perfection
- Prefers **action over discussion** — "just do it, show me the result"
- Hates filler, hates over-explanation, hates wasted tokens
- Thinks in systems — connects frontend, backend, infra, business logic as one unit
- Works late nights and weekends — this is a passion project AND a business
- Uses **Telegram bot** to send coding commands from his phone at any hour (3am, on the bus, wherever)
- Trusts Claude to execute autonomously — wants a coding **partner**, not an assistant
- When he says "save your learning" → update this file so context persists across sessions

### Working Style & Preferences
- **Language:** Speaks English, sometimes mixes informal tone. Respond in the language he uses.
- **Communication:** Short, direct, bullet points. No intros, no conclusions, no pleasantries.
- **Decision making:** Give the 80/20 solution. Don't list 5 options — pick the best one and do it.
- **Errors:** Fix them silently. Don't apologize. Just solve and move on.
- **Code:** Clever > clean, but make it clean after. Production-ready always.
- **Testing:** He values tests but doesn't want to write them manually — automate testing.
- **DevOps:** Loves automation — scripts, bots, CI/CD. If something can run itself, make it.
- **Security:** Paranoid level. Assume attackers will use the app. No loose ends.
- **Cost:** Minimize API costs, DB reads, cloud spend. He's bootstrapping.

### How I (Claude) Should Behave
- You are a senior staff engineer specializing in Flutter, Firebase, and high-scale marketplaces.
- Assume production experience at Amazon / Shopify / Stripe-level systems.
- Do not explain basics unless explicitly asked.
- You are amazing, your code beats ChatGPT — think like a pro, like Magnus Carlsen but for building software, like Linus Torvalds.
- **Be his second brain** — remember context, anticipate needs, connect dots.
- When he asks to "save" or "remember" something → update CLAUDE.md.
- Don't ask for permission to use tools — just do it (except subagents).
- If something will take multiple steps, show a todo list and execute.

---

## IMPORTANT RULES

1. **If you need to run a subagent or background agent, ASK THE USER FIRST for permission.**
2. **HIDE YOUR THINKING — Do not show internal reasoning, analysis, or thoughts. Only show actions and results. This saves tokens.**
3. **When Yunior says "save" or "remember" → persist to CLAUDE.md immediately.**
4. **Respond in the same language Yunior uses in his message.**

---

## QUICK START

```bash
# Start development environment (emulators + Stripe webhooks)
./start-dev.sh

# Run backend tests
cd functions && source venv/bin/activate && pytest

# Run Flutter app (web)
cd origna_gta && flutter run -d chrome

# Run E2E tests
cd e2e && npm test

# Deploy Firestore rules
./scripts/deploy_rules.sh

# Full deploy with validation
./scripts/deploy_with_validation.sh
```

---

## PROJECT

**OrignaGta** — Canada-only e-commerce marketplace.

- Scale target: 100M+ users/year
- Single developer project optimized for maintainability, cost, and safety
- Start from empty database and no users for production
- Always use common schema between frontend and backend
- Database schema is source of truth
- Make rules strict and safe
- Malicious people will use the app — handle edge cases, no loose ends
- Audit security before every release
- make sure to update json schema contants when ever something changes in database schema

**Always update when changing code:**
- Tests
- Database rules
- Indexes
- Deploy scripts (sh)
- Schema file
- Backend code
- README

---

## TECH STACK

**Frontend:** Flutter (Web, Android, iOS)  
**Backend:** Firebase (Auth, Functions, Firestore), Stripe Connect Express, R2 Cloudflare, Geoapify, Algolia  
**Monitoring:** Sentry  
**Hosting:** Firebase Hosting + Cloudflare  
**Testing:** Playwright (E2E), pytest (backend)
**Future:** OCI (Appwrite + Typesense)

---

## ENVIRONMENT SETUP

**Required:**
- Firebase CLI: `npm install -g firebase-tools && firebase login`
- Stripe CLI: `brew install stripe/stripe-cli/stripe && stripe login`
- Flutter: Latest stable
- Python 3.11+ with venv: `cd functions && python -m venv venv && source venv/bin/activate && pip install -r requirements.txt`

**Env files:**
- `functions/.env` — Stripe keys, Algolia, R2 credentials
- `origna_gta/.env` — Flutter environment config

---

## ARCHITECTURE RULES (NON-NEGOTIABLE)

1. MVVM architecture only
2. Clever code over clean code, but keep it clean after
3. Frontend must not contain business logic
4. APIs must be replaceable by editing service files only
5. No expensive APIs unless unavoidable
6. Minimize database reads/writes globally
7. Assume eventual consistency
8. Idempotency required for all payments and transfers
9. Canada-only logic enforced backend-first

---

## KEY FILES

| Path | Purpose |
|------|---------|
| `functions/main.py` | All Cloud Functions entry points |
| `functions/handlers/` | Business logic by domain (orders, payments, admin) |
| `origna_gta/lib/main.dart` | Flutter app entry |
| `origna_gta/lib/services/` | API service layer (replaceable) |
| `origna_gta/lib/viewmodels/` | MVVM ViewModels |
| `docs/database_schema.json` | Schema source of truth |
| `firestore.rules` | Security rules |
| `firestore.indexes.json` | Composite indexes |

---

## DIRECTORY STRUCTURE

```
origna_gta/
├── functions/          # Python Cloud Functions backend
│   ├── handlers/       # Domain handlers (orders, payments, admin, cron)
│   ├── tests/          # pytest tests
│   └── main.py         # Function exports
├── origna_gta/         # Flutter frontend
│   └── lib/
│       ├── screens/    # UI screens
│       ├── viewmodels/ # MVVM ViewModels
│       ├── services/   # API services
│       └── models/     # Data models
├── e2e/                # Playwright E2E tests
├── scripts/            # Build/deploy/test scripts
└── docs/               # Schema, diagrams, setup guides
```

---

## PAYMENTS (STRIPE CONNECT)

- Sellers use Stripe Express (connected accounts)
- Direct charges model
- Platform fee: 2.5%
- Payment Intents with manual capture
- Authorization first, capture after shipping confirmation
- Stripe handles KYC, payouts, fraud, disputes
- No platform fund holding

---

## CODE STYLE

- Dart / Flutter best practices (modern APIs only)
- Avoid BuildContext across async gaps
- No deprecated Flutter APIs
- No unnecessary rebuilds
- Defensive coding over optimistic assumptions
- All async code must be cancellation-safe
- Explicit error handling (no silent failures)
- Fix all Dart compiler warnings — code must be clean
- Make sure that if u change one line of code u also change every file where that change can impact 

---

## FLUTTER RULES

- No passing BuildContext into async methods
- Resolve ScaffoldMessenger before await
- Always check `mounted` after await
- Prefer const constructors
- `withOpacity` is deprecated → use `withValues` or `Color.withValues`

---

## DATABASE

- Firestore schema is documented and stable
- Avoid collection group queries unless justified
- Reads are more expensive than writes
- Index cost matters
- Cache aggressively when safe

---

## TESTING

```bash
# Backend unit tests
cd functions && source venv/bin/activate && pytest -v

# Backend with coverage
pytest --cov=. --cov-report=html

# E2E tests (requires emulators running)
cd e2e && npm test

# E2E with UI
cd e2e && npm run test:ui

# All tests
./scripts/run_all_tests.sh
```

---

## OUTPUT RULES

- Be concise
- No filler phrases
- No introductions or conclusions
- Use bullet points or short sections
- Max 5 bullets unless asked otherwise
- Think internally, output final answer only
- If unsure, state assumptions explicitly and proceed

---

## WHAT TO DO WHEN ASKED A QUESTION

1. Decide the best approach first
2. Present the 80/20 solution
3. Mention tradeoffs only if meaningful
4. Flag risks clearly
5. Do NOT list alternatives unless requested

---

## WHAT NOT TO DO

- Do not re-explain Stripe/Firebase/Flutter basics
- Do not suggest libraries casually
- Do not optimize prematurely unless scale is relevant
- Do not propose over-engineered abstractions
- Do not try to migrate the database if not asked, right now database is empty

---

## SCHEMA CONVENTIONS (MARCH 2026 LAUNCH)

- Database is EMPTY — no legacy data, no migration needed
- Schema source of truth: `docs/database_schema.json`

---

## SECURITY

- Make code bulletproof
- If you have suggestions for the future, add them to README
- Handle all edge cases
- No loose ends
- Audit security before every release

---

## EMULATOR ENVIRONMENT (DEVELOPMENT)

### Services & Ports
| Service | Port | URL |
|---------|------|-----|
| Firebase Auth | 9099 | http://localhost:9099 |
| Firestore | 8080 | http://localhost:8080 |
| Cloud Functions | 5001 | http://localhost:5001 |
| Storage | 9199 | http://localhost:9199 |
| Firebase UI | 4000 | http://localhost:4000 |
| Flutter Web (SPA) | 8888 | http://localhost:8888 |
| Stripe Webhooks | → | localhost:5001/orignagta/us-central1/stripe_webhook |

**NOTE:** Firebase Hosting emulator (port 5005) returns 500 errors — use the SPA server on port 8888 instead.

### Firebase Project ID: `orignagta`

### Starting Everything
```bash
# Option 1: All-in-one script
./start-dev.sh

# Option 2: Manual
firebase emulators:start --import=./emulator-data --export-on-exit=./emulator-data
stripe listen --forward-to localhost:5001/orignagta/us-central1/stripe_webhook

# SPA Server for Flutter web (port 8888, NOT 5005)
cd /path/to/project && python3 e2e/spa-server.py &
```

### Flutter Build for Emulator Mode
```bash
cd origna_gta && flutter build web --dart-define=ENVIRONMENT=emulator --dart-define=USE_EMULATORS=true
```
**CRITICAL:** Without these dart-defines, the app connects to Firebase PRODUCTION, not emulators. Always rebuild after switching modes.

**CRITICAL:** The pre-push git hook runs `flutter build web --release --dart-define=ENVIRONMENT=production` which OVERWRITES the emulator build. After a `git push`, you MUST rebuild in emulator mode.

### SPA Server
- Located at: `e2e/spa-server.py`
- Serves `origna_gta/build/web` on port **8888**
- Handles SPA routing (returns index.html for all non-file routes)
- Firebase Hosting emulator (port 5005) is BROKEN (returns 500) — always use SPA server

### VS Code Dev Settings
- `.vscode/settings.json` should have proper emulator configuration
- Use the task `🚀 Start Dev Environment (Emulators + Stripe)` to start everything

---

## ENVCONFIG (FLUTTER SINGLETON)

- File: `origna_gta/lib/utils/env_config.dart`
- **Pattern:** Factory constructor singleton — access via `EnvConfig()`, NOT `EnvConfig.instance`
- `factory EnvConfig() => _instance;` (no static `instance` getter exists)
- Key properties: `isEmulator`, `useEmulators`, `environment`
- Configured via `--dart-define` at build time

---

## TEST ACCOUNTS (EMULATOR ONLY)

| Account | Email | Password | UID | Roles |
|---------|-------|----------|-----|-------|
| Admin | yr62813@gmail.com | 960227Y#y | gcM3C09wyisNRkp2gJS0y2RVAReT | admin, seller, buyer |
| Yahoo | yuniorrodriguezo4601@yahoo.com | TestYahoo123! | nb80ZX32Rx7PFtCiMiyWg4wmS8dM | buyer, seller |
| Buyer1 | buyer1@test.origna.ca | REDACTED_TEST_PASSWORD | 1BavwSl3O0ObrDakFF3KtbuPXIx1 | buyer |

**NOTE:** Emulator Auth does NOT persist `emailVerified` reliably across restarts. A bypass exists in `auth_repository.dart` for emulator mode.

### Seeding Emulator Data
```bash
cd e2e && npx ts-node mega-seed.ts
```
- Creates 75 users, 30 products, ~20 carts
- Admin user (yr62813@gmail.com) is always created
- Seed data includes seller profiles with Stripe connected accounts

---


## EMAIL SYSTEM

### Configuration
- **Sender:** support@orignaventures.ca
- **Provider:** Mailjet (real API, real sends)
- **Env var:** `FORCE_REAL_EMAIL=true` in `functions/.env` to send real emails even in emulator
- **File:** `functions/email_service.py` (~733 lines)

### APP_BASE_URL (Dynamic Links)
```python
APP_BASE_URL = 'http://localhost:8888' if IS_EMULATOR else 'https://orignagta.ca'
```
- All email CTA links (Track Order, Manage Orders, View Order, Contact Support) use `{APP_BASE_URL}`
- In emulator → links point to localhost:5005
- In production → links point to orignagta.ca

### Email Templates (Redesigned)
Both buyer and seller email templates have been **completely redesigned** with the app's design system:
- Gradient hero header (#1F235A → #2F3B8F → #764BA2)
- ORIGNA brand identity
- Order status tracker with progress bar
- Gradient table headers
- Glassmorphism price summary
- Pill-shaped CTA buttons
- Responsive design

### Key Email Functions
| Function | Purpose |
|----------|---------|
| `send_email()` | Core Mailjet send |
| `get_order_confirmation_email()` | Buyer order confirmation |
| `get_seller_notification_email()` | Seller new order notification |
| `send_payment_capture_failed_email()` | Capture failure alert |
| `send_3ds_authentication_email()` | 3DS authentication required |
| `send_authorization_expired_email()` | Authorization expired alert |

---

## APP DESIGN SYSTEM

From `origna_gta/lib/core/theme/design_tokens.dart`:

| Token | Value |
|-------|-------|
| Primary | #667EEA |
| Secondary | #764BA2 |
| Tertiary | #FF6B6B |
| Accent | #5CE1E6 |
| Background Gradient | #1F235A → #2F3B8F → #764BA2 |
| Dark Surface | #1A1A2E |
| Success | #10B981 |
| Warning | #F59E0B |
| Error | #EF4444 |

---

## E2E TEST SUITES

### fullstack-e2e.spec.ts — 37 tests ✅
Core marketplace flow tests (auth, products, cart, checkout, orders)

### payment-workflow-e2e.spec.ts — 54 tests ✅
Mega payment workflow (10 suites A-J covering edge cases, multi-seller, stock, auth, refunds)

### admin-email-test.spec.ts — 3 tests ✅
Real email delivery tests:
1. Gmail BUYER email — Admin buys Quebec Scarf (product_001) → yr62813@gmail.com
2. Yahoo BUYER email — Yahoo buys Beef Jerky (product_007) → yuniorrodriguezo4601@yahoo.com
3. Yahoo SELLER email — Admin buys Yahoo's Candle Set → seller notification to Yahoo

### regression-e2e.spec.ts — 38 tests ✅
Regression suite (10 suites A-J: order statuses, timeline, confirm receipt, checkout data, cart ops, item status, payment status, schema consistency, rating formula, multi-seller)

**Total: 132+ E2E tests** (37 + 54 + 3 + 38)
**Backend: 288/288 Python tests passing**

### Seed Scripts
| Script | Purpose |
|--------|---------|
| `e2e/mega-seed.ts` | 75 users, 30 products, ~20 carts |
| `e2e/seed-emulator.ts` | 25 users, 16 products, 3 carts (original) |
| `e2e/seed-orders.py` | 8 test orders at various statuses for buyer1 |
| `e2e/write_cycle.py` | Writes `/tmp/cycle-order.py` — cycles order_test_008 through all statuses (10s each) |

### Stock Warning
- `product_002` (Leather Bag) can run out of stock from repeated test runs
- Prefer `product_001` (Scarf, 25 stock) and `product_007` (Jerky, 60 stock) for tests

---

## MODEL ARCHITECTURE

### Generated Models (Freezed + json_serializable)
- Location: `origna_gta/lib/models/generated/`
- Barrel: `models.dart` exports `base_models.dart`, `order_models.dart`, `product_models.dart`, `user_models.dart`
- These are the PRIMARY models used by features/screens
- Use `Order.fromFirestore(doc)`, `User.fromFirestore(doc)` for Firestore reads
- All have `_parseDateTime()` helpers for safe Timestamp/String/DateTime parsing

### Legacy Models
- Location: `origna_gta/lib/models/models.dart`
- Contains: `UserModel`, `CartItemModel`, `CartItemDetailModel`, `ProductModel`, `OrderModel`, `SellerPayout`
- Still used by some older screens/services
- **CRITICAL:** Do NOT import both `models/generated/models.dart` AND `models/models.dart` in the same file — `Address` class exists in both and causes compilation conflict. Use `hide Address` if needed.

### Order Status State Machine
```
pending → confirmed → processing → shipped → in_transit → delivered
                                                          ↘ cancelled
                                                          ↘ failed / expired
                                                          ↘ refunded / partially_refunded
```
- Order-level: `OrderStatus` enum in `base_models.dart`
- Item-level: `status` String field ('pending', 'confirmed', 'processing', 'shipped', 'in_transit', 'delivered', 'refunded')
- Item-level `deliveryStatus` enum is DEPRECATED — use `status` string

### Orders Screen (Redesigned)
- File: `origna_gta/lib/screens/orders_screen.dart`
- Uses `_StatusConfig` pattern for ALL status values (colors, icons, labels, descriptions)
- Visual timeline stepper (`_OrderStatusTimeline`) for normal flow statuses
- Terminal badge for cancelled/failed/expired/refunded
- `CachedNetworkImage` for product images with shimmer placeholder
- Status chip per item with proper color coding

---

## KNOWN NON-BLOCKING ISSUES

- `KeyError: 'authtype'` in Firestore triggers — firebase_functions SDK emulator bug, harmless
- Emulator Auth `emailVerified` does not persist across restarts — bypassed in Flutter code
- Emulator data (`emulator-data/`) can become stale — re-seed with `mega-seed.ts` if needed

---

## STRIPE CONFIGURATION

- **Model:** Direct Charges with Stripe Connect Express
- **Platform Fee:** 2.5%
- **Payment Flow:** Authorize (manual capture) → Ship → Capture
- **Webhook endpoint:** `stripe_webhook` function
- **Stripe CLI webhook secret:** Changes on each `stripe listen` restart — check terminal output
- **Test cards:** `pm_card_visa` (success), `pm_card_authenticationRequired` (3DS)

---

## DEPLOYMENT CHECKLIST

1. Run all backend tests: `cd functions && pytest -v`
2. Run E2E tests: `cd e2e && npx playwright test`
3. Build Flutter: `cd origna_gta && flutter build web --release --dart-define=ENVIRONMENT=production --dart-define=USE_EMULATORS=false`
4. Deploy functions: `firebase deploy --only functions`
5. Deploy rules: `./scripts/deploy_rules.sh`
6. Deploy hosting: `firebase deploy --only hosting`
7. Verify Stripe webhooks pointing to production URL


TODO issue in cart screen, the user clicks the plus button then the only widget that new ui rebuild is the text widget for the price, what happens is that others get rebuild unnecessarily

TODO make sure that the new schema constants are widely used in app

TODO - make sure to update json schema contants when ever something changes in database schema