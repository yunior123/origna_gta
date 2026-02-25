import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/services/conf_services.dart';
import 'package:origna_gta/utils/utils.dart';

class FirebaseProductRepository implements ProductRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  FirebaseProductRepository(this._firestore, this._functions);

  @override
  @Deprecated(
    'Use createProductAtomic() instead — addProduct() bypasses server-controlled fields '
    '(sellerId validation, lifecycleStatus=under_review, SKU dedup). '
    'Will be removed before launch.',
  )
  Future<String> addProduct(Product product) async {
    throw UnsupportedError(
      'addProduct() is disabled. Use createProductAtomic() to create products '
      'through the server-validated Cloud Function.',
    );
  }

  @override
  @Deprecated(
    'Use createProductAtomic() instead — addProductWithId() bypasses server-controlled fields. '
    'Will be removed before launch.',
  )
  Future<void> addProductWithId(String productId, Product product) async {
    throw UnsupportedError(
      'addProductWithId() is disabled. Use createProductAtomic() to create products '
      'through the server-validated Cloud Function.',
    );
  }

  @override
  String generateProductId() {
    return _firestore.collection(Collections.products).doc().id;
  }

  @override
  /// Creates a product atomically via Cloud Function, uploading images to R2 storage.
  ///
  /// [imageBytes] are compressed JPEG bytes for each image; [testImageUrls] bypasses
  /// upload in dev/emulator runs. Returns the Firestore document ID assigned server-side.
  /// Throws [Exception] if the function returns no productId.
  Future<String> createProductAtomic(
    Product product,
    List<Uint8List> imageBytes, {
    List<String>? testImageUrls,
  }) async {
    final productJson = product.toJson()
      ..remove(Fields.productId)
      ..remove(Fields.imageUrls)
      ..remove(Fields.createdAt)
      ..remove(Fields.rating)
      ..remove(Fields.ratingCount);

    // Normalize apartment: empty string → null (matches sanitizeProductForFirestore)
    final sellerAddress = productJson[Fields.sellerAddress];
    if (sellerAddress is Map) {
      final addr = Map<String, dynamic>.from(sellerAddress.cast<String, dynamic>());
      if (addr['apartment'] is String && (addr['apartment'] as String).trim().isEmpty) {
        addr['apartment'] = null;
      }
      productJson[Fields.sellerAddress] = addr;
    }

    final images = imageBytes
        .map((bytes) => {
              'data': base64Encode(bytes),
              'contentType': 'image/jpeg',
            })
        .toList();

    final payload = <String, dynamic>{
      'productData': productJson,
      'images': images,
    };
    if (testImageUrls != null && testImageUrls.isNotEmpty) {
      payload['testImageUrls'] = testImageUrls;
    }

    final result = await _functions
        .httpsCallable(CloudFunctionEndpoints.createProductAtomic)
        .call(payload);

    final productId = result.data[Fields.productId] as String?;
    if (productId == null || productId.isEmpty) {
      throw Exception('create_product_atomic returned no productId');
    }
    return productId;
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _functions.httpsCallable(CloudFunctionEndpoints.deleteProduct).call({
      Fields.productId: productId,
    });
  }

  @override
  /// Fetches a single product by Firestore document ID.
  ///
  /// Returns null if the document does not exist or its [lifecycleStatus] is not `active`.
  Future<Product?> fetchProductById(String productId) async {
    final doc = await _firestore
        .collection(Collections.products)
        .doc(productId)
        .get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    if (data[Fields.lifecycleStatus] != ProductLifecycleStatusValues.active) return null;
    return Product.fromFirestore(doc);
  }

  @override
  Future<Product?> getProductBySlug(String slug) async {
    final snap = await _firestore
        .collection(Collections.products)
        .where(Fields.slug, isEqualTo: slug)
        .where(Fields.lifecycleStatus, isEqualTo: ProductLifecycleStatusValues.active)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Product.fromFirestore(snap.docs.first);
  }

  @override
  /// Fetches a paginated list of active products with optional keyword and category filters.
  ///
  /// [lastDocument] is the pagination cursor returned by a previous call.
  /// Returns [ProductQueryResult] containing the page of products, the new cursor, and [hasMore].
  Future<ProductQueryResult> fetchProducts({
    String? searchQuery,
    int? categoryId,
    String? subcategory,
    DocumentSnapshot? lastDocument,
    int pageSize = 20,
  }) async {
    Query query = _firestore.collection(Collections.products);

    query = query.where(Fields.lifecycleStatus, isEqualTo: ProductLifecycleStatusValues.active);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.where(
        Fields.keywords,
        arrayContains: searchQuery.toLowerCase().trim(),
      );
    }

    if (categoryId != null) {
      query = query.where(Fields.categoryId, isEqualTo: categoryId);
    }

    if (subcategory != null && subcategory.isNotEmpty) {
      query = query.where(Fields.subcategory, isEqualTo: subcategory);
    }

    query = query.orderBy(Fields.createdAt, descending: true).limit(pageSize);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    final products = snapshot.docs
        .map((doc) => Product.fromFirestore(doc))
        .toList();
    final hasMore = snapshot.docs.length >= pageSize;

    return ProductQueryResult(
      products: products,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: hasMore,
    );
  }

  @override
  /// Batch-fetches products by ID, ignoring lifecycle status.
  ///
  /// Fetches in chunks of 30 to respect Firestore `whereIn` limits. Inactive products
  /// are intentionally included so cart items can surface an "unavailable" state rather
  /// than silently disappearing from the buyer's view (see F-79).
  Future<List<Product>> fetchProductsByIds(List<String> productIds) async {
    if (productIds.isEmpty) return [];

    final List<Product> results = [];
    // F-79: Fetch regardless of lifecycleStatus so inactive cart items show "unavailable"
    // instead of silently disappearing from the buyer's cart.
    for (int i = 0; i < productIds.length; i += 30) {
      final chunk = productIds.skip(i).take(30).toList();
      final snapshot = await _firestore
          .collection(Collections.products)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(
        snapshot.docs
            .map((doc) => Product.fromFirestore(doc)),
      );
    }
    return results;
  }

  @override
  Future<List<Map<String, dynamic>>> getAutocompleteSuggestions(
    String query,
  ) async {
    final String apiKey = ConfigService().geoapifyKey;
    final encodedQuery = Uri.encodeQueryComponent(query);
    final response = await http.get(
      Uri.parse(
        'https://api.geoapify.com/v1/geocode/autocomplete?text=$encodedQuery&filter=countrycode:ca&apiKey=$apiKey',
      ),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['features'] ?? []);
    }
    return [];
  }

  @override
  Future<Map<String, String>?> getUploadUrlInfo(String fileName) async {
    final result = await _functions
        .httpsCallable(CloudFunctionEndpoints.uploadProductImages)
        .call({'fileNames': [fileName], 'contentTypes': ['image/jpeg']});
    final uploadUrls = List<Map<String, dynamic>>.from(result.data['uploadUrls'] ?? []);
    if (uploadUrls.isEmpty) return null;
    return {
      'uploadUrl': uploadUrls[0]['uploadUrl'] as String,
      'publicUrl': uploadUrls[0]['publicUrl'] as String,
    };
  }

  @override
  Future<String?> getUploadUrl(String fileName) async {
    final info = await getUploadUrlInfo(fileName);
    return info?['uploadUrl'];
  }

  @override
  /// Submits a product rating (1–5) and optional review via Cloud Function.
  ///
  /// [orderId] scopes the rating to a verified purchase. [reviewImageUrls] and
  /// [reviewText] are optional; omitting them submits a star-only rating.
  Future<void> submitRating(
    String orderId,
    String productId,
    int rating, {
    List<String>? reviewImageUrls,
    String? reviewText,
  }) async {
    final payload = {
      Fields.orderId: orderId,
      Fields.productId: productId,
      Fields.rating: rating,
    };
    if (reviewImageUrls != null && reviewImageUrls.isNotEmpty) {
      payload[Fields.reviewImageUrls] = reviewImageUrls;
    }
    if (reviewText != null && reviewText.isNotEmpty) {
      payload[Fields.reviewText] = reviewText;
    }
    await _functions
        .httpsCallable(CloudFunctionEndpoints.submitProductRating)
        .call(payload);
  }

  @override
  /// Toggles the favorite status of a product for the given user.
  ///
  /// Uses a Firestore transaction to prevent duplicate subcollection writes from rapid taps.
  /// [userId] The authenticated user UID. [productId] The product to toggle.
  Future<void> toggleFavorite(String userId, String productId) async {
    final favRef = _firestore
        .collection(Collections.users)
        .doc(userId)
        .collection(Collections.favorites)
        .doc(productId);

    // RACE CONDITION FIX: Use transaction to prevent duplicate writes from rapid taps
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(favRef);
      if (doc.exists) {
        transaction.delete(favRef);
      } else {
        transaction.set(favRef, {
          Fields.productId: productId,
          Fields.dateFavorited: FieldValue.serverTimestamp(),
        });
      }
    });
  }

  @override
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> data,
  ) async {
    final sanitized = sanitizeProductForFirestore(data);

    // Re-denormalize shipFrom fields when warehouseIds are updated
    final rawWarehouseIds = data[Fields.warehouseIds];
    if (rawWarehouseIds is List && rawWarehouseIds.isNotEmpty) {
      final sellerId = data[Fields.sellerId] as String?;
      if (sellerId != null && sellerId.isNotEmpty) {
        try {
          final warehouseIds = rawWarehouseIds.cast<String>();
          final warehouseDocs = await Future.wait(
            warehouseIds.map((wId) => _firestore
                .collection(Collections.users)
                .doc(sellerId)
                .collection(Collections.warehouses)
                .doc(wId)
                .get()),
          );

          final primaryData = warehouseDocs
              .where((d) => d.exists)
              .map((d) => d.data()!)
              .firstWhereOrNull((d) => d[Fields.isDefault] == true) ??
              warehouseDocs.where((d) => d.exists).map((d) => d.data()!).firstOrNull;
          if (primaryData != null) {
            final addr = primaryData['address'] as Map<String, dynamic>?;
            sanitized[Fields.shipFromCity] = addr?[Fields.city];
            sanitized[Fields.shipFromProvince] = addr?[Fields.state];
            sanitized[Fields.shipFromCountry] = addr?[Fields.country];
          }

          final countries = warehouseDocs
              .where((d) => d.exists)
              .map((d) => (d.data()!['address'] as Map<String, dynamic>?)?[Fields.country] as String?)
              .whereType<String>()
              .toSet()
              .toList();
          if (countries.isNotEmpty) {
            sanitized[Fields.shipFromCountries] = countries;
          }
        } catch (e) {
          AppError.log(e, context: 'updateProduct.warehouseDenorm');
        }
      }
    }

    await _firestore
        .collection(Collections.products)
        .doc(productId)
        .update(sanitized);
  }

  @override
  /// Uploads product images to R2 and returns their public CDN URLs.
  ///
  /// [images] Raw JPEG bytes per image; [productId] is used to derive filenames.
  /// Performs best-effort cleanup of any already-uploaded files on partial failure to
  /// avoid R2 orphans. Throws [Exception] if any single image fails all retries.
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
      // Partial failure — clean up successfully uploaded images to avoid R2 orphans
      if (urls.isNotEmpty) {
        try {
          await _functions
              .httpsCallable(CloudFunctionEndpoints.deleteProductImages)
              .call({'publicUrls': urls});
        } catch (_) {
          // Best-effort cleanup; ignore errors so the original error is surfaced
        }
      }
      throw Exception('product.image_upload_failed'.tr());
    }
    return urls;
  }

  @override
  /// Streams the set of product IDs the user has favorited, updating in real-time.
  ///
  /// [userId] The authenticated user UID.
  /// Returns a [Stream] of product ID strings capped at [BusinessRules.favoritesPageSize].
  Stream<Set<String>> watchFavorites(String userId) {
    return _firestore
        .collection(Collections.users)
        .doc(userId)
        .collection(Collections.favorites)
        .limit(BusinessRules.favoritesPageSize)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  // Sanitization is now handled by the shared top-level
  // sanitizeProductForFirestore() function in this file.

  Future<String?> _uploadSingleImage(
    Uint8List bytes,
    String productId,
    int index,
  ) async {
    const maxRetries = 3;
    // Derive MIME type and extension from magic bytes
    final mimeType = _detectImageMimeType(bytes);
    final ext = mimeType.split('/').last.replaceFirst('jpeg', 'jpg');
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final fileName =
            "product_${productId}_${index}_${DateTime.now().millisecondsSinceEpoch}.$ext";
        final urlInfo = await getUploadUrlInfo(fileName);

        if (urlInfo == null) throw Exception('Could not get upload URL');

        final response = await http
            .put(
              Uri.parse(urlInfo['uploadUrl']!),
              body: bytes,
              headers: {"Content-Type": mimeType},
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

  /// Detect image MIME type from magic bytes header.
  static String _detectImageMimeType(Uint8List bytes) {
    if (bytes.length < 4) return 'image/jpeg';
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'image/png';
    }
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    // WebP: RIFF????WEBP
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return 'image/webp';
    }
    // GIF: GIF8
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38) {
      return 'image/gif';
    }
    return 'image/jpeg'; // default fallback
  }

  @override
  Future<List<String>> uploadReviewImages(List<Uint8List> images, String userId) async {
    if (images.isEmpty) return [];
    final fileNames = List.generate(images.length, (i) => 'review_${userId}_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    final contentTypes = List.filled(images.length, 'image/jpeg');

    final result = await _functions
        .httpsCallable(CloudFunctionEndpoints.uploadReviewImages)
        .call({'fileNames': fileNames, 'contentTypes': contentTypes});

    final uploadUrls = List<Map<String, dynamic>>.from(result.data['uploadUrls'] ?? []);

    final uploadFutures = uploadUrls.asMap().entries.map((entry) async {
      final i = entry.key;
      final urlInfo = entry.value;
      try {
        final response = await http
            .put(
              Uri.parse(urlInfo['uploadUrl'] as String),
              body: images[i],
              headers: {'Content-Type': 'image/jpeg'},
            )
            .timeout(const Duration(seconds: 30));
        if (response.statusCode == 200) return urlInfo['publicUrl'] as String;
        return null;
      } catch (_) {
        return null;
      }
    });

    final results = await Future.wait(uploadFutures);
    return results.whereType<String>().toList();
  }
}

