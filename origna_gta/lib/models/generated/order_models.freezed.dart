// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Order _$OrderFromJson(Map<String, dynamic> json) {
  return _Order.fromJson(json);
}

/// @nodoc
mixin _$Order {
  String get orderId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get customerId => throw _privateConstructorUsedError;
  String get customerEmail => throw _privateConstructorUsedError;
  List<OrderItem> get items =>
      throw _privateConstructorUsedError; // All money in integer cents
  int get totalAmountCents => throw _privateConstructorUsedError;
  int get subtotalCents => throw _privateConstructorUsedError;
  int get shippingCostCents => throw _privateConstructorUsedError;
  int get taxAmountCents => throw _privateConstructorUsedError;
  Taxes get taxes => throw _privateConstructorUsedError;
  OrderStatus get orderStatus => throw _privateConstructorUsedError;
  PaymentStatus get paymentStatus => throw _privateConstructorUsedError;
  Address get shippingAddress => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  List<String> get sellerIds => throw _privateConstructorUsedError;
  String get stripeSessionId =>
      throw _privateConstructorUsedError; // Shipping approval
  ShippingApprovalStatus get shippingApprovalStatus =>
      throw _privateConstructorUsedError;
  bool get shippingApprovalRequired => throw _privateConstructorUsedError;
  double get actualShipping => throw _privateConstructorUsedError;
  double get pendingTotal =>
      throw _privateConstructorUsedError; // Payout tracking
  List<SellerPayout> get sellerPayouts => throw _privateConstructorUsedError;
  bool get confirmedByClient => throw _privateConstructorUsedError;
  DateTime? get confirmedAt => throw _privateConstructorUsedError;
  double get platformFeeTotal => throw _privateConstructorUsedError;
  String get payoutStatus => throw _privateConstructorUsedError; // Ratings
  List<Ratings> get ratings => throw _privateConstructorUsedError;

  /// Serializes this Order to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderCopyWith<Order> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderCopyWith<$Res> {
  factory $OrderCopyWith(Order value, $Res Function(Order) then) =
      _$OrderCopyWithImpl<$Res, Order>;
  @useResult
  $Res call({
    String orderId,
    String userId,
    String customerId,
    String customerEmail,
    List<OrderItem> items,
    int totalAmountCents,
    int subtotalCents,
    int shippingCostCents,
    int taxAmountCents,
    Taxes taxes,
    OrderStatus orderStatus,
    PaymentStatus paymentStatus,
    Address shippingAddress,
    DateTime createdAt,
    String currency,
    List<String> sellerIds,
    String stripeSessionId,
    ShippingApprovalStatus shippingApprovalStatus,
    bool shippingApprovalRequired,
    double actualShipping,
    double pendingTotal,
    List<SellerPayout> sellerPayouts,
    bool confirmedByClient,
    DateTime? confirmedAt,
    double platformFeeTotal,
    String payoutStatus,
    List<Ratings> ratings,
  });

  $TaxesCopyWith<$Res> get taxes;
  $AddressCopyWith<$Res> get shippingAddress;
}

