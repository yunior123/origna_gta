// coverage:ignore-file
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/notifications/notification_provider.dart';
import 'package:origna_gta/services/push_transport.dart';
import 'package:origna_gta/utils/utils.dart';

/// OrignaBase notification service — replaces legacy token storage.
/// Token registration/cleanup goes through OrignaBase push API, while the
/// client-side transport is abstracted behind [PushMessagingClient].
class OrignaBaseNotificationService {
  static final OrignaBaseNotificationService instance =
      OrignaBaseNotificationService._internal();

  static GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  bool _initialized = false;
  bool _isInitializing = false;

  StreamSubscription<dynamic>? _tokenSubscription;
  ProviderSubscription<dynamic>? _authSubscription;
  ProviderContainer? _container;

  @visibleForTesting
  PushMessagingClient? messagingOverride;

  @visibleForTesting
  Stream<AppRemoteMessage>? onMessageOverride;

  @visibleForTesting
  Stream<AppRemoteMessage>? onMessageOpenedAppOverride;

  factory OrignaBaseNotificationService() => instance;

  OrignaBaseNotificationService._internal();

  @visibleForTesting
  void resetForTesting() {
    _initialized = false;
    _isInitializing = false;
    _tokenSubscription?.cancel();
    _authSubscription?.close();
    _container = null;
    messagingOverride = null;
    onMessageOverride = null;
    onMessageOpenedAppOverride = null;
  }

  @visibleForTesting
  set testContainerOverride(ProviderContainer container) {
    _container = container;
  }

  @visibleForTesting
  set testNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }

  @visibleForTesting
  set testScaffoldMessengerKey(GlobalKey<ScaffoldMessengerState> key) {
    scaffoldMessengerKey = key;
  }

  PushMessagingClient get _messaging =>
      messagingOverride ?? const NoopPushMessagingClient();

  OrignaBase get _ob => _container!.read(orignabaseProvider);

  /// Removes the device's FCM token from OrignaBase.
  Future<void> clearTokenFromOrignaBase() async {
    if (_container == null || kIsWeb) return;
    final userId = _container!.read(obUserIdProvider);
    if (userId == null) return;
    try {
      final fcmToken = await _messaging.getToken();
      if (fcmToken != null) {
        await _ob.push.unregisterToken(fcmToken);
        debugPrint('Removed FCM token from OrignaBase for user: $userId');
      }
    } catch (e, st) {
      AppError.log(e,
          stackTrace: st,
          context: 'OrignaBaseNotificationService.clearTokenFromOrignaBase');
    }
  }

  void dispose() {
    _tokenSubscription?.cancel();
    _authSubscription?.close();
  }

  /// Initialize the notification service.
  Future<void> initialize(WidgetRef? ref) async {
    if (kIsWeb) {
      ref?.read(notificationPermissionProvider.notifier).setGranted(false);
      _initialized = true;
      return;
    }

    if (_initialized || _isInitializing) return;
    _isInitializing = true;

    try {
      if (ref != null) {
        _container = ProviderScope.containerOf(ref.context);
      }

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

      final granted =
          settings.authorizationStatus ==
                  AppNotificationAuthorizationStatus.authorized ||
              settings.authorizationStatus ==
                  AppNotificationAuthorizationStatus.provisional;

      ref?.read(notificationPermissionProvider.notifier).setGranted(granted);

      if (granted) {
        debugPrint('User granted permission: ${settings.authorizationStatus}');

        await _saveTokenToOrignaBase();

        _tokenSubscription = messaging.onTokenRefresh.listen((fcmToken) {
          _saveTokenToOrignaBase(token: fcmToken);
        });

        if (_container != null) {
          _authSubscription =
              _container!.listen(obUserIdProvider, (previous, next) {
            if (next != null && next != previous) {
              _saveTokenToOrignaBase();
            }
          });
        }
      } else {
        debugPrint(
            'User declined or has not accepted notification permissions');

        Future<void> saveOptOut() async {
          if (_container == null) return;
          final userId = _container!.read(obUserIdProvider);
          if (userId != null) {
            try {
              await _ob
                  .collection(Collections.users)
                  .doc(userId)
                  .update({Fields.pushEnabled: false});
            } catch (e) {
              debugPrint('Failed to save pushEnabled setting: $e');
            }
          }
        }

        await saveOptOut();

        if (_container != null) {
          _authSubscription =
              _container!.listen(obUserIdProvider, (previous, next) {
            if (next != null && next != previous) {
              saveOptOut();
            }
          });
        }
      }

      (onMessageOpenedAppOverride ?? const Stream.empty())
          .listen(handleNotificationTap);

      messaging.getInitialMessage().then((AppRemoteMessage? message) {
        if (message != null) {
          Future.delayed(const Duration(milliseconds: 300),
              () => handleNotificationTap(message));
        }
      });

      (onMessageOverride ?? const Stream.empty())
          .listen(handleForegroundMessage);

      _initialized = true;
    } catch (e, st) {
      AppError.log(e,
          stackTrace: st,
          context: 'OrignaBaseNotificationService.initialize');
    } finally {
      _isInitializing = false;
    }
  }

  /// Foreground message handler.
  void handleForegroundMessage(AppRemoteMessage message) {
    debugPrint('Foreground FCM: ${message.messageId}');
    final notification = message.notification;
    if (notification != null) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
              '${notification.title ?? ''}: ${notification.body ?? ''}'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
              label: 'common.view'.tr(),
              onPressed: () => handleNotificationTap(message)),
        ),
      );
    }
  }

  /// Save FCM token to OrignaBase push service.
  @visibleForTesting
  Future<void> saveTokenToOrignaBase({String? token}) =>
      _saveTokenToOrignaBase(token: token);

  Future<void> _saveTokenToOrignaBase({String? token}) async {
    if (_container == null) return;
    final userId = _container!.read(obUserIdProvider);
    if (userId == null) return;

    try {
      final fcmToken = token ?? await _messaging.getToken();
      if (fcmToken != null) {
        final platform =
            kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();
        await _ob.push.registerToken(
          userId: userId,
          token: fcmToken,
          platform: platform,
        );
        debugPrint(
            'FCM Token registered with OrignaBase for user: $userId ($platform)');
      }
    } catch (e, st) {
      AppError.log(e,
          stackTrace: st,
          context:
              'OrignaBaseNotificationService._saveTokenToOrignaBase');
    }
  }

  /// Routes to the appropriate screen based on the FCM message payload.
  void handleNotificationTap(AppRemoteMessage message) {
    final data = message.data;
    final type = data[Fields.type] as String?;

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    switch (type) {
      case NotificationTypes.orderStatus:
      case NotificationTypes.orderUpdate:
      case NotificationTypes.returnStatus:
      case NotificationTypes.returnRequest:
      case NotificationTypes.refundIssued:
        final orderId = data[Fields.orderId] as String?;
        if (orderId != null && orderId.isNotEmpty) {
          navigator.pushNamed(AppRoutes.orderDetail,
              arguments: OrderDetailArgs(orderId: orderId));
        } else {
          navigator.pushNamed(AppRoutes.orders);
        }

      case NotificationTypes.backInStock:
        final productId = data[Fields.productId] as String?;
        if (productId != null && productId.isNotEmpty) {
          navigator.pushNamed(AppRoutes.productDetails,
              arguments: ProductDetailsArgs(productId: productId));
        }

      default:
        debugPrint(
            'OrignaBaseNotificationService: unhandled notification type "$type" — ignoring tap');
    }
  }
}
