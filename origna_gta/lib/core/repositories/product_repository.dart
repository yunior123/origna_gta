import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  Future<String> addProduct(Product product) async {
    if (kDebugMode) {
      debugPrint('REPO: Attempting to add product: ${product.name}');
    }
    try {
      final firestoreData = sanitizeProductForFirestore(
        product.toJson(),
        ensureDateCreated: true,
      );

      // Pre-write sellerSku uniqueness check (safety net; on_product_created trigger is 2nd layer)
      final sellerSku = product.sellerSku;
      if (sellerSku != null && sellerSku.isNotEmpty) {
        final existing = await _firestore
            .collection(Collections.products)
            .where(Fields.sellerId, isEqualTo: product.sellerId)
            .where(Fields.sellerSku, isEqualTo: sellerSku)
            .limit(1)
            .get();
        if (existing.docs.isNotEmpty) {
          throw Exception(
            'A product with SKU "$sellerSku" already exists. '
            'Use a unique seller SKU per product.',
          );
        }
      }

      // Denormalize shipFrom fields from warehouses for O(1) card rendering
      final warehouseIds = product.warehouseIds;
      if (warehouseIds != null && warehouseIds.isNotEmpty) {
        try {
          // Fetch all warehouse docs in parallel
          final warehouseDocs = await Future.wait(
            warehouseIds.map((wId) => _firestore
                .collection(Collections.users)
                .doc(product.sellerId)
                .collection(Collections.warehouses)
                .doc(wId)
                .get()),
          );

          // Primary warehouse: prefer the default, fall back to first
          final primaryData = warehouseDocs
              .where((d) => d.exists)
              .map((d) => d.data()!)
              .firstWhereOrNull((d) => d[Fields.isDefault] == true) ??
          warehouseDocs.where((d) => d.exists).map((d) => d.data()!).firstOrNull;
          if (primaryData != null) {
            final addr = primaryData['address'] as Map<String, dynamic>?;
            firestoreData[Fields.shipFromCity] = addr?[Fields.city];
            firestoreData[Fields.shipFromProvince] = addr?[Fields.state];
            firestoreData[Fields.shipFromCountry] = addr?[Fields.country];
          }

          // All unique countries across every warehouse
          final countries = warehouseDocs
              .where((d) => d.exists)
              .map((d) => (d.data()!['address'] as Map<String, dynamic>?)?[Fields.country] as String?)
              .whereType<String>()
              .toSet()
              .toList();
          if (countries.isNotEmpty) {
            firestoreData[Fields.shipFromCountries] = countries;
          }
        } catch (e) {
          AppError.log(e, context: 'addProduct.warehouseDenorm');
        }
      }

      final docRef = await _firestore
          .collection(Collections.products)
          .add(firestoreData);
      if (kDebugMode) {
        debugPrint(
          'REPO: Product added successfully locally with ID: ${docRef.id}',
        );
      }

      // Debug-only server verification to confirm write persisted
      if (kDebugMode) {
        try {
          debugPrint('REPO: [FirebaseProductRepository] Verifying write from SERVER...');
          final docSnapshot = await docRef.get(const GetOptions(source: Source.server));
          if (docSnapshot.exists) {
            debugPrint('REPO: SERVER VERIFICATION SUCCESS!');
          } else {
            debugPrint('REPO: SERVER VERIFICATION FAILED: Document does not exist on server.');
          }
        } catch (e) {
          debugPrint('REPO: SERVER VERIFICATION ERROR: $e');
        }
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('REPO: Error adding product: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> addProductWithId(String productId, Product product) async {
    if (kDebugMode) debugPrint('REPO: Adding product with ID: $productId');
    final firestoreData = sanitizeProductForFirestore(
      product.toJson(),
      ensureDateCreated: true,
    );
    try {
      // SKU uniqueness check (same as addProduct — safety net before write)
      final sellerSku = product.sellerSku;
      if (sellerSku != null && sellerSku.isNotEmpty) {
        final existing = await _firestore
            .collection(Collections.products)
            .where(Fields.sellerId, isEqualTo: product.sellerId)
            .where(Fields.sellerSku, isEqualTo: sellerSku)
            .limit(1)
            .get();
        if (existing.docs.isNotEmpty) {
          throw Exception(
            'A product with SKU "$sellerSku" already exists. '
            'Use a unique seller SKU per product.',
          );
        }
      }

      // Denormalize shipFrom fields from warehouses for O(1) card rendering
      final warehouseIds = product.warehouseIds;
      if (warehouseIds != null && warehouseIds.isNotEmpty) {
        try {
          final warehouseDocs = await Future.wait(
            warehouseIds.map((wId) => _firestore
                .collection(Collections.users)
                .doc(product.sellerId)
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
            firestoreData[Fields.shipFromCity] = addr?[Fields.city];
            firestoreData[Fields.shipFromProvince] = addr?[Fields.state];
            firestoreData[Fields.shipFromCountry] = addr?[Fields.country];
          }

          final countries = warehouseDocs
              .where((d) => d.exists)
              .map((d) => (d.data()!['address'] as Map<String, dynamic>?)?[Fields.country] as String?)
              .whereType<String>()
              .toSet()
              .toList();
          if (countries.isNotEmpty) {
            firestoreData[Fields.shipFromCountries] = countries;
          }
        } catch (_) {
          // Non-fatal — card falls back gracefully
        }
      }

      if (kDebugMode) {
        final currentUser = FirebaseAuth.instance.currentUser;
        debugPrint(
          'REPO: addProductWithId auth uid=${currentUser?.uid} email=${currentUser?.email}',
        );
        debugPrint(
          'REPO: addProductWithId payload sellerId=${firestoreData[Fields.sellerId]} state=${(firestoreData[Fields.sellerAddress] as Map?)?['state']} apartment=${(firestoreData[Fields.sellerAddress] as Map?)?['apartment']} keys=${firestoreData.keys.toList()}',
        );
      }

      final docRef = _firestore.collection(Collections.products).doc(productId);
      await docRef.set(firestoreData);

      // Debug-only server verification
      if (kDebugMode) {
        try {
          final docSnapshot = await docRef.get(const GetOptions(source: Source.server));
          if (docSnapshot.exists) {
            debugPrint('REPO: Product added with predetermined ID: $productId');
          } else {
            debugPrint('REPO: SERVER VERIFICATION FAILED: Document does not exist on server.');
          }
        } catch (e) {
          debugPrint('REPO: SERVER VERIFICATION ERROR: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        if (e is FirebaseException) {
          debugPrint(
            'REPO: addProductWithId FirebaseException code=${e.code} message=${e.message}',
          );
        } else {
          debugPrint('REPO: addProductWithId error: $e');
        }
      }
      rethrow;
    }
  }

  @override
  String generateProductId() {
    return _firestore.collection(Collections.products).doc().id;
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _functions.httpsCallable(CloudFunctionEndpoints.deleteProduct).call({
      Fields.productId: productId,
    });
  }

  @override
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
  Future<List<Product>> fetchProductsByIds(List<String> productIds) async {
    if (productIds.isEmpty) return [];

    final List<Product> results = [];
    // Firestore whereIn has a limit of 30 (previously 10, now 30 in some versions, but let's be safe with 10 or 30)
    // Actually current limit is 30. Let's use 30.
    for (int i = 0; i < productIds.length; i += 30) {
      final chunk = productIds.skip(i).take(30).toList();
      final snapshot = await _firestore
          .collection(Collections.products)
          .where(FieldPath.documentId, whereIn: chunk)
          .where(Fields.lifecycleStatus, isEqualTo: ProductLifecycleStatusValues.active)
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
    await _firestore
        .collection(Collections.products)
        .doc(productId)
        .update(sanitized);
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
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final fileName =
            "product_${productId}_${index}_${DateTime.now().millisecondsSinceEpoch}.jpg";
        final urlInfo = await getUploadUrlInfo(fileName);

        if (urlInfo == null) throw Exception('Could not get upload URL');

        final response = await http
            .put(
              Uri.parse(urlInfo['uploadUrl']!),
              body: bytes,
              headers: {"Content-Type": "image/jpeg"},
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
  // ratingCount and rating are server-managed via rating events; do not allow client write on create.
  data.remove(Fields.ratingCount);
  data.remove(Fields.rating);

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
