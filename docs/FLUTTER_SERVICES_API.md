# Flutter Services, Utils & Core -- API Reference

> Auto-generated from source on 2026-03-23. Covers `lib/services/`, `lib/utils/`, `lib/core/`, and `lib/widgets/shared/`.

## Table of Contents

- [Services (`lib/services/`)](#services-libservices)
- [Utils (`lib/utils/`)](#utils-libutils)
- [Core -- Providers & Config (`lib/core/`)](#core--providers-&-config-libcore)
- [Shared Widgets (`lib/widgets/shared/`)](#shared-widgets-libwidgetsshared)


---

## Services (`lib/services/`)

### analytics_service.dart
**Path**: `lib/services/analytics_service.dart`
**Purpose**: Injectable provider for [AnalyticsService].

**`AnalyticsEventItem`**
> Lightweight event item model preserved so existing app/test call sites do not depend on platform analytics SDK types.
  Methods:
  - `Map<String, dynamic> toJson()`

**`AnalyticsService`**
> Backward-compatible analytics facade now backed by OrignaBase.
  Methods:
  - `Future<void> logSignUp({required String method})`
  - `Future<void> logLogin({required String method})`
  - `Future<void> logViewItemList({ required String listName, required List<AnalyticsEventItem> items, })`
  - `Future<void> logSelectItem({ required String productId, required String productName, required double priceCad, String listName = '', })`
  - `Future<void> logViewItem({ required String productId, required String productName, required double priceCad, })`
  - `Future<void> logSearch({required String searchTerm})`
  - `Future<void> logAddToCart({ required String productId, required String productName, required double priceCad, int quantity = 1, })`
  - `Future<void> logRemoveFromCart({ required String productId, required String productName, required double priceCad, int quantity = 1, })`
  - `Future<void> logAddToWishlist({ required String productId, required String productName, required double priceCad, })`
  - `Future<void> logRemoveFromWishlist({ required String productId, required String productName, })`
  - `Future<void> logBeginCheckout({ required double valueCad, required int itemCount, })`
  - `Future<void> logAddShippingInfo({ required double valueCad, required double shippingCostCad, required String shippingTier, })`
  - `Future<void> logAddPaymentInfo({ required double valueCad, required String paymentType, })`
  - `Future<void> logPurchase({ required String orderId, required double valueCad, required int itemCount, })`
  - `Future<void> logRefund({required String orderId, required double valueCad})`
  - `Future<void> logSubscriptionStarted({required double priceCad})`
  - `Future<void> logSubscriptionCancelled()`
  - `Future<void> logReviewSubmitted({ required String productId, required double rating, })`
  - `Future<void> logScreenView({required String screenName})`

  Internal deps: `services/orignabase_analytics_service.dart`, `utils/env_config.dart`

### conf_services.dart
**Path**: `lib/services/conf_services.dart`
**Purpose**: Thin wrapper — delegates all config reads to [OrignaBaseConfigService]. Retained so existing callers (`utils.dart`, `orignabase_product_repository.dart`) compile without import changes.

**`ConfigService`**
> Thin wrapper — delegates all config reads to [OrignaBaseConfigService]. Retained so existing callers (`utils.dart`, `orignabase_product_repository.dart`) compile without import changes.
  Methods:
  - `Future<void> initialize({bool skipFetch = false})` -- No-op — initialization is done by [OrignaBaseConfigService] in main.dart.

  Internal deps: `services/orignabase_conf_service.dart`

### orignabase_analytics_service.dart
**Path**: `lib/services/orignabase_analytics_service.dart`
**Purpose**: OrignaBase analytics service. All events are no-ops in emulator, dev, and staging environments. Covers the full GA4 e-commerce funnel + auth + marketplace-specific events.

**`OrignaBaseAnalyticsService`**
> OrignaBase analytics service. All events are no-ops in emulator, dev, and staging environments. Covers the full GA4 e-commerce funnel + auth + marketplace-specific events.
  Methods:
  - `Future<void> logSignUp({required String method})`
  - `Future<void> logLogin({required String method})`
  - `Future<void> logViewItemList({ required String listName, required List<Map<String, dynamic>> items, })`
  - `Future<void> logSelectItem({ required String productId, required String productName, required double priceCad, String listName = '', })`
  - `Future<void> logViewItem({ required String productId, required String productName, required double priceCad, })`
  - `Future<void> logSearch({required String searchTerm})`
  - `Future<void> logAddToCart({ required String productId, required String productName, required double priceCad, int quantity = 1, })`
  - `Future<void> logRemoveFromCart({ required String productId, required String productName, required double priceCad, int quantity = 1, })`
  - `Future<void> logAddToWishlist({ required String productId, required String productName, required double priceCad, })`
  - `Future<void> logRemoveFromWishlist({ required String productId, required String productName, })`
  - `Future<void> logBeginCheckout({ required double valueCad, required int itemCount, })`
  - `Future<void> logAddShippingInfo({ required double valueCad, required double shippingCostCad, required String shippingTier, })`
  - `Future<void> logAddPaymentInfo({ required double valueCad, required String paymentType, })`
  - `Future<void> logPurchase({ required String orderId, required double valueCad, required int itemCount, })`
  - `Future<void> logRefund({ required String orderId, required double valueCad, })`
  - `Future<void> logSubscriptionStarted({required double priceCad})`
  - `Future<void> logSubscriptionCancelled()`
  - `Future<void> logReviewSubmitted({ required String productId, required double rating, })`
  - `Future<void> logScreenView({required String screenName})`

  Internal deps: `utils/app_logger.dart`, `utils/env_config.dart`

### orignabase_conf_service.dart
**Path**: `lib/services/orignabase_conf_service.dart`
**Purpose**: OrignaBase config service. Fetches config key-value pairs from OrignaBase's /config endpoint.

**`OrignaBaseConfigService`**
> OrignaBase config service. Fetches config key-value pairs from OrignaBase's /config endpoint.
  Methods:
  - `Future<void> initialize(OrignaBase ob, {bool skipFetch = false})` -- Initialize with defaults, then fetch from OrignaBase server.
  - `Future<String> getString(String key)` -- Re-fetch a single config value on demand.

  Internal deps: `core/schema/schema_constants.dart`, `utils/app_logger.dart`

### orignabase_digital_service.dart
**Path**: `lib/services/orignabase_digital_service.dart`
**Purpose**: OrignaBase digital download service. for book and software download session generation.

**`OrignaBaseDigitalService`**
> OrignaBase digital download service. for book and software download session generation.

  Internal deps: `core/schema/schema_constants.dart`

### orignabase_notification_service.dart
**Path**: `lib/services/orignabase_notification_service.dart`
**Purpose**: OrignaBase notification service — replaces legacy token storage. Token registration/cleanup goes through OrignaBase push API, while the client-side transport is abstracted behind [PushMessagingClient].

**`OrignaBaseNotificationService`**
> OrignaBase notification service — replaces legacy token storage. Token registration/cleanup goes through OrignaBase push API, while the client-side transport is abstracted behind [PushMessagingClient].
  Static fields: `instance` (OrignaBaseNotificationService), `scaffoldMessengerKey` (GlobalKey<ScaffoldMessengerState>), `navigatorKey` (GlobalKey<NavigatorState>)
  Methods:
  - `void resetForTesting()`
  - `Future<void> clearTokenFromOrignaBase()` -- Removes the device's FCM token from OrignaBase.
  - `void dispose()`
  - `Future<void> initialize(WidgetRef? ref)` -- Initialize the notification service.
  - `Future<void> saveOptOut()`
  - `void handleForegroundMessage(AppRemoteMessage message)` -- Foreground message handler.
  - `Future<void> saveTokenToOrignaBase({String? token})` -- Save FCM token to OrignaBase push service.
  - `void handleNotificationTap(AppRemoteMessage message)` -- Routes to the appropriate screen based on the FCM message payload.

  Internal deps: `core/orignabase_provider.dart`, `core/routes.dart`, `core/schema/schema_constants.dart`, `features/notifications/notification_provider.dart`, `services/push_transport.dart`, `utils/app_logger.dart`, `utils/utils.dart`

### push_transport.dart
**Path**: `lib/services/push_transport.dart`

**`AppNotificationAuthorizationStatus`**

**`AppNotificationSettings`**

**`AppRemoteNotification`**

**`AppRemoteMessage`**

**abstract `PushMessagingClient`**
  Methods:
  - `Future<String?> getToken()`
  - `Future<AppRemoteMessage?> getInitialMessage()`
  - `Future<AppNotificationSettings> requestPermission({ bool alert = true, bool announcement = false, bool badge = true, bool carPlay = false, bool criticalAlert = false, bool provisional = false, bool sound = true, })`

**`NoopPushMessagingClient`**
  Methods:
  - `Future<String?> getToken()`
  - `Future<AppRemoteMessage?> getInitialMessage()`
  - `Future<AppNotificationSettings> requestPermission({ bool alert = true, bool announcement = false, bool badge = true, bool carPlay = false, bool criticalAlert = false, bool provisional = false, bool sound = true, })`

### session_timeout_service.dart
**Path**: `lib/services/session_timeout_service.dart`
**Purpose**: Service to automatically logout users after 15 minutes of inactivity.  SECURITY: Phase 3 - Session timeout implementation Tracks user interactions and signs out after 15 minutes of inactivity.

**`SessionTimeoutService`**
> Service to automatically logout users after 15 minutes of inactivity.  SECURITY: Phase 3 - Session timeout implementation Tracks user interactions and signs out after 15 minutes of inactivity.
  Methods:
  - `void resetInstance()`
  - `String? Function()`
  - `Future<void> handleTimeoutForTesting()`
  - `void configure({ String? Function()` -- Inject app auth callbacks so this service stays backend-agnostic.
  - `Duration getRemainingTime()` -- Get remaining time before timeout
  - `bool isAboutToExpire()` -- Check if session is about to expire (< 5 minutes remaining)
  - `void recordActivity()` -- Call this whenever user interacts with the app (no context needed)
  - `void startMonitoring(GlobalKey<NavigatorState> navigatorKey)` -- Start monitoring user activity. Pass the app's [GlobalKey] of [NavigatorState].
  - `void stopMonitoring()` -- Stop monitoring (when user logs out manually)

  Internal deps: `utils/design_tokens.dart`, `core/schema/schema_constants.dart`

### turnstile_service.dart
**Path**: `lib/services/turnstile_service.dart`
**Purpose**: Cloudflare Turnstile bot-protection service.  Web: renders an invisible Turnstile widget injected in [web/index.html] and returns the challenge token via JS interop.  Mobile/Desktop: always returns null — App Check handles attestation there.

**`TurnstileService`**
> Cloudflare Turnstile bot-protection service.  Web: renders an invisible Turnstile widget injected in [web/index.html] and returns the challenge token via JS interop.  Mobile/Desktop: always returns null — App Check handles attestation there.
  Methods:
  - `Future<String?> getToken()` -- Returns a Turnstile challenge token, or null if not on web / not configured.  The token is consumed once — call [reset] before retrying on error.
  - `void reset()` -- Resets the Turnstile widget so a fresh token can be obtained.

### turnstile_service_stub.dart
**Path**: `lib/services/turnstile_service_stub.dart`
**Purpose**: Non-web stub — mobile/desktop do not request a Turnstile token.

### turnstile_service_web.dart
**Path**: `lib/services/turnstile_service_web.dart`
**Purpose**: Web implementation — JS interop to read the Cloudflare Turnstile token that was rendered by the invisible widget in web/index.html.

### web_auth_redirect_stub.dart
**Path**: `lib/services/web_auth_redirect_stub.dart`

### web_auth_redirect_web.dart
**Path**: `lib/services/web_auth_redirect_web.dart`


---

## Utils (`lib/utils/`)

### animations.dart
**Path**: `lib/utils/animations.dart`
**Purpose**: Custom page route with slide and fade animation

**`SlidePageRoute`**
> Custom page route with slide and fade animation

**`SlideDirection`**

**`AnimatedListItem`**
> Animated list item that fades and slides in
  Methods:
  - `State<AnimatedListItem> createState()`

**`_AnimatedListItemState`**
  Methods:
  - `void initState()`
  - `void dispose()`
  - `Widget build(BuildContext context)`

**`TapScaleAnimation`**
> Tap scale animation wrapper for buttons and cards
  Methods:
  - `State<TapScaleAnimation> createState()`

**`_TapScaleAnimationState`**
  Methods:
  - `void initState()`
  - `void dispose()`
  - `Widget build(BuildContext context)`

**`ShimmerLoading`**
> Shimmer loading effect for placeholder content
  Methods:
  - `State<ShimmerLoading> createState()`

**`_ShimmerLoadingState`**
  Methods:
  - `void initState()`
  - `void dispose()`
  - `Widget build(BuildContext context)`

**`FadeInWidget`**
> Fade in widget on first build
  Methods:
  - `State<FadeInWidget> createState()`

**`_FadeInWidgetState`**
  Methods:
  - `void initState()`
  - `void dispose()`
  - `Widget build(BuildContext context)`

**`AnimatedCounter`**
> Animated counter for numbers
  Methods:
  - `Widget build(BuildContext context)`

**`AnimatedCheckmark`**
> Success checkmark animation
  Methods:
  - `State<AnimatedCheckmark> createState()`

**`_AnimatedCheckmarkState`**
  Methods:
  - `void initState()`
  - `void dispose()`
  - `Widget build(BuildContext context)`

**`_CheckmarkPainter`**
  Methods:
  - `void paint(Canvas canvas, Size size)`
  - `bool shouldRepaint(_CheckmarkPainter oldDelegate)`

**`BounceAnimation`**
> Bounce animation for emphasis
  Methods:
  - `State<BounceAnimation> createState()`

**`_BounceAnimationState`**
  Methods:
  - `void initState()`
  - `void didUpdateWidget(BounceAnimation oldWidget)`
  - `void dispose()`
  - `Widget build(BuildContext context)`

**`NavigatorExtension`**
> Extension for easy navigation with animation

  Internal deps: `utils/design_tokens.dart`

### app_logger.dart
**Path**: `lib/utils/app_logger.dart`
**Purpose**: Centralized logging utility.  - Debug/info logs only print in debug mode. - Warnings add Sentry breadcrumbs. - Errors are captured by Sentry in release mode.

**`AppLogger`**
> Centralized logging utility.  - Debug/info logs only print in debug mode. - Warnings add Sentry breadcrumbs. - Errors are captured by Sentry in release mode.
  Methods:
  - `void d(String message, {String? tag})` -- Debug-level log — only prints in debug mode.
  - `void i(String message, {String? tag})` -- Info-level log — only prints in debug mode.
  - `void w(String message, {String? tag, Object? error})` -- Warning-level log — prints in debug, adds Sentry breadcrumb.
  - `void e( String message, { String? tag, Object? error, StackTrace? stackTrace, })` -- Error-level log — prints in debug, captures to Sentry in release.

### circuit_breaker.dart
**Path**: `lib/utils/circuit_breaker.dart`
**Purpose**: Circuit breaker states

**`CircuitState`**
> Circuit breaker states

**`CircuitBreakerConfig`**
> Configuration for circuit breaker
  Static fields: `paymentDefault` (const), `searchDefault` (const), `lenientDefault` (const)

**`CircuitBreaker`**
> Represents a circuit breaker for external service calls  Usage: ```dart final stripeBreaker = CircuitBreaker( name: 'stripe', config: CircuitBreakerConfig.paymentDefault, );  try { final result = await stripeBreaker.execute( () => stripeApi.createPaymentIntent(...), ); } on CircuitBreakerOpenException catch (e) { // Show degraded mode UI } ```
  Methods:
  - `Future<T> Function()`
  - `void reset()` -- Manually reset the circuit breaker (for testing or admin override)
  - `CircuitBreakerMetrics getMetrics()` -- Get current metrics for monitoring

**`CircuitBreakerMetrics`**
> Metrics for monitoring circuit breaker health
  Methods:
  - `Map<String, dynamic> toJson()`

**`CircuitBreakerOpenException`**
> Exception thrown when circuit breaker is open
  Methods:
  - `String toString()`

**`CircuitBreakerRegistry`**
> Registry to manage multiple circuit breakers
  Methods:
  - `CircuitBreaker get( String name, { CircuitBreakerConfig? config, })` -- Get or create a circuit breaker
  - `Map<String, CircuitBreakerMetrics> getAllMetrics()` -- Get metrics for all circuit breakers
  - `void resetAll()` -- Reset all circuit breakers
  - `void clear()` -- Clear all circuit breakers (mainly for testing)

  Internal deps: `utils/app_logger.dart`

### constants.dart
**Path**: `lib/utils/constants.dart`

**`AppConfig`**
> Application configuration constants
  Static fields: `appName` (String), `supportEmail` (String), `websiteUrl` (String), `currency` (String), `currencySymbol` (String), `autoConfirmDays` (int)

**`CaptureMethod`**
> Capture method for payments
  Methods:
  - `CaptureMethod fromValue(String value)`

**`is`**

**`DeliveryItemCheck`**
> Helper class for checking delivery availability

**`DeliverySpeed`**
> Delivery speed options for checkout
  Methods:
  - `DateTime getEstimatedDeliveryDate()` -- Get delivery date estimate
  - `bool isAvailableForItems( List<DeliveryItemCheck> items, bool isLocalDelivery, )` -- Check if this delivery speed is available for given items Same-day only available for local/perishable items within delivery radius
  - `DeliverySpeed fromValue(String value)`

**`DeliveryStatus`**
> Delivery status enum for individual order items
  Methods:
  - `DeliveryStatus fromValue(String value)` -- Parse from string value

**`is`**
  Methods:
  - `Map<String, dynamic> toMap()`

**`from`**
  Methods:
  - `Map<String, dynamic> toMap()`

**`ShippingQuantityDiscount`**
> Seller-defined delivery option for a product Stored in database under [Fields.deliveryOptions].  Canonical schema uses: type/description/cost/estimatedDays (+ optional volume discounts). Alternate schema uses: speed/isEnabled/price/maxRadiusKm.
  Methods:
  - `Map<String, dynamic> toMap()`

**`SellerDeliveryOption`**
> Documentation for SellerDeliveryOption
  Methods:
  - `SellerDeliveryOption? fromMap(Map<String, dynamic> map)`
  - `New schema(costCents)`
  - `double calculateCostForQuantity(int quantity)` -- Calculate effective shipping cost for a given quantity. Mirrors backend `ShippingQuantityDiscount` logic.
  - `Map<String, dynamic> toMap()`
  - `List<SellerDeliveryOption> defaultOptions()` -- Create default options for a new product

**`UserRoles`**
> User role constants
  Static fields: `admin` (const), `seller` (const), `buyer` (const)

  Internal deps: `core/schema/schema_constants.dart`

### csv_parser.dart
**Path**: `lib/utils/csv_parser.dart`

### deferred_widget.dart
**Path**: `lib/utils/deferred_widget.dart`
**Purpose**: Helper widget for Flutter Web code splitting via deferred imports.  Usage: ```dart import 'package:origna_gta/screens/heavy_screen.dart' deferred as heavy;  DeferredWidget( loader: heavy.loadLibrary, builder: () => const heavy.HeavyScreen(), ) ```  On Flutter Web (dart2js), deferred imports create separate JavaScript chunks that are loaded on demand, reducing initial bundle size. On mobile, deferred loading completes synchronously.

**`DeferredWidget`**
> Helper widget for Flutter Web code splitting via deferred imports.  Usage: ```dart import 'package:origna_gta/screens/heavy_screen.dart' deferred as heavy;  DeferredWidget( loader: heavy.loadLibrary, builder: () => const heavy.HeavyScreen(), ) ```  On Flutter Web (dart2js), deferred imports create separate JavaScript chunks that are loaded on demand, reducing initial bundle size. On mobile, deferred loading completes synchronously.
  Methods:
  - `Future<dynamic> Function()`
  - `Future<void> preload(Future<dynamic> Function()`
  - `State<DeferredWidget> createState()`

**`_DeferredWidgetState`**
  Methods:
  - `void initState()`
  - `Widget build(BuildContext context)`

  Internal deps: `utils/design_tokens.dart`, `widgets/modern_loading_indicator.dart`

### design_tokens.dart
**Path**: `lib/utils/design_tokens.dart`
**Purpose**: 2100 Design System — OrignaGTA Multi-platform: Mobile · Tablet · Desktop · Web Futuristic, modern aesthetic with glassmorphism and fluid animations

**`DesignTokens`**
> Documentation for DesignTokens
  Static fields: `primary` (Color), `secondary` (Color), `tertiary` (Color), `accent` (Color), `digital` (Color), `gradientStart` (Color), `gradientMiddle` (Color), `gradientEnd` (Color)
  Methods:
  - `Primary Palette(Matched to Ecommerce Splash)`
  - `Cornflower Blue(WCAG AA: ≥4.5:1 on #0F0F1E)`
  - `Gradient Definition(Matches index.html splash)`
  - `Text Colors(WCAG 2.1 AA: ≥4.5:1 for normal text, ≥3:1 for large text)`
  - `Derived Semantic(additional shades)`
  - `LinearGradient backgroundGradient({required bool isDark})` -- Background gradient that adapts to light/dark theme.
  - `LinearGradient surfaceGradient({required bool isDark})` -- Surface gradient for screen bodies.

**`GlassContainer`**
> Glassmorphism Container Helper
  Methods:
  - `Widget build(BuildContext context)`

### env_config.dart
**Path**: `lib/utils/env_config.dart`
**Purpose**: Environment Configuration for OrignaGTA Flutter App =====================================================  WHAT'S EMULATED (Local): - OrignaBase Auth - OrignaBase Database - OrignaBase Handlers - OrignaBase Storage  WHAT'S REAL (Even in Emulator Mode): - Cloudflare R2 → Uses emulator/ folder prefix - Stripe → Uses test keys (sk_test_*) - All other external APIs  BACKEND CONTRACT: - `baseUrl` is the public website host and share-link origin. - `orignabaseUrl` is the primary backend for auth, data, and business APIs. - Web bundle served from Hetzner VPS with Caddy (no Firebase Hosting).  USAGE: - Emulator mode: Pass --dart-define=ENVIRONMENT=emulator - Dev mode: Pass --dart-define=ENVIRONMENT=dev - Production mode: Pass --dart-define=ENVIRONMENT=production  VS Code will automatically pass these flags when using launch configurations.

**`AppEnvironment`**
> Environment enumeration

**`EnvConfig`**
> Environment configuration class
  Methods:
  - `String baseUrlFor(AppEnvironment environment)`
  - `String orignabaseUrlFor(AppEnvironment environment)`
  - `Current environment(memoized — safe to call on every rebuild)`
  - `void printInfo()` -- Print environment info (for debugging)

**`String`**

  Internal deps: `utils/app_logger.dart`

### error_messages.dart
**Path**: `lib/utils/error_messages.dart`
**Purpose**: Formats an error code + description for display in the UI.  Format: `Error [CODE]: <description>` Example: `Error [ORIGNA-PAY-001]: Card declined`  Usage: ```dart final msg = ErrorMessages.format(ErrorCodes.payCardDeclined); // → "Error [ORIGNA-PAY-001]: Card declined" ```

**`ErrorMessages`**
  Methods:
  - `String format(String code)` -- Returns a display string for SnackBars and error dialogs. Falls back to a generic message if the code is unrecognized.
  - `String unknown()` -- Formats a generic unknown error with the SYS-999 code.

  Internal deps: `core/errors/error_codes.dart`

### glassmorphism.dart
**Path**: `lib/utils/glassmorphism.dart`
**Purpose**: Glassmorphism design system for OrignaGta Provides blur effects, frosted glass containers, and modern glassmorphic styling

**`GlassAppBar`**
> Glassmorphic appbar header
  Methods:
  - `Widget build(BuildContext context)`

**`GlassBadge`**
> Glassmorphic notification badge
  Methods:
  - `Widget build(BuildContext context)`

**`GlassBlurIntensity`**
> Glassmorphism blur levels

**`GlassButton`**
> Frosted glass button with glassmorphism effect
  Methods:
  - `State<GlassButton> createState()`

**`GlassCard`**
> Glassmorphic card for product/content display
  Methods:
  - `Widget build(BuildContext context)`

**`GlassFloatingActionButton`**
> Glassmorphic floating action button
  Methods:
  - `State<GlassFloatingActionButton> createState()`

**`GlassModal`**
> Glassmorphic modal/dialog background
  Methods:
  - `Widget build(BuildContext context)`

**`_GlassButtonState`**
  Methods:
  - `Widget build(BuildContext context)`

**`_GlassFloatingActionButtonState`**
  Methods:
  - `Widget build(BuildContext context)`
  - `void dispose()`
  - `void initState()`

  Internal deps: `utils/design_tokens.dart`

### image_compression_utils.dart
**Path**: `lib/utils/image_compression_utils.dart`

### responsive_layout.dart
**Path**: `lib/utils/responsive_layout.dart`
**Purpose**: Responsive layout utilities for OrignaGta Multi-platform: Mobile · Tablet · Desktop · Web · Large Display Breakpoints: 320px → 480px → 768px → 1024px → 1280px → 1440px

**`ResponsiveBreakpoints`**
> Documentation for ResponsiveBreakpoints
  Static fields: `mobile` (double), `mobilePlus` (double), `tablet` (double), `desktop` (double), `desktopLg` (double), `desktopXl` (double), `contentMaxWidth` (double), `sidebarWidth` (double)
  Methods:
  - `Standard breakpoints(matching common device sizes)`
  - `Content area(Expanded flex:4)`
  - `double dropdownMaxHeight(BuildContext context)` -- Maximum height for dropdown/popup menus — 40 % of the viewport height. Using a viewport fraction avoids magic pixel values and adapts across screen sizes (phones, tablets, desktops) automatically.
  - `double getFontScale(BuildContext context)` -- Get font scale factor for responsive text
  - `int getGridColumns(BuildContext context)` -- Get grid column count based on screen size
  - `bool isDesktop(BuildContext context)` -- Returns true when the screen is in desktop/web mode (≥1024px)
  - `bool isTablet(BuildContext context)` -- Returns true when the screen is tablet-sized (768–1023px)
  - `bool isMobile(BuildContext context)` -- Returns true when running on a mobile-sized screen (<768px)
  - `EdgeInsets getSafePadding(BuildContext context)` -- Get safe padding for edges (avoids notches, safe areas)
  - `double getSpacing(BuildContext context, SpacingSize size)` -- Get spacing value based on screen size

**`ResponsiveContainer`**
> No-collapse responsive container
  Methods:
  - `Widget build(BuildContext context)`

**`ResponsiveGridView`**
> Responsive grid view
  Methods:
  - `Widget build(BuildContext context)`

**`ResponsiveLayout`**
> Responsive layout builder — Mobile · Tablet · Desktop · Web  Breakpoints (based on [ResponsiveBreakpoints]): - [mobilePlus] covers ALL phones (< 768px, including < 320px). There is no separate `mobile` layout — sub-480px devices use the same layout as larger phones. This is intentional: screens narrower than 320px are negligible in practice and the same layout adapts well enough. - [tablet] covers 768–1023px. - [desktop] covers 1024px+ (web, desktop browsers, large displays).
  Methods:
  - `Widget build(BuildContext context)`

**`ResponsiveText`**
> Responsive text styles
  Methods:
  - `TextStyle body(BuildContext context)`
  - `TextStyle caption(BuildContext context)`
  - `TextStyle heading1(BuildContext context)`
  - `TextStyle heading2(BuildContext context)`
  - `TextStyle heading3(BuildContext context)`

**`SpacingSize`**
  Methods:
  - `Extra small(4-12px)`
  - `Extra large(16-32px)`

### safe_url_launcher.dart
**Path**: `lib/utils/safe_url_launcher.dart`
**Purpose**: Allowed domains for external URL launching. URLs with schemes like `mailto:` are always allowed.

  Internal deps: `utils/app_logger.dart`

### test_keys.dart
**Path**: `lib/utils/test_keys.dart`
**Purpose**: Test Keys for Integration Testing Centralized keys for all testable widgets

**`TestKeys`**
> Test Keys for Integration Testing Centralized keys for all testable widgets
  Static fields: `loginEmailField` (const), `loginPasswordField` (const), `loginNameField` (const), `loginSubmitButton` (const), `loginToggleMode` (const), `homeAddProductButton` (const), `homeSearchBar` (const), `homeProfileButton` (const)

### utils.dart
**Path**: `lib/utils/utils.dart`

**`AppError`**
> Centralized error handler - logs to console and Sentry Use this for all caught errors to ensure visibility
  Methods:
  - `String getMessage(dynamic error, [String? fallback, String? code])` -- Extract user-friendly message from error.  For [OrignaBaseException], returns the backend message (safe — our backend already sanitises messages before raising HttpsError), but filters out any raw database exceptions that might have leaked. For auth/storage/backend exceptions, returns a safe generic message when the raw message may leak internals. For everything else, returns [fallback] to avoid leaking internals.  If [code] is provided it is appended to the message so users can quote it when contacting support: e.g. "Card declined [ORIGNA-PAY-001]". When [code] is omitted the method attempts to infer one automatically via [_inferCode].
  - `void log( dynamic error, { StackTrace? stackTrace, String? context, Map<String, dynamic>? extras, })` -- Log error with optional user message - Logs to debugPrint in development - Sends to Sentry in production
  - `void show( BuildContext context, String userMessage, { dynamic error, StackTrace? stackTrace, String? logContext, Duration duration = const Duration(seconds: 5)` -- Show error to user via SnackBar and log it.  If [userMessage] contains an embedded `[ORIGNA-*]` code the code is extracted and rendered as a small monospace subtitle so users can quote it when contacting support@orignagta.ca.

**`VideoValidationError`**
> Enum for video validation errors

**`_FixedPriceResult`**

  Internal deps: `core/compat/timestamp.dart`, `core/providers.dart`, `core/errors/error_codes.dart`, `core/repositories/orignabase_auth_repository.dart`, `core/routes.dart`, `models/models.dart`, `core/schema/schema_constants.dart`, `utils/responsive_layout.dart`, `utils/app_logger.dart`, `utils/constants.dart`, `utils/design_tokens.dart`, `utils/env_config.dart`


---

## Core -- Providers & Config (`lib/core/`)

### timestamp.dart
**Path**: `lib/core/compat/timestamp.dart`
**Purpose**: Lightweight Timestamp shim used by generated/manual model tests. App code should prefer `DateTime` directly.

**`Timestamp`**
> Lightweight Timestamp shim used by generated/manual model tests. App code should prefer `DateTime` directly.
  Methods:
  - `DateTime toDate()`
  - `int compareTo(Timestamp other)`
  - `String toString()`

### supplier_config.dart
**Path**: `lib/core/config/supplier_config.dart`
**Purpose**: The ONLY currency allowed for selling products on the platform

**`SupplierPlatformConfig`**
> Supplier platform configuration

  Internal deps: `utils/design_tokens.dart`

### validation_constants.dart
**Path**: `lib/core/constants/validation_constants.dart`
**Purpose**: F-74: Centralised validation constants — single source of truth. All email validation across the app MUST use [ValidationConstants.emailRegex].

**`ValidationConstants`**
  Static fields: `emailRegex` (RegExp), `passwordRegex` (RegExp), `minPasswordLength` (int), `maxEmailLength` (int), `minEmailLength` (int), `minNameLength` (int), `maxNameLength` (int), `commonPasswords` (List<String>)

### error_codes.dart
**Path**: `lib/core/errors/error_codes.dart`
**Purpose**: Standardized error codes for OrignaGTA. Format: ORIGNA-{DOMAIN}-{NUMBER}  Users see these codes appended to error messages, e.g.: "Card declined [ORIGNA-PAY-001]" They can quote the code when contacting support@orignagta.ca  Full table: docs/ERROR_CODES.md

**`ErrorCodes`**
  Static fields: `authEmailInUse` (const), `authWrongPassword` (const), `authUserNotFound` (const), `authWeakPassword` (const), `authTooManyRequests` (const), `authGoogleSignInFailed` (const), `authAppleSignInFailed` (const), `authSessionExpired` (const)
  Methods:
  - `PAY domain(Stripe / payments)`
  - `Description table(used by AppError.describe()`
  - `String describe(String code)` -- Returns a short human-readable description for a given code. Used in support UIs and error dialogs.

### orignabase_provider.dart
**Path**: `lib/core/orignabase_provider.dart`
**Purpose**: EnvConfig provider local to this file. Cannot use the one from providers.dart — that would create a circular import (providers.dart imports orignabase_provider.dart, not the other way around).

  Internal deps: `core/providers.dart`, `utils/env_config.dart`

### providers.dart
**Path**: `lib/core/providers.dart`

**`AppAuthProviderInfo`**

**`PublicAuthProviderAvailability`**

**`AppAuthUser`**
  Methods:
  - `AppAuthUser copyWith({ String? uid, String? email, bool? emailVerified, List<AppAuthProviderInfo>? providerData, })`

  Internal deps: `core/orignabase_provider.dart`, `core/repositories/auth_repository.dart`, `core/repositories/cart_repository.dart`, `core/repositories/location_repository.dart`, `core/repositories/order_repository.dart`, `core/repositories/orignabase_auth_repository.dart`, `core/repositories/orignabase_cart_repository.dart`, `core/repositories/orignabase_location_repository.dart`, `core/repositories/orignabase_order_repository.dart`, `core/repositories/orignabase_product_repository.dart`, `core/repositories/orignabase_user_repository.dart`, `core/repositories/product_repository.dart`, `core/repositories/user_repository.dart`, `core/schema/schema_constants.dart`, `models/models.dart`, `services/orignabase_conf_service.dart`, `utils/env_config.dart`, `utils/utils.dart`

### auth_repository.dart
**Path**: `lib/core/repositories/auth_repository.dart`

**abstract `AuthRepository`**
  Methods:
  - `Future<void> confirmPasswordReset(String code, String newPassword)`
  - `Future<void> deleteAccount()`
  - `Future<void> ensureUserDocumentExists()`
  - `Future<bool> isEmailVerified()`
  - `Future<void> registerWithEmail(String email, String password, String name, {bool marketingOptIn = false})`
  - `Future<void> sendEmailVerification()`
  - `Future<void> sendPasswordResetEmail(String email)`
  - `Future<void> signInWithApple()`
  - `Future<void> signInWithEmail(String email, String password)`
  - `Future<void> signInWithGoogle()`
  - `Future<void> signOut()`
  - `Future<bool> validateCurrentUser()` -- Validates that the current user still exists in auth storage Returns true if valid, false if user was deleted (and signs out)
  - `Stream<UserModel?> watchProfile(String userId)`

  Internal deps: `utils/utils.dart`

### cart_repository.dart
**Path**: `lib/core/repositories/cart_repository.dart`

**abstract `CartRepository`**
  Methods:
  - `Future<void> addToCart(String userId, String productId, int quantity, { String? variantId, String? variantTitle, Map<String, String>? variantOptions, String? variantSku, })`
  - `Future<void> clearCart(String userId)`
  - `Future<String?> getProductSellerId(String productId)` -- Fetch the seller ID for a product to prevent self-purchase. Returns null if the product does not exist.
  - `Future<bool> isVariantValid(String productId, String variantId)` -- Returns true if [variantId] exists and is active in the product's variants array. Returns false if the product doesn't exist or the variant is not found/inactive.
  - `Future<void> removeFromCart(String userId, String cartItemId)`
  - `Future<void> updateBuyerNote(String userId, String cartItemId, String? note)`
  - `Future<void> updateQuantity(String userId, String cartItemId, int quantity)`

  Internal deps: `utils/utils.dart`

### location_repository.dart
**Path**: `lib/core/repositories/location_repository.dart`

**abstract `LocationRepository`**

### notification_repository.dart
**Path**: `lib/core/repositories/notification_repository.dart`
**Purpose**: Notification repository backed by OrignaBase subcollections.

**`NotificationRepository`**
> Notification repository backed by OrignaBase subcollections.
  Methods:
  - `Future<void> markAllRead(String uid)` -- Mark all unread notifications as read for a user.
  - `Future<void> markRead(String uid, String notificationId)` -- Mark a single notification as read.

  Internal deps: `core/orignabase_provider.dart`, `core/schema/schema_constants.dart`

### order_query_helpers.dart
**Path**: `lib/core/repositories/order_query_helpers.dart`

**`OrderQueryHelpers`**
> Extracted realtime stream helpers for [OrignaBaseOrderRepository].  Contains the generic _watchOrders pattern and session-based polling so the main repository file stays focused on the public API surface.
  Static fields: `activePaymentStatuses` (final)
  Methods:
  - `Order docToOrder(Document doc)`
  - `String paymentStatusToString(PaymentStatus status)` -- Converts [PaymentStatus] enum to its database string value.
  - `String normalizeId(String id)` -- Strips `collection:` prefix for flexible ID comparison.
  - `Query Function()`
  - `Future<void> seed()`
  - `Stream<models.Order?> watchPaidOrderBySessionImpl(String sessionId)` -- Session lookup: short-lived stream that polls until the order appears. WebSocket is not suitable here because we don't know the order ID upfront.
  - `Future<void> fetch()`

**`to`**

  Internal deps: `core/schema/schema_constants.dart`, `models/enum_extensions.dart`, `models/generated/base_models.dart`, `models/generated/models.dart`

### order_repository.dart
**Path**: `lib/core/repositories/order_repository.dart`

**abstract `OrderRepository`**
  Methods:
  - `Future<void> approveShippingCost(String orderId, bool approved)` -- Approves or rejects a seller-submitted shipping cost update for [orderId].
  - `Future<void> capturePayment(String orderId)` -- Captures the pre-authorized Stripe payment for [orderId]. Must be called after buyer confirms delivery (or auto-capture cron fires).
  - `Future<void> confirmReceipt(String orderId, {String? productId})` -- Buyer confirms receipt of [orderId]; triggers capture if not yet done.
  - `Future<models.Order?> fetchOrderById(String orderId)` -- Fetches a single order by document ID. Returns null if the document does not exist.
  - `Future<void> updateItemStatus( String orderId, String itemId, String status, { String? trackingNumber, String? carrier, String? carrierNote, })` -- Updates the shipping status of a specific item within an order.  [itemId] is the product ID of the item to update. [trackingNumber], [carrier], and [carrierNote] are optional and only relevant for the `shipped` status.
  - `Future<void> updateLastSession( String userId, String sessionId, String orderId, )` -- Persists the last Stripe session and order IDs on the user document for post-payment recovery (e.g., polling the success screen).
  - `Future<void> updateShippingCost( String orderId, int newShippingCostCents, String reason, )` -- Submits a revised shipping cost for [orderId] with an audit [reason].
  - `Stream<models.Order?> watchPaidOrderBySession(String sessionId)` -- Watches a single order matched by Stripe session ID, resolving only once it is captured. Returns null if no matching captured order exists yet.

  Internal deps: `models/generated/models.dart`

### orignabase_auth_repository.dart
**Path**: `lib/core/repositories/orignabase_auth_repository.dart`
**Purpose**: Returns the device's preferred language if it's one we support (en/fr), else 'en'.

**`OrignaBaseAuthException`**
> OrignaBase-specific auth exception that mirrors common auth error codes. so the existing error handling in login_viewmodel.dart works unchanged.
  Methods:
  - `String toString()`

**`OrignaBaseAuthRepository`**
> OrignaBase implementation of [AuthRepository].
  Methods:
  - `Future<void> registerWithEmail( String email, String password, String name, { bool marketingOptIn = false, })`
  - `Future<void> signInWithEmail(String email, String password)`
  - `Future<void> signInWithGoogle()`
  - `Future<void> signInWithApple()`
  - `Future<void> signOut()`
  - `Future<void> sendEmailVerification()`
  - `Future<bool> isEmailVerified()`
  - `Future<void> sendPasswordResetEmail(String email)`
  - `Future<void> confirmPasswordReset(String code, String newPassword)`
  - `Future<void> deleteAccount()`
  - `Future<void> ensureUserDocumentExists()`
  - `Future<bool> validateCurrentUser()`
  - `Stream<UserModel?> watchProfile(String userId)`
  - `SDK exceptions(NotFoundException, AuthException, etc.)`

  Internal deps: `core/constants/validation_constants.dart`, `core/schema/schema_constants.dart`, `services/orignabase_notification_service.dart`, `utils/app_logger.dart`, `utils/utils.dart`, `utils/safe_url_launcher.dart`

### orignabase_cart_repository.dart
**Path**: `lib/core/repositories/orignabase_cart_repository.dart`
**Purpose**: OrignaBase implementation of [CartRepository].  Cart items are stored as a subcollection: users/{userId}/cart/{docId}. Document IDs are deterministic: `productId` or `productId_variantId`.

**`OrignaBaseCartRepository`**
> OrignaBase implementation of [CartRepository].  Cart items are stored as a subcollection: users/{userId}/cart/{docId}. Document IDs are deterministic: `productId` or `productId_variantId`.
  Static fields: `maxCartItemQuantity` (int), `minCartItemQuantity` (int)
  Methods:
  - `Future<void> addToCart( String userId, String productId, int quantity, { String? variantId, String? variantTitle, Map<String, String>? variantOptions, String? variantSku, })`
  - `Future<void> clearCart(String userId)`
  - `Future<String?> getProductSellerId(String productId)`
  - `Future<bool> isVariantValid(String productId, String variantId)`
  - `Future<void> removeFromCart(String userId, String cartItemId)`
  - `Future<void> updateBuyerNote(String userId, String cartItemId, String? note)`
  - `Future<void> updateQuantity(String userId, String cartItemId, int quantity)`

  Internal deps: `core/repositories/cart_repository.dart`, `core/schema/schema_constants.dart`, `models/models.dart`

### orignabase_location_repository.dart
**Path**: `lib/core/repositories/orignabase_location_repository.dart`
**Purpose**: OrignaBase location repository.

**`OrignaBaseLocationRepository`**
> OrignaBase location repository.

  Internal deps: `core/schema/schema_constants.dart`

### orignabase_notification_repository.dart
**Path**: `lib/core/repositories/orignabase_notification_repository.dart`
**Purpose**: OrignaBase implementation of the notification repository.  Notifications are stored in the flat [Collections.notifications] collection with a [Fields.userId] field referencing the owner.

**`OrignaBaseNotificationRepository`**
> OrignaBase implementation of the notification repository.  Notifications are stored in the flat [Collections.notifications] collection with a [Fields.userId] field referencing the owner.
  Methods:
  - `Future<void> markAllRead(String uid)` -- Marks all unread notifications as read using batch update.  Silently succeeds when the user has no notifications (list returns empty or 403 due to null resource context on the SurrealDB rule).
  - `Future<void> markRead(String uid, String notificationId)` -- Marks a single notification as read.  Silently succeeds when the notification does not exist (non-fatal).

  Internal deps: `core/schema/schema_constants.dart`, `utils/utils.dart`

### orignabase_order_repository.dart
**Path**: `lib/core/repositories/orignabase_order_repository.dart`
**Purpose**: OrignaBase implementation of [OrderRepository].  Realtime stream logic is extracted into [OrderQueryHelpers]. This file focuses on the public API surface and mutation endpoints.

**`OrignaBaseOrderRepository`**
> OrignaBase implementation of [OrderRepository].  Realtime stream logic is extracted into [OrderQueryHelpers]. This file focuses on the public API surface and mutation endpoints.
  Methods:
  - `Order docToOrder(Document doc)`
  - `Future<void> approveShippingCost(String orderId, bool approved)`
  - `Future<void> capturePayment(String orderId)`
  - `Future<void> confirmReceipt(String orderId, {String? productId})`
  - `Future<models.Order?> fetchOrderById(String orderId)`
  - `Future<void> updateItemStatus( String orderId, String itemId, String status, { String? trackingNumber, String? carrier, String? carrierNote, })`
  - `Future<void> updateLastSession( String userId, String sessionId, String orderId, )`
  - `Future<void> updateShippingCost( String orderId, int newShippingCostCents, String reason, )`
  - `Stream<models.Order?> watchPaidOrderBySession(String sessionId)`

  Internal deps: `core/repositories/order_repository.dart`, `core/repositories/order_query_helpers.dart`, `core/schema/schema_constants.dart`, `models/generated/models.dart`

### orignabase_product_repository.dart
**Path**: `lib/core/repositories/orignabase_product_repository.dart`
**Purpose**: OrignaBase implementation of [ProductRepository].  Search/query logic is in [ProductSearchHelpers]. Image upload logic is in [ProductImageHelpers].

**`OrignaBaseProductRepository`**
> OrignaBase implementation of [ProductRepository].  Search/query logic is in [ProductSearchHelpers]. Image upload logic is in [ProductImageHelpers].
  Methods:
  - `Product docToProduct(Document doc)`
  - `Future<String> createProductAtomic( Product product, List<Uint8List> imageBytes, { List<String>? testImageUrls, String? bookSourceUrl, })`
  - `Future<void> deleteProduct(String productId)`
  - `Future<Product?> fetchProductById(String productId)`
  - `Future<ProductQueryResult> fetchProducts({ String? searchQuery, int? categoryId, String? subcategory, String? lastDocumentId, int pageSize = 20, SortOption sortOption = SortOption.relevance, int? minPriceCents, int? maxPriceCents, })`
  - `String generateProductId()`
  - `Future<Product?> getProductBySlug(String slug)`
  - `Future<String?> getUploadUrl(String fileName)`
  - `Future<void> submitRating( String orderId, String productId, int rating, { List<String>? reviewImageUrls, String? reviewText, })`
  - `Future<void> submitRatingAtomic( String orderId, String productId, int rating, { List<Uint8List>? reviewImages, String? reviewText, })`
  - `Future<void> toggleFavorite(String userId, String productId)`
  - `Future<void> updateProduct( String productId, Map<String, dynamic> data, )`
  - `Future<String?> uploadProductVideo(XFile videoFile, String sellerId)`
  - `Stream<int> watchUnansweredQuestionsCount(String sellerId)`
  - `Future<void> fetch()`

  Internal deps: `utils/app_logger.dart`, `core/compat/timestamp.dart`, `core/repositories/product_repository.dart`, `core/repositories/product_search_helpers.dart`, `core/repositories/product_image_helpers.dart`, `core/schema/schema_constants.dart`, `models/generated/models.dart`

### orignabase_user_repository.dart
**Path**: `lib/core/repositories/orignabase_user_repository.dart`

**`OrignaBaseUserRepository`**
> OrignaBase implementation of [UserRepository].  User profile watching uses OrignaBase document-level `.snapshots()`. Address subcollection uses collection-level `.snapshots()`. Seller account status uses polling since it combines two collections.
  Methods:
  - `Address CRUD(direct OrignaBase operations)`
  - `Future<String> addBuyerAddress(Address address)`
  - `Future<void> deleteBuyerAddress(String addressId)`
  - `Future<SellerAccountStatus> getSellerAccountStatus(String userId)`
  - `Future<UserModel?> getUserProfile(String userId)`
  - `Future<void> recordTermsAcceptance()`
  - `Future<void> setDefaultBuyerAddress(String addressId)`
  - `Future<void> updateBuyerAddress(String addressId, Address address)`
  - `Future<void> updateNotificationPreferences( String userId, { bool? notifyNewProducts, bool? notifyTrending, })`
  - `Future<void> updatePreferredLanguage(String userId, String lang)`
  - `void Function()`
  - `Future<void> fetchOnce()`
  - `Stream<SellerAccountStatus> watchSellerAccountStatus(String userId)`

  Internal deps: `core/repositories/user_repository.dart`, `core/schema/schema_constants.dart`, `utils/constants.dart`, `utils/app_logger.dart`, `utils/utils.dart`

### product_image_helpers.dart
**Path**: `lib/core/repositories/product_image_helpers.dart`
**Purpose**: Extracted image upload helpers for [OrignaBaseProductRepository].  Handles presigned URL generation, image upload with retry, MIME detection, and review image uploads. Stateless — depends only on [OrignaBase] and an [http.Client].

**`ProductImageHelpers`**
> Extracted image upload helpers for [OrignaBaseProductRepository].  Handles presigned URL generation, image upload with retry, MIME detection, and review image uploads. Stateless — depends only on [OrignaBase] and an [http.Client].
  Methods:
  - `Future<String?> uploadSingleImage( Uint8List bytes, String productId, int index, )` -- Uploads a single product image with retry logic (up to 3 attempts).
  - `String detectImageMimeType(Uint8List bytes)` -- Detects the MIME type of an image from its magic bytes.

### product_repository.dart
**Path**: `lib/core/repositories/product_repository.dart`
**Purpose**: Shared sanitization for product data before writing to database. Used by both concrete repository implementations.

**`ProductQueryResult`**
> Documentation for ProductQueryResult

**abstract `ProductRepository`**
  Methods:
  - `Future<String> createProductAtomic( Product product, List<Uint8List> imageBytes, { List<String>? testImageUrls, String? bookSourceUrl, })`
  - `Future<void> deleteProduct(String productId)`
  - `Future<Product?> fetchProductById(String productId)`
  - `Future<ProductQueryResult> fetchProducts({ String? searchQuery, int? categoryId, String? subcategory, String? lastDocumentId, int pageSize = 20, SortOption sortOption = SortOption.relevance, int? minPriceCents, int? maxPriceCents, })`
  - `String generateProductId()`
  - `Future<Product?> getProductBySlug(String slug)`
  - `Future<String?> getUploadUrl(String fileName)`
  - `Future<void> submitRating( String orderId, String productId, int rating, { List<String>? reviewImageUrls, String? reviewText, })`
  - `Future<void> submitRatingAtomic( String orderId, String productId, int rating, { List<Uint8List>? reviewImages, String? reviewText, })`
  - `Future<void> toggleFavorite(String userId, String productId)`
  - `Future<void> updateProduct(String productId, Map<String, dynamic> data)`
  - `Future<String?> uploadProductVideo(XFile videoFile, String sellerId)`
  - `Stream<int> watchUnansweredQuestionsCount(String sellerId)`

  Internal deps: `core/compat/timestamp.dart`, `core/schema/schema_constants.dart`, `models/generated/models.dart`

### product_search_helpers.dart
**Path**: `lib/core/repositories/product_search_helpers.dart`
**Purpose**: Extracted search/query helpers for [OrignaBaseProductRepository].  These are pure functions (+ OrignaBase collection refs) so they can be unit-tested in isolation without instantiating the full repository.

**`ProductSearchHelpers`**
> Extracted search/query helpers for [OrignaBaseProductRepository].  These are pure functions (+ OrignaBase collection refs) so they can be unit-tested in isolation without instantiating the full repository.
  Methods:
  - `Product docToProduct(Document doc)`
  - `Future<ProductQueryResult> fetchProductsImpl({ String? searchQuery, int? categoryId, String? subcategory, String? lastDocumentId, int pageSize = 20, SortOption sortOption = SortOption.relevance, int? minPriceCents, int? maxPriceCents, })` -- Fetches products matching optional filters with cursor pagination.
  - `Future<Product?> getProductBySlugImpl(String slug)` -- Looks up a single active product by its URL slug.
  - `Future<Product?> fetchProductByIdImpl(String productId)` -- Fetches a single active product by ID.

  Internal deps: `core/schema/schema_constants.dart`, `models/generated/models.dart`, `utils/app_logger.dart`

### user_repository.dart
**Path**: `lib/core/repositories/user_repository.dart`
**Purpose**: Documentation for SellerAccountStatus

**`SellerAccountStatus`**
> Documentation for SellerAccountStatus
  Methods:
  - `Identity document(ID, passport, or driver\'s license)`
  - `Insurance Number(SIN)`

**abstract `UserRepository`**
  Methods:
  - `Future<String> addBuyerAddress(Address address)`
  - `Future<void> deleteBuyerAddress(String addressId)`
  - `Future<SellerAccountStatus> getSellerAccountStatus(String userId)`
  - `Future<UserModel?> getUserProfile(String userId)`
  - `Future<void> recordTermsAcceptance()`
  - `Future<void> setDefaultBuyerAddress(String addressId)`
  - `Future<void> updateBuyerAddress(String addressId, Address address)`
  - `Future<void> updateNotificationPreferences( String userId, { bool? notifyNewProducts, bool? notifyTrending, })`
  - `Future<void> updatePreferredLanguage(String userId, String lang)`
  - `Stream<SellerAccountStatus> watchSellerAccountStatus(String userId)`

  Internal deps: `utils/utils.dart`

### routes.dart
**Path**: `lib/core/routes.dart`
**Purpose**: Named route constants and typed argument classes for the app. Used with Navigator.pushNamed() and onGenerateRoute.  NEVER pass raw `Map<String, dynamic>` as route arguments. Use the typed classes below — they are compile-time safe.

**`AppRoutes`**
> Documentation for AppRoutes
  Static fields: `home` (String), `login` (String), `cart` (String), `profile` (String), `orders` (String), `orderDetail` (String), `addProduct` (String), `editProduct` (String)

**`ChatArgs`**
> Arguments for [AppRoutes.chat].

**`CheckoutArgs`**
> Arguments for [AppRoutes.checkout].

**`EditProductArgs`**
> Arguments for [AppRoutes.editProduct]. Wraps [Product] for consistency and future extensibility.

**`OrderDetailArgs`**
> Arguments for [AppRoutes.orderDetail].

**`ReturnRequestArgs`**
> Arguments for [AppRoutes.returnRequest].

**`ProductDetailsArgs`**
> Arguments for [AppRoutes.productDetails].

**`ProductSlugArgs`**
> Arguments for [AppRoutes.productBySlug].

  Internal deps: `models/generated/models.dart`, `models/models.dart`

### schema_constants.dart
**Path**: `lib/core/schema/schema_constants.dart`
**Purpose**: Standard address labels

**`AddressLabelValues`**
  Static fields: `home` (const), `work` (const), `other` (const)

**`AdminActionValues`**
  Static fields: `paymentProviderUpdate` (const), `stockUpdate` (const), `orderRefund` (const), `reviewDelete` (const), `reviewFlag` (const)

**`fields`**
  Static fields: `turnstileToken` (const), `eulaAccepted` (const), `ageVerificationAccepted` (const), `add` (const), `remove` (const), `reason` (const), `code` (const), `provider` (const)

**`ApiKeys`**
  Static fields: `turnstileToken` (const), `eulaAccepted` (const), `ageVerificationAccepted` (const), `add` (const), `remove` (const), `reason` (const), `code` (const), `provider` (const)

**`BusinessRules`**
  Static fields: `platformFeePercent` (const), `autoConfirmDays` (const), `authorizationExpiryDays` (const), `returnWindowDays` (const), `maxCaptureAttempts` (const), `defaultCurrency` (const), `allowedShippingCountries` (const), `ordersPageSize` (const)

**`CancellationReasonValues`**
  Static fields: `buyerRequested` (const), `sellerCancelled` (const), `shippingRejected` (const), `paymentFailed` (const), `expired` (const)

**`CarrierValues`**
  Static fields: `ups` (const), `fedex` (const), `canadaPost` (const), `purolator` (const), `dhl` (const), `usps` (const), `maritime` (const), `other` (const)

**`CartVerificationReasonValues`**
  Static fields: `deactivated` (const)

**`CategoryIds`**
  Static fields: `electronics` (const), `computers` (const), `gaming` (const), `homeKitchen` (const), `fashion` (const), `shoesAccessories` (const), `jewelryWatches` (const), `beautyPersonalCare` (const)

**`CloudFunctionEndpoints`**
  Static fields: `getAddressSuggestions` (const), `deleteAccount` (const), `createUserProfile` (const), `exportUserData` (const), `updateUserRoles` (const), `suspendSeller` (const), `unsuspendSeller` (const), `adminUpdateProductStock` (const)
  Methods:
  - `Review helpfulness(N-04)`
  - `MANAGEMENT ENDPOINTS(F-006)`

**`Collections`**
  Static fields: `users` (const), `products` (const), `orders` (const), `payouts` (const), `refunds` (const), `webhookLogs` (const), `webhookEvents` (const), `securityAlerts` (const)
  Methods:
  - `Email infrastructure(backend-only — never accessed from client)`
  - `Financial audit(backend-only)`

**`ConfirmationValues`**
  Static fields: `deleteMyAccount` (const)

**`ConsentMethodValues`**
  Static fields: `signup` (const), `signupForm` (const), `googleOauth` (const), `appleOauth` (const), `checkbox` (const), `doubleOptIn` (const), `implied` (const), `userPreference` (const)

**`CountryValues`**
  Static fields: `canada` (const), `canadaCode` (const), `all` (const)

**`CouponDiscountTypeValues`**
  Static fields: `percent` (const), `fixedCents` (const), `all` (const)

**`CronLockStatusValues`**
  Static fields: `running` (const), `completed` (const)

**`DeliveryItemStatusTransitions`**
  Static fields: `validTransitions` (const)

**`DeliveryStatusValues`**
  Static fields: `pending` (const), `shipped` (const), `delivered` (const), `refunded` (const), `all` (const)

**`DeliveryTypeValues`**
  Static fields: `pickup` (const), `standard` (const), `express` (const), `sameDay` (const), `localDelivery` (const), `international` (const), `internationalExpress` (const), `custom` (const)

**`DigitalPlatformValues`**
  Static fields: `macos` (const), `windows` (const), `linux` (const), `all` (const)

**`DigitalTypeValues`**
  Static fields: `software` (const), `book` (const), `all` (const)

**`DiscountTypeValues`**
  Static fields: `percent` (const), `fixed` (const), `flatRate` (const), `all` (const)

**`Documents`**
  Static fields: `paymentProviders` (const)

**`EmailConfig`**
  Static fields: `supportEmail` (const), `senderName` (const), `copyrightText` (const), `appTagline` (const), `prodUrl` (const), `physicalAddress` (const), `gstHstNumber` (const), `unsubscribeUrl` (const)

**`ErrorCodeValues`**
  Static fields: `priceChanged` (const)

**`ExternalUrls`**
  Static fields: `stripeDashboard` (const), `buyerProtectionUrl` (const), `geoapifyBase` (const)

**`Fields`**
  Static fields: `createdAt` (const), `dateCreated` (const), `updatedAt` (const), `version` (const), `schemaVersion` (const), `savedAt` (const), `deletedAt` (String), `deletedBy` (String)
  Methods:
  - `COMMON TIMESTAMPS(used across multiple collections)`
  - `MFA FIELDS(admin only)`
  - `FIELD NAMES(used in database deserialization fallbacks)`
  - `TAX KEYS(used in JSON API responses)`

**`FilterValues`**
  Static fields: `all` (const)

**`GeoValues`**
  Static fields: `countryCanada` (const)

**`LanguageValues`**
  Static fields: `english` (const), `french` (const)

**`LicenseStatusValues`**
  Static fields: `active` (const), `revoked` (const), `all` (const)

**`LocalStorageKeys`**
  Static fields: `recentlyViewed` (const), `recentSearches` (const)

**`NotificationTypes`**
  Static fields: `orderStatus` (const), `orderUpdate` (const), `newMessage` (const), `promo` (const), `system` (const), `account` (const), `returnRequest` (const), `returnStatus` (const)

**`OrderEventTypes`**
  Static fields: `statusChanged` (const), `paymentAuthorized` (const), `paymentCaptured` (const), `paymentFailed` (const), `refundIssued` (const), `itemShipped` (const), `itemDelivered` (const), `cancellationConfirmed` (const)

**`OrderItemIdValues`**
  Static fields: `all` (const)

**`OrderStatusValues`**
  Static fields: `pending` (const), `pendingPayment` (const), `confirmed` (const), `processing` (const), `shipped` (const), `inTransit` (const), `delivered` (const), `cancelled` (const)

**`PaymentProviderValues`**
  Static fields: `stripe` (const), `all` (const)

**`PaymentStatusValues`**
  Static fields: `awaitingPayment` (const), `processing` (const), `paid` (const), `paymentFailed` (const), `refunded` (const), `partiallyRefunded` (const), `sessionExpired` (const), `authorized` (const)
  Methods:
  - `Transitional states(internal use, not stored long-term)`

**`PayoutStatusValues`**
  Static fields: `pending` (const), `processing` (const), `completed` (const), `partial` (const), `failed` (const), `reversed` (const), `partiallyReversed` (const), `reversedDispute` (const)

**`PlaceholderAddressValues`**
  Static fields: `unknownText` (const), `defaultState` (const), `defaultPostalCode` (const), `defaultCountry` (const)

**`PolicyVersionValues`**
  Static fields: `defaultVersion` (const)

**`ProductConditionValues`**
  Static fields: `newCondition` (const), `likeNew` (const), `good` (const), `fair` (const), `forParts` (const), `all` (const)

**`ProductLifecycleStatusValues`**
  Static fields: `draft` (const), `underReview` (const), `approved` (const), `active` (const), `paused` (const), `archived` (const), `rejected` (const)

**`ProvinceCodeValues`**
  Static fields: `alberta` (const), `britishColumbia` (const), `manitoba` (const), `newBrunswick` (const), `newfoundland` (const), `northwestTerritories` (const), `novaScotia` (const), `nunavut` (const)

**`RateLimitActions`**
  Static fields: `verifyCart` (const), `createCheckout` (const), `stripeWebhook` (const), `unsubscribe` (const), `exportData` (const), `mfaEnroll` (const), `mfaVerify` (const), `mfaDisable` (const)

**`RefundReasonValues`**
  Static fields: `returnApproved` (const), `outOfStock` (const), `buyerRequested` (const), `damaged` (const), `incorrectItem` (const)

**`RemoteConfigKeys`**
  Static fields: `geoapifyApiKey` (const), `imageBaseUrl` (const), `sentryDnsKey` (const), `googleWebClientId` (const)

**`ReturnStatusValues`**
  Static fields: `requested` (const), `approved` (const), `labelIssued` (const), `received` (const), `refunded` (const), `rejected` (const), `escalated` (const)

**`SchemaRegistry`**
  Static fields: `timestampField` (const)
  Methods:
  - `String getTimestampField(String collection)` -- Get the correct timestamp field name for a collection.

**`SecurityAlertTypes`**
  Static fields: `disputeCreated` (const), `disputeFundsReinstated` (const), `roleChange` (const), `sellerSuspended` (const), `sellerUnsuspended` (const), `paymentProviderDisabled` (const), `refundReversalFailed` (const), `payoutFailed` (const)

**`SeverityLevels`**
  Static fields: `low` (const), `medium` (const), `high` (const), `critical` (const)

**`ShippingApprovalStatusValues`**
  Static fields: `notRequired` (const), `pending` (const), `approved` (const), `rejected` (const), `all` (const)

**`ShippingSourceValues`**
  Static fields: `internationalSupplier` (const), `internationalGeneric` (const), `domestic` (const)

**`SortOption`**
> Sort options for product listings. Each maps to a specific Meilisearch sort parameter.

**`StripeConstants`**
  Static fields: `reverseCharge` (const), `shippingReference` (const), `taxExemptNone` (const), `addressSourceShipping` (const), `addressSource` (const), `value` (const), `modePayment` (const), `paymentMethodCard` (const)
  Methods:
  - `Calculation keys(Stripe Tax API specifically uses these names)`

**`StripeEventTypes`**
  Static fields: `checkoutCompleted` (const), `asyncPaymentSucceeded` (const), `asyncPaymentFailed` (const), `sessionExpired` (const), `paymentIntentSucceeded` (const), `paymentIntentPaymentFailed` (const), `paymentIntentCanceled` (const), `chargeRefunded` (const)

**`SubcategoryConstants`**
  Methods:
  - `List<String> forCategoryId(int categoryId)` -- Lookup subcategories by category ID (matches productCategories list in utils.dart).

**`SubscriptionStatusValues`**
  Static fields: `active` (const), `canceled` (const), `inactive` (const), `pastDue` (const), `incomplete` (const), `incompleteExpired` (const), `trialing` (const), `unpaid` (const)

**`SupplierCurrencyValues`**
  Static fields: `cad` (const), `usd` (const), `eur` (const), `gbp` (const), `cny` (const), `jpy` (const), `krw` (const), `inr` (const)

**`SupplierTypeValues`**
  Static fields: `aliexpress` (const), `dhgate` (const), `alibaba` (const), `s1688` (const), `temu` (const), `cjdropshipping` (const), `local` (const), `other` (const)
  Methods:
  - `International suppliers(non-local)`

**`TransactionSentinel`**
  Static fields: `alreadyRefunded` (const), `refunded` (const)

**`UIMessages`**
  Static fields: `sessionExpired` (const), `sessionExpiredTitle` (const)

**`UserRoleValues`**
  Static fields: `admin` (const), `seller` (const), `buyer` (const), `all` (const)

**`WarehouseTypeValues`**
  Static fields: `warehouse` (const), `personal` (const), `all` (const)

**`WebhookResponseStatus`**
  Static fields: `processed` (const), `ignored` (const), `error` (const)

**`WebhookStatusValues`**
  Static fields: `processing` (const), `completed` (const), `failed` (const), `all` (const)

**`ApiEndpoints`**
  Static fields: `authDeleteAccount` (const), `usersProfileGet` (const), `usersProfileUpdate` (const), `usersCreateProfile` (const), `usersNotificationPreferences` (const), `productsCreateAtomic` (const), `productsUploadImages` (const), `productsDelete` (const)
  Methods:
  - `Route matrix(distance calculation)`

**`DeepLinkParams`**
  Static fields: `mode` (const), `oobCode` (const), `sessionId` (const), `orderId` (const), `productId` (const), `productTitle` (const), `modeResetPassword` (const)

### theme_provider.dart
**Path**: `lib/core/theme_provider.dart`
**Purpose**: Controls the app-wide theme mode (light / dark / system). Defaults to [ThemeMode.dark] — OrignaGTA is a dark-first app. The OS preference is intentionally overridden to guarantee consistent dark backgrounds across all platforms (avoids white-text-on-white-bg on web).


---

## Shared Widgets (`lib/widgets/shared/`)

### cart_badge.dart
**Path**: `lib/widgets/shared/cart_badge.dart`
**Purpose**: Shared cart badge widget used across the app.  Two modes: - **Animated** (`animated: true`): scale/pulse hover effects, email verification before navigation. Used in the home hero section. - **Simple** (`animated: false`): plain icon button with count badge. Used in [CustomAppBar].

**`CartBadge`**
> Shared cart badge widget used across the app.  Two modes: - **Animated** (`animated: true`): scale/pulse hover effects, email verification before navigation. Used in the home hero section. - **Simple** (`animated: false`): plain icon button with count badge. Used in [CustomAppBar].
  Methods:
  - `ConsumerState<CartBadge> createState()`

**`_CartBadgeState`**
  Methods:
  - `void initState()`
  - `void dispose()`
  - `Widget build(BuildContext context)`

  Internal deps: `core/providers.dart`, `core/routes.dart`, `features/cart/cart_provider.dart`, `utils/design_tokens.dart`, `utils/utils.dart`

### filter_chip_widget.dart
**Path**: `lib/widgets/shared/filter_chip_widget.dart`

**`FilterChipWidget`**
  Methods:
  - `Widget build(BuildContext context)`

  Internal deps: `utils/design_tokens.dart`

### quantity_button.dart
**Path**: `lib/widgets/shared/quantity_button.dart`
**Purpose**: Shared quantity +/- button used on product detail and cart item screens.  [isDark] controls the active icon color in dark mode. [useHaptic] enables haptic feedback on tap (default: false).

**`QuantityButton`**
> Shared quantity +/- button used on product detail and cart item screens.  [isDark] controls the active icon color in dark mode. [useHaptic] enables haptic feedback on tap (default: false).
  Methods:
  - `Widget build(BuildContext context)`

  Internal deps: `utils/design_tokens.dart`

### trending_badge.dart
**Path**: `lib/widgets/shared/trending_badge.dart`
**Purpose**: Shared trending badge used by product cards. HOT badge (score >= 50) uses fire gradient; RISING badge uses teal gradient.

**`TrendingBadge`**
> Shared trending badge used by product cards. HOT badge (score >= 50) uses fire gradient; RISING badge uses teal gradient.
  Methods:
  - `Widget build(BuildContext context)`

  Internal deps: `utils/design_tokens.dart`
