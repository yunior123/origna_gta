import 'dart:async';

enum AppNotificationAuthorizationStatus { authorized, provisional, denied }

class AppNotificationSettings {
  final AppNotificationAuthorizationStatus authorizationStatus;

  const AppNotificationSettings({required this.authorizationStatus});
}

class AppRemoteNotification {
  final String? title;
  final String? body;

  const AppRemoteNotification({this.title, this.body});
}

class AppRemoteMessage {
  final String? messageId;
  final Map<String, dynamic> data;
  final AppRemoteNotification? notification;

  const AppRemoteMessage({
    this.messageId,
    this.data = const {},
    this.notification,
  });
}

abstract class PushMessagingClient {
  Stream<String> get onTokenRefresh;
  Future<String?> getToken();
  Future<AppRemoteMessage?> getInitialMessage();
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

class NoopPushMessagingClient implements PushMessagingClient {
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
