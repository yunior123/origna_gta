# Services Layer Reference

> **Purpose**: Services are stateless, platform-agnostic functions that wrap external APIs, platform features, and third-party integrations. ViewModels call Services, Services never call ViewModels.

---

## Architecture Position

```
┌─────────────────────────────────────────────────────────┐
│                   VIEWMODELS                             │
│  - Call Services for external operations                │
│  - Never call APIs directly                            │
└──────────────────────┬──────────────────────────────────┘
                       │ Service calls
                       ▼
┌─────────────────────────────────────────────────────────┐
│                    SERVICES                              │
│  - Stateless, pure functions                            │
│  - Wrap APIs, platform features                        │
│  - No business logic (that's ViewModels)               │
│  - Single responsibility per service                   │
└──────────────────────┬──────────────────────────────────┘
                       │ API calls
                       ▼
┌─────────────────────────────────────────────────────────┐
│              EXTERNAL APIS / PLATFORMS                   │
│  - OrignaBase SDK, Stripe, Firebase, etc.              │
└─────────────────────────────────────────────────────────┘
```

---

## Service Catalog

### Core Services

| Service | File | Purpose |
|---------|------|---------|
| `OrignaBaseConfigService` | `orignabase_conf_service.dart` | Remote config fetching |
| `OrignaBaseAnalyticsService` | `orignabase_analytics_service.dart` | Analytics event tracking |
| `OrignaBaseNotificationService` | `orignabase_notification_service.dart` | Push notifications |
| `OrignaBaseDigitalService` | `orignabase_digital_service.dart` | Digital product delivery |
| `SessionTimeoutService` | `session_timeout_service.dart` | Auto session expiry |
| `TurnstileService` | `turnstile_service.dart` | Cloudflare bot protection |

### Platform Services (Conditional Exports)

| Service | Files | Platform |
|---------|-------|----------|
| `WebAuthRedirect` | `web_auth_redirect_web.dart` | Web OAuth |
| | `web_auth_redirect_stub.dart` | Non-web stub |
| `TurnstileService` | `turnstile_service_web.dart` | Web bot protection |
| | `turnstile_service_stub.dart` | Non-web stub |

---

## Service Details

### OrignaBaseConfigService

Remote configuration service that fetches runtime settings from OrignaBase.

**Purpose**: Fetch feature flags, API keys, and environment-specific config at startup.

**File**: `lib/services/orignabase_conf_service.dart`

**Key Methods**:

```dart
class OrignaBaseConfigService {
  /// Initialize and fetch remote config
  /// Called once at app startup (main.dart)
  Future<void> initialize(OrignaBase ob) async {
    // Fetches from ob.collection('config').doc('app_config')
    // Falls back to hardcoded defaults if fetch fails
  }

  /// GlitchTip DSN for self-hosted error reporting
  String get glitchtipDsn;

  /// Feature flags
  bool isFeatureEnabled(String featureName);

  /// Remote A/B test variants
  String getVariant(String experimentId);
}
```

**Usage**:

```dart
// In main.dart
final ob = OrignaBase.initialize(url: envConfig.orignabaseUrl);

unawaited(
  OrignaBaseConfigService()
    .initialize(ob)
    .timeout(const Duration(seconds: 10))
);

// Later, in ViewModels
final configService = OrignaBaseConfigService();
if (configService.isFeatureEnabled('new_checkout_flow')) {
  // Use new flow
}
```

**Config Document Structure**:

```json
{
  "glitchtipDsn": "https://...",
  "features": {
    "new_checkout_flow": true,
    "dark_mode_default": false
  },
  "experiments": {
    "product_card_style": "variant_b"
  }
}
```

---

### OrignaBaseAnalyticsService

Privacy-first analytics using OrignaBase.

**Purpose**: Track user behavior for product insights without exposing PII.

**File**: `lib/services/orignabase_analytics_service.dart`

**Key Methods**:

```dart
class OrignaBaseAnalyticsService {
  /// Track an event
  /// [eventName] - Event type (e.g., 'product_view', 'add_to_cart')
  /// [properties] - Event metadata (never PII)
  Future<void> track(
    String eventName, {
    Map<String, dynamic>? properties,
  });

  /// Track screen view
  Future<void> trackScreenView(String screenName);

  /// Track user action
  Future<void> trackAction(
    String action, {
    String? category,
    Map<String, dynamic>? metadata,
  });
}
```

**Usage**:

```dart
class ProductDetailScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsServiceProvider);

    // Track screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      analytics.trackScreenView('product_detail');
    });

    return ModernButton(
      label: 'Add to Cart',
      onPressed: () {
        // Track action
        analytics.trackAction(
          'add_to_cart',
          category: 'product',
          metadata: {
            'product_id': product.id,
            'price_cents': product.priceCents,
          },
        );
        
        // Execute action
        ref.read(cartProvider.notifier).addItem(product);
      },
    );
  }
}
```

**Privacy Guarantee**:
- IP addresses are hashed before storage
- No emails, names, or addresses in events
- All timestamps rounded to hour (no precise times)

---

### OrignaBaseNotificationService

Push notification service via FCM (Firebase Cloud Messaging).

**Purpose**: Manage device tokens and send push notifications through OrignaBase.

**File**: `lib/services/orignabase_notification_service.dart`

**Key Methods**:

```dart
class OrignaBaseNotificationService {
  /// Get current FCM token
  Future<String?> getToken();

  /// Save token to user's fcm_tokens subcollection
  Future<void> saveToken(String userId, String token);

  /// Remove token on logout
  Future<void> cleanupToken(String userId, String token);

  /// Request notification permission
  Future<bool> requestPermission();

  /// Check if notifications enabled
  Future<bool> areNotificationsEnabled();
}
```

**Usage**:

```dart
// On login
final notificationService = ref.read(notificationServiceProvider);
final token = await notificationService.getToken();
if (token != null) {
  await notificationService.saveToken(userId, token);
}

// On logout (cleanup)
final token = await notificationService.getToken();
if (token != null) {
  await notificationService.cleanupToken(userId, token);
}
```

**Token Storage**:

```
users/{userId}/fcm_tokens/{tokenId}
{
  "token": "fcm_token_string",
  "platform": "ios" | "android" | "web",
  "createdAt": Timestamp,
  "lastUsedAt": Timestamp
}
```

---

### OrignaBaseDigitalService

Digital product delivery service.

**Purpose**: Handle software downloads and ebook access for digital products.

**File**: `lib/services/orignabase_digital_service.dart`

**Key Methods**:

```dart
class OrignaBaseDigitalService {
  /// Generate download session for software
  /// Returns time-limited download URL
  Future<DownloadSession> generateSoftwareDownloadSession({
    required String licenseId,
    required String platform, // 'macos' | 'windows' | 'linux'
  });

  /// Generate download session for ebook
  Future<DownloadSession> generateBookDownloadSession({
    required String accessTokenId,
  });

  /// Validate license key
  Future<LicenseValidation> validateLicense({
    required String licenseKey,
    required String deviceId,
  });

  /// Revoke license (for refunds)
  Future<void> revokeLicense(String licenseId);
}
```

**Usage**:

```dart
class DigitalDownloadScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digitalService = ref.watch(digitalServiceProvider);

    return ModernButton(
      label: 'Download for macOS',
      onPressed: () async {
        final session = await digitalService.generateSoftwareDownloadSession(
          licenseId: license.id,
          platform: 'macos',
        );

        // session.downloadUrl is valid for 1 hour
        launchUrl(Uri.parse(session.downloadUrl));
      },
    );
  }
}
```

**Session Structure**:

```dart
class DownloadSession {
  final String downloadUrl;  // Time-limited signed URL
  final DateTime expiresAt;  // 1 hour from creation
  final String platform;
}
```

