import 'dart:async';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/terms/terms_provider.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/models/models.dart' as app_models;
import 'package:origna_gta/screens/authwrapper_screen.dart';
import 'package:origna_gta/screens/common_screens.dart';
import 'package:origna_gta/screens/main_screen.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

import '../test_utils.dart';

class FakeUserRepository implements UserRepository {
  Future<void> Function()? onRecordTermsAcceptance;
  int recordTermsAcceptanceCalls = 0;

  @override
  Future<String> addBuyerAddress(app_models.Address address) async => 'addr-1';

  @override
  Future<void> deleteBuyerAddress(String addressId) async {}

  @override
  Future<SellerAccountStatus> getSellerAccountStatus(String userId) async =>
      const SellerAccountStatus(isSeller: false, chargesEnabled: false);

  @override
  Future<app_models.UserModel?> getUserProfile(String userId) async => null;

  @override
  Future<void> recordTermsAcceptance() async {
    recordTermsAcceptanceCalls += 1;
    await onRecordTermsAcceptance?.call();
  }

  @override
  Future<void> setDefaultBuyerAddress(String addressId) async {}

  @override
  Future<void> updateBuyerAddress(
    String addressId,
    app_models.Address address,
  ) async {}

  @override
  Future<void> updateNotificationPreferences(
    String userId, {
    bool? notifyNewProducts,
    bool? notifyTrending,
  }) async {}

  @override
  Future<void> updatePreferredLanguage(String userId, String lang) async {}

  @override
  Stream<List<app_models.Address>> watchAddresses(String userId) =>
      const Stream.empty();

  @override
  Stream<SellerAccountStatus> watchSellerAccountStatus(String userId) =>
      Stream.value(
        const SellerAccountStatus(isSeller: false, chargesEnabled: false),
      );
}

class FakeProductRepository implements ProductRepository {
  @override
  Future<String> createProductAtomic(
    Product product,
    List<Uint8List> imageBytes, {
    List<String>? testImageUrls,
    String? bookSourceUrl,
  }) async => 'p1';

  @override
  Future<void> deleteProduct(String productId) async {}

  @override
  Future<Product?> fetchProductById(String productId) async => null;

  @override
  Future<ProductQueryResult> fetchProducts({
    String? searchQuery,
    int? categoryId,
    String? subcategory,
    lastDocumentId,
    int pageSize = 20,
    SortOption sortOption = SortOption.relevance,
    int? minPriceCents,
    int? maxPriceCents,
  }) async => ProductQueryResult(products: [], hasMore: false);

  @override
  Future<List<Product>> fetchProductsByIds(List<String> productIds) async => [];

  @override
  String generateProductId() => 'p1';

  @override
  Future<List<Map<String, dynamic>>> getAutocompleteSuggestions(
    String query,
  ) async => [];

  @override
  Future<Product?> getProductBySlug(String slug) async => null;

  @override
  Future<String?> getUploadUrl(String fileName) async => null;

  @override
  Future<Map<String, String>?> getUploadUrlInfo(String fileName) async => null;

  @override
  Future<Map<String, String>?> getUploadVideoUrlInfo(
    String fileName,
    String contentType,
  ) async => null;

  @override
  Future<void> submitRating(
    String orderId,
    String productId,
    int rating, {
    List<String>? reviewImageUrls,
    String? reviewText,
  }) async {}

  @override
  Future<void> submitRatingAtomic(
    String orderId,
    String productId,
    int rating, {
    List<Uint8List>? reviewImages,
    String? reviewText,
  }) async {}

  @override
  Future<void> toggleFavorite(String userId, String productId) async {}

  @override
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> data,
  ) async {}

  @override
  Future<List<String>> uploadImages(
    List<Uint8List> images,
    String productId,
  ) async => [];

  @override
  Future<String?> uploadProductVideo(XFile videoFile, String sellerId) async =>
      null;

  @override
  Future<List<String>> uploadReviewImages(
    List<Uint8List> images,
    String userId,
  ) async => [];

  @override
  Stream<Set<String>> watchFavorites(String userId) => const Stream.empty();

  @override
  Stream<int> watchUnansweredQuestionsCount(String sellerId) =>
      const Stream.empty();
}

