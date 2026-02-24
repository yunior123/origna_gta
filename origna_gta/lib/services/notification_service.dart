import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/notifications/notification_provider.dart';
import 'package:origna_gta/utils/utils.dart';

/// Background message handler — top-level function required by FCM.
/// Must be outside of any class.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by the OS before this runs.
  // Log receipt; local notification display requires flutter_local_notifications (future task).
  debugPrint('Background FCM message received: ${message.messageId}');
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();

  StreamSubscription? _tokenSubscription;
  ProviderSubscription? _authSubscription;

  late ProviderContainer _container;

  /// Global key to show foreground notification SnackBars without BuildContext.
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

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

    final messaging = _messaging;

    // Restore prior-granted permission state without re-prompting
    final currentSettings = await messaging.getNotificationSettings();
    final alreadyGranted = currentSettings.authorizationStatus == AuthorizationStatus.authorized ||
        currentSettings.authorizationStatus == AuthorizationStatus.provisional;

    if (alreadyGranted) {
      ref.read(notificationPermissionProvider.notifier).setGranted(true);
    }

    // Request permissions (no-ops if already granted on iOS)
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    // Update permission state before any downstream token-save calls
    ref.read(notificationPermissionProvider.notifier).setGranted(granted);

    if (granted) {
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
      debugPrint('User declined or has not accepted notification permissions');
    }

    // Set up background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground messages handler — show SnackBar for real-time order updates
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground FCM: ${message.messageId}');
      final notification = message.notification;
      if (notification != null) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('${notification.title ?? ''}: ${notification.body ?? ''}'),
            duration: const Duration(seconds: 4),
          ),
        );
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
    } catch (e, st) {
      AppError.log(e, stackTrace: st, context: 'NotificationService.saveTokenToFirestore');
    }
  }
}
