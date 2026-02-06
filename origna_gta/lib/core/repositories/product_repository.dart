import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/services/conf_services.dart';

class FirebaseProductRepository implements ProductRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  FirebaseProductRepository(this._firestore, this._functions);

  @override
  Future<String> addProduct(Product product) async {
    if (kDebugMode) debugPrint('REPO: Attempting to add product: ${product.name}');
    try {
      final firestoreData = _sanitizeProductForFirestore(product.toJson(), ensureDateCreated: true);
      final docRef = await _firestore.collection(Collections.products).add(firestoreData);
      if (kDebugMode) debugPrint('REPO: Product added successfully locally with ID: ${docRef.id}');

      // DIAGNOSTIC: Check connectivity
      try {
        if (kDebugMode) debugPrint('REPO: [FirebaseProductRepository] Verifying write from SERVER...');
        final docSnapshot = await docRef.get(const GetOptions(source: Source.server));
        if (docSnapshot.exists) {
          if (kDebugMode) debugPrint('REPO: SERVER VERIFICATION SUCCESS!');
        } else {
          if (kDebugMode) debugPrint('REPO: SERVER VERIFICATION FAILED: Document does not exist on server.');
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'sync-failed',
            message: '[FirebaseProductRepository] Write succeeded locally but failed to persist to server.',
          );
        }
      } catch (e) {
        if (kDebugMode) debugPrint('REPO: SERVER VERIFICATION ERROR: $e');
        if (e is FirebaseException && e.code == 'sync-failed') rethrow;
        // If network error on get(), it usually means offline/blocked
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'sync-failed-network',
          message: '[FirebaseProductRepository] Server verification threw error: $e',
        );
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) debugPrint('REPO: Error adding product: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _functions.httpsCallable('delete_product').call({Fields.productId: productId});
  }

  @override
  Future<Product?> fetchProductById(String productId) async {
    final doc = await _firestore.collection(Collections.products).doc(productId).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    if (data[Fields.isActive] == false) return null;
    return Product.fromFirestore(doc);
  }

  @override
  Future<ProductQueryResult> fetchProducts({String? searchQuery, int? categoryId, DocumentSnapshot? lastDocument, int pageSize = 20}) async {
    Query query = _firestore.collection(Collections.products);

    query = query.where(Fields.isActive, isEqualTo: true);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.where(Fields.keywords, arrayContains: searchQuery.toLowerCase().trim());
    }

    if (categoryId != null) {
      query = query.where(Fields.categoryId, isEqualTo: categoryId);
    }

    query = query.orderBy(Fields.dateCreated, descending: true).limit(pageSize);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    final products = snapshot.docs.map((doc) => Product.fromFirestore(doc)).where((p) => p.isActive).toList();
    final hasMore = snapshot.docs.length >= pageSize;

    return ProductQueryResult(products: products, lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null, hasMore: hasMore);
  }

  @override
  Future<List<Product>> fetchProductsByIds(List<String> productIds) async {
    if (productIds.isEmpty) return [];

    final List<Product> results = [];
    // Firestore whereIn has a limit of 30 (previously 10, now 30 in some versions, but let's be safe with 10 or 30)
    // Actually current limit is 30. Let's use 30.
    for (int i = 0; i < productIds.length; i += 30) {
      final chunk = productIds.skip(i).take(30).toList();
      final snapshot = await _firestore.collection(Collections.products).where(FieldPath.documentId, whereIn: chunk).where(Fields.isActive, isEqualTo: true).get();
      results.addAll(snapshot.docs.map((doc) => Product.fromFirestore(doc)).where((p) => p.isActive));
    }
    return results;
  }

  @override
  Future<List<Map<String, dynamic>>> getAutocompleteSuggestions(String query) async {
    final String apiKey = ConfigService().geoapifyKey;
    final response = await http.get(Uri.parse('https://api.geoapify.com/v1/geocode/autocomplete?text=$query&filter=countrycode:ca&apiKey=$apiKey'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['features'] ?? []);
    }
    return [];
  }

  @override
  Future<String?> getUploadUrl(String fileName) async {
    final result = await _functions.httpsCallable('get_r2_presigned_url').call({'fileName': fileName});
    return result.data['uploadUrl'];
  }

  @override
  Future<void> submitRating(String orderId, String productId, int rating) async {
    await _functions.httpsCallable('submit_product_rating').call({Fields.orderId: orderId, Fields.productId: productId, Fields.rating: rating});
  }

  @override
  Future<void> toggleFavorite(String userId, String productId) async {
    final favRef = _firestore.collection(Collections.users).doc(userId).collection(Collections.favorites).doc(productId);
    final doc = await favRef.get();

    if (doc.exists) {
      await favRef.delete();
    } else {
      await favRef.set({Fields.productId: productId, Fields.dateFavorited: FieldValue.serverTimestamp()});
    }
  }

  @override
  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    final sanitized = _sanitizeProductForFirestore(data);
    await _firestore.collection(Collections.products).doc(productId).update(sanitized);
  }

  @override
  Future<List<String>> uploadImages(List<Uint8List> images, String productId) async {
    final uploadFutures = images.asMap().entries.map((entry) async {
      return await _uploadSingleImage(entry.value, productId, entry.key);
    });

    final results = await Future.wait(uploadFutures);
    return results.whereType<String>().toList();
  }

  @override
  Stream<Set<String>> watchFavorites(String userId) {
    return _firestore.collection(Collections.users).doc(userId).collection(Collections.favorites).snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  Map<String, dynamic> _deepToJsonEncodableMap(Map<String, dynamic> data) {
    final encoded = jsonEncode(data);
    final decoded = jsonDecode(encoded);
    return (decoded as Map).cast<String, dynamic>();
  }

  Map<String, dynamic> _sanitizeProductForFirestore(Map<String, dynamic> rawData, {bool ensureDateCreated = false}) {
    final data = _deepToJsonEncodableMap(rawData);

    // productId is derived from document id; avoid storing a client-controlled field.
    data.remove(Fields.productId);

    // Ensure dateCreated is stored as a Firestore Timestamp (not ISO string)
    if (data.containsKey(Fields.dateCreated) || ensureDateCreated) {
      final dateCreated = data[Fields.dateCreated];
      if (dateCreated is String) {
        try {
          data[Fields.dateCreated] = Timestamp.fromDate(DateTime.parse(dateCreated));
        } catch (_) {
          data[Fields.dateCreated] = Timestamp.now();
        }
      } else if (dateCreated is DateTime) {
        data[Fields.dateCreated] = Timestamp.fromDate(dateCreated);
      } else if (dateCreated == null && ensureDateCreated) {
        data[Fields.dateCreated] = Timestamp.now();
      }
    }

    return data;
  }

  Future<String?> _uploadSingleImage(Uint8List bytes, String productId, int index) async {
    const maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final fileName = "product_${productId}_${index}_${DateTime.now().millisecondsSinceEpoch}.jpg";
        final uploadUrl = await getUploadUrl(fileName);

        if (uploadUrl == null) throw Exception('Could not get upload URL');

        final response = await http.put(Uri.parse(uploadUrl), body: bytes, headers: {"Content-Type": "image/jpeg"}).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          return "${ConfigService().imageBaseUrl}/products/$fileName";
        }
        throw Exception('Upload failed with status ${response.statusCode}');
      } catch (e) {
        if (attempt == maxRetries) return null;
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    return null;
  }
}

class ProductQueryResult {
  final List<Product> products;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  ProductQueryResult({required this.products, this.lastDocument, required this.hasMore});
}

abstract class ProductRepository {
  Future<String> addProduct(Product product);
  Future<void> deleteProduct(String productId);
  Future<Product?> fetchProductById(String productId);
  Future<ProductQueryResult> fetchProducts({String? searchQuery, int? categoryId, DocumentSnapshot? lastDocument, int pageSize = 20});
  Future<List<Product>> fetchProductsByIds(List<String> productIds);
  Future<List<Map<String, dynamic>>> getAutocompleteSuggestions(String query);
  Future<String?> getUploadUrl(String fileName);
  Future<void> submitRating(String orderId, String productId, int rating);
  Future<void> toggleFavorite(String userId, String productId);
  Future<void> updateProduct(String productId, Map<String, dynamic> data);
  Future<List<String>> uploadImages(List<Uint8List> images, String productId);
  Stream<Set<String>> watchFavorites(String userId);
}
