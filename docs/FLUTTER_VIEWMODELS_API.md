# Flutter ViewModels & Providers -- API Reference

> Auto-generated from codebase exploration. All paths relative to `origna_gta/lib/`.

---

## Table of Contents

1. [Core Providers](#core-providers)
2. [Auth](#auth)
3. [Cart](#cart)
4. [Checkout](#checkout)
5. [Orders](#orders)
6. [Products](#products)
7. [Profile](#profile)
8. [Seller](#seller)
9. [Admin](#admin)
10. [Subscription](#subscription)
11. [Support](#support)
12. [Chat](#chat)
13. [Notifications](#notifications)
14. [Q&A](#qa)
15. [Terms](#terms)
16. [Mascot / Moose](#mascot--moose)

---

## Core Providers

### `core/providers.dart`

**Purpose**: Central dependency injection hub. Wires all repositories to OrignaBase SDK.

| Provider | Type | Description |
|----------|------|-------------|
| `envConfigProvider` | `Provider<EnvConfig>` | Environment configuration (URLs, flags) |
| `authRepositoryProvider` | `Provider<AuthRepository>` | Auth operations |
| `cartRepositoryProvider` | `Provider<CartRepository>` | Cart CRUD |
| `orderRepositoryProvider` | `Provider<OrderRepository>` | Order operations |
| `productRepositoryProvider` | `Provider<ProductRepository>` | Product CRUD + search |
| `userRepositoryProvider` | `Provider<UserRepository>` | User profile operations |
| `locationRepositoryProvider` | `Provider<LocationRepository>` | Geocoding + address lookup |
| `authStateProvider` | `StreamProvider<AppAuthUser?>` | Reactive auth state stream |
| `currentUserProvider` | `Provider<AppAuthUser?>` | Synchronous current user snapshot |
| `userIdProvider` | `Provider<String?>` | Current user ID (short form) |
| `googleAuthAvailabilityProvider` | `FutureProvider<PublicAuthProviderAvailability>` | Google sign-in availability |

**Watches**: `orignabaseProvider`, `authStateProvider`, `currentUserProvider`, `userIdProvider`, `userRepositoryProvider`

### `core/orignabase_provider.dart`

**Purpose**: OrignaBase SDK initialization and auth state stream.

| Provider | Type | Description |
|----------|------|-------------|
| `orignabaseProvider` | `Provider<OrignaBase>` | Global OrignaBase client (URL from EnvConfig) |
| `obAuthStateProvider` | `StreamProvider<AuthState>` | Raw OrignaBase auth state changes |
| `obUserIdProvider` | alias for `userIdProvider` | Convenience alias |

### `core/theme_provider.dart`

**Purpose**: App theme mode state.

| Provider | Type | Description |
|----------|------|-------------|
| `themeModeProvider` | `StateProvider<ThemeMode>` | Current theme mode (dark/light/system) |

---

## Auth

### `features/auth/auth_provider.dart`

**Purpose**: Auth action helpers (sign-out, email verification, user document creation).

| Provider | Type | Description |
|----------|------|-------------|
| `authActionsProvider` | `Provider<AuthActions>` | Auth action methods |

**Methods**:
- `signOut()` -- Signs user out via OrignaBase SDK
- `isEmailVerified()` -- Checks email verification status
- `ensureUserDocumentExists()` -- Creates user document in PostgreSQL if missing
- `sendEmailVerification()` -- Sends verification email

**Watches**: `userIdProvider`, `authRepositoryProvider`, `userProfileProvider`

### `features/auth/login_viewmodel.dart`

**Purpose**: Login/register form state and authentication flows.

**Class**: `LoginViewModel extends StateNotifier<LoginState>`

**Methods**:
- `handleAuth({required String email, required String password, String? name, ...})` -- Email/password login or register
- `handleGoogleSignIn()` -- Google OAuth via OrignaBase server-side redirect
- `handleAppleSignIn()` -- Apple Sign-In
- `resetPassword(String email)` -- Password reset email
- `toggleAuthMode()` -- Switch login/register mode
- `toggleObscurePassword()` -- Toggle password visibility
- `setAcceptedTerms(bool value)` -- Terms acceptance checkbox
- `setMarketingOptIn(bool value)` -- Marketing opt-in checkbox

### `features/auth/mfa_viewmodel.dart`

**Purpose**: Multi-factor authentication setup, verification, and recovery.

**Class**: `MfaViewModel extends StateNotifier<MfaState>`

**Methods**:
- `checkStatus()` -- Check if MFA is enabled for current user
- `startSetup()` -- Begin TOTP setup (generates QR code + secret)
- `verifySetup(String code)` -- Verify TOTP code during setup
- `goToStep(int step)` -- Navigate MFA setup wizard
- `confirmSaved()` -- Confirm recovery codes saved
- `verifyChallenge(String challengeToken, String code)` -- Verify MFA challenge during login
- `useRecoveryCode(String challengeToken, String code)` -- Use recovery code instead of TOTP
- `disable(String code)` -- Disable MFA (requires valid code)

---

## Cart

### `features/cart/cart_provider.dart`

**Purpose**: Cart state management, item CRUD, computed totals.

| Provider | Type | Description |
|----------|------|-------------|
| `cartItemsProvider` | `StreamProvider.autoDispose` | Real-time cart items stream |
| `cartControllerProvider` | `Provider.autoDispose` | Cart action methods |
| `cartItemCountProvider` | `Provider.autoDispose` | Total item count |
| `cartSubtotalProvider` | `Provider.autoDispose` | Subtotal in integer cents |
| `cartWithDetailsProvider` | `FutureProvider.autoDispose` | Cart items with full product details |
| `cartItemDetailProvider` | `FutureProvider.autoDispose` | Single cart item with product detail |
| `cartItemQuantityProvider` | `Provider.autoDispose` | Quantity for a specific item |
| `cartItemDateProvider` | `Provider.autoDispose` | Date added for a specific item |
| `cartShippingValidationProvider` | `FutureProvider.autoDispose` | Validates shipping eligibility |
| `deliveryInstructionsProvider` | `StateProvider.autoDispose` | Delivery instructions text |
| `unavailableCartItemsProvider` | `FutureProvider.autoDispose` | Items no longer available |

**Controller Methods** (via `cartControllerProvider`):
- `addToCart(String productId, int quantity, {String? variantId, String? product...})` -- Add item to cart
- `removeFromCart(String cartItemId)` -- Remove item
- `updateQuantity(String cartItemId, int newQuantity)` -- Update item quantity
- `updateBuyerNote(String cartItemId, String? note)` -- Add/update buyer note
- `clearCart()` -- Remove all items
- `refreshCart()` -- Force refresh cart data
- `saveForLater(String productId, String cartItemId)` -- Move to saved items
- `canAddToCart(String productId)` -- Check if item can be added

**Watches**: `cartItemsProvider`, `userIdProvider`, `cartRepositoryProvider`, `cartWithDetailsProvider`, `productRepositoryProvider`

---

## Checkout

### `features/checkout/checkout_provider.dart`

**Purpose**: Re-exports + computed checkout providers (tax rate, total).

| Provider | Type | Description |
|----------|------|-------------|
| `checkoutTaxRateProvider` | `Provider.autoDispose<double>` | Tax rate based on shipping address province |
| `checkoutTotalProvider` | `Provider.autoDispose<double>` | Final total = (subtotal - coupon) + tax + shipping |

**Watches**: `checkoutStateProvider`, `cartSubtotalProvider`

### `features/checkout/orignabase_checkout_provider.dart`

**Purpose**: Full checkout flow state -- address, shipping, coupons, payment.

**Class**: `OrignaBaseCheckoutNotifier extends StateNotifier<CheckoutState>`

**Methods**:
- `initialize()` -- Load user profile + default address
- `updateAddress(Address address)` -- Set shipping address
- `calculateShipping(List<CartItemDetailModel> items)` -- Calculate shipping costs per seller
- `calculateTaxes(double subtotal, {double shippingCost = 0.0})` -- Calculate provincial taxes
- `applyCoupon(String code, int subtotalCents, {List<String>? sellerIds})` -- Apply coupon code
- `removeCoupon()` -- Remove applied coupon
- `setDeliverySpeed(DeliverySpeed speed)` -- Standard/express/same-day
- `setPaymentProvider(String provider)` -- Select payment method
- `startCheckout({required List<CartItemDetailModel> items, required UserModel user, ...})` -- Create Stripe Checkout Session
- `reset()` -- Clear checkout state

---

## Orders

### `features/orders/orders_provider.dart`

**Purpose**: Order streams for buyers and sellers, computed summaries.

| Provider | Type | Description |
|----------|------|-------------|
| `buyerOrdersProvider` | `StreamProvider.autoDispose` | Buyer's orders stream |
| `sellerOrdersProvider` | `StreamProvider.autoDispose` | Seller's orders stream |
| `orderByIdProvider` | `FutureProvider.autoDispose` | Fetch single order by ID |
| `paidOrderBySessionProvider` | `StreamProvider.autoDispose` | Order by Stripe session ID |
| `pendingApprovalsCountProvider` | `Provider.autoDispose` | Count of pending shipping approvals |
| `pendingShippingApprovalsProvider` | `Provider.autoDispose` | List of pending shipping approvals |
| `returnRequestsProvider` | `FutureProvider.autoDispose` | Return requests for an order |
| `sellerEarningsSummaryProvider` | `Provider.autoDispose` | Seller earnings summary |
| `sellerOrderNetProvider` | `Provider.autoDispose` | Net earnings for a specific order |

**Watches**: `userIdProvider`, `orderRepositoryProvider`, `buyerOrdersProvider`, `sellerOrdersProvider`

### `features/orders/buyer_orders_viewmodel.dart`

**Purpose**: Buyer-side order actions.

**Class**: `BuyerOrdersViewModel extends StateNotifier<BuyerOrdersState>`
**State**: `BuyerOrdersState` (Freezed)

**Methods**:
- `confirmReceipt(String orderId, String itemKey)` -- Confirm delivery receipt

### `features/orders/seller_orders_viewmodel.dart`

**Purpose**: Seller-side order fulfillment actions.

**Class**: `SellerOrdersViewModel extends StateNotifier<SellerOrdersState>`

**Methods**:
- `updateShippingAndCapture(String orderId, int actualShippingCents, String trackingNumber, {St...})` -- Ship order with tracking info, capture payment
- `updateItemStatus(String orderId, String itemId, String status, {String? trackingNumb...})` -- Update individual item status

### `features/orders/shipping_approval_viewmodel.dart`

**Purpose**: Buyer approval of actual shipping costs (when different from estimate).

**Class**: `ShippingApprovalViewModel extends StateNotifier<ShippingApprovalState>`
**State**: `ShippingApprovalState` (Freezed)

**Methods**:
- `approveShippingCost(String orderId, bool approved)` -- Approve or reject shipping cost
- `clearStatus()` -- Reset status

### `features/orders/return_request_viewmodel.dart`

**Purpose**: Submit return/refund requests.

**Class**: `ReturnRequestViewModel extends StateNotifier<ReturnRequestState>`
**State**: `ReturnRequestState` (Freezed)

**Methods**:
- `submitReturn({required String orderId, required List<String> cartItemIds, requir...})` -- Submit return request with reason + items
- `clearStatus()` -- Reset status

---

## Products

### `features/products/products_provider.dart`

**Purpose**: Product listing, search, favorites, filtering.

| Provider | Type | Description |
|----------|------|-------------|
| `filteredProductsProvider` | `FutureProvider.autoDispose<List<Product>>` | Products filtered by category + search |
| `favoritesProvider` | `StreamProvider.autoDispose<Set<String>>` | User's favorite product IDs |
| `favoritedProductsProvider` | `FutureProvider.autoDispose<List<Product>>` | Full product objects for favorites |
| `favoritesControllerProvider` | `Provider.autoDispose<FavoritesController>` | Toggle/check favorites |
| `searchQueryProvider` | `StateProvider.autoDispose<String>` | Current search query |
| `selectedCategoryProvider` | `StateProvider.autoDispose<int?>` | Selected category filter |

**FavoritesController Methods**:
- `isFavorite(String productId)` -- Check if product is favorited
- `toggleFavorite(String productId, {String? productName, double? priceCad})` -- Toggle favorite status

### `features/products/product_detail_viewmodel.dart`

**Purpose**: Product detail page state (quantity, images, variants, seller metrics).

**Class**: `ProductDetailViewModel extends StateNotifier<ProductDetailState>`

**Methods**:
- `setQuantity(int quantity)` -- Set purchase quantity
- `incrementQuantity()` / `decrementQuantity()` -- Adjust quantity
- `setImageIndex(int index)` -- Set active product image
- `setSelectedOption(String optionName, String value, {String? variantId})` -- Select variant option
- `setSelectedVariantId(String? variantId)` -- Set active variant
- `fetchSellerMetrics(String sellerId)` -- Load seller rating/order count
- `voteHelpful(String ratingId, String productId, bool helpful)` -- Vote on review helpfulness

### `features/products/add_product_viewmodel.dart`

**Purpose**: Multi-step product creation form (50+ fields).

**Class**: `AddProductViewModel extends StateNotifier<AddProductState>`

**Key Methods** (abbreviated -- 50+ methods):
- `addProduct({required String name, required String description, required double...})` -- Submit new product
- `addImage(ImageModel image)` / `removeImage(int index)` / `updateImages(List<ImageModel> images)` -- Manage product images
- `setVideo(XFile? file, int? durationSeconds)` / `removeVideo()` -- Video management
- `setCategoryId(String? id)` / `setSubcategory(String? sub)` -- Category selection
- `toggleDigital(bool value)` / `togglePerishable(bool value)` / `toggleFreeShipping(bool value)` -- Product flags
- `toggleHasVariants(bool value)` / `addVariantOption(...)` / `updateVariantPrice(...)` -- Variant management
- `setActiveStep(int step)` -- Wizard step navigation
- `setWarehouseStock(String warehouseId, int qty)` -- Per-warehouse stock levels
- `selectAddress(Map<String, dynamic> suggestion)` -- Autocomplete address selection

### `features/products/edit_product_viewmodel.dart`

**Purpose**: Edit existing product (mirrors AddProduct but pre-populated).

**Class**: `EditProductViewModel extends StateNotifier<EditProductState>`

**Key Methods**:
- `updateProduct({required String name, required String description, required double...})` -- Submit product update
- `addImage(XFile file)` / `removeExistingImage(int index)` / `setExistingImageAsCover(int index)` -- Image management
- `setVideo(XFile file, int durationSeconds)` / `removeVideo()` -- Video
- `toggleDigital(bool value)` / `togglePerishable(bool value)` / `toggleSoldOut(bool value)` -- Flags
- All setter methods mirror AddProductViewModel

### `features/products/product_actions_viewmodel.dart`

**Purpose**: Destructive product actions.

**Class**: `ProductActionsViewModel extends StateNotifier<ProductActionsState>`
**State**: `ProductActionsState` (Freezed)

**Methods**:
- `deleteProduct(String productId)` -- Delete product (sets lifecycle to `deleted`)

### `features/products/product_rating_viewmodel.dart`

**Purpose**: Submit product ratings and reviews.

**Class**: `ProductRatingViewModel extends StateNotifier<ProductRatingState>`
**State**: `ProductRatingState` (Freezed)

**Methods**:
- `setReviewText(String? text)` -- Set review text
- `submitRating(String orderId, String productId, int rating, {List<Uint8List>? rev...})` -- Submit rating with optional review images

### `features/products/bulk_upload_viewmodel.dart`

**Purpose**: CSV bulk product upload.

**Class**: `BulkUploadViewModel extends StateNotifier<BulkUploadState>`

**Methods**:
- `parseCsvContent(String csvContent)` -- Parse uploaded CSV
- `generateTemplate()` -- Generate CSV template for download
- `uploadProducts()` -- Upload parsed products to backend
- `reset()` -- Clear state

### `features/products/review_eligibility_provider.dart`

**Purpose**: Checks if a user is eligible to review a product (must have purchased it).

**Watches**: `userIdProvider`, `buyerOrdersProvider`

### `features/products/stock_notification_provider.dart` / `orignabase_stock_notification_provider.dart`

**Purpose**: Back-in-stock notifications.

**Class**: `OrignaBaseStockNotificationNotifier extends StateNotifier<AsyncValue<bool>>`

**Methods**:
- `init()` -- Check if user is subscribed to stock alerts for a product
- `subscribe()` -- Subscribe to back-in-stock alerts
- `unsubscribe()` -- Unsubscribe

---

## Profile

### `features/profile/profile_viewmodel.dart`

**Purpose**: Re-export of `OrignaBaseProfileViewModel`. `typedef ProfileViewModel = OrignaBaseProfileViewModel`.

### `features/profile/orignabase_profile_viewmodel.dart`

**Purpose**: User profile actions (sign-out, language, data export, account deletion).

**Class**: `OrignaBaseProfileViewModel extends StateNotifier<ProfileState>`

**Methods**:
- `signOut()` -- Sign out via OrignaBase SDK
- `updateLanguage(String langCode)` -- Change preferred language
- `exportData()` -- GDPR data export
- `deleteAccount(String confirmation)` -- Delete account (requires "DELETE" confirmation)

### `features/profile/address_viewmodel.dart`

**Purpose**: Address form state with Google Places autocomplete.

**Class**: `AddressViewModel extends StateNotifier<AddressState>`

**Methods**:
- `saveAddress({required String street, required String apartment, required String...})` -- Save address to user profile
- `selectAddress(Map<String, dynamic> suggestion)` -- Select autocomplete suggestion
- `onStreetChanged(String value)` -- Trigger autocomplete on street input
- `setInitialData(Address? address)` -- Pre-populate for editing
- `setDefault(bool value)` -- Mark as default address
- `setLabel(String label)` -- Address label (home/work/custom)
- `setProvince(String province)` -- Set province

### `features/profile/address_management_viewmodel.dart`

**Purpose**: Address list management (delete, set default).

**Class**: `AddressManagementViewModel extends StateNotifier<AsyncValue<void>>`

**Methods**:
- `deleteAddress(String addressId)` -- Delete an address
- `setDefaultAddress(String addressId)` -- Set as default shipping address

### `features/profile/profile_provider.dart`

**Purpose**: Re-exports `profile_state.dart` and `profile_viewmodel.dart`.

---

## Seller

### `features/seller/seller_account_status_viewmodel.dart`

**Purpose**: Seller onboarding/account status checks.

**Watches**: `obUserIdProvider`

### `features/seller/seller_products_viewmodel.dart`

**Purpose**: Seller's product list with fetch capability.
**State**: `SellerProductsState` (Freezed)

**Methods**:
- `fetch()` -- Load seller's products

**Watches**: `obUserIdProvider`, `orignabaseProvider`

### `features/seller/orignabase_seller_products_viewmodel.dart`

**Purpose**: Seller product list with bulk actions and selection.

**Class**: `OrignaBaseSellerProductsViewModel extends StateNotifier<SellerProductsState>`

**Methods**:
- `bulkAction(String action)` -- Apply action to selected products (activate/deactivate/delete)
- `toggleSelection(String productId)` -- Toggle product selection
- `selectAll(List<String> productIds)` -- Select all products
- `clearSelection()` -- Clear selection

### `features/seller/warehouses_viewmodel.dart`

**Purpose**: Seller warehouse list with fetch.
**State**: `WarehousesState` (Freezed)

**Methods**:
- `fetch()` -- Load seller's warehouses

**Watches**: `obUserIdProvider`, `orignabaseProvider`

### `features/seller/orignabase_warehouses_viewmodel.dart`

**Purpose**: Full warehouse CRUD.

**Class**: `OrignaBaseWarehousesViewModel extends StateNotifier<WarehousesState>`

**Methods**:
- `createWarehouse({required String label, required String type, required Address addr...})` -- Create warehouse
- `updateWarehouse({required String warehouseId, String? label, String? type, Addr...})` -- Update warehouse
- `deleteWarehouse(String warehouseId)` -- Delete warehouse
- `submitWarehouseForm({String? warehouseId, required String label, required String type, ...})` -- Create or update (upsert)
- `clearStatus()` -- Reset status

---

## Admin

### `features/admin/admin_providers.dart`

**Purpose**: Admin data streams for the admin dashboard.

| Provider | Type | Description |
|----------|------|-------------|
| `adminRepositoryProvider` | `Provider<AdminRepository>` | Admin repository |
| `adminOrdersProvider` | `StreamProvider.autoDispose` | All orders stream |
| `adminProductsProvider` | `StreamProvider.autoDispose` | All products stream |
| `adminPendingReviewProductsProvider` | `StreamProvider.autoDispose` | Products pending review |
| `adminReviewsProvider` | `StreamProvider.autoDispose` | Product reviews stream |
| `adminSellersProvider` | `StreamProvider.autoDispose` | All sellers stream |
| `adminUsersProvider` | `StreamProvider.autoDispose` | All users stream |
| `adminPaymentProvidersDataProvider` | `FutureProvider.autoDispose` | Payment provider config |

**Watches**: `adminRepositoryProvider`, `orignabaseProvider`

### `features/admin/admin_actions_viewmodel.dart`

**Purpose**: Admin moderation actions.

**Class**: `AdminActionsViewModel extends StateNotifier<AdminActionsState>`
**State**: `AdminActionsState` (Freezed)

**Methods**:
- `approveProduct(String productId)` -- Approve product for listing
- `rejectProduct(String productId, String reason)` -- Reject product with reason
- `deleteProduct(String productId)` -- Delete product
- `updateProductStock(String productId, int quantity)` -- Override stock quantity
- `fetchUserById(String userId)` -- Fetch user details
- `setUserSuspended(String userId, bool suspended)` -- Suspend/unsuspend user
- `updateUserRoles(String userId, {List<String> add, List<String> remove})` -- Add/remove user roles
- `verifyAdminMfa(String code)` -- Verify admin MFA
- `disableAdminMfa(String code)` -- Disable admin MFA

---

## Subscription

### `features/subscription/orignabase_subscription_provider.dart`

**Purpose**: Premium subscription management (Stripe-backed).

**Class**: `OrignaBaseSubscriptionViewModel extends StateNotifier<SubscriptionState>`

**Methods**:
- `createSubscription()` -- Create Stripe subscription checkout session
- `cancelSubscription()` -- Cancel active subscription
- `reactivateSubscription()` -- Reactivate cancelled subscription
- `updateNotificationPreferences({bool? notifyNewProducts, bool? notifyTrending})` -- Update premium notification prefs
- `clearCheckoutUrl()` -- Clear checkout URL after redirect

**Watches**: `obUserIdProvider`, `orignabaseProvider`

### `features/subscription/subscription_provider.dart`

**Purpose**: Re-export. `typedef SubscriptionViewModel = OrignaBaseSubscriptionViewModel`.

---

## Support

### `features/support/support_provider.dart`

**Purpose**: Provides `SupportViewModel` with autoDispose.

| Provider | Type | Description |
|----------|------|-------------|
| `supportViewModelProvider` | `StateNotifierProvider.autoDispose<SupportViewModel, SupportState>` | Support chat state |

### `features/support/support_viewmodel.dart`

**Purpose**: Customer support agent chat.

**Class**: `SupportViewModel extends StateNotifier<SupportState>`

**Methods**:
- `startConversation(SupportCategory category)` -- Start support conversation by category
- `sendMessage(String text)` -- Send message in support chat

---

## Chat

### `features/chat/chat_provider.dart`

**Purpose**: Real-time buyer-seller chat.

| Provider | Type | Description |
|----------|------|-------------|
| `chatRepositoryProvider` | `Provider<OrignaBaseChatRepository>` | Chat repository |

**Class**: `ChatViewModel extends StateNotifier<ChatState>`

**Methods**:
- `openChat()` -- Open/create chat thread
- `sendMessage(String text)` -- Send chat message
- `markRead()` -- Mark messages as read
- `markReadDebounced()` -- Debounced version of markRead
- `dispose()` -- Clean up subscriptions

**Watches**: `orignabaseProvider`, `chatRepositoryProvider`, `obUserIdProvider`

---

## Notifications

### `features/notifications/notification_provider.dart`

**Purpose**: Push notification permission state.

| Provider | Type | Description |
|----------|------|-------------|
| `notificationPermissionProvider` | `StateNotifierProvider<NotificationPermissionNotifier, bool>` | Permission granted state |

**Class**: `NotificationPermissionNotifier extends StateNotifier<bool>`

**Methods**:
- `setGranted(bool granted)` -- Update permission state

---

## Q&A

### `features/qa/qa_provider.dart`

**Purpose**: Product Q&A (questions and answers).

**Class**: `QAController extends StateNotifier<AsyncValue<void>>`

**Methods**:
- `askQuestion(String productId, String question)` -- Ask a question on a product
- `answerQuestion({required String qaId, required String answer})` -- Answer a question

**Exceptions**: `PremiumRequiredException` -- Thrown when non-premium user tries to ask questions.

**Watches**: `qaRepositoryProvider`

---

## Terms

### `features/terms/terms_provider.dart`

**Purpose**: Load terms of service content.

| Provider | Type | Description |
|----------|------|-------------|
| `termsProvider` | `FutureProvider<String>` | Terms of service text |

---

## Home

### `features/home/home_viewmodel.dart`

**Purpose**: Home screen state -- search, filters, product grid.

**Class**: `HomeViewModel extends StateNotifier<HomeState>`

**Methods**:
- `loadProducts()` -- Load/refresh product grid
- `refresh()` -- Pull-to-refresh
- `onSearchChanged(String value)` -- Live search input
- `onSearchSubmitted(String value)` -- Search submitted
- `onCategorySelected(int? categoryId)` -- Filter by category
- `onSubcategorySelected(String? subcategory)` -- Filter by subcategory
- `onSortChanged(SortOption sort)` -- Change sort order
- `onPriceFilterChanged(int? minCents, int? maxCents)` -- Price range filter
- `clearPriceFilter()` -- Remove price filter
- `onToggleCanadaOnly()` -- Toggle Canada-only products
- `addRecentSearch(String query)` -- Add to recent searches
- `clearRecentSearches()` -- Clear search history
- `onSearchFocusChanged(bool focused)` -- Search bar focus state
- `dismissSearchOverlay()` -- Dismiss search suggestions overlay

---

## Mascot / Moose

### `widgets/mascot/mascot_provider.dart`

| Provider | Type | Description |
|----------|------|-------------|
| `mascotControllerProvider` | `Provider<MascotController>` | Shop mascot animation controller |

### `widgets/mascot/moose_provider.dart`

| Provider | Type | Description |
|----------|------|-------------|
| `mooseControllerProvider` | `Provider<MooseController>` | Canadian moose animation controller |

---

## Architecture Notes

- **Pattern**: MVVM with Riverpod. Screens watch providers; ViewModels extend `StateNotifier<T>`.
- **State classes**: Most use Freezed (`extends _` pattern). Some use `AsyncValue<T>` directly.
- **Naming**: `*_provider.dart` files declare Riverpod providers. `*_viewmodel.dart` files contain `StateNotifier` classes.
- **Re-exports**: Several `*_provider.dart` files are thin re-exports of `orignabase_*` implementations (e.g., `subscription_provider.dart` re-exports `orignabase_subscription_provider.dart`).
- **Money**: All monetary values in integer cents. Display conversion happens at the UI layer only.
- **Disposal**: ViewModels with subscriptions implement `dispose()` for cleanup.
- **Total files**: 42 provider/viewmodel files across 13 feature domains + 3 core providers + 2 widget providers.
