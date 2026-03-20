import 'package:freezed_annotation/freezed_annotation.dart';

part 'bulk_upload_state.freezed.dart';

/// Represents a validation error for a single product in the bulk upload.
@freezed
abstract class BulkProductError with _$BulkProductError {
  const factory BulkProductError({
    required int index,
    required String message,
  }) = _BulkProductError;
}

/// Represents a successfully created product.
@freezed
abstract class CreatedProduct with _$CreatedProduct {
  const factory CreatedProduct({
    required int index,
    required String productId,
    required String title,
  }) = _CreatedProduct;
}

/// State for the bulk upload feature.
@freezed
abstract class BulkUploadState with _$BulkUploadState {
  const factory BulkUploadState({
    /// CSV content (raw text)
    @Default('') String csvContent,

    /// Parsed products (`List<Map<String, dynamic>>`)
    @Default([]) List<Map<String, dynamic>> parsedProducts,

    /// Validation errors from CSV parsing
    @Default([]) List<BulkProductError> parseErrors,

    /// Whether currently uploading to backend
    @Default(false) bool isUploading,

    /// Products successfully created
    @Default([]) List<CreatedProduct> createdProducts,

    /// Errors from bulk API call
    @Default([]) List<BulkProductError> uploadErrors,

    /// Error message (general)
    @Default('') String errorMessage,

    /// Success indicator
    @Default(false) bool isSuccess,

    /// Total product count attempted
    @Default(0) int totalCount,
  }) = _BulkUploadState;
}
