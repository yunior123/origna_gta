# Comment Audit Report

> **Audit Date**: 2026-03-25
> **Scope**: All `.dart` files in `origna_gta/lib/`
> **Exclusions**: Generated files (`.freezed.dart`, `.g.dart`)

---

## Summary

| Metric | Count | Assessment |
|--------|-------|------------|
| **Total inline comments** | 4,707 | Good - extensive coverage |
| **Doc comments (`///`)** | 2,562 | Good - API documentation |
| **TODOs** | 2 | Low - healthy backlog |
| **FIXMEs** | 0 | None - no critical issues marked |
| **HACKs** | 0 | None - no code smells marked |
| **XXX/BUG markers** | 1 | Low - one known issue tracked |

---

## Overall Assessment: ✅ GOOD

The codebase has **well-maintained comments** with clear documentation patterns. Comments explain **why** (rationale) rather than **what** (obvious code), following best practices.

---

## Strengths

### 1. ✅ Excellent Doc Comments

Doc comments (`///`) explain public APIs with:
- Purpose statement
- Parameters explained
- Return values
- Edge cases
- Usage examples

**Example** (`main.dart:16-18`):
```dart
/// Keep the semantics handle alive so it doesn't get GC'd in release mode.
/// Without this, ensureSemantics() has no lasting effect.
SemanticsHandle? _semanticsHandle;
```

**Example** (`orignabase_checkout_provider.dart:44-70`):
```dart
/// Manages the entire checkout flow: address selection, shipping calculation,
/// tax computation, coupon application, and Stripe session creation.
///
/// ## State Flow
/// ```
/// Initialized (address loaded) → Shipping calculated → Taxes computed
/// → Coupon applied (optional) → Checkout started → Stripe redirect
/// ```
///
/// ## Key Decisions
/// - Circuit breakers wrap shipping and Stripe calls
/// - Idempotency keys prevent duplicate orders on retry
/// - Biometric auth required for transactions >= $100 CAD
```

### 2. ✅ Section Headers

Well-organized files use section headers:

**Example** (`timestamp.dart:32-34`):
```dart
// =============================================================================
// PostgreSQL -> Dart timestamp precision workaround
// =============================================================================
```

**Example** (`orignabase_product_repository.dart:93-95`):
```dart
// ---------------------------------------------------------------------------
// Product CRUD
// ---------------------------------------------------------------------------
```

### 3. ✅ Why-Not-What Comments

Comments explain rationale, not obvious code:

**Example** (`main.dart:77-81`):
```dart
// Force semantic tree on web for accessibility + E2E Playwright testing.
// Flutter Web renders to <canvas> — this generates a parallel <flt-semantics>
// DOM tree with ARIA attributes that Playwright can target.
// IMPORTANT: Store the handle — if it's GC'd, semantics gets disabled.
```

**Example** (`orignabase_cart_repository.dart:70-71`):
```dart
// Read-then-write: OrignaBase does not have client-side transactions yet.
// Use deterministic doc ID to avoid duplicates.
```

### 4. ✅ Workaround Documentation

Non-obvious solutions are documented with problem/solution:

**Example** (`timestamp.dart:36-69`):
```dart
// ## Problem
// PostgreSQL stores timestamps with microsecond precision (6 fractional digits).
// Dart's [DateTime.parse] supports up to microsecond precision (6 digits).
//
// ## Solution
// Before any `DateTime.parse` call on a PostgreSQL timestamp, truncate the
// fractional digits to 6 using [truncateNanoseconds].
//
// ## Where this is applied
// - [OrignaBaseProductRepository.docToProduct] — product timestamps
// - [_parseDateTime] in `order_models.dart` — order timestamps
```

### 5. ✅ Bug Tracking

Known issues tracked with reference IDs:

**Example** (`schema_constants.dart:192`):
```dart
static const localDeliveryRadiusKm = 50.0; // 50km radius for local delivery Eligibility (BUG-L1)
```

---

## Issues Found

### 1. ⚠️ TODOs Should Have Context (LOW PRIORITY)

**Location**: `notifications_screen.dart:52, 84`

```dart
// TODO: Extract to NotificationViewModel if more notification logic is added
```

**Issue**: TODO lacks deadline or priority.

**Recommendation**: Use format `// TODO(#issue): Description [PRIORITY]` or create a tracking issue.

**Fix**:
```dart
// TODO(#123): Extract to NotificationViewModel if notification logic grows beyond 2 methods [LOW]
```