/// @nodoc
class _$OrderCopyWithImpl<$Res, $Val extends Order>
    implements $OrderCopyWith<$Res> {
  _$OrderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orderId = null,
    Object? userId = null,
    Object? customerId = null,
    Object? customerEmail = null,
    Object? items = null,
    Object? totalAmountCents = null,
    Object? subtotalCents = null,
    Object? shippingCostCents = null,
    Object? taxAmountCents = null,
    Object? taxes = null,
    Object? orderStatus = null,
    Object? paymentStatus = null,
    Object? shippingAddress = null,
    Object? createdAt = null,
    Object? currency = null,
    Object? sellerIds = null,
    Object? stripeSessionId = null,
    Object? shippingApprovalStatus = null,
    Object? shippingApprovalRequired = null,
    Object? actualShipping = null,
    Object? pendingTotal = null,
    Object? sellerPayouts = null,
    Object? confirmedByClient = null,
    Object? confirmedAt = freezed,
    Object? platformFeeTotal = null,
    Object? payoutStatus = null,
    Object? ratings = null,
  }) {
    return _then(
      _value.copyWith(
            orderId: null == orderId
                ? _value.orderId
                : orderId // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            customerId: null == customerId
                ? _value.customerId
                : customerId // ignore: cast_nullable_to_non_nullable
                      as String,
            customerEmail: null == customerEmail
                ? _value.customerEmail
                : customerEmail // ignore: cast_nullable_to_non_nullable
                      as String,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<OrderItem>,
            totalAmountCents: null == totalAmountCents
                ? _value.totalAmountCents
                : totalAmountCents // ignore: cast_nullable_to_non_nullable
                      as int,
            subtotalCents: null == subtotalCents
                ? _value.subtotalCents
                : subtotalCents // ignore: cast_nullable_to_non_nullable
                      as int,
            shippingCostCents: null == shippingCostCents
                ? _value.shippingCostCents
                : shippingCostCents // ignore: cast_nullable_to_non_nullable
                      as int,
            taxAmountCents: null == taxAmountCents
                ? _value.taxAmountCents
                : taxAmountCents // ignore: cast_nullable_to_non_nullable
                      as int,
            taxes: null == taxes
                ? _value.taxes
                : taxes // ignore: cast_nullable_to_non_nullable
                      as Taxes,
            orderStatus: null == orderStatus
                ? _value.orderStatus
                : orderStatus // ignore: cast_nullable_to_non_nullable
                      as OrderStatus,
            paymentStatus: null == paymentStatus
                ? _value.paymentStatus
                : paymentStatus // ignore: cast_nullable_to_non_nullable
                      as PaymentStatus,
            shippingAddress: null == shippingAddress
                ? _value.shippingAddress
                : shippingAddress // ignore: cast_nullable_to_non_nullable
                      as Address,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            sellerIds: null == sellerIds
                ? _value.sellerIds
                : sellerIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            stripeSessionId: null == stripeSessionId
                ? _value.stripeSessionId
                : stripeSessionId // ignore: cast_nullable_to_non_nullable
                      as String,
            shippingApprovalStatus: null == shippingApprovalStatus
                ? _value.shippingApprovalStatus
                : shippingApprovalStatus // ignore: cast_nullable_to_non_nullable
                      as ShippingApprovalStatus,
            shippingApprovalRequired: null == shippingApprovalRequired
                ? _value.shippingApprovalRequired
                : shippingApprovalRequired // ignore: cast_nullable_to_non_nullable
                      as bool,
            actualShipping: null == actualShipping
                ? _value.actualShipping
                : actualShipping // ignore: cast_nullable_to_non_nullable
                      as double,
            pendingTotal: null == pendingTotal
                ? _value.pendingTotal
                : pendingTotal // ignore: cast_nullable_to_non_nullable
                      as double,
            sellerPayouts: null == sellerPayouts
                ? _value.sellerPayouts
                : sellerPayouts // ignore: cast_nullable_to_non_nullable
                      as List<SellerPayout>,
            confirmedByClient: null == confirmedByClient
                ? _value.confirmedByClient
                : confirmedByClient // ignore: cast_nullable_to_non_nullable
                      as bool,
            confirmedAt: freezed == confirmedAt
                ? _value.confirmedAt
                : confirmedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            platformFeeTotal: null == platformFeeTotal
                ? _value.platformFeeTotal
                : platformFeeTotal // ignore: cast_nullable_to_non_nullable
                      as double,
            payoutStatus: null == payoutStatus
                ? _value.payoutStatus
                : payoutStatus // ignore: cast_nullable_to_non_nullable
                      as String,
            ratings: null == ratings
                ? _value.ratings
                : ratings // ignore: cast_nullable_to_non_nullable
                      as List<Ratings>,
          )
          as $Val,
    );
  }

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TaxesCopyWith<$Res> get taxes {
    return $TaxesCopyWith<$Res>(_value.taxes, (value) {
      return _then(_value.copyWith(taxes: value) as $Val);
    });
  }

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AddressCopyWith<$Res> get shippingAddress {
    return $AddressCopyWith<$Res>(_value.shippingAddress, (value) {
      return _then(_value.copyWith(shippingAddress: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OrderImplCopyWith<$Res> implements $OrderCopyWith<$Res> {
  factory _$$OrderImplCopyWith(
    _$OrderImpl value,
    $Res Function(_$OrderImpl) then,
  ) = __$$OrderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String orderId,
    String userId,
    String customerId,
    String customerEmail,
    List<OrderItem> items,
    int totalAmountCents,
    int subtotalCents,
    int shippingCostCents,
    int taxAmountCents,
    Taxes taxes,
    OrderStatus orderStatus,
    PaymentStatus paymentStatus,
    Address shippingAddress,
    DateTime createdAt,
    String currency,
    List<String> sellerIds,
    String stripeSessionId,
    ShippingApprovalStatus shippingApprovalStatus,
    bool shippingApprovalRequired,
    double actualShipping,
    double pendingTotal,
    List<SellerPayout> sellerPayouts,
    bool confirmedByClient,
    DateTime? confirmedAt,
    double platformFeeTotal,
    String payoutStatus,
    List<Ratings> ratings,
  });

  @override
  $TaxesCopyWith<$Res> get taxes;
  @override
  $AddressCopyWith<$Res> get shippingAddress;
}

/// @nodoc
class __$$OrderImplCopyWithImpl<$Res>
    extends _$OrderCopyWithImpl<$Res, _$OrderImpl>
    implements _$$OrderImplCopyWith<$Res> {
  __$$OrderImplCopyWithImpl(
    _$OrderImpl _value,
    $Res Function(_$OrderImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orderId = null,
    Object? userId = null,
    Object? customerId = null,
    Object? customerEmail = null,
    Object? items = null,
    Object? totalAmountCents = null,
    Object? subtotalCents = null,
    Object? shippingCostCents = null,
    Object? taxAmountCents = null,
    Object? taxes = null,
    Object? orderStatus = null,
    Object? paymentStatus = null,
    Object? shippingAddress = null,
    Object? createdAt = null,
    Object? currency = null,
    Object? sellerIds = null,
    Object? stripeSessionId = null,
    Object? shippingApprovalStatus = null,
    Object? shippingApprovalRequired = null,
    Object? actualShipping = null,
    Object? pendingTotal = null,
    Object? sellerPayouts = null,
    Object? confirmedByClient = null,
    Object? confirmedAt = freezed,
    Object? platformFeeTotal = null,
    Object? payoutStatus = null,
    Object? ratings = null,
  }) {
    return _then(
      _$OrderImpl(
        orderId: null == orderId
            ? _value.orderId
            : orderId // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        customerId: null == customerId
            ? _value.customerId
            : customerId // ignore: cast_nullable_to_non_nullable
                  as String,
        customerEmail: null == customerEmail
            ? _value.customerEmail
            : customerEmail // ignore: cast_nullable_to_non_nullable
                  as String,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<OrderItem>,
        totalAmountCents: null == totalAmountCents
            ? _value.totalAmountCents
            : totalAmountCents // ignore: cast_nullable_to_non_nullable
                  as int,
        subtotalCents: null == subtotalCents
            ? _value.subtotalCents
            : subtotalCents // ignore: cast_nullable_to_non_nullable
                  as int,
        shippingCostCents: null == shippingCostCents
            ? _value.shippingCostCents
            : shippingCostCents // ignore: cast_nullable_to_non_nullable
                  as int,
        taxAmountCents: null == taxAmountCents
            ? _value.taxAmountCents
            : taxAmountCents // ignore: cast_nullable_to_non_nullable
                  as int,
        taxes: null == taxes
            ? _value.taxes
            : taxes // ignore: cast_nullable_to_non_nullable
                  as Taxes,
        orderStatus: null == orderStatus
            ? _value.orderStatus
            : orderStatus // ignore: cast_nullable_to_non_nullable
                  as OrderStatus,
        paymentStatus: null == paymentStatus
            ? _value.paymentStatus
            : paymentStatus // ignore: cast_nullable_to_non_nullable
                  as PaymentStatus,
        shippingAddress: null == shippingAddress
            ? _value.shippingAddress
            : shippingAddress // ignore: cast_nullable_to_non_nullable
                  as Address,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        sellerIds: null == sellerIds
            ? _value._sellerIds
            : sellerIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        stripeSessionId: null == stripeSessionId
            ? _value.stripeSessionId
            : stripeSessionId // ignore: cast_nullable_to_non_nullable
                  as String,
        shippingApprovalStatus: null == shippingApprovalStatus
            ? _value.shippingApprovalStatus
            : shippingApprovalStatus // ignore: cast_nullable_to_non_nullable
                  as ShippingApprovalStatus,
        shippingApprovalRequired: null == shippingApprovalRequired
            ? _value.shippingApprovalRequired
            : shippingApprovalRequired // ignore: cast_nullable_to_non_nullable
                  as bool,
        actualShipping: null == actualShipping
            ? _value.actualShipping
            : actualShipping // ignore: cast_nullable_to_non_nullable
                  as double,
        pendingTotal: null == pendingTotal
            ? _value.pendingTotal
            : pendingTotal // ignore: cast_nullable_to_non_nullable
                  as double,
        sellerPayouts: null == sellerPayouts
            ? _value._sellerPayouts
            : sellerPayouts // ignore: cast_nullable_to_non_nullable
                  as List<SellerPayout>,
        confirmedByClient: null == confirmedByClient
            ? _value.confirmedByClient
            : confirmedByClient // ignore: cast_nullable_to_non_nullable
                  as bool,
        confirmedAt: freezed == confirmedAt
            ? _value.confirmedAt
            : confirmedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        platformFeeTotal: null == platformFeeTotal
            ? _value.platformFeeTotal
            : platformFeeTotal // ignore: cast_nullable_to_non_nullable
                  as double,
        payoutStatus: null == payoutStatus
            ? _value.payoutStatus
            : payoutStatus // ignore: cast_nullable_to_non_nullable
                  as String,
        ratings: null == ratings
            ? _value._ratings
            : ratings // ignore: cast_nullable_to_non_nullable
                  as List<Ratings>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderImpl extends _Order {
  const _$OrderImpl({
    required this.orderId,
    required this.userId,
    required this.customerId,
    required this.customerEmail,
    required final List<OrderItem> items,
    required this.totalAmountCents,
    required this.subtotalCents,
    this.shippingCostCents = 0,
    this.taxAmountCents = 0,
    required this.taxes,
    this.orderStatus = OrderStatus.pending,
    this.paymentStatus = PaymentStatus.awaitingPayment,
    required this.shippingAddress,
    required this.createdAt,
    this.currency = 'cad',
    final List<String> sellerIds = const [],
    required this.stripeSessionId,
    this.shippingApprovalStatus = ShippingApprovalStatus.notRequired,
    this.shippingApprovalRequired = false,
    this.actualShipping = 0.0,
    this.pendingTotal = 0.0,
    final List<SellerPayout> sellerPayouts = const [],
    this.confirmedByClient = false,
    this.confirmedAt,
    this.platformFeeTotal = 0.0,
    this.payoutStatus = 'pending',
    final List<Ratings> ratings = const [],
  }) : _items = items,
       _sellerIds = sellerIds,
       _sellerPayouts = sellerPayouts,
       _ratings = ratings,
       super._();

  factory _$OrderImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderImplFromJson(json);

  @override
  final String orderId;
  @override
  final String userId;
  @override
  final String customerId;
  @override
  final String customerEmail;
  final List<OrderItem> _items;
  @override
  List<OrderItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  // All money in integer cents
  @override
  final int totalAmountCents;
  @override
  final int subtotalCents;
  @override
  @JsonKey()
  final int shippingCostCents;
  @override
  @JsonKey()
  final int taxAmountCents;
  @override
  final Taxes taxes;
  @override
  @JsonKey()
  final OrderStatus orderStatus;
  @override
  @JsonKey()
  final PaymentStatus paymentStatus;
  @override
  final Address shippingAddress;
  @override
  final DateTime createdAt;
  @override
  @JsonKey()
  final String currency;
  final List<String> _sellerIds;
  @override
  @JsonKey()
  List<String> get sellerIds {
    if (_sellerIds is EqualUnmodifiableListView) return _sellerIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sellerIds);
  }

  @override
  final String stripeSessionId;
  // Shipping approval
  @override
  @JsonKey()
  final ShippingApprovalStatus shippingApprovalStatus;
  @override
  @JsonKey()
  final bool shippingApprovalRequired;
  @override
  @JsonKey()
  final double actualShipping;
  @override
  @JsonKey()
  final double pendingTotal;
  // Payout tracking
  final List<SellerPayout> _sellerPayouts;
  // Payout tracking
  @override
  @JsonKey()
  List<SellerPayout> get sellerPayouts {
    if (_sellerPayouts is EqualUnmodifiableListView) return _sellerPayouts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sellerPayouts);
  }

  @override
  @JsonKey()
  final bool confirmedByClient;
  @override
  final DateTime? confirmedAt;
  @override
  @JsonKey()
  final double platformFeeTotal;
  @override
  @JsonKey()
  final String payoutStatus;
  // Ratings
  final List<Ratings> _ratings;
  // Ratings
  @override
  @JsonKey()
  List<Ratings> get ratings {
    if (_ratings is EqualUnmodifiableListView) return _ratings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ratings);
  }

  @override
  String toString() {
    return 'Order(orderId: $orderId, userId: $userId, customerId: $customerId, customerEmail: $customerEmail, items: $items, totalAmountCents: $totalAmountCents, subtotalCents: $subtotalCents, shippingCostCents: $shippingCostCents, taxAmountCents: $taxAmountCents, taxes: $taxes, orderStatus: $orderStatus, paymentStatus: $paymentStatus, shippingAddress: $shippingAddress, createdAt: $createdAt, currency: $currency, sellerIds: $sellerIds, stripeSessionId: $stripeSessionId, shippingApprovalStatus: $shippingApprovalStatus, shippingApprovalRequired: $shippingApprovalRequired, actualShipping: $actualShipping, pendingTotal: $pendingTotal, sellerPayouts: $sellerPayouts, confirmedByClient: $confirmedByClient, confirmedAt: $confirmedAt, platformFeeTotal: $platformFeeTotal, payoutStatus: $payoutStatus, ratings: $ratings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderImpl &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.customerEmail, customerEmail) ||
                other.customerEmail == customerEmail) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.totalAmountCents, totalAmountCents) ||
                other.totalAmountCents == totalAmountCents) &&
            (identical(other.subtotalCents, subtotalCents) ||
                other.subtotalCents == subtotalCents) &&
            (identical(other.shippingCostCents, shippingCostCents) ||
                other.shippingCostCents == shippingCostCents) &&
            (identical(other.taxAmountCents, taxAmountCents) ||
                other.taxAmountCents == taxAmountCents) &&
            (identical(other.taxes, taxes) || other.taxes == taxes) &&
            (identical(other.orderStatus, orderStatus) ||
                other.orderStatus == orderStatus) &&
            (identical(other.paymentStatus, paymentStatus) ||
                other.paymentStatus == paymentStatus) &&
            (identical(other.shippingAddress, shippingAddress) ||
                other.shippingAddress == shippingAddress) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            const DeepCollectionEquality().equals(
              other._sellerIds,
              _sellerIds,
            ) &&
            (identical(other.stripeSessionId, stripeSessionId) ||
                other.stripeSessionId == stripeSessionId) &&
            (identical(other.shippingApprovalStatus, shippingApprovalStatus) ||
                other.shippingApprovalStatus == shippingApprovalStatus) &&
            (identical(
                  other.shippingApprovalRequired,
                  shippingApprovalRequired,
                ) ||
                other.shippingApprovalRequired == shippingApprovalRequired) &&
            (identical(other.actualShipping, actualShipping) ||
                other.actualShipping == actualShipping) &&
            (identical(other.pendingTotal, pendingTotal) ||
                other.pendingTotal == pendingTotal) &&
            const DeepCollectionEquality().equals(
              other._sellerPayouts,
              _sellerPayouts,
            ) &&
            (identical(other.confirmedByClient, confirmedByClient) ||
                other.confirmedByClient == confirmedByClient) &&
            (identical(other.confirmedAt, confirmedAt) ||
                other.confirmedAt == confirmedAt) &&
            (identical(other.platformFeeTotal, platformFeeTotal) ||
                other.platformFeeTotal == platformFeeTotal) &&
            (identical(other.payoutStatus, payoutStatus) ||
                other.payoutStatus == payoutStatus) &&
            const DeepCollectionEquality().equals(other._ratings, _ratings));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    orderId,
    userId,
    customerId,
    customerEmail,
    const DeepCollectionEquality().hash(_items),
    totalAmountCents,
    subtotalCents,
    shippingCostCents,
    taxAmountCents,
    taxes,
    orderStatus,
    paymentStatus,
    shippingAddress,
    createdAt,
    currency,
    const DeepCollectionEquality().hash(_sellerIds),
    stripeSessionId,
    shippingApprovalStatus,
    shippingApprovalRequired,
    actualShipping,
    pendingTotal,
    const DeepCollectionEquality().hash(_sellerPayouts),
    confirmedByClient,
    confirmedAt,
    platformFeeTotal,
    payoutStatus,
    const DeepCollectionEquality().hash(_ratings),
  ]);

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderImplCopyWith<_$OrderImpl> get copyWith =>
      __$$OrderImplCopyWithImpl<_$OrderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderImplToJson(this);
  }
}

