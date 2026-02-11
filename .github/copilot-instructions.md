# GitHub Copilot Instructions — OrignaGta

> Auto-loaded every Copilot session. Keep minimal — every token costs money.

**Source of truth:** [`CLAUDE.md`](../CLAUDE.md) — read before any changes.

## Project

**OrignaGta** — E-commerce marketplace, Canadian buyers, worldwide sellers. Flutter/Riverpod + Python Cloud Functions/Pydantic + Firestore + Stripe Connect Express + Algolia.

## Architecture — MVVM (Non-Negotiable)

- Screens = ZERO business logic, ViewModels = logic via Riverpod StateNotifier
- Repositories for data access, Providers (Riverpod ONLY — never Provider/Bloc/Redux)
- Cross-stack sync: `schema_constants.py` ↔ `schema_constants.dart` ↔ `database_schema.json` ↔ models ↔ tests

## Anti-Patterns (NEVER)

- `withOpacity()` → `Color.fromRGBO` or `DesignTokens`
- Hardcoded colors → `DesignTokens` from `utils/design_tokens.dart`
- `MaterialPageRoute` → named routes
- `CircularProgressIndicator` → `ModernLoadingIndicator`
- `IconButton` without tooltip
- Business logic in screens
- Edit one side of cross-stack pair without the other
- Magic strings → use `schema_constants`

## Critical Invariants

- **Idempotency** for all payment/transfer ops
- **Canada-only buyers** — backend-first validation, never trust frontend
- **Price re-verification** — backend re-fetches from Firestore
- **Self-purchase blocked** — `sellerId != buyerId` in backend

## Key References

- `CLAUDE.md` — primary AI context
- `docs/WORKFLOW_INDEX.md` — file groups to read together
- `docs/REPO_MAP.md` — file inventory
- `.github/copilot-skills.md` — learned patterns & gotchas

## Specialized AI Agents

- **🏗️ Infra Verification** → `python audit/run_hooks.py --hook infra` or `python audit/scripts/verify_infra.py`
- **🧪 QA Engineer** → `python audit/run_hooks.py --hook qa` or `python audit/scripts/qa_scanner.py`