---

### SessionTimeoutService

Auto-logout service for security.

**Purpose**: Automatically log out inactive users after 15 minutes (configurable).

**File**: `lib/services/session_timeout_service.dart`

**Key Methods**:

```dart
class SessionTimeoutService {
  /// Start timeout timer (call on login)
  void startTimer(Duration timeout);

  /// Reset timer on user activity
  void resetTimer();

  /// Cancel timer (call on logout)
  void cancelTimer();

  /// Stream of timeout events
  Stream<void> get onTimeout;
}
```

**Usage**:

```dart
// In main app wrapper
class OrignaApp extends ConsumerStatefulWidget {
  @override
  ConsumerState<OrignaApp> createState() => _OrignaAppState();
}

class _OrignaAppState extends ConsumerState<OrignaApp> {
  late SessionTimeoutService _sessionService;

  @override
  void initState() {
    super.initState();
    _sessionService = SessionTimeoutService();
    
    // Start 15-minute timer
    _sessionService.startTimer(
      Duration(minutes: BusinessRules.sessionTimeoutMinutes),
    );

    // Listen for timeout
    _sessionService.onTimeout.listen((_) {
      ref.read(authProvider.notifier).logout();
      showSessionExpiredDialog();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User returned - reset timer
      _sessionService.resetTimer();
    }
  }
}

// In global gesture detector (detects any tap)
Listener(
  onPointerDown: (_) {
    _sessionService.resetTimer();
  },
  child: yourApp,
)
```

---

### TurnstileService

Cloudflare Turnstile bot protection.

**Purpose**: Verify human users before sensitive operations (checkout, registration).

**File**: `lib/services/turnstile_service.dart` (interface)
- Web implementation: `turnstile_service_web.dart`
- Non-web stub: `turnstile_service_stub.dart`

**Key Methods**:

```dart
abstract class TurnstileService {
  /// Get Turnstile token
  /// Shows challenge if needed, returns token on success
  Future<String?> getToken();

  /// Reset for retry
  void reset();

  /// Check if Turnstile is supported (web only)
  bool get isSupported;
}
```

**Usage**:

```dart
// Web checkout with Turnstile
class CheckoutScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turnstileService = ref.watch(turnstileServiceProvider);

    return ModernButton(
      label: 'Place Order',
      onPressed: () async {
        // Get Turnstile token (web only)
        String? turnstileToken;
        if (turnstileService.isSupported) {
          turnstileToken = await turnstileService.getToken();
          if (turnstileToken == null) {
            showError('Bot verification failed');
            return;
          }
        }

        // Submit checkout with token
        await ref.read(checkoutProvider.notifier).submit(
          turnstileToken: turnstileToken,
        );
      },
    );
  }
}
```

**Conditional Import Pattern**:

```dart
// lib/services/turnstile_service.dart
export 'turnstile_service_stub.dart'
    if (dart.library.html) 'turnstile_service_web.dart';

// lib/services/turnstile_service_web.dart
class TurnstileService {
  bool get isSupported => true;
  // Uses dart:html to integrate with Turnstile JS SDK
}

// lib/services/turnstile_service_stub.dart
class TurnstileService {
  bool get isSupported => false;
  // No-op for mobile/desktop
}
```

---

## Service Provider Pattern

All services are exposed via Riverpod providers:

```dart
// Provider definitions
final analyticsServiceProvider = Provider<OrignaBaseAnalyticsService>((ref) {
  return OrignaBaseAnalyticsService();
});

final notificationServiceProvider = Provider<OrignaBaseNotificationService>((ref) {
  return OrignaBaseNotificationService();
});

final digitalServiceProvider = Provider<OrignaBaseDigitalService>((ref) {
  return OrignaBaseDigitalService();
});

final sessionTimeoutServiceProvider = Provider<SessionTimeoutService>((ref) {
  return SessionTimeoutService();
});

final turnstileServiceProvider = Provider<TurnstileService>((ref) {
  return TurnstileService();
});
```

