# 🧠 Copilot Skills — OrignaGta AI Knowledge Base

> Auto-loaded by GitHub Copilot alongside `copilot-instructions.md`.
> Contains learned patterns, gotchas, and decision tables so any AI
> can work on this codebase efficiently without re-discovering them.

---

## 🔍 Search & Product Fetch — Routing Decision Table

| Condition | Route | Why |
|---|---|---|
| Text search + Algolia available | Algolia → Firestore fallback on error | Full-text ranking, typo tolerance |
| Text search + Algolia unavailable | Firestore `arrayContains(keywords.first)` | Emulator has no Algolia; credentials empty |
| Category only (no text) | Firestore `where(categoryId)` | Cursor pagination works; Algolia can't paginate with `DocumentSnapshot` |
| Browse (no filter) | Firestore `orderBy(dateCreated)` | Simple cursor pagination |
| Algolia timeout (>5s) | Firestore fallback | Prevents infinite shimmer |

### Key Files
- `lib/services/algolia_service.dart` — `isAvailable` flag, `EnvConfig().algoliaIndexName`, facet filters
- `lib/core/repositories/algolia_product_repository.dart` — routing logic, `_fetchFromFirestore`, `_searchWithAlgolia`
- `lib/core/providers.dart` — `productRepositoryProvider` → always `AlgoliaProductRepository` (graceful degradation built-in)
- `lib/utils/env_config.dart` — `algoliaIndexName` returns `products_emulator` or `products`
- `lib/services/conf_services.dart` — Remote Config keys (`algolia_app_id`, `algolia_search_api_key`), defaults to empty

### Emulator vs Production
| Service | Emulator | Production |
|---|---|---|
| Firestore | Emulated (port 8080) | Real |
| Auth | Emulated (port 9099) | Real |
| Functions | Emulated (port 5001) | Real |
| Storage | Emulated (port 9199) | Real |
| Algolia | **NOT emulated** — `isAvailable=false` | Real — `isAvailable=true` |
| Stripe | Test keys (sk_test_*) | Live keys |
| R2 Cloudflare | `emulator/` prefix | Root |

---

## 🏠 Home Screen — Pagination & State

### Sentinel Pattern (copyWith)
`HomeState.copyWith` uses a `_Sentinel` class to distinguish "field not passed" from "explicitly set to null".
Without this, `copyWith(lastDocument: null)` vs not passing it are indistinguishable.

```
✅ state.copyWith(lastDocument: null)  → resets pagination
✅ state.copyWith()                     → preserves lastDocument
```

### Infinite Scroll Guards
In `HomeViewModel.loadProducts()`:
1. Guard: `isLoading || isLoadingMore` → skip
2. Guard: `!isFirstLoad && !hasMore` → skip  
3. Deduplication: filter products by `productId` before appending
4. `hasMore: false` for Algolia results (no cursor pagination)

### Category Switch Flow
`onCategorySelected()` → resets `products`, `lastDocument`, `hasMore`, `isLoading`, `isLoadingMore` → calls `loadProducts()`

### Favorites Blink Fix
`favoritesProvider` uses `ref.keepAlive()` to prevent auto-dispose when the grid rebuilds during category switches.

---

## 💳 Payment Pipeline

```
checkout_provider.dart → create_payment_intent → payment_stripe.py
  (manual capture) → seller confirms → capture_payment → 
  Stripe Connect transfer after delivery
```

- **2.5% platform fee** on every transaction
- **Manual capture** — PaymentIntent authorized, captured only after seller confirms
- **Idempotency keys** required for ALL payment operations
- Cron: 7-day auto-confirm, authorization expiry check

---

## 📦 Order Lifecycle

```
pending → confirmed → processing → shipped → in_transit → delivered
```
- Cancel/refund: restore stock + refund/void PaymentIntent
- Rating: backend-only via `submit_product_rating` Cloud Function
- Cross-stack: `order_models.dart` ↔ `models/order.py` ↔ `Order.json`

---

## 🏗️ Add Product Flow

Key gotchas (from `.claude/skills/add-product-flow/SKILL.md`):
- Sentinel `copyWith` for nullable fields
- Image sync callback pattern
- Free shipping cascade (forced true for digital)
- Postal code normalization (uppercase, trim, format validation)
- Stale coordinates if address edited after geocoding
- Double-submit guard in ViewModel
- `_inventoryManaged`, `_trackQuantity`, `_allowBackorder` are local-only state (NOT persisted) — known TODO

---

## 🎨 UI Patterns

### NEVER Do
- `withOpacity()` → use `Color.fromRGBO` or `DesignTokens`
- Hardcoded colors → `DesignTokens` from `utils/design_tokens.dart`
- `MaterialPageRoute` → named routes
- `CircularProgressIndicator` → `ModernLoadingIndicator`
- `IconButton` without tooltip
- Business logic in screens → ViewModels only

### Glassmorphism
All Modern* widgets use the glassmorphism toolkit (`utils/glassmorphism.dart`).
Backdrop filter + frosted glass effect. Design tokens control blur, opacity, border radius.

### Responsive
`utils/responsive.dart` — breakpoints and scaling. All screens adapt to mobile/tablet/desktop.

---

## 🔄 Cross-Stack Sync Checklist

When changing a field:
1. `functions/schema_constants.py` — Python source of truth
2. `lib/core/schema/schema_constants.dart` — Dart mirror  
3. `docs/database_schema.json` — Firestore schema doc
4. Freezed models (`lib/models/generated/`) — regenerate with `build_runner`
5. Pydantic models (`functions/models/`) — update manually
6. Tests — update ALL affected test files

---

## 🧪 Testing Quick Reference

```bash
# Backend (288+ tests)
cd functions && source venv/bin/activate && pytest tests/ -v --tb=short

# Flutter
cd origna_gta && flutter test && flutter analyze

# E2E (161+ tests)
cd e2e && npx playwright test

# Python lint
ruff check functions/
```

---

## 🐛 Known Gotchas

1. **Firestore text search** — limited to `arrayContains` on first keyword only. Multi-word search requires Algolia.
2. **Remote Config in emulator** — `fetchAndActivate()` returns defaults (empty strings). This is expected.
3. **AlgoliaProductRepository.uploadImages / getUploadUrl** — throw `UnimplementedError`. Image upload goes through `FirebaseProductRepository` path.
4. **Firestore eventual consistency** — reads after writes may return stale data. Use `Source.server` for critical verifications.
5. **Canada-only validation** — NEVER trust frontend. Backend validates postal code + province on every write.

---

## 📁 File Groups (Read Together)

| Workflow | Files |
|---|---|
| Product search | `algolia_service.dart`, `algolia_product_repository.dart`, `product_repository.dart`, `home_viewmodel.dart`, `home_state.dart`, `home_screen.dart` |
| Product CRUD | `products_provider.dart`, `add_product_screen.dart`, `product_detail_screen.dart`, `handlers/products.py` |
| Checkout | `checkout_provider.dart`, `checkout_screen.dart`, `payment_stripe.py`, `shipping_service.py` |
| Orders | `order_repository.dart`, `orders_viewmodel.dart`, `orders_screen.dart`, `handlers/orders.py` |
| Auth | `auth_repository.dart`, `auth_viewmodel.dart`, `login_screen.dart`, `handlers/admin.py` |
| Seller | `seller_viewmodel.dart`, `seller_dashboard_screen.dart`, `seller_products_screen.dart` |

---

*Last updated: 2026-02-07 — Copilot session with Yunior*
