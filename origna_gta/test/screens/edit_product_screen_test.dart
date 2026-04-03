import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/screens/editproduct_screen.dart';
import 'package:cross_file/cross_file.dart';
import '../test_utils.dart';

class _RecordingProductRepository implements ProductRepository {
  String? lastUpdatedProductId;
  Map<String, dynamic>? lastUpdatedData;

  @override
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> data,
  ) async {
    lastUpdatedProductId = productId;
    lastUpdatedData = data;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

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
  Future<Product?> fetchProductById(String productId) =>
      throw UnimplementedError();

  @override
  Future<ProductQueryResult> fetchProducts({
    String? searchQuery,
    int? categoryId,
    String? subcategory,
    String? sellerId,
    String? lastDocumentId,
    int pageSize = 20,
    SortOption sortOption = SortOption.relevance,
    int? minPriceCents,
    int? maxPriceCents,
  }) => throw UnimplementedError();

  @override
  Future<List<Product>> fetchProductsByIds(List<String> productIds) =>
      throw UnimplementedError();

  @override
  String generateProductId() => throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> getAutocompleteSuggestions(String query) =>
      Future.value(const []);

  @override
  Future<Product?> getProductBySlug(String slug) => throw UnimplementedError();

  @override
  Future<String?> getUploadUrl(String fileName) => throw UnimplementedError();

  @override
  Future<Map<String, String>?> getUploadUrlInfo(String fileName) =>
      throw UnimplementedError();

  @override
  Future<Map<String, String>?> getUploadVideoUrlInfo(
    String fileName,
    String contentType,
  ) => throw UnimplementedError();

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
    List<Uint8List>? reviewImages,
    String? reviewText,
  }) => throw UnimplementedError();

  @override
  Future<void> toggleFavorite(String userId, String productId) =>
      throw UnimplementedError();

  @override
  Future<List<String>> uploadImages(List<Uint8List> images, String productId) =>
      throw UnimplementedError();

  @override
  Future<String?> uploadProductVideo(XFile videoFile, String sellerId) =>
      throw UnimplementedError();

  @override
  Future<List<String>> uploadReviewImages(
    List<Uint8List> images,
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
  setUpAll(() {
    initTestMocks();
  });
  late AppAuthUser mockUser;
  late _RecordingProductRepository mockProductRepository;

  setUp(() {
    mockUser = const AppAuthUser(
      uid: 'test_user_123',
      email: 'test@example.com',
    );
    mockProductRepository = _RecordingProductRepository();
  });

  group('EditProductScreen Smoke Test', () {
    testWidgets('renders edit product screen correctly', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1920);
      tester.view.devicePixelRatio = 1.0;

      final testProduct = Product(
        productId: 'prod_123',
        name: 'Existing Product',
        description: 'Existing description.',
        priceCents: 4999,
        sellerId: 'test_user_123',
        categoryId: 1,
        imageUrls: [],
        stockQuantity: 5,
        createdAt: DateTime.now(),
        isDigital: false,
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [currentUserProvider.overrideWithValue(mockUser)],
          child: EditProductScreen(product: testProduct),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Existing Product'), findsOneWidget);
      expect(find.text('Basic Information'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('renders with full product data from API', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1920);
      tester.view.devicePixelRatio = 1.0;

      final testProduct = Product(
        productId: 'prod_full',
        name: 'Full Product',
        nameF: 'Produit Complet',
        description: 'Full product description.',
        descriptionF: 'Description complète du produit.',
        priceCents: 9999,
        compareAtPriceCents: 14999,
        sellerId: 'test_user_123',
        categoryId: 5,
        imageUrls: [
          'https://example.com/img1.jpg',
          'https://example.com/img2.jpg',
        ],
        stockQuantity: 25,
        createdAt: DateTime(2026, 1, 15),
        isDigital: false,
        isPerishable: false,
        isLocalDeliveryOnly: false,
        isAgeRestricted: false,
        estimatedShipDays: 5,
        minimumOrderQuantity: 2,
        freeShipping: false,
        weightKg: 1.5,
        lengthCm: 30.0,
        widthCm: 20.0,
        heightCm: 10.0,
        taxCode: 'txcd_99999999',
        sellerAddress: const Address(
          street: '123 Main St',
          apartment: 'Suite 4',
          city: 'Toronto',
          state: 'ON',
          postalCode: 'M5V 2T6',
          country: 'Canada',
          latitude: 43.6532,
          longitude: -79.3832,
        ),
        deliveryOptions: const [
          SellerDeliveryOption(
            type: 'standard',
            description: 'Standard Delivery',
            costCents: 599,
            estimatedDays: 5,
          ),
          SellerDeliveryOption(
            type: 'express',
            description: 'Express Delivery',
            costCents: 1299,
            estimatedDays: 2,
          ),
        ],
        inventory: const InventoryConfig(
          managed: true,
          trackQuantity: true,
          lowStockThreshold: 10,
        ),
        lifecycleStatus: 'active',
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [currentUserProvider.overrideWithValue(mockUser)],
          child: EditProductScreen(product: testProduct),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Full Product'), findsOneWidget);
      expect(find.text('Basic Information'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('renders with null sellerAddress', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1920);
      tester.view.devicePixelRatio = 1.0;

      final testProduct = Product(
        productId: 'prod_no_addr',
        name: 'No Address Product',
        description: 'Product without seller address.',
        priceCents: 2500,
        sellerId: 'test_user_123',
        categoryId: 3,
        imageUrls: [],
        stockQuantity: 0,
        createdAt: DateTime.now(),
        isDigital: false,
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [currentUserProvider.overrideWithValue(mockUser)],
          child: EditProductScreen(product: testProduct),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Address Product'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('renders digital product', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1920);
      tester.view.devicePixelRatio = 1.0;

      final testProduct = Product(
        productId: 'prod_digital',
        name: 'Digital Product',
        description: 'A software product.',
        priceCents: 1999,
        sellerId: 'test_user_123',
        categoryId: 21,
        imageUrls: ['https://example.com/img.jpg'],
        stockQuantity: 999,
        createdAt: DateTime.now(),
        isDigital: true,
        digitalType: 'software',
        digitalBuilds: const {
          'macos': 'https://example.com/macos.dmg',
          'windows': 'https://example.com/windows.exe',
        },
        deviceLimit: 3,
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [currentUserProvider.overrideWithValue(mockUser)],
          child: EditProductScreen(product: testProduct),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Digital Product'), findsWidgets);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('renders with invalid categoryId', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1920);
      tester.view.devicePixelRatio = 1.0;

      final testProduct = Product(
        productId: 'prod_bad_cat',
        name: 'Bad Category Product',
        description: 'Product with invalid categoryId.',
        priceCents: 999,
        sellerId: 'test_user_123',
        categoryId: 9999,
        imageUrls: [],
        stockQuantity: 1,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [currentUserProvider.overrideWithValue(mockUser)],
          child: EditProductScreen(product: testProduct),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Bad Category Product'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('save preserves quantity discounts and shipping extras', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2200);
      tester.view.devicePixelRatio = 1.0;

      final testProduct = Product(
        productId: 'prod_shipping',
        name: 'Shipping Product',
        description: 'Product with tiered shipping discounts.',
        priceCents: 4999,
        sellerId: 'test_user_123',
        categoryId: 1,
        imageUrls: const ['https://example.com/product.jpg'],
        stockQuantity: 5,
        createdAt: DateTime.now(),
        sellerAddress: const Address(
          street: '123 Main St',
          city: 'Toronto',
          state: 'ON',
          postalCode: 'M5V 2T6',
          country: 'Canada',
          latitude: 43.6532,
          longitude: -79.3832,
        ),
        deliveryOptions: const [
          SellerDeliveryOption(
            type: 'standard',
            description: 'Standard Delivery',
            costCents: 599,
            estimatedDays: 5,
            additionalItemCostCents: 125,
            maxItemsPerShipment: 4,
            quantityDiscounts: [
              ShippingQuantityDiscount(
                minQuantity: 3,
                discountType: 'percent',
                discountValue: 15,
                label: '15% off 3+',
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(mockUser),
            userIdProvider.overrideWithValue('test_user_123'),
            productRepositoryProvider.overrideWithValue(mockProductRepository),
          ],
          child: EditProductScreen(product: testProduct),
        ),
      );

      await tester.pumpAndSettle();
      await tester.ensureVisible(find.bySemanticsLabel('btn-save-product'));
      await tester.tap(find.bySemanticsLabel('btn-save-product'));
      await tester.pumpAndSettle();

      expect(mockProductRepository.lastUpdatedProductId, 'prod_shipping');
      final updateMap = mockProductRepository.lastUpdatedData!;
      final deliveryOptions = updateMap['deliveryOptions'] as List<dynamic>;
      final standard = deliveryOptions.single as SellerDeliveryOption;
      final discounts = standard.quantityDiscounts;

      expect(standard.additionalItemCostCents, 125);
      expect(standard.maxItemsPerShipment, 4);
      expect(discounts, hasLength(1));
      expect(discounts.single.minQuantity, 3);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