**Why providers?**
- Easy mocking in tests
- Lazy initialization
- Singleton management
- Dependency injection

---

## Testing Services

### Mocking Services

```dart
// test/helpers/test_providers.dart
class MockAnalyticsService extends Mock implements OrignaBaseAnalyticsService {}

class MockNotificationService extends Mock implements OrignaBaseNotificationService {}

// In test file
void main() {
  late MockAnalyticsService mockAnalytics;
  late ProviderContainer container;

  setUp(() {
    mockAnalytics = MockAnalyticsService();
    container = ProviderContainer(
      overrides: [
        analyticsServiceProvider.overrideWithValue(mockAnalytics),
      ],
    );
  });

  test('tracks product view', () async {
    // Arrange
    when(() => mockAnalytics.trackScreenView(any()))
        .thenAnswer((_) async {});

    // Act
    final service = container.read(analyticsServiceProvider);
    await service.trackScreenView('product_detail');

    // Assert
    verify(() => mockAnalytics.trackScreenView('product_detail')).called(1);
  });
}
```

---

## Service vs Repository

| Aspect | Service | Repository |
|--------|---------|------------|
| Purpose | External API wrapper | Data access layer |
| State | Stateless | Stateless |
| Business logic | None | Minimal (transformation) |
| Called by | ViewModels | ViewModels |
| Example | `TurnstileService` | `ProductRepository` |

**When to create a Service:**
- Wrapping a third-party API (Stripe, Turnstile)
- Platform feature (push notifications, biometrics)
- Cross-cutting concern (analytics, error reporting)

**When to create a Repository:**
- Database CRUD operations
- API data fetching
- Data transformation/mapping

---

## Best Practices

### 1. Keep Services Stateless

```dart
// ❌ Wrong - Service with state
class AnalyticsService {
  int _eventCount = 0;  // State!

  Future<void> track(String event) async {
    _eventCount++;  // Bad - use repository for persistence
  }
}

// ✅ Correct - Stateless service
class AnalyticsService {
  Future<void> track(String event, {Map<String, dynamic>? properties}) async {
    // Stateless - just forwards to OrignaBase
    await _ob.collection('analytics').add({
      'event': event,
      'properties': properties,
      'timestamp': DateTime.now(),
    });
  }
}
```

### 2. Use Platform Conditionals

```dart
// ✅ Correct - Platform-aware
class NotificationService {
  Future<String?> getToken() async {
    if (kIsWeb) {
      // Web push is different
      return null;
    }
    return await FirebaseMessaging.instance.getToken();
  }
}
```

### 3. Handle Errors Gracefully

```dart
// ✅ Correct - Graceful degradation
class AnalyticsService {
  Future<void> track(String event) async {
    try {
      await _sendEvent(event);
    } catch (e, st) {
      // Never crash app for analytics failure
      AppLogger.w('Analytics tracking failed: $e');
      // Optionally report to GlitchTip (non-blocking)
      unawaited(Sentry.captureException(e, stackTrace: st));
    }
  }
}
```

---

## Quick Reference

| Service | Purpose | Key Method |
|---------|---------|------------|
| `OrignaBaseConfigService` | Remote config | `initialize()`, `isFeatureEnabled()` |
| `OrignaBaseAnalyticsService` | Analytics | `track()`, `trackScreenView()` |
| `OrignaBaseNotificationService` | Push notifications | `getToken()`, `saveToken()` |
| `OrignaBaseDigitalService` | Digital downloads | `generateSoftwareDownloadSession()` |
| `SessionTimeoutService` | Auto-logout | `startTimer()`, `resetTimer()` |
| `TurnstileService` | Bot protection | `getToken()` (web only) |

---

*Last updated: 2026-03-25 | Source: `lib/services/*.dart`*
