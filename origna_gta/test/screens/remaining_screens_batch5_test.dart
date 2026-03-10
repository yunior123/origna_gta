import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/screens/reset_password_screen.dart';
import 'package:origna_gta/screens/terms_screen.dart';
import 'package:origna_gta/screens/privacy_policy_screen.dart';
import 'package:origna_gta/screens/authwrapper_screen.dart';
import 'package:origna_gta/core/providers.dart';
import '../test_utils.dart';

import 'package:origna_gta/core/repositories/product_repository.dart';

@GenerateNiceMocks([MockSpec<ProductRepository>()])
import 'remaining_screens_batch5_test.mocks.dart';

void main() {
  late AppAuthUser mockUser;
  late MockProductRepository mockProductRepo;

  setUpAll(() {
    initTestMocks();
  });

  setUp(() {
    mockUser = const AppAuthUser(uid: 'test_user_123', email: 'test@example.com');
    mockProductRepo = MockProductRepository();
  });

  Future<void> pumpResilient(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    // Use a very short pumpAndSettle to clear any remaining microtasks/animations
    // but catch the timeout if it's an infinite animation.
    try {
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    } catch (_) {}
  }

  group('Remaining Screens Batch 5 Smoke Tests', () {
    testWidgets('renders reset password screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(mockUser),
            productRepositoryProvider.overrideWithValue(mockProductRepo),
          ],
          child: const ResetPasswordScreen(oobCode: 'test_code'),
        ),
      );
      await pumpResilient(tester);
      expect(find.byType(ResetPasswordScreen), findsOneWidget);
    });

    testWidgets('renders terms screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(mockUser),
            productRepositoryProvider.overrideWithValue(mockProductRepo),
          ],
          child: const TermsScreen(),
        ),
      );
      await pumpResilient(tester);
      expect(find.byType(TermsScreen), findsOneWidget);
    });

    testWidgets('renders privacy policy screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(mockUser),
            productRepositoryProvider.overrideWithValue(mockProductRepo),
          ],
          child: const PrivacyPolicyScreen(),
        ),
      );
      await pumpResilient(tester);
      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
    });

    testWidgets('renders auth wrapper screen', (WidgetTester tester) async {
      await tester.runAsync(() async {
        when(mockProductRepo.fetchProducts(
          searchQuery: anyNamed('searchQuery'),
          categoryId: anyNamed('categoryId'),
          subcategory: anyNamed('subcategory'),
          lastDocumentId: anyNamed('lastDocumentId'),
          pageSize: anyNamed('pageSize'),
          sortOption: anyNamed('sortOption'),
          minPriceCents: anyNamed('minPriceCents'),
          maxPriceCents: anyNamed('maxPriceCents'),
        )).thenAnswer((_) async => ProductQueryResult(products: [], lastDocumentId: null, hasMore: false));

        await tester.pumpWidget(
          TestWrapper(
            overrides: [
              currentUserProvider.overrideWithValue(null),
              productRepositoryProvider.overrideWithValue(mockProductRepo),
              authStateProvider.overrideWith((ref) => Stream.value(null)),
            ],
            child: const AuthWrapper(),
          ),
        );
        await tester.pump();
        await Future.delayed(const Duration(seconds: 1));
        await tester.pump();
      });
      expect(find.byType(AuthWrapper), findsOneWidget);
    });
  });
}
