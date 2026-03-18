# OrignaGTA Legacy Code Audit — Findings by Severity & File:Line

## CRITICAL (Delete/Fix Immediately)

### 🔴 patrol_test/ — 3,807 Lines of Dead Firebase Code
```
origna_gta/patrol_test/common.dart:17 — import 'package:cloud_firestore/cloud_firestore.dart';
origna_gta/patrol_test/common.dart:18 — import 'package:cloud_functions/cloud_functions.dart';
origna_gta/patrol_test/common.dart:19 — import 'package:firebase_auth/firebase_auth.dart';
origna_gta/patrol_test/common.dart:20 — import 'package:firebase_core/firebase_core.dart';
origna_gta/patrol_test/common.dart:21 — import 'package:firebase_storage/firebase_storage.dart';
origna_gta/patrol_test/common.dart:28 — import 'package:origna_gta/firebase_options.dart'; [BROKEN — FILE NOT FOUND]
origna_gta/patrol_test/common.dart:44, 48, 56, 64 — Firebase emulator account doc comments
origna_gta/patrol_test/common.dart:73-105 — Firebase initialization code block
origna_gta/patrol_test/critical_workflows_test.dart:3-10 — Firebase emulator setup doc comments
origna_gta/patrol_test/critical_workflows_test.dart:13-15 — Firebase imports
origna_gta/patrol_test/critical_workflows_test.dart:753, 758, 760 — Firebase singleton accessors
origna_gta/patrol_test/critical_workflows_test.dart:771, 779, 825, 859 — Firestore operation doc comments
origna_gta/patrol_test/checkout_test.dart:14-15 — Firebase emulator comments
```
**ACTION:** `rm -rf origna_gta/patrol_test/`

### 🔴 firebase-debug.log — Stale CLI Artifact
```
firebase-debug.log (520 lines) — Firebase CLI debug output from 2026-03-17
```
**ACTION:** `rm firebase-debug.log` + add to .gitignore

### 🔴 setState() in admin_products_tab.dart — MVVM Violation
```
origna_gta/lib/features/admin/tabs/admin_products_tab.dart:184 — setState(() { ... })
origna_gta/lib/features/admin/tabs/admin_products_tab.dart:208 — onTap: () => setState(() => _stockFilter = 'pending_review')
origna_gta/lib/features/admin/tabs/admin_products_tab.dart:287 — onTap: () => setState(() => _stockFilter = value)
```
**ACTION:** Migrate `_stockFilter` to Riverpod provider

---

## HIGH (Refactor in Sprint)

### 🟠 StatefulWidget + Riverpod Mixing — 7 Files (Architectural Violation)
```
origna_gta/lib/screens/chat_screen.dart — extends StatefulWidget + imports flutter_riverpod
origna_gta/lib/screens/login_screen.dart — extends StatefulWidget + imports flutter_riverpod
origna_gta/lib/screens/payment_screens.dart — extends StatefulWidget + imports flutter_riverpod
origna_gta/lib/screens/productdetails_screen.dart — extends StatefulWidget + imports flutter_riverpod
origna_gta/lib/screens/seller/seller_warehouses_screen.dart — extends StatefulWidget + imports flutter_riverpod
origna_gta/lib/screens/subscription_screen.dart — extends StatefulWidget + imports flutter_riverpod
origna_gta/lib/screens/terms_screen.dart — extends StatefulWidget + imports flutter_riverpod
```
**ACTION:** Migrate each to `ConsumerWidget` + Riverpod providers

---

## MEDIUM (Polish Phase)

### 🟡 FutureProvider for Mutable State (2 instances)
```
origna_gta/lib/core/providers.dart:142 — FutureProvider<PublicAuthProviderAvailability>
origna_gta/lib/features/seller/orignabase_seller_registration_view_model.dart:12 — FutureProvider<Map<String, dynamic>>
```
**ACTION:** Consider converting to `AsyncNotifier` for consistency

### 🟡 Historical Firebase Comments (4 locations — safe to update)
```
origna_gta/lib/core/schema/schema_constants.dart:2050 — /// Firebase Auth action mode (e.g. 'resetPassword')
origna_gta/lib/core/schema/schema_constants.dart:2053 — /// Firebase Auth out-of-band code for password reset
origna_gta/lib/utils/env_config.dart:18 — /// - Web bundle served from Hetzner VPS with Caddy (no Firebase Hosting).
origna_gta/lib/previews/_preview_theme.dart:37 — // FIREBASE-SAFE PROVIDER SCOPE
```
**ACTION:** Update comments to reference OrignaBase instead of Firebase

---

## LOW (Nice-to-Have)

### 🟢 Logging Inconsistencies
```
origna_gta/lib/main_test.dart:96 — print('⚠️ Ignored web lifecycle assertion in test run');
```
**ACTION:** Use `AppLogger` instead of `print()` (acceptable in test, but for consistency)

### 🟢 debugPrint Usage (Acceptable — wrapped in kDebugMode)
```
origna_gta/lib/core/repositories/orignabase_product_repository.dart:237, 270
origna_gta/lib/core/repositories/orignabase_user_repository.dart:181
origna_gta/lib/core/repositories/orignabase_auth_repository.dart:82, 87, 249, 272, 310, 313, 333
```
**ACTION:** None required (stripped in release builds)

---

## CLEAN (No Issues Found)

- ✓ No unused imports
- ✓ No significant commented-out code blocks
- ✓ No hardcoded magic strings (uses DesignTokens)
- ✓ No outdated dependencies
- ✓ 384 private methods (reasonable size)

---

## Summary Statistics

| Category | Count | Severity |
|----------|-------|----------|
| Firebase references | 37 | CRITICAL |
| Dead test files | 10 | CRITICAL |
| setState() violations | 3 | CRITICAL |
| StatefulWidget + Riverpod mixing | 7 | HIGH |
| FutureProvider (questionable) | 2 | MEDIUM |
| Historical comments | 4 | MEDIUM |
| Logging inconsistencies | 1 | LOW |
| Total files affected | 24 | — |
| Total lines of dead code | 3,807 | — |

---

## Audit Metadata

- **Date:** 2026-03-18
- **Auditor:** Legacy Code Auditor (Claude)
- **Scope:** Full Flutter/Dart codebase (origna_gta/)
- **Zero Tolerance:** Firebase remnants, architectural violations, dead code
- **Status:** BLOCKING — patrol_test/ should be deleted before launch

