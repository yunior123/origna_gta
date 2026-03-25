import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:orignabase/orignabase.dart' show FieldValue;
import 'package:origna_gta/core/compat/timestamp.dart' show truncateNanoseconds;
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart';

/// Shared sanitization for product data before writing to database.
/// Used by both concrete repository implementations.
Map<String, dynamic> sanitizeProductData(
  Map<String, dynamic> rawData, {
  bool ensureDateCreated = false,
}) {
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
        // SurrealDB may return nanosecond-precision strings; truncate first.
        data[Fields.createdAt] = DateTime.parse(
          truncateNanoseconds(createdAt),
        ).toIso8601String();
      } catch (_) {
        data[Fields.createdAt] = FieldValue.serverTimestamp();
      }
    } else if (createdAt is DateTime) {
      data[Fields.createdAt] = createdAt.toIso8601String();
    }
  }

  return data;
}

/// Paginated result from a product search or listing query.
///
/// [lastDocumentId] is used as cursor for the next page.
/// [hasMore] indicates whether more results exist beyond the current page.
class ProductQueryResult {
  final List<Product> products;
  final String? lastDocumentId;
  final bool hasMore;

  ProductQueryResult({
    required this.products,
    this.lastDocumentId,
    required this.hasMore,
  });
}

/// Contract for product operations: CRUD, search, ratings, favorites, uploads.
///
/// Implementations: [OrignaBaseProductRepository] (production).
///
/// Search/query logic is delegated to [ProductSearchHelpers].
/// Image upload logic is delegated to [ProductImageHelpers].
abstract class ProductRepository {
  /// Creates a product and uploads images in one flow. Returns the new product ID.
  ///
  /// Server-side: validates seller role, sets lifecycleStatus to draft,
  /// assigns sellerId from JWT. [testImageUrls] bypasses upload in tests.
  Future<String> createProductAtomic(
    Product product,
    List<Uint8List> imageBytes, {
    List<String>? testImageUrls,
    String? bookSourceUrl,
  });

  /// Soft-deletes a product (sets lifecycleStatus to 'deleted').
  /// Only the product's seller or an admin can delete.
  Future<void> deleteProduct(String productId);

  /// Fetches a single product by its SurrealDB document ID. Returns null if not found.
  Future<Product?> fetchProductById(String productId);

  /// Searches/lists products with optional filters and pagination.
  ///
  /// Uses Meilisearch for keyword search, falls back to SurrealDB for
  /// category/price filtering when no search query is provided.
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

  /// Batch-fetches products by IDs. Used by favorites and cart detail providers.
  Future<List<Product>> fetchProductsByIds(List<String> productIds);

  /// Generates a unique, time-based product ID (Base36 encoded).
  String generateProductId();

  /// Returns geocode autocomplete suggestions for address input (Canadian addresses).
  Future<List<Map<String, dynamic>>> getAutocompleteSuggestions(String query);

  /// Fetches a product by its URL-friendly slug. Returns null if not found.
  Future<Product?> getProductBySlug(String slug);

  /// Gets a presigned upload URL for a product image. Returns just the URL string.
  Future<String?> getUploadUrl(String fileName);

  /// Gets upload URL info including both uploadUrl and publicUrl for images.
  Future<Map<String, String>?> getUploadUrlInfo(String fileName);

  /// Gets upload URL info for video files with the specified content type.
  Future<Map<String, String>?> getUploadVideoUrlInfo(
    String fileName,
    String contentType,
  );

  /// Submits a product rating/review with pre-uploaded image URLs.
  ///
  /// [rating] is 1-5 stars. One rating per (orderId, productId, userId) combination.
  Future<void> submitRating(
    String orderId,
    String productId,
    int rating, {
    List<String>? reviewImageUrls,
    String? reviewText,
  });

  /// Submits a product rating and uploads review images in one atomic flow.
  Future<void> submitRatingAtomic(
    String orderId,
    String productId,
    int rating, {
    List<Uint8List>? reviewImages,
    String? reviewText,
  });

  /// Toggles a product in the user's favorites set (add or remove).
  Future<void> toggleFavorite(String userId, String productId);

  /// Updates a product's fields. Server-side validates seller ownership.
  Future<void> updateProduct(String productId, Map<String, dynamic> data);

  /// Uploads product images to Cloudflare R2 via presigned URLs. Returns public URLs.
  Future<List<String>> uploadImages(List<Uint8List> images, String productId);

  /// Uploads a product video to Cloudflare R2. Returns the public URL.
  Future<String?> uploadProductVideo(XFile videoFile, String sellerId);

  /// Uploads review images to Cloudflare R2. Returns public URLs.
  Future<List<String>> uploadReviewImages(
    List<Uint8List> images,
    String userId,
  );

  /// Real-time stream of the user's favorite product IDs.
  ///
  /// Uses OrignaBase realtime subscriptions for instant updates.
  Stream<Set<String>> watchFavorites(
    String userId, {
    int limit = 50,
    int offset = 0,
  });

  /// Polls for unanswered Q&A questions on the seller's products (10s interval).
  Stream<int> watchUnansweredQuestionsCount(String sellerId);
}