abstract class _Order extends Order {
  const factory _Order({
    required final String orderId,
    required final String userId,
    required final String customerId,
    required final String customerEmail,
    required final List<OrderItem> items,
    required final int totalAmountCents,
    required final int subtotalCents,
    final int shippingCostCents,
    final int taxAmountCents,
    required final Taxes taxes,
    final OrderStatus orderStatus,
    final PaymentStatus paymentStatus,
    required final Address shippingAddress,
    required final DateTime createdAt,
    final String currency,
    final List<String> sellerIds,
    required final String stripeSessionId,
    final ShippingApprovalStatus shippingApprovalStatus,
    final bool shippingApprovalRequired,
    final double actualShipping,
    final double pendingTotal,
    final List<SellerPayout> sellerPayouts,
    final bool confirmedByClient,
    final DateTime? confirmedAt,
    final double platformFeeTotal,
    final String payoutStatus,
    final List<Ratings> ratings,
  }) = _$OrderImpl;
  const _Order._() : super._();

  factory _Order.fromJson(Map<String, dynamic> json) = _$OrderImpl.fromJson;

  @override
  String get orderId;
  @override
  String get userId;
  @override
  String get customerId;
  @override
  String get customerEmail;
  @override
  List<OrderItem> get items; // All money in integer cents
  @override
  int get totalAmountCents;
  @override
  int get subtotalCents;
  @override
  int get shippingCostCents;
  @override
  int get taxAmountCents;
  @override
  Taxes get taxes;
  @override
  OrderStatus get orderStatus;
  @override
  PaymentStatus get paymentStatus;
  @override
  Address get shippingAddress;
  @override
  DateTime get createdAt;
  @override
  String get currency;
  @override
  List<String> get sellerIds;
  @override
  String get stripeSessionId; // Shipping approval
  @override
  ShippingApprovalStatus get shippingApprovalStatus;
  @override
  bool get shippingApprovalRequired;
  @override
  double get actualShipping;
  @override
  double get pendingTotal; // Payout tracking
  @override
  List<SellerPayout> get sellerPayouts;
  @override
  bool get confirmedByClient;
  @override
  DateTime? get confirmedAt;
  @override
  double get platformFeeTotal;
  @override
  String get payoutStatus; // Ratings
  @override
  List<Ratings> get ratings;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderImplCopyWith<_$OrderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OrderCreate _$OrderCreateFromJson(Map<String, dynamic> json) {
  return _OrderCreate.fromJson(json);
}

/// @nodoc
mixin _$OrderCreate {
  String get userId => throw _privateConstructorUsedError;
  String get customerId => throw _privateConstructorUsedError;
  String get customerEmail => throw _privateConstructorUsedError;
  List<OrderItem> get items => throw _privateConstructorUsedError;
  Address get shippingAddress => throw _privateConstructorUsedError;
  double get shippingCost => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  bool get shippingApprovalRequired => throw _privateConstructorUsedError;

  /// Serializes this OrderCreate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderCreate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderCreateCopyWith<OrderCreate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderCreateCopyWith<$Res> {
  factory $OrderCreateCopyWith(
    OrderCreate value,
    $Res Function(OrderCreate) then,
  ) = _$OrderCreateCopyWithImpl<$Res, OrderCreate>;
  @useResult
  $Res call({
    String userId,
    String customerId,
    String customerEmail,
    List<OrderItem> items,
    Address shippingAddress,
    double shippingCost,
    String currency,
    bool shippingApprovalRequired,
  });

  $AddressCopyWith<$Res> get shippingAddress;
}

/// @nodoc
class _$OrderCreateCopyWithImpl<$Res, $Val extends OrderCreate>
    implements $OrderCreateCopyWith<$Res> {
  _$OrderCreateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderCreate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? customerId = null,
    Object? customerEmail = null,
    Object? items = null,
    Object? shippingAddress = null,
    Object? shippingCost = null,
    Object? currency = null,
    Object? shippingApprovalRequired = null,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            customerId: null == customerId
                ? _value.customerId
                : customerId // ignore: cast_nullable_to_non_nullable
                      as String,
            customerEmail: null == customerEmail
                ? _value.customerEmail
                : customerEmail // ignore: cast_nullable_to_non_nullable
                      as String,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<OrderItem>,
            shippingAddress: null == shippingAddress
                ? _value.shippingAddress
                : shippingAddress // ignore: cast_nullable_to_non_nullable
                      as Address,
            shippingCost: null == shippingCost
                ? _value.shippingCost
                : shippingCost // ignore: cast_nullable_to_non_nullable
                      as double,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            shippingApprovalRequired: null == shippingApprovalRequired
                ? _value.shippingApprovalRequired
                : shippingApprovalRequired // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of OrderCreate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AddressCopyWith<$Res> get shippingAddress {
    return $AddressCopyWith<$Res>(_value.shippingAddress, (value) {
      return _then(_value.copyWith(shippingAddress: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OrderCreateImplCopyWith<$Res>
    implements $OrderCreateCopyWith<$Res> {
  factory _$$OrderCreateImplCopyWith(
    _$OrderCreateImpl value,
    $Res Function(_$OrderCreateImpl) then,
  ) = __$$OrderCreateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    String customerId,
    String customerEmail,
    List<OrderItem> items,
    Address shippingAddress,
    double shippingCost,
    String currency,
    bool shippingApprovalRequired,
  });

  @override
  $AddressCopyWith<$Res> get shippingAddress;
}

/// @nodoc
class __$$OrderCreateImplCopyWithImpl<$Res>
    extends _$OrderCreateCopyWithImpl<$Res, _$OrderCreateImpl>
    implements _$$OrderCreateImplCopyWith<$Res> {
  __$$OrderCreateImplCopyWithImpl(
    _$OrderCreateImpl _value,
    $Res Function(_$OrderCreateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OrderCreate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? customerId = null,
    Object? customerEmail = null,
    Object? items = null,
    Object? shippingAddress = null,
    Object? shippingCost = null,
    Object? currency = null,
    Object? shippingApprovalRequired = null,
  }) {
    return _then(
      _$OrderCreateImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        customerId: null == customerId
            ? _value.customerId
            : customerId // ignore: cast_nullable_to_non_nullable
                  as String,
        customerEmail: null == customerEmail
            ? _value.customerEmail
            : customerEmail // ignore: cast_nullable_to_non_nullable
                  as String,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<OrderItem>,
        shippingAddress: null == shippingAddress
            ? _value.shippingAddress
            : shippingAddress // ignore: cast_nullable_to_non_nullable
                  as Address,
        shippingCost: null == shippingCost
            ? _value.shippingCost
            : shippingCost // ignore: cast_nullable_to_non_nullable
                  as double,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        shippingApprovalRequired: null == shippingApprovalRequired
            ? _value.shippingApprovalRequired
            : shippingApprovalRequired // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderCreateImpl implements _OrderCreate {
  const _$OrderCreateImpl({
    required this.userId,
    required this.customerId,
    required this.customerEmail,
    required final List<OrderItem> items,
    required this.shippingAddress,
    this.shippingCost = 0.0,
    this.currency = 'cad',
    this.shippingApprovalRequired = false,
  }) : _items = items;

  factory _$OrderCreateImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderCreateImplFromJson(json);

  @override
  final String userId;
  @override
  final String customerId;
  @override
  final String customerEmail;
  final List<OrderItem> _items;
  @override
  List<OrderItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final Address shippingAddress;
  @override
  @JsonKey()
  final double shippingCost;
  @override
  @JsonKey()
  final String currency;
  @override
  @JsonKey()
  final bool shippingApprovalRequired;

  @override
  String toString() {
    return 'OrderCreate(userId: $userId, customerId: $customerId, customerEmail: $customerEmail, items: $items, shippingAddress: $shippingAddress, shippingCost: $shippingCost, currency: $currency, shippingApprovalRequired: $shippingApprovalRequired)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderCreateImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.customerEmail, customerEmail) ||
                other.customerEmail == customerEmail) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.shippingAddress, shippingAddress) ||
                other.shippingAddress == shippingAddress) &&
            (identical(other.shippingCost, shippingCost) ||
                other.shippingCost == shippingCost) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(
                  other.shippingApprovalRequired,
                  shippingApprovalRequired,
                ) ||
                other.shippingApprovalRequired == shippingApprovalRequired));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    customerId,
    customerEmail,
    const DeepCollectionEquality().hash(_items),
    shippingAddress,
    shippingCost,
    currency,
    shippingApprovalRequired,
  );

  /// Create a copy of OrderCreate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderCreateImplCopyWith<_$OrderCreateImpl> get copyWith =>
      __$$OrderCreateImplCopyWithImpl<_$OrderCreateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderCreateImplToJson(this);
  }
}

