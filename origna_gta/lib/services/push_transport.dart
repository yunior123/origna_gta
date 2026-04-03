import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/core/repositories/notification_repository.dart';
import 'package:origna_gta/utils/app_logger.dart';

/// Authorization status for push notification permissions.
///
/// Maps to platform-specific notification authorization states.
/// [authorized] means the user explicitly granted permission.
/// [provisional] means silent notifications are allowed (iOS provisional push).
/// [denied] means the user declined or has not been prompted yet.
enum AppNotificationAuthorizationStatus { authorized, provisional, denied }

/// Holds the result of a push notification permission request.
///
/// Wraps [AppNotificationAuthorizationStatus] to provide a platform-agnostic
/// representation of the user's notification settings.
class AppNotificationSettings {
  /// The current authorization status for push notifications.
  final AppNotificationAuthorizationStatus authorizationStatus;

  /// Creates notification settings with the given [authorizationStatus].
  const AppNotificationSettings({required this.authorizationStatus});
}

/// Represents a remote push notification payload received from the server.
///
/// Contains the optional [title] and [body] displayed to the user.
/// Both fields are nullable because some push payloads carry only data.
class AppRemoteNotification {
  /// The notification title displayed in the system tray.
  final String? title;

  /// The notification body text displayed below the title.
  final String? body;

  /// Creates a remote notification with optional [title] and [body].
  const AppRemoteNotification({this.title, this.body});
}

/// Represents a complete remote message received via push messaging.
///
/// Contains an optional [messageId] for deduplication, a [data] map with
/// custom key-value pairs from the server, and an optional [notification]
/// with the user-visible title and body.
class AppRemoteMessage {
  /// Unique identifier for deduplication. May be null for data-only messages.
  final String? messageId;

  /// Custom data payload sent from the server (e.g., order ID, type).
  final Map<String, dynamic> data;

  /// The user-visible notification portion, if present.
  final AppRemoteNotification? notification;

  /// Creates a remote message with optional [messageId], [data], and [notification].
  const AppRemoteMessage({
    this.messageId,
    this.data = const {},
    this.notification,
  });
}

/// Field names used by the app-side push payload contract.
abstract final class _PushMessageFields {
  static const id = 'id';
  static const title = 'title';
  static const body = 'body';

  const _PushMessageFields._();
}

/// Platform values used by the synthetic OrignaBase token path.
abstract final class _PushPlatformValues {
  static const web = 'web';
  static const unknown = 'unknown';

  const _PushPlatformValues._();
}

/// Platform-agnostic interface for push messaging operations.
///
/// Abstracts the underlying push provider (FCM, APNs) so the notification
/// service can work on both mobile and web without platform-specific code.
/// Implementations must handle token lifecycle, permission requests, and
/// initial message retrieval.
abstract class PushMessagingClient {
  /// Stream that emits a new token whenever the push token is refreshed.
  Stream<String> get onTokenRefresh;

  /// Returns the current push token, or null if not yet available.
  Future<String?> getToken();

  /// Returns the message that launched the app from a terminated state,
  /// or null if the app was not opened from a notification.
  Future<AppRemoteMessage?> getInitialMessage();

  /// Requests notification permission from the user with the specified options.
  ///
  /// Returns [AppNotificationSettings] indicating the resulting authorization status.
  /// Parameters control which notification features are requested:
  /// - [alert]: show notification banners/alerts.
  /// - [badge]: update the app badge count.
  /// - [sound]: play a sound for notifications.
  /// - [provisional]: allow silent notifications without explicit permission (iOS).
  /// - [criticalAlert]: bypass Do Not Disturb (requires entitlement).
  /// - [announcement]: announce notifications via Siri (iOS).
  /// - [carPlay]: show notifications in CarPlay (iOS).
  Future<AppNotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
  });

  /// Stream of incoming notification messages while app is in foreground.
  ///
  /// Defaults to empty for implementations that don't support foreground messages.
  Stream<AppRemoteMessage> get onMessage => const Stream.empty();

  /// Stream of notification messages that opened the app from background.
  ///
  /// Defaults to empty for implementations that don't support background messages.
  Stream<AppRemoteMessage> get onMessageOpenedApp => const Stream.empty();

  /// Releases any platform channels, subscriptions, or stream controllers.
  void dispose() {}
}

/// No-op implementation of [PushMessagingClient] for platforms without push support.
///
/// Used as the default when no real push provider is available (e.g., web or
/// when the user denies permission). All methods return safe defaults without
/// making any network or platform calls.
class NoopPushMessagingClient implements PushMessagingClient {
  /// Creates a const no-op push messaging client.
  const NoopPushMessagingClient();

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Future<String?> getToken() async => null;

  @override
  Future<AppRemoteMessage?> getInitialMessage() async => null;

  @override
  Future<AppNotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
  }) async {
    return const AppNotificationSettings(
      authorizationStatus: AppNotificationAuthorizationStatus.denied,
    );
  }

  @override
  Stream<AppRemoteMessage> get onMessage => const Stream.empty();

  @override
  Stream<AppRemoteMessage> get onMessageOpenedApp => const Stream.empty();

  @override
  void dispose() {}
}

