# Feature Spec: Full UI Design Audit & Fix

## Prompt
Audit and fix all design issues across every single view, widget, variant, and state in the entire app. 117 screen/widget files. Every layout, every state (loading/error/empty/data), all responsive breakpoints (mobile/tablet/desktop).

## Scope
All 117 files in `origna_gta/lib/screens/` including `parts/`, `widgets/`, and `seller/` subdirectories.

## Acceptance Criteria
- [ ] Zero hardcoded colors (all DesignTokens)
- [ ] Zero hardcoded route strings (all AppRoutes)
- [ ] Zero setState in screens (all Riverpod) — exceptions: animations, mascots
- [ ] Zero print()/debugPrint() (all AppLogger)
- [ ] Zero MediaQuery.of(context).size (all ResponsiveBreakpoints)
- [ ] All interactive elements have Semantics labels (btn-*, input-*, nav-*)
- [ ] All screens responsive at mobile(<768), tablet(768-1023), desktop(>=1024)
- [ ] All money displayed as integer cents formatted to 2 decimals
- [ ] All images use CachedNetworkImage with width/height/fit
- [ ] All lists use ListView.builder (not ListView(children:[]))
- [ ] RenderFlex overflow fixed (product card info section)
- [ ] Auth infinite loop fixed (ensureUserDocument)
- [ ] Login title "OrignaGta" → "Origna GTA"
- [ ] Hardcoded route '/' in reset_password_screen → AppRoutes.home
- [ ] Email verification responsive on desktop
- [ ] flutter analyze --no-fatal-infos passes
- [ ] flutter test --exclude-tags golden passes

## Batched Rounds

### Round 1: HIGH priority fixes + Tier 1 screens (revenue critical)
Files: auth loop fix, product_card_info_section, home_screen, productdetails_screen, cart/cartitem_screen, checkout_screen, login_screen, email_verification_screen, reset_password_screen
Focus: overflow fix, auth loop, responsive, Semantics, HIGH issues from UI_IMPROVEMENTS.md

### Round 2: Tier 2 screens (user journey) + parts
Files: profile_screen, profile_header, profile_settings_section, orders_screen, order_detail_screen, ordersuccess_screen, favorites_screen, notifications_screen, chat_screen, chat_conversations_screen, common_screens, error_screen, main_screen

### Round 3: Seller screens + admin
Files: seller_products_screen, seller_orders_screen, seller_registration_screen, seller_setup_screen, seller_integration_screen, seller_analytics_screen, seller_warehouses_screen, shipping_approval_screen, bulk_upload_screen, all seller parts/*

### Round 4: Product CRUD + detail widgets
Files: addproduct_screen + all addproduct parts, editproduct_screen + all editproduct parts, productaddimages_screen, productaddvideo_screen, product_card_screen, all product_detail widgets

### Round 5: Remaining screens + final sweep
Files: subscription_screen, subscription_cancel/success, mfa_setup/challenge, security_settings + parts, address_management, editaddress, terms, privacy_policy, payment_screens, return_request, authwrapper, admin_required_gate

## Constraints
- 8GB RAM: sequential only, kill zombies between rounds
- DesignTokens only for colors/spacing
- schema_constants for field names
- Package imports only (no relative ../)
- No magic strings
- Money in integer cents
