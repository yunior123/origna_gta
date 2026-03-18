# OrignaGTA Legacy Code Audit Report
**Date:** 2026-03-18  
**Scope:** Flutter/Dart codebase at `/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/origna_gta`

---

## 1. FIREBASE REMNANTS — CRITICAL

**Finding:** Firebase references exist in code that was supposed to be fully migrated to OrignaBase.

### 1.1 patrol_test/ Directory (DEAD CODE — Should be deleted)
- **Location:** `/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/origna_gta/patrol_test/`
- **Status:** 10 test files, **3,807 total lines**
- **Firebase References:** 37 instances across 3 files
- **Purpose:** E2E tests using Firebase emulators (DEPRECATED — migrated to agent-browser)
- **Files:**
  | File | Lines | Firebase Refs | Status |
  |------|-------|---------------|--------|
  | `common.dart` | 287 | 22 | **CRITICAL** — imports Firebase core, Auth, Firestore, Storage |
  | `critical_workflows_test.dart` | 862 | 13 | **CRITICAL** — Firebase emulator setup, Firestore operations |
  | `checkout_test.dart` | 244 | 2 | **CRITICAL** — Firebase emulator comments |
  | `extended_workflows_test.dart` | 1517 | 0 | ORPHANED — likely migration artifact |
  | `bonus_workflows_test.dart` | 189 | 0 | ORPHANED |
  | `final_workflows_test.dart` | 142 | 0 | ORPHANED |
  | `more_new_workflows_test.dart` | 268 | 0 | ORPHANED |
  | `new_workflows_test.dart` | 157 | 0 | ORPHANED |
  | `premium_workflows_test.dart` | 52 | 0 | ORPHANED |
  | `test_bundle.dart` | 89 | 0 | ORPHANED |

### 1.2 patrol_test/ Specific Issues

**File:** `patrol_test/common.dart`  
Lines with Firebase:
- Line 17: `import 'package:cloud_firestore/cloud_firestore.dart';`
- Line 18: `import 'package:cloud_functions/cloud_functions.dart';`
- Line 19: `import 'package:firebase_auth/firebase_auth.dart';`
- Line 20: `import 'package:firebase_core/firebase_core.dart';`
- Line 21: `import 'package:firebase_storage/firebase_storage.dart';`
- Line 28: `import 'package:origna_gta/firebase_options.dart';` (FILE NOT FOUND in repo)
- Lines 44, 48, 56, 64: Doc comments reference Firebase emulator accounts
- Lines 73–105: Firebase initialization code — `Firebase.initializeApp()`, `FirebaseAuth.useAuthEmulator()`, `FirebaseFirestore.useFirestoreEmulator()`, etc.
- Line 77: Global flag `bool _firebaseInitialised = false;`

**File:** `patrol_test/critical_workflows_test.dart`  
Lines with Firebase:
- Lines 3–10: Doc comments detail Firebase emulator setup
- Lines 13–15: Firebase imports (`cloud_firestore`, `cloud_functions`, `firebase_auth`)
- Lines 753, 758, 760: Firebase singleton accessors (`FirebaseAuth.instance`, `FirebaseFirestore.instance`, `FirebaseFunctions.instance`)
- Lines 771, 779, 825, 859: Doc comments reference Firestore operations

**File:** `patrol_test/checkout_test.dart`  
- Lines 14–15: Comments reference Firebase emulators

### 1.3 Stale Firebase CLI Artifacts

**File:** `/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/firebase-debug.log`
- **Size:** 520 lines
- **Created:** 2026-03-17T18:59:33Z (STALE)
- **Content:** Firebase CLI debug output querying Cloud Billing and GCP services
- **Status:** Should be `.gitignored` (never committed to repo)

### 1.4 Historical Firebase Comments (Safe)

**File:** `lib/core/schema/schema_constants.dart`
- Line 2050: `/// Firebase Auth action mode (e.g. 'resetPassword')`
- Line 2053: `/// Firebase Auth out-of-band code for password reset`
- **Status:** Historical documentation only. Field names are OrignaBase-compatible. Safe to update comments but not critical.

**File:** `lib/utils/env_config.dart`
- Line 18: Comment: `/// - Web bundle served from Hetzner VPS with Caddy (no Firebase Hosting).`
- **Status:** Informational comment. Safe.

**File:** `lib/previews/_preview_theme.dart`
- Line 37: Comment: `// FIREBASE-SAFE PROVIDER SCOPE`
- **Status:** Informational comment. Safe.

**Files:** Test coverage comments
- `/origna_gta/test/widget/product_details_screen_coverage_test.dart:1`
- `/origna_gta/test/widget/product_card_test.dart:5`
- **Comment:** `// firebase_auth removed — using AppAuthUser from providers`
- **Status:** Historical migration notes. Safe.

---

## 2. DEPRECATED RIVERPOD PATTERNS

