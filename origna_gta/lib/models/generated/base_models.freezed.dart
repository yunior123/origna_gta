// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'base_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Address _$AddressFromJson(Map<String, dynamic> json) {
  return _Address.fromJson(json);
}

/// @nodoc
mixin _$Address {
  String get street => throw _privateConstructorUsedError;
  String get apartment => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  String get state => throw _privateConstructorUsedError;
  String get postalCode => throw _privateConstructorUsedError;
  String get country => throw _privateConstructorUsedError;
  String? get phoneNumber => throw _privateConstructorUsedError;
  bool get isDefault => throw _privateConstructorUsedError;
  String? get label => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;

  /// Serializes this Address to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Address
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AddressCopyWith<Address> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AddressCopyWith<$Res> {
  factory $AddressCopyWith(Address value, $Res Function(Address) then) =
      _$AddressCopyWithImpl<$Res, Address>;
  @useResult
  $Res call({
    String street,
    String apartment,
    String city,
    String state,
    String postalCode,
    String country,
    String? phoneNumber,
    bool isDefault,
    String? label,
    double? latitude,
    double? longitude,
  });
}

/// @nodoc
class _$AddressCopyWithImpl<$Res, $Val extends Address>
    implements $AddressCopyWith<$Res> {
  _$AddressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Address
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? street = null,
    Object? apartment = null,
    Object? city = null,
    Object? state = null,
    Object? postalCode = null,
    Object? country = null,
    Object? phoneNumber = freezed,
    Object? isDefault = null,
    Object? label = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
  }) {
    return _then(
      _value.copyWith(
            street: null == street
                ? _value.street
                : street // ignore: cast_nullable_to_non_nullable
                      as String,
            apartment: null == apartment
                ? _value.apartment
                : apartment // ignore: cast_nullable_to_non_nullable
                      as String,
            city: null == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String,
            state: null == state
                ? _value.state
                : state // ignore: cast_nullable_to_non_nullable
                      as String,
            postalCode: null == postalCode
                ? _value.postalCode
                : postalCode // ignore: cast_nullable_to_non_nullable
                      as String,
            country: null == country
                ? _value.country
                : country // ignore: cast_nullable_to_non_nullable
                      as String,
            phoneNumber: freezed == phoneNumber
                ? _value.phoneNumber
                : phoneNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            isDefault: null == isDefault
                ? _value.isDefault
                : isDefault // ignore: cast_nullable_to_non_nullable
                      as bool,
            label: freezed == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String?,
            latitude: freezed == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            longitude: freezed == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AddressImplCopyWith<$Res> implements $AddressCopyWith<$Res> {
  factory _$$AddressImplCopyWith(
    _$AddressImpl value,
    $Res Function(_$AddressImpl) then,
  ) = __$$AddressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String street,
    String apartment,
    String city,
    String state,
    String postalCode,
    String country,
    String? phoneNumber,
    bool isDefault,
    String? label,
    double? latitude,
    double? longitude,
  });
}

/// @nodoc
class __$$AddressImplCopyWithImpl<$Res>
    extends _$AddressCopyWithImpl<$Res, _$AddressImpl>
    implements _$$AddressImplCopyWith<$Res> {
  __$$AddressImplCopyWithImpl(
    _$AddressImpl _value,
    $Res Function(_$AddressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Address
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? street = null,
    Object? apartment = null,
    Object? city = null,
    Object? state = null,
    Object? postalCode = null,
    Object? country = null,
    Object? phoneNumber = freezed,
    Object? isDefault = null,
    Object? label = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
  }) {
    return _then(
      _$AddressImpl(
        street: null == street
            ? _value.street
            : street // ignore: cast_nullable_to_non_nullable
                  as String,
        apartment: null == apartment
            ? _value.apartment
            : apartment // ignore: cast_nullable_to_non_nullable
                  as String,
        city: null == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String,
        state: null == state
            ? _value.state
            : state // ignore: cast_nullable_to_non_nullable
                  as String,
        postalCode: null == postalCode
            ? _value.postalCode
            : postalCode // ignore: cast_nullable_to_non_nullable
                  as String,
        country: null == country
            ? _value.country
            : country // ignore: cast_nullable_to_non_nullable
                  as String,
        phoneNumber: freezed == phoneNumber
            ? _value.phoneNumber
            : phoneNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        isDefault: null == isDefault
            ? _value.isDefault
            : isDefault // ignore: cast_nullable_to_non_nullable
                  as bool,
        label: freezed == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String?,
        latitude: freezed == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AddressImpl extends _Address {
  const _$AddressImpl({
    required this.street,
    this.apartment = '',
    required this.city,
    required this.state,
    required this.postalCode,
    this.country = 'Canada',
    this.phoneNumber,
    this.isDefault = false,
    this.label,
    this.latitude,
    this.longitude,
  }) : super._();

  factory _$AddressImpl.fromJson(Map<String, dynamic> json) =>
      _$$AddressImplFromJson(json);

  @override
  final String street;
  @override
  @JsonKey()
  final String apartment;
  @override
  final String city;
  @override
  final String state;
  @override
  final String postalCode;
  @override
  @JsonKey()
  final String country;
  @override
  final String? phoneNumber;
  @override
  @JsonKey()
  final bool isDefault;
  @override
  final String? label;
  @override
  final double? latitude;
  @override
  final double? longitude;

  @override
  String toString() {
    return 'Address(street: $street, apartment: $apartment, city: $city, state: $state, postalCode: $postalCode, country: $country, phoneNumber: $phoneNumber, isDefault: $isDefault, label: $label, latitude: $latitude, longitude: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AddressImpl &&
            (identical(other.street, street) || other.street == street) &&
            (identical(other.apartment, apartment) ||
                other.apartment == apartment) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.postalCode, postalCode) ||
                other.postalCode == postalCode) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.isDefault, isDefault) ||
                other.isDefault == isDefault) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    street,
    apartment,
    city,
    state,
    postalCode,
    country,
    phoneNumber,
    isDefault,
    label,
    latitude,
    longitude,
  );

  /// Create a copy of Address
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AddressImplCopyWith<_$AddressImpl> get copyWith =>
      __$$AddressImplCopyWithImpl<_$AddressImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AddressImplToJson(this);
  }
}

