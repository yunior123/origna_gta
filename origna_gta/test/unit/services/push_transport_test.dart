import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/services/push_transport.dart';

void main() {
  group('AppNotificationAuthorizationStatus', () {
    test('has all expected values', () {
      expect(
        AppNotificationAuthorizationStatus.values,
        containsAll([
          AppNotificationAuthorizationStatus.authorized,
          AppNotificationAuthorizationStatus.provisional,
          AppNotificationAuthorizationStatus.denied,
        ]),
      );
    });
  });

  group('AppNotificationSettings', () {
    test('stores authorization status', () {
      const settings = AppNotificationSettings(
        authorizationStatus: AppNotificationAuthorizationStatus.authorized,
      );

      expect(
        settings.authorizationStatus,
        AppNotificationAuthorizationStatus.authorized,
      );
    });

    test('supports all authorization statuses', () {
      for (final status in AppNotificationAuthorizationStatus.values) {
        final settings = AppNotificationSettings(authorizationStatus: status);
        expect(settings.authorizationStatus, status);
      }
    });
  });

  group('AppRemoteNotification', () {
    test('stores title and body', () {
      const notification = AppRemoteNotification(
        title: 'Test Title',
        body: 'Test Body',
      );

      expect(notification.title, 'Test Title');
      expect(notification.body, 'Test Body');
    });

    test('handles null values', () {
      const notification = AppRemoteNotification();

      expect(notification.title, isNull);
      expect(notification.body, isNull);
    });
  });

  group('AppRemoteMessage', () {
    test('stores all fields', () {
      const message = AppRemoteMessage(
        messageId: 'msg_123',
        data: {'key': 'value', 'orderId': 'order_abc'},
        notification: AppRemoteNotification(title: 'Title', body: 'Body'),
      );

      expect(message.messageId, 'msg_123');
      expect(message.data['key'], 'value');
      expect(message.data['orderId'], 'order_abc');
      expect(message.notification?.title, 'Title');
      expect(message.notification?.body, 'Body');
    });

    test('uses default empty data map', () {
      const message = AppRemoteMessage(messageId: 'msg_123');

      expect(message.data, isEmpty);
      expect(message.data, isA<Map<String, dynamic>>());
    });

    test('handles null messageId', () {
      const message = AppRemoteMessage();

      expect(message.messageId, isNull);
      expect(message.data, isEmpty);
      expect(message.notification, isNull);
    });
  });

  group('NoopPushMessagingClient', () {
    test('getToken returns null', () async {
      const client = NoopPushMessagingClient();
      final token = await client.getToken();

      expect(token, isNull);
    });

    test('getInitialMessage returns null', () async {
      const client = NoopPushMessagingClient();
      final message = await client.getInitialMessage();

      expect(message, isNull);
    });

    test('onTokenRefresh is empty stream', () {
      const client = NoopPushMessagingClient();
      expect(client.onTokenRefresh, isA<Stream<String>>());
    });

    test('requestPermission returns denied status', () async {
      const client = NoopPushMessagingClient();
      final settings = await client.requestPermission();

      expect(
        settings.authorizationStatus,
        AppNotificationAuthorizationStatus.denied,
      );
    });

    test('requestPermission ignores all parameters', () async {
      const client = NoopPushMessagingClient();

      final settings = await client.requestPermission(
        alert: false,
        announcement: true,
        badge: false,
        carPlay: true,
        criticalAlert: true,
        provisional: true,
        sound: false,
      );

      expect(
        settings.authorizationStatus,
        AppNotificationAuthorizationStatus.denied,
      );
    });
  });

  group('PushMessagingClient interface', () {
    test('defines required methods', () {
      final client = _TestPushMessagingClient();

      expect(client.onTokenRefresh, isA<Stream<String>>());
      expect(() => client.getToken(), returnsNormally);
      expect(() => client.getInitialMessage(), returnsNormally);
      expect(() => client.requestPermission(), returnsNormally);
    });
  });
}

class _TestPushMessagingClient implements PushMessagingClient {
  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Future<String?> getToken() async => 'test_token';

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
      authorizationStatus: AppNotificationAuthorizationStatus.authorized,
    );
  }
}