abstract class _OrderCreate implements OrderCreate {
  const factory _OrderCreate({
    required final String userId,
    required final String customerId,
    required final String customerEmail,
    required final List<OrderItem> items,
    required final Address shippingAddress,
    final double shippingCost,
    final String currency,
    final bool shippingApprovalRequired,
  }) = _$OrderCreateImpl;

  factory _OrderCreate.fromJson(Map<String, dynamic> json) =
      _$OrderCreateImpl.fromJson;

  @override
  String get userId;
  @override
  String get customerId;
  @override
  String get customerEmail;
  @override
  List<OrderItem> get items;
  @override
  Address get shippingAddress;
  @override
  double get shippingCost;
  @override
  String get currency;
  @override
  bool get shippingApprovalRequired;

  /// Create a copy of OrderCreate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderCreateImplCopyWith<_$OrderCreateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) {
  return _OrderItem.fromJson(json);
}

/// @nodoc
mixin _$OrderItem {
  String get productId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  List<String> get imageUrls => throw _privateConstructorUsedError;
  String get sellerId => throw _privateConstructorUsedError;
  Address get sellerAddress => throw _privateConstructorUsedError;
  DeliveryStatus get deliveryStatus => throw _privateConstructorUsedError;
  String? get trackingNumber => throw _privateConstructorUsedError;
  bool get confirmedByBuyer =>
      throw _privateConstructorUsedError; // Shipping metadata
  double? get weightKg => throw _privateConstructorUsedError;
  double? get lengthCm => throw _privateConstructorUsedError;
  double? get widthCm => throw _privateConstructorUsedError;
  double? get heightCm => throw _privateConstructorUsedError;
  bool get isLocalDeliveryOnly => throw _privateConstructorUsedError;
  bool get isPerishable => throw _privateConstructorUsedError;
  int get estimatedShipDays => throw _privateConstructorUsedError;
  List<SellerDeliveryOption> get deliveryOptions =>
      throw _privateConstructorUsedError;
  int get minimumOrderQuantity => throw _privateConstructorUsedError;
  bool get freeShipping => throw _privateConstructorUsedError;
  bool get isDigital => throw _privateConstructorUsedError;

  /// Serializes this OrderItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderItemCopyWith<OrderItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderItemCopyWith<$Res> {
  factory $OrderItemCopyWith(OrderItem value, $Res Function(OrderItem) then) =
      _$OrderItemCopyWithImpl<$Res, OrderItem>;
  @useResult
  $Res call({
    String productId,
    String name,
    String description,
    double price,
    int quantity,
    List<String> imageUrls,
    String sellerId,
    Address sellerAddress,
    DeliveryStatus deliveryStatus,
    String? trackingNumber,
    bool confirmedByBuyer,
    double? weightKg,
    double? lengthCm,
    double? widthCm,
    double? heightCm,
    bool isLocalDeliveryOnly,
    bool isPerishable,
    int estimatedShipDays,
    List<SellerDeliveryOption> deliveryOptions,
    int minimumOrderQuantity,
    bool freeShipping,
    bool isDigital,
  });

  $AddressCopyWith<$Res> get sellerAddress;
}