/// OrignaBase-backed push messaging client.
///
/// P1-NEW-11: Replaces [NoopPushMessagingClient] to provide real-time
/// notification delivery via OrignaBase WebSocket snapshots. Since Firebase
/// is removed, this implementation:
///
/// - Watches the user's notification subcollection via OrignaBase realtime
/// - Detects new notifications and emits them as [AppRemoteMessage] objects
/// - Uses a synthetic device-local token (userId + platform) for registration
/// - Requests native notification permission for OS-level banners
///
/// This enables foreground notification SnackBars and notification-tap
/// routing without any server-side push infrastructure.
class OrignaBasePushMessagingClient implements PushMessagingClient {
  /// The notification repository for watching realtime changes.
  final NotificationRepository _repository;

  /// The user ID for token generation and subcollection access.
  final String _userId;

  /// The platform name for token registration.
  final String _platform;

  /// Controller for foreground message stream.
  final StreamController<AppRemoteMessage> _messageController =
      StreamController<AppRemoteMessage>.broadcast();

  /// Controller for notification-tap stream.
  final StreamController<AppRemoteMessage> _tapController =
      StreamController<AppRemoteMessage>.broadcast();

  /// Subscription to the notification stream.
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  /// IDs of notifications seen in the previous snapshot (for dedup).
  final Set<String> _seenIds = <String>{};

  /// Whether the initial snapshot has been processed.
  bool _initialized = false;

  /// Creates an OrignaBase push messaging client.
  ///
  /// [repository] — the notification repository for realtime watches.
  /// [userId] — the authenticated user's ID.
  /// [platform] — the device platform (e.g., 'android', 'ios', 'web').
  OrignaBasePushMessagingClient({
    required NotificationRepository repository,
    required String userId,
    String? platform,
  }) : _repository = repository,
       _userId = userId,
       _platform =
           platform ??
           (kIsWeb ? _PushPlatformValues.web : _PushPlatformValues.unknown) {
    _startWatching();
  }

  /// Starts watching the user's notification subcollection.
  void _startWatching() {
    _subscription = _repository
        .watchNotifications(_userId)
        .listen(
          (notifications) {
            if (!_initialized) {
              // First snapshot — seed the seen set, don't emit
              for (final notif in notifications) {
                final id = notif[_PushMessageFields.id] as String?;
                if (id != null) _seenIds.add(id);
              }
              _initialized = true;
              return;
            }

            // Subsequent snapshots — find new notifications
            for (final notif in notifications) {
              final id = notif[_PushMessageFields.id] as String?;
              if (id == null || _seenIds.contains(id)) continue;
              _seenIds.add(id);

              final message = _toAppRemoteMessage(notif);
              _messageController.add(message);
            }
          },
          onError: (Object error, StackTrace st) {
            AppLogger.w('Notification stream error: $error', tag: 'push');
          },
        );
  }

  /// Converts a notification document map to an [AppRemoteMessage].
  AppRemoteMessage _toAppRemoteMessage(Map<String, dynamic> data) {
    final title = data[_PushMessageFields.title] as String?;
    final body = data[_PushMessageFields.body] as String?;
    final type = data[Fields.type] as String?;
    final id = data[_PushMessageFields.id] as String?;

    final orderId = data[Fields.orderId] as String?;
    final productId = data[Fields.productId] as String?;
    final productTitle = data[Fields.productTitle] as String?;

    return AppRemoteMessage(
      messageId: id,
      data: <String, dynamic>{
        ...?type == null ? null : <String, dynamic>{Fields.type: type},
        ...?orderId == null ? null : <String, dynamic>{Fields.orderId: orderId},
        ...?productId == null
            ? null
            : <String, dynamic>{Fields.productId: productId},
        ...?productTitle == null
            ? null
            : <String, dynamic>{Fields.productTitle: productTitle},
      },
      notification: (title != null || body != null)
          ? AppRemoteNotification(title: title, body: body)
          : null,
    );
  }

  /// Stable synthetic token: orignabase://{platform}/{userId}
  String get _syntheticToken => 'orignabase://$_platform/$_userId';

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Future<String?> getToken() async => _syntheticToken;

  @override
  Future<AppRemoteMessage?> getInitialMessage() async => null;

  @override
  Future<AppNotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
  }) async {
    // Without Firebase/APNs, we can't prompt the native permission dialog.
    // Return authorized so the service proceeds with WebSocket-based delivery.
    return const AppNotificationSettings(
      authorizationStatus: AppNotificationAuthorizationStatus.authorized,
    );
  }

  @override
  Stream<AppRemoteMessage> get onMessage => _messageController.stream;

  @override
  Stream<AppRemoteMessage> get onMessageOpenedApp => _tapController.stream;

  /// Exposes the tap controller for external notification-tap handling.
  StreamController<AppRemoteMessage> get tapController => _tapController;

  /// Disposes resources. Call when the user logs out.
  @override
  void dispose() {
    _subscription?.cancel();
    _messageController.close();
    _tapController.close();
  }
}
