// coverage:ignore-file
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/csv_parser.dart';

import 'bulk_upload_state.dart';

final bulkUploadViewModelProvider =
    StateNotifierProvider.autoDispose<BulkUploadViewModel, BulkUploadState>(
        (ref) {
  return BulkUploadViewModel(ref);
});

/// ViewModel for bulk product upload feature.
/// 
/// Responsibilities:
/// - Parse CSV content into product maps
/// - Validate parsed products
/// - Upload validated products via OrignaBase SDK
/// - Manage UI state (loading, errors, results)
class BulkUploadViewModel extends StateNotifier<BulkUploadState> {
  final Ref _ref;

  BulkUploadViewModel(this._ref) : super(const BulkUploadState());

  /// Set CSV content and parse it.
  /// Validates each row and collects errors.
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
          errors.add(BulkProductError(
            index: i,
            message: e.toString().replaceFirst('FormatException: ', ''),
          ));
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
      state = state.copyWith(
        errorMessage: 'CSV parsing error: ${e.toString()}',
      );
    }
  }

  /// Clear all state.
  void reset() {
    state = const BulkUploadState();
  }

  /// Generate a CSV template for download.
  String generateTemplate() {
    return generateCsvTemplate();
  }

  /// Upload parsed products to OrignaBase.
  /// Uses the OrignaBase SDK to call POST /api/products/bulk.
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
      final requestBody = {
        'products': products,
      };

      // Call bulk upload endpoint via SDK
      final response = await sdk.call(
        method: 'POST',
        path: '/api/products/bulk',
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        state = state.copyWith(
          isUploading: false,
          errorMessage:
              'Upload failed: ${response.statusCode} ${response.reasonPhrase}',
        );
        return;
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final created = (jsonResponse['created'] ?? 0) as int;
      final failed = (jsonResponse['failed'] ?? 0) as int;
      final errorsList = (jsonResponse['errors'] ?? []) as List<dynamic>;
      final productIds = (jsonResponse['productIds'] ?? []) as List<dynamic>;

      // Build created products list
      final createdList = productIds.asMap().entries.map((e) {
        return CreatedProduct(
          index: e.key,
          productId: e.value.toString(),
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
      state = state.copyWith(
        isUploading: false,
        errorMessage: 'Upload error: ${e.toString()}',
      );
    }
  }
}
