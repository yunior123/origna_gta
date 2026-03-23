import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/main_screen.dart';
import 'package:origna_gta/core/providers.dart';
import '../test_utils.dart';

import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart';

class FakeProductRepository implements ProductRepository {
  @override
  Future<String> createProductAtomic(
    Product product,
    List<Uint8List> imageBytes, {
    List<String>? testImageUrls,
    String? bookSourceUrl,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteProduct(String productId) => throw UnimplementedError();

  @override
  Future<Product?> fetchProductById(String productId) async => null;

  @override
  Future<ProductQueryResult> fetchProducts({
    String? searchQuery,
    int? categoryId,
    String? subcategory,
    String? lastDocumentId,
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
  }) => throw UnimplementedError();

  @override
  Future<void> submitRatingAtomic(
    String orderId,
    String productId,
    int rating, {
    List<List<int>>? reviewImages,
    String? reviewText,
  }) => throw UnimplementedError();

  @override
  Future<void> toggleFavorite(String userId, String productId) =>
      throw UnimplementedError();

  @override
  Future<void> updateProduct(String productId, Map<String, dynamic> data) =>
      throw UnimplementedError();

  @override
  Future<List<String>> uploadImages(List<List<int>> images, String productId) =>
      throw UnimplementedError();

  @override
  Future<String?> uploadProductVideo(videoFile, String sellerId) async => null;

  @override
  Future<List<String>> uploadReviewImages(
    List<List<int>> images,
    String userId,
  ) => throw UnimplementedError();

  @override
  Stream<Set<String>> watchFavorites(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) => const Stream.empty();

  @override
  Stream<int> watchUnansweredQuestionsCount(String sellerId) =>
      const Stream.empty();
}

void main() {
  const signedInUser = AppAuthUser(
    uid: 'test_user_123',
    email: 'test@example.com',
    emailVerified: true,
  );
  late FakeProductRepository fakeProductRepo;

  setUpAll(() {
    initTestMocks();
  });

  setUp(() {
    fakeProductRepo = FakeProductRepository();
  });

  group('MainScreen Smoke Test', () {
    testWidgets('renders main screen correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(signedInUser),
            productRepositoryProvider.overrideWithValue(fakeProductRepo),
          ],
          child: const MainScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(
        const Duration(seconds: 5),
      ); // Wait for 3s timer in initState

      expect(find.byType(MainScreen), findsOneWidget);
    });
  });
}
