/// Lightweight Timestamp shim used by generated/manual model tests.
/// App code should prefer `DateTime` directly.
class Timestamp {
  final DateTime _value;

  Timestamp._(DateTime value) : _value = value;

  factory Timestamp.now() => Timestamp._(DateTime.now());

  factory Timestamp.fromDate(DateTime value) => Timestamp._(value);

  DateTime toDate() => _value;

  int get millisecondsSinceEpoch => _value.millisecondsSinceEpoch;

  int get seconds => _value.millisecondsSinceEpoch ~/ 1000;

  int compareTo(Timestamp other) => _value.compareTo(other._value);

  @override
  bool operator ==(Object other) =>
      other is Timestamp &&
      other._value.millisecondsSinceEpoch == _value.millisecondsSinceEpoch;

  @override
  int get hashCode => _value.millisecondsSinceEpoch.hashCode;

  @override
  String toString() => 'Timestamp(${_value.toIso8601String()})';
}

// =============================================================================
// PostgreSQL -> Dart timestamp precision workaround
// =============================================================================
//
// ## Problem
// PostgreSQL stores timestamps with **nanosecond** precision (9 fractional
// digits), e.g.:
//
//     2026-03-12T11:56:03.185238962+00:00
//
// Dart's [DateTime.parse] only supports up to **microsecond** precision
// (6 fractional digits). Passing a 9-digit fractional string to
// `DateTime.parse` or `DateTime.tryParse` returns null / throws a
// FormatException.
//
// ## Solution
// Before any `DateTime.parse` call on a PostgreSQL timestamp, truncate the
// fractional digits from 9 to 6 using [truncateNanoseconds].
//
// This is a lossy conversion — the final 3 digits (nanoseconds) are
// discarded — but Dart's [DateTime] has no nanosecond field, so there is
// no way to preserve them. For all business logic in this app (ordering,
// sorting, display) microsecond precision is more than sufficient.
//
// ## Usage
// ```dart
// final raw = '2026-03-12T11:56:03.185238962+00:00';
// final dt = DateTime.parse(truncateNanoseconds(raw));
// // dt = 2026-03-12 11:56:03.185238 UTC
// ```
//
// ## Where this is applied
// - [OrignaBaseProductRepository.docToProduct] — product timestamps
// - [_parseDateTime] in `order_models.dart` — order timestamps
// - [sanitizeProductData] in `product_repository.dart` — createdAt on writes
//
// If a new collection is added to OrignaBase that returns ISO timestamps,
// its Dart model parser must also call [truncateNanoseconds] before parsing.
// =============================================================================

/// Truncate subsecond precision from 7+ digits to exactly 6 (microseconds).
///
/// PostgreSQL emits 9-digit fractional seconds; Dart only handles 6.
/// The regex matches `.` followed by 6+ digits and keeps only the first 6.
///
/// Safe to call on strings that already have <= 6 fractional digits — the
/// regex simply won't match, returning the input unchanged.
String truncateNanoseconds(String iso) {
  return iso.replaceAllMapped(RegExp(r'(\.\d{6})\d+'), (m) => m.group(1)!);
}

/// Parse a dynamic value to [DateTime], handling PostgreSQL nanosecond strings.
///
/// Accepts:
/// - `null` -> returns `null`
/// - [DateTime] -> returned as-is
/// - [String] -> truncated to microsecond precision, then parsed
/// - [int] -> treated as milliseconds since epoch
DateTime? parseTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(truncateNanoseconds(value));
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}
