import 'dart:async';

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
}
