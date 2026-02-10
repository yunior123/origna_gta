# GitHub Copilot Instructions — OrignaGta

> These instructions are automatically loaded by GitHub Copilot in VS Code.

## ⚠️ READ FIRST: Source of Truth

**ALL AI agents (Copilot, Gemini, Claude, etc.) MUST read [`CLAUDE.md`](../CLAUDE.md) in the project root before making any changes.**

`CLAUDE.md` contains:
- Full project context and architecture rules
- Tech stack and conventions
- Critical patterns and anti-patterns
- Workflow commands and learned knowledge
- Cross-stack mapping (Frontend ↔ Backend ↔ Schema)

This file provides a quick reference only. For complete context, always consult `CLAUDE.md`.

---

## Project Overview

**OrignaGta** — E-commerce marketplace serving Canadian buyers, with sellers worldwide. Scale: 100M+ users/year. Launch: March 2026.
Solo founder-developer project. Production-grade quality required.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.10+ (Web, Android, iOS) |
| State Management | **Riverpod** (NEVER Provider, NEVER Bloc, NEVER Redux) |
| Models | **Freezed** + json_serializable (code generation) |
| Backend | Python 3.11 Cloud Functions (Flask + firebase-functions) |
| Validation | **Pydantic v2** for all request/response models |
| Database | Cloud Firestore (eventual consistency assumed) |
| Payments | Stripe Connect Express (direct charges, manual capture, 2.5% platform fee) |
| Search | Algolia |
| Storage | Firebase Storage + Cloudflare R2 (images) |
| Email | Mailjet |
| Monitoring | Sentry |
| Auth | Firebase Auth + PyOTP (admin MFA) |
| CI/CD | GitHub Actions |

## Architecture — MVVM (Non-Negotiable)

**CRITICAL:** Screens contain ZERO business logic — only UI rendering.

```
Frontend (Flutter)           Backend (Python)
┌─────────────────┐         ┌──────────────────┐
│ Screen (View)   │ ←UI→    │ handlers/*.py     │ ← HTTP endpoints
│ ViewModel       │ ←Logic→ │ models/*.py       │ ← Pydantic models
│ Repository      │ ←Data→  │ services/*.py     │ ← Business logic
│ Provider (Riverpod)│      │ schema_constants  │ ← Shared schema
└─────────────────┘         └──────────────────┘
```

See `CLAUDE.md` for full architecture rules and cross-stack mapping.

## Folder Structure

```
origna_gta/lib/
├── core/           → repositories/, schema/schema_constants.dart
├── features/       → MVVM ViewModels (auth, cart, checkout, orders, products, etc.)
├── models/         → generated/ (Freezed models)
├── screens/        → 28 screens (UI only, no logic)
├── services/       → algolia, analytics, session, splash
├── utils/          → design_tokens, glassmorphism, responsive, animations
└── widgets/        → 9 Modern* reusable widgets

functions/
├── handlers/       → admin, orders, payment_stripe, products, cron_jobs
├── models/         → base, order, product, user (Pydantic)
├── main.py         → Entry point + route registration
├── schema_constants.py → Single source of schema truth (backend)
└── tests/          → 288+ unit tests
```

See `docs/REPO_MAP.md` for complete file inventory.

## Critical Patterns (MUST Follow)

1. **Cross-stack sync** — When changing a field: update `schema_constants.py` → `schema_constants.dart` → `database_schema.json` → Freezed models → Pydantic models → ALL tests
2. **Idempotency** — All payment and transfer operations MUST be idempotent (use idempotency keys)
3. **Canada-only buyers** — Backend-first postal code/province validation for buyer/shipping addresses. Sellers can be worldwide. Never trust frontend.
4. **Eventual consistency** — Minimize Firestore reads/writes. Assume data may be stale.
5. **Error handling** — Always handle: network errors, auth expiry, permission denied, not found, rate limits

**See `CLAUDE.md` RULES and ARCHITECTURE sections for complete patterns.**

## Anti-Patterns (NEVER Do)

- ❌ Never use `Provider` or `Bloc` — only Riverpod
- ❌ Never put business logic in screens — use ViewModels
- ❌ Never use `withOpacity()` on colors — use `Color.fromRGBO` or design tokens
- ❌ Never hardcode colors — use `DesignTokens` from `utils/design_tokens.dart`
- ❌ Never use `MaterialPageRoute` — use named routes
- ❌ Never use `CircularProgressIndicator` without `ModernLoadingIndicator` wrapper
- ❌ Never use `IconButton` without a tooltip
- ❌ Never edit one side of a cross-stack pair without updating the other

**See `CLAUDE.md` for complete anti-patterns list.**

## Testing

```bash
cd functions && source venv/bin/activate && pytest     # 288+ backend tests
cd origna_gta && flutter test                          # Flutter unit tests
cd origna_gta && flutter analyze                       # Dart static analysis
cd e2e && npx playwright test                          # 161+ E2E tests
ruff check functions/                                  # Python linting
```

**See `CLAUDE.md` WORKFLOW COMMANDS for full test automation.**

## Key References

- **`CLAUDE.md`** — **PRIMARY SOURCE OF TRUTH** for all AI agents
- `docs/WORKFLOW_INDEX.md` — All workflows with file groups to read together
- `docs/REPO_MAP.md` — Complete file inventory with responsibilities
- `docs/database_schema.json` — Firestore schema definition
- `docs/SYMBOL_MAP.md` — AST-extracted class/function signatures by domain
- `docs/SELLER_TERMS_AND_POLICIES.md` — Business rules for sellers
- `.github/copilot-skills.md` — Learned patterns, gotchas, and decision tables
- `.github/claude.md` — Minimal context for GitHub-based workflows

---

## Quick Reference: Most Common Patterns

### State Management (Riverpod)
```dart
// Provider definition
final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier(ref);
});

// ViewModel pattern
class MyNotifier extends StateNotifier<MyState> {
  MyNotifier(this._ref) : super(MyState.initial());
  final Ref _ref;
  // Business logic here
}
```

### Design Tokens (Never hardcode colors)
```dart
import 'package:origna_gta/utils/design_tokens.dart';

DesignTokens.primaryColor
DesignTokens.backgroundColor
DesignTokens.textPrimary
```

### Schema Constants
```dart
// Frontend
import 'package:origna_gta/core/schema/schema_constants.dart';

// Backend
from schema_constants import ORDER_STATUSES, PRODUCT_CONDITION
```

**For complete patterns, workflows, and learned knowledge, see `CLAUDE.md`.**