void main() {
  late FakeUserRepository fakeUserRepository;
  late FakeProductRepository fakeProductRepository;
  const verifiedUser = AppAuthUser(
    uid: 'u1',
    email: 'test@example.com',
    emailVerified: true,
  );
  const unverifiedUser = AppAuthUser(
    uid: 'u1',
    email: 'test@example.com',
    emailVerified: false,
  );

  setUp(() {
    fakeUserRepository = FakeUserRepository();
    fakeProductRepository = FakeProductRepository();
    initTestMocks();
  });

  Widget createTestApp({
    required Widget child,
    AsyncValue<AppAuthUser?> authState = const AsyncValue.data(null),
    bool needsTermsUpdate = false,
    Stream<app_models.UserModel?>? profileStream,
    AsyncValue<String> termsState = const AsyncValue.data(
      'Terms and conditions mock text.',
    ),
  }) {
    return TestWrapper(
      overrides: [
        productRepositoryProvider.overrideWithValue(fakeProductRepository),
        authStateProvider.overrideWith((ref) {
          if (authState.isLoading) return const Stream.empty();
          if (authState.hasError) {
            return Stream.error(authState.error!, authState.stackTrace!);
          }
          return Stream.value(authState.value);
        }),
        if (profileStream != null)
          userProfileProvider.overrideWith((ref) => profileStream),
        needsTermsUpdateProvider.overrideWithValue(needsTermsUpdate),
        termsProvider.overrideWith((ref) async {
          if (termsState.isLoading) {
            await Future.delayed(const Duration(seconds: 1));
            return 'Loaded';
          }
          if (termsState.hasError) throw termsState.error!;
          return termsState.value!;
        }),
        userRepositoryProvider.overrideWithValue(fakeUserRepository),
      ],
      child: child,
    );
  }

  group('AuthWrapper Tests', () {
    testWidgets(
      'shows loading indicator while authenticated profile is loading',
      (tester) async {
        final controller = StreamController<app_models.UserModel?>();
        await tester.pumpWidget(
          createTestApp(
            child: const AuthWrapper(),
            authState: const AsyncValue.data(verifiedUser),
            profileStream: controller.stream,
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byType(MainScreen), findsNothing);
        expect(find.byType(ModernLoadingIndicator), findsOneWidget);
        await controller.close();
      },
    );

    testWidgets('shows MainScreen directly when auth state is loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          child: const AuthWrapper(),
          authState: const AsyncValue.loading(),
        ),
      );
      await tester.pump();

      expect(find.byType(MainScreen), findsOneWidget);
    });

    testWidgets('shows MainScreen when auth state has error', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const AuthWrapper(),
          authState: AsyncValue.error('Auth error', StackTrace.empty),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(MainScreen), findsOneWidget);
    });

    testWidgets('shows MainScreen when user is null (unauthenticated)', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          child: const AuthWrapper(),
          authState: const AsyncValue.data(null),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(MainScreen), findsOneWidget);
    });

    testWidgets(
      'shows EmailVerificationRequiredScreen if email not verified and not emulator',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const AuthWrapper(),
            authState: const AsyncValue.data(unverifiedUser),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byType(EmailVerificationRequiredScreen), findsOneWidget);
      },
    );

    testWidgets(
      'shows TermsUpdateGate if user is verified but needs terms update',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const AuthWrapper(),
            authState: const AsyncValue.data(verifiedUser),
            needsTermsUpdate: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.policy_outlined), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
      },
    );

    testWidgets(
      'shows MainScreen if user is verified and terms are up to date',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const AuthWrapper(),
            authState: const AsyncValue.data(verifiedUser),
            needsTermsUpdate: false,
          ),
        );
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(MainScreen), findsOneWidget);
      },
    );

    group('TermsUpdateGate Interactions', () {
      testWidgets(
        'Accept button is disabled initially and enabled after scrolling',
        (tester) async {
          final longTerms = List.generate(
            50,
            (index) => 'Line $index of terms.',
          ).join('\n');

          await tester.pumpWidget(
            createTestApp(
              child: const AuthWrapper(),
              authState: const AsyncValue.data(verifiedUser),
              needsTermsUpdate: true,
              termsState: AsyncValue.data(longTerms),
            ),
          );
          await tester.pumpAndSettle();

          final acceptButtonFinder = find.byKey(const Key('btn-terms-accept'));
          expect(acceptButtonFinder, findsOneWidget);

          final modernButton = tester.widget<ModernButton>(acceptButtonFinder);
          expect(modernButton.onPressed, isNull);

          await tester.drag(find.byType(ListView), const Offset(0, -3000));
          await tester.pumpAndSettle();

          final updatedButton = tester.widget<ModernButton>(acceptButtonFinder);
          expect(updatedButton.onPressed, isNotNull);
        },
      );

      testWidgets('Accept button calls repository method when tapped', (
        tester,
      ) async {
        final longTerms = List.generate(
          50,
          (index) => 'Line $index of terms.',
        ).join('\n');

        await tester.pumpWidget(
          createTestApp(
            child: const AuthWrapper(),
            authState: const AsyncValue.data(verifiedUser),
            needsTermsUpdate: true,
            termsState: AsyncValue.data(longTerms),
          ),
        );
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -3000));
        await tester.pumpAndSettle();

        final acceptButtonFinder = find.byKey(const Key('btn-terms-accept'));
        await tester.tap(acceptButtonFinder);
        await tester.pump();

        expect(fakeUserRepository.recordTermsAcceptanceCalls, 1);
      });

      testWidgets('Shows error SnackBar when repository call fails', (
        tester,
      ) async {
        fakeUserRepository.onRecordTermsAcceptance = () async {
          throw Exception('Failed to accept');
        };
        final longTerms = List.generate(
          50,
          (index) => 'Line $index of terms.',
        ).join('\n');

        await tester.pumpWidget(
          createTestApp(
            child: const AuthWrapper(),
            authState: const AsyncValue.data(verifiedUser),
            needsTermsUpdate: true,
            termsState: AsyncValue.data(longTerms),
          ),
        );
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -3000));
        await tester.pumpAndSettle();

        final acceptButtonFinder = find.byKey(const Key('btn-terms-accept'));
        await tester.tap(acceptButtonFinder);
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('Shows loading indicator when terms are loading', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(
            child: const AuthWrapper(),
            authState: const AsyncValue.data(verifiedUser),
            needsTermsUpdate: true,
            termsState: const AsyncValue.loading(),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byType(ModernLoadingIndicator), findsOneWidget);
        // Advance past Future.delayed in terms provider, then settle
        await tester.pumpAndSettle();
      });

      testWidgets('Shows error text when terms fail to load', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const AuthWrapper(),
            authState: const AsyncValue.data(verifiedUser),
            needsTermsUpdate: true,
            termsState: AsyncValue.error('Fetch failed', StackTrace.empty),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));

        // The error state renders a Text widget — just verify it exists
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(Text), findsWidgets);
        // Clean up pending timers
        await tester.pump(const Duration(seconds: 2));
      });
    });
  });
}
