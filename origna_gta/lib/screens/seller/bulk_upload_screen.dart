import 'dart:html' as html;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/features/products/bulk_upload_viewmodel.dart';
import 'package:origna_gta/utils/design_tokens.dart';

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
  const BulkUploadScreen({Key? key}) : super(key: key);

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
            minHeight: MediaQuery.of(context).size.height,
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
                        color: DesignTokens.lightText,
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
                      color: const Color(0xFF5C2C2C),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE74C3C)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Color(0xFFE74C3C)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.errorMessage,
                            style: const TextStyle(
                              color: Color(0xFFE74C3C),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (state.errorMessage.isNotEmpty)
                  const SizedBox(height: 24),

                // Parse errors table
                if (state.parseErrors.isNotEmpty) ...[
                  Text(
                    'parse_errors'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFFE74C3C),
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
                        '${state.totalCount}'
                      ],
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: DesignTokens.lightText,
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
                              Color(0xFF667EEA),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'uploading'.tr(),
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: DesignTokens.lightText,
                                    ),
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
                          backgroundColor: const Color(0xFF27AE60),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text('upload_all'.tr(
                          args: ['${state.parsedProducts.length}'],
                        )),
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
    final input = html.FileUploadInputElement()
      ..accept = '.csv'
      ..click();

    input.onChange.listen((e) async {
      final files = input.files;
      if (files?.isNotEmpty ?? false) {
        final file = files![0];
        final reader = html.FileReader();
        reader.readAsText(file);

        reader.onLoadEnd.listen((_) {
          final content = reader.result as String;
          viewModel.parseCsvContent(content);
        });
      }
    });
  }

  /// Download file (web: trigger download).
  void _downloadFile(String filename, String content) {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final link = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  /// Build errors table.
  Widget _buildErrorsTable(
    List<BulkProductError> errors,
    BuildContext context,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Row')),
          DataColumn(label: Text('Error')),
        ],
        rows: errors.take(10).map((e) {
          return DataRow(cells: [
            DataCell(Text('${e.index + 1}')),
            DataCell(Text(e.message)),
          ]);
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
        columns: keys
            .map((k) => DataColumn(label: Text(k)))
            .toList(),
        rows: previewProducts
            .map((product) => DataRow(
                  cells: keys
                      .map((k) => DataCell(
                            Text(
                              (product[k] ?? '').toString(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                ))
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
            color: const Color(0xFF2C5C2C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF27AE60)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF27AE60)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'upload_complete'.tr(
                    args: ['${state.createdProducts.length}'],
                  ),
                  style: const TextStyle(
                    color: Color(0xFF27AE60),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFFE74C3C),
              ),
        ),
        const SizedBox(height: 12),
        _buildErrorsTable(state.uploadErrors, context),
      ],
    );
  }
}

extension on List {
  List<E> take<E>(int count) => cast<E>().take(count).toList();
}
