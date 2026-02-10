# 🗺️ Symbol Map — OrignaGta

> **Auto-generated** by `scripts/generate-symbol-map.sh` using universal-ctags + grep.
> Regenerate: `./scripts/generate-symbol-map.sh`
> Last updated: 2026-02-07 08:11

This map provides AST-extracted class/function signatures organized by domain.
Use it for navigating the codebase architecture without reading every file.

---

## 🔐 Auth & User

### Auth (Frontend) (Dart/Flutter)

| Symbol | Kind | File | Line |
|--------|------|------|------|
| `LoginViewModel` | class | lib/features/auth/login_viewmodel.dart | L11 |
| `LoginState` | class | lib/features/auth/login_state.dart | L1 |
| `handleAuth` | method | lib/features/auth/login_viewmodel.dart | L16 |
| `handleGoogleSignIn` | method | lib/features/auth/login_viewmodel.dart | L111 |
| `resetPassword` | method | lib/features/auth/login_viewmodel.dart | L130 |
| `setAcceptedTerms` | method | lib/features/auth/login_viewmodel.dart | L134 |
| `toggleAuthMode` | method | lib/features/auth/login_viewmodel.dart | L138 |
| `toggleObscurePassword` | method | lib/features/auth/login_viewmodel.dart | L142 |
| `AuthRepository` | abstract_class | lib/core/repositories/auth_repository.dart | L12 |
| `FirebaseAuthRepository` | class | lib/core/repositories/auth_repository.dart | L34 |
| `deleteAccount` | method | lib/core/repositories/auth_repository.dart | L13 |
| `isEmailVerified` | method | lib/core/repositories/auth_repository.dart | L16 |
| `registerWithEmail` | method | lib/core/repositories/auth_repository.dart | L17 |
| `sendEmailVerification` | method | lib/core/repositories/auth_repository.dart | L22 |
| `sendPasswordResetEmail` | method | lib/core/repositories/auth_repository.dart | L23 |
| `signInWithEmail` | method | lib/core/repositories/auth_repository.dart | L24 |
| `signInWithGoogle` | method | lib/core/repositories/auth_repository.dart | L25 |
| `signOut` | method | lib/core/repositories/auth_repository.dart | L26 |
| `watchProfile` | method | lib/core/repositories/auth_repository.dart | L27 |
| `validateCurrentUser` | method | lib/core/repositories/auth_repository.dart | L31 |
| `deleteAccount` | method | lib/core/repositories/auth_repository.dart | L42 |
| `ensureUserDocumentExists` | method | lib/core/repositories/auth_repository.dart | L53 |
| `isEmailVerified` | method | lib/core/repositories/auth_repository.dart | L84 |
| `registerWithEmail` | method | lib/core/repositories/auth_repository.dart | L103 |
| `sendEmailVerification` | method | lib/core/repositories/auth_repository.dart | L159 |
| `sendPasswordResetEmail` | method | lib/core/repositories/auth_repository.dart | L203 |
| `signInWithEmail` | method | lib/core/repositories/auth_repository.dart | L233 |
| `signInWithGoogle` | method | lib/core/repositories/auth_repository.dart | L264 |
| `signOut` | method | lib/core/repositories/auth_repository.dart | L281 |
| `validateCurrentUser` | method | lib/core/repositories/auth_repository.dart | L286 |
| `watchProfile` | method | lib/core/repositories/auth_repository.dart | L342 |
| `_createUserDocumentIfNeeded` | method | lib/core/repositories/auth_repository.dart | L351 |

### Auth (Backend) (Python Backend)

| Symbol | Kind | File | Line |
|--------|------|------|------|
| `admin_mfa_disable` | function | functions/handlers/admin.py | L489 |
| `admin_mfa_enroll` | function | functions/handlers/admin.py | L382 |
| `admin_mfa_verify` | function | functions/handlers/admin.py | L434 |
| `delete_account` | function | functions/handlers/admin.py | L538 |
| `get_db` | function | functions/handlers/admin.py | L24 |
| `get_delete_field` | function | functions/handlers/admin.py | L41 |
| `get_server_timestamp` | function | functions/handlers/admin.py | L33 |
| `restore_stock_batch` | function | functions/handlers/admin.py | L346 |
| `suspend_seller` | function | functions/handlers/admin.py | L195 |
| `update_user_roles` | function | functions/handlers/admin.py | L86 |
| `User` | class | functions/models/user.py | L12 |
| `UserCreate` | class | functions/models/user.py | L173 |
| `can_sell` | member | functions/models/user.py | L168 |
| `is_admin` | member | functions/models/user.py | L164 |
| `is_seller` | member | functions/models/user.py | L160 |
| `validate_name` | member | functions/models/user.py | L143 |
| `validate_roles` | member | functions/models/user.py | L154 |

## 📦 Products

### Products (Frontend) (Dart/Flutter)

| Symbol | Kind | File | Line |
|--------|------|------|------|
| `ProductActionsState` | class | lib/features/products/product_actions_viewmodel.dart | L4 |
| `ProductActionsViewModel` | class | lib/features/products/product_actions_viewmodel.dart | L20 |
| `EditProductViewModel` | class | lib/features/products/edit_product_viewmodel.dart | L15 |
| `ProductRatingState` | class | lib/features/products/product_rating_viewmodel.dart | L4 |
| `ProductRatingViewModel` | class | lib/features/products/product_rating_viewmodel.dart | L20 |
| `ProductDetailState` | class | lib/features/products/product_detail_viewmodel.dart | L3 |
| `ProductDetailViewModel` | class | lib/features/products/product_detail_viewmodel.dart | L28 |
| `EditProductState` | class | lib/features/products/edit_product_state.dart | L3 |
| `FavoritesController` | class | lib/features/products/products_provider.dart | L70 |
| `ProductQuery` | class | lib/features/products/products_provider.dart | L93 |
| `AddProductViewModel` | class | lib/features/products/add_product_viewmodel.dart | L17 |
| `AddProductState` | class | lib/features/products/add_product_state.dart | L3 |
| `deleteProduct` | method | lib/features/products/product_actions_viewmodel.dart | L25 |
| `onStreetChanged` | method | lib/features/products/edit_product_viewmodel.dart | L44 |
| `removeExistingImage` | method | lib/features/products/edit_product_viewmodel.dart | L57 |
| `selectAddress` | method | lib/features/products/edit_product_viewmodel.dart | L62 |
| `setExpressEnabled` | method | lib/features/products/edit_product_viewmodel.dart | L73 |
| `setMinimumOrderQuantity` | method | lib/features/products/edit_product_viewmodel.dart | L75 |
| `setProvince` | method | lib/features/products/edit_product_viewmodel.dart | L77 |
| `setSameDayEnabled` | method | lib/features/products/edit_product_viewmodel.dart | L79 |
| `setStandardEnabled` | method | lib/features/products/edit_product_viewmodel.dart | L81 |
| `toggleDigital` | method | lib/features/products/edit_product_viewmodel.dart | L83 |
| `toggleFreeShipping` | method | lib/features/products/edit_product_viewmodel.dart | L93 |
| `toggleLocalDelivery` | method | lib/features/products/edit_product_viewmodel.dart | L95 |
| `togglePerishable` | method | lib/features/products/edit_product_viewmodel.dart | L97 |
| `toggleSoldOut` | method | lib/features/products/edit_product_viewmodel.dart | L99 |
| `updateProduct` | method | lib/features/products/edit_product_viewmodel.dart | L101 |
| `_processImages` | method | lib/features/products/edit_product_viewmodel.dart | L216 |
| `_validateAndCompressImage` | method | lib/features/products/edit_product_viewmodel.dart | L225 |
| `submitRating` | method | lib/features/products/product_rating_viewmodel.dart | L25 |
| `setQuantity` | method | lib/features/products/product_detail_viewmodel.dart | L31 |
| `incrementQuantity` | method | lib/features/products/product_detail_viewmodel.dart | L36 |
| `decrementQuantity` | method | lib/features/products/product_detail_viewmodel.dart | L37 |
| `setImageIndex` | method | lib/features/products/product_detail_viewmodel.dart | L43 |
| `toggleFavorite` | method | lib/features/products/products_provider.dart | L85 |
| `addImage` | method | lib/features/products/add_product_viewmodel.dart | L22 |
| `addProduct` | method | lib/features/products/add_product_viewmodel.dart | L23 |
| `onStreetChanged` | method | lib/features/products/add_product_viewmodel.dart | L186 |
| `removeImage` | method | lib/features/products/add_product_viewmodel.dart | L195 |
| `selectAddress` | method | lib/features/products/add_product_viewmodel.dart | L196 |
| `setExpressEnabled` | method | lib/features/products/add_product_viewmodel.dart | L207 |
| `setFreeShippingAt10Plus` | method | lib/features/products/add_product_viewmodel.dart | L208 |
| `setLocalDeliveryOnly` | method | lib/features/products/add_product_viewmodel.dart | L209 |
| `setMinimumOrderQuantity` | method | lib/features/products/add_product_viewmodel.dart | L215 |
| `setProvince` | method | lib/features/products/add_product_viewmodel.dart | L217 |
| `setSameDayEnabled` | method | lib/features/products/add_product_viewmodel.dart | L219 |
| `setStandardEnabled` | method | lib/features/products/add_product_viewmodel.dart | L221 |
| `toggleDigital` | method | lib/features/products/add_product_viewmodel.dart | L223 |
| `toggleFreeShipping` | method | lib/features/products/add_product_viewmodel.dart | L233 |
| `togglePerishable` | method | lib/features/products/add_product_viewmodel.dart | L235 |
| `_compressImages` | method | lib/features/products/add_product_viewmodel.dart | L237 |
| `_validateAndCompressImage` | method | lib/features/products/add_product_viewmodel.dart | L246 |
| `FirebaseProductRepository` | class | lib/core/repositories/product_repository.dart | L11 |
| `ProductQueryResult` | class | lib/core/repositories/product_repository.dart | L224 |
| `ProductRepository` | abstract_class | lib/core/repositories/product_repository.dart | L232 |
| `addProduct` | method | lib/core/repositories/product_repository.dart | L18 |
| `deleteProduct` | method | lib/core/repositories/product_repository.dart | L58 |
| `fetchProductById` | method | lib/core/repositories/product_repository.dart | L63 |
| `fetchProducts` | method | lib/core/repositories/product_repository.dart | L73 |
| `fetchProductsByIds` | method | lib/core/repositories/product_repository.dart | L100 |
| `getAutocompleteSuggestions` | method | lib/core/repositories/product_repository.dart | L115 |
| `getUploadUrl` | method | lib/core/repositories/product_repository.dart | L126 |
| `submitRating` | method | lib/core/repositories/product_repository.dart | L132 |
| `toggleFavorite` | method | lib/core/repositories/product_repository.dart | L137 |
| `updateProduct` | method | lib/core/repositories/product_repository.dart | L149 |
| `uploadImages` | method | lib/core/repositories/product_repository.dart | L155 |
| `watchFavorites` | method | lib/core/repositories/product_repository.dart | L165 |
| `_uploadSingleImage` | method | lib/core/repositories/product_repository.dart | L200 |
| `addProduct` | method | lib/core/repositories/product_repository.dart | L233 |
| `deleteProduct` | method | lib/core/repositories/product_repository.dart | L234 |
| `fetchProductById` | method | lib/core/repositories/product_repository.dart | L235 |
| `fetchProducts` | method | lib/core/repositories/product_repository.dart | L236 |
| `fetchProductsByIds` | method | lib/core/repositories/product_repository.dart | L237 |
| `getAutocompleteSuggestions` | method | lib/core/repositories/product_repository.dart | L238 |
| `getUploadUrl` | method | lib/core/repositories/product_repository.dart | L239 |
| `submitRating` | method | lib/core/repositories/product_repository.dart | L240 |
| `toggleFavorite` | method | lib/core/repositories/product_repository.dart | L241 |
| `updateProduct` | method | lib/core/repositories/product_repository.dart | L242 |
| `uploadImages` | method | lib/core/repositories/product_repository.dart | L243 |
| `watchFavorites` | method | lib/core/repositories/product_repository.dart | L244 |
| `DeliveryInfo` | class | lib/models/generated/product_models.dart | L42 |
| `InventoryConfig` | class | lib/models/generated/product_models.dart | L65 |
| `Product` | class | lib/models/generated/product_models.dart | L91 |
| `ProductCreate` | class | lib/models/generated/product_models.dart | L159 |
| `SellerDeliveryOption` | class | lib/models/generated/product_models.dart | L202 |
| `ShippingQuantityDiscount` | class | lib/models/generated/product_models.dart | L230 |
| `SupplierInfo` | class | lib/models/generated/product_models.dart | L253 |
| `ProductExtension` | extension | lib/models/generated/product_models.dart | L288 |
| `SellerDeliveryOptionExtension` | extension | lib/models/generated/product_models.dart | L374 |