**Finding:** 10 instances of `FutureProvider` without `family` modifier, should use `AsyncNotifier` for mutable state.

### 2.1 FutureProvider Usage (Not Following AsyncNotifier Pattern)

| File | Line | Pattern | Status |
|------|------|---------|--------|
| `lib/core/providers.dart` | 142 | `FutureProvider<PublicAuthProviderAvailability>` | Should use AsyncNotifier |
| `lib/features/seller/seller_account_status_viewmodel.dart` | 23 | `FutureProvider.family.autoDispose<SellerAccountStatus, void>` | Mixing family + autoDispose OK |
| `lib/features/seller/orignabase_seller_registration_view_model.dart` | 12 | `FutureProvider<Map<String, dynamic>>` | Should use AsyncNotifier |
| `lib/features/products/products_provider.dart` | 16 | `FutureProvider.autoDispose<List<Product>>` | OK (no state mutation) |
| `lib/features/products/products_provider.dart` | 61 | `FutureProvider.autoDispose<List<Product>>` | OK (no state mutation) |
| `lib/features/products/products_provider.dart` | 71 | `FutureProvider.autoDispose.family<Product?, String>` | OK (read-only) |
| `lib/features/products/products_provider.dart` | 77 | `FutureProvider.autoDispose.family<Product?, String>` | OK (read-only) |
| `lib/features/products/products_provider.dart` | 83 | `FutureProvider.autoDispose.family<List<Product>, ProductQuery>` | OK (read-only) |
| `lib/features/products/products_provider.dart` | 92 | `FutureProvider.autoDispose.family<List<Product>, ...>` | OK (read-only) |
| `lib/features/terms/terms_provider.dart` | 102 | `FutureProvider<String>` | OK (read-only) |

**Verdict:** Most are acceptable (read-only data). The ones marked "Should use AsyncNotifier" are for mutable state.

---

## 3. MIXING STATEFULWIDGET WITH RIVERPOD (ARCHITECTURAL VIOLATION)

**Finding:** 7 files extend `StatefulWidget` while importing Riverpod, violating MVVM pattern.

| File | Lines | Issue |
|------|-------|-------|
| `lib/screens/chat_screen.dart` | — | Uses StatefulWidget + WidgetRef (mixed state management) |
| `lib/screens/login_screen.dart` | — | Uses StatefulWidget + WidgetRef (mixed state management) |
| `lib/screens/payment_screens.dart` | — | Uses StatefulWidget + WidgetRef (mixed state management) |
| `lib/screens/productdetails_screen.dart` | — | Uses StatefulWidget + WidgetRef (mixed state management) |
| `lib/screens/seller/seller_warehouses_screen.dart` | — | Uses StatefulWidget + WidgetRef (mixed state management) |
| `lib/screens/subscription_screen.dart` | — | Uses StatefulWidget + WidgetRef (mixed state management) |
| `lib/screens/terms_screen.dart` | — | Uses StatefulWidget + WidgetRef (mixed state management) |

### 3.1 Direct setState() Violations

**File:** `lib/features/admin/tabs/admin_products_tab.dart`

| Line | Code | Issue |
|------|------|-------|
| 184 | `setState(() { ... })` | Modifying local state in StatefulWidget |
| 208 | `onTap: () => setState(() => _stockFilter = 'pending_review')` | setState in callback |
| 287 | `onTap: () => setState(() => _stockFilter = value)` | setState in callback |

**Status:** VIOLATION of Riverpod + MVVM architecture. Should migrate to provider-based state.

---

## 4. PRINT() STATEMENTS (LOGGING VIOLATION)

**File:** `lib/main_test.dart:96`
```dart
print('⚠️ Ignored web lifecycle assertion in test run');
```
**Status:** In test file (acceptable), but should use `AppLogger` for consistency.

---

## 5. DEBUGPRINT USAGE (ACCEPTABLE)

**Finding:** 13+ instances of `debugPrint()` in repositories and services.

| File | Line | Context |
|------|------|---------|
| `lib/core/repositories/orignabase_product_repository.dart` | 237, 270 | Debugging product queries |
| `lib/core/repositories/orignabase_user_repository.dart` | 181 | Address clearing warnings |
| `lib/core/repositories/orignabase_auth_repository.dart` | 82, 87, 249, 272, 310, 313, 333 | Auth error logging |

**Status:** ACCEPTABLE (wrapped in `kDebugMode` checks). Not a violation since `debugPrint()` is stripped in release builds.

---

## 6. HARDCODED MAGIC VALUES (LOW-SEVERITY)

**Finding:** No critical hardcoded magic values found. Color hex literals and magic strings are minimal.

