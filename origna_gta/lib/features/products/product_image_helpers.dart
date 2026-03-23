import 'package:flutter/foundation.dart';
import 'package:origna_gta/utils/image_compression_utils.dart';
import 'package:origna_gta/utils/utils.dart';

/// Shared image compression for Add/Edit product ViewModels.
///
/// Compresses images in parallel using [Future.wait] + [compute] isolates,
/// NOT sequential for-loops. Each image is validated (size, format) then
/// resized to max 2048px and encoded as JPEG 85%.
///
/// Returns only successfully compressed images — failed ones are silently skipped.
///
/// Usage:
/// ```dart
/// final compressed = await compressProductImages(state.imageModels);
/// ```
Future<List<Uint8List>> compressProductImages(
  List<ImageModel> imageModels,
) async {
  if (imageModels.isEmpty) return [];

  final futures = imageModels.map((m) async {
    try {
      return await validateAndCompressImage(m.bytes);
    } catch (_) {
      return null;
    }
  });

  final results = await Future.wait(futures);
  return results.whereType<Uint8List>().toList();
}
