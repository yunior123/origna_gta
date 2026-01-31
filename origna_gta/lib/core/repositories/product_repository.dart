import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:origna_gta/services/conf_services.dart';
import 'package:origna_gta/utils/utils.dart';

abstract class ProductRepository {
  Future<String> addProduct(ProductModel product);
  Future<void> updateProduct(String productId, Map<String, dynamic> data);
  Future<List<String>> uploadImages(List<Uint8List> images, String productId);
  Future<String?> getUploadUrl(String fileName);
  Future<ProductQueryResult> fetchProducts({
    String? searchQuery,
    int? categoryId,
    DocumentSnapshot? lastDocument,
    int pageSize = 20,
  });
  Future<ProductModel?> fetchProductById(String productId);
  Stream<Set<String>> watchFavorites(String userId);
  Future<void> toggleFavorite(String userId, String productId);
  Future<void> deleteProduct(String productId);
  Future<List<ProductModel>> fetchProductsByIds(List<String> productIds);
  Future<void> submitRating(String orderId, String productId, int rating);
  Future<List<Map<String, dynamic>>> getAutocompleteSuggestions(String query);
}

class ProductQueryResult {
  final List<ProductModel> products;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  ProductQueryResult({required this.products, this.lastDocument, required this.hasMore});
}

class FirebaseProductRepository implements ProductRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  FirebaseProductRepository(this._firestore, this._functions);

  @override
  Future<ProductQueryResult> fetchProducts({
    String? searchQuery,
    int? categoryId,
    DocumentSnapshot? lastDocument,
    int pageSize = 20,
  }) async {
    Query query = _firestore.collection('products');

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.where('searchKeywords', arrayContains: searchQuery.toLowerCase().trim());
    }

    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    query = query.orderBy('dateCreated', descending: true).limit(pageSize);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    final products = snapshot.docs.map((doc) => ProductModel.fromDocument(doc)).toList();
    final hasMore = snapshot.docs.length >= pageSize;

    return ProductQueryResult(
      products: products,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: hasMore,
    );
  }

  @override
  Future<String> addProduct(ProductModel product) async {
    final docRef = await _firestore.collection('products').add(product.toMap());
    return docRef.id;
  }

  @override
  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    await _firestore.collection('products').doc(productId).update(data);
  }

  @override
  Future<String?> getUploadUrl(String fileName) async {
    final result = await _functions.httpsCallable('get_r2_presigned_url').call({'fileName': fileName});
    return result.data['uploadUrl'];
  }

  @override
  Future<ProductModel?> fetchProductById(String productId) async {
    final doc = await _firestore.collection('products').doc(productId).get();
    if (!doc.exists) return null;
    return ProductModel.fromDocument(doc);
  }

  @override
  Stream<Set<String>> watchFavorites(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  @override
  Future<void> toggleFavorite(String userId, String productId) async {
    final favRef = _firestore.collection('users').doc(userId).collection('favorites').doc(productId);
    final doc = await favRef.get();

    if (doc.exists) {
      await favRef.delete();
    } else {
      await favRef.set({
        'productId': productId,
        'dateFavorited': Timestamp.now(),
      });
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _functions.httpsCallable('delete_product').call({'productId': productId});
  }

  @override
  Future<List<String>> uploadImages(List<Uint8List> images, String productId) async {
    final uploadFutures = images.asMap().entries.map((entry) async {
      return await _uploadSingleImage(entry.value, productId, entry.key);
    });

    final results = await Future.wait(uploadFutures);
    return results.whereType<String>().toList();
  }

  Future<String?> _uploadSingleImage(Uint8List bytes, String productId, int index) async {
    const maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final fileName = "product_${productId}_${index}_${DateTime.now().millisecondsSinceEpoch}.jpg";
        final uploadUrl = await getUploadUrl(fileName);
        
        if (uploadUrl == null) throw Exception('Could not get upload URL');

        final response = await http.put(
          Uri.parse(uploadUrl),
          body: bytes,
          headers: {"Content-Type": "image/jpeg"},
        ).timeout(const Duration(seconds: 30));

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

  @override
  Future<List<ProductModel>> fetchProductsByIds(List<String> productIds) async {
    if (productIds.isEmpty) return [];

    final List<ProductModel> results = [];
    // Firestore whereIn has a limit of 30 (previously 10, now 30 in some versions, but let's be safe with 10 or 30)
    // Actually current limit is 30. Let's use 30.
    for (int i = 0; i < productIds.length; i += 30) {
      final chunk = productIds.skip(i).take(30).toList();
      final snapshot = await _firestore.collection('products').where(FieldPath.documentId, whereIn: chunk).get();
      results.addAll(snapshot.docs.map((doc) => ProductModel.fromDocument(doc)));
    }
    return results;
  }

  @override
  Future<void> submitRating(String orderId, String productId, int rating) async {
    await _firestore.runTransaction((transaction) async {
      final productRef = _firestore.collection('products').doc(productId);
      final productDoc = await transaction.get(productRef);

      if (!productDoc.exists) throw Exception('Product not found');

      final productData = productDoc.data()!;
      final currentRating = (productData['rating'] ?? 0.0).toDouble();
      final currentCount = (productData['ratingCount'] ?? 0) as int;

      final newCount = currentCount + 1;
      final newRating = ((currentRating * currentCount) + rating) / newCount;

      transaction.update(productRef, {
        'rating': newRating,
        'ratingCount': newCount,
      });

      final orderRef = _firestore.collection('orders').doc(orderId);
      transaction.update(orderRef, {
        'ratings.$productId': {
          'rating': rating,
          'ratedAt': FieldValue.serverTimestamp(),
        },
      });
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getAutocompleteSuggestions(String query) async {
    final String apiKey = ConfigService().geoapifyKey;
    final response = await http.get(
      Uri.parse('https://api.geoapify.com/v1/geocode/autocomplete?text=$query&filter=countrycode:ca&apiKey=$apiKey'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['features'] ?? []);
    }
    return [];
  }
}
