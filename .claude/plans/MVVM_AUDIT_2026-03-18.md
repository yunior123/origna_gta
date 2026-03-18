# OrignaGTA MVVM Architecture Audit Report
Generated: 2026-03-18

---

## EXECUTIVE SUMMARY

**Total Violations Found: 127+**

| Category | Count | Severity |
|----------|-------|----------|
| Colors.* hardcoding | 52+ | HIGH |
| Color(0x...) hex literals | 30+ | MEDIUM |
| setState() in Screens | 42 | CRITICAL |
| StatefulWidget abuse | 6 | CRITICAL |
| Navigator.pushNamed (old API) | 8 | MEDIUM |
| GlobalKey in Services | 2 | LOW |
| Direct API calls from Screens | 0 | — |

---

## CRITICAL VIOLATIONS

### 1. setState() Usage in Screens (42 instances) - CRITICAL

**Root Cause:** Business logic state managed in StatefulWidgets instead of Riverpod providers.

#### seller/seller_warehouses_screen.dart
- Line 466: `setState(() => _saving = true);`
- Line 484: `setState(() => _saving = false);`
- Line 535: `setState(() => _selectedType = WarehouseTypeValues.warehouse);`
- Line 541: `setState(() => _selectedType = WarehouseTypeValues.personal);`
- Line 641: `setState(() => _isDefault = v);`

#### mfa_setup_screen.dart
- Line 414: `setState(() => _codesSavedChecked = val ?? false);`

#### seller_orders_screen.dart
- Line 645: Dialog builder with `setState`
- Line 678: `setState(() => selectedCarrier = value);`
- Line 761: Dialog builder with `setState`
- Line 812: `setState(() => selectedCarrier = value);`

#### subscription_success_screen.dart
- Line 187: `setState(() { ... });` (timeout state)
- Line 391: `setState(() => _timedOut = true);`
- Line 426: `setState(() => _timedOut = true);`

#### security_settings_screen.dart
- Line 39: `setState(() => _isLoadingSecurity = true);`
- Line 48: `setState(() { ... });` (toggle state)
- Line 56: `setState(() => _isLoadingSecurity = false);`
- Line 618: `setState(() { ... });` (complex state)

#### terms_screen.dart
- Line 204: `setState(() => _expanded.add(number));`
- Line 456: `setState(() { ... });` (expansion state)

#### seller_registration_screen.dart
- Line 195: `setState(() => _termsAccepted = value ?? false);`

#### payment_screens.dart
- Line 241: `setState(() => _timedOut = true);`

#### orders_screen.dart
- Line 200: `setState(() => _selectedFilter = filter);` (filter state)

#### profile_screen.dart
- Line 1009: `setState(() {});` (empty rebuild)
- Line 1218: `setState(() => _isChecking = true);`
- Line 1246: `setState(() => _isChecking = false);`
- Line 1251: `setState(() => _isResending = true);`
- Line 1272: `setState(() => _isResending = false);`

#### productaddvideo_screen.dart
- Line 130: `setState(() => _isInitializing = false);`
- Line 135: `setState(() { ... });` (video state)
- Line 160: `setState(() => _isInitializing = false);`

#### editproduct_screen.dart
- Line 329: `setState(() => _lowStockAlertEnabled = v);`
- Line 375: `setState(() => _categoryController.text = v ?? '');`

#### common_screens.dart
- Line 480: `setState(() => _isChecking = true);`
- Line 512: `setState(() => _isChecking = false);`
- Line 517: `setState(() => _isResending = true);`
- Line 536: `setState(() => _isResending = false);`

#### login_screen.dart
- Line 1004: Dialog builder with `setState`
- Line 1070: `setState(() => isSending = true);`
- Line 1096: `setState(() => isSending = false);`

#### productaddimages_screen.dart
- Line 129: `setState(() { ... });` (image upload)
- Line 151: `setState(() => _imageModels.removeAt(index));`
- Line 209: `setState(() => _imageModels = List<ImageModel>.from(...));`
- Line 261: `setState(() {});` (force rebuild)

#### authwrapper_screen.dart
- Line 80: `setState(() => _hasScrolledToBottom = true);`
- Line 86: `setState(() => _accepting = true);`
- Line 98: `setState(() => _accepting = false);`

