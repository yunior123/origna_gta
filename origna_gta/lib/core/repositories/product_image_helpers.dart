// coverage:ignore-file
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:orignabase/orignabase.dart';

/// Extracted image upload helpers for [OrignaBaseProductRepository].
///
/// Handles presigned URL generation, image upload with retry, MIME detection,
/// and review image uploads. Stateless — depends only on [OrignaBase] and
/// an [http.Client].
mixin ProductImageHelpers {
  OrignaBase get ob;
  http.Client get httpClient;

  /// Returns a presigned upload URL and the resulting public URL for a product image.
  Future<Map<String, String>?> getUploadUrlInfoImpl(String fileName) async {
    final path = 'products/$fileName';
    final result = await ob.request(
      'POST',
      '/storage/presign/upload',
      body: {
        'paths': [path],
        'ttl_secs': 3600,
      },
    );
    final resultMap = Map<String, dynamic>.from((result as Map?) ?? {});
    final urls = List<Map<String, dynamic>>.from((resultMap['urls'] as List?) ?? []);
    if (urls.isEmpty) return null;
    return {
      'uploadUrl': urls[0]['upload_url'] as String,
      'publicUrl': urls[0]['path'] as String,
    };
  }

  /// Returns a presigned upload URL for a product video.
  Future<Map<String, String>?> getUploadVideoUrlInfoImpl(
    String fileName,
    String contentType,
  ) async {
    final path = 'products/videos/$fileName';
    final result = await ob.request(
      'POST',
      '/storage/presign/upload',
      body: {
        'paths': [path],
        'ttl_secs': 3600,
      },
    );
    final resultMap = Map<String, dynamic>.from((result as Map?) ?? {});
    final urls = List<Map<String, dynamic>>.from((resultMap['urls'] as List?) ?? []);
    if (urls.isEmpty) return null;
    return {
      'uploadUrl': urls[0]['upload_url'] as String,
      'publicUrl': urls[0]['path'] as String,
    };
  }

  /// Uploads multiple product images, returning their public URLs.
  /// On partial failure, cleans up successfully uploaded images.
  Future<List<String>> uploadImagesImpl(
    List<Uint8List> images,
    String productId,
  ) async {
    final uploadFutures = images.asMap().entries.map((entry) async {
      return await uploadSingleImage(entry.value, productId, entry.key);
    });

    final results = await Future.wait(uploadFutures);
    final urls = results.whereType<String>().toList();
    if (urls.length != images.length) {
      if (urls.isNotEmpty) {
        try {
          await ob.request(
            'POST',
            '/storage/batch-delete',
            body: {'paths': urls},
          );
        } catch (_) {
          // Best-effort cleanup
        }
      }
      throw Exception('Image upload failed');
    }
    return urls;
  }

  /// Uploads review images for a user, returning their public URLs.
  Future<List<String>> uploadReviewImagesImpl(
    List<Uint8List> images,
    String userId,
  ) async {
    if (images.isEmpty) return [];
    final ts = DateTime.now().millisecondsSinceEpoch;
    final paths = List.generate(
      images.length,
      (i) => 'reviews/$userId/img_${i}_$ts.jpg',
    );

    final result = await ob.request(
      'POST',
      '/storage/presign/upload',
      body: {'paths': paths, 'ttl_secs': 3600},
    );

    final resultMap = Map<String, dynamic>.from((result as Map?) ?? {});
    final urls = List<Map<String, dynamic>>.from((resultMap['urls'] as List?) ?? []);

    final uploadFutures = urls.asMap().entries.map((entry) async {
      final i = entry.key;
      final urlInfo = entry.value;
      try {
        final response = await httpClient
            .put(
              Uri.parse(urlInfo['upload_url'] as String),
              body: images[i],
              headers: {'Content-Type': 'image/jpeg'},
            )
            .timeout(const Duration(seconds: 30));
        if (response.statusCode == 200) return urlInfo['path'] as String;
        return null;
      } catch (_) {
        return null;
      }
    });

    final results = await Future.wait(uploadFutures);
    return results.whereType<String>().toList();
  }

  /// Uploads a single product image with retry logic (up to 3 attempts).
  Future<String?> uploadSingleImage(
    Uint8List bytes,
    String productId,
    int index,
  ) async {
    const maxRetries = 3;
    final mimeType = detectImageMimeType(bytes);
    final ext = mimeType.split('/').last.replaceFirst('jpeg', 'jpg');
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final fileName =
            'product_${productId}_${index}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final urlInfo = await getUploadUrlInfoImpl(fileName);

        if (urlInfo == null) throw Exception('Could not get upload URL');

        final response = await httpClient
            .put(
              Uri.parse(urlInfo['uploadUrl']!),
              body: bytes,
              headers: {'Content-Type': mimeType},
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          return urlInfo['publicUrl'];
        }
        throw Exception('Upload failed with status ${response.statusCode}');
      } catch (e) {
        if (attempt == maxRetries) return null;
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    return null;
  }

  /// Detects the MIME type of an image from its magic bytes.
  static String detectImageMimeType(Uint8List bytes) {
    if (bytes.length < 4) return 'image/jpeg';
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return 'image/gif';
    }
    return 'image/jpeg';
  }
}