abstract class _Address extends Address {
  const factory _Address({
    required final String street,
    final String apartment,
    required final String city,
    required final String state,
    required final String postalCode,
    final String country,
    final String? phoneNumber,
    final bool isDefault,
    final String? label,
    final double? latitude,
    final double? longitude,
  }) = _$AddressImpl;
  const _Address._() : super._();

  factory _Address.fromJson(Map<String, dynamic> json) = _$AddressImpl.fromJson;

  @override
  String get street;
  @override
  String get apartment;
  @override
  String get city;
  @override
  String get state;
  @override
  String get postalCode;
  @override
  String get country;
  @override
  String? get phoneNumber;
  @override
  bool get isDefault;
  @override
  String? get label;
  @override
  double? get latitude;
  @override
  double? get longitude;

  /// Create a copy of Address
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AddressImplCopyWith<_$AddressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AddressDetails _$AddressDetailsFromJson(Map<String, dynamic> json) {
  return _AddressDetails.fromJson(json);
}

/// @nodoc
mixin _$AddressDetails {
  String get street => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  String get state => throw _privateConstructorUsedError;
  String get postalCode => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;

  /// Serializes this AddressDetails to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AddressDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AddressDetailsCopyWith<AddressDetails> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AddressDetailsCopyWith<$Res> {
  factory $AddressDetailsCopyWith(
    AddressDetails value,
    $Res Function(AddressDetails) then,
  ) = _$AddressDetailsCopyWithImpl<$Res, AddressDetails>;
  @useResult
  $Res call({
    String street,
    String city,
    String state,
    String postalCode,
    double latitude,
    double longitude,
  });
}

/// @nodoc
class _$AddressDetailsCopyWithImpl<$Res, $Val extends AddressDetails>
    implements $AddressDetailsCopyWith<$Res> {
  _$AddressDetailsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AddressDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? street = null,
    Object? city = null,
    Object? state = null,
    Object? postalCode = null,
    Object? latitude = null,
    Object? longitude = null,
  }) {
    return _then(
      _value.copyWith(
            street: null == street
                ? _value.street
                : street // ignore: cast_nullable_to_non_nullable
                      as String,
            city: null == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String,
            state: null == state
                ? _value.state
                : state // ignore: cast_nullable_to_non_nullable
                      as String,
            postalCode: null == postalCode
                ? _value.postalCode
                : postalCode // ignore: cast_nullable_to_non_nullable
                      as String,
            latitude: null == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double,
            longitude: null == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AddressDetailsImplCopyWith<$Res>
    implements $AddressDetailsCopyWith<$Res> {
  factory _$$AddressDetailsImplCopyWith(
    _$AddressDetailsImpl value,
    $Res Function(_$AddressDetailsImpl) then,
  ) = __$$AddressDetailsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String street,
    String city,
    String state,
    String postalCode,
    double latitude,
    double longitude,
  });
}

/// @nodoc
class __$$AddressDetailsImplCopyWithImpl<$Res>
    extends _$AddressDetailsCopyWithImpl<$Res, _$AddressDetailsImpl>
    implements _$$AddressDetailsImplCopyWith<$Res> {
  __$$AddressDetailsImplCopyWithImpl(
    _$AddressDetailsImpl _value,
    $Res Function(_$AddressDetailsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AddressDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? street = null,
    Object? city = null,
    Object? state = null,
    Object? postalCode = null,
    Object? latitude = null,
    Object? longitude = null,
  }) {
    return _then(
      _$AddressDetailsImpl(
        street: null == street
            ? _value.street
            : street // ignore: cast_nullable_to_non_nullable
                  as String,
        city: null == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String,
        state: null == state
            ? _value.state
            : state // ignore: cast_nullable_to_non_nullable
                  as String,
        postalCode: null == postalCode
            ? _value.postalCode
            : postalCode // ignore: cast_nullable_to_non_nullable
                  as String,
        latitude: null == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double,
        longitude: null == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AddressDetailsImpl implements _AddressDetails {
  const _$AddressDetailsImpl({
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
  });

  factory _$AddressDetailsImpl.fromJson(Map<String, dynamic> json) =>
      _$$AddressDetailsImplFromJson(json);

  @override
  final String street;
  @override
  final String city;
  @override
  final String state;
  @override
  final String postalCode;
  @override
  final double latitude;
  @override
  final double longitude;

  @override
  String toString() {
    return 'AddressDetails(street: $street, city: $city, state: $state, postalCode: $postalCode, latitude: $latitude, longitude: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AddressDetailsImpl &&
            (identical(other.street, street) || other.street == street) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.postalCode, postalCode) ||
                other.postalCode == postalCode) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    street,
    city,
    state,
    postalCode,
    latitude,
    longitude,
  );

  /// Create a copy of AddressDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AddressDetailsImplCopyWith<_$AddressDetailsImpl> get copyWith =>
      __$$AddressDetailsImplCopyWithImpl<_$AddressDetailsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AddressDetailsImplToJson(this);
  }
}

abstract class _AddressDetails implements AddressDetails {
  const factory _AddressDetails({
    required final String street,
    required final String city,
    required final String state,
    required final String postalCode,
    required final double latitude,
    required final double longitude,
  }) = _$AddressDetailsImpl;

  factory _AddressDetails.fromJson(Map<String, dynamic> json) =
      _$AddressDetailsImpl.fromJson;

  @override
  String get street;
  @override
  String get city;
  @override
  String get state;
  @override
  String get postalCode;
  @override
  double get latitude;
  @override
  double get longitude;

  /// Create a copy of AddressDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AddressDetailsImplCopyWith<_$AddressDetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
