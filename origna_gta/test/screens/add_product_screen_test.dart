import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/screens/addproduct_screen.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../test_utils.dart';

@GenerateNiceMocks([MockSpec<User>(), MockSpec<FirebaseFunctions>()])
import 'add_product_screen_test.mocks.dart';

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
  });

  group('AddProductScreen Smoke Test', () {
    testWidgets('renders add product screen correctly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1920);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(mockUser),
            firestoreProvider.overrideWithValue(fakeFirestore),
            firebaseFunctionsProvider.overrideWithValue(mockFunctions),
          ],
          child: const AddProductScreen(),
        ),
      );

      // Use pump() because of infinite animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('New Product'), findsOneWidget);
      expect(find.text('Product Details'), findsOneWidget);
      
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
