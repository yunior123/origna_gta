import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/screens/checkout_screen.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import '../test_utils.dart';

@GenerateNiceMocks([MockSpec<User>(), MockSpec<FirebaseFunctions>()])
import 'checkout_screen_test.mocks.dart';

void main() {
  setUpAll(() {
    initTestMocks();
  });
  late MockUser mockUser;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseFunctions mockFunctions;

  setUp(() {
    mockUser = MockUser();
    fakeFirestore = FakeFirebaseFirestore();
    mockFunctions = MockFirebaseFunctions();
    when(mockUser.uid).thenReturn('test_user_123');
    when(mockUser.email).thenReturn('test@example.com');
  });

  group('CheckoutScreen Smoke Test', () {
    testWidgets('renders checkout screen correctly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1920);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(mockUser),
            firestoreProvider.overrideWithValue(fakeFirestore),
            firebaseFunctionsProvider.overrideWithValue(mockFunctions),
          ],
          child: const CheckoutScreen(
            items: [],
            total: 0.0,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Checkout'), findsOneWidget);
      
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
