import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/addressmanagement_screen.dart';
import 'package:origna_gta/screens/editaddress_screen.dart';
import 'package:origna_gta/screens/notifications_screen.dart';
import 'package:origna_gta/screens/ordersuccess_screen.dart';
import 'package:origna_gta/core/providers.dart';
import '../test_utils.dart';


void main() {
  late AppAuthUser mockUser;

  setUpAll(() {
    initTestMocks();
  });

  setUp(() {
    mockUser = const AppAuthUser(uid: 'test_user_123', email: 'test@example.com');
  });

  Future<void> pumpResilient(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(
      TestWrapper(
        overrides: [
          currentUserProvider.overrideWithValue(mockUser),
        ],
        child: widget,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    try {
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    } catch (_) {}
  }

  group('Remaining Screens Batch 6 Smoke Tests', () {
    testWidgets('renders AddressManagementScreen', (tester) async {
      await pumpResilient(tester, const AddressManagementScreen());
      expect(find.byType(AddressManagementScreen), findsOneWidget);
    });

    testWidgets('renders AddEditAddressScreen (New)', (tester) async {
      await pumpResilient(tester, const AddEditAddressScreen());
      expect(find.byType(AddEditAddressScreen), findsOneWidget);
    });

    testWidgets('renders NotificationsScreen', (tester) async {
      await pumpResilient(tester, const NotificationsScreen());
      expect(find.byType(NotificationsScreen), findsOneWidget);
    });

    testWidgets('renders OrderSuccessScreen', (tester) async {
      await pumpResilient(tester, const OrderSuccessScreen(orderId: 'o1'));
      expect(find.byType(OrderSuccessScreen), findsOneWidget);
    });
  });
}
