# OrignaGTA Legacy Code Audit — Action Checklist

## Pre-Launch Blocking Issues

- [ ] **DELETE patrol_test/ directory** (3,807 lines of Firebase dead code)
  ```bash
  rm -rf origna_gta/patrol_test/
  ```
  Files to delete:
  - [ ] origna_gta/patrol_test/common.dart
  - [ ] origna_gta/patrol_test/critical_workflows_test.dart
  - [ ] origna_gta/patrol_test/checkout_test.dart
  - [ ] origna_gta/patrol_test/bonus_workflows_test.dart
  - [ ] origna_gta/patrol_test/extended_workflows_test.dart
  - [ ] origna_gta/patrol_test/final_workflows_test.dart
  - [ ] origna_gta/patrol_test/more_new_workflows_test.dart
  - [ ] origna_gta/patrol_test/new_workflows_test.dart
  - [ ] origna_gta/patrol_test/premium_workflows_test.dart
  - [ ] origna_gta/patrol_test/test_bundle.dart

- [ ] **DELETE firebase-debug.log**
  ```bash
  rm firebase-debug.log
  ```

- [ ] **Add to .gitignore**
  ```bash
  echo "patrol_test/" >> .gitignore
  echo "firebase-debug.log" >> .gitignore
  ```

- [ ] **Run tests and analyze**
  ```bash
  flutter analyze --no-fatal-infos
  flutter test
  ```

- [ ] **Commit deletions**
  ```bash
  git add -A
  git commit -m "refactor: delete patrol_test Firebase-era dead code (replaced by e2e-agent-browser)"
  ```

---

## High Priority (Sprint 1)

- [ ] **Refactor admin_products_tab.dart**
  - [ ] Remove setState() usage (lines 184, 208, 287)
  - [ ] Create Riverpod provider for `_stockFilter`
  - [ ] Convert StatefulWidget to ConsumerWidget
  - [ ] Test: ensure stock filter still works
  - File: `origna_gta/lib/features/admin/tabs/admin_products_tab.dart`

- [ ] **Refactor 7 StatefulWidget + Riverpod mixing files** (convert to ConsumerWidget)
  - [ ] `lib/screens/chat_screen.dart`
  - [ ] `lib/screens/login_screen.dart`
  - [ ] `lib/screens/payment_screens.dart`
  - [ ] `lib/screens/productdetails_screen.dart`
  - [ ] `lib/screens/seller/seller_warehouses_screen.dart`
  - [ ] `lib/screens/subscription_screen.dart`
  - [ ] `lib/screens/terms_screen.dart`
  
  For each file:
  - [ ] Change `StatefulWidget` → `ConsumerWidget`
  - [ ] Change `State<X>` → remove (use ref directly)
  - [ ] Move local state to Riverpod providers
  - [ ] Remove `setState()` calls
  - [ ] Test: ensure all functionality still works

---

## Medium Priority (Sprint 2)

- [ ] **Convert FutureProvider to AsyncNotifier** (2 instances)
  - [ ] `lib/core/providers.dart:142` — PublicAuthProviderAvailability
    ```dart
    // BEFORE:
    final refreshSellerStatusProvider = FutureProvider<SellerAccountStatus>((ref) async { ... });
    
    // AFTER:
    class SellerStatusNotifier extends AsyncNotifier<SellerAccountStatus> {
      @override
      Future<SellerAccountStatus> build() async { ... }
    }
    final sellerStatusProvider = AsyncNotifierProvider<SellerStatusNotifier, SellerAccountStatus>(
      SellerStatusNotifier.new,
    );
    ```
  - [ ] `lib/features/seller/orignabase_seller_registration_view_model.dart:12`
    
  For each:
  - [ ] Create AsyncNotifier class
  - [ ] Convert FutureProvider to AsyncNotifierProvider
  - [ ] Test: ensure data fetching still works

- [ ] **Update historical Firebase comments** (4 locations)
  - [ ] `lib/core/schema/schema_constants.dart:2050` — Update to reference OrignaBase
  - [ ] `lib/core/schema/schema_constants.dart:2053` — Update to reference OrignaBase
  - [ ] `lib/utils/env_config.dart:18` — Remove "no Firebase Hosting" reference
  - [ ] `lib/previews/_preview_theme.dart:37` — Update comment for clarity

---

## Low Priority (Polish)

- [ ] **Standardize logging**
  - [ ] Replace `print()` in `lib/main_test.dart:96` with `AppLogger` (or mark as acceptable test-only)
  - [ ] No action needed for `debugPrint()` (already stripped in release)

- [ ] **Run full test suite**
  ```bash
  flutter analyze --no-fatal-infos && flutter test
  ```

- [ ] **Code review**
  - [ ] Verify no Firebase references remain in lib/ code
  - [ ] Verify all StatefulWidgets are now ConsumerWidgets
  - [ ] Verify setState() is completely removed

---

## Verification Checklist (Final)

```bash
# Verify patrol_test/ is deleted
test ! -d origna_gta/patrol_test/ && echo "✓ patrol_test/ deleted"

# Verify firebase-debug.log is deleted
test ! -f firebase-debug.log && echo "✓ firebase-debug.log deleted"

# Verify no Firebase imports remain in lib/
! grep -r "import.*firebase" origna_gta/lib --include="*.dart" && echo "✓ No Firebase imports in lib/"

# Verify no setState() in StatefulWidgets
! grep -r "setState(" origna_gta/lib --include="*.dart" && echo "✓ No setState() in lib/"

# Run tests
flutter analyze --no-fatal-infos && echo "✓ Static analysis passed"
flutter test && echo "✓ Unit tests passed"
```

---

## Reporting

Once completed, update:
1. **Memory file:** `~/.claude/projects/-Users-yuniorrodriguezosorio-Documents-GitHub-origna-gta/memory/MEMORY.md`
2. **State file:** `STATE.md` in repo root
3. **Git history:** Commits with clear messages

---

## Timeline Estimate

| Phase | Files | Time | Priority |
|-------|-------|------|----------|
| Pre-launch | patrol_test/, firebase-debug.log | 30 min | CRITICAL |
| Sprint 1 | admin_products_tab.dart + 7 screens | 8–12 hrs | HIGH |
| Sprint 2 | FutureProvider → AsyncNotifier + comments | 4–6 hrs | MEDIUM |
| Polish | Logging + final tests | 2–3 hrs | LOW |
| **Total** | **24 files** | **~15–21 hrs** | — |

---

## Sign-Off

- [ ] All CRITICAL items completed and committed
- [ ] All HIGH items completed and tested
- [ ] MEDIUM items scheduled (optional for launch)
- [ ] LOW items noted for future cleanup
- [ ] Audit report updated with resolution status
