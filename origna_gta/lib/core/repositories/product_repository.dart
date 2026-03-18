// coverage:ignore-file
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:orignabase/orignabase.dart' show FieldValue;
import 'package:origna_gta/core/compat/timestamp.dart' show truncateNanoseconds;
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart';

/// Shared sanitization for product data before writing to database.
/// Used by both concrete repository implementations.
Map<String, dynamic> sanitizeProductData(Map<String, dynamic> rawData, {bool ensureDateCreated = false}) {
  final data = Map<String, dynamic>.from(rawData);

  // productId is derived from document id; avoid storing a client-controlled field.
  data.remove(Fields.productId);
  // ratingCount and rating are server-managed via rating events; do not allow client write.
  data.remove(Fields.ratingCount);
  data.remove(Fields.rating);
  // sellerId and lifecycleStatus are server-controlled; strip to prevent client overwrite.
  data.remove(Fields.sellerId);
  data.remove(Fields.lifecycleStatus);

  // Server-side validation expects sellerAddress.apartment to be null OR non-empty string.
  // Address model defaults apartment to '', so normalize empty values to null.
  final sellerAddress = data[Fields.sellerAddress];
  if (sellerAddress is Map) {
    final address = Map<String, dynamic>.from(sellerAddress.cast<String, dynamic>());
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
        // SurrealDB may return nanosecond-precision strings; truncate first.
        data[Fields.createdAt] = DateTime.parse(truncateNanoseconds(createdAt)).toIso8601String();
      } catch (_) {
        data[Fields.createdAt] = FieldValue.serverTimestamp();
      }
    } else if (createdAt is DateTime) {
      data[Fields.createdAt] = createdAt.toIso8601String();
    }
  }

  return data;
}

/// Documentation for ProductQueryResult
class ProductQueryResult {
  final List<Product> products;
  final String? lastDocumentId;
  final bool hasMore;

  ProductQueryResult({required this.products, this.lastDocumentId, required this.hasMore});
}

abstract class ProductRepository {
  Future<String> createProductAtomic(Product product, List<Uint8List> imageBytes, {List<String>? testImageUrls, String? bookSourceUrl});
  Future<void> deleteProduct(String productId);
  Future<Product?> fetchProductById(String productId);
  Future<ProductQueryResult> fetchProducts({
    String? searchQuery,
    int? categoryId,
    String? subcategory,
    String? lastDocumentId,
    int pageSize = 20,
    SortOption sortOption = SortOption.relevance,
    int? minPriceCents,
    int? maxPriceCents,
  });
  Future<List<Product>> fetchProductsByIds(List<String> productIds);
  String generateProductId();
  Future<List<Map<String, dynamic>>> getAutocompleteSuggestions(String query);
  Future<Product?> getProductBySlug(String slug);
  Future<String?> getUploadUrl(String fileName);
  Future<Map<String, String>?> getUploadUrlInfo(String fileName);
  Future<Map<String, String>?> getUploadVideoUrlInfo(String fileName, String contentType);
  Future<void> submitRating(String orderId, String productId, int rating, {List<String>? reviewImageUrls, String? reviewText});
  Future<void> submitRatingAtomic(String orderId, String productId, int rating, {List<Uint8List>? reviewImages, String? reviewText});
  Future<void> toggleFavorite(String userId, String productId);
  Future<void> updateProduct(String productId, Map<String, dynamic> data);
  Future<List<String>> uploadImages(List<Uint8List> images, String productId);
  Future<String?> uploadProductVideo(XFile videoFile, String sellerId);
  Future<List<String>> uploadReviewImages(List<Uint8List> images, String userId);
  Stream<Set<String>> watchFavorites(String userId);
  Stream<int> watchUnansweredQuestionsCount(String sellerId);
}
