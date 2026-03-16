// coverage:ignore-file
import 'dart:async';
import 'dart:convert';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/services/conf_services.dart';

/// OrignaBase implementation of [ProductRepository].
class OrignaBaseProductRepository implements ProductRepository {
  final OrignaBase _ob;
  final http.Client _httpClient;
  final ConfigService _configService;

  OrignaBaseProductRepository(
    this._ob, {
    http.Client? httpClient,
    ConfigService? configService,
  }) : _httpClient = httpClient ?? http.Client(),
       _configService = configService ?? ConfigService();

  // ---------------------------------------------------------------------------
  // Auth helper
  // ---------------------------------------------------------------------------

  String? get _currentUserId => _ob.auth.currentUserId;

  // ---------------------------------------------------------------------------
  // Helper: convert OrignaBase Document → Product
  // ---------------------------------------------------------------------------
  Product _docToProduct(Document doc) {
    final data = <String, dynamic>{...doc.data};

    // Normalize timestamps: SurrealDB returns nanosecond-precision ISO strings
    // (e.g. "2026-03-12T11:56:03.185238962+00:00") which Dart's DateTime.parse
    // cannot handle (only supports up to microseconds). Truncate to 6 decimal places.
    for (final key in [
      Fields.createdAt,
      Fields.updatedAt,
      'trendingAt',
      'lastLowStockAlertAt',
    ]) {
      final raw = data[key];
      if (raw is String) {
        data[key] = _truncateNanoseconds(raw);
      } else if (raw is DateTime) {
        data[key] = raw.toIso8601String();
      }
    }

    // Strip collection prefix (e.g. "products:abc" → "abc")
    data[Fields.productId] = doc.id.contains(':') ? doc.id.split(':').last : doc.id;
    return Product.fromJson(data);
  }

