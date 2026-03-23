import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

const int _maxDimension = 2048;
const int maxImageSize = 10 * 1024 * 1024; // 10MB — matches backend limit

Uint8List? compressImageIsolate(Uint8List bytes) {
  if (bytes.isEmpty) return null;
  final image = img.decodeImage(bytes);
  if (image == null) return null;
  img.Image resized = image;
  if (image.width > _maxDimension || image.height > _maxDimension) {
    resized = img.copyResize(
      image,
      width: image.width > image.height ? _maxDimension : null,
      height: image.height > image.width ? _maxDimension : null,
    );
  }
  return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
}

Future<Uint8List?> validateAndCompressImage(Uint8List bytes) async {
  if (bytes.length > maxImageSize) {
    throw Exception('product.image_too_large'.tr());
  }
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw Exception('product.image_invalid_format'.tr());
  }
  return compute(compressImageIsolate, bytes);
}
