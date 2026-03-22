import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/repositories/product_image_helpers.dart';

void main() {
  group('ProductImageHelpers.detectImageMimeType', () {
    test('returns image/jpeg for bytes shorter than 4', () {
      final bytes = Uint8List.fromList([0x89, 0x50]);
      expect(ProductImageHelpers.detectImageMimeType(bytes), 'image/jpeg');
    });

    test('returns image/jpeg for empty bytes', () {
      final bytes = Uint8List(0);
      expect(ProductImageHelpers.detectImageMimeType(bytes), 'image/jpeg');
    });

    test('returns image/png for PNG magic bytes', () {
      final bytes = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
      ]);
      expect(ProductImageHelpers.detectImageMimeType(bytes), 'image/png');
    });

    test('returns image/jpeg for JPEG magic bytes', () {
      final bytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);
      expect(ProductImageHelpers.detectImageMimeType(bytes), 'image/jpeg');
    });

    test('returns image/webp for WEBP magic bytes', () {
      final bytes = Uint8List.fromList([
        0x52,
        0x49,
        0x46,
        0x46,
        0x00,
        0x00,
        0x00,
        0x00,
        0x57,
        0x45,
        0x42,
        0x50,
        0x00,
        0x00,
      ]);
      expect(ProductImageHelpers.detectImageMimeType(bytes), 'image/webp');
    });

    test('returns image/gif for GIF87a magic bytes', () {
      final bytes = Uint8List.fromList([0x47, 0x49, 0x46, 0x38, 0x37, 0x61]);
      expect(ProductImageHelpers.detectImageMimeType(bytes), 'image/gif');
    });

    test('returns image/gif for GIF89a magic bytes', () {
      final bytes = Uint8List.fromList([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]);
      expect(ProductImageHelpers.detectImageMimeType(bytes), 'image/gif');
    });

    test('returns image/jpeg for unrecognized bytes', () {
      final bytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
      expect(ProductImageHelpers.detectImageMimeType(bytes), 'image/jpeg');
    });

    test('returns image/jpeg for 3-byte input', () {
      final bytes = Uint8List.fromList([0x89, 0x50, 0x4E]);
      expect(ProductImageHelpers.detectImageMimeType(bytes), 'image/jpeg');
    });

    test('WEBP detection requires at least 12 bytes', () {
      final bytes = Uint8List.fromList([
        0x52,
        0x49,
        0x46,
        0x46,
        0x00,
        0x00,
        0x00,
        0x00,
        0x57,
        0x45,
        0x42,
      ]);
      expect(
        ProductImageHelpers.detectImageMimeType(bytes),
        isNot('image/webp'),
      );
    });

    test('JPEG takes precedence when bytes start with FF D8', () {
      final bytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xDB]);
      expect(ProductImageHelpers.detectImageMimeType(bytes), 'image/jpeg');
    });

    test('returns image/jpeg for single byte input', () {
      final bytes = Uint8List.fromList([0xFF]);
      expect(ProductImageHelpers.detectImageMimeType(bytes), 'image/jpeg');
    });

    test('returns image/jpeg for 2-byte input', () {
      final bytes = Uint8List.fromList([0xFF, 0xD8]);
      expect(ProductImageHelpers.detectImageMimeType(bytes), 'image/jpeg');
    });

    test('PNG detection works with exactly 4 bytes', () {
      final bytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);
      expect(ProductImageHelpers.detectImageMimeType(bytes), 'image/png');
    });

    test('JPEG detection works with exactly 4 bytes', () {
      final bytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
      expect(ProductImageHelpers.detectImageMimeType(bytes), 'image/jpeg');
    });

    test('GIF detection works with exactly 4 bytes', () {
      final bytes = Uint8List.fromList([0x47, 0x49, 0x46, 0x38]);
      expect(ProductImageHelpers.detectImageMimeType(bytes), 'image/gif');
    });

    test('WEBP with valid RIFF but wrong WEBP signature returns jpeg', () {
      final bytes = Uint8List.fromList([
        0x52,
        0x49,
        0x46,
        0x46,
        0x00,
        0x00,
        0x00,
        0x00,
        0x57,
        0x45,
        0x42,
        0x41,
      ]);
      expect(ProductImageHelpers.detectImageMimeType(bytes), 'image/jpeg');
    });

    test('returns jpeg for bytes starting with null bytes', () {
      final bytes = Uint8List.fromList([0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
      expect(ProductImageHelpers.detectImageMimeType(bytes), 'image/jpeg');
    });

    test('handles large byte arrays correctly', () {
      final bytes = Uint8List(10000);
      bytes[0] = 0x89;
      bytes[1] = 0x50;
      bytes[2] = 0x4E;
      bytes[3] = 0x47;
      expect(ProductImageHelpers.detectImageMimeType(bytes), 'image/png');
    });

    test('WEBP with exactly 12 bytes', () {
      final bytes = Uint8List.fromList([
        0x52,
        0x49,
        0x46,
        0x46,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x57,
        0x45,
        0x42,
        0x50,
      ]);
      expect(ProductImageHelpers.detectImageMimeType(bytes), 'image/webp');
    });

    test('detection order: PNG checked before WEBP', () {
      final pngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);
      expect(ProductImageHelpers.detectImageMimeType(pngBytes), 'image/png');
    });

    test('case where PNG magic bytes appear after other bytes', () {
      final bytes = Uint8List.fromList([0x00, 0x89, 0x50, 0x4E, 0x47]);
      expect(ProductImageHelpers.detectImageMimeType(bytes), 'image/jpeg');
    });
  });
}