/// @nodoc
class _$OrderItemCopyWithImpl<$Res, $Val extends OrderItem>
    implements $OrderItemCopyWith<$Res> {
  _$OrderItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productId = null,
    Object? name = null,
    Object? description = null,
    Object? price = null,
    Object? quantity = null,
    Object? imageUrls = null,
    Object? sellerId = null,
    Object? sellerAddress = null,
    Object? deliveryStatus = null,
    Object? trackingNumber = freezed,
    Object? confirmedByBuyer = null,
    Object? weightKg = freezed,
    Object? lengthCm = freezed,
    Object? widthCm = freezed,
    Object? heightCm = freezed,
    Object? isLocalDeliveryOnly = null,
    Object? isPerishable = null,
    Object? estimatedShipDays = null,
    Object? deliveryOptions = null,
    Object? minimumOrderQuantity = null,
    Object? freeShipping = null,
    Object? isDigital = null,
  }) {
    return _then(
      _value.copyWith(
            productId: null == productId
                ? _value.productId
                : productId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as double,
            quantity: null == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as int,
            imageUrls: null == imageUrls
                ? _value.imageUrls
                : imageUrls // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            sellerId: null == sellerId
                ? _value.sellerId
                : sellerId // ignore: cast_nullable_to_non_nullable
                      as String,
            sellerAddress: null == sellerAddress
                ? _value.sellerAddress
                : sellerAddress // ignore: cast_nullable_to_non_nullable
                      as Address,
            deliveryStatus: null == deliveryStatus
                ? _value.deliveryStatus
                : deliveryStatus // ignore: cast_nullable_to_non_nullable
                      as DeliveryStatus,
            trackingNumber: freezed == trackingNumber
                ? _value.trackingNumber
                : trackingNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            confirmedByBuyer: null == confirmedByBuyer
                ? _value.confirmedByBuyer
                : confirmedByBuyer // ignore: cast_nullable_to_non_nullable
                      as bool,
            weightKg: freezed == weightKg
                ? _value.weightKg
                : weightKg // ignore: cast_nullable_to_non_nullable
                      as double?,
            lengthCm: freezed == lengthCm
                ? _value.lengthCm
                : lengthCm // ignore: cast_nullable_to_non_nullable
                      as double?,
            widthCm: freezed == widthCm
                ? _value.widthCm
                : widthCm // ignore: cast_nullable_to_non_nullable
                      as double?,
            heightCm: freezed == heightCm
                ? _value.heightCm
                : heightCm // ignore: cast_nullable_to_non_nullable
                      as double?,
            isLocalDeliveryOnly: null == isLocalDeliveryOnly
                ? _value.isLocalDeliveryOnly
                : isLocalDeliveryOnly // ignore: cast_nullable_to_non_nullable
                      as bool,
            isPerishable: null == isPerishable
                ? _value.isPerishable
                : isPerishable // ignore: cast_nullable_to_non_nullable
                      as bool,
            estimatedShipDays: null == estimatedShipDays
                ? _value.estimatedShipDays
                : estimatedShipDays // ignore: cast_nullable_to_non_nullable
                      as int,
            deliveryOptions: null == deliveryOptions
                ? _value.deliveryOptions
                : deliveryOptions // ignore: cast_nullable_to_non_nullable
                      as List<SellerDeliveryOption>,
            minimumOrderQuantity: null == minimumOrderQuantity
                ? _value.minimumOrderQuantity
                : minimumOrderQuantity // ignore: cast_nullable_to_non_nullable
                      as int,
            freeShipping: null == freeShipping
                ? _value.freeShipping
                : freeShipping // ignore: cast_nullable_to_non_nullable
                      as bool,
            isDigital: null == isDigital
                ? _value.isDigital
                : isDigital // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AddressCopyWith<$Res> get sellerAddress {
    return $AddressCopyWith<$Res>(_value.sellerAddress, (value) {
      return _then(_value.copyWith(sellerAddress: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OrderItemImplCopyWith<$Res>
    implements $OrderItemCopyWith<$Res> {
  factory _$$OrderItemImplCopyWith(
    _$OrderItemImpl value,
    $Res Function(_$OrderItemImpl) then,
  ) = __$$OrderItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String productId,
    String name,
    String description,
    double price,
    int quantity,
    List<String> imageUrls,
    String sellerId,
    Address sellerAddress,
    DeliveryStatus deliveryStatus,
    String? trackingNumber,
    bool confirmedByBuyer,
    double? weightKg,
    double? lengthCm,
    double? widthCm,
    double? heightCm,
    bool isLocalDeliveryOnly,
    bool isPerishable,
    int estimatedShipDays,
    List<SellerDeliveryOption> deliveryOptions,
    int minimumOrderQuantity,
    bool freeShipping,
    bool isDigital,
  });

  @override
  $AddressCopyWith<$Res> get sellerAddress;
}

/// @nodoc
class __$$OrderItemImplCopyWithImpl<$Res>
    extends _$OrderItemCopyWithImpl<$Res, _$OrderItemImpl>
    implements _$$OrderItemImplCopyWith<$Res> {
  __$$OrderItemImplCopyWithImpl(
    _$OrderItemImpl _value,
    $Res Function(_$OrderItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productId = null,
    Object? name = null,
    Object? description = null,
    Object? price = null,
    Object? quantity = null,
    Object? imageUrls = null,
    Object? sellerId = null,
    Object? sellerAddress = null,
    Object? deliveryStatus = null,
    Object? trackingNumber = freezed,
    Object? confirmedByBuyer = null,
    Object? weightKg = freezed,
    Object? lengthCm = freezed,
    Object? widthCm = freezed,
    Object? heightCm = freezed,
    Object? isLocalDeliveryOnly = null,
    Object? isPerishable = null,
    Object? estimatedShipDays = null,
    Object? deliveryOptions = null,
    Object? minimumOrderQuantity = null,
    Object? freeShipping = null,
    Object? isDigital = null,
  }) {
    return _then(
      _$OrderItemImpl(
        productId: null == productId
            ? _value.productId
            : productId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        quantity: null == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as int,
        imageUrls: null == imageUrls
            ? _value._imageUrls
            : imageUrls // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        sellerId: null == sellerId
            ? _value.sellerId
            : sellerId // ignore: cast_nullable_to_non_nullable
                  as String,
        sellerAddress: null == sellerAddress
            ? _value.sellerAddress
            : sellerAddress // ignore: cast_nullable_to_non_nullable
                  as Address,
        deliveryStatus: null == deliveryStatus
            ? _value.deliveryStatus
            : deliveryStatus // ignore: cast_nullable_to_non_nullable
                  as DeliveryStatus,
        trackingNumber: freezed == trackingNumber
            ? _value.trackingNumber
            : trackingNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        confirmedByBuyer: null == confirmedByBuyer
            ? _value.confirmedByBuyer
            : confirmedByBuyer // ignore: cast_nullable_to_non_nullable
                  as bool,
        weightKg: freezed == weightKg
            ? _value.weightKg
            : weightKg // ignore: cast_nullable_to_non_nullable
                  as double?,
        lengthCm: freezed == lengthCm
            ? _value.lengthCm
            : lengthCm // ignore: cast_nullable_to_non_nullable
                  as double?,
        widthCm: freezed == widthCm
            ? _value.widthCm
            : widthCm // ignore: cast_nullable_to_non_nullable
                  as double?,
        heightCm: freezed == heightCm
            ? _value.heightCm
            : heightCm // ignore: cast_nullable_to_non_nullable
                  as double?,
        isLocalDeliveryOnly: null == isLocalDeliveryOnly
            ? _value.isLocalDeliveryOnly
            : isLocalDeliveryOnly // ignore: cast_nullable_to_non_nullable
                  as bool,
        isPerishable: null == isPerishable
            ? _value.isPerishable
            : isPerishable // ignore: cast_nullable_to_non_nullable
                  as bool,
        estimatedShipDays: null == estimatedShipDays
            ? _value.estimatedShipDays
            : estimatedShipDays // ignore: cast_nullable_to_non_nullable
                  as int,
        deliveryOptions: null == deliveryOptions
            ? _value._deliveryOptions
            : deliveryOptions // ignore: cast_nullable_to_non_nullable
                  as List<SellerDeliveryOption>,
        minimumOrderQuantity: null == minimumOrderQuantity
            ? _value.minimumOrderQuantity
            : minimumOrderQuantity // ignore: cast_nullable_to_non_nullable
                  as int,
        freeShipping: null == freeShipping
            ? _value.freeShipping
            : freeShipping // ignore: cast_nullable_to_non_nullable
                  as bool,
        isDigital: null == isDigital
            ? _value.isDigital
            : isDigital // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderItemImpl extends _OrderItem {
  const _$OrderItemImpl({
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required final List<String> imageUrls,
    required this.sellerId,
    required this.sellerAddress,
    this.deliveryStatus = DeliveryStatus.pending,
    this.trackingNumber,
    this.confirmedByBuyer = false,
    this.weightKg,
    this.lengthCm,
    this.widthCm,
    this.heightCm,
    this.isLocalDeliveryOnly = false,
    this.isPerishable = false,
    this.estimatedShipDays = 3,
    final List<SellerDeliveryOption> deliveryOptions = const [],
    this.minimumOrderQuantity = 1,
    this.freeShipping = false,
    this.isDigital = false,
  }) : _imageUrls = imageUrls,
       _deliveryOptions = deliveryOptions,
       super._();

  factory _$OrderItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderItemImplFromJson(json);

  @override
  final String productId;
  @override
  final String name;
  @override
  final String description;
  @override
  final double price;
  @override
  final int quantity;
  final List<String> _imageUrls;
  @override
  List<String> get imageUrls {
    if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_imageUrls);
  }

  @override
  final String sellerId;
  @override
  final Address sellerAddress;
  @override
  @JsonKey()
  final DeliveryStatus deliveryStatus;
  @override
  final String? trackingNumber;
  @override
  @JsonKey()
  final bool confirmedByBuyer;
  // Shipping metadata
  @override
  final double? weightKg;
  @override
  final double? lengthCm;
  @override
  final double? widthCm;
  @override
  final double? heightCm;
  @override
  @JsonKey()
  final bool isLocalDeliveryOnly;
  @override
  @JsonKey()
  final bool isPerishable;
  @override
  @JsonKey()
  final int estimatedShipDays;
  final List<SellerDeliveryOption> _deliveryOptions;
  @override
  @JsonKey()
  List<SellerDeliveryOption> get deliveryOptions {
    if (_deliveryOptions is EqualUnmodifiableListView) return _deliveryOptions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_deliveryOptions);
  }

  @override
  @JsonKey()
  final int minimumOrderQuantity;
  @override
  @JsonKey()
  final bool freeShipping;
  @override
  @JsonKey()
  final bool isDigital;

  @override
  String toString() {
    return 'OrderItem(productId: $productId, name: $name, description: $description, price: $price, quantity: $quantity, imageUrls: $imageUrls, sellerId: $sellerId, sellerAddress: $sellerAddress, deliveryStatus: $deliveryStatus, trackingNumber: $trackingNumber, confirmedByBuyer: $confirmedByBuyer, weightKg: $weightKg, lengthCm: $lengthCm, widthCm: $widthCm, heightCm: $heightCm, isLocalDeliveryOnly: $isLocalDeliveryOnly, isPerishable: $isPerishable, estimatedShipDays: $estimatedShipDays, deliveryOptions: $deliveryOptions, minimumOrderQuantity: $minimumOrderQuantity, freeShipping: $freeShipping, isDigital: $isDigital)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderItemImpl &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            const DeepCollectionEquality().equals(
              other._imageUrls,
              _imageUrls,
            ) &&
            (identical(other.sellerId, sellerId) ||
                other.sellerId == sellerId) &&
            (identical(other.sellerAddress, sellerAddress) ||
                other.sellerAddress == sellerAddress) &&
            (identical(other.deliveryStatus, deliveryStatus) ||
                other.deliveryStatus == deliveryStatus) &&
            (identical(other.trackingNumber, trackingNumber) ||
                other.trackingNumber == trackingNumber) &&
            (identical(other.confirmedByBuyer, confirmedByBuyer) ||
                other.confirmedByBuyer == confirmedByBuyer) &&
            (identical(other.weightKg, weightKg) ||
                other.weightKg == weightKg) &&
            (identical(other.lengthCm, lengthCm) ||
                other.lengthCm == lengthCm) &&
            (identical(other.widthCm, widthCm) || other.widthCm == widthCm) &&
            (identical(other.heightCm, heightCm) ||
                other.heightCm == heightCm) &&
            (identical(other.isLocalDeliveryOnly, isLocalDeliveryOnly) ||
                other.isLocalDeliveryOnly == isLocalDeliveryOnly) &&
            (identical(other.isPerishable, isPerishable) ||
                other.isPerishable == isPerishable) &&
            (identical(other.estimatedShipDays, estimatedShipDays) ||
                other.estimatedShipDays == estimatedShipDays) &&
            const DeepCollectionEquality().equals(
              other._deliveryOptions,
              _deliveryOptions,
            ) &&
            (identical(other.minimumOrderQuantity, minimumOrderQuantity) ||
                other.minimumOrderQuantity == minimumOrderQuantity) &&
            (identical(other.freeShipping, freeShipping) ||
                other.freeShipping == freeShipping) &&
            (identical(other.isDigital, isDigital) ||
                other.isDigital == isDigital));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    productId,
    name,
    description,
    price,
    quantity,
    const DeepCollectionEquality().hash(_imageUrls),
    sellerId,
    sellerAddress,
    deliveryStatus,
    trackingNumber,
    confirmedByBuyer,
    weightKg,
    lengthCm,
    widthCm,
    heightCm,
    isLocalDeliveryOnly,
    isPerishable,
    estimatedShipDays,
    const DeepCollectionEquality().hash(_deliveryOptions),
    minimumOrderQuantity,
    freeShipping,
    isDigital,
  ]);

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderItemImplCopyWith<_$OrderItemImpl> get copyWith =>
      __$$OrderItemImplCopyWithImpl<_$OrderItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderItemImplToJson(this);
  }
}

abstract class _OrderItem extends OrderItem {
  const factory _OrderItem({
    required final String productId,
    required final String name,
    required final String description,
    required final double price,
    required final int quantity,
    required final List<String> imageUrls,
    required final String sellerId,
    required final Address sellerAddress,
    final DeliveryStatus deliveryStatus,
    final String? trackingNumber,
    final bool confirmedByBuyer,
    final double? weightKg,
    final double? lengthCm,
    final double? widthCm,
    final double? heightCm,
    final bool isLocalDeliveryOnly,
    final bool isPerishable,
    final int estimatedShipDays,
    final List<SellerDeliveryOption> deliveryOptions,
    final int minimumOrderQuantity,
    final bool freeShipping,
    final bool isDigital,
  }) = _$OrderItemImpl;
  const _OrderItem._() : super._();

  factory _OrderItem.fromJson(Map<String, dynamic> json) =
      _$OrderItemImpl.fromJson;

  @override
  String get productId;
  @override
  String get name;
  @override
  String get description;
  @override
  double get price;
  @override
  int get quantity;
  @override
  List<String> get imageUrls;
  @override
  String get sellerId;
  @override
  Address get sellerAddress;
  @override
  DeliveryStatus get deliveryStatus;
  @override
  String? get trackingNumber;
  @override
  bool get confirmedByBuyer; // Shipping metadata
  @override
  double? get weightKg;
  @override
  double? get lengthCm;
  @override
  double? get widthCm;
  @override
  double? get heightCm;
  @override
  bool get isLocalDeliveryOnly;
  @override
  bool get isPerishable;
  @override
  int get estimatedShipDays;
  @override
  List<SellerDeliveryOption> get deliveryOptions;
  @override
  int get minimumOrderQuantity;
  @override
  bool get freeShipping;
  @override
  bool get isDigital;

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderItemImplCopyWith<_$OrderItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Ratings _$RatingsFromJson(Map<String, dynamic> json) {
  return _Ratings.fromJson(json);
}

/// @nodoc
mixin _$Ratings {
  String get productId => throw _privateConstructorUsedError;
  double get rating => throw _privateConstructorUsedError;
  String? get review => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Ratings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Ratings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RatingsCopyWith<Ratings> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RatingsCopyWith<$Res> {
  factory $RatingsCopyWith(Ratings value, $Res Function(Ratings) then) =
      _$RatingsCopyWithImpl<$Res, Ratings>;
  @useResult
  $Res call({
    String productId,
    double rating,
    String? review,
    DateTime createdAt,
  });
}

/// @nodoc
class _$RatingsCopyWithImpl<$Res, $Val extends Ratings>
    implements $RatingsCopyWith<$Res> {
  _$RatingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Ratings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productId = null,
    Object? rating = null,
    Object? review = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            productId: null == productId
                ? _value.productId
                : productId // ignore: cast_nullable_to_non_nullable
                      as String,
            rating: null == rating
                ? _value.rating
                : rating // ignore: cast_nullable_to_non_nullable
                      as double,
            review: freezed == review
                ? _value.review
                : review // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RatingsImplCopyWith<$Res> implements $RatingsCopyWith<$Res> {
  factory _$$RatingsImplCopyWith(
    _$RatingsImpl value,
    $Res Function(_$RatingsImpl) then,
  ) = __$$RatingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String productId,
    double rating,
    String? review,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$RatingsImplCopyWithImpl<$Res>
    extends _$RatingsCopyWithImpl<$Res, _$RatingsImpl>
    implements _$$RatingsImplCopyWith<$Res> {
  __$$RatingsImplCopyWithImpl(
    _$RatingsImpl _value,
    $Res Function(_$RatingsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Ratings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productId = null,
    Object? rating = null,
    Object? review = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$RatingsImpl(
        productId: null == productId
            ? _value.productId
            : productId // ignore: cast_nullable_to_non_nullable
                  as String,
        rating: null == rating
            ? _value.rating
            : rating // ignore: cast_nullable_to_non_nullable
                  as double,
        review: freezed == review
            ? _value.review
            : review // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RatingsImpl implements _Ratings {
  const _$RatingsImpl({
    required this.productId,
    required this.rating,
    this.review,
    required this.createdAt,
  });

  factory _$RatingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$RatingsImplFromJson(json);

  @override
  final String productId;
  @override
  final double rating;
  @override
  final String? review;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'Ratings(productId: $productId, rating: $rating, review: $review, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RatingsImpl &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.review, review) || other.review == review) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, productId, rating, review, createdAt);

  /// Create a copy of Ratings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RatingsImplCopyWith<_$RatingsImpl> get copyWith =>
      __$$RatingsImplCopyWithImpl<_$RatingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RatingsImplToJson(this);
  }
}

abstract class _Ratings implements Ratings {
  const factory _Ratings({
    required final String productId,
    required final double rating,
    final String? review,
    required final DateTime createdAt,
  }) = _$RatingsImpl;

  factory _Ratings.fromJson(Map<String, dynamic> json) = _$RatingsImpl.fromJson;

  @override
  String get productId;
  @override
  double get rating;
  @override
  String? get review;
  @override
  DateTime get createdAt;

  /// Create a copy of Ratings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RatingsImplCopyWith<_$RatingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SellerPayout _$SellerPayoutFromJson(Map<String, dynamic> json) {
  return _SellerPayout.fromJson(json);
}

/// @nodoc
mixin _$SellerPayout {
  String get sellerId => throw _privateConstructorUsedError;
  String? get stripeAccountId => throw _privateConstructorUsedError;
  int get amountCents => throw _privateConstructorUsedError;
  int get platformFeeCents => throw _privateConstructorUsedError;
  int get netAmountCents => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime? get payoutDate => throw _privateConstructorUsedError;
  String? get stripeTransferId => throw _privateConstructorUsedError;
  String? get failureReason => throw _privateConstructorUsedError;

  /// Serializes this SellerPayout to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SellerPayout
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SellerPayoutCopyWith<SellerPayout> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SellerPayoutCopyWith<$Res> {
  factory $SellerPayoutCopyWith(
    SellerPayout value,
    $Res Function(SellerPayout) then,
  ) = _$SellerPayoutCopyWithImpl<$Res, SellerPayout>;
  @useResult
  $Res call({
    String sellerId,
    String? stripeAccountId,
    int amountCents,
    int platformFeeCents,
    int netAmountCents,
    String status,
    DateTime? payoutDate,
    String? stripeTransferId,
    String? failureReason,
  });
}

/// @nodoc
class _$SellerPayoutCopyWithImpl<$Res, $Val extends SellerPayout>
    implements $SellerPayoutCopyWith<$Res> {
  _$SellerPayoutCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SellerPayout
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sellerId = null,
    Object? stripeAccountId = freezed,
    Object? amountCents = null,
    Object? platformFeeCents = null,
    Object? netAmountCents = null,
    Object? status = null,
    Object? payoutDate = freezed,
    Object? stripeTransferId = freezed,
    Object? failureReason = freezed,
  }) {
    return _then(
      _value.copyWith(
            sellerId: null == sellerId
                ? _value.sellerId
                : sellerId // ignore: cast_nullable_to_non_nullable
                      as String,
            stripeAccountId: freezed == stripeAccountId
                ? _value.stripeAccountId
                : stripeAccountId // ignore: cast_nullable_to_non_nullable
                      as String?,
            amountCents: null == amountCents
                ? _value.amountCents
                : amountCents // ignore: cast_nullable_to_non_nullable
                      as int,
            platformFeeCents: null == platformFeeCents
                ? _value.platformFeeCents
                : platformFeeCents // ignore: cast_nullable_to_non_nullable
                      as int,
            netAmountCents: null == netAmountCents
                ? _value.netAmountCents
                : netAmountCents // ignore: cast_nullable_to_non_nullable
                      as int,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            payoutDate: freezed == payoutDate
                ? _value.payoutDate
                : payoutDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            stripeTransferId: freezed == stripeTransferId
                ? _value.stripeTransferId
                : stripeTransferId // ignore: cast_nullable_to_non_nullable
                      as String?,
            failureReason: freezed == failureReason
                ? _value.failureReason
                : failureReason // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SellerPayoutImplCopyWith<$Res>
    implements $SellerPayoutCopyWith<$Res> {
  factory _$$SellerPayoutImplCopyWith(
    _$SellerPayoutImpl value,
    $Res Function(_$SellerPayoutImpl) then,
  ) = __$$SellerPayoutImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String sellerId,
    String? stripeAccountId,
    int amountCents,
    int platformFeeCents,
    int netAmountCents,
    String status,
    DateTime? payoutDate,
    String? stripeTransferId,
    String? failureReason,
  });
}

/// @nodoc
class __$$SellerPayoutImplCopyWithImpl<$Res>
    extends _$SellerPayoutCopyWithImpl<$Res, _$SellerPayoutImpl>
    implements _$$SellerPayoutImplCopyWith<$Res> {
  __$$SellerPayoutImplCopyWithImpl(
    _$SellerPayoutImpl _value,
    $Res Function(_$SellerPayoutImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SellerPayout
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sellerId = null,
    Object? stripeAccountId = freezed,
    Object? amountCents = null,
    Object? platformFeeCents = null,
    Object? netAmountCents = null,
    Object? status = null,
    Object? payoutDate = freezed,
    Object? stripeTransferId = freezed,
    Object? failureReason = freezed,
  }) {
    return _then(
      _$SellerPayoutImpl(
        sellerId: null == sellerId
            ? _value.sellerId
            : sellerId // ignore: cast_nullable_to_non_nullable
                  as String,
        stripeAccountId: freezed == stripeAccountId
            ? _value.stripeAccountId
            : stripeAccountId // ignore: cast_nullable_to_non_nullable
                  as String?,
        amountCents: null == amountCents
            ? _value.amountCents
            : amountCents // ignore: cast_nullable_to_non_nullable
                  as int,
        platformFeeCents: null == platformFeeCents
            ? _value.platformFeeCents
            : platformFeeCents // ignore: cast_nullable_to_non_nullable
                  as int,
        netAmountCents: null == netAmountCents
            ? _value.netAmountCents
            : netAmountCents // ignore: cast_nullable_to_non_nullable
                  as int,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        payoutDate: freezed == payoutDate
            ? _value.payoutDate
            : payoutDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        stripeTransferId: freezed == stripeTransferId
            ? _value.stripeTransferId
            : stripeTransferId // ignore: cast_nullable_to_non_nullable
                  as String?,
        failureReason: freezed == failureReason
            ? _value.failureReason
            : failureReason // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SellerPayoutImpl extends _SellerPayout {
  const _$SellerPayoutImpl({
    required this.sellerId,
    this.stripeAccountId,
    required this.amountCents,
    required this.platformFeeCents,
    required this.netAmountCents,
    this.status = 'pending',
    this.payoutDate,
    this.stripeTransferId,
    this.failureReason,
  }) : super._();

  factory _$SellerPayoutImpl.fromJson(Map<String, dynamic> json) =>
      _$$SellerPayoutImplFromJson(json);

  @override
  final String sellerId;
  @override
  final String? stripeAccountId;
  @override
  final int amountCents;
  @override
  final int platformFeeCents;
  @override
  final int netAmountCents;
  @override
  @JsonKey()
  final String status;
  @override
  final DateTime? payoutDate;
  @override
  final String? stripeTransferId;
  @override
  final String? failureReason;

  @override
  String toString() {
    return 'SellerPayout(sellerId: $sellerId, stripeAccountId: $stripeAccountId, amountCents: $amountCents, platformFeeCents: $platformFeeCents, netAmountCents: $netAmountCents, status: $status, payoutDate: $payoutDate, stripeTransferId: $stripeTransferId, failureReason: $failureReason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SellerPayoutImpl &&
            (identical(other.sellerId, sellerId) ||
                other.sellerId == sellerId) &&
            (identical(other.stripeAccountId, stripeAccountId) ||
                other.stripeAccountId == stripeAccountId) &&
            (identical(other.amountCents, amountCents) ||
                other.amountCents == amountCents) &&
            (identical(other.platformFeeCents, platformFeeCents) ||
                other.platformFeeCents == platformFeeCents) &&
            (identical(other.netAmountCents, netAmountCents) ||
                other.netAmountCents == netAmountCents) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.payoutDate, payoutDate) ||
                other.payoutDate == payoutDate) &&
            (identical(other.stripeTransferId, stripeTransferId) ||
                other.stripeTransferId == stripeTransferId) &&
            (identical(other.failureReason, failureReason) ||
                other.failureReason == failureReason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    sellerId,
    stripeAccountId,
    amountCents,
    platformFeeCents,
    netAmountCents,
    status,
    payoutDate,
    stripeTransferId,
    failureReason,
  );

  /// Create a copy of SellerPayout
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SellerPayoutImplCopyWith<_$SellerPayoutImpl> get copyWith =>
      __$$SellerPayoutImplCopyWithImpl<_$SellerPayoutImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SellerPayoutImplToJson(this);
  }
}

abstract class _SellerPayout extends SellerPayout {
  const factory _SellerPayout({
    required final String sellerId,
    final String? stripeAccountId,
    required final int amountCents,
    required final int platformFeeCents,
    required final int netAmountCents,
    final String status,
    final DateTime? payoutDate,
    final String? stripeTransferId,
    final String? failureReason,
  }) = _$SellerPayoutImpl;
  const _SellerPayout._() : super._();

  factory _SellerPayout.fromJson(Map<String, dynamic> json) =
      _$SellerPayoutImpl.fromJson;

  @override
  String get sellerId;
  @override
  String? get stripeAccountId;
  @override
  int get amountCents;
  @override
  int get platformFeeCents;
  @override
  int get netAmountCents;
  @override
  String get status;
  @override
  DateTime? get payoutDate;
  @override
  String? get stripeTransferId;
  @override
  String? get failureReason;

  /// Create a copy of SellerPayout
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SellerPayoutImplCopyWith<_$SellerPayoutImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Taxes {
  double get gst => throw _privateConstructorUsedError;
  double get pst => throw _privateConstructorUsedError;
  double get hst => throw _privateConstructorUsedError;
  double get qst => throw _privateConstructorUsedError;

  /// Create a copy of Taxes
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaxesCopyWith<Taxes> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaxesCopyWith<$Res> {
  factory $TaxesCopyWith(Taxes value, $Res Function(Taxes) then) =
      _$TaxesCopyWithImpl<$Res, Taxes>;
  @useResult
  $Res call({double gst, double pst, double hst, double qst});
}

/// @nodoc
class _$TaxesCopyWithImpl<$Res, $Val extends Taxes>
    implements $TaxesCopyWith<$Res> {
  _$TaxesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Taxes
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gst = null,
    Object? pst = null,
    Object? hst = null,
    Object? qst = null,
  }) {
    return _then(
      _value.copyWith(
            gst: null == gst
                ? _value.gst
                : gst // ignore: cast_nullable_to_non_nullable
                      as double,
            pst: null == pst
                ? _value.pst
                : pst // ignore: cast_nullable_to_non_nullable
                      as double,
            hst: null == hst
                ? _value.hst
                : hst // ignore: cast_nullable_to_non_nullable
                      as double,
            qst: null == qst
                ? _value.qst
                : qst // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TaxesImplCopyWith<$Res> implements $TaxesCopyWith<$Res> {
  factory _$$TaxesImplCopyWith(
    _$TaxesImpl value,
    $Res Function(_$TaxesImpl) then,
  ) = __$$TaxesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double gst, double pst, double hst, double qst});
}

/// @nodoc
class __$$TaxesImplCopyWithImpl<$Res>
    extends _$TaxesCopyWithImpl<$Res, _$TaxesImpl>
    implements _$$TaxesImplCopyWith<$Res> {
  __$$TaxesImplCopyWithImpl(
    _$TaxesImpl _value,
    $Res Function(_$TaxesImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Taxes
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gst = null,
    Object? pst = null,
    Object? hst = null,
    Object? qst = null,
  }) {
    return _then(
      _$TaxesImpl(
        gst: null == gst
            ? _value.gst
            : gst // ignore: cast_nullable_to_non_nullable
                  as double,
        pst: null == pst
            ? _value.pst
            : pst // ignore: cast_nullable_to_non_nullable
                  as double,
        hst: null == hst
            ? _value.hst
            : hst // ignore: cast_nullable_to_non_nullable
                  as double,
        qst: null == qst
            ? _value.qst
            : qst // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class _$TaxesImpl extends _Taxes {
  const _$TaxesImpl({
    this.gst = 0.0,
    this.pst = 0.0,
    this.hst = 0.0,
    this.qst = 0.0,
  }) : super._();

  @override
  @JsonKey()
  final double gst;
  @override
  @JsonKey()
  final double pst;
  @override
  @JsonKey()
  final double hst;
  @override
  @JsonKey()
  final double qst;

  @override
  String toString() {
    return 'Taxes(gst: $gst, pst: $pst, hst: $hst, qst: $qst)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaxesImpl &&
            (identical(other.gst, gst) || other.gst == gst) &&
            (identical(other.pst, pst) || other.pst == pst) &&
            (identical(other.hst, hst) || other.hst == hst) &&
            (identical(other.qst, qst) || other.qst == qst));
  }

  @override
  int get hashCode => Object.hash(runtimeType, gst, pst, hst, qst);

  /// Create a copy of Taxes
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaxesImplCopyWith<_$TaxesImpl> get copyWith =>
      __$$TaxesImplCopyWithImpl<_$TaxesImpl>(this, _$identity);
}

abstract class _Taxes extends Taxes {
  const factory _Taxes({
    final double gst,
    final double pst,
    final double hst,
    final double qst,
  }) = _$TaxesImpl;
  const _Taxes._() : super._();

  @override
  double get gst;
  @override
  double get pst;
  @override
  double get hst;
  @override
  double get qst;

  /// Create a copy of Taxes
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaxesImplCopyWith<_$TaxesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
