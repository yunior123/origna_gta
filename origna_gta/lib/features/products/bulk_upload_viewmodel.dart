import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/utils/app_logger.dart';
import 'package:origna_gta/utils/csv_parser.dart';

import 'bulk_upload_state.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

/// Riverpod provider for [BulkUploadViewModel].
///
/// Auto-disposed — fresh state per bulk upload session.
final bulkUploadViewModelProvider =
    StateNotifierProvider.autoDispose<BulkUploadViewModel, BulkUploadState>((
      ref,
    ) {
      return BulkUploadViewModel(ref);
    });

/// ViewModel for bulk product upload feature.
///
/// Responsibilities:
/// - Parse CSV content into product maps
/// - Validate parsed products
/// - Upload validated products via OrignaBase SDK
/// - Manage UI state (loading, errors, results)
///
/// ## Key Decisions
/// - CSV parsing is synchronous; upload is async via OrignaBase SDK.
/// - Parse errors are collected per-row — valid rows still proceed.
/// - Upload endpoint: `POST /api/products/bulk` via OrignaBase SDK.
///
/// See also:
/// - [BulkUploadState] for the state shape
class BulkUploadViewModel extends StateNotifier<BulkUploadState> {
  final Ref _ref;

  BulkUploadViewModel(this._ref) : super(const BulkUploadState());

  /// Parses [csvContent] and populates [BulkUploadState.parsedProducts] and [parseErrors].
  ///
  /// Each row is mapped via [mapCsvToBulkProduct]. Rows with mapping errors are
  /// collected as [BulkProductError] with their row index.
  ///
  /// Sets [errorMessage] when the CSV is empty or no valid products are found.
  void parseCsvContent(String csvContent) {
    state = state.copyWith(
      csvContent: csvContent,
      parsedProducts: [],
      parseErrors: [],
      errorMessage: '',
    );

    try {
      // Parse CSV
      final rows = parseCsv(csvContent);

      if (rows.isEmpty) {
        state = state.copyWith(
          errorMessage: 'CSV is empty. Please add at least one product.',
        );
        return;
      }

      // Map CSV rows to products and collect errors
      final products = <Map<String, dynamic>>[];
      final errors = <BulkProductError>[];

      for (var i = 0; i < rows.length; i++) {
        try {
          final product = mapCsvToBulkProduct(rows[i]);
          products.add(product);
        } catch (e) {
          errors.add(
            BulkProductError(
              index: i,
              message: e.toString().replaceFirst('FormatException: ', ''),
            ),
          );
        }
      }

      if (products.isEmpty) {
        state = state.copyWith(
          parseErrors: errors,
          errorMessage: 'No valid products found. Check validation errors.',
          totalCount: rows.length,
        );
        return;
      }

      state = state.copyWith(
        parsedProducts: products,
        parseErrors: errors,
        totalCount: rows.length,
      );
    } catch (e) {
      AppLogger.w('BulkUpload: CSV parsing failed', tag: 'product', error: e);
      state = state.copyWith(
        errorMessage: 'CSV parsing error: ${e.toString()}',
      );
    }
  }

  /// Resets all state to initial values.
  void reset() {
    state = const BulkUploadState();
  }

  /// Generates a CSV template string for the user to download and fill in.
  String generateTemplate() {
    return generateCsvTemplate();
  }

  /// Uploads parsed products to OrignaBase via `POST /api/products/bulk`.
  ///
  /// Requires [BulkUploadState.parsedProducts] to be non-empty.
  /// Sets [isUploading] during the operation; [isSuccess] when all products succeed.
  ///
  /// Gotchas:
  /// - Partial failures are supported — [uploadErrors] lists per-row failures
  ///   while [createdProducts] lists successful ones.
  Future<void> uploadProducts() async {
    final products = state.parsedProducts;

    if (products.isEmpty) {
      state = state.copyWith(
        errorMessage: 'No products to upload. Please parse a valid CSV first.',
      );
      return;
    }

    state = state.copyWith(isUploading: true, errorMessage: '');

    try {
      final sdk = _ref.read(orignabaseProvider);

      // Prepare request payload
      final requestBody = {'products': products};

      // Call bulk upload endpoint via SDK
      final response = await sdk.request(
        'POST',
        ApiEndpoints.productsBulk,
        body: requestBody,
      );

      final failed = (response['failed'] ?? 0) as int;
      final errorsList = (response['errors'] ?? []) as List<dynamic>;
      final productIds = (response['productIds'] ?? []) as List<dynamic>;

      // Build created products list
      final createdList = productIds.asMap().entries.map((e) {
        return CreatedProduct(
          index: e.key,
          productId: (e.value as int).toString(),
          title: products[e.key]['title'].toString(),
        );
      }).toList();

      // Convert error list
      final uploadErrors = errorsList.map((e) {
        final error = e as Map<String, dynamic>;
        return BulkProductError(
          index: error['index'] as int,
          message: error['message'].toString(),
        );
      }).toList();

      state = state.copyWith(
        isUploading: false,
        createdProducts: createdList,
        uploadErrors: uploadErrors,
        isSuccess: failed == 0,
        errorMessage: failed > 0
            ? '$failed products failed to upload. See details below.'
            : '',
      );
    } catch (e) {
      AppLogger.w('BulkUpload: upload failed', tag: 'product', error: e);
      state = state.copyWith(
        isUploading: false,
        errorMessage: 'Upload error: ${e.toString()}',
      );
    }
  }
}