#### productdetails_screen.dart
- Line 1184: `setState(() => _isBuyingNow = true);`
- Line 1205: `setState(() => _isBuyingNow = false);`
- Line 1631: `setState(() => _expanded = !_expanded);`
- Line 2104: `setState(() => _showAll = true);`

---

### 2. Colors.* Hardcoding (52+ instances) - HIGH

**Issue:** Using Flutter's Material colors instead of DesignTokens.

#### editproduct_screen.dart
- Line 1069: `color: Colors.orange` → should use `DesignTokens.warning` or custom token

#### Admin Panel (Colors.white - inconsistent with DARK theme)
**File: features/admin/tabs/admin_products_tab.dart**
- Line 36: `color: Colors.white`
- Line 216: `color: isSelected ? DesignTokens.warning : Colors.white`
- Line 242: `? Colors.white`
- Line 259: `? Colors.white.withValues(alpha: 0.3)`
- Line 266: `color: Colors.white`
- Line 292: `color: isSelected ? DesignTokens.primary : Colors.white`
- Line 312: `color: isSelected ? Colors.white : DesignTokens.textSecondary`

**File: features/admin/tabs/admin_payment_providers_tab.dart**
- Line 71: `color: Colors.white`
- Line 415: `foregroundColor: Colors.white`
- Line 468: `foregroundColor: Colors.white`

**File: features/admin/tabs/admin_orders_tab.dart**
- Line 313: `color: Colors.white`
- Line 503: `color: isSelected ? DesignTokens.primary : Colors.white`
- Line 523: `color: isSelected ? Colors.white : DesignTokens.textSecondary`

**File: features/admin/tabs/admin_security_tab.dart**
- Line 70: `color: Colors.white`
- Line 167: `color: Colors.white`
- Line 189: `color: Colors.white`

**File: features/admin/tabs/admin_users_tab.dart**
- Line 53: `color: isDark ? DesignTokens.darkCard : Colors.white`
- Line 235: `color: isSelected ? Colors.white : DesignTokens.textSecondary`
- Line 290: `color: Colors.white`

**File: features/admin/tabs/admin_reviews_tab.dart**
- Line 35: `color: Colors.white`

**File: features/admin/tabs/admin_sellers_tab.dart**
- Line 225: `color: Colors.white`
- Line 574: `backgroundColor: Colors.transparent`
- Line 575: `foregroundColor: Colors.white`

**File: features/admin/admin_panel_screen.dart**
- Line 152: `backgroundColor: Colors.transparent`
- Line 153: `foregroundColor: Colors.white`
- Line 157: `indicatorColor: Colors.white`
- Line 160: `labelColor: Colors.white`
- Line 161: `unselectedLabelColor: Colors.white60`
- Line 222: `color: Colors.white.withValues(alpha: 0.15)`
- Line 225: `color: Colors.white`

---

### 3. Color(0x...) Hex Literals (30+ instances) - MEDIUM

#### ACCEPTABLE (Purpose-built for supplier branding):
**File: core/config/supplier_config.dart** (24 instances)
- Lines 37, 52, 67, 82, 97, 112, 127, 144, 159, 175, 191, 209, 224, 241, 256, 273, 288, 305, 321, 339, 355, 371, 389, 406, 423, 437
- Examples: `Color(0xFFE62E04)`, `Color(0xFFFF6A00)`, etc.
- These are supplier-specific brand colors and should remain as-is.

#### VIOLATIONS (Should use DesignTokens):

**File: features/admin/tabs/admin_products_tab.dart**
- Line 335: `color = const Color(0xFF22C55E);` → success green, use `DesignTokens.success`
- Line 340: `color = const Color(0xFFEF4444);` → error red, use `DesignTokens.error`
- Line 345: `color = const Color(0xFFF59E0B);` → warning amber, use `DesignTokens.warning`
- Line 618: `backgroundColor: const Color(0xFF22C55E);` → success green
- Line 812: `color: Color(0xFF6B7280)` → gray, use `DesignTokens.textSecondary`
- Line 833: `color: Color(0xFF6B7280)` → gray, use `DesignTokens.textSecondary`

**File: utils/utils.dart**
- Line 398: `Color(0xFFFFF3E0)` → light orange background
- Line 399: `Color(0xFFF57C00)` → orange icon color