class ProductQueryResult {
  final List<Product> products;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  ProductQueryResult({
    required this.products,
    this.lastDocument,
    required this.hasMore,
  });
}

/// Shared sanitization for product data before writing to Firestore.
/// Used by both [FirebaseProductRepository] and [AlgoliaProductRepository].
Map<String, dynamic> sanitizeProductForFirestore(
  Map<String, dynamic> rawData, {
  bool ensureDateCreated = false,
}) {
  final encoded = jsonEncode(rawData);
  final decoded = jsonDecode(encoded);
  final data = (decoded as Map).cast<String, dynamic>();

  // productId is derived from document id; avoid storing a client-controlled field.
  data.remove(Fields.productId);
  // ratingCount and rating are server-managed via rating events; do not allow client write.
  data.remove(Fields.ratingCount);
  data.remove(Fields.rating);
  // sellerId and lifecycleStatus are server-controlled; strip to prevent client overwrite.
  data.remove(Fields.sellerId);
  data.remove(Fields.lifecycleStatus);

  // Firestore rules expect sellerAddress.apartment to be null OR non-empty string.
  // Address model defaults apartment to '', so normalize empty values to null.
  final sellerAddress = data[Fields.sellerAddress];
  if (sellerAddress is Map) {
    final address = Map<String, dynamic>.from(
      sellerAddress.cast<String, dynamic>(),
    );
    final apartment = address['apartment'];
    if (apartment is String && apartment.trim().isEmpty) {
      address['apartment'] = null;
    }
    data[Fields.sellerAddress] = address;
  }

  // Ensure createdAt is stored as a server timestamp (not a client-side value)
  // When ensureDateCreated is true (new products), always use FieldValue.serverTimestamp()
  // to prevent clock skew or manipulation.
  if (ensureDateCreated) {
    data[Fields.createdAt] = FieldValue.serverTimestamp();
  } else if (data.containsKey(Fields.createdAt)) {
    final createdAt = data[Fields.createdAt];
    if (createdAt is String) {
      try {
        data[Fields.createdAt] = Timestamp.fromDate(DateTime.parse(createdAt));
      } catch (_) {
        data[Fields.createdAt] = FieldValue.serverTimestamp();
      }
    } else if (createdAt is DateTime) {
      data[Fields.createdAt] = Timestamp.fromDate(createdAt);
    }
  }

  return data;
}

