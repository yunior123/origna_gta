import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/repositories/product_image_helpers.dart';

@GenerateNiceMocks([MockSpec<OrignaBase>(), MockSpec<http.Client>()])
import 'product_image_helpers_test.mocks.dart';

class _TestImageHelpers with ProductImageHelpers {
  @override
  final OrignaBase ob;

  @override
  final http.Client httpClient;

  _TestImageHelpers({required this.ob, required this.httpClient});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockOrignaBase mockOb;
  late MockClient mockHttpClient;

  setUp(() {
    mockOb = MockOrignaBase();
    mockHttpClient = MockClient();
  });

  _TestImageHelpers createHelper() =>
      _TestImageHelpers(ob: mockOb, httpClient: mockHttpClient);

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

  group('ProductImageHelpers.getUploadUrlInfoImpl', () {
    test('returns upload URL info on success', () async {
      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => {
          'urls': [
            {
              'upload_url': 'https://upload.example.com/file.jpg',
              'path': 'products/file.jpg',
            },
          ],
        },
      );

      final helper = createHelper();
      final result = await helper.getUploadUrlInfoImpl('test.jpg');

      expect(result, isNotNull);
      expect(result!['uploadUrl'], 'https://upload.example.com/file.jpg');
      expect(result['publicUrl'], 'products/file.jpg');
    });

    test('returns null when urls list is empty', () async {
      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => {'urls': []});

      final helper = createHelper();
      final result = await helper.getUploadUrlInfoImpl('test.jpg');

      expect(result, isNull);
    });

