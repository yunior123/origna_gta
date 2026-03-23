import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/services/orignabase_notification_service.dart';
import 'package:origna_gta/services/push_transport.dart';
import 'package:orignabase/orignabase.dart';

import 'notification_service_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<PushMessagingClient>(),
  MockSpec<NavigatorState>(),
  MockSpec<ScaffoldMessengerState>(),
  MockSpec<OrignaBase>(),
  MockSpec<OrignaBasePush>(),
])
void main() {
  group('OrignaBaseNotificationService', () {
    late MockPushMessagingClient mockMessaging;
    late MockOrignaBase mockOrignaBase;
    late MockOrignaBasePush mockPush;

    setUp(() {
      mockMessaging = MockPushMessagingClient();
      mockOrignaBase = MockOrignaBase();
      mockPush = MockOrignaBasePush();

      when(mockOrignaBase.push).thenReturn(mockPush);

      OrignaBaseNotificationService.instance.resetForTesting();
      OrignaBaseNotificationService.instance.messagingOverride = mockMessaging;
      OrignaBaseNotificationService.instance.onMessageOverride =
          const Stream.empty();
      OrignaBaseNotificationService.instance.onMessageOpenedAppOverride =
          const Stream.empty();
    });

    test('saveTokenToOrignaBase registers token with push API', () async {
      const testUid = 'user_123';
      const testToken = 'fake_fcm_token_xyz';

      when(mockMessaging.getToken()).thenAnswer((_) async => testToken);
      when(
        mockPush.registerToken(
          userId: anyNamed('userId'),
          token: anyNamed('token'),
          platform: anyNamed('platform'),
        ),
      ).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          obUserIdProvider.overrideWith((ref) => testUid),
          orignabaseProvider.overrideWithValue(mockOrignaBase),
        ],
      );
      OrignaBaseNotificationService.instance.testContainerOverride = container;

      await OrignaBaseNotificationService.instance.saveTokenToOrignaBase();

      verify(
        mockPush.registerToken(
          userId: testUid,
          token: testToken,
          platform: anyNamed('platform'),
        ),
      ).called(1);
    });

    test('clearTokenFromOrignaBase unregisters token', () async {
      const testUid = 'user_123';
      const testToken = 'fake_fcm_token_xyz';

      when(mockMessaging.getToken()).thenAnswer((_) async => testToken);
      when(mockPush.unregisterToken(testToken)).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          obUserIdProvider.overrideWith((ref) => testUid),
          orignabaseProvider.overrideWithValue(mockOrignaBase),
        ],
      );
      OrignaBaseNotificationService.instance.testContainerOverride = container;

      await OrignaBaseNotificationService.instance.clearTokenFromOrignaBase();

      verify(mockPush.unregisterToken(testToken)).called(1);
    });

    testWidgets('handleNotificationTap routes to orderDetail when orderId present',
        (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      bool pushedOrderDetail = false;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.orderDetail) {
              pushedOrderDetail = true;
              final args = settings.arguments as OrderDetailArgs;
              expect(args.orderId, 'order_abc');
            }
            return MaterialPageRoute(builder: (_) => Container());
          },
          home: Container(),
        ),
      );

      OrignaBaseNotificationService.instance.testNavigatorKey = navKey;

      final message = const AppRemoteMessage(
        data: {'type': 'order_status', 'orderId': 'order_abc'},
      );

      OrignaBaseNotificationService.instance.handleNotificationTap(message);
      await tester.pumpAndSettle();

      expect(pushedOrderDetail, true);
    });

    testWidgets('handleNotificationTap routes to orders when orderId absent',
        (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      bool pushedOrders = false;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.orders) {
              pushedOrders = true;
            }
            return MaterialPageRoute(builder: (_) => Container());
          },
          home: Container(),
        ),
      );

      OrignaBaseNotificationService.instance.testNavigatorKey = navKey;

      final message = const AppRemoteMessage(data: {'type': 'order_status'});

      OrignaBaseNotificationService.instance.handleNotificationTap(message);
      await tester.pumpAndSettle();

      expect(pushedOrders, true);
    });

    testWidgets('handleForegroundMessage shows SnackBar and handles tap',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      addTearDown(tester.view.resetPhysicalSize);

      final messengerKey = GlobalKey<ScaffoldMessengerState>();
      final navKey = GlobalKey<NavigatorState>();
      bool pushedOrderDetail = false;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          scaffoldMessengerKey: messengerKey,
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.orderDetail) {
              pushedOrderDetail = true;
            }
            return MaterialPageRoute(builder: (_) => Container());
          },
          home: Scaffold(body: Container()),
        ),
      );

      OrignaBaseNotificationService.instance.testScaffoldMessengerKey =
          messengerKey;
      OrignaBaseNotificationService.instance.testNavigatorKey = navKey;

      final message = const AppRemoteMessage(
        notification: AppRemoteNotification(
          title: 'Order Updated',
          body: 'Your order is ready',
        ),
        data: {'type': NotificationTypes.orderStatus, 'orderId': 'order_abc'},
      );

      OrignaBaseNotificationService.instance.handleForegroundMessage(message);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);

      final actionButton = find.text('common.view'.tr());
      expect(actionButton, findsOneWidget);

      await tester.tap(actionButton);
      await tester.pumpAndSettle();

      expect(pushedOrderDetail, true);
    });

    test('initialize sets up listeners on authorized permission', () async {
      when(
        mockMessaging.requestPermission(
          alert: anyNamed('alert'),
          announcement: anyNamed('announcement'),
          badge: anyNamed('badge'),
          carPlay: anyNamed('carPlay'),
          criticalAlert: anyNamed('criticalAlert'),
          provisional: anyNamed('provisional'),
          sound: anyNamed('sound'),
        ),
      ).thenAnswer((_) async => const AppNotificationSettings(
            authorizationStatus: AppNotificationAuthorizationStatus.authorized,
          ));
      when(mockMessaging.getToken()).thenAnswer((_) async => 'fake_token');
      when(mockMessaging.onTokenRefresh).thenAnswer((_) => const Stream.empty());
      when(mockMessaging.getInitialMessage()).thenAnswer((_) async => null);
      when(
        mockPush.registerToken(
          userId: anyNamed('userId'),
          token: anyNamed('token'),
          platform: anyNamed('platform'),
        ),
      ).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          obUserIdProvider.overrideWith((ref) => 'user_123'),
          orignabaseProvider.overrideWithValue(mockOrignaBase),
        ],
      );
      OrignaBaseNotificationService.instance.testContainerOverride = container;

      await OrignaBaseNotificationService.instance.initialize(null);

      verify(
        mockPush.registerToken(
          userId: 'user_123',
          token: 'fake_token',
          platform: anyNamed('platform'),
        ),
      ).called(1);
    });
  });
}
