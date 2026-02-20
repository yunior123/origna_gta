import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/notifications/notification_provider.dart';

/// Background message handler Top-level function.
/// Must be outside of any class to handle messages when app is terminated.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();

  StreamSubscription? _tokenSubscription;

  ProviderSubscription? _authSubscription;

  late ProviderContainer _container;
  @visibleForTesting
  FirebaseMessaging? messagingOverride;

  factory NotificationService() => instance;

  NotificationService._internal();

  @visibleForTesting
  set testContainerOverride(ProviderContainer container) {
    _container = container;
  }

  FirebaseMessaging get _messaging => messagingOverride ?? FirebaseMessaging.instance;

  void dispose() {
    _tokenSubscription?.cancel();
    _authSubscription?.close();
  }

  /// Initialize the notification service. Should be called only once
  /// in the app lifecycle (typically in OrignaApp's initState).
  Future<void> initialize(WidgetRef ref) async {
    // Skip if on web (FCM requires VAPID key setup on Web, keeping this mobile-only)
    if (kIsWeb) return;

    _container = ProviderScope.containerOf(ref.context);

    // Request permissions
    final messaging = _messaging;
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized || settings.authorizationStatus == AuthorizationStatus.provisional) {
      ref.read(notificationPermissionProvider.notifier).state = true;
      debugPrint('User granted permission: ${settings.authorizationStatus}');

      // Automatically save FCM token if user is already logged in
      await saveTokenToFirestore();

      // Listen for token refreshes
      _tokenSubscription = messaging.onTokenRefresh.listen((fcmToken) {
        saveTokenToFirestore(token: fcmToken);
      });

      // Listen for auth state changes to save token when user logs in
      _authSubscription = _container.listen(userIdProvider, (previous, next) {
        if (next != null && next != previous) {
          saveTokenToFirestore();
        }
      });
    } else {
      ref.read(notificationPermissionProvider.notifier).state = false;
      debugPrint('User declined or has not accepted notification permissions');
    }

    // Set up background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground messages handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        // For foreground notifications, you could trigger a local SnackBar here
        // The OrignaApp would need a global scaffold messenger key to show it.
      }
    });
  }

  /// Fetches the current FCM token and saves it to the user's Firestore document.
  @visibleForTesting
  Future<void> saveTokenToFirestore({String? token}) async {
    final userId = _container.read(userIdProvider);
    if (userId == null) return;

    try {
      final fcmToken = token ?? await _messaging.getToken();
      if (fcmToken != null) {
        final firestore = _container.read(firestoreProvider);
        await firestore.collection(Collections.users).doc(userId).set({
          Fields.fcmToken: fcmToken,
          Fields.fcmTokenUpdatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('FCM Token saved to Firestore for user: $userId');
      }
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }
}
