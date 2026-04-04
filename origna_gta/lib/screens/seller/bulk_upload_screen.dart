import 'dart:convert';
import 'dart:js_interop';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/features/products/bulk_upload_state.dart';
import 'package:origna_gta/features/products/bulk_upload_viewmodel.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:web/web.dart' as web;

/// Bulk product upload screen.
///
/// Allows sellers to upload multiple products via CSV file.
/// Features:
/// - CSV file picker
/// - Product preview (first 10 rows)
/// - Validation error display
/// - Bulk upload with progress
/// - Results summary
class BulkUploadScreen extends ConsumerStatefulWidget {
  const BulkUploadScreen({super.key});

  @override
  ConsumerState<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends ConsumerState<BulkUploadScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bulkUploadViewModelProvider);
    final viewModel = ref.read(bulkUploadViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: DesignTokens.darkBackground,
      appBar: AppBar(
        backgroundColor: DesignTokens.darkCard,
        title: Text('bulk_upload_title'.tr()),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 1200,
            minHeight: MediaQuery.sizeOf(context).height,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instructions
                Text(
                  'bulk_upload_instructions'.tr(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: DesignTokens.textOnDark,
                  ),
                ),
                const SizedBox(height: 24),

                // Download template button
                Semantics(
                  label: 'btn-download-template',
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final csv = viewModel.generateTemplate();
                      _downloadFile('bulk_upload_template.csv', csv);
                    },
                    icon: const Icon(Icons.download),
                    label: Text('download_template'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // File picker
                Semantics(
                  label: 'btn-select-csv',
                  child: ElevatedButton.icon(
                    onPressed: () => _pickCsvFile(viewModel),
                    icon: const Icon(Icons.upload_file),
                    label: Text('select_csv_file'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Error message
                if (state.errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DesignTokens.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: DesignTokens.error),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: DesignTokens.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.errorMessage,
                            style: const TextStyle(
                              color: DesignTokens.error,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (state.errorMessage.isNotEmpty) const SizedBox(height: 24),

                // Parse errors table
                if (state.parseErrors.isNotEmpty) ...[
                  Text(
                    'parse_errors'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: DesignTokens.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildErrorsTable(state.parseErrors, context),
                  const SizedBox(height: 24),
                ],

                // Preview table
                if (state.parsedProducts.isNotEmpty) ...[
                  Text(
                    'preview'.tr(
                      args: [
                        '${state.parsedProducts.length}',
                        '${state.totalCount}',
                      ],
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: DesignTokens.textOnDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPreviewTable(state.parsedProducts, context),
                  const SizedBox(height: 24),
                ],

                // Upload button & results
                if (state.parsedProducts.isNotEmpty)
                  if (state.isUploading)
                    Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              DesignTokens.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'uploading'.tr(),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: DesignTokens.textOnDark),
                          ),
                        ],
                      ),
                    )
                  else if (state.isSuccess)
                    _buildSuccessResults(state, context)
                  else if (state.uploadErrors.isEmpty)
                    Semantics(
                      label: 'btn-upload-all',
                      child: ElevatedButton(
                        onPressed: () => viewModel.uploadProducts(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.success,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'upload_all'.tr(
                            args: ['${state.parsedProducts.length}'],
                          ),
                        ),
                      ),
                    )
                  else
                    _buildErrorResults(state, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Pick CSV file from file system (web: file input).
  Future<void> _pickCsvFile(BulkUploadViewModel viewModel) async {
    // On web, use HTML file input
    final input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = '.csv'
      ..click();

    input.onChange.listen((e) async {
      final files = input.files;
      if (files != null && files.length > 0) {
        final file = files.item(0)!;
        final reader = web.FileReader();
        reader.readAsText(file);

        reader.onLoadEnd.listen((_) {
          final content = (reader.result as JSString).toDart;
          viewModel.parseCsvContent(content);
        });
      }
    });
  }

  /// Download file (web: trigger download).
  void _downloadFile(String filename, String content) {
    final bytes = utf8.encode(content);
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'text/csv'),
    );
    final url = web.URL.createObjectURL(blob);
    web.HTMLAnchorElement()
      ..href = url
      ..download = filename
      ..click();
    web.URL.revokeObjectURL(url);
  }

  /// Build errors table.
  Widget _buildErrorsTable(
    List<BulkProductError> errors,
    BuildContext context,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('upload_row'.tr())),
          DataColumn(label: Text('upload_error'.tr())),
        ],
        rows: errors.take(10).map((error) {
          return DataRow(
            cells: [
              DataCell(Text('${error.index + 1}')),
              DataCell(Text(error.message)),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Build preview table (first 10 rows).
  Widget _buildPreviewTable(
    List<Map<String, dynamic>> products,
    BuildContext context,
  ) {
    if (products.isEmpty) return const SizedBox.shrink();

    final previewProducts = products.take(10).toList();
    final allKeys = <String>{};
    for (final product in previewProducts) {
      allKeys.addAll(product.keys);
    }
    final keys = allKeys.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: keys.map((k) => DataColumn(label: Text(k))).toList(),
        rows: previewProducts
            .map(
              (product) => DataRow(
                cells: keys
                    .map(
                      (k) => DataCell(
                        Text(
                          (product[k] ?? '').toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
              ),
            )
            .toList(),
      ),
    );
  }

  /// Build success results section.
  Widget _buildSuccessResults(BulkUploadState state, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DesignTokens.success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DesignTokens.success),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: DesignTokens.success),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'upload_complete'.tr(
                    args: ['${state.createdProducts.length}'],
                  ),
                  style: const TextStyle(
                    color: DesignTokens.success,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          label: 'btn-view-products',
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.sellerProducts);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primary,
            ),
            child: Text('view_products'.tr()),
          ),
        ),
      ],
    );
  }

  /// Build error results section.
  Widget _buildErrorResults(BulkUploadState state, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'upload_errors'.tr(),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: DesignTokens.error),
        ),
        const SizedBox(height: 12),
        _buildErrorsTable(state.uploadErrors, context),
      ],
    );
  }
}

@Preview(
  name: 'Bulk Upload — Mobile',
  group: 'BulkUpload',
  size: Size(390, 844),
)
Widget previewBulkUploadMobile() =>
    previewMobile(child: const BulkUploadScreen());

@Preview(
  name: 'Bulk Upload — Tablet',
  group: 'BulkUpload',
  size: Size(768, 1024),
)
Widget previewBulkUploadTablet() =>
    previewTablet(child: const BulkUploadScreen());

@Preview(
  name: 'Bulk Upload — Desktop',
  group: 'BulkUpload',
  size: Size(1280, 800),
)
Widget previewBulkUploadDesktop() =>
    previewDesktop(child: const BulkUploadScreen());
