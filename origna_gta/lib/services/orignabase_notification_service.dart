import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/repositories/notification_repository.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/notifications/notification_provider.dart';
import 'package:origna_gta/services/push_transport.dart';
import 'package:origna_gta/utils/app_logger.dart';
import 'package:origna_gta/utils/utils.dart';

/// Manages the complete push notification lifecycle for the app.
///
/// Responsibilities:
/// - Requests notification permission from the user.
/// - Registers/unregisters the FCM token with OrignaBase's push service.
/// - Listens for token refresh and re-registers automatically.
/// - Handles foreground messages (shows SnackBar).
/// - Handles notification taps (routes to order detail, product detail, etc.).
/// - Saves push opt-out status when the user declines permission.
///
/// This is a singleton service. On web, initialization is a no-op (push is
/// not supported). The transport layer is abstracted behind [PushMessagingClient].
class OrignaBaseNotificationService {
  static final OrignaBaseNotificationService instance =
      OrignaBaseNotificationService._internal();

  /// Global key for showing SnackBars from anywhere (including outside widget tree).
  static GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Global key for navigating from notification taps without BuildContext.
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Whether the service has been initialized.
  bool _initialized = false;

  /// Guard against concurrent initialization.
  bool _isInitializing = false;

  /// Subscription to the push token refresh stream.
  StreamSubscription<dynamic>? _tokenSubscription;

  /// Subscription to auth state changes for re-registering tokens on login.
  ProviderSubscription<dynamic>? _authSubscription;

  /// The Riverpod container used for reading providers.
  ProviderContainer? _container;

  /// Override for [PushMessagingClient] in tests.
  @visibleForTesting
  PushMessagingClient? messagingOverride;

  /// Factory override for constructing user-bound messaging clients in tests.
  @visibleForTesting
  PushMessagingClient Function(
    NotificationRepository repository,
    String userId,
    String platform,
  )?
  messagingFactoryOverride;

  /// Override for foreground message stream in tests.
  @visibleForTesting
  Stream<AppRemoteMessage>? onMessageOverride;

  /// Override for notification-opened-app stream in tests.
  @visibleForTesting
  Stream<AppRemoteMessage>? onMessageOpenedAppOverride;

  PushMessagingClient? _cachedMessagingClient;
  String? _cachedMessagingUserId;

  factory OrignaBaseNotificationService() => instance;

  OrignaBaseNotificationService._internal();

  /// Resets all service state for testing. Cancels active subscriptions.
  @visibleForTesting
  void resetForTesting() {
    _disposeCachedMessagingClient();
    _initialized = false;
    _isInitializing = false;
    _tokenSubscription?.cancel();
    _authSubscription?.close();
    _container = null;
    messagingOverride = null;
    messagingFactoryOverride = null;
    onMessageOverride = null;
    onMessageOpenedAppOverride = null;
  }

  /// Override for the Riverpod container in tests.
  @visibleForTesting
  set testContainerOverride(ProviderContainer container) {
    _container = container;
  }