**File: glassmorphism.dart**
- Line 202: `Color(0xFF000000)` → should use `DesignTokens.darkBackground`

**File: screens/terms_screen.dart**
- Line 626: `Color(0xFF4A4A5A)` → light mode text alternative
- Line 659: `Color(0xFF6A6A7A)` → light mode text alternative
- Line 676: `Color(0xFF4A4A5A)` → light mode text alternative

**File: screens/login_screen.dart** (Google Sign-In colors)
- Line 679: `Color(0xFF4285F4)` → Google blue
- Line 689: `Color(0xFFEA4335)` → Google red
- Line 699: `Color(0xFFFBBC05)` → Google yellow
- Line 709: `Color(0xFF34A853)` → Google green
- Line 724: `Color(0xFF4285F4)` → Google blue
- Line 732: `Color(0xFF4285F4)` → Google blue
- Line 787: `Color(0xFF131314)` → near-black for dark mode
- Line 791: `Color(0xFF5F6368)` → dark gray
- Line 792: `Color(0xFFDEDEDE)` → light gray
- Line 812: `Color(0xFF4285F4)` → Google blue
- Line 827: `Color(0xFF3C4043)` → dark gray

**File: screens/cartitem_screen.dart**
- Line 312: `Color(0xFF2A2A3E)` → dark surface variant

**File: screens/ordersuccess_screen.dart** (Confetti animation colors)
- Line 374: `Color(0xFFFFD700)` → gold
- Line 375: `Color(0xFFFF6B6B)` → red
- Line 376: `Color(0xFF5CE1E6)` → cyan
- Line 377: `Color(0xFF7B61FF)` → purple
- Line 378: `Color(0xFF4CAF50)` → green
- Line 379: `Color(0xFFFF9800)` → orange
- Line 380: `Color(0xFFE91E63)` → pink
- Line 381: `Color(0xFF00BCD4)` → light blue

**File: screens/seller_integration_screen.dart**
- Line 151: `Color(0xFFF4F4F8)` → light surface variant

**File: screens/productdetails_screen.dart**
- Line 1408: `Color(0xFF059669)` → success green for gradient

**File: screens/product_card_screen.dart** (Medal colors)
- Line 932: `Color(0xFFFFD700)`, `Color(0xFFFFA000)` → gold gradient
- Line 933: `Color(0xFFB0BEC5)`, `Color(0xFF78909C)` → silver gradient
- Line 934: `Color(0xFFCD7F32)`, `Color(0xFF8B4513)` → bronze gradient
- Line 979: `Color(0xFFFF3D00)` → red-orange

**File: screens/addproduct_screen.dart** (PayPal colors)
- Line 1243: `Color(0xFF003087)`, `Color(0xFFEF3340)` → PayPal blue/red
- Line 1265: `Color(0xFFEF3340)` → PayPal red
- Line 1267: `Color(0xFFEF3340)` → PayPal red
- Line 1271: `Color(0xFFEF3340)` → PayPal red

#### ACCEPTABLE (Preview/Demo Only):
**File: previews/_preview_theme.dart**
- Lines 154, 157, 246, 249, 305, 309, 311 — These are for widget preview displays only.

---

### 4. StatefulWidget Abuse (6 critical screens) - CRITICAL

Screens using StatefulWidget for business logic when they should use Riverpod:

1. **seller/seller_warehouses_screen.dart**
   - Local state: `_selectedType`, `_saving`, `_isDefault`
   - Should move to `warehousesViewModelProvider`

2. **subscription_success_screen.dart**
   - Local state: `_timedOut` (timeout tracking)
   - Should move to a Riverpod provider

3. **security_settings_screen.dart**
   - Local state: `_isLoadingSecurity`
   - Should use `securitySettingsViewModelProvider`

4. **productdetails_screen.dart**
   - Local state: `_isBuyingNow`, `_expanded`, `_showAll`
   - Should move to product details provider

5. **productaddimages_screen.dart**
   - Local state: `_imageModels` (image list management)
   - Should use Riverpod for image state

6. **login_screen.dart**
   - Uses dialog with local setState for form state
   - Should consider moving to provider-based form handling

---

## MEDIUM VIOLATIONS

### 5. Navigator.pushNamed (Old API) - 8 instances - MEDIUM