### Products (Backend) (Python Backend)

| Symbol | Kind | File | Line |
|--------|------|------|------|
| `configure_algolia` | function | functions/handlers/products.py | L474 |
| `delete_product` | function | functions/handlers/products.py | L160 |
| `get_db` | function | functions/handlers/products.py | L33 |
| `get_product_ratings_paginated` | function | functions/handlers/products.py | L705 |
| `get_products_paginated` | function | functions/handlers/products.py | L505 |
| `get_seller_products_paginated` | function | functions/handlers/products.py | L605 |
| `get_server_timestamp` | function | functions/handlers/products.py | L42 |
| `on_product_created` | function | functions/handlers/products.py | L358 |
| `on_product_deleted` | function | functions/handlers/products.py | L460 |
| `on_product_updated` | function | functions/handlers/products.py | L431 |
| `submit_product_rating` | function | functions/handlers/products.py | L237 |
| `update_rating_transaction` | function | functions/handlers/products.py | L325 |
| `upload_product_images` | function | functions/handlers/products.py | L63 |
| `InventoryConfig` | class | functions/models/product.py | L208 |
| `Product` | class | functions/models/product.py | L248 |
| `ProductCreate` | class | functions/models/product.py | L458 |
| `SellerDeliveryOption` | class | functions/models/product.py | L58 |
| `ShippingQuantityDiscount` | class | functions/models/product.py | L16 |
| `SupplierInfo` | class | functions/models/product.py | L131 |
| `validate_seller_address` | member | functions/models/product.py | L530 |
| `validate_description` | member | functions/models/product.py | L448 |
| `validate_discount_type` | member | functions/models/product.py | L51 |
| `validate_image_urls` | member | functions/models/product.py | L439 |
| `validate_status` | member | functions/models/product.py | L431 |
| `validate_supplier_currency` | member | functions/models/product.py | L193 |
| `validate_type` | member | functions/models/product.py | L117 |

## 📋 Orders

### Orders (Frontend) (Dart/Flutter)

| Symbol | Kind | File | Line |
|--------|------|------|------|
| `SellerOrdersViewModel` | class | lib/features/orders/seller_orders_viewmodel.dart | L9 |
| `BuyerOrdersState` | class | lib/features/orders/buyer_orders_viewmodel.dart | L4 |
| `BuyerOrdersViewModel` | class | lib/features/orders/buyer_orders_viewmodel.dart | L20 |
| `SellerOrdersState` | class | lib/features/orders/seller_orders_state.dart | L1 |
| `OrderError` | class | lib/features/orders/orders_provider.dart | L54 |
| `OrderSuccess` | class | lib/features/orders/orders_provider.dart | L66 |
| `ShippingApprovalState` | class | lib/features/orders/shipping_approval_viewmodel.dart | L4 |
| `ShippingApprovalViewModel` | class | lib/features/orders/shipping_approval_viewmodel.dart | L20 |
| `updateShippingAndCapture` | method | lib/features/orders/seller_orders_viewmodel.dart | L14 |
| `updateItemStatus` | method | lib/features/orders/seller_orders_viewmodel.dart | L29 |
| `confirmReceipt` | method | lib/features/orders/buyer_orders_viewmodel.dart | L25 |
| `approveShippingCost` | method | lib/features/orders/shipping_approval_viewmodel.dart | L25 |
| `FirebaseOrderRepository` | class | lib/core/repositories/order_repository.dart | L7 |
| `OrderRepository` | abstract_class | lib/core/repositories/order_repository.dart | L104 |
| `approveShippingCost` | method | lib/core/repositories/order_repository.dart | L14 |
| `capturePayment` | method | lib/core/repositories/order_repository.dart | L19 |
| `confirmReceipt` | method | lib/core/repositories/order_repository.dart | L24 |
| `createCheckoutSession` | method | lib/core/repositories/order_repository.dart | L29 |
| `fetchOrderById` | method | lib/core/repositories/order_repository.dart | L36 |
| `updateItemStatus` | method | lib/core/repositories/order_repository.dart | L43 |
| `updateLastSession` | method | lib/core/repositories/order_repository.dart | L54 |
| `updateShippingCost` | method | lib/core/repositories/order_repository.dart | L63 |
| `watchBuyerOrders` | method | lib/core/repositories/order_repository.dart | L68 |
| `watchPaidOrderBySession` | method | lib/core/repositories/order_repository.dart | L79 |
| `watchSellerOrders` | method | lib/core/repositories/order_repository.dart | L93 |
| `approveShippingCost` | method | lib/core/repositories/order_repository.dart | L105 |
| `capturePayment` | method | lib/core/repositories/order_repository.dart | L106 |
| `confirmReceipt` | method | lib/core/repositories/order_repository.dart | L107 |
| `createCheckoutSession` | method | lib/core/repositories/order_repository.dart | L108 |
| `fetchOrderById` | method | lib/core/repositories/order_repository.dart | L109 |
| `updateItemStatus` | method | lib/core/repositories/order_repository.dart | L110 |
| `updateLastSession` | method | lib/core/repositories/order_repository.dart | L111 |
| `updateShippingCost` | method | lib/core/repositories/order_repository.dart | L112 |
| `watchBuyerOrders` | method | lib/core/repositories/order_repository.dart | L113 |
| `watchPaidOrderBySession` | method | lib/core/repositories/order_repository.dart | L114 |
| `watchSellerOrders` | method | lib/core/repositories/order_repository.dart | L115 |
| `Order` | class | lib/models/generated/order_models.dart | L162 |
| `OrderCreate` | class | lib/models/generated/order_models.dart | L348 |
| `OrderItem` | class | lib/models/generated/order_models.dart | L368 |
| `Ratings` | class | lib/models/generated/order_models.dart | L417 |
| `SellerPayout` | class | lib/models/generated/order_models.dart | L428 |
| `Taxes` | class | lib/models/generated/order_models.dart | L474 |

### Orders (Backend) (Python Backend)

| Symbol | Kind | File | Line |
|--------|------|------|------|
| `approve_shipping_cost` | function | functions/handlers/orders.py | L728 |
| `cancel_order` | function | functions/handlers/orders.py | L397 |
| `confirm_order_receipt` | function | functions/handlers/orders.py | L61 |
| `get_db` | function | functions/handlers/orders.py | L34 |
| `get_firestore` | function | functions/handlers/orders.py | L51 |
| `get_server_timestamp` | function | functions/handlers/orders.py | L43 |
| `on_order_status_changed` | function | functions/handlers/orders.py | L852 |
| `refund_order_item` | function | functions/handlers/orders.py | L518 |
| `update_item_status` | function | functions/handlers/orders.py | L253 |
| `update_order_status` | function | functions/handlers/orders.py | L85 |
| `Order` | class | functions/models/order.py | L122 |
| `OrderCreate` | class | functions/models/order.py | L209 |
| `OrderItem` | class | functions/models/order.py | L14 |
| `Ratings` | class | functions/models/order.py | L80 |
| `SellerPayout` | class | functions/models/order.py | L88 |
| `Taxes` | class | functions/models/order.py | L68 |
| `subtotal` | member | functions/models/order.py | L63 |
| `total` | member | functions/models/order.py | L75 |
| `validate_currency` | member | functions/models/order.py | L203 |
| `validate_status` | member | functions/models/order.py | L115 |
| `auto_archive_old_orders` | function | functions/handlers/cron_jobs.py | L308 |
| `auto_capture_confirmed_receipts` | function | functions/handlers/cron_jobs.py | L57 |
| `check_expired_authorizations` | function | functions/handlers/cron_jobs.py | L237 |
| `check_expired_authorizations_scheduled` | function | functions/handlers/cron_jobs.py | L455 |
| `cleanup_stale_rate_limits` | function | functions/handlers/cron_jobs.py | L415 |
| `get_db` | function | functions/handlers/cron_jobs.py | L34 |
| `get_firestore` | function | functions/handlers/cron_jobs.py | L43 |
| `get_server_timestamp` | function | functions/handlers/cron_jobs.py | L51 |
| `monitor_algolia_sync` | function | functions/handlers/cron_jobs.py | L360 |

## 💳 Payments

### Payments (Frontend) (Dart/Flutter)

| Symbol | Kind | File | Line |
|--------|------|------|------|
| `CheckoutAlreadyProcessed` | class | lib/features/checkout/checkout_provider.dart | L32 |
| `CheckoutError` | class | lib/features/checkout/checkout_provider.dart | L38 |
| `CheckoutNotifier` | class | lib/features/checkout/checkout_provider.dart | L49 |
| `CheckoutState` | class | lib/features/checkout/checkout_provider.dart | L337 |
| `CheckoutSuccess` | class | lib/features/checkout/checkout_provider.dart | L411 |
| `calculateShipping` | method | lib/features/checkout/checkout_provider.dart | L59 |
| `calculateTaxes` | method | lib/features/checkout/checkout_provider.dart | L122 |
| `initialize` | method | lib/features/checkout/checkout_provider.dart | L130 |
| `reset` | method | lib/features/checkout/checkout_provider.dart | L145 |
| `setDeliverySpeed` | method | lib/features/checkout/checkout_provider.dart | L150 |
| `setPaymentProvider` | method | lib/features/checkout/checkout_provider.dart | L156 |
| `startCheckout` | method | lib/features/checkout/checkout_provider.dart | L163 |
| `updateAddress` | method | lib/features/checkout/checkout_provider.dart | L267 |
| `_checkLocalDelivery` | method | lib/features/checkout/checkout_provider.dart | L285 |
| `CartController` | class | lib/features/cart/cart_provider.dart | L179 |
| `canAddToCart` | method | lib/features/cart/cart_provider.dart | L188 |
| `addToCart` | method | lib/features/cart/cart_provider.dart | L205 |
| `clearCart` | method | lib/features/cart/cart_provider.dart | L229 |
| `refreshCart` | method | lib/features/cart/cart_provider.dart | L235 |
| `removeFromCart` | method | lib/features/cart/cart_provider.dart | L239 |
| `updateQuantity` | method | lib/features/cart/cart_provider.dart | L245 |