  /// Truncate subsecond precision to 6 digits (microseconds) so Dart can parse it.
  static String _truncateNanoseconds(String iso) {
    return iso.replaceAllMapped(RegExp(r'(\.\d{6})\d+'), (m) => m.group(1)!);
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
  Future<Product?> fetchProductById(String productId) async {
    final doc = await _ob.collection(Collections.products).doc(productId).get();
    if (doc == null || !doc.exists) return null;
    if (doc.data[Fields.lifecycleStatus] !=
        ProductLifecycleStatusValues.active) {
      return null;
    }
    return _docToProduct(doc);
  }

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
  }) async {
    Query query = _ob
        .collection(Collections.products)
        .where(
          Fields.lifecycleStatus,
          isEqualTo: ProductLifecycleStatusValues.active,
        );

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final words = searchQuery.toLowerCase().trim().split(RegExp(r'\s+'));
      for (final word in words) {
        if (word.isNotEmpty) {
          query = query.where(
            Fields.keywords,
            contains: word,
          );
        }
      }
    }

    if (categoryId != null) {
      query = query.where(Fields.categoryId, isEqualTo: categoryId);
    }

    if (subcategory != null && subcategory.isNotEmpty) {
      query = query.where(Fields.subcategory, isEqualTo: subcategory);
    }

    if (minPriceCents != null) {
      query = query.where(Fields.priceCents, isGreaterThan: minPriceCents - 1);
    }
    if (maxPriceCents != null) {
      query = query.where(Fields.priceCents, isLessThan: maxPriceCents + 1);
    }

    // Sort ordering
    switch (sortOption) {
      case SortOption.priceLowToHigh:
        query = query
            .orderBy(Fields.priceCents)
            .orderBy(Fields.createdAt, descending: true);
      case SortOption.priceHighToLow:
        query = query
            .orderBy(Fields.priceCents, descending: true)
            .orderBy(Fields.createdAt, descending: true);
      case SortOption.newest:
      case SortOption.relevance:
        query = query.orderBy(Fields.createdAt, descending: true);
    }

    // N+1 pattern for hasMore detection
    query = query.limit(pageSize + 1);

    // Cursor pagination using document ID.
    if (lastDocumentId != null) {
      query = query.startAfterId(lastDocumentId);
    }

    final snapshot = await query.get();

    final hasMore = snapshot.docs.length > pageSize;
    final docsToMap = hasMore
        ? snapshot.docs.take(pageSize).toList()
        : snapshot.docs;

    final products = docsToMap.expand((doc) {
      try {
        return [_docToProduct(doc)];
      } catch (e) {
        debugPrint(
          'OrignaBaseProductRepo: skipping malformed doc ${doc.id}: $e',
        );
        return <Product>[];
      }
    }).toList();

    return ProductQueryResult(
      products: products,
      lastDocumentId: products.isNotEmpty ? products.last.productId : null,
      hasMore: hasMore,
    );
  }

  @override
  Future<List<Product>> fetchProductsByIds(List<String> productIds) async {
    if (productIds.isEmpty) return [];

    final List<Product> results = [];
    // Fetch in chunks of 30 to avoid oversized parallel batches.
    for (int i = 0; i < productIds.length; i += 30) {
      final chunk = productIds.skip(i).take(30).toList();
      // OrignaBase: fetch each doc individually since whereIn on doc ID
      // is not directly supported. Use parallel fetches.
      final futures = chunk.map(
        (id) => _ob.collection(Collections.products).doc(id).get(),
      );
      final docs = await Future.wait(futures);
      for (final doc in docs) {
        if (doc != null && doc.exists) {
          try {
            results.add(_docToProduct(doc));
          } catch (e) {
            debugPrint(
              'OrignaBaseProductRepo: skipping malformed doc ${doc.id}: $e',
            );
          }
        }
      }
    }
    return results;
  }

  @override
  String generateProductId() {
    // Generate a unique ID client-side (OrignaBase can use UUIDs)
    return DateTime.now().microsecondsSinceEpoch.toRadixString(36) +
        (DateTime.now().hashCode & 0xFFFF).toRadixString(36);
  }

  @override
  Future<List<Map<String, dynamic>>> getAutocompleteSuggestions(
    String query,
  ) async {
    final String apiKey = _configService.geoapifyKey;
    final encodedQuery = Uri.encodeQueryComponent(query);
    final response = await _httpClient.get(
      Uri.parse(
        '${ExternalUrls.geoapifyBase}/geocode/autocomplete?text=$encodedQuery&filter=countrycode:ca&apiKey=$apiKey',
      ),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['features'] ?? []);
    }
    return [];
  }

  @override
  Future<Product?> getProductBySlug(String slug) async {
    final snapshot = await _ob
        .collection(Collections.products)
        .where(Fields.slug, isEqualTo: slug)
        .where(
          Fields.lifecycleStatus,
          isEqualTo: ProductLifecycleStatusValues.active,
        )
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return _docToProduct(snapshot.docs.first);
  }

  @override
  Future<String?> getUploadUrl(String fileName) async {
    final info = await getUploadUrlInfo(fileName);
    return info?['uploadUrl'];
  }

  @override
  Future<Map<String, String>?> getUploadUrlInfo(String fileName) async {
    final path = 'products/$fileName';
    final result = await _ob.request(
      'POST',
      '/storage/presign/upload',
      body: {
        'paths': [path],
        'ttl_secs': 3600,
      },
    );
    final resultMap = Map<String, dynamic>.from(result as Map);
    final urls = List<Map<String, dynamic>>.from(resultMap['urls'] ?? []);
    if (urls.isEmpty) return null;
    return {
      'uploadUrl': urls[0]['upload_url'] as String,
      'publicUrl': urls[0]['path'] as String,
    };
  }

  @override
  Future<Map<String, String>?> getUploadVideoUrlInfo(
    String fileName,
    String contentType,
  ) async {
    final path = 'products/videos/$fileName';
    final result = await _ob.request(
      'POST',
      '/storage/presign/upload',
      body: {
        'paths': [path],
        'ttl_secs': 3600,
      },
    );
    final resultMap = Map<String, dynamic>.from(result as Map);
    final urls = List<Map<String, dynamic>>.from(resultMap['urls'] ?? []);
    if (urls.isEmpty) return null;
    return {
      'uploadUrl': urls[0]['upload_url'] as String,
      'publicUrl': urls[0]['path'] as String,
    };
  }

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
  Future<List<String>> uploadImages(
    List<Uint8List> images,
    String productId,
  ) async {
    final uploadFutures = images.asMap().entries.map((entry) async {
      return await _uploadSingleImage(entry.value, productId, entry.key);
    });

    final results = await Future.wait(uploadFutures);
    final urls = results.whereType<String>().toList();
    if (urls.length != images.length) {
      // Partial failure — clean up successfully uploaded images
      if (urls.isNotEmpty) {
        try {
          await _ob.request(
            'POST',
            '/storage/batch-delete',
            body: {'paths': urls},
          );
        } catch (_) {
          // Best-effort cleanup
        }
      }
      throw Exception('Image upload failed');
    }
    return urls;
  }

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
  ) async {
    if (images.isEmpty) return [];
    final ts = DateTime.now().millisecondsSinceEpoch;
    final paths = List.generate(
      images.length,
      (i) => 'reviews/$userId/img_${i}_$ts.jpg',
    );

    final result = await _ob.request(
      'POST',
      '/storage/presign/upload',
      body: {'paths': paths, 'ttl_secs': 3600},
    );

    final resultMap = Map<String, dynamic>.from(result as Map);
    final urls = List<Map<String, dynamic>>.from(resultMap['urls'] ?? []);

    final uploadFutures = urls.asMap().entries.map((entry) async {
      final i = entry.key;
      final urlInfo = entry.value;
      try {
        final response = await _httpClient
            .put(
              Uri.parse(urlInfo['upload_url'] as String),
              body: images[i],
              headers: {'Content-Type': 'image/jpeg'},
            )
            .timeout(const Duration(seconds: 30));
        if (response.statusCode == 200) return urlInfo['path'] as String;
        return null;
      } catch (_) {
        return null;
      }
    });

    final results = await Future.wait(uploadFutures);
    return results.whereType<String>().toList();
  }

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
    final sub = realtime.subscribe(Collections.favorites).listen((change) {
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

    controller.onCancel = () {
      sub.cancel();
      realtime.disconnect();
    };

    return controller.stream;
  }

  @override
  Stream<int> watchUnansweredQuestionsCount(String sellerId) {
    // Polling-based: OrignaBase doesn't support query-level snapshots yet.
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

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<String?> _uploadSingleImage(
    Uint8List bytes,
    String productId,
    int index,
  ) async {
    const maxRetries = 3;
    final mimeType = _detectImageMimeType(bytes);
    final ext = mimeType.split('/').last.replaceFirst('jpeg', 'jpg');
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final fileName =
            'product_${productId}_${index}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final urlInfo = await getUploadUrlInfo(fileName);

        if (urlInfo == null) throw Exception('Could not get upload URL');

        final response = await _httpClient
            .put(
              Uri.parse(urlInfo['uploadUrl']!),
              body: bytes,
              headers: {'Content-Type': mimeType},
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          return urlInfo['publicUrl'];
        }
        throw Exception('Upload failed with status ${response.statusCode}');
      } catch (e) {
        if (attempt == maxRetries) return null;
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    return null;
  }

  static String _detectImageMimeType(Uint8List bytes) {
    if (bytes.length < 4) return 'image/jpeg';
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return 'image/gif';
    }
    return 'image/jpeg';
  }
}