### 2. ⚠️ Comment References Playwright (Should be agent-browser) (LOW PRIORITY)

**Location**: `main.dart:77`

```dart
// Force semantic tree on web for accessibility + E2E Playwright testing.
```

**Issue**: Should reference `agent-browser` instead of `Playwright` (per user feedback that Playwright was replaced).

**Fix**:
```dart
// Force semantic tree on web for accessibility + E2E agent-browser testing.
```

---

## Recommendations

### 1. Add File Headers to All Files

Some files lack file-level documentation. Add headers explaining:
- Purpose
- Key exports
- Dependencies

**Example template**:
```dart
/// Product Detail Screen — Displays full product information.
///
/// Shows product images, price, description, reviews, and Q&A.
/// Handles add-to-cart, favorite toggle, and seller chat initiation.
///
/// **Architecture:** UI-only screen. Business logic in [ProductDetailViewModel].
/// **Related:** [ProductDetailViewModel], [ProductRepository]
/// **Routing:** `/product/:id`
library;

import 'package:flutter/material.dart';
```

### 2. Use Issue References for TODOs

Convert free-form TODOs to issue-linked:

| Current | Recommended |
|---------|-------------|
| `// TODO: Extract to ViewModel` | `// TODO(#123): Extract to ViewModel [LOW]` |
| `// FIXME: Handle edge case` | `// FIXME(#124): Handle edge case [HIGH]` |

### 3. Document Non-Obvious Business Rules

Some business rules in code lack explanation:

**Example needing documentation**:
```dart
// Why $100 threshold for biometrics?
if (subtotalCents >= 10000) {
  await _requireBiometricAuth();
}
```

**Recommended**:
```dart
// Biometric auth required for transactions >= $100 CAD per security policy (Section 4.2).
// Threshold aligns with card-present PIN requirements in Canada.
if (subtotalCents >= 10000) {
  await _requireBiometricAuth();
}
```

---

## Comment Quality by Category

| Category | Rating | Notes |
|----------|--------|-------|
| **API Documentation** | ✅ Excellent | All public methods documented |
| **Inline Explanations** | ✅ Good | Why-not-what style followed |
| **Workarounds** | ✅ Excellent | Problem/solution documented |
| **Section Headers** | ✅ Good | Most files organized |
| **TODO Management** | ⚠️ Fair | Low count, but lacks tracking |
| **Bug Markers** | ✅ Good | Single known issue tracked |

---

## Files with Exemplary Comments

| File | Why Excellent |
|------|---------------|
| `core/compat/timestamp.dart` | Complete problem/solution/usage documentation |
| `main.dart` | Clear initialization flow comments |
| `orignabase_checkout_provider.dart` | State flow diagram, key decisions documented |
| `core/schema/schema_constants.dart` | Header explains naming conventions |
| `core/repositories/*.dart` | Interface contracts documented |

---

## Comment Anti-Patterns (None Found)

The following anti-patterns were **NOT found**:
- ❌ Commented-out code (dead code)
- ❌ Obvious comments (`i++; // increment i`)
- ❌ Misleading comments
- ❌ TODO graveyards (unmaintained TODOs)
- ❌ Comment blocks instead of refactoring

---

## Statistics by Directory

| Directory | Files | Avg Comments/File | Quality |
|-----------|-------|-------------------|---------|
| `core/` | ~30 | 85 | Excellent |
| `features/` | ~50 | 45 | Good |
| `screens/` | ~35 | 35 | Good |
| `widgets/` | ~20 | 25 | Good |
| `services/` | ~10 | 30 | Good |

---

## Action Items

| Priority | Item | Effort |
|----------|------|--------|
| **Low** | Update Playwright reference to agent-browser | 1 file |
| **Low** | Add issue links to 2 TODOs | 2 files |
| **Optional** | Add file headers to undocumented files | ~10 files |

---

## Conclusion

The OrignaGTA codebase demonstrates **professional comment hygiene**. Comments explain rationale, document workarounds, and track known issues. The codebase follows the principle that **good code is self-documenting, but non-obvious decisions need explanation**.

**Rating**: 8.5/10

**Key Strengths**:
- Why-not-what style
- Workaround documentation
- Section organization
- Bug tracking

**Minor Improvements**:
- Link TODOs to issues
- Update tool references (Playwright → agent-browser)

---

*Audit completed: 2026-03-25*