### Payments (Backend) (Python Backend)

| Symbol | Kind | File | Line |
|--------|------|------|------|
| `PaymentProvider` | class | functions/handlers/payment_providers.py | L80 |
| `airwallex_capture_payment` | function | functions/handlers/payment_airwallex.py | L195 |
| `airwallex_create_seller_account` | function | functions/handlers/payment_airwallex.py | L73 |
| `airwallex_process_payment` | function | functions/handlers/payment_airwallex.py | L116 |
| `airwallex_webhook` | function | functions/handlers/payment_airwallex.py | L249 |
| `capture_payment` | function | functions/handlers/payment_stripe.py | L1462 |
| `create_account_link` | function | functions/handlers/payment_stripe.py | L1364 |
| `create_checkout_session` | function | functions/handlers/payment_stripe.py | L144 |
| `create_connect_account` | function | functions/handlers/payment_stripe.py | L1280 |
| `get_airwallex_service` | function | functions/handlers/payment_airwallex.py | L39 |
| `get_collections` | function | functions/handlers/payment_airwallex.py | L47 |
| `get_connect_account_status` | function | functions/handlers/payment_stripe.py | L1408 |
| `get_db` | function | functions/handlers/payment_airwallex.py | L22 |
| `get_db` | function | functions/handlers/payment_providers.py | L30 |
| `get_db` | function | functions/handlers/payment_stripe.py | L60 |
| `get_enabled_providers` | function | functions/handlers/payment_providers.py | L151 |
| `get_fields` | function | functions/handlers/payment_airwallex.py | L55 |
| `get_payment_providers` | function | functions/handlers/payment_providers.py | L242 |
| `get_provider_status` | function | functions/handlers/payment_providers.py | L406 |
| `get_rate_limiter` | function | functions/handlers/payment_stripe.py | L72 |
| `get_server_timestamp` | function | functions/handlers/payment_airwallex.py | L31 |
| `get_server_timestamp` | function | functions/handlers/payment_providers.py | L39 |
| `get_server_timestamp` | function | functions/handlers/payment_stripe.py | L79 |
| `get_tax_code_for_category` | function | functions/handlers/payment_stripe.py | L534 |
| `get_transactional` | function | functions/handlers/payment_stripe.py | L87 |
| `get_utils` | function | functions/handlers/payment_airwallex.py | L63 |
| `is_provider_enabled` | function | functions/handlers/payment_providers.py | L113 |
| `lock_for_capture` | function | functions/handlers/payment_stripe.py | L1569 |
| `process_account_updated` | function | functions/handlers/payment_stripe.py | L1218 |
| `process_async_payment_failed` | function | functions/handlers/payment_stripe.py | L922 |
| `process_async_payment_succeeded` | function | functions/handlers/payment_stripe.py | L906 |
| `process_charge_refunded` | function | functions/handlers/payment_stripe.py | L1017 |
| `process_checkout_session_completed` | function | functions/handlers/payment_stripe.py | L825 |
| `process_dispute_closed` | function | functions/handlers/payment_stripe.py | L1145 |
| `process_dispute_created` | function | functions/handlers/payment_stripe.py | L1058 |
| `process_payment_intent_failed` | function | functions/handlers/payment_stripe.py | L1001 |
| `process_payment_intent_succeeded` | function | functions/handlers/payment_stripe.py | L985 |
| `process_payout_failed` | function | functions/handlers/payment_stripe.py | L1188 |
| `process_refund_failed` | function | functions/handlers/payment_stripe.py | L1203 |
| `process_session_expired` | function | functions/handlers/payment_stripe.py | L962 |
| `process_transfer_reversed` | function | functions/handlers/payment_stripe.py | L1167 |
| `require_provider_enabled` | function | functions/handlers/payment_providers.py | L186 |
| `reserve_stock_transaction` | function | functions/handlers/payment_stripe.py | L425 |
| `rollback_stock` | function | functions/handlers/payment_stripe.py | L628 |
| `sanitize_metadata` | function | functions/handlers/payment_stripe.py | L1784 |
| `stripe_webhook` | function | functions/handlers/payment_stripe.py | L655 |
| `update_payment_provider` | function | functions/handlers/payment_providers.py | L293 |
| `capture_payment` | function | functions/handlers/payment_stripe.py | L1462 |
| `create_account_link` | function | functions/handlers/payment_stripe.py | L1364 |
| `create_checkout_session` | function | functions/handlers/payment_stripe.py | L144 |
| `create_connect_account` | function | functions/handlers/payment_stripe.py | L1280 |
| `get_connect_account_status` | function | functions/handlers/payment_stripe.py | L1408 |
| `get_db` | function | functions/handlers/payment_stripe.py | L60 |
| `get_rate_limiter` | function | functions/handlers/payment_stripe.py | L72 |
| `get_server_timestamp` | function | functions/handlers/payment_stripe.py | L79 |
| `get_tax_code_for_category` | function | functions/handlers/payment_stripe.py | L534 |
| `get_transactional` | function | functions/handlers/payment_stripe.py | L87 |
| `lock_for_capture` | function | functions/handlers/payment_stripe.py | L1569 |
| `process_account_updated` | function | functions/handlers/payment_stripe.py | L1218 |
| `process_async_payment_failed` | function | functions/handlers/payment_stripe.py | L922 |
| `process_async_payment_succeeded` | function | functions/handlers/payment_stripe.py | L906 |
| `process_charge_refunded` | function | functions/handlers/payment_stripe.py | L1017 |
| `process_checkout_session_completed` | function | functions/handlers/payment_stripe.py | L825 |
| `process_dispute_closed` | function | functions/handlers/payment_stripe.py | L1145 |
| `process_dispute_created` | function | functions/handlers/payment_stripe.py | L1058 |
| `process_payment_intent_failed` | function | functions/handlers/payment_stripe.py | L1001 |
| `process_payment_intent_succeeded` | function | functions/handlers/payment_stripe.py | L985 |
| `process_payout_failed` | function | functions/handlers/payment_stripe.py | L1188 |
| `process_refund_failed` | function | functions/handlers/payment_stripe.py | L1203 |
| `process_session_expired` | function | functions/handlers/payment_stripe.py | L962 |
| `process_transfer_reversed` | function | functions/handlers/payment_stripe.py | L1167 |
| `reserve_stock_transaction` | function | functions/handlers/payment_stripe.py | L425 |
| `rollback_stock` | function | functions/handlers/payment_stripe.py | L628 |
| `sanitize_metadata` | function | functions/handlers/payment_stripe.py | L1784 |
| `stripe_webhook` | function | functions/handlers/payment_stripe.py | L655 |
| `airwallex_capture_payment` | function | functions/handlers/payment_airwallex.py | L195 |
| `airwallex_create_seller_account` | function | functions/handlers/payment_airwallex.py | L73 |
| `airwallex_process_payment` | function | functions/handlers/payment_airwallex.py | L116 |
| `airwallex_webhook` | function | functions/handlers/payment_airwallex.py | L249 |
| `get_airwallex_service` | function | functions/handlers/payment_airwallex.py | L39 |
| `get_collections` | function | functions/handlers/payment_airwallex.py | L47 |
| `get_db` | function | functions/handlers/payment_airwallex.py | L22 |
| `get_fields` | function | functions/handlers/payment_airwallex.py | L55 |
| `get_server_timestamp` | function | functions/handlers/payment_airwallex.py | L31 |
| `get_utils` | function | functions/handlers/payment_airwallex.py | L63 |
| `PaymentProvider` | class | functions/handlers/payment_providers.py | L80 |
| `get_db` | function | functions/handlers/payment_providers.py | L30 |
| `get_enabled_providers` | function | functions/handlers/payment_providers.py | L151 |
| `get_payment_providers` | function | functions/handlers/payment_providers.py | L242 |
| `get_provider_status` | function | functions/handlers/payment_providers.py | L406 |
| `get_server_timestamp` | function | functions/handlers/payment_providers.py | L39 |
| `is_provider_enabled` | function | functions/handlers/payment_providers.py | L113 |
| `require_provider_enabled` | function | functions/handlers/payment_providers.py | L186 |
| `update_payment_provider` | function | functions/handlers/payment_providers.py | L293 |

## 🏪 Seller

### Seller (Frontend) (Dart/Flutter)

| Symbol | Kind | File | Line |
|--------|------|------|------|
| `SellerRegistrationViewModel` | class | lib/features/seller/seller_registration_view_model.dart | L15 |
| `SellerRegistrationState` | class | lib/features/seller/seller_registration_state.dart | L2 |
| `Duration` | method | lib/features/seller/seller_registration_view_model.dart | L23 |
| `continueOnboarding` | method | lib/features/seller/seller_registration_view_model.dart | L58 |
| `openStripeDashboard` | method | lib/features/seller/seller_registration_view_model.dart | L64 |
| `refreshAccountStatus` | method | lib/features/seller/seller_registration_view_model.dart | L83 |
| `setPaymentProvider` | method | lib/features/seller/seller_registration_view_model.dart | L98 |
| `startRegistration` | method | lib/features/seller/seller_registration_view_model.dart | L110 |
| `_continueOnboarding` | method | lib/features/seller/seller_registration_view_model.dart | L145 |

### Seller (Backend) (Python Backend)

| Symbol | Kind | File | Line |
|--------|------|------|------|
| `admin_mfa_disable` | function | functions/handlers/admin.py | L489 |
| `admin_mfa_enroll` | function | functions/handlers/admin.py | L382 |
| `admin_mfa_verify` | function | functions/handlers/admin.py | L434 |
| `delete_account` | function | functions/handlers/admin.py | L538 |
| `get_db` | function | functions/handlers/admin.py | L24 |
| `get_delete_field` | function | functions/handlers/admin.py | L41 |
| `get_server_timestamp` | function | functions/handlers/admin.py | L33 |
| `restore_stock_batch` | function | functions/handlers/admin.py | L346 |
| `suspend_seller` | function | functions/handlers/admin.py | L195 |
| `update_user_roles` | function | functions/handlers/admin.py | L86 |

## 🛒 Cart

### Cart (Frontend) (Dart/Flutter)

| Symbol | Kind | File | Line |
|--------|------|------|------|
| `CartController` | class | lib/features/cart/cart_provider.dart | L179 |
| `canAddToCart` | method | lib/features/cart/cart_provider.dart | L188 |
| `addToCart` | method | lib/features/cart/cart_provider.dart | L205 |
| `clearCart` | method | lib/features/cart/cart_provider.dart | L229 |
| `refreshCart` | method | lib/features/cart/cart_provider.dart | L235 |
| `removeFromCart` | method | lib/features/cart/cart_provider.dart | L239 |
| `updateQuantity` | method | lib/features/cart/cart_provider.dart | L245 |
| `CartRepository` | abstract_class | lib/core/repositories/cart_repository.dart | L5 |
| `FirebaseCartRepository` | class | lib/core/repositories/cart_repository.dart | L13 |
| `watchCart` | method | lib/core/repositories/cart_repository.dart | L6 |
| `addToCart` | method | lib/core/repositories/cart_repository.dart | L7 |
| `updateQuantity` | method | lib/core/repositories/cart_repository.dart | L8 |
| `removeFromCart` | method | lib/core/repositories/cart_repository.dart | L9 |
| `clearCart` | method | lib/core/repositories/cart_repository.dart | L10 |
| `watchCart` | method | lib/core/repositories/cart_repository.dart | L21 |
| `addToCart` | method | lib/core/repositories/cart_repository.dart | L33 |
| `updateQuantity` | method | lib/core/repositories/cart_repository.dart | L52 |
| `removeFromCart` | method | lib/core/repositories/cart_repository.dart | L62 |
| `clearCart` | method | lib/core/repositories/cart_repository.dart | L67 |

