import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/utils/media_url_resolver.dart';

void main() {
  group('resolveMediaUrl', () {
    test('maps relative R2 product paths to the public HTTPS bucket', () {
      expect(
        resolveMediaUrl('dev/products/solar/image-1.jpg'),
        'https://pub-f9698d0f50d146bcac0e2dc9eb09de57.r2.dev/dev/products/solar/image-1.jpg',
      );
    });

    test('maps slash-prefixed storage paths to the public HTTPS bucket', () {
      expect(
        resolveMediaUrl('/dev/products/solar/image-2.jpg'),
        'https://pub-f9698d0f50d146bcac0e2dc9eb09de57.r2.dev/dev/products/solar/image-2.jpg',
      );
    });

    test('preserves fully-qualified HTTPS URLs', () {
      expect(
        resolveMediaUrl('https://cdn.example.com/products/image-3.jpg'),
        'https://cdn.example.com/products/image-3.jpg',
      );
    });
  });
}
