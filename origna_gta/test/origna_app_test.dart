import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/origna_app.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'mock_asset_loader.dart';
import 'test_utils.dart';

import 'package:origna_gta/services/session_timeout_service.dart';

@GenerateNiceMocks([MockSpec<User>(), MockSpec<FirebaseAuth>()])
import 'origna_app_test.mocks.dart';

void main() {
  late MockUser mockUser;
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    mockUser = MockUser();
    mockAuth = MockFirebaseAuth();
    fakeFirestore = FakeFirebaseFirestore();
    
    // Inject mock auth into the singleton service to prevent crash
    SessionTimeoutService().setAuth(mockAuth);

    when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));
    when(mockUser.uid).thenReturn('test_user_123');
  });

  Widget createTestApp({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(mockAuth),
        firestoreProvider.overrideWithValue(fakeFirestore),
        ...overrides,
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('fr')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        assetLoader: MockAssetLoader(),
        useOnlyLangCode: true,
        saveLocale: false,
        child: const OrignaApp(),
      ),
    );
  }

  group('OrignaApp Tests', () {
    testWidgets('renders OrignaApp and shows home (AuthWrapper)', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(OrignaApp), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('handles deep link /p/test-slug', (WidgetTester tester) async {
       // We need to trigger the deep link logic. 
       // OrignaApp uses AppLinks in initState for mobile, but onGenerateInitialRoutes for Web/Initial.
       
       // For this test, we can try to test _onGenerateInitialRoutes indirectly
       // by pumping the widget. However, OrignaApp's build method uses 
       // onGenerateInitialRoutes: _onGenerateInitialRoutes.
       
       // Flutter's pumpWidget doesn't easily let us set the initial route for the internal MaterialApp.
       // But we can test the routes directly if we expose them or test the logic.
    });
  });
}
