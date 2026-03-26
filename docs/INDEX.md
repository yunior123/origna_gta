# OrignaGTA Documentation Index

> **Documentation Philosophy**: This codebase follows the [Diátaxis Framework](https://documentation.divio.com/) — a systematic approach to documentation that divides content into four distinct categories: **Tutorials**, **How-to Guides**, **Reference**, and **Explanation**.

---

## Quick Navigation

| I want to... | Go to |
|--------------|-------|
| Start developing immediately | [Onboarding Guide](./ONBOARDING.md) |
| Understand the system architecture | [Architecture Reference](./ARCHITECTURE.md) |
| Find API documentation | [API Reference](./api-reference.md) |
| Learn how to implement a feature | [How-to Guides](#how-to-guides) |
| Understand why something exists | [Design Decisions](#explanation) |
| Deploy to production | [VPS Operations Guide](./VPS_OPERATIONS.md) |
| Run tests | [Testing Guide](#testing-reference) |

---

## Tutorials (Learning-Oriented)

> **Purpose**: Help newcomers get started. Learning by doing.

| Document | Description | Time |
|----------|-------------|------|
| [Onboarding Guide](./ONBOARDING.md) | Complete developer setup from zero to first PR | 30 min |
| [First Feature Tutorial](./tutorials/first-feature.md) | Step-by-step: Add a new product filter | 45 min |
| [MVVM Deep Dive](./tutorials/mvvm-pattern.md) | Understanding the MVVM architecture in practice | 20 min |
| [Testing Tutorial](./tutorials/testing.md) | Write your first unit, widget, and integration test | 30 min |

---

## How-to Guides (Problem-Oriented)

> **Purpose**: Solve specific problems. Recipe-style instructions.

### Flutter Development

| Guide | Description |
|-------|-------------|
| [Add a New Screen](./how-to/add-screen.md) | Create a new screen with ViewModel, routing, and tests |
| [Add a New Widget](./how-to/add-widget.md) | Create reusable widgets following design system |
| [Implement a New ViewModel](./how-to/add-viewmodel.md) | State management with Riverpod AsyncNotifier |
| [Add a New Service](./how-to/add-service.md) | Integrate external APIs or platform features |
| [Handle Errors Properly](./how-to/error-handling.md) | Using AppError and user-friendly messages |
| [Display Money Correctly](./how-to/money-handling.md) | Integer cents pattern throughout the stack |

### Backend Development (OrignaBase)

| Guide | Description |
|-------|-------------|
| [Add a New API Endpoint](./how-to/add-api-endpoint.md) | GraphQL resolvers and security rules |
| [Create a New Crate](./how-to/add-rust-crate.md) | Workspace structure and dependencies |
| [Add a Database Collection](./how-to/add-collection.md) | Schema, security rules, and SDK integration |

### Infrastructure

| Guide | Description |
|-------|-------------|
| [Deploy to VPS](./how-to/deploy.md) | Web frontend and backend deployment |
| [Run E2E Tests Locally](./how-to/e2e-local.md) | Playwright and agent-browser setup |
| [Debug Production Issues](./how-to/debug-production.md) | Logs, Sentry, and database queries |

---

## Reference (Information-Oriented)

> **Purpose**: Describe the machinery. Technical facts, looked up when needed.

### Architecture Reference

| Document | Description |
|----------|-------------|
| [System Architecture](./ARCHITECTURE.md) | Complete architecture overview with diagrams |
| [Repo Map](./REPO_MAP.md) | Directory structure and file inventory |
| [MVVM Architecture](./ARCHITECTURE_PATTERNS.md) | Model-View-ViewModel implementation details |
| [Data Flow Diagrams](./ARCHITECTURE.md#data-flow) | Checkout, auth, and order lifecycle flows |

### API Reference

| Document | Description |
|----------|-------------|
| [Flutter ViewModels API](./FLUTTER_VIEWMODELS_API.md) | All ViewModel classes and their responsibilities |
| [Flutter Services API](./FLUTTER_SERVICES_API.md) | Service layer interfaces and implementations |
| [Flutter Widgets Reference](./FLUTTER_WIDGETS.md) | Widget library with usage examples |
| [Flutter Screens Reference](./FLUTTER_SCREENS.md) | Screen components and their routes |
| [Rust Handlers API](./RUST_HANDLERS_API.md) | Backend business logic handlers |
| [OrignaBase SDK API](./ORIGNABASE_SDK_API.md) | Flutter SDK for backend communication |
| [GraphQL Schema](./api-reference.md) | GraphQL types, queries, and mutations |
| [REST Endpoints](./rest-endpoints.md) | Non-GraphQL API endpoints |

### Core Utilities Reference

| Document | Description |
|----------|-------------|
| [Design Tokens](./reference/design-tokens.md) | Complete design system: colors, spacing, typography |
| [Schema Constants](./reference/schema-constants.md) | Database field names and collection names |
| [Error Codes](./ERROR_CODES.md) | All error codes and their meanings |
| [Business Rules](./reference/business-rules.md) | Platform fees, shipping thresholds, limits |

### Testing Reference

| Document | Description |
|----------|-------------|
| [Test Strategy](./testing/TEST_STRATEGY.md) | Test pyramid and coverage targets |
| [Unit Tests](./testing/unit-tests.md) | Unit test patterns and conventions |
| [Widget Tests](./testing/widget-tests.md) | Widget testing best practices |
| [Integration Tests](./testing/integration-tests.md) | Live tests against real backend |
| [E2E Tests](./testing/e2e-tests.md) | Playwright and agent-browser specs |

### Infrastructure Reference

| Document | Description |
|----------|-------------|
| [VPS Operations](./VPS_OPERATIONS.md) | Server setup, Docker, Caddy, monitoring |
| [Local Dev Guide](./LOCAL_DEV_GUIDE.md) | Emulator setup and local development |
| [Environment Config](./reference/env-config.md) | All environment variables and their purposes |
| [CI/CD Pipeline](./reference/ci-cd.md) | GitHub Actions workflows explained |

---

## Explanation (Understanding-Oriented)

> **Purpose**: Explain concepts. Why things are the way they are.

### Design Decisions

| Document | Description |
|----------|-------------|
| [Why MVVM?](./explanation/why-mvvm.md) | Architecture decision and trade-offs |
| [Why Integer Cents?](./explanation/why-integer-cents.md) | Money handling rationale |
| [Why Riverpod?](./explanation/why-riverpod.md) | State management choice explained |
| [Why OrignaBase?](./explanation/why-orignabase.md) | Backend architecture decision |
| [Why SurrealDB?](./explanation/why-surrealdb.md) | Database choice and trade-offs |

### Domain Concepts

| Document | Description |
|----------|-------------|
| [Order Lifecycle](./explanation/order-lifecycle.md) | Order states, transitions, and business rules |
| [Payment Flow](./explanation/payment-flow.md) | Stripe Checkout, webhooks, and idempotency |
| [Multi-Seller Orders](./explanation/multi-seller.md) | How orders spanning multiple sellers work |
| [Seller Payouts](./explanation/seller-payouts.md) | Platform fees, Connect, and payout timing |
| [Inventory Management](./explanation/inventory.md) | Stock tracking, reservations, and race conditions |

### Compliance & Legal

| Document | Description |
|----------|-------------|
| [CASL Compliance](./explanation/casl-compliance.md) | Canadian anti-spam law requirements |
| [PIPEDA Compliance](./explanation/pipeda-compliance.md) | Privacy law data handling |
| [Quebec Law 25](./explanation/quebec-law-25.md) | Province-specific privacy requirements |
| [Tax Calculation](./explanation/tax-calculation.md) | Canadian tax by province |

---

## Code Documentation Standards

### Inline Documentation

Every file, class, method, and property **must** have documentation comments explaining:

1. **What it does** (one sentence)
2. **Why it exists** (if not obvious)
3. **How to use it** (for public APIs)
4. **Edge cases** (for complex logic)

Example:

```dart
/// Compresses product images in parallel using Dart isolates.
///
/// Each image is validated (size, format), resized to max 2048px,
/// and encoded as JPEG at 85% quality. Failed compressions are
/// silently filtered out to prevent blocking the batch.
///
/// **Usage:**
/// ```dart
/// final compressed = await compressProductImages(imageModels);
/// if (compressed.isEmpty) {
///   // All images failed validation
/// }
/// ```
///
/// **Why isolates?** Image compression is CPU-intensive. Running
/// each compression in a separate isolate prevents UI jank on
/// low-end devices.
///
/// **Edge cases:**
/// - Empty input returns empty list (no error)
/// - Corrupted images are skipped, not retried
/// - Memory pressure may cause isolate spawn failures
Future<List<Uint8List>> compressProductImages(
  List<ImageModel> imageModels,
) async {
  // Implementation...
}
```

### File Headers

Every source file must start with a header explaining its purpose:

```dart
/// Product Detail Screen — Displays full product information.
///
/// Shows product images, price, description, reviews, and Q&A.
/// Handles add-to-cart, favorite toggle, and seller chat initiation.
///
/// **Architecture:** This screen is UI-only. All business logic
/// is in [ProductDetailViewModel]. Data comes from [ProductRepository].
///
/// **Related files:**
/// - [ProductDetailViewModel] — State management
/// - [ProductRepository] — Data fetching
/// - [product_card_screen.dart] — Grid/list display
///
/// **Routing:** `/product/:id` (GoRouter path)
library;

import 'package:flutter/material.dart';
// ...
```

### Module Documentation

Every module (directory with related files) must have a `README.md`:

```
lib/features/checkout/
├── README.md          # Module overview
├── checkout_screen.dart
├── checkout_viewmodel.dart
├── orignabase_checkout_provider.dart
└── widgets/
    ├── README.md      # Widgets overview
    ├── order_review_sheet.dart
    └── delivery_options_section.dart
```

---

## Contributing to Documentation

### When to Update Docs

| Trigger | Action |
|---------|--------|
| New feature | Add tutorial + how-to guide |
| API change | Update API reference |
| Architecture change | Update ARCHITECTURE.md |
| New pattern | Add explanation |
| Bug fix with non-obvious solution | Add inline comment |

### Documentation Style Guide

1. **Be concise** — No filler, no fluff
2. **Use examples** — Code snippets > abstract explanations
3. **Link, don't repeat** — Reference other docs instead of duplicating
4. **Update immediately** — Stale docs are worse than no docs
5. **Test your examples** — All code samples must compile and run

---

## Document Index

### By Last Updated

| Document | Updated | Status |
|----------|---------|--------|
| [ARCHITECTURE.md](./ARCHITECTURE.md) | 2026-03-24 | ✅ Current |
| [REPO_MAP.md](./REPO_MAP.md) | 2026-03-22 | ✅ Current |
| [README.md](../README.md) | 2026-03-20 | ✅ Current |
| [AGENTS.md](../AGENTS.md) | 2026-03-24 | ✅ Current |

### By Audience

| Audience | Documents |
|----------|-----------|
| New developers | Onboarding, Tutorials, First Feature |
| Feature developers | How-to Guides, API Reference, Architecture |
| Backend developers | Rust Handlers API, VPS Operations, OrignaBase docs |
| QA/Testing | Testing Reference, E2E Tests, Test Strategy |
| DevOps | VPS Operations, CI/CD, Environment Config |
| Product/Design | Design Tokens, Flutter Widgets, Architecture |

---

## Quick Reference Cards

### File Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Screen | `*_screen.dart` | `checkout_screen.dart` |
| ViewModel | `*_viewmodel.dart` | `checkout_viewmodel.dart` |
| Service | `*_service.dart` | `analytics_service.dart` |
| Repository | `*_repository.dart` | `product_repository.dart` |
| Widget | `*.dart` (descriptive) | `modern_button.dart` |
| Test | `*_test.dart` | `checkout_viewmodel_test.dart` |

### Import Order

```dart
// 1. Dart SDK
import 'dart:async';

// 2. Flutter SDK
import 'package:flutter/material.dart';

// 3. External packages
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 4. Project imports (package notation, NOT relative)
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/design_tokens.dart';
```

### Money Display Pattern

```dart
// ALWAYS use integer cents
final priceCents = 7500; // $75.00

// Display formatting
Text('\$${(priceCents / 100).toStringAsFixed(2)}') // "$75.00"

// NEVER use double for money
// ❌ double price = 75.00;
// ✅ int priceCents = 7500;
```

---

## External Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [SurrealDB Documentation](https://surrealdb.com/docs)
- [Stripe Documentation](https://stripe.com/docs)
- [Canadian Tax Rates](https://www.canada.ca/en/revenue-agency/services/tax/businesses/topics/gst-hst-businesses/charge-gst/collecting/calculating-rates.html)

---

*Last updated: 2026-03-25 | Maintained by: Development Team*
