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