    test('returns null when response is empty', () async {
      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{});

      final helper = createHelper();
      final result = await helper.getUploadUrlInfoImpl('test.jpg');

      expect(result, isNull);
    });

    test('returns null when response has no urls key', () async {
      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => {'other': 'data'});

      final helper = createHelper();
      final result = await helper.getUploadUrlInfoImpl('test.jpg');

      expect(result, isNull);
    });

    test('handles malformed urls data gracefully', () async {
      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => {'urls': 'not_a_list'});

      final helper = createHelper();
      await expectLater(
        () => helper.getUploadUrlInfoImpl('test.jpg'),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('ProductImageHelpers.getUploadVideoUrlInfoImpl', () {
    test('returns video upload URL info on success', () async {
      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => {
          'urls': [
            {
              'upload_url': 'https://upload.example.com/video.mp4',
              'path': 'products/videos/video.mp4',
            },
          ],
        },
      );

      final helper = createHelper();
      final result = await helper.getUploadVideoUrlInfoImpl(
        'video.mp4',
        'video/mp4',
      );

      expect(result, isNotNull);
      expect(result!['uploadUrl'], 'https://upload.example.com/video.mp4');
      expect(result['publicUrl'], 'products/videos/video.mp4');
    });

    test('returns null when urls list is empty', () async {
      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => {'urls': []});

      final helper = createHelper();
      final result = await helper.getUploadVideoUrlInfoImpl(
        'video.mp4',
        'video/mp4',
      );

      expect(result, isNull);
    });

    test('returns null when response is empty', () async {
      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{});

      final helper = createHelper();
      final result = await helper.getUploadVideoUrlInfoImpl(
        'video.mp4',
        'video/mp4',
      );

      expect(result, isNull);
    });
  });

  group('ProductImageHelpers.uploadImagesImpl', () {
    test('uploads multiple images successfully', () async {
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);

      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => {
          'urls': [
            {
              'upload_url': 'https://upload.example.com/img1.jpg',
              'path': 'products/img1.jpg',
            },
          ],
        },
      );

      when(
        mockHttpClient.put(
          any,
          body: anyNamed('body'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response('', 200));

      final helper = createHelper();
      final results = await helper.uploadImagesImpl([jpegBytes], 'prod_1');

      expect(results.length, 1);
    });

    test('throws exception on partial upload failure', () async {
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);

      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => {
          'urls': [
            {
              'upload_url': 'https://upload.example.com/img1.jpg',
              'path': 'products/img1.jpg',
            },
          ],
        },
      );

      when(
        mockHttpClient.put(
          any,
          body: anyNamed('body'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response('Error', 500));

      when(
        mockOb.request('POST', '/storage/batch-delete', body: anyNamed('body')),
      ).thenAnswer((_) async => {'deleted': true});

      final helper = createHelper();

      await expectLater(
        () => helper.uploadImagesImpl([jpegBytes, jpegBytes], 'prod_1'),
        throwsA(isA<Exception>()),
      );
    });

    test('cleans up successfully uploaded images on failure', () async {
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);

      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => {
          'urls': [
            {
              'upload_url': 'https://upload.example.com/img.jpg',
              'path': 'products/img.jpg',
            },
          ],
        },
      );

      var uploadCallCount = 0;
      when(
        mockHttpClient.put(
          any,
          body: anyNamed('body'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async {
        uploadCallCount++;
        if (uploadCallCount == 1) {
          return http.Response('', 200);
        }
        return http.Response('Error', 500);
      });

      when(
        mockOb.request('POST', '/storage/batch-delete', body: anyNamed('body')),
      ).thenAnswer((_) async => {'deleted': true});

      final helper = createHelper();

      await expectLater(
        () => helper.uploadImagesImpl([jpegBytes, jpegBytes], 'prod_1'),
        throwsA(isA<Exception>()),
      );

      verify(
        mockOb.request('POST', '/storage/batch-delete', body: anyNamed('body')),
      ).called(1);
    });

    test('handles empty image list', () async {
      final helper = createHelper();
      final results = await helper.uploadImagesImpl([], 'prod_1');

      expect(results, isEmpty);
    });

    test('continues cleanup even if batch-delete fails', () async {
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);

      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => {
          'urls': [
            {
              'upload_url': 'https://upload.example.com/img.jpg',
              'path': 'products/img.jpg',
            },
          ],
        },
      );

      var uploadCallCount = 0;
      when(
        mockHttpClient.put(
          any,
          body: anyNamed('body'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async {
        uploadCallCount++;
        if (uploadCallCount == 1) {
          return http.Response('', 200);
        }
        return http.Response('Error', 500);
      });

      when(
        mockOb.request('POST', '/storage/batch-delete', body: anyNamed('body')),
      ).thenThrow(Exception('Cleanup failed'));

      final helper = createHelper();

      await expectLater(
        () => helper.uploadImagesImpl([jpegBytes, jpegBytes], 'prod_1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ProductImageHelpers.uploadReviewImagesImpl', () {
    test('returns empty list for empty input', () async {
      final helper = createHelper();
      final results = await helper.uploadReviewImagesImpl([], 'user_1');

      expect(results, isEmpty);
    });

    test('uploads review images successfully', () async {
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);

      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => {
          'urls': [
            {
              'upload_url': 'https://upload.example.com/review1.jpg',
              'path': 'reviews/user_1/img_0_123.jpg',
            },
          ],
        },
      );

      when(
        mockHttpClient.put(
          any,
          body: anyNamed('body'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response('', 200));

      final helper = createHelper();
      final results = await helper.uploadReviewImagesImpl([
        jpegBytes,
      ], 'user_1');

      expect(results.length, 1);
      expect(results.first, 'reviews/user_1/img_0_123.jpg');
    });

    test('filters out failed uploads', () async {
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);

      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => {
          'urls': [
            {
              'upload_url': 'https://upload.example.com/review1.jpg',
              'path': 'reviews/user_1/img_0_123.jpg',
            },
            {
              'upload_url': 'https://upload.example.com/review2.jpg',
              'path': 'reviews/user_1/img_1_123.jpg',
            },
          ],
        },
      );

      var putCallCount = 0;
      when(
        mockHttpClient.put(
          any,
          body: anyNamed('body'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async {
        putCallCount++;
        if (putCallCount == 1) {
          return http.Response('', 200);
        }
        return http.Response('Error', 500);
      });

      final helper = createHelper();
      final results = await helper.uploadReviewImagesImpl([
        jpegBytes,
        jpegBytes,
      ], 'user_1');

      expect(results.length, 1);
    });

    test('handles upload exception gracefully', () async {
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);

      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => {
          'urls': [
            {
              'upload_url': 'https://upload.example.com/review.jpg',
              'path': 'reviews/user_1/img_0_123.jpg',
            },
          ],
        },
      );

      when(
        mockHttpClient.put(
          any,
          body: anyNamed('body'),
          headers: anyNamed('headers'),
        ),
      ).thenThrow(Exception('Network error'));

      final helper = createHelper();
      final results = await helper.uploadReviewImagesImpl([
        jpegBytes,
      ], 'user_1');

      expect(results, isEmpty);
    });

    test('returns empty list when no urls in response', () async {
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);

      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => {'urls': []});

      final helper = createHelper();
      final results = await helper.uploadReviewImagesImpl([
        jpegBytes,
      ], 'user_1');

      expect(results, isEmpty);
    });

    test('uses correct Content-Type header for review images', () async {
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);

      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => {
          'urls': [
            {
              'upload_url': 'https://upload.example.com/review.jpg',
              'path': 'reviews/user_1/img.jpg',
            },
          ],
        },
      );

      when(
        mockHttpClient.put(
          any,
          body: anyNamed('body'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response('', 200));

      final helper = createHelper();
      await helper.uploadReviewImagesImpl([jpegBytes], 'user_1');

      verify(
        mockHttpClient.put(
          any,
          body: anyNamed('body'),
          headers: {'Content-Type': 'image/jpeg'},
        ),
      ).called(1);
    });
  });

  group('ProductImageHelpers.uploadSingleImage', () {
    test('uploads single image successfully on first attempt', () async {
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);

      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => {
          'urls': [
            {
              'upload_url': 'https://upload.example.com/img.jpg',
              'path': 'products/img.jpg',
            },
          ],
        },
      );

      when(
        mockHttpClient.put(
          any,
          body: anyNamed('body'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response('', 200));

      final helper = createHelper();
      final result = await helper.uploadSingleImage(jpegBytes, 'prod_1', 0);

      expect(result, 'products/img.jpg');
    });

    test('retries on transient failure and succeeds', () async {
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);

      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => {
          'urls': [
            {
              'upload_url': 'https://upload.example.com/img.jpg',
              'path': 'products/img.jpg',
            },
          ],
        },
      );

      var putCallCount = 0;
      when(
        mockHttpClient.put(
          any,
          body: anyNamed('body'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async {
        putCallCount++;
        if (putCallCount < 3) {
          throw Exception('Network error');
        }
        return http.Response('', 200);
      });

      final helper = createHelper();
      final result = await helper.uploadSingleImage(jpegBytes, 'prod_1', 0);

      expect(result, 'products/img.jpg');
      expect(putCallCount, 3);
    });

    test('returns null after max retries exceeded', () async {
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);

      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => {
          'urls': [
            {
              'upload_url': 'https://upload.example.com/img.jpg',
              'path': 'products/img.jpg',
            },
          ],
        },
      );

      when(
        mockHttpClient.put(
          any,
          body: anyNamed('body'),
          headers: anyNamed('headers'),
        ),
      ).thenThrow(Exception('Network error'));

      final helper = createHelper();
      final result = await helper.uploadSingleImage(jpegBytes, 'prod_1', 0);

      expect(result, isNull);
    });

    test('returns null when getUploadUrlInfoImpl returns null', () async {
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);

      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => {'urls': []});

      final helper = createHelper();
      final result = await helper.uploadSingleImage(jpegBytes, 'prod_1', 0);

      expect(result, isNull);
    });

    test('uses correct MIME type for PNG images', () async {
      final pngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);

      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => {
          'urls': [
            {
              'upload_url': 'https://upload.example.com/img.png',
              'path': 'products/img.png',
            },
          ],
        },
      );

      when(
        mockHttpClient.put(
          any,
          body: anyNamed('body'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response('', 200));

      final helper = createHelper();
      await helper.uploadSingleImage(pngBytes, 'prod_1', 0);

      verify(
        mockHttpClient.put(
          any,
          body: anyNamed('body'),
          headers: {'Content-Type': 'image/png'},
        ),
      ).called(1);
    });

    test('uses correct MIME type for WEBP images', () async {
      final webpBytes = Uint8List.fromList([
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
      ]);

      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => {
          'urls': [
            {
              'upload_url': 'https://upload.example.com/img.webp',
              'path': 'products/img.webp',
            },
          ],
        },
      );

      when(
        mockHttpClient.put(
          any,
          body: anyNamed('body'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response('', 200));

      final helper = createHelper();
      await helper.uploadSingleImage(webpBytes, 'prod_1', 0);

      verify(
        mockHttpClient.put(
          any,
          body: anyNamed('body'),
          headers: {'Content-Type': 'image/webp'},
        ),
      ).called(1);
    });

    test('uses correct MIME type for GIF images', () async {
      final gifBytes = Uint8List.fromList([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]);

      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => {
          'urls': [
            {
              'upload_url': 'https://upload.example.com/img.gif',
              'path': 'products/img.gif',
            },
          ],
        },
      );

      when(
        mockHttpClient.put(
          any,
          body: anyNamed('body'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response('', 200));

      final helper = createHelper();
      await helper.uploadSingleImage(gifBytes, 'prod_1', 0);

      verify(
        mockHttpClient.put(
          any,
          body: anyNamed('body'),
          headers: {'Content-Type': 'image/gif'},
        ),
      ).called(1);
    });

    test('returns null on non-200 status code after retries', () async {
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);

      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => {
          'urls': [
            {
              'upload_url': 'https://upload.example.com/img.jpg',
              'path': 'products/img.jpg',
            },
          ],
        },
      );

      when(
        mockHttpClient.put(
          any,
          body: anyNamed('body'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response('Error', 500));

      final helper = createHelper();
      final result = await helper.uploadSingleImage(jpegBytes, 'prod_1', 0);

      expect(result, isNull);
    });

    test('generates unique filename with timestamp', () async {
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);

      String? capturedPath;
      when(
        mockOb.request(
          'POST',
          '/storage/presign/upload',
          body: anyNamed('body'),
        ),
      ).thenAnswer((invocation) async {
        final body = invocation.namedArguments[#body] as Map<String, dynamic>;
        capturedPath = (body['paths'] as List).first as String;
        return {
          'urls': [
            {
              'upload_url': 'https://upload.example.com/img.jpg',
              'path': capturedPath,
            },
          ],
        };
      });

      when(
        mockHttpClient.put(
          any,
          body: anyNamed('body'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response('', 200));

      final helper = createHelper();
      await helper.uploadSingleImage(jpegBytes, 'prod_123', 5);

      expect(capturedPath, contains('product_prod_123_5_'));
      expect(capturedPath, endsWith('.jpg'));
    });
  });
}