## 🏗️ Core & Schema

### Core (Frontend) (Dart/Flutter)

| Symbol | Kind | File | Line |
|--------|------|------|------|
| `CartRepository` | abstract_class | lib/core/repositories/cart_repository.dart | L5 |
| `FirebaseCartRepository` | class | lib/core/repositories/cart_repository.dart | L13 |
| `AlgoliaProductRepository` | class | lib/core/repositories/algolia_product_repository.dart | L12 |
| `FirebaseOrderRepository` | class | lib/core/repositories/order_repository.dart | L7 |
| `OrderRepository` | abstract_class | lib/core/repositories/order_repository.dart | L104 |
| `LocationRepository` | abstract_class | lib/core/repositories/location_repository.dart | L5 |
| `GeoapifyLocationRepository` | class | lib/core/repositories/location_repository.dart | L9 |
| `AuthRepository` | abstract_class | lib/core/repositories/auth_repository.dart | L12 |
| `FirebaseAuthRepository` | class | lib/core/repositories/auth_repository.dart | L34 |
| `FirebaseUserRepository` | class | lib/core/repositories/user_repository.dart | L5 |
| `SellerAccountStatus` | class | lib/core/repositories/user_repository.dart | L52 |
| `UserRepository` | abstract_class | lib/core/repositories/user_repository.dart | L108 |
| `FirebaseProductRepository` | class | lib/core/repositories/product_repository.dart | L11 |
| `ProductQueryResult` | class | lib/core/repositories/product_repository.dart | L224 |
| `ProductRepository` | abstract_class | lib/core/repositories/product_repository.dart | L232 |
| `watchCart` | method | lib/core/repositories/cart_repository.dart | L6 |
| `addToCart` | method | lib/core/repositories/cart_repository.dart | L7 |
| `updateQuantity` | method | lib/core/repositories/cart_repository.dart | L8 |
| `removeFromCart` | method | lib/core/repositories/cart_repository.dart | L9 |
| `clearCart` | method | lib/core/repositories/cart_repository.dart | L10 |
| `watchCart` | method | lib/core/repositories/cart_repository.dart | L21 |
| `addToCart` | method | lib/core/repositories/cart_repository.dart | L33 |
| `updateQuantity` | method | lib/core/repositories/cart_repository.dart | L52 |
| `removeFromCart` | method | lib/core/repositories/cart_repository.dart | L62 |
| `clearCart` | method | lib/core/repositories/cart_repository.dart | L67 |
| `addProduct` | method | lib/core/repositories/algolia_product_repository.dart | L21 |
| `deleteProduct` | method | lib/core/repositories/algolia_product_repository.dart | L46 |
| `fetchProductById` | method | lib/core/repositories/algolia_product_repository.dart | L51 |
| `fetchProducts` | method | lib/core/repositories/algolia_product_repository.dart | L63 |
| `fetchProductsByIds` | method | lib/core/repositories/algolia_product_repository.dart | L86 |
| `getAutocompleteSuggestions` | method | lib/core/repositories/algolia_product_repository.dart | L99 |
| `getUploadUrl` | method | lib/core/repositories/algolia_product_repository.dart | L114 |
| `submitRating` | method | lib/core/repositories/algolia_product_repository.dart | L119 |
| `toggleFavorite` | method | lib/core/repositories/algolia_product_repository.dart | L130 |
| `updateProduct` | method | lib/core/repositories/algolia_product_repository.dart | L142 |
| `uploadImages` | method | lib/core/repositories/algolia_product_repository.dart | L147 |
| `watchFavorites` | method | lib/core/repositories/algolia_product_repository.dart | L152 |
| `_fetchFromFirestore` | method | lib/core/repositories/algolia_product_repository.dart | L161 |
| `_searchWithAlgolia` | method | lib/core/repositories/algolia_product_repository.dart | L199 |
| `approveShippingCost` | method | lib/core/repositories/order_repository.dart | L14 |
| `capturePayment` | method | lib/core/repositories/order_repository.dart | L19 |
| `confirmReceipt` | method | lib/core/repositories/order_repository.dart | L24 |
| `createCheckoutSession` | method | lib/core/repositories/order_repository.dart | L29 |
| `fetchOrderById` | method | lib/core/repositories/order_repository.dart | L36 |
| `updateItemStatus` | method | lib/core/repositories/order_repository.dart | L43 |
| `updateLastSession` | method | lib/core/repositories/order_repository.dart | L54 |
| `updateShippingCost` | method | lib/core/repositories/order_repository.dart | L63 |
| `watchBuyerOrders` | method | lib/core/repositories/order_repository.dart | L68 |
| `watchPaidOrderBySession` | method | lib/core/repositories/order_repository.dart | L79 |
| `watchSellerOrders` | method | lib/core/repositories/order_repository.dart | L93 |
| `approveShippingCost` | method | lib/core/repositories/order_repository.dart | L105 |
| `capturePayment` | method | lib/core/repositories/order_repository.dart | L106 |
| `confirmReceipt` | method | lib/core/repositories/order_repository.dart | L107 |
| `createCheckoutSession` | method | lib/core/repositories/order_repository.dart | L108 |
| `fetchOrderById` | method | lib/core/repositories/order_repository.dart | L109 |
| `updateItemStatus` | method | lib/core/repositories/order_repository.dart | L110 |
| `updateLastSession` | method | lib/core/repositories/order_repository.dart | L111 |
| `updateShippingCost` | method | lib/core/repositories/order_repository.dart | L112 |
| `watchBuyerOrders` | method | lib/core/repositories/order_repository.dart | L113 |
| `watchPaidOrderBySession` | method | lib/core/repositories/order_repository.dart | L114 |
| `watchSellerOrders` | method | lib/core/repositories/order_repository.dart | L115 |
| `getAddressSuggestions` | method | lib/core/repositories/location_repository.dart | L6 |
| `getAddressSuggestions` | method | lib/core/repositories/location_repository.dart | L11 |
| `deleteAccount` | method | lib/core/repositories/auth_repository.dart | L13 |
| `isEmailVerified` | method | lib/core/repositories/auth_repository.dart | L16 |
| `registerWithEmail` | method | lib/core/repositories/auth_repository.dart | L17 |
| `sendEmailVerification` | method | lib/core/repositories/auth_repository.dart | L22 |
| `sendPasswordResetEmail` | method | lib/core/repositories/auth_repository.dart | L23 |
| `signInWithEmail` | method | lib/core/repositories/auth_repository.dart | L24 |
| `signInWithGoogle` | method | lib/core/repositories/auth_repository.dart | L25 |
| `signOut` | method | lib/core/repositories/auth_repository.dart | L26 |
| `watchProfile` | method | lib/core/repositories/auth_repository.dart | L27 |
| `validateCurrentUser` | method | lib/core/repositories/auth_repository.dart | L31 |
| `deleteAccount` | method | lib/core/repositories/auth_repository.dart | L42 |
| `ensureUserDocumentExists` | method | lib/core/repositories/auth_repository.dart | L53 |
| `isEmailVerified` | method | lib/core/repositories/auth_repository.dart | L84 |
| `registerWithEmail` | method | lib/core/repositories/auth_repository.dart | L103 |
| `sendEmailVerification` | method | lib/core/repositories/auth_repository.dart | L159 |
| `sendPasswordResetEmail` | method | lib/core/repositories/auth_repository.dart | L203 |
| `signInWithEmail` | method | lib/core/repositories/auth_repository.dart | L233 |
| `signInWithGoogle` | method | lib/core/repositories/auth_repository.dart | L264 |
| `signOut` | method | lib/core/repositories/auth_repository.dart | L281 |
| `validateCurrentUser` | method | lib/core/repositories/auth_repository.dart | L286 |
| `watchProfile` | method | lib/core/repositories/auth_repository.dart | L342 |
| `_createUserDocumentIfNeeded` | method | lib/core/repositories/auth_repository.dart | L351 |
| `getSellerAccountStatus` | method | lib/core/repositories/user_repository.dart | L11 |
| `watchSellerAccountStatus` | method | lib/core/repositories/user_repository.dart | L17 |
| `getUserProfile` | method | lib/core/repositories/user_repository.dart | L40 |
| `updateAddress` | method | lib/core/repositories/user_repository.dart | L47 |
| `getSellerAccountStatus` | method | lib/core/repositories/user_repository.dart | L109 |
| `watchSellerAccountStatus` | method | lib/core/repositories/user_repository.dart | L110 |
| `getUserProfile` | method | lib/core/repositories/user_repository.dart | L111 |
| `updateAddress` | method | lib/core/repositories/user_repository.dart | L112 |
| `addProduct` | method | lib/core/repositories/product_repository.dart | L18 |
| `deleteProduct` | method | lib/core/repositories/product_repository.dart | L58 |
| `fetchProductById` | method | lib/core/repositories/product_repository.dart | L63 |
| `fetchProducts` | method | lib/core/repositories/product_repository.dart | L73 |
| `fetchProductsByIds` | method | lib/core/repositories/product_repository.dart | L100 |
| `getAutocompleteSuggestions` | method | lib/core/repositories/product_repository.dart | L115 |
| `getUploadUrl` | method | lib/core/repositories/product_repository.dart | L126 |
| `submitRating` | method | lib/core/repositories/product_repository.dart | L132 |
| `toggleFavorite` | method | lib/core/repositories/product_repository.dart | L137 |
| `updateProduct` | method | lib/core/repositories/product_repository.dart | L149 |
| `uploadImages` | method | lib/core/repositories/product_repository.dart | L155 |
| `watchFavorites` | method | lib/core/repositories/product_repository.dart | L165 |
| `_uploadSingleImage` | method | lib/core/repositories/product_repository.dart | L200 |
| `addProduct` | method | lib/core/repositories/product_repository.dart | L233 |
| `deleteProduct` | method | lib/core/repositories/product_repository.dart | L234 |
| `fetchProductById` | method | lib/core/repositories/product_repository.dart | L235 |
| `fetchProducts` | method | lib/core/repositories/product_repository.dart | L236 |
| `fetchProductsByIds` | method | lib/core/repositories/product_repository.dart | L237 |
| `getAutocompleteSuggestions` | method | lib/core/repositories/product_repository.dart | L238 |
| `getUploadUrl` | method | lib/core/repositories/product_repository.dart | L239 |
| `submitRating` | method | lib/core/repositories/product_repository.dart | L240 |
| `toggleFavorite` | method | lib/core/repositories/product_repository.dart | L241 |
| `updateProduct` | method | lib/core/repositories/product_repository.dart | L242 |
| `uploadImages` | method | lib/core/repositories/product_repository.dart | L243 |
| `watchFavorites` | method | lib/core/repositories/product_repository.dart | L244 |

### Schema & Config (Backend) (Python Backend)

