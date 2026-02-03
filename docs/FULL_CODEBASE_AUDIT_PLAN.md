# Comprehensive Codebase Audit Plan (2026-02-03)

Objective: "Bulletproof logic, no loose ends" - Full audit divided into 15 specific features.

## Audit Workflow
For each feature, a specialized subagent will:
1. Review relevant code files (Frontend + Backend + Rules).
2. Identify "loose ends" (TODOs, unhandled errors, missing validation, race conditions).
3. Verify "bulletproof" status (security, idempotency, edge cases).
4. Report findings and recommended fixes.

## Feature Breakdown

| ID | Feature Name | Core Files | Responsibility |
|----|--------------|------------|----------------|
| **F01** | **Auth & Session Management** | `lib/features/auth`, `lib/core/providers/auth_provider.dart` | Login, Register, Session timeout, MFA, Token refresh. |
| **F02** | **RBAC & Permissions** | `firestore.rules`, `functions/main.py`, `lib/core/services/role_service.dart` | Admin/Seller/Buyer gates, Custom claims, Rule enforcement. |
| **F03** | **Product Catalog (CRUD)** | `lib/features/products`, `functions/main.py`, `firestore.rules` | Creation, Validation, Deletion, Image uploads, Sanitization. |
| **F04** | **Digital Products Flow** | `lib/models/product.dart`, `lib/features/checkout`, Backend logic | File delivery, Shipping bypass, Validation. |
| **F05** | **Search & Discovery** | `lib/features/search`, `functions/algolia_service.py`, `algolia_product_repository.dart` | Algolia sync, Fallback logic, Filters, Pagination. |
| **F06** | **Cart & Stock Reservation** | `lib/features/cart`, `functions/main.py` (reservations) | Quantity logic, Stock holds, Cleanup, Race conditions. |
| **F07** | **Checkout Validation** | `functions/main.py`, `lib/features/checkout` | Address (Canada-only), CAD currency, Limits, Integrity. |
| **F08** | **Payment Processing** | `functions/main.py`, `functions/stripe.txt` | Stripe Intents, Webhook security, Idempotency, Capture. |
| **F09** | **Order State Machine** | `lib/features/orders`, `firestore.rules`, `functions/main.py` | Status transitions, Consistency, History, immutability. |
| **F10** | **Shipping Engine** | `functions/shipping_service.py`, `lib/features/shipping` | Estimates, Tiered calculation, Weights, International rules. |
| **F11** | **Tax Calculation** | `functions/shipping_service.py`, `functions/main.py` | GST/HST/PST rates, Recalculation, Rounding usage. |
| **F12** | **Seller Financials** | `functions/airwallex_service.py`, `lib/features/seller/payouts` | Payouts, Balance tracking, Commission logic, Ledgers. |
| **F13** | **Security Infrastructure** | `functions/rate_limiter.py`, `firestore.rules` | Rate limiting, DDoS, Injection, Headers, Secret handling. |
| **F14** | **Notifications System** | `functions/email_service.py`, `functions/main.py` | Transactional emails, Reliability, Templates, Spam compliance. |
| **F15** | **Frontend Core & Perf** | `lib/core`, `lib/main.dart`, `lib/router.dart` | Error boundaries (Sentry), Responsive logic, Provider leaks. |

## Progress Tracker

- [ ] F01: Auth & User Session
- [ ] F02: RBAC & Permissions
- [ ] F03: Product Catalog (CRUD)
- [ ] F04: Digital Products Flow
- [ ] F05: Search & Discovery
- [ ] F06: Cart & Stock Reservation
- [ ] F07: Checkout Validation
- [ ] F08: Payment Processing
- [ ] F09: Order State Machine
- [ ] F10: Shipping Engine
- [ ] F11: Tax Calculation
- [ ] F12: Seller Financials
- [ ] F13: Security Infrastructure
- [ ] F14: Notifications System
- [ ] F15: Frontend Core & Performance