**Issue:** Using old Navigator API instead of GoRouter context.push().

**Violations:**
- origna_gta/lib/screens/cart_screen.dart:986 - `Navigator.pushNamed(context, ...)`
- origna_gta/lib/screens/subscription_success_screen.dart:198 - `Navigator.pushNamedAndRemoveUntil(...)`
- origna_gta/lib/screens/subscription_success_screen.dart:358 - `Navigator.pushNamedAndRemoveUntil(...)`
- origna_gta/lib/screens/login_screen.dart:87 - `Navigator.pushNamedAndRemoveUntil(...)`
- origna_gta/lib/screens/login_screen.dart:630 - `Navigator.pushNamedAndRemoveUntil(...)`
- origna_gta/lib/screens/chat_conversations_screen.dart:119 - `Navigator.pushNamed(...)`
- origna_gta/lib/screens/productdetails_screen.dart:1199 - `Navigator.pushNamed(...)`
- origna_gta/lib/screens/productdetails_screen.dart:2571 - `Navigator.pushNamed(...)`
- origna_gta/lib/screens/productdetails_screen.dart:2985 - `Navigator.pushNamed(...)`

**Fix:** Replace with `context.push(AppRoutes.path)` or `context.go(AppRoutes.path)`.

---

## LOW VIOLATIONS

### 6. GlobalKey Usage in Services - 2 instances - LOW

**Note:** These are architecturally non-ideal but accepted Flutter patterns for app-level concerns.

**File: services/session_timeout_service.dart**
- Line 19: `GlobalKey<NavigatorState>? _navigatorKey;`
- Line 55-87: Uses GlobalKey to show snackbar notifications
- **Rationale:** Singleton service managing session timeout needs to trigger UI updates without context injection
- **Better Alternative:** Could use Riverpod StateNotifierProvider for notifications

**File: services/orignabase_notification_service.dart**
- Line 23: `GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey`
- Line 26: `GlobalKey<NavigatorState> navigatorKey`
- **Rationale:** App-level notification service, GlobalKey is accepted pattern here
- **Note:** This is the only way to show notifications from completely detached services

---

## SUMMARY BY SEVERITY

### CRITICAL (Fix Immediately)
1. **42 setState() calls in Screens** → Migrate to Riverpod providers
2. **6 StatefulWidget screens with business logic** → Convert to ConsumerWidget + providers

### HIGH (Fix Soon)
3. **52+ Colors.* usage** → Replace with DesignTokens (especially admin screens)
4. **30+ Color(0x...) literals** → Create DesignTokens for status colors, gradients, special colors

### MEDIUM (Schedule Refactor)
5. **8 Navigator.pushNamed calls** → Migrate to GoRouter (context.push/go)

### LOW (Document & Accept)
6. **2 GlobalKey usages in Services** → Accept pattern, document in code comments

---

## RECOMMENDATIONS

### Priority 1: setState() Elimination (CRITICAL)
Refactor 6 major StatefulWidget screens:
1. Create `warehousing_viewmodel.dart` with warehouse state
2. Create `subscription_viewmodel.dart` for timeout tracking
3. Create `security_settings_viewmodel.dart`
4. Create `product_details_viewmodel.dart`
5. Create `image_upload_viewmodel.dart`
6. Convert dialog state management to provider-based patterns

### Priority 2: Color Token Management (HIGH)
1. Add status color tokens to DesignTokens:
   - `DesignTokens.success` (#22C55E)
   - `DesignTokens.error` (#EF4444) — already exists
   - `DesignTokens.warning` (#F59E0B) — already exists
   
2. Add animation colors to DesignTokens:
   - Medal colors (gold, silver, bronze)
   - Confetti palette
   
3. Add brand colors:
   - Google sign-in colors
   - PayPal colors
   
4. Replace all Colors.white in admin screens with appropriate tokens or DesignTokens.surface

### Priority 3: Router Migration (MEDIUM)
- Audit remaining Navigator.pushNamed calls
- Migrate to GoRouter `context.push(AppRoutes.path)` pattern
- Ensure all routes are defined in `lib/core/routes.dart`

### Priority 4: Service Architecture (LOW)
- Document GlobalKey usage as accepted pattern
- Add code comments explaining why GlobalKey is necessary
- Monitor for Riverpod notification provider as potential future refactor