| Symbol | Kind | File | Line |
|--------|------|------|------|
| `ApiKeys` | class | functions/schema_constants.py | L496 |
| `BusinessRules` | class | functions/schema_constants.py | L437 |
| `CategoryIds` | class | functions/schema_constants.py | L468 |
| `Collections` | class | functions/schema_constants.py | L35 |
| `DeliveryStatusValues` | class | functions/schema_constants.py | L315 |
| `Fields` | class | functions/schema_constants.py | L59 |
| `OrderStatusValues` | class | functions/schema_constants.py | L275 |
| `PaymentStatusValues` | class | functions/schema_constants.py | L295 |
| `PayoutStatusValues` | class | functions/schema_constants.py | L325 |
| `ProductStatusValues` | class | functions/schema_constants.py | L349 |
| `SchemaRegistry` | class | functions/schema_constants.py | L383 |
| `ShippingApprovalStatusValues` | class | functions/schema_constants.py | L360 |
| `UserRoleValues` | class | functions/schema_constants.py | L340 |
| `WebhookStatusValues` | class | functions/schema_constants.py | L370 |
| `get_timestamp_field` | member | functions/schema_constants.py | L421 |
| `validate_field_name` | member | functions/schema_constants.py | L426 |
| `AlgoliaConfig` | class | functions/config.py | L185 |
| `CaptureMethod` | class | functions/config.py | L119 |
| `Collections` | class | functions/config.py | L94 |
| `DeliveryStatus` | class | functions/config.py | L83 |
| `Environment` | class | functions/config.py | L37 |
| `OrderStatus` | class | functions/config.py | L58 |
| `PaymentStatus` | class | functions/config.py | L71 |
| `PayoutStatus` | class | functions/config.py | L110 |
| `R2Config` | class | functions/config.py | L143 |
| `ShippingApprovalStatus` | class | functions/config.py | L123 |
| `StripeConfig` | class | functions/config.py | L225 |
| `UserRoles` | class | functions/config.py | L89 |
| `get_environment` | function | functions/config.py | L46 |
| `get_image_path` | member | functions/config.py | L163 |
| `get_index_name` | member | functions/config.py | L193 |
| `get_products_folder` | member | functions/config.py | L153 |
| `get_r2_credentials` | function | functions/config.py | L302 |
| `get_users_folder` | member | functions/config.py | L158 |
| `is_emulator` | function | functions/config.py | L50 |
| `is_test_mode` | member | functions/config.py | L229 |
| `print_env_info` | function | functions/config.py | L344 |
| `create_error_response` | function | functions/utils.py | L21 |
| `create_success_response` | function | functions/utils.py | L17 |
| `is_valid_order_status_transition` | function | functions/utils.py | L286 |
| `log_webhook_to_database` | function | functions/utils.py | L253 |
| `sanitize_email` | function | functions/utils.py | L127 |
| `sanitize_error_log` | function | functions/utils/log_sanitizer.py | L46 |
| `sanitize_log_data` | function | functions/utils/log_sanitizer.py | L9 |
| `sanitize_path` | function | functions/utils.py | L88 |
| `sanitize_text` | function | functions/utils.py | L112 |
| `sanitized_text` | function | functions/utils.py | L55 |
| `validate_address_map` | function | functions/utils.py | L171 |
| `validate_item` | function | functions/utils.py | L182 |
| `validate_message` | function | functions/utils.py | L157 |
| `validate_name` | function | functions/utils.py | L139 |
| `validate_order_data` | function | functions/utils.py | L206 |
| `validate_phone` | function | functions/utils.py | L147 |
| `validate_postal_code` | function | functions/utils.py | L163 |

## ⚙️ Services

### Services (Frontend) (Dart/Flutter)

| Symbol | Kind | File | Line |
|--------|------|------|------|
| `SplashManager` | class | lib/services/splash_manager_web.dart | L3 |
| `SessionTimeoutService` | class | lib/services/session_timeout_service.dart | L11 |
| `SplashManager` | class | lib/services/splash_manager_stub.dart | L1 |
| `SplashService` | class | lib/services/splash_service.dart | L4 |
| `AlgoliaService` | class | lib/services/algolia_service.dart | L7 |
| `ConfigService` | class | lib/services/conf_services.dart | L3 |

### Services (Backend) (Python Backend)

| Symbol | Kind | File | Line |
|--------|------|------|------|
| `calculate_shipping_cost` | function | functions/shipping_service.py | L373 |
| `estimate_delivery_date_range` | function | functions/shipping_service.py | L133 |
| `get_international_shipping_estimate` | function | functions/shipping_service.py | L99 |
| `get_tax_rate` | function | functions/shipping_service.py | L94 |
| `get_order_confirmation_email` | function | functions/email_service.py | L13 |
| `get_seller_notification_email` | function | functions/email_service.py | L228 |
| `send_3ds_authentication_email` | function | functions/email_service.py | L680 |
| `send_authorization_expired_email` | function | functions/email_service.py | L493 |
| `send_email` | function | functions/email_service.py | L451 |
| `send_payment_capture_failed_email` | function | functions/email_service.py | L550 |
| `batch_index_products` | function | functions/algolia_service.py | L189 |
| `configure_algolia_index` | function | functions/algolia_service.py | L221 |
| `delete_product` | function | functions/algolia_service.py | L152 |
| `format_product_for_algolia` | function | functions/algolia_service.py | L20 |
| `index_product` | function | functions/algolia_service.py | L107 |
| `RateLimiter` | class | functions/rate_limiter.py | L9 |
| `check_and_increment` | function | functions/rate_limiter.py | L43 |
| `check_rate_limit` | member | functions/rate_limiter.py | L16 |
| `get_identifier` | member | functions/rate_limiter.py | L93 |
| `AirwallexService` | class | functions/airwallex_service.py | L22 |
| `cancel_payment` | member | functions/airwallex_service.py | L214 |
| `capture_payment` | member | functions/airwallex_service.py | L183 |
| `create_connected_account` | member | functions/airwallex_service.py | L83 |
| `create_customer` | member | functions/airwallex_service.py | L64 |
| `create_payment_intent` | member | functions/airwallex_service.py | L148 |
| `create_payment_intent_for_checkout` | member | functions/airwallex_service.py | L105 |
| `create_payout` | member | functions/airwallex_service.py | L225 |
| `get_airwallex_service` | function | functions/airwallex_service.py | L549 |
| `get_payout_status` | member | functions/airwallex_service.py | L248 |
| `handle_webhook_event` | member | functions/airwallex_service.py | L316 |
| `refund_payment` | member | functions/airwallex_service.py | L198 |
| `verify_webhook_signature` | member | functions/airwallex_service.py | L259 |

## 🧊 Freezed Models (Generated)

```
product_models.dart:66:  const factory InventoryConfig({
product_models.dart:83:  factory InventoryConfig.fromJson(Map<String, dynamic> json) => _$InventoryConfigFromJson(json);
product_models.dart:92:  const factory Product({
product_models.dart:137:  factory Product.fromFirestore(DocumentSnapshot doc) {
product_models.dart:151:  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
product_models.dart:160:  const factory ProductCreate({
product_models.dart:194:  factory ProductCreate.fromJson(Map<String, dynamic> json) => _$ProductCreateFromJson(json);
product_models.dart:203:  const factory SellerDeliveryOption({
product_models.dart:222:  factory SellerDeliveryOption.fromJson(Map<String, dynamic> json) => _$SellerDeliveryOptionFromJson(json);
product_models.dart:231:  const factory ShippingQuantityDiscount({
product_models.dart:245:  factory ShippingQuantityDiscount.fromJson(Map<String, dynamic> json) => _$ShippingQuantityDiscountFromJson(json);
product_models.dart:254:  const factory SupplierInfo({
product_models.dart:281:  factory SupplierInfo.fromJson(Map<String, dynamic> json) => _$SupplierInfoFromJson(json);
user_models.dart:28:  const factory User({
user_models.dart:51:  factory User.fromFirestore(DocumentSnapshot doc) {
user_models.dart:79:  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
user_models.dart:99:  const factory UserCreate({required String email, required String name, @Default([UserRole.buyer]) List<UserRole> roles, Address? address}) = _UserCreate;
user_models.dart:101:  factory UserCreate.fromJson(Map<String, dynamic> json) => _$UserCreateFromJson(json);
base_models.dart:16:  const factory Address({
base_models.dart:30:  factory Address.fromJson(Map<String, dynamic> json) => _$AddressFromJson(json);
base_models.dart:49:  const factory AddressDetails({
base_models.dart:58:  factory AddressDetails.fromJson(Map<String, dynamic> json) => _$AddressDetailsFromJson(json);
order_models.dart:163:  const factory Order({
order_models.dart:197:  factory Order.fromFirestore(DocumentSnapshot doc) {
order_models.dart:326:  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
order_models.dart:349:  const factory OrderCreate({
order_models.dart:360:  factory OrderCreate.fromJson(Map<String, dynamic> json) => _$OrderCreateFromJson(json);
order_models.dart:369:  const factory OrderItem({
order_models.dart:404:  factory OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);
order_models.dart:418:  const factory Ratings({required String productId, required double rating, String? review, required DateTime createdAt}) = _Ratings;
order_models.dart:420:  factory Ratings.fromJson(Map<String, dynamic> json) => _$RatingsFromJson(json);
order_models.dart:429:  const factory SellerPayout({
order_models.dart:441:  factory SellerPayout.fromJson(Map<String, dynamic> json) => _$SellerPayoutFromJson(json);
order_models.dart:443:  factory SellerPayout.fromMap(Map<String, dynamic> map) {
order_models.dart:475:  const factory Taxes({@Default(0.0) double gst, @Default(0.0) double pst, @Default(0.0) double hst, @Default(0.0) double qst}) = _Taxes;
order_models.dart:477:  factory Taxes.fromJson(Map<String, dynamic> json) {
order_models.dart:486:  factory Taxes.fromMap(Map<String, dynamic> map) =>
```

## 🐍 Pydantic Models

```
models/user.py:12:class User(BaseModel):
models/user.py:173:class UserCreate(BaseModel):
models/order.py:14:class OrderItem(BaseModel):
models/order.py:68:class Taxes(BaseModel):
models/order.py:80:class Ratings(BaseModel):
models/order.py:88:class SellerPayout(BaseModel):
models/order.py:122:class Order(BaseModel):
models/order.py:209:class OrderCreate(BaseModel):
models/product.py:16:class ShippingQuantityDiscount(BaseModel):
models/product.py:58:class SellerDeliveryOption(BaseModel):
models/product.py:131:class SupplierInfo(BaseModel):
models/product.py:208:class InventoryConfig(BaseModel):
models/product.py:248:class Product(BaseModel):
models/product.py:458:class ProductCreate(BaseModel):
models/base.py:73:class Address(BaseModel):
models/base.py:210:class AddressDetails(BaseModel):
```

## 🔌 Riverpod Providers