  /// Override for the navigator key in tests.
  @visibleForTesting
  set testNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }

  /// Override for the scaffold messenger key in tests.
  @visibleForTesting
  set testScaffoldMessengerKey(GlobalKey<ScaffoldMessengerState> key) {
    scaffoldMessengerKey = key;
  }

  void _disposeCachedMessagingClient() {
    _cachedMessagingClient?.dispose();
    _cachedMessagingClient = null;
    _cachedMessagingUserId = null;
  }

  void _resetMessagingClientIfUserChanged(String? nextUserId) {
    if (_cachedMessagingUserId != nextUserId) {
      _disposeCachedMessagingClient();
    }
  }

  /// Resolves the push messaging client (test override or cached OrignaBase realtime client).
  PushMessagingClient get _messaging {
    if (messagingOverride != null) return messagingOverride!;
    final container = _container;
    if (container == null) {
      _disposeCachedMessagingClient();
      return const NoopPushMessagingClient();
    }

    final userId = container.read(obUserIdProvider);
    if (userId == null) {
      _disposeCachedMessagingClient();
      return const NoopPushMessagingClient();
    }

    if (_cachedMessagingClient != null && _cachedMessagingUserId == userId) {
      return _cachedMessagingClient!;
    }

    _disposeCachedMessagingClient();

    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();
    final repo = container.read(notificationRepositoryProvider);
    final client =
        messagingFactoryOverride?.call(repo, userId, platform) ??
        OrignaBasePushMessagingClient(
          repository: repo,
          userId: userId,
          platform: platform,
        );
    _cachedMessagingClient = client;
    _cachedMessagingUserId = userId;
    return client;
  }

  /// Reads the OrignaBase client from the Riverpod container.
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
        AppLogger.d(
          'Removed FCM token from OrignaBase for user: $userId',
          tag: 'push',
        );
      }
    } catch (e, st) {
      AppError.log(
        e,
        stackTrace: st,
        context: 'OrignaBaseNotificationService.clearTokenFromOrignaBase',
      );
    }
  }

  /// Cancels active token and auth subscriptions.
  void dispose() {
    _tokenSubscription?.cancel();
    _authSubscription?.close();
    _disposeCachedMessagingClient();
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
        AppLogger.i(
          'User granted permission: ${settings.authorizationStatus}',
          tag: 'push',
        );

        await _saveTokenToOrignaBase();

        _tokenSubscription = messaging.onTokenRefresh.listen((fcmToken) {
          _saveTokenToOrignaBase(token: fcmToken);
        });

        if (_container != null) {
          _authSubscription = _container!.listen(obUserIdProvider, (
            previous,
            next,
          ) {
            final previousUserId = previous as String?;
            final nextUserId = next as String?;
            _resetMessagingClientIfUserChanged(nextUserId);
            if (nextUserId != null && nextUserId != previousUserId) {
              _saveTokenToOrignaBase();
            }
          });
        }
      } else {
        AppLogger.i(
          'User declined or has not accepted notification permissions',
          tag: 'push',
        );

        Future<void> saveOptOut() async {
          if (_container == null) return;
          final userId = _container!.read(obUserIdProvider);
          if (userId != null) {
            try {
              await _ob.collection(Collections.users).doc(userId).update({
                Fields.pushEnabled: false,
              });
            } catch (e) {
              AppLogger.w(
                'Failed to save pushEnabled setting: $e',
                tag: 'push',
              );
            }
          }
        }

        await saveOptOut();

        if (_container != null) {
          _authSubscription = _container!.listen(obUserIdProvider, (
            previous,
            next,
          ) {
            final previousUserId = previous as String?;
            final nextUserId = next as String?;
            _resetMessagingClientIfUserChanged(nextUserId);
            if (nextUserId != null && nextUserId != previousUserId) {
              saveOptOut();
            }
          });
        }
      }

      (onMessageOpenedAppOverride ?? messaging.onMessageOpenedApp).listen(
        handleNotificationTap,
      );

      messaging.getInitialMessage().then((AppRemoteMessage? message) {
        if (message != null) {
          Future.delayed(
            const Duration(milliseconds: 300),
            () => handleNotificationTap(message),
          );
        }
      });

      (onMessageOverride ?? messaging.onMessage).listen(
        handleForegroundMessage,
      );

      _initialized = true;
    } catch (e, st) {
      AppError.log(
        e,
        stackTrace: st,
        context: 'OrignaBaseNotificationService.initialize',
      );
    } finally {
      _isInitializing = false;
    }
  }

  /// Foreground message handler.
  void handleForegroundMessage(AppRemoteMessage message) {
    AppLogger.d('Foreground FCM: ${message.messageId}', tag: 'push');
    final notification = message.notification;
    if (notification != null) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            '${notification.title ?? ''}: ${notification.body ?? ''}',
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'common.view'.tr(),
            onPressed: () => handleNotificationTap(message),
          ),
        ),
      );
    }
  }

  /// Exposed for testing — delegates to [_saveTokenToOrignaBase].
  @visibleForTesting
  Future<void> saveTokenToOrignaBase({String? token}) =>
      _saveTokenToOrignaBase(token: token);

  /// Saves the current FCM token to OrignaBase's push service.
  ///
  /// If [token] is provided, uses it directly; otherwise fetches from the
  /// messaging client. Registers the token with the user's ID and platform.
  Future<void> _saveTokenToOrignaBase({String? token}) async {
    if (_container == null) return;
    final userId = _container!.read(obUserIdProvider);
    if (userId == null) return;

    try {
      final fcmToken = token ?? await _messaging.getToken();
      if (fcmToken != null) {
        final platform = kIsWeb
            ? 'web'
            : defaultTargetPlatform.name.toLowerCase();
        await _ob.push.registerToken(
          userId: userId,
          token: fcmToken,
          platform: platform,
        );
        AppLogger.d(
          'FCM Token registered with OrignaBase for user: $userId ($platform)',
          tag: 'push',
        );
      }
    } catch (e, st) {
      AppError.log(
        e,
        stackTrace: st,
        context: 'OrignaBaseNotificationService._saveTokenToOrignaBase',
      );
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
          navigator.pushNamed(
            AppRoutes.orderDetail,
            arguments: OrderDetailArgs(orderId: orderId),
          );
        } else {
          navigator.pushNamed(AppRoutes.orders);
        }

      case NotificationTypes.backInStock:
        final productId = data[Fields.productId] as String?;
        if (productId != null && productId.isNotEmpty) {
          navigator.pushNamed(
            AppRoutes.productDetails,
            arguments: ProductDetailsArgs(productId: productId),
          );
        }

      case NotificationTypes.newMessage:
        final productId = data[Fields.productId] as String?;
        final productTitle = data[Fields.productTitle] as String? ?? '';
        if (productId != null && productId.isNotEmpty) {
          navigator.pushNamed(
            AppRoutes.chat,
            arguments: ChatArgs(
              productId: productId,
              productTitle: productTitle,
            ),
          );
        } else {
          navigator.pushNamed(AppRoutes.chatInbox);
        }

      case NotificationTypes.messageReport:
        navigator.pushNamed(AppRoutes.chatInbox);

      case NotificationTypes.perishableOrderUrgent:
        final orderId = data[Fields.orderId] as String?;
        if (orderId != null && orderId.isNotEmpty) {
          navigator.pushNamed(
            AppRoutes.orderDetail,
            arguments: OrderDetailArgs(orderId: orderId),
          );
        } else {
          navigator.pushNamed(AppRoutes.sellerOrders);
        }

      case NotificationTypes.promo:
      case NotificationTypes.system:
      case NotificationTypes.account:
        navigator.pushNamed(AppRoutes.notifications);

      default:
        AppLogger.d(
          'Unhandled notification type "$type" — ignoring tap',
          tag: 'push',
        );
    }
  }
}
