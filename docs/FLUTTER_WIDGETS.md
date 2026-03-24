# OrignaGTA Custom Widgets Documentation

> Comprehensive documentation of all significant custom widgets in `lib/widgets/`
> Generated: March 2026

---

## Table of Contents

1. [Shared Widgets](#shared-widgets)
2. [Checkout Widgets](#checkout-widgets)
3. [Cart Widgets](#cart-widgets)
4. [Order Widgets](#order-widgets)
5. [Profile Widgets](#profile-widgets)
6. [Mascot Widgets](#mascot-widgets)
7. [Modern UI Widgets](#modern-ui-widgets)
8. [Other Widgets](#other-widgets)

---

## Shared Widgets

### CartBadge

**File:** `origna_gta/lib/widgets/shared/cart_badge.dart` (Lines 17-71)

**Description:** Shopping cart icon with animated badge showing item count. Supports two modes: animated (with scale/pulse effects) and simple (plain icon button).

**Constructor Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `animated` | `bool` | No | `false` | Enables scale/pulse hover animations |
| `iconColor` | `Color` | No | `DesignTokens.textOnPrimary` | Icon colour |
| `requireEmailVerification` | `bool` | No | `false` | Check email verification before navigation |
| `tooltip` | `String?` | No | `null` | Optional tooltip override |
| `badgeRight` | `double` | No | `-2` | Badge offset from right |
| `badgeTop` | `double` | No | `-2` | Badge offset from top |
| `showBadgeBorder` | `bool` | No | `false` | Show border and glow effect |

**Named Constructors:**
- `CartBadge.animated()` - Home hero section badge with animations
- `CartBadge.appBar()` - Simple app-bar style badge

**Renders:**
- `IconButton` with shopping cart icon
- `Positioned` badge circle showing count
- `AnimatedBuilder` wrappers for scale/pulse effects

**Usage Locations:**
- `lib/screens/home_screen.dart` - Home hero section
- `lib/widgets/custom_app_bar.dart` - Custom app bar

---

### FilterChipWidget

**File:** `origna_gta/lib/widgets/shared/filter_chip_widget.dart`

**Description:** Reusable filter chip for category/tag filtering.

**Usage Locations:** Used throughout product filtering screens

---

### QuantityButton

**File:** `origna_gta/lib/widgets/shared/quantity_button.dart`

**Description:** Increment/decrement quantity selector button.

**Renders:**
- Decrement button
- Quantity text display
- Increment button

---

### TrendingBadge

**File:** `origna_gta/lib/widgets/shared/trending_badge.dart`

**Description:** Shows HOT or RISING trending status on products.

---

## Checkout Widgets

### OrderReviewSheet

**File:** `origna_gta/lib/widgets/checkout/order_review_sheet.dart` (Lines 15-390)

**Description:** Draggable bottom sheet showing full order review before payment. Displays cart items, shipping address, price breakdown (subtotal, coupon, shipping, tax), and confirm-and-pay button.

**Constructor Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `items` | `List<CartItemDetailModel>` | Yes | Cart items to display |
| `subtotal` | `double` | Yes | Cart subtotal |
| `onConfirm` | `VoidCallback` | Yes | Callback when confirm button pressed |

**Renders:**
- `DraggableScrollableSheet` container
- `ListView.builder` with item rows
- Price breakdown section (subtotal, coupon, shipping, tax)
- Total row with estimated total
- `ModernButton` for confirm and pay

**Usage Locations:**
- `lib/screens/checkout_screen.dart`

---

### DeliveryOptionsSection

**File:** `origna_gta/lib/widgets/checkout/delivery_options_section.dart` (Lines 12-370)

**Description:** Delivery speed selector for checkout flow. Shows skeleton cards while shipping costs are calculated, then renders selectable radio-style cards for each DeliverySpeed.

**Constructor Parameters:**

None (stateless, reads from Riverpod providers)

**Renders:**
- `Row` with title and info button
- Skeleton loading cards (when calculating)
- Selectable delivery option cards (standard, express, same-day)
- Info dialog with delivery details

**Usage Locations:**
- `lib/screens/checkout_screen.dart`

---

## Cart Widgets

### FreeShippingBar

**File:** `origna_gta/lib/widgets/cart/free_shipping_bar.dart` (Lines 8-106)

**Description:** Free shipping progress bar shown above checkout button. Displays progress toward free shipping threshold and remaining amount.

**Constructor Parameters:** None (ConsumerWidget)

**Renders:**
- Container with progress status text
- `LinearProgressIndicator` showing progress
- Threshold info text

**Usage Locations:**
- `lib/screens/cart_screen.dart`

---

### CartTotalDisplay

**File:** `origna_gta/lib/widgets/cart/cart_total_display.dart` (Lines 12-585)

**Description:** Cart total display with info icons and delivery instructions. Shows subtotal, service fees, tax estimate, estimated total, and editable delivery instructions.

**Constructor Parameters:** None (ConsumerWidget)

**Renders:**
- Subtotal row with item count
- Service fees row with tooltip
- Tax estimate row with tooltip
- Estimated total row
- Delivery instructions row (editable)
- Info sheet modals

**Usage Locations:**
- `lib/screens/cart_screen.dart`

---

## Order Widgets

### BuyerOrderCard

**File:** `origna_gta/lib/widgets/order_widgets.dart` (Lines 254-2356)

**Description:** Comprehensive order card for buyers showing order details, status, items, pricing, and actions. Includes per-seller package grouping with individual timelines.

**Constructor Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `order` | `Order` | Yes | - | Order model to display |
| `isDetailView` | `bool` | No | `false` | Whether showing in detail view |

**Renders:**
- Order header with status badge and order ID
- Terminal status banner (cancelled/failed/refunded)
- Status description with icon
- Payment status banner (authorized orders)
- Seller packages (Amazon-style per-seller grouping)
- Price breakdown (subtotal, discount, shipping, tax)
- Buy again button (delivered orders)
- Return request button (within return window)
- Delivery address section
- Delivery instructions section

**Usage Locations:**
- `lib/screens/orders_screen.dart`
- `lib/screens/order_detail_screen.dart`

---

### OrderStatusTimeline

**File:** `origna_gta/lib/widgets/order_widgets.dart` (Lines 338-461)

**Description:** 5-step order status timeline (Confirmed -> Processing -> Shipped -> In Transit -> Delivered).

**Constructor Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `currentStep` | `int` | Yes | Current step index (0-4) |

**Renders:**
- Row with step icons and labels
- Connecting gradient lines between steps

---

### SellerPackageTimeline

**File:** `origna_gta/lib/widgets/order_widgets.dart` (Lines 567-681)

**Description:** Compact 3-step timeline for a single seller's package (Preparing -> Shipped -> Delivered).

**Constructor Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `currentStep` | `int` | Yes | Current step index (0-2) |

---

### PendingApprovalsBanner

**File:** `origna_gta/lib/widgets/order_widgets.dart` (Lines 464-563)

**Description:** Warning banner showing pending shipping approvals count with tap to navigate.

**Constructor Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `count` | `int` | Yes | Number of pending approvals |

---

### DigitalItemActions

**File:** `origna_gta/lib/widgets/order_widgets.dart` (Lines 272-335)

**Description:** Shows license key and download buttons for digital items.

**Constructor Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `item` | `OrderItem` | Yes | Digital order item |

---

### BookDownloadButton

**File:** `origna_gta/lib/widgets/order_widgets.dart` (Lines 241-257)

**Description:** Download button for digital books.

**Constructor Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `item` | `OrderItem` | Yes | Book order item |

---

### SoftwareDownloadLinks

**File:** `origna_gta/lib/widgets/order_widgets.dart` (Lines 684-691)

**Description:** Download links for software by platform (macOS, Windows, Linux).

**Constructor Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `item` | `OrderItem` | Yes | Software order item |

---

### SellerOrderItemTile

**File:** `origna_gta/lib/widgets/orders/seller_order_item_tile.dart` (Lines 13-311)

**Description:** Single order-item tile for seller order view. Shows item thumbnail, name, quantity, delivery status chip, carrier info, refund date, buyer note, and action buttons.

**Constructor Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `item` | `OrderItem` | Yes | Order item to display |
| `isDark` | `bool` | Yes | Dark mode flag |
| `isAuthorized` | `bool` | Yes | Whether payment is authorized |
| `onMarkShipped` | `VoidCallback?` | No | Callback for mark shipped |
| `onEditTracking` | `VoidCallback?` | No | Callback for edit tracking |

**Renders:**
- `ListTile` with thumbnail, title, subtitle
- Status chip
- Mark shipped / edit tracking buttons
- Digital badge for digital items

**Usage Locations:**
- `lib/screens/seller_orders_screen.dart`

---

### showMarkShippedDialog

**File:** `origna_gta/lib/widgets/orders/mark_shipped_dialog.dart` (Lines 16-205)

**Description:** Dialog function for sellers to enter carrier, tracking number, and optional carrier note when marking an item shipped.

**Function Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `context` | `BuildContext` | Yes | Build context |
| `ref` | `WidgetRef` | Yes | Riverpod reference |
| `orderId` | `String` | Yes | Order ID |
| `productId` | `String` | Yes | Product ID |
| `carrierProvider` | `AutoDisposeStateProvider<String?>` | Yes | Provider for carrier state |
| `prefillTracking` | `String?` | No | Prefill tracking number |
| `prefillCarrier` | `String?` | No | Prefill carrier |
| `prefillCarrierNote` | `String?` | No | Prefill carrier note |

**Usage Locations:**
- `lib/screens/seller_orders_screen.dart`

---

### showUpdateShippingDialog

**File:** `origna_gta/lib/widgets/orders/update_shipping_dialog.dart` (Lines 17-234)

**Description:** Dialog function for sellers to enter actual shipping cost, carrier, tracking number when confirming shipping for authorized orders.

**Function Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `context` | `BuildContext` | Yes | Build context |
| `ref` | `WidgetRef` | Yes | Riverpod reference |
| `orderId` | `String` | Yes | Order ID |
| `estimatedShipping` | `double` | Yes | Estimated shipping cost |
| `carrierProvider` | `AutoDisposeStateProvider<String?>` | Yes | Provider for carrier state |

**Usage Locations:**
- `lib/screens/seller_orders_screen.dart`

---

### OrderStatusWidgets

**File:** `origna_gta/lib/widgets/orders/order_status_widgets.dart`

**Description:** Reusable order status display widgets.

---

## Profile Widgets

### ProfileThemeToggle

**File:** `origna_gta/lib/widgets/profile/profile_theme_toggle.dart`

**Description:** Theme toggle switch for light/dark mode in profile.

**Usage Locations:**
- `lib/screens/profile_screen.dart`

---

### ProfileHeaderCard

**File:** `origna_gta/lib/widgets/profile/profile_header_card.dart`

**Description:** Profile header with user avatar, name, and member info.

**Usage Locations:**
- `lib/screens/profile_screen.dart`

---

### PremiumMenuItem

**File:** `origna_gta/lib/widgets/profile/premium_menu_item.dart`

**Description:** Premium/upgrade menu item for profile.

**Usage Locations:**
- `lib/screens/profile_screen.dart`

---

### ProfileMenuItem

**File:** `origna_gta/lib/widgets/profile/profile_menu_item.dart`

**Description:** Standard profile menu item.

**Usage Locations:**
- `lib/screens/profile_screen.dart`

---

## Mascot Widgets

### CanadianMoose

**File:** `origna_gta/lib/widgets/mascot/canadian_moose.dart`

**Description:** Canadian moose mascot illustration widget.

---

### MascotProvider

**File:** `origna_gta/lib/widgets/mascot/mascot_provider.dart`

**Description:** Provider for mascot state management.

---

### ShopMascot

**File:** `origna_gta/lib/widgets/mascot/shop_mascot.dart`

**Description:** Main shop mascot wrapper widget.

---

### MascotPreview

**File:** `origna_gta/lib/widgets/mascot/mascot_preview.dart`

**Description:** Preview widget for mascot.

---

### MooseProvider

**File:** `origna_gta/lib/widgets/moose_provider.dart`

**Description:** Specific provider for moose mascot.

---

## Modern UI Widgets

### ModernButton

**File:** `origna_gta/lib/widgets/modern_button.dart` (Lines 8-146)

**Description:** Modern 2100 button with gradient and smooth interactions. Primary UI button component with scale animation on tap.

**Constructor Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `label` | `String` | Yes | - | Button text label |
| `onPressed` | `VoidCallback?` | No | `null` | Button press callback |
| `isLoading` | `bool` | No | `false` | Show loading indicator |
| `isPrimary` | `bool` | No | `true` | Use primary gradient |
| `isOutlined` | `bool` | No | `false` | Use outlined style |
| `icon` | `IconData?` | No | `null` | Leading icon |
| `imageIcon` | `String?` | No | `null` | Image asset for icon |
| `width` | `double` | No | `double.infinity` | Button width |
| `height` | `double` | No | `52` | Button height |
| `fullWidth` | `bool` | No | `true` | Expand to full width |
| `backgroundColor` | `Color?` | No | `null` | Custom background |
| `semanticsLabel` | `String?` | No | `null` | Accessibility label |

**Renders:**
- `GestureDetector` with scale animation
- Container with gradient or solid background
- `InkWell` for tap handling
- Row with icon and text or loading indicator

**Usage Locations:** 39 files throughout the app including:
- `lib/screens/checkout_screen.dart`
- `lib/screens/cart_screen.dart`
- `lib/screens/login_screen.dart`
- `lib/screens/profile_screen.dart`
- And many more

---

### ModernTextField

**File:** `origna_gta/lib/widgets/modern_textfield.dart` (Lines 7-160)

**Description:** Modern 2100 text input field with glassmorphism styling.

**Constructor Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `label` | `String?` | No | `null` | Field label |
| `hint` | `String?` | No | `null` | Hint text |
| `controller` | `TextEditingController?` | No | `null` | Text controller |
| `keyboardType` | `TextInputType` | No | `TextInputType.text` | Keyboard type |
| `isPassword` | `bool` | No | `false` | Password field (obscured) |
| `isMultiline` | `bool` | No | `false` | Multiline text |
| `prefixIcon` | `IconData?` | No | `null` | Leading icon |
| `suffixIcon` | `IconData?` | No | `null` | Trailing icon |
| `onSuffixTap` | `VoidCallback?` | No | `null` | Suffix icon tap |
| `validator` | `String? Function(String?)?` | No | `null` | Validation function |
| `onChanged` | `void Function(String)?` | No | `null` | Change callback |
| `maxLines` | `int` | No | `1` | Maximum lines |
| `minLines` | `int` | No | `1` | Minimum lines |
| `maxLength` | `int?` | No | `null` | Max character count |
| `showCounter` | `bool` | No | `false` | Show character counter |
| `textFieldKey` | `Key?` | No | `null` | Widget key |
| `semanticsLabel` | `String?` | No | `null` | Accessibility label |

**Renders:**
- Column with label and field
- `TextFormField` with custom decoration
- Optional prefix/suffix icons

**Usage Locations:**
- `lib/screens/login_screen.dart`
- `lib/screens/profile_screen.dart`
- `lib/screens/reset_password_screen.dart`
- `lib/widgets/cart/cart_total_display.dart`
- `lib/features/support/support_screen.dart`

---

### ModernCard

**File:** `origna_gta/lib/widgets/modern_card.dart` (Lines 7-115)

**Description:** Modern 2100 card with glassmorphism and hover effects.

**Constructor Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `child` | `Widget` | Yes | - | Card content |
| `onTap` | `VoidCallback?` | No | `null` | Tap callback |
| `backgroundColor` | `Color?` | No | `null` | Custom background |
| `padding` | `EdgeInsets` | No | `16px all` | Inner padding |
| `borderRadius` | `BorderRadius` | No | `16px radius` | Corner radius |
| `enableHoverScale` | `bool` | No | `true` | Enable hover scale |
| `width` | `double?` | No | `null` | Fixed width |
| `height` | `double?` | No | `null` | Fixed height |
| `semanticLabel` | `String?` | No | `null` | Accessibility label |

**Renders:**
- `MouseRegion` for hover detection
- `ScaleTransition` for hover animation
- `GestureDetector` with animated container
- ClipRRect with padding for content

**Usage Locations:**
- `lib/widgets/order_widgets.dart`
- `lib/screens/widgets/product_detail/product_info_section.dart`
- `lib/screens/widgets/product_detail/product_price_section.dart`

---

### ModernProductCard

**File:** `origna_gta/lib/widgets/modern_product_card.dart` (Lines 9-471)

**Description:** Modern 2100 product card with glassmorphism. Displays product image, name, seller, rating, price, and add-to-cart button.

**Constructor Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `productName` | `String` | Yes | - | Product name |
| `priceCents` | `int` | Yes | - | Price in cents |
| `imageUrl` | `String` | Yes | - | Product image URL |
| `sellerName` | `String` | Yes | - | Seller name |
| `rating` | `double` | No | `0.0` | Product rating |
| `reviewCount` | `int` | No | `0` | Number of reviews |
| `onTap` | `VoidCallback` | Yes | - | Tap callback |
| `onAddToCart` | `VoidCallback?` | No | `null` | Add to cart callback |
| `shipFromCity` | `String?` | No | `null` | Shipping city |
| `shipFromProvince` | `String?` | No | `null` | Shipping province |
| `shipFromCountry` | `String?` | No | `null` | Shipping country |
| `shipFromCountries` | `List<String>?` | No | `null` | Multiple shipping countries |
| `compareAtPriceCents` | `int?` | No | `null` | Original price for sale |
| `isTrending` | `bool` | No | `false` | Show trending badge |
| `trendingScore` | `int` | No | `0` | Trending score |
| `isOutOfStock` | `bool` | No | `false` | Out of stock state |

**Renders:**
- Product image with CachedNetworkImage
- TrendingBadge (if trending)
- Out of stock overlay
- Product name, seller, location
- Rating stars
- Price (with optional sale price)
- Add to cart button

**Usage Locations:**
- `lib/previews/widgets/modern_product_card_preview.dart`
- `lib/previews/widgets/product_card_preview.dart`

---

### ModernLoadingIndicator

**File:** `origna_gta/lib/widgets/modern_loading_indicator.dart` (Lines 18-98)

**Description:** Styled loading indicator with glassmorphism aesthetic. Replaces raw CircularProgressIndicator.

**Constructor Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `size` | `double` | No | `24` | Spinner diameter |
| `strokeWidth` | `double` | No | `2.5` | Arc stroke width |
| `color` | `Color?` | No | `DesignTokens.primary` | Spinner color |
| `message` | `String?` | No | `null` | Optional label |
| `centered` | `bool` | No | `true` | Center the indicator |
| `padding` | `EdgeInsets` | No | `zero` | Outer padding |

**Named Constructors:**
- `ModernLoadingIndicator.fullScreen()` - Centered overlay with optional message
- `ModernLoadingIndicator.small()` - Compact 16x16 spinner

**Renders:**
- Custom painted spinning arc
- Optional message text

**Usage Locations:** Throughout the app wherever loading states are shown

---

### ModernSkeletonLoader

**File:** `origna_gta/lib/widgets/modern_skeleton_loader.dart` (Lines 5-191)

**Description:** Shimmer-based skeleton loading placeholders for content loading states.

**Factory Constructors:**

| Constructor | Description |
|-------------|-------------|
| `ModernSkeletonLoader.card({height, width})` | Card-shaped skeleton |
| `ModernSkeletonLoader.listTile()` | List tile skeleton |
| `ModernSkeletonLoader.text({width, height})` | Text line skeleton |
| `ModernSkeletonLoader.imagePlaceholder(...)` | Image placeholder |
| `ModernSkeletonLoader.wrap(...)` | Wrap arbitrary child |

**Renders:**
- Shimmer.fromColors wrapper with base/highlight colors
- Theme-aware shimmer colors

**Usage Locations:** Throughout the app for loading states

---

### ModernSnackbar

**File:** `origna_gta/lib/widgets/modern_snackbar.dart` (Lines 4-76)

**Description:** Static utility class for showing styled snackbars.

**Static Methods:**

| Method | Parameters |
|--------|------------|
| `ModernSnackbar.show(context, message, {isError, isSuccess, duration, icon})` | Show a snackbar |

**Renders:**
- Floating SnackBar with custom styling
- Icon, message text
- Dark theme styling

**Usage Locations:** Throughout the app for transient messages

---

### ModernAppBar

**File:** `origna_gta/lib/widgets/modern_app_bar.dart`

**Description:** Modern styled app bar widget.

---

## Other Widgets

### CustomAppBar

**File:** `origna_gta/lib/widgets/custom_app_bar.dart` (Lines 98-236)

**Description:** Reusable custom AppBar with gradient background and consistent styling.

**Constructor Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `title` | `String` | Yes | - | AppBar title |
| `subtitle` | `String?` | No | `null` | Optional subtitle |
| `actions` | `List<Widget>?` | No | `null` | Action widgets |
| `leading` | `Widget?` | No | `null` | Custom leading widget |
| `showBackButton` | `bool` | No | `true` | Show back button |
| `showCartBadge` | `bool` | No | `false` | Show cart badge |
| `onBackPressed` | `VoidCallback?` | No | `null` | Back button callback |
| `height` | `double` | No | `60` | AppBar height |

**Factory Methods:**
- `AppBarFactory.custom()` - Custom configuration
- `AppBarFactory.main()` - Main screen without back button
- `AppBarFactory.simple()` - Simple with title and back
- `AppBarFactory.withCart()` - With cart badge

**Renders:**
- Gradient container (top-left to bottom-right)
- SafeArea with Row layout
- Back button or leading widget
- Title (with optional subtitle)
- Actions and cart badge

**Usage Locations:**
- Throughout screen implementations

---

### AppBarIconButton

**File:** `origna_gta/lib/widgets/custom_app_bar.dart` (Lines 69-94)

**Description:** Styled icon button for use in CustomAppBar actions.

**Constructor Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `icon` | `IconData` | Yes | Icon to display |
| `onPressed` | `VoidCallback` | Yes | Press callback |
| `tooltip` | `String` | Yes | Tooltip (WCAG required) |

---

### RatingDialog

**File:** `origna_gta/lib/widgets/rating_dialog.dart`

**Description:** Dialog for submitting product ratings.

**Usage Locations:**
- `lib/screens/order_detail_screen.dart`
- `lib/widgets/order_widgets.dart`

---

### RatingHistogram

**File:** `origna_gta/lib/widgets/rating_histogram.dart`

**Description:** Rating distribution histogram display.

---

### LanguageSelector

**File:** `origna_gta/lib/widgets/language_selector.dart`

**Description:** Language selection dropdown/switcher.

**Usage Locations:**
- `lib/screens/profile_screen.dart`

---

### PremiumPaywallWidget

**File:** `origna_gta/lib/widgets/premium_paywall_widget.dart`

**Description:** Premium feature paywall UI widget.

**Usage Locations:**
- Premium feature screens

---

### StandalonePromoWidget

**File:** `origna_gta/lib/widgets/promotions/standalone_promo_widget.dart`

**Description:** Standalone promotional content widget.

---

### GradientBadge

**File:** `origna_gta/lib/widgets/gradient_badge.dart`

**Description:** Badge with gradient background.

---

### EnvPreviewBanner

**File:** `origna_gta/lib/widgets/env_preview_banner.dart`

**Description:** Development environment banner.

---

### Animations

**File:** `origna_gta/lib/widgets/animations.dart`

**Description:** Reusable animation widgets and utilities (FadeSlideIn, etc.).

---

### LegalScreenBody

**File:** `origna_gta/lib/widgets/legal_screen_body.dart`

**Description:** Reusable legal text content body.

---

## Helper Classes

### StatusConfig

**File:** `origna_gta/lib/widgets/order_widgets.dart` (Lines 698-710)

**Description:** Configuration for order status display (color, icon, label, description).

```dart
class StatusConfig {
  final Color color;
  final IconData icon;
  final String label;
  final String description;
}
```

---

### Helper Functions

**File:** `origna_gta/lib/widgets/order_widgets.dart`

| Function | Lines | Description |
|----------|-------|-------------|
| `getItemDeliveryStep(String status)` | 31-42 | Maps delivery status to timeline step |
| `getItemStatusConfig(String status)` | 44-130 | Gets StatusConfig for item status |
| `getOrderStatusConfig(OrderStatus status)` | 132-219 | Gets StatusConfig for order status |
| `getTimelineStep(OrderStatus status)` | 221-236 | Gets timeline step for order status |

---

## Design Tokens Usage

All widgets use `DesignTokens` from `lib/utils/design_tokens.dart` for consistent styling:

- Colors: `DesignTokens.primary`, `DesignTokens.secondary`, `DesignTokens.success`, etc.
- Spacing: `DesignTokens.spacing8`, `DesignTokens.spacing12`, `DesignTokens.spacing16`
- Radius: `DesignTokens.radius8`, `DesignTokens.radius12`, `DesignTokens.radius16`
- Gradients: `DesignTokens.primaryGradient`
- Shadows: `DesignTokens.shadowMd`, `DesignTokens.shadowLg`

---

## Notes

- All widgets follow the MVVM architecture pattern
- Most widgets are theme-aware (support light/dark mode)
- Accessibility: Use Semantics widgets for screen readers
- WCAG compliance: Touch targets >= 48dp, proper labels
- Riverpod for state management in consumer widgets

---

*Generated from code analysis of lib/widgets/ directory*