```
core/repositories/auth_repository.dart:265:    final googleProvider = GoogleAuthProvider();
core/providers.dart:17:final algoliaProductRepositoryProvider = Provider<ProductRepository>((ref) {
core/providers.dart:26:final algoliaServiceProvider = Provider<AlgoliaService>((ref) {
core/providers.dart:35:final authRepositoryProvider = Provider<AuthRepository>((ref) {
core/providers.dart:43:final authStateProvider = StreamProvider<User?>((ref) => ref.watch(firebaseAuthProvider).authStateChanges());
core/providers.dart:45:final cartRepositoryProvider = Provider<CartRepository>((ref) {
core/providers.dart:49:final currentUserProvider = Provider<User?>((ref) => ref.watch(authStateProvider).valueOrNull);
core/providers.dart:55:final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
core/providers.dart:57:final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
core/providers.dart:67:final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
core/providers.dart:69:final locationRepositoryProvider = Provider<LocationRepository>((ref) {
core/providers.dart:73:final orderRepositoryProvider = Provider<OrderRepository>((ref) {
core/providers.dart:78:final productRepositoryProvider = Provider<ProductRepository>((ref) {
core/providers.dart:88:final userIdProvider = Provider<String?>((ref) => ref.watch(currentUserProvider)?.uid);
core/providers.dart:89:final userRepositoryProvider = Provider<UserRepository>((ref) {
features/seller/seller_registration_view_model.dart:11:final sellerRegistrationViewModelProvider = StateNotifierProvider.autoDispose<SellerRegistrationViewModel, SellerRegistrationState>((ref) {
features/seller/seller_registration_view_model.dart:86:      final functions = _ref.read(firebaseFunctionsProvider);
features/seller/seller_registration_view_model.dart:102:      final functions = _ref.read(firebaseFunctionsProvider);
features/seller/seller_registration_view_model.dart:118:      final functions = _ref.read(firebaseFunctionsProvider);
features/seller/seller_registration_view_model.dart:159:      final functions = _ref.read(firebaseFunctionsProvider);
features/seller/seller_registration_state.dart:6:  final String paymentProvider;
features/home/home_viewmodel.dart:9:final homeViewModelProvider = StateNotifierProvider.autoDispose<HomeViewModel, HomeState>((ref) {
features/home/home_viewmodel.dart:41:      final repository = _ref.read(productRepositoryProvider);
features/products/product_actions_viewmodel.dart:16:final productActionsViewModelProvider = StateNotifierProvider.autoDispose<ProductActionsViewModel, ProductActionsState>((ref) {
features/products/edit_product_viewmodel.dart:11:final editProductViewModelProvider = StateNotifierProvider.autoDispose.family<EditProductViewModel, EditProductState, models.Product>((ref, product) {
features/products/product_rating_viewmodel.dart:16:final productRatingViewModelProvider = StateNotifierProvider.autoDispose<ProductRatingViewModel, ProductRatingState>((ref) {
features/products/product_detail_viewmodel.dart:23:final productDetailViewModelProvider =
features/products/products_provider.dart:11:final favoritedProductsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
features/products/products_provider.dart:12:  final favoriteIds = ref.watch(favoritesProvider).valueOrNull ?? {};
features/products/products_provider.dart:15:  final repository = ref.watch(productRepositoryProvider);
features/products/products_provider.dart:20:final favoritesControllerProvider = Provider<FavoritesController>((ref) {
features/products/products_provider.dart:29:final favoritesProvider = StreamProvider.autoDispose<Set<String>>((ref) {
features/products/products_provider.dart:30:  final userId = ref.watch(userIdProvider);
features/products/products_provider.dart:33:  final repository = ref.watch(productRepositoryProvider);
features/products/products_provider.dart:38:final filteredProductsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
features/products/products_provider.dart:39:  final categoryId = ref.watch(selectedCategoryProvider);
features/products/products_provider.dart:40:  final searchQuery = ref.watch(searchQueryProvider);
features/products/products_provider.dart:48:final productByIdProvider = FutureProvider.autoDispose.family<Product?, String>((ref, productId) async {
features/products/products_provider.dart:49:  final repository = ref.watch(productRepositoryProvider);
features/products/products_provider.dart:54:final productsProvider = FutureProvider.autoDispose.family<List<Product>, ProductQuery>((ref, query) async {
features/products/products_provider.dart:55:  final repository = ref.watch(productRepositoryProvider);
features/products/products_provider.dart:65:final searchQueryProvider = StateProvider<String>((ref) => '');
features/products/products_provider.dart:68:final selectedCategoryProvider = StateProvider<int?>((ref) => null);
features/products/products_provider.dart:80:    final favorites = _ref.read(favoritesProvider).valueOrNull ?? {};
features/products/add_product_viewmodel.dart:13:final addProductViewModelProvider = StateNotifierProvider.autoDispose<AddProductViewModel, AddProductState>((ref) {
features/products/add_product_viewmodel.dart:118:      final productRepository = _ref.read(productRepositoryProvider);
features/products/add_product_viewmodel.dart:191:    final suggestions = await _ref.read(locationRepositoryProvider).getAddressSuggestions(value);
features/app/seller_account_status_viewmodel.dart:10:final sellerAccountStatusProvider = StreamProvider.autoDispose<SellerAccountStatus>((ref) {
features/app/seller_account_status_viewmodel.dart:11:  final user = ref.watch(currentUserProvider);
features/app/seller_account_status_viewmodel.dart:23:final refreshSellerStatusProvider = FutureProvider.family.autoDispose<SellerAccountStatus, void>((ref, _) async {
features/app/seller_account_status_viewmodel.dart:24:  final user = ref.watch(currentUserProvider);
features/app/seller_account_status_viewmodel.dart:32:    final functions = ref.read(firebaseFunctionsProvider);
features/auth/auth_provider.dart:10:final userProfileProvider = StreamProvider.autoDispose<UserModel?>((ref) {
features/auth/auth_provider.dart:11:  final userId = ref.watch(userIdProvider);
features/auth/auth_provider.dart:14:  final repository = ref.watch(authRepositoryProvider);
features/auth/login_viewmodel.dart:7:final loginViewModelProvider = StateNotifierProvider.autoDispose<LoginViewModel, LoginState>((ref) {
features/auth/login_viewmodel.dart:51:    final repository = _ref.read(authRepositoryProvider);
features/auth/login_viewmodel.dart:115:    final repository = _ref.read(authRepositoryProvider);
features/terms/terms_provider.dart:100:final termsProvider = FutureProvider<String>((ref) async {
features/checkout/checkout_provider.dart:14:final checkoutStateProvider = StateNotifierProvider.autoDispose<CheckoutNotifier, CheckoutState>((ref) {
features/checkout/checkout_provider.dart:19:final checkoutTaxRateProvider = Provider.autoDispose<double>((ref) {
features/checkout/checkout_provider.dart:20:  final checkoutState = ref.watch(checkoutStateProvider);
features/checkout/checkout_provider.dart:26:final checkoutTotalProvider = Provider.autoDispose<double>((ref) {
features/checkout/checkout_provider.dart:27:  final checkoutState = ref.watch(checkoutStateProvider);
features/checkout/checkout_provider.dart:28:  final subtotal = ref.watch(cartSubtotalProvider);
features/checkout/checkout_provider.dart:184:      final authRepository = _ref.read(authRepositoryProvider);
features/checkout/checkout_provider.dart:349:  final String paymentProvider;
features/profile/profile_viewmodel.dart:5:final profileViewModelProvider = StateNotifierProvider.autoDispose<ProfileViewModel, ProfileState>((ref) {
features/profile/address_viewmodel.dart:6:final addressViewModelProvider = StateNotifierProvider.autoDispose<AddressViewModel, AddressState>((ref) {
features/profile/address_viewmodel.dart:34:    final suggestions = await _ref.read(locationRepositoryProvider).getAddressSuggestions(value);
features/profile/address_viewmodel.dart:50:    final userId = _ref.read(userIdProvider);
features/cart/cart_provider.dart:8:final cartControllerProvider = Provider<CartController>((ref) {
features/cart/cart_provider.dart:12:final cartItemCountProvider = Provider<int>((ref) {
features/cart/cart_provider.dart:13:  final cartItems = ref.watch(cartItemsProvider);
features/cart/cart_provider.dart:18:final cartItemDateProvider = Provider.autoDispose.family<Timestamp?, String>((ref, productId) {
features/cart/cart_provider.dart:27:final cartItemDetailProvider = FutureProvider.autoDispose.family<CartItemDetailModel?, String>((ref, productId) async {
features/cart/cart_provider.dart:28:  final firestore = ref.watch(firestoreProvider);
features/cart/cart_provider.dart:29:  final createdAt = ref.watch(cartItemDateProvider(productId));
features/cart/cart_provider.dart:79:final cartItemQuantityProvider = StreamProvider.autoDispose.family<int, String>((ref, productId) {
features/cart/cart_provider.dart:80:  final userId = ref.watch(userIdProvider);
features/cart/cart_provider.dart:93:final cartItemsProvider = StreamProvider.autoDispose<List<CartItemModel>>((ref) {
features/cart/cart_provider.dart:94:  final userId = ref.watch(userIdProvider);
features/cart/cart_provider.dart:101:final cartSubtotalProvider = Provider<double>((ref) {
features/cart/cart_provider.dart:102:  final cartDetails = ref.watch(cartWithDetailsProvider);
features/cart/cart_provider.dart:111:final cartWithDetailsProvider = FutureProvider.autoDispose<List<CartItemDetailModel>>((ref) async {
features/cart/cart_provider.dart:112:  final cartItems = ref.watch(cartItemsProvider);
features/cart/cart_provider.dart:113:  final firestore = ref.watch(firestoreProvider);
features/cart/cart_provider.dart:193:      final firestore = _ref.read(firestoreProvider);
features/cart/cart_provider.dart:211:      final firestore = _ref.read(firestoreProvider);
features/orders/seller_orders_viewmodel.dart:5:final sellerOrdersViewModelProvider = StateNotifierProvider.autoDispose<SellerOrdersViewModel, SellerOrdersState>((ref) {
features/orders/seller_orders_viewmodel.dart:17:    final repository = _ref.read(orderRepositoryProvider);
features/orders/seller_orders_viewmodel.dart:32:    final repository = _ref.read(orderRepositoryProvider);
features/orders/buyer_orders_viewmodel.dart:16:final buyerOrdersViewModelProvider = StateNotifierProvider.autoDispose<BuyerOrdersViewModel, BuyerOrdersState>((ref) {
features/orders/orders_provider.dart:9:final buyerOrdersProvider = StreamProvider.autoDispose<List<models.Order>>((ref) {
features/orders/orders_provider.dart:10:  final userId = ref.watch(userIdProvider);
features/orders/orders_provider.dart:20:final orderByIdProvider = FutureProvider.autoDispose.family<models.Order?, String>((ref, orderId) async {
features/orders/orders_provider.dart:25:final paidOrderBySessionProvider = StreamProvider.autoDispose.family<models.Order?, String>((ref, sessionId) {
features/orders/orders_provider.dart:29:final pendingApprovalsCountProvider = Provider.autoDispose<int>((ref) {
features/orders/orders_provider.dart:30:  final ordersAsync = ref.watch(buyerOrdersProvider);
features/orders/orders_provider.dart:37:final pendingShippingApprovalsProvider = Provider.autoDispose<AsyncValue<List<models.Order>>>((ref) {
features/orders/orders_provider.dart:47:final sellerOrdersProvider = StreamProvider.autoDispose<List<models.Order>>((ref) {
features/orders/orders_provider.dart:48:  final userId = ref.watch(userIdProvider);
features/orders/shipping_approval_viewmodel.dart:16:final shippingApprovalViewModelProvider = StateNotifierProvider.autoDispose<ShippingApprovalViewModel, ShippingApprovalState>((ref) {
admin/tabs/admin_products_tab.dart:274:    final success = await ref.read(adminActionsViewModelProvider.notifier).updateProductStock(product.id, quantity);
admin/tabs/admin_products_tab.dart:284:      final error = ref.read(adminActionsViewModelProvider).errorMessage ?? 'Failed to update stock';
admin/tabs/admin_products_tab.dart:308:              final success = await ref.read(adminActionsViewModelProvider.notifier).deleteProduct(product.id);
admin/tabs/admin_products_tab.dart:313:                final error = ref.read(adminActionsViewModelProvider).errorMessage ?? 'Failed to delete product';
admin/tabs/admin_products_tab.dart:356:    final sellerData = await ref.read(adminActionsViewModelProvider.notifier).fetchUserById(sellerId);
admin/tabs/admin_payment_providers_tab.dart:344:    final enabledProviders = _providersData?[ApiKeys.enabledProviders] as List<dynamic>? ?? [];
admin/tabs/admin_payment_providers_tab.dart:358:      final adminRepo = ref.read(adminRepositoryProvider);
admin/tabs/admin_payment_providers_tab.dart:359:      final data = await adminRepo.getPaymentProviders();
admin/tabs/admin_payment_providers_tab.dart:494:      final adminRepo = ref.read(adminRepositoryProvider);
admin/tabs/admin_security_tab.dart:24:    final adminActionsState = ref.watch(adminActionsViewModelProvider);
admin/tabs/admin_security_tab.dart:321:              final viewModel = ref.read(adminActionsViewModelProvider.notifier);
admin/tabs/admin_security_tab.dart:341:    final viewModel = ref.read(adminActionsViewModelProvider.notifier);
admin/tabs/admin_security_tab.dart:359:    final viewModel = ref.read(adminActionsViewModelProvider.notifier);
admin/tabs/admin_users_tab.dart:272:    final viewModel = ref.read(adminActionsViewModelProvider.notifier);
admin/tabs/admin_users_tab.dart:313:      final error = ref.read(adminActionsViewModelProvider).errorMessage ?? 'Action failed';
admin/tabs/admin_sellers_tab.dart:330:              final success = await ref.read(adminActionsViewModelProvider.notifier).setUserSuspended(userId, true);
admin/tabs/admin_sellers_tab.dart:336:                  final error = ref.read(adminActionsViewModelProvider).errorMessage ?? 'Failed to suspend seller';
admin/tabs/admin_sellers_tab.dart:351:    final success = await ref.read(adminActionsViewModelProvider.notifier).setUserSuspended(userId, false);
admin/tabs/admin_sellers_tab.dart:356:        final error = ref.read(adminActionsViewModelProvider).errorMessage ?? 'Failed to unsuspend seller';
admin/admin_providers.dart:6:final adminOrdersProvider = StreamProvider.autoDispose.family<List<OrderModel>, String>((ref, status) {
admin/admin_providers.dart:10:final adminProductsProvider = StreamProvider.autoDispose.family<List<ProductModel>, String?>((ref, sellerId) {
admin/admin_providers.dart:14:final adminRepositoryProvider = Provider<AdminRepository>((ref) {
admin/admin_providers.dart:18:final adminSellersProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
admin/admin_providers.dart:22:final adminUsersProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
admin/admin_panel_screen.dart:37:    final user = ref.watch(currentUserProvider);
admin/admin_panel_screen.dart:38:    final userProfile = ref.watch(userProfileProvider);
admin/admin_panel_screen.dart:316:    final sellers = ref.watch(adminSellersProvider);
admin/admin_panel_screen.dart:317:    final users = ref.watch(adminUsersProvider);
admin/admin_actions_viewmodel.dart:6:final adminActionsViewModelProvider = StateNotifierProvider.autoDispose<AdminActionsViewModel, AdminActionsState>((ref) {
models/models.dart:867:  final String paymentProvider; // stripe | airwallex
screens/favorites_screen.dart:16:    final favoritesAsync = ref.watch(favoritedProductsProvider);
screens/favorites_screen.dart:17:    final userModel = ref.watch(userProfileProvider.select((value) => value.valueOrNull));
screens/editaddress_screen.dart:58:    final state = ref.watch(addressViewModelProvider);
screens/editaddress_screen.dart:59:    final viewModel = ref.read(addressViewModelProvider.notifier);
screens/seller_orders_screen.dart:21:    final user = ref.watch(currentUserProvider);
screens/seller_orders_screen.dart:22:    final userProfile = ref.watch(userProfileProvider).valueOrNull;
screens/seller_orders_screen.dart:90:    final ordersAsync = ref.watch(sellerOrdersProvider);
screens/seller_orders_screen.dart:242:    final isLoading = ref.watch(sellerOrdersViewModelProvider.select((state) => state.isLoading));
screens/cart_screen.dart:23:    final user = ref.watch(currentUserProvider);
screens/cart_screen.dart:38:    final productIdsAsync = ref.watch(cartItemsProvider.select((async) => async.whenData((items) => items.map((i) => i.productId).toList())));
screens/cart_screen.dart:148:    final itemAsync = ref.watch(cartItemDetailProvider(productId));
screens/cart_screen.dart:187:    final isEmpty = ref.watch(cartWithDetailsProvider.select((async) => async.whenData((items) => items.isEmpty)));
screens/cart_screen.dart:276:    final cartDetailsAsync = ref.watch(cartWithDetailsProvider);
screens/terms_screen.dart:72:    final termsAsync = ref.watch(termsProvider);
screens/seller_registration_screen.dart:15:final paymentProviderStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
screens/seller_registration_screen.dart:126:    final userProfileAsync = ref.watch(userProfileProvider);
screens/seller_registration_screen.dart:128:    final viewState = ref.watch(sellerRegistrationViewModelProvider);
screens/seller_registration_screen.dart:129:    final viewModel = ref.read(sellerRegistrationViewModelProvider.notifier);
screens/seller_registration_screen.dart:345:    final paymentProvider = viewState.paymentProvider;
screens/seller_registration_screen.dart:509:    final backendStatus = ref.watch(paymentProviderStatusProvider);
screens/seller_registration_screen.dart:571:    final provider = user.paymentProvider.isNotEmpty ? user.paymentProvider : state.paymentProvider;
screens/seller_registration_screen.dart:572:    final selectedConfig = availablePaymentProviders.firstWhere((p) => p.id == provider, orElse: () => availablePaymentProviders.first);
screens/seller_registration_screen.dart:575:    final backendStatus = ref.watch(paymentProviderStatusProvider);
screens/payment_screens.dart:19:    final orderAsync = ref.watch(paidOrderBySessionProvider(sessionId));
screens/orders_screen.dart:115:    final user = ref.watch(currentUserProvider);
screens/orders_screen.dart:128:    final ordersAsync = ref.watch(buyerOrdersProvider);
screens/orders_screen.dart:832:    final viewModel = ref.read(buyerOrdersViewModelProvider.notifier);
screens/orders_screen.dart:845:      final error = ref.read(buyerOrdersViewModelProvider).errorMessage ?? 'Failed to confirm receipt';
screens/profile_screen.dart:33:    final userProfileAsync = ref.watch(userProfileProvider);
screens/profile_screen.dart:34:    final viewModel = ref.read(profileViewModelProvider.notifier);
screens/profile_screen.dart:79:              final currentUser = ref.watch(currentUserProvider);
screens/profile_screen.dart:711:    final profileState = ref.watch(profileViewModelProvider);
screens/profile_screen.dart:712:    final viewModel = ref.read(profileViewModelProvider.notifier);
screens/editproduct_screen.dart:63:    final state = ref.watch(editProductViewModelProvider(widget.product));
screens/editproduct_screen.dart:64:    final viewModel = ref.read(editProductViewModelProvider(widget.product).notifier);
screens/editproduct_screen.dart:543:    final state = ref.read(editProductViewModelProvider(widget.product));
screens/common_screens.dart:20:    final authState = ref.watch(authStateProvider);
screens/common_screens.dart:278:    final user = ref.watch(currentUserProvider);
screens/login_screen.dart:30:    final state = ref.watch(loginViewModelProvider);
screens/login_screen.dart:31:    final viewModel = ref.read(loginViewModelProvider.notifier);
screens/cartitem_screen.dart:99:                      final quantityAsync = ref.watch(cartItemQuantityProvider(productId));
screens/cartitem_screen.dart:114:                      final quantityAsync = ref.watch(cartItemQuantityProvider(productId));
screens/cartitem_screen.dart:134:                    final quantityAsync = ref.watch(cartItemQuantityProvider(productId));
screens/cartitem_screen.dart:136:                    final cartController = ref.read(cartControllerProvider);
screens/authwrapper_screen.dart:19:    final authState = ref.watch(authStateProvider);
screens/authwrapper_screen.dart:46:        final authState = ref.read(authStateProvider);
screens/checkout_screen.dart:16:final _termsAcceptedProvider = StateProvider.autoDispose<bool>((ref) => false);
screens/checkout_screen.dart:136:    final isProcessing = ref.watch(checkoutStateProvider.select((state) => state.isProcessing));
screens/checkout_screen.dart:137:    final isCalculating = ref.watch(checkoutStateProvider.select((state) => state.isCalculatingShipping));
screens/checkout_screen.dart:138:    final shippingError = ref.watch(checkoutStateProvider.select((state) => state.shippingError));
screens/checkout_screen.dart:139:    final termsAccepted = ref.watch(_termsAcceptedProvider);
screens/checkout_screen.dart:166:    final notifier = ref.read(checkoutStateProvider.notifier);
screens/checkout_screen.dart:192:    final address = ref.watch(checkoutStateProvider.select((state) => state.address));
screens/checkout_screen.dart:193:    final shippingCost = ref.watch(checkoutStateProvider.select((state) => state.shippingCost));
screens/checkout_screen.dart:196:    final paymentProvider = ref.watch(checkoutStateProvider.select((state) => state.paymentProvider));
screens/checkout_screen.dart:197:    final notifier = ref.read(checkoutStateProvider.notifier);
screens/checkout_screen.dart:314:    final userProfileAsync = ref.watch(userProfileProvider);
screens/checkout_screen.dart:345:    final notifier = ref.read(checkoutStateProvider.notifier);
screens/checkout_screen.dart:348:    final state = ref.read(checkoutStateProvider);
screens/checkout_screen.dart:356:    final notifier = ref.read(checkoutStateProvider.notifier);
screens/checkout_screen.dart:368:    final availableSpeeds = ref.watch(checkoutStateProvider.select((state) => state.availableDeliverySpeeds));
screens/checkout_screen.dart:369:    final selectedSpeed = ref.watch(checkoutStateProvider.select((state) => state.deliverySpeed));
screens/checkout_screen.dart:370:    final isCalculating = ref.watch(checkoutStateProvider.select((state) => state.isCalculatingShipping));
screens/checkout_screen.dart:371:    final baseShippingCost = ref.watch(checkoutStateProvider.select((state) => state.baseShippingCost));
screens/checkout_screen.dart:595:    final shippingCost = ref.watch(checkoutStateProvider.select((state) => state.shippingCost));
screens/checkout_screen.dart:596:    final isCalculating = ref.watch(checkoutStateProvider.select((state) => state.isCalculatingShipping));
screens/checkout_screen.dart:597:    final shippingError = ref.watch(checkoutStateProvider.select((state) => state.shippingError));
screens/checkout_screen.dart:702:  final String selectedProvider;
screens/checkout_screen.dart:776:    final termsAccepted = ref.watch(_termsAcceptedProvider);
screens/productdetails_screen.dart:23:    final productAsync = ref.watch(productByIdProvider(productId));
screens/productdetails_screen.dart:24:    final viewModel = ref.read(productDetailViewModelProvider.notifier);
screens/productdetails_screen.dart:301:    final quantity = ref.watch(productDetailViewModelProvider.select((state) => state.quantity));
screens/productdetails_screen.dart:302:    final currentUser = ref.watch(currentUserProvider);
screens/productdetails_screen.dart:331:        final user = ref.read(currentUserProvider);
screens/productdetails_screen.dart:342:        final success = await ref.read(cartControllerProvider).addToCart(productId, quantity);
screens/productdetails_screen.dart:502:    final currentIndex = ref.watch(productDetailViewModelProvider.select((state) => state.currentImageIndex));
screens/productdetails_screen.dart:549:    final quantity = ref.watch(productDetailViewModelProvider.select((state) => state.quantity));
screens/seller_setup_screen.dart:48:      final status = await ref.read(refreshSellerStatusProvider(null).future);
screens/seller_setup_screen.dart:82:    final statusAsync = ref.watch(sellerAccountStatusProvider);
screens/main_screen.dart:23:        final userProfileAsync = ref.read(userProfileProvider);
screens/main_screen.dart:33:    final userProfileAsync = ref.watch(userProfileProvider);
screens/product_card_screen.dart:44:    final isFavorite = ref.watch(favoritesProvider.select((value) => value.maybeWhen(data: (favs) => favs.contains(widget.productId), orElse: () => false)));
screens/product_card_screen.dart:224:                                final user = ref.read(currentUserProvider);
screens/product_card_screen.dart:229:                                final success = await ref.read(cartControllerProvider).addToCart(widget.productId, _quantity);
screens/product_card_screen.dart:302:    final viewModel = ref.read(productActionsViewModelProvider.notifier);
screens/product_card_screen.dart:309:      final error = ref.read(productActionsViewModelProvider).errorMessage ?? 'Error deleting product';
screens/product_card_screen.dart:340:    final user = ref.read(currentUserProvider);
screens/addressmanagement_screen.dart:16:    final userProfileAsync = ref.watch(userProfileProvider);
screens/home_screen.dart:32:    final userProfile = ref.watch(userProfileProvider).valueOrNull;
screens/home_screen.dart:33:    final sellerStatus = ref.watch(sellerAccountStatusProvider);
screens/home_screen.dart:100:    final user = ref.watch(currentUserProvider);
screens/home_screen.dart:101:    final cartCount = ref.watch(cartItemCountProvider);
screens/home_screen.dart:190:    final selectedCategoryId = ref.watch(homeViewModelProvider.select((state) => state.selectedCategoryId));
screens/home_screen.dart:258:    final homeNotifier = ref.read(homeViewModelProvider.notifier);
screens/home_screen.dart:489:    final isLoadingMore = ref.watch(homeViewModelProvider.select((state) => state.isLoadingMore));
screens/home_screen.dart:519:    final isLoading = ref.watch(homeViewModelProvider.select((state) => state.isLoading));
screens/home_screen.dart:520:    final products = ref.watch(homeViewModelProvider.select((state) => state.products));
screens/home_screen.dart:521:    final userProfile = ref.watch(userProfileProvider).valueOrNull;
screens/home_screen.dart:615:    final user = ref.watch(currentUserProvider);
screens/addproduct_screen.dart:103:    final state = ref.watch(addProductViewModelProvider);
screens/addproduct_screen.dart:104:    final viewModel = ref.read(addProductViewModelProvider.notifier);
screens/shipping_approval_screen.dart:19:    final approvalsAsync = ref.watch(pendingShippingApprovalsProvider);
screens/shipping_approval_screen.dart:403:    final viewModel = ref.read(shippingApprovalViewModelProvider.notifier);
screens/shipping_approval_screen.dart:413:      final error = ref.read(shippingApprovalViewModelProvider).errorMessage ?? 'Failed to update shipping approval';
widgets/custom_app_bar.dart:130:    final isLoggedIn = ref.watch(currentUserProvider.select((user) => user != null));
widgets/custom_app_bar.dart:131:    final cartCount = ref.watch(cartItemCountProvider);
```