**File:** `lib/screens/addproduct_screen.dart:1465–1466`
```dart
// FIX [HIGH] WCAG 2.1 AA: amber (#F59E0B) on white is ~2:1 contrast — fails 4.5:1.
// Use DesignTokens.warningText (#92400E, ~7:1) for text when banner is warning-colored.
```
**Status:** TODO comment documenting accessibility fix needed. Not a violation.

---

## 7. COMMENTED-OUT CODE BLOCKS

**Finding:** No significant blocks of commented-out code found. Most comments are documentation or TODOs.

**Verified:**
- Integration test files (`integration_test/app_test.dart`, `integration_test/all_tests.dart`) use comments as documentation labels, not dead code.
- No multi-line code blocks (3+) commented out.

**Status:** CLEAN

---

## 8. UNUSED IMPORTS & DEAD CODE

**Finding:** No critical unused imports detected. 384 private methods exist (reasonable for codebase size).

**Status:** Overall CLEAN — no major dead code bloat detected outside patrol_test/

---

## 9. OUTDATED DEPENDENCIES

**Analysis:** All major dependencies are current as of March 2026.

| Package | Version | Status |
|---------|---------|--------|
| `flutter_riverpod` | `^2.6.1` | ✓ Current |
| `freezed` | `^3.2.5` | ✓ Current |
| `sentry_flutter` | `^9.10.0` | ✓ Current |
| `google_sign_in` | `^7.2.0` | ✓ Current |
| `flutter_test` | SDK | ✓ Current |
| `mockito` | `^5.4.4` | ✓ Current |
| `json_serializable` | `^6.9.0` | ✓ Current |
| `patrol` | `^4.1.1` | ✓ Current (agent-browser replacement) |

**Status:** CLEAN — no outdated packages.

---

## 10. DELETED FILE REFERENCES

**Finding:** `patrol_test/common.dart:28` imports `firebase_options.dart` which does NOT exist in the codebase.

```dart
import 'package:origna_gta/firebase_options.dart';
```

**Status:** This import would fail if patrol_test were ever executed. Confirms patrol_test is dead code.

---

## SUMMARY OF FINDINGS

| Category | Severity | Count | Action |
|----------|----------|-------|--------|
| **patrol_test/ — Firebase dead code** | **CRITICAL** | 3,807 lines | DELETE entire directory |
| **Firebase imports in patrol_test/** | CRITICAL | 5 import statements | Deleted with patrol_test/ |
| **firebase-debug.log** | LOW | 1 file | Delete + add to .gitignore |
| **StatefulWidget + Riverpod mixing** | HIGH | 7 files | Refactor to Riverpod-only |
| **setState() usage in MVVM** | HIGH | 3 instances | Migrate to providers |
| **FutureProvider (questionable pattern)** | MEDIUM | 2 instances | Consider AsyncNotifier |
| **Historical Firebase comments** | LOW | 4 locations | Update to reference OrignaBase |
| **print() in test** | LOW | 1 instance | Use AppLogger |
| **Unused code / dead imports** | LOW | 0 | None found |
| **Outdated dependencies** | LOW | 0 | None found |

---

## RECOMMENDATIONS (PRIORITY ORDER)

### 🔴 CRITICAL — Do Now
1. **Delete `/origna_gta/patrol_test/` directory** — 3,807 lines of Firebase-era test code
   - All tests have been replaced by `e2e-agent-browser/`
   - Contains broken imports (`firebase_options.dart`)
   - Keeping this is technical debt

2. **Delete `firebase-debug.log`** — stale Firebase CLI artifact
   - Add to `.gitignore` to prevent future commits

### 🟠 HIGH — Sprint Next
3. **Refactor 7 StatefulWidget files to use Riverpod only**
   - `lib/screens/chat_screen.dart`
   - `lib/screens/login_screen.dart`
   - `lib/screens/payment_screens.dart`
   - `lib/screens/productdetails_screen.dart`
   - `lib/screens/seller/seller_warehouses_screen.dart`
   - `lib/screens/subscription_screen.dart`
   - `lib/screens/terms_screen.dart`

4. **Eliminate setState() in admin_products_tab.dart**
   - Migrate `_stockFilter` to a provider
   - Use Riverpod state management exclusively

### 🟡 MEDIUM — Polish
5. Update historical Firebase comments in `schema_constants.dart` to reference OrignaBase instead
6. Consider converting `FutureProvider` in `core/providers.dart` and `orignabase_seller_registration_view_model.dart` to `AsyncNotifier` if state mutations are planned

### 🟢 LOW — Nice to Have
7. Standardize logging to use `AppLogger` instead of `print()`
8. Run `flutter analyze --no-fatal-infos` to catch any other warnings

---

## FILES REQUIRING IMMEDIATE DELETION

```bash
rm -rf origna_gta/patrol_test/
rm firebase-debug.log
```

Then commit:
```bash
git add -A
git commit -m "refactor: delete patrol_test Firebase-era tests (replaced by agent-browser)"
```