abstract class ProductRepository {
  Future<String> addProduct(Product product);
  Future<void> addProductWithId(String productId, Product product);
  Future<String> createProductAtomic(Product product, List<Uint8List> imageBytes, {List<String>? testImageUrls});
  Future<void> deleteProduct(String productId);
  Future<Product?> fetchProductById(String productId);
  Future<ProductQueryResult> fetchProducts({
    String? searchQuery,
    int? categoryId,
    String? subcategory,
    DocumentSnapshot? lastDocument,
    int pageSize = 20,
  });
  Future<List<Product>> fetchProductsByIds(List<String> productIds);
  String generateProductId();
  Future<List<Map<String, dynamic>>> getAutocompleteSuggestions(String query);
  Future<Product?> getProductBySlug(String slug);
  Future<Map<String, String>?> getUploadUrlInfo(String fileName);
  Future<String?> getUploadUrl(String fileName);
  Future<void> submitRating(String orderId, String productId, int rating, {List<String>? reviewImageUrls, String? reviewText});
  Future<void> toggleFavorite(String userId, String productId);
  Future<void> updateProduct(String productId, Map<String, dynamic> data);
  Future<List<String>> uploadImages(List<Uint8List> images, String productId);
  Future<List<String>> uploadReviewImages(List<Uint8List> images, String userId);
  Stream<Set<String>> watchFavorites(String userId);
}
