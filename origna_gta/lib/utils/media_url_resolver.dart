import 'package:origna_gta/services/conf_services.dart';

/// Resolves product/media image paths into browser-safe URLs.
///
/// Backend storage may persist bare R2 object paths like `dev/products/foo.jpg`
/// instead of fully qualified URLs. Web rendering is much more reliable when
/// these paths are normalized before they reach `CachedNetworkImage`.
String resolveMediaUrl(String rawSource) {
  final source = rawSource.trim();
  if (source.isEmpty) return '';

  if (source.startsWith('assets/') || source.startsWith('images/')) {
    return source;
  }

  if (source.startsWith('//')) {
    return 'https:$source';
  }

  final parsed = Uri.tryParse(source);
  if (parsed != null && parsed.hasScheme) {
    return source;
  }

  final baseUrl = ConfigService().imageBaseUrl.trim();
  if (baseUrl.isEmpty) {
    return source;
  }

  final normalizedBase = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
  final normalizedPath = source.startsWith('/') ? source.substring(1) : source;
  return '$normalizedBase/$normalizedPath';
}