## ☁️ Cloud Functions Endpoints

```
main_old.py.backup:216:@https_fn.on_call(cors=cors_config)
main_old.py.backup:764:@https_fn.on_request(timeout_sec=60)
main_old.py.backup:2045:@https_fn.on_call(secrets=[R2_ACCESS_KEY_NEW, R2_SECRET_KEY_NEW, R2_ACCOUNT_ID_NEW])
main_old.py.backup:2087:@https_fn.on_call()
main_old.py.backup:2205:@https_fn.on_call()
main_old.py.backup:2463:@https_fn.on_call()
main_old.py.backup:2597:@https_fn.on_call()
main_old.py.backup:2685:@https_fn.on_call()
main_old.py.backup:2736:@https_fn.on_call()
main_old.py.backup:2809:@https_fn.on_call()
main_old.py.backup:2846:@https_fn.on_call()
main_old.py.backup:2880:@https_fn.on_call()
main_old.py.backup:2965:@https_fn.on_call()
main_old.py.backup:3034:@https_fn.on_call()
main_old.py.backup:3093:@https_fn.on_request(timeout_sec=60)
main_old.py.backup:3151:@https_fn.on_call()
main_old.py.backup:3321:@https_fn.on_call()
main_old.py.backup:3395:@https_fn.on_call()
main_old.py.backup:3701:@scheduler_fn.on_schedule(schedule="every 24 hours")
main_old.py.backup:3827:@scheduler_fn.on_schedule(schedule="every 24 hours")
main_old.py.backup:3904:@https_fn.on_call()
main_old.py.backup:4047:@https_fn.on_call()
main_old.py.backup:4159:@https_fn.on_call()
main_old.py.backup:4422:@https_fn.on_call()
main_old.py.backup:4525:@https_fn.on_call()
main_old.py.backup:4659:@scheduler_fn.on_schedule(schedule="every 12 hours")
main_old.py.backup:4825:@https_fn.on_call()
main_old.py.backup:5098:@https_fn.on_call(cors=cors_config_p)
main_old.py.backup:5154:@scheduler_fn.on_schedule(schedule="every 15 minutes")
main_old.py.backup:5225:@scheduler_fn.on_schedule(schedule="every 30 minutes")
main_old.py.backup:5334:@scheduler_fn.on_schedule(schedule="0 2 * * *")  # Daily at 02:00 UTC
check_expired_authorizations.py:28:@scheduler_fn.on_schedule(schedule="0 2 * * *")  # Run daily at 2 AM UTC
check_expired_authorizations.py:42:@https_fn.on_request()
handlers/payment_stripe.py:143:@https_fn.on_call(**DEFAULT_OPTIONS, cors=CORS_CONFIG)
handlers/payment_stripe.py:654:@https_fn.on_request(**WEBHOOK_OPTIONS)
handlers/payment_stripe.py:1279:@https_fn.on_call(**DEFAULT_OPTIONS)
handlers/payment_stripe.py:1363:@https_fn.on_call(**DEFAULT_OPTIONS)
handlers/payment_stripe.py:1407:@https_fn.on_call(**DEFAULT_OPTIONS)
handlers/payment_stripe.py:1461:@https_fn.on_call(**DEFAULT_OPTIONS)
handlers/products.py:62:@https_fn.on_call(secrets=[R2_ACCESS_KEY_NEW, R2_SECRET_KEY_NEW, R2_ACCOUNT_ID_NEW])
handlers/products.py:159:@https_fn.on_call(**DEFAULT_OPTIONS)
handlers/products.py:236:@https_fn.on_call(**DEFAULT_OPTIONS)
handlers/products.py:473:@https_fn.on_call(**DEFAULT_OPTIONS, cors=CORS_CONFIG)
handlers/products.py:504:@https_fn.on_call(**DEFAULT_OPTIONS, cors=CORS_CONFIG)
handlers/products.py:604:@https_fn.on_call(**DEFAULT_OPTIONS, cors=CORS_CONFIG)
handlers/products.py:704:@https_fn.on_call(**DEFAULT_OPTIONS, cors=CORS_CONFIG)
handlers/orders.py:60:@https_fn.on_call(**DEFAULT_OPTIONS)
handlers/orders.py:84:@https_fn.on_call(**DEFAULT_OPTIONS)
handlers/orders.py:252:@https_fn.on_call(**DEFAULT_OPTIONS)
handlers/orders.py:396:@https_fn.on_call(**DEFAULT_OPTIONS)
handlers/orders.py:517:@https_fn.on_call(**DEFAULT_OPTIONS)
handlers/orders.py:727:@https_fn.on_call(**DEFAULT_OPTIONS)
handlers/cron_jobs.py:56:@scheduler_fn.on_schedule(schedule="every 24 hours", **CRON_OPTIONS)
handlers/cron_jobs.py:236:@scheduler_fn.on_schedule(schedule="every 24 hours", **CRON_OPTIONS)
handlers/cron_jobs.py:307:@scheduler_fn.on_schedule(schedule="every 12 hours", **CRON_OPTIONS)
handlers/cron_jobs.py:359:@scheduler_fn.on_schedule(schedule="every 15 minutes", **CRON_OPTIONS)
handlers/cron_jobs.py:414:@scheduler_fn.on_schedule(schedule="every 30 minutes", **CRON_OPTIONS)
handlers/cron_jobs.py:454:@scheduler_fn.on_schedule(schedule="0 2 * * *", **CRON_OPTIONS)  # Daily at 02:00 UTC
handlers/payment_providers.py:241:@https_fn.on_call(**DEFAULT_OPTIONS)
handlers/payment_providers.py:292:@https_fn.on_call(**DEFAULT_OPTIONS)
handlers/payment_providers.py:405:@https_fn.on_call(**DEFAULT_OPTIONS)
handlers/admin.py:85:@https_fn.on_call(**DEFAULT_OPTIONS)
handlers/admin.py:194:@https_fn.on_call(**DEFAULT_OPTIONS)
handlers/admin.py:381:@https_fn.on_call(**DEFAULT_OPTIONS)
handlers/admin.py:433:@https_fn.on_call(**DEFAULT_OPTIONS)
handlers/admin.py:488:@https_fn.on_call(**DEFAULT_OPTIONS)
handlers/admin.py:537:@https_fn.on_call(**DEFAULT_OPTIONS)
handlers/payment_airwallex.py:72:@https_fn.on_call(**DEFAULT_OPTIONS)
handlers/payment_airwallex.py:115:@https_fn.on_call(**DEFAULT_OPTIONS)
handlers/payment_airwallex.py:194:@https_fn.on_call(**DEFAULT_OPTIONS)
handlers/payment_airwallex.py:248:@https_fn.on_request(timeout_sec=60)
update_function_options.py:3:Script to update all @https_fn decorators to use global options
update_function_options.py:15:        r'@https_fn\.on_call\(\)',
update_function_options.py:16:        '@https_fn.on_call(**DEFAULT_OPTIONS._asdict())'
update_function_options.py:20:        r'@https_fn\.on_call\(cors=cors_config\)',
update_function_options.py:21:        '@https_fn.on_call(**DEFAULT_OPTIONS._asdict(), cors=CORS_CONFIG)'
update_function_options.py:25:        r'@https_fn\.on_request\(\)',
update_function_options.py:26:        '@https_fn.on_request(**DEFAULT_OPTIONS._asdict())'
update_function_options.py:41:    if '@https_fn.' in content and 'from function_options import' not in content:
```

---

**Stats:** 487 Dart symbols, 292 Python symbols, 239 Riverpod providers extracted.
