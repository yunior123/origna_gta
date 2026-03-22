import 'dart:async';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:origna_gta/utils/app_logger.dart';
import 'package:http/http.dart' as http;
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/compat/timestamp.dart' show truncateNanoseconds;
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/core/repositories/product_search_helpers.dart';
import 'package:origna_gta/core/repositories/product_image_helpers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart';

/// OrignaBase implementation of [ProductRepository].
///
/// Search/query logic is in [ProductSearchHelpers].
/// Image upload logic is in [ProductImageHelpers].
class OrignaBaseProductRepository
    with ProductSearchHelpers, ProductImageHelpers
    implements ProductRepository {
  final OrignaBase _ob;
  final http.Client _httpClient;

  OrignaBaseProductRepository(this._ob, {http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  // Mixin accessors
  @override
  OrignaBase get ob => _ob;
  @override
  http.Client get httpClient => _httpClient;

  // ---------------------------------------------------------------------------
  // Auth helper
  // ---------------------------------------------------------------------------

  String? get _currentUserId => _ob.auth.currentUserId;

  // ---------------------------------------------------------------------------
  // Helper: convert OrignaBase Document -> Product
  // ---------------------------------------------------------------------------
  @override
  Product docToProduct(Document doc) {
    final data = <String, dynamic>{...doc.data};

    data[Fields.name] ??= data['title'] ?? 'Untitled product';
    data[Fields.description] ??= '';
    // Backend may store images as 'images' — map to 'imageUrls' for model
    data[Fields.imageUrls] ??= data['images'] ?? const <String>[];
    data[Fields.sellerId] ??= '';
    // categoryId may arrive as String from backend — coerce to int
    if (data[Fields.categoryId] is String) {
      data[Fields.categoryId] =
          int.tryParse(data[Fields.categoryId] as String) ?? 0;
    }
    data[Fields.categoryId] ??= 0;
    data[Fields.stockQuantity] ??= 0;
    data[Fields.priceCents] ??= 0;
    data[Fields.price] ??=
        ((data[Fields.priceCents] as num?)?.toDouble() ?? 0) / 100;
    data[Fields.rating] ??= 0.0;
    data[Fields.ratingCount] ??= 0;
    data[Fields.keywords] ??= const <String>[];
    data[Fields.lifecycleStatus] ??= ProductLifecycleStatusValues.draft;
    data[Fields.createdAt] ??=
        data[Fields.dateCreated] ?? DateTime.now().toIso8601String();

    // Normalize timestamps: SurrealDB returns nanosecond-precision ISO strings
    // (e.g. "2026-03-12T11:56:03.185238962+00:00") which Dart's DateTime.parse
    // cannot handle (only supports up to microseconds). Truncate to 6 decimal places.
    for (final key in [
      Fields.createdAt,
      Fields.dateCreated,
      Fields.updatedAt,
      'trendingAt',
      'lastLowStockAlertAt',
    ]) {
      final raw = data[key];
      if (raw is String) {
        data[key] = truncateNanoseconds(raw);
      } else if (raw is DateTime) {
        data[key] = raw.toIso8601String();
      }
    }

    // Strip collection prefix (e.g. "products:abc" -> "abc")
    data[Fields.productId] = doc.id.contains(':')
        ? doc.id.split(':').last
        : doc.id;
    return Product.fromJson(data);
  }

  // ---------------------------------------------------------------------------
  // Product CRUD
  // ---------------------------------------------------------------------------

  @override
  Future<String> createProductAtomic(
    Product product,
    List<Uint8List> imageBytes, {
    List<String>? testImageUrls,
    String? bookSourceUrl,
  }) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      throw Exception('Not authenticated');
    }

    final productJson = product.toJson()
      ..remove(Fields.productId)
      ..remove(Fields.imageUrls)
      ..remove(Fields.createdAt)
      ..remove(Fields.rating)
      ..remove(Fields.ratingCount);

    if (bookSourceUrl != null && bookSourceUrl.isNotEmpty) {
      productJson['bookSourceUrl'] = bookSourceUrl;
    }

    // Normalize apartment
    final sellerAddress = productJson[Fields.sellerAddress];
    if (sellerAddress is Map) {
      final addr = Map<String, dynamic>.from(
        sellerAddress.cast<String, dynamic>(),
      );
      if (addr['apartment'] is String &&
          (addr['apartment'] as String).trim().isEmpty) {
        addr['apartment'] = null;
      }
      productJson[Fields.sellerAddress] = addr;
    }

    final result = await _ob.request(
      'POST',
      ApiEndpoints.productsCreateAtomic,
      body: {
        Fields.userId: userId,
        'productData': productJson,
        'testImageUrls': testImageUrls ?? const <String>[],
      },
    );

    final productId = result[Fields.productId] as String?;
    if (productId == null || productId.isEmpty) {
      throw Exception('create_product_atomic returned no productId');
    }

    var imageUrls = testImageUrls ?? const <String>[];
    if (imageUrls.isEmpty && imageBytes.isNotEmpty) {
      imageUrls = await uploadImages(imageBytes, productId);
      await _ob.request(
        'POST',
        ApiEndpoints.productsUploadImages,
        body: {Fields.productId: productId, Fields.imageUrls: imageUrls},
      );
    }

    return productId;
  }

  @override
  Future<void> deleteProduct(String productId) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      throw Exception('Not authenticated');
    }
    await _ob.request(
      'POST',
      ApiEndpoints.productsDelete,
      body: {Fields.productId: productId, Fields.userId: userId},
    );
  }

  @override
  Future<Product?> fetchProductById(String productId) =>
      fetchProductByIdImpl(productId);

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
  }) => fetchProductsImpl(
    searchQuery: searchQuery,
    categoryId: categoryId,
    subcategory: subcategory,
    lastDocumentId: lastDocumentId,
    pageSize: pageSize,
    sortOption: sortOption,
    minPriceCents: minPriceCents,
    maxPriceCents: maxPriceCents,
  );

  @override
  Future<List<Product>> fetchProductsByIds(List<String> productIds) =>
      fetchProductsByIdsImpl(productIds);

  @override
  String generateProductId() {
    return DateTime.now().microsecondsSinceEpoch.toRadixString(36) +
        (DateTime.now().hashCode & 0xFFFF).toRadixString(36);
  }

  @override
  Future<List<Map<String, dynamic>>> getAutocompleteSuggestions(
    String query,
  ) async {
    try {
      final response = await _ob.request(
        'POST',
        ApiEndpoints.geocodeAutocomplete,
        body: {'query': query, 'country': 'ca'},
      );
      final features = response['features'];
      if (features is List) {
        return List<Map<String, dynamic>>.from(features);
      }
    } catch (e) {
      AppLogger.d('[getAutocompleteSuggestions] $e', tag: 'product');
    }
    return [];
  }

  @override
  Future<Product?> getProductBySlug(String slug) => getProductBySlugImpl(slug);

  @override
  Future<String?> getUploadUrl(String fileName) async {
    final info = await getUploadUrlInfo(fileName);
    return info?['uploadUrl'];
  }

  @override
  Future<Map<String, String>?> getUploadUrlInfo(String fileName) =>
      getUploadUrlInfoImpl(fileName);

  @override
  Future<Map<String, String>?> getUploadVideoUrlInfo(
    String fileName,
    String contentType,
  ) => getUploadVideoUrlInfoImpl(fileName, contentType);

  @override
  Future<void> submitRating(
    String orderId,
    String productId,
    int rating, {
    List<String>? reviewImageUrls,
    String? reviewText,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    await _ob.request(
      'POST',
      ApiEndpoints.productsSubmitRating,
      body: {
        Fields.orderId: orderId,
        Fields.productId: productId,
        Fields.rating: rating,
        Fields.userId: userId,
        if (reviewImageUrls != null && reviewImageUrls.isNotEmpty)
          Fields.reviewImageUrls: reviewImageUrls,
        if (reviewText != null && reviewText.isNotEmpty)
          Fields.reviewText: reviewText,
      },
    );
  }

  @override
  Future<void> submitRatingAtomic(
    String orderId,
    String productId,
    int rating, {
    List<Uint8List>? reviewImages,
    String? reviewText,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    final reviewImageUrls = reviewImages == null || reviewImages.isEmpty
        ? const <String>[]
        : await uploadReviewImages(reviewImages, userId);
    await _ob.request(
      'POST',
      ApiEndpoints.productsSubmitRatingAtomic,
      body: {
        Fields.orderId: orderId,
        Fields.productId: productId,
        Fields.rating: rating,
        Fields.userId: userId,
        'images': reviewImageUrls,
        if (reviewText != null && reviewText.isNotEmpty)
          Fields.reviewText: reviewText,
      },
    );
  }

  @override
  Future<void> toggleFavorite(String userId, String productId) async {
    await _ob.request(
      'POST',
      ApiEndpoints.productsToggleFavorite,
      body: {Fields.userId: userId, Fields.productId: productId},
    );
  }

  @override
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> data,
  ) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      throw Exception('Not authenticated');
    }
    await _ob.request(
      'POST',
      ApiEndpoints.productsUpdate,
      body: {
        Fields.productId: productId,
        Fields.userId: userId,
        'productData': data,
      },
    );
  }

  @override
  Future<List<String>> uploadImages(List<Uint8List> images, String productId) =>
      uploadImagesImpl(images, productId);

  @override
  Future<String?> uploadProductVideo(XFile videoFile, String sellerId) async {
    final bytes = await videoFile.readAsBytes();
    final ext = videoFile.name.split('.').last.toLowerCase();
    String contentType = 'video/mp4';
    if (ext == 'mov') contentType = 'video/quicktime';
    if (ext == 'webm') contentType = 'video/webm';

    final fileName =
        'product_video_${sellerId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final urlInfo = await getUploadVideoUrlInfo(fileName, contentType);

    if (urlInfo == null) throw Exception('Video upload failed');

    final response = await _httpClient
        .put(
          Uri.parse(urlInfo['uploadUrl']!),
          body: bytes,
          headers: {'Content-Type': contentType},
        )
        .timeout(const Duration(minutes: 5));

    if (response.statusCode == 200) {
      return urlInfo['publicUrl'];
    }
    throw Exception('Upload failed with status ${response.statusCode}');
  }

  @override
  Future<List<String>> uploadReviewImages(
    List<Uint8List> images,
    String userId,
  ) => uploadReviewImagesImpl(images, userId);

  @override
  Stream<Set<String>> watchFavorites(String userId) {
    final favoritesQuery = _ob
        .collection(Collections.favorites)
        .where(Fields.userId, isEqualTo: userId)
        .orderBy(Fields.createdAt, descending: true)
        .limit(BusinessRules.favoritesPageSize);
    final Set<String> favorites = {};
    final controller = StreamController<Set<String>>();

    favoritesQuery
        .get()
        .then((snapshot) {
          favorites
            ..clear()
            ..addAll(
              snapshot.docs
                  .map((doc) => doc.data[Fields.productId] as String?)
                  .whereType<String>(),
            );
          controller.add(Set<String>.from(favorites));
        })
        .catchError((Object error, StackTrace stackTrace) {
          controller.addError(error, stackTrace);
        });

    final realtime = RealtimeClient(_ob);
    realtime.connect();
    late final StreamSubscription<DocumentChange> sub;
    try {
      sub = realtime.subscribe(Collections.favorites).listen((change) {
        final data = change.document.data;
        if (data[Fields.userId] != userId) return;
        final productId = data[Fields.productId] as String?;
        if (productId == null || productId.isEmpty) return;
        switch (change.type) {
          case ChangeType.create:
          case ChangeType.update:
            favorites.add(productId);
          case ChangeType.delete:
            favorites.remove(productId);
        }
        controller.add(Set<String>.from(favorites));
      }, onError: controller.addError);
    } catch (e, st) {
      controller.addError(e, st);
      controller.close();
      return controller.stream;
    }

    controller.onCancel = () {
      sub.cancel();
      realtime.disconnect();
    };

    return controller.stream;
  }

  @override
  Stream<int> watchUnansweredQuestionsCount(String sellerId) {
    late StreamController<int> controller;
    Timer? timer;

    Future<void> fetch() async {
      try {
        final snapshot = await _ob
            .collection(Collections.productQuestions)
            .where(Fields.sellerId, isEqualTo: sellerId)
            .where(Fields.isAnswered, isEqualTo: false)
            .limit(500)
            .get();
        if (!controller.isClosed) {
          controller.add(snapshot.docs.length);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    controller = StreamController<int>(
      onListen: () {
        fetch();
        timer = Timer.periodic(const Duration(seconds: 10), (_) => fetch());
      },
      onCancel: () {
        timer?.cancel();
      },
    );

    return controller.stream;
  }
}
