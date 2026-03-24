# OrignaGTA Flutter Screens Documentation

This document provides comprehensive documentation of all Flutter screens in the `origna_gta/lib/screens/` directory.

**Auto-generated from code analysis**  
**Total Screens Documented:** 41

---

## Table of Contents

1. [Route Configuration Reference](#route-configuration-reference)
2. [Authentication Screens](#authentication-screens)
3. [Main App Shell](#main-app-shell)
4. [Home & Discovery](#home--discovery)
5. [Cart & Checkout](#cart--checkout)
6. [Orders](#orders)
7. [Profile & Settings](#profile--settings)
8. [Favorites](#favorites)
9. [Seller Dashboard](#seller-dashboard)
10. [Subscription](#subscription)
11. [Chat & Messaging](#chat--messaging)
12. [Legal & Common](#legal--common)

---

## Route Configuration Reference

Routes are defined in `origna_gta/lib/core/routes.dart` (lines 1-109).

| Route Name | Path | Screen |
|------------|------|--------|
| `home` | `/` | HomeScreen |
| `login` | `/login` | LoginScreen |
| `cart` | `/cart` | CartScreen |
| `profile` | `/profile` | ProfileScreen |
| `orders` | `/orders` | OrdersScreen |
| `orderDetail` | `/orders/detail` | OrderDetailScreen |
| `addProduct` | `/add-product` | AddProductScreen |
| `editProduct` | `/edit-product` | EditProductScreen |
| `productDetails` | `/product-details` | ProductDetailScreen |
| `addressManagement` | `/addresses` | AddressManagementScreen |
| `addEditAddress` | `/address/edit` | EditAddressScreen |
| `checkout` | `/checkout` | CheckoutScreen |
| `orderSuccess` | `/order-success` | OrderSuccessScreen |
| `shippingApproval` | `/shipping-approval` | ShippingApprovalScreen |
| `sellerRegistration` | `/seller/register` | SellerRegistrationScreen |
| `sellerOrders` | `/seller/orders` | SellerOrdersScreen |
| `sellerProducts` | `/seller/products` | SellerProductsScreen |
| `favorites` | `/favorites` | FavoritesScreen |
| `privacyPolicy` | `/privacy-policy` | PrivacyPolicyScreen |
| `termsOfService` | `/terms-of-service` | TermsOfServiceScreen |
| `subscription` | `/subscription` | SubscriptionScreen |
| `subscriptionSuccess` | `/subscription/success` | SubscriptionSuccessScreen |
| `subscriptionCancel` | `/subscription/cancel` | SubscriptionCancelScreen |
| `chat` | `/chat` | ChatScreen |
| `chatInbox` | `/chat/inbox` | ChatConversationsScreen |
| `notifications` | `/notifications` | NotificationsScreen |
| `mfaSetup` | `/mfa/setup` | MfaSetupScreen |
| `mfaChallenge` | `/mfa/challenge` | MfaChallengeScreen |
| `securitySettings` | `/security-settings` | SecuritySettingsScreen |
| `returnRequest` | `/orders/return-request` | ReturnRequestScreen |

---

## Authentication Screens

### 1. LoginScreen

**File:** `origna_gta/lib/screens/login_screen.dart`  
**Lines:** 1-309

**Route:** `/login` (AppRoutes.login)

**Description:**  
Login and registration screen that supports email/password authentication, Google sign-in, and Apple sign-in. Handles MFA challenge navigation when required.

**State Dependencies:**
- `loginViewModelProvider` - LoginState (isLogin, isLoading, obscurePassword, acceptedTerms, marketingOptIn)
- `googleAuthAvailabilityProvider` - Checks if Google auth is enabled

**Key Widgets:**
- LoginFormPanel (part/login_form_panel.dart)
- LoginGoogleButton (part/login_google_button.dart)
- ModernTextField, ModernButton

**Navigation:**
- **From:** HomeScreen (login button), AuthWrapper
- **To:** MfaChallengeScreen (on MFA required), HomeScreen (on success)
- **Dialogs:** Forgot password dialog

---

### 2. ResetPasswordScreen

**File:** `origna_gta/lib/screens/reset_password_screen.dart`  
**Lines:** 1-217

**Route:** Password reset via email link (route not in constants)

**Description:**  
Allows users to set a new password after clicking a reset link in their email. Validates password match and OOB code.

**State Dependencies:**
- `resetPasswordViewModelProvider(oobCode)` - ResetPasswordState (isVerifying, isSuccess, isLoading, errorMessage, userEmail)

**Key Widgets:**
- ModernTextField (password fields with visibility toggle)
- ModernButton

**Navigation:**
- **From:** Email link
- **To:** Home (on success)

---

### 3. EmailVerificationScreen

**File:** `origna_gta/lib/screens/email_verification_screen.dart`  
**Lines:** 1-339

**Description:**  
Shown when user needs to verify their email before accessing features. Displays verification instructions and resend button.

**State Dependencies:**
- `currentUserProvider` - UserModel
- `_evrsCheckingProvider` - Local loading state
- `_evrsResendingProvider` - Local resend state

**Key Widgets:**
- FadeSlideIn animations
- ModernButton (verify, resend)

**Navigation:**
- **From:** AuthWrapper (when email not verified)
- **To:** HomeScreen (on verification success)

---

### 4. MfaSetupScreen

**File:** `origna_gta/lib/screens/mfa_setup_screen.dart`  
**Lines:** 1-539

**Route:** `/mfa/setup` (AppRoutes.mfaSetup)

**Description:**  
Multi-step MFA setup flow: QR code scan -> verify TOTP code -> save backup codes. Uses `SensitiveContent` wrapper for security.

**State Dependencies:**
- `mfaViewModelProvider` - MfaState (currentStep, qrCodeBase64, manualKey, recoveryCodes, isLoading, errorMessage)

**Key Widgets:**
- QR Code display (Image.memory from base64)
- TextField for code entry
- CheckboxListTile for backup code confirmation

**Navigation:**
- **From:** SecuritySettingsScreen
- **To:** SecuritySettingsScreen (on completion with true result)

---

### 5. MfaChallengeScreen

**File:** `origna_gta/lib/screens/mfa_challenge_screen.dart`  
**Lines:** 1-314

**Route:** `/mfa/challenge` (AppRoutes.mfaChallenge)

**Description:**  
MFA challenge screen shown when a user with MFA enabled logs in. Accepts TOTP code or recovery code.

**State Dependencies:**
- `_mfaChallengeLoadingProvider` - Local loading state
- `_mfaChallengeRecoveryModeProvider` - Toggle between TOTP/recovery
- `_mfaChallengeAttemptsProvider` - Attempt counter (max 5)

**Key Widgets:**
- TextField for code entry
- FilledButton for submit

**Navigation:**
- **From:** LoginScreen (after MFA required)
- **To:** HomeScreen (on success), LoginScreen (on too many attempts)

---

## Main App Shell

### 6. AuthWrapperScreen

**File:** `origna_gta/lib/screens/authwrapper_screen.dart`  
**Lines:** 1-241

**Description:**  
Root authentication wrapper that gates app access. Checks email verification, terms acceptance, and suspended status.

**State Dependencies:**
- `authStateProvider` - AsyncValue<User?>
- `userProfileProvider` - User profile data
- `needsTermsUpdateProvider` - Terms version check

**Key Widgets:**
- _TermsUpdateGate - Forces terms acceptance
- EmailVerificationRequiredScreen
- MainScreen

**Navigation:**
- **From:** App entry point
- **To:** MainScreen, EmailVerificationRequiredScreen, _TermsUpdateGate

---

### 7. MainScreen

**File:** `Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/origna_gta/lib/screens/main_screen.dart`  
**Lines:** 1-72

**Description:**  
Main screen coordinator that loads user profile and displays HomeScreen. Includes 3-second timeout for profile loading.

**State Dependencies:**
- `_mainScreenTimedOutProvider` - Timeout state
- `userProfileProvider` - UserModel

**Key Widgets:**
- HomeScreen (with userModel parameter)

**Navigation:**
- **From:** AuthWrapper
- **To:** HomeScreen

---

## Home & Discovery

### 8. HomeScreen

**File:** `origna_gta/lib/screens/home_screen.dart`  
**Lines:** 1-616

**Route:** `/` (AppRoutes.home)

**Description:**  
Main product discovery screen with search bar, category filters, product grid, and recently viewed section. Features responsive layout with mascot animations.

**State Dependencies:**
- `homeViewModelProvider` - HomeViewModel (products, showSearchOverlay, recentSearches, searchSuggestions)
- `userProfileProvider` - User profile for seller/admin detection
- `mascotControllerProvider` - Animated mascot state
- `mooseControllerProvider` - Canadian moose mascot state

**Key Widgets:**
- CustomScrollView with SliverToBoxAdapter/SliverGrid
- _SearchBarWithOverlay
- _SortAndFilterRow
- _CategoryChips
- _SubcategoryChips
- ProductCard widgets
- ShopMascot, CanadianMoose

**Navigation:**
- **From:** MainScreen, Cart, Profile, Orders
- **To:** ProductDetailScreen, CartScreen, LoginScreen (add product)

---

### 9. ProductCardScreen

**File:** `origna_gta/lib/screens/product_card_screen.dart`  
**Lines:** 1-320

**Description:**  
Reusable product card widget for displaying products in grids/lists. Supports favorites, trending badges, and seller management actions.

**State Dependencies:**
- `favoritesProvider` - List of favorited product IDs
- `productActionsViewModelProvider` - Delete product actions

**Key Widgets:**
- _ProductCardImageSection
- _ProductCardInfoSection
- TrendingBadge
- IconButtons for edit/delete (owner/admin only)

**Navigation:**
- **From:** HomeScreen, FavoritesScreen
- **To:** ProductDetailScreen, EditProductScreen

---

### 10. ProductDetailScreen

**File:** `origna_gta/lib/screens/productdetails_screen.dart`  
**Lines:** 1-596

**Route:** `/product-details` (AppRoutes.productDetails)

**Description:**  
Comprehensive product detail view with image gallery, price, variants, reviews, Q&A, related products, and add-to-cart functionality.

**State Dependencies:**
- `productByIdProvider(productId)` - Product data
- `productDetailViewModelProvider` - Selected variant state
- `productRatingsProvider(productId)` - Reviews/ratings
- `userProfileProvider` - For seller detection

**Key Widgets:**
- ProductImageGallery
- _ProductInfoColumn
- ReviewsSection
- QASection
- SimilarProductsSection
- StickyBottomCTA

**Navigation:**
- **From:** HomeScreen, ProductCard, Favorites
- **To:** ChatScreen, CheckoutScreen

---

## Cart & Checkout

### 11. CartScreen

**File:** `origna_gta/lib/screens/cart_screen.dart`  
**Lines:** 1-273

**Route:** `/cart` (AppRoutes.cart)

**Description:**  
Shopping cart with item list, quantity controls, unavailable items warning, and checkout summary. Uses optimized Riverpod patterns with family providers.

**State Dependencies:**
- `cartItemsProvider` - Cart items with product IDs
- `currentUserProvider` - Auth state check
- `unavailableCartItemsProvider` - Unavailable items warning
- `checkoutStateProvider` - Checkout state

**Key Widgets:**
- _CartItemWidget (part/cart_item_widget.dart)
- _CartSummary (part/cart_summary_widgets.dart)
- FreeShippingBar, CartTotalDisplay

**Navigation:**
- **From:** HomeScreen, ProductDetailScreen
- **To:** CheckoutScreen, HomeScreen

---

### 12. CheckoutScreen

**File:** `origna_gta/lib/screens/checkout_screen.dart`  
**Lines:** 1-545

**Route:** `/checkout` (AppRoutes.checkout)

**Description:**  
Multi-step checkout flow: address selection -> delivery options -> payment -> confirmation. Features 3-step progress indicator and responsive 2-column layout.

**State Dependencies:**
- `userProfileProvider` - User address data
- `checkoutStateProvider` - Address, shipping, payment provider
- `checkoutSubtotalCentsProvider` - Subtotal calculation
- `checkoutBuyerTotalProvider` - Total with tax

**Key Widgets:**
- _CheckoutStepper
- _CheckoutContent
- _AddressSection (part/checkout_address_section.dart)
- _PaymentProviderSection
- _OrderSummary
- _CheckoutButton

**Navigation:**
- **From:** CartScreen
- **To:** OrderSuccessScreen, HomeScreen

---

### 13. CartitemScreen

**File:** `origna_gta/lib/screens/cartitem_screen.dart`  
**Description:** (Not fully analyzed - appears to be part of cart flow)

---

### 14. OrderSuccessScreen

**File:** `origna_gta/lib/screens/ordersuccess_screen.dart`  
**Lines:** 1-550

**Route:** `/order-success` (AppRoutes.orderSuccess)

**Description:**  
Celebration screen shown after successful order placement. Features confetti animation, mascot, delivery estimate, and order summary.

**State Dependencies:**
- Analytics service for purchase logging

**Key Widgets:**
- _ConfettiAnimation (custom particle system)
- ShopMascot
- _DeliveryWindowCard

**Navigation:**
- **From:** CheckoutScreen
- **To:** HomeScreen, OrdersScreen

---

## Orders

### 15. OrdersScreen

**File:** `origna_gta/lib/screens/orders_screen.dart`  
**Lines:** 1-370

**Route:** `/orders` (AppRoutes.orders)

**Description:**  
Buyer order history with filter tabs (All, Active, Delivered, Cancelled). Shows pending shipping approvals banner.

**State Dependencies:**
- `buyerOrdersProvider` - List of orders
- `_ordersFilterProvider` - Local filter state
- `currentUserProvider` - Auth check

**Key Widgets:**
- _FilterRow with _OrderFilterChip
- _OrdersLoadingSkeleton
- BuyerOrderCard
- PendingApprovalsBanner

**Navigation:**
- **From:** HomeScreen, OrderSuccessScreen
- **To:** OrderDetailScreen, ShippingApprovalScreen

---

### 16. OrderDetailScreen

**File:** `origna_gta/lib/screens/order_detail_screen.dart`  
**Lines:** 1-139

**Route:** `/orders/detail` (AppRoutes.orderDetail)

**Description:**  
Detailed order view with item list, status timeline, and actions. Uses OrderDetailScreenLayout for rendering.

**State Dependencies:**
- `orderByIdProvider(orderId)` - Specific order data

**Key Widgets:**
- OrderDetailScreenLayout
- BuyerOrderCard (isDetailView: true)

**Navigation:**
- **From:** OrdersScreen
- **To:** ReturnRequestScreen, HomeScreen

---

### 17. ReturnRequestScreen

**File:** `origna_gta/lib/screens/return_request_screen.dart`  
**Lines:** 1-532

**Route:** `/orders/return-request` (AppRoutes.returnRequest)

**Description:**  
Allows buyers to request returns on delivered order items. Select items, choose reason, add description.

**State Dependencies:**
- `orderByIdProvider(orderId)` - Order data
- `returnRequestViewModelProvider` - Return request state
- `_returnSelectedItemsProvider` - Local item selection
- `_returnSelectedReasonProvider` - Local reason selection

**Key Widgets:**
- _ReturnWindowNotice
- _buildItemTile (with CachedNetworkImage)
- DropdownButtonFormField for reason

**Navigation:**
- **From:** OrderDetailScreen
- **To:** OrderDetailScreen (on submit)

---

### 18. ShippingApprovalScreen

**File:** `origna_gta/lib/screens/shipping_approval_screen.dart`  
**Lines:** 1-747

**Route:** `/shipping-approval` (AppRoutes.shippingApproval)

**Description:**  
Allows buyers to approve or reject shipping cost changes when actual cost exceeds estimate by >20%.

**State Dependencies:**
- `pendingShippingApprovalsProvider` - Orders needing approval
- `shippingApprovalViewModelProvider` - Approval actions

**Key Widgets:**
- _ApprovalCard with shipping cost comparison
- ModernButton (approve/reject)

**Navigation:**
- **From:** OrdersScreen (pending approvals banner)
- **To:** OrdersScreen (after approval/rejection)

---

## Profile & Settings

### 19. ProfileScreen

**File:** `origna_gta/lib/screens/profile_screen.dart`  
**Lines:** 1-121

**Route:** `/profile` (AppRoutes.profile)

**Description:**  
User profile with header, settings sections (theme, language), subscription status, and account actions (sign out, delete).

**State Dependencies:**
- `userProfileProvider` - User profile data
- `profileViewModelProvider` - ProfileState (isLoading, successMessage, errorMessage)
- `currentUserProvider` - Auth user
- `themeModeProvider` - Theme preference
- `subscriptionStreamProvider` - Premium status

**Key Widgets:**
- ProfileScreenLayout (part/profile_header.dart, part/profile_settings_section.dart)
- ProfileHeaderCard
- ProfileThemeToggle
- PremiumMenuItem

**Navigation:**
- **From:** HomeScreen
- **To:** LoginScreen, AddressManagementScreen, SecuritySettingsScreen, SubscriptionScreen

---

### 20. AddressManagementScreen

**File:** `origna_gta/lib/screens/addressmanagement_screen.dart`  
**Lines:** 1-482

**Route:** `/addresses` (AppRoutes.addressManagement)

**Description:**  
Manage saved shipping addresses (add, edit, delete, set default). Limited to 10 addresses.

**State Dependencies:**
- `userAddressesProvider` - List of addresses
- `addressManagementViewModelProvider` - CRUD operations

**Key Widgets:**
- _buildAddressCard with PopupMenuButton
- ModernLoadingIndicator overlay
- AnimatedEmptyState

**Navigation:**
- **From:** ProfileScreen, CheckoutScreen
- **To:** EditAddressScreen

---

### 21. EditAddressScreen

**File:** `origna_gta/lib/screens/editaddress_screen.dart`  
**Route:** `/address/edit` (AppRoutes.addEditAddress)

**Description:**  
Add or edit a shipping address with form validation.

---

### 22. SecuritySettingsScreen

**File:** `origna_gta/lib/screens/security_settings_screen.dart`  
**Lines:** 1-252

**Route:** `/security-settings` (AppRoutes.securitySettings)

**Description:**  
Security settings including MFA enable/disable, login history, known devices, and security alerts.

**State Dependencies:**
- `mfaViewModelProvider` - MFA status
- `_securityDataProvider` - FutureProvider for login history, devices, alerts

**Key Widgets:**
- _buildMfaStatusCard (part/security_mfa_section.dart)
- _buildLoginHistoryCard (part/security_login_history_section.dart)
- _buildKnownDevicesCard (part/security_devices_section.dart)

**Navigation:**
- **From:** ProfileScreen
- **To:** MfaSetupScreen

---

### 23. NotificationsScreen

**File:** `origna_gta/lib/screens/notifications_screen.dart`  
**Lines:** 1-547

**Route:** `/notifications` (AppRoutes.notifications)

**Description:**  
Live notification feed grouped by time (Today, This Week, Earlier). Supports mark all read and individual mark read.

**State Dependencies:**
- `_userNotificationsProvider` - StreamProvider from notification repository
- `currentUserProvider` - UID for filtering

**Key Widgets:**
- NotificationsScreenLayout
- _MarkAllReadBar
- _NotificationTile
- _SectionHeader

**Navigation:**
- **From:** HomeScreen (notification icon)
- **To:** HomeScreen

---

## Favorites

### 24. FavoritesScreen

**File:** `origna_gta/lib/screens/favorites_screen.dart`  
**Lines:** 1-175

**Route:** `/favorites` (AppRoutes.favorites)

**Description:**  
Grid of favorited products with unavailable items warning. Pull-to-refresh enabled.

**State Dependencies:**
- `favoritedProductsProvider` - List of favorited products
- `userProfileProvider` - User data

**Key Widgets:**
- CustomScrollView with SliverGrid
- ProductCard (with opacity for unavailable)
- AnimatedEmptyState

**Navigation:**
- **From:** HomeScreen (favorites icon)
- **To:** ProductDetailScreen

---

## Seller Dashboard

### 25. SellerRegistrationScreen

**File:** `origna_gta/lib/screens/seller_registration_screen.dart`  
**Lines:** 1-334

**Route:** `/seller/register` (AppRoutes.sellerRegistration)

**Description:**  
Seller onboarding with Stripe Connect payment provider selection, benefits display, and terms acceptance.

**State Dependencies:**
- `userProfileProvider` - User data
- `sellerRegistrationViewModelProvider` - Registration state
- `_sellerTermsAcceptedProvider` - Local checkbox state

**Key Widgets:**
- _HeaderCard
- _ProviderSelector (Stripe, PayPal, Wise)
- _BenefitsCard
- _VerificationStatusCard
- _ActionButton

**Navigation:**
- **From:** ProfileScreen (become seller)
- **To:** SellerSetupScreen, HomeScreen

---

### 26. SellerSetupScreen

**File:** `origna_gta/lib/screens/seller_setup_screen.dart`  
**Lines:** 1-726

**Description:**  
Seller setup completion/refresh screen shown after Stripe Connect onboarding. Checks account status and guides user through verification.

**State Dependencies:**
- `sellerAccountStatusProvider` - Stripe account status
- `refreshSellerStatusProvider` - Manual status refresh
- `_sellerSetupRefreshingProvider` - Local loading state

**Key Widgets:**
- SellerSetupCompleteScreen
- SellerSetupRefreshScreen

**Navigation:**
- **From:** SellerRegistrationScreen
- **To:** SellerRegistrationScreen, HomeScreen

---

### 27. SellerOrdersScreen

**File:** `origna_gta/lib/screens/seller_orders_screen.dart`  
**Lines:** 1-236

**Route:** `/seller/orders` (AppRoutes.sellerOrders)

**Description:**  
Seller order management with earnings summary, order cards, and Q&A badge. Shows suspended state for blocked sellers.

**State Dependencies:**
- `currentUserProvider` - Auth check
- `userProfileProvider` - Suspended status
- `sellerOrdersProvider` - Seller's orders
- `sellerEarningsSummaryProvider` - Revenue stats

**Key Widgets:**
- _EarningsSummaryCard (part/seller_orders_earnings_card.dart)
- _SellerOrderCard (part/seller_orders_order_card.dart)
- _UnansweredQaBadge

**Navigation:**
- **From:** HomeScreen, ProfileScreen
- **To:** SellerIntegrationScreen

---

### 28. SellerProductsScreen

**File:** `origna_gta/lib/screens/seller_products_screen.dart`  
**Lines:** 1-284

**Route:** `/seller/products` (AppRoutes.sellerProducts)

**Description:**  
Seller product management with grid view, bulk selection, and bulk actions (activate, pause, archive).

**State Dependencies:**
- `userProfileProvider` - User data
- `sellerProductsProvider` - Seller's products
- `sellerProductsViewModelProvider` - Bulk selection state

**Key Widgets:**
- _BulkActionBar
- _SellerProductCard
- _UnansweredQaBadge
- ModernButton, ModernLoadingIndicator

**Navigation:**
- **From:** HomeScreen
- **To:** AddProductScreen, EditProductScreen, SellerBulkUpload

---

### 29. AddProductScreen

**File:** `origna_gta/lib/screens/addproduct_screen.dart`  
**Lines:** 1-233

**Route:** `/add-product` (AppRoutes.addProduct)

**Description:**  
Multi-section product creation form with basic info, delivery options, package location, supplier info, and image/video upload navigation.

**State Dependencies:**
- `addProductViewModelProvider` - Form state

**Key Widgets:**
- Form with GlobalKey<FormState>
- Multiple TextEditingControllers
- Parts in parts/ directory

**Navigation:**
- **From:** SellerProductsScreen
- **To:** ProductAddImagesScreen, ProductAddVideoScreen, SellerProductsScreen

---

### 30. EditProductScreen

**File:** `origna_gta/lib/screens/editproduct_screen.dart`  
**Lines:** 1-329

**Route:** `/edit-product` (AppRoutes.editProduct)

**Description:**  
Product edit form pre-populated with existing product data. Supports digital products with platform-specific URLs.

**State Dependencies:**
- `editProductViewModelProvider(product)` - Edit state

**Key Widgets:**
- Pre-populated TextEditingControllers
- Parts in parts/ directory

**Navigation:**
- **From:** SellerProductsScreen, ProductCard
- **To:** ProductAddImagesScreen, ProductAddVideoScreen, SellerProductsScreen

---

### 31. SellerIntegrationScreen

**File:** `origna_gta/lib/screens/seller_integration_screen.dart`  
**Lines:** 1-626

**Route:** `/seller/integration` (AppRoutes.sellerIntegration)

**Description:**  
API documentation for sellers to integrate license activation/verification into their software. Shows endpoints and code snippets.

**State Dependencies:**
- None (static UI)

**Key Widgets:**
- _GuideCard (reusable card wrapper)
- _CodeBlock (with copy button)
- _EndpointRow
- _SwiftSnippetCard
- _PythonSnippetCard

**Navigation:**
- **From:** SellerOrdersScreen

---

### 32. ProductAddImagesScreen

**File:** `origna_gta/lib/screens/productaddimages_screen.dart`

**Description:**  
Image upload interface for products.

---

### 33. ProductAddVideoScreen

**File:** `origna_gta/lib/screens/productaddvideo_screen.dart`

**Description:**  
Video upload interface for products.

---

## Subscription

### 34. SubscriptionScreen

**File:** `origna_gta/lib/screens/subscription_screen.dart`  
**Lines:** 1-218

**Route:** `/subscription` (AppRoutes.subscription)

**Description:**  
Premium membership upgrade page with benefits list, current status, and checkout redirect.

**State Dependencies:**
- `subscriptionStreamProvider` - Subscription info
- `subscriptionViewModelProvider` - Checkout URL state

**Key Widgets:**
- _SubscriptionHeroSection (part/subscription_hero_section.dart)
- _BenefitCard (part/subscription_benefit_card.dart)
- _SubscriptionStatusSection
- _SubscriptionActions
- PremiumPaywallWidget

**Navigation:**
- **From:** ProfileScreen
- **To:** External Stripe checkout, SubscriptionSuccessScreen

---

### 35. SubscriptionSuccessScreen

**File:** `origna_gta/lib/screens/subscription_success_screen.dart`  
**Lines:** 1-442

**Route:** `/subscription/success` (AppRoutes.subscriptionSuccess)

**Description:**  
Post-checkout success screen with 30-second timeout fallback. Shows premium benefits and welcomes new premium members.

**State Dependencies:**
- `subscriptionStreamProvider` - isPremium check
- `_subscriptionTimedOutProvider` - Timeout state

**Key Widgets:**
- _BenefitRow (repeated 5 times)
- ModernButton
- ModernLoadingIndicator

**Navigation:**
- **From:** External Stripe checkout
- **To:** HomeScreen

---

### 36. SubscriptionCancelScreen

**File:** `origna_gta/lib/screens/subscription_cancel_screen.dart`  
**Lines:** 1-170

**Route:** `/subscription/cancel` (AppRoutes.subscriptionCancel)

**Description:**  
Checkout cancellation page reassuring user no charge was made.

**State Dependencies:**
- None (static UI)

**Key Widgets:**
- ElevatedButton (resubscribe)
- TextButton (back to home)

**Navigation:**
- **From:** External Stripe checkout cancel
- **To:** SubscriptionScreen, HomeScreen

---

## Chat & Messaging

### 37. ChatScreen

**File:** `origna_gta/lib/screens/chat_screen.dart`  
**Lines:** 1-643

**Route:** `/chat` (AppRoutes.chat)

**Description:**  
Real-time chat between buyer and seller about a product. Supports premium-only access, message deletion, and typing indicators.

**State Dependencies:**
- `chatViewModelProvider(productId)` - Chat state
- `userIdProvider` - Current user ID
- `chatMessagesProvider(chatId)` - Message stream

**Key Widgets:**
- _MessagesList with ListView.builder
- _MessageBubble with animations
- _MessageInput
- PremiumPaywallWidget

**Navigation:**
- **From:** ProductDetailScreen
- **To:** HomeScreen

---

### 38. ChatConversationsScreen

**File:** `origna_gta/lib/screens/chat_conversations_screen.dart`  
**Lines:** 1-309

**Route:** `/chat/inbox` (AppRoutes.chatInbox)

**Description:**  
Inbox showing all chat threads with product context. Premium-gated, shows unread counts.

**State Dependencies:**
- `subscriptionStreamProvider` - Premium check
- `myAllChatsProvider` - All chat threads

**Key Widgets:**
- _ChatInboxBody
- _ChatThreadTile
- _ProductAvatar
- PremiumPaywallWidget

**Navigation:**
- **From:** HomeScreen
- **To:** ChatScreen

---

## Legal & Common

### 39. ErrorScreen

**File:** `origna_gta/lib/screens/error_screen.dart`  
**Lines:** 1-101

**Description:**  
Generic error screen with message display and home navigation button.

**State Dependencies:**
- None (receives message via constructor)

**Key Widgets:**
- FadeSlideIn animations
- ModernButton

**Navigation:**
- **From:** AuthWrapper, various error states
- **To:** HomeScreen

---

### 40. PrivacyPolicyScreen

**File:** `origna_gta/lib/screens/privacy_policy_screen.dart`  
**Route:** `/privacy-policy` (AppRoutes.privacyPolicy)

**Description:**  
Privacy policy display screen.

---

### 41. TermsOfServiceScreen

**File:** `origna_gta/lib/screens/terms_of_service_screen.dart`  
**Route:** `/terms-of-service` (AppRoutes.termsOfService)

**Description:**  
Terms of service display screen.

---

### Additional Common Screens

- **TermsScreen** (`terms_screen.dart`) - Terms display
- **PrivacyPolicyScreen** (`privacy_policy_screen.dart`) - Privacy display  
- **EmailVerificationRequiredScreen** - Part of common_screens.dart (exported from email_verification_screen.dart)

---

## Common Patterns

### Authentication Flow
```
AuthWrapper → (not logged in) → LoginScreen → (success) → MainScreen → HomeScreen
AuthWrapper → (email not verified) → EmailVerificationScreen → HomeScreen
AuthWrapper → (terms update needed) → _TermsUpdateGate → HomeScreen
```

### Cart to Checkout Flow
```
HomeScreen → ProductDetailScreen → Add to Cart → CartScreen → CheckoutScreen → OrderSuccessScreen
```

### Seller Flow
```
ProfileScreen → SellerRegistrationScreen → SellerSetupScreen → (complete) → SellerProductsScreen
```

### Order Management Flow
```
OrdersScreen → OrderDetailScreen → ReturnRequestScreen
OrdersScreen (pending approvals) → ShippingApprovalScreen
```

---

## Key Providers Summary

| Provider | Purpose |
|----------|---------|
| `authStateProvider` | Authentication state (Firebase/OrignaBase user) |
| `userProfileProvider` | User profile data from database |
| `homeViewModelProvider` | Home screen products and search |
| `cartItemsProvider` | Shopping cart items |
| `checkoutStateProvider` | Checkout flow state |
| `buyerOrdersProvider` | Customer order history |
| `sellerOrdersProvider` | Seller order management |
| `sellerProductsProvider` | Seller product inventory |
| `subscriptionStreamProvider` | Premium subscription status |
| `chatViewModelProvider` | Chat state management |
| `mfaViewModelProvider` | MFA setup/challenge state |

---

*Document generated from code analysis of origna_gta Flutter project.*
*Last updated: 2026-03-23*
