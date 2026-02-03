import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/order_repository.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/utils.dart';

/// StateNotifierProvider for checkout
final checkoutStateProvider = StateNotifierProvider.autoDispose<CheckoutNotifier, CheckoutState>((ref) {
  return CheckoutNotifier(ref);
});

/// Computed provider for tax rate based on address
final checkoutTaxRateProvider = Provider.autoDispose<double>((ref) {
  final checkoutState = ref.watch(checkoutStateProvider);
  if (checkoutState.address == null) return 0.13; // Default Ontario HST
  return getTaxRate(checkoutState.address!.state);
});

/// Computed provider for checkout total
final checkoutTotalProvider = Provider.autoDispose<double>((ref) {
  final checkoutState = ref.watch(checkoutStateProvider);
  final subtotal = ref.watch(cartSubtotalProvider);
  return subtotal + checkoutState.taxAmount + checkoutState.shippingCost;
});

class CheckoutAlreadyProcessed extends CheckoutResult {
  final String existingOrderId;

  CheckoutAlreadyProcessed({required this.existingOrderId});
}

class CheckoutError extends CheckoutResult {
  final String message;
  final String? code;

  CheckoutError({required this.message, this.code});
}

// ============================================================================
// CHECKOUT NOTIFIER
// ============================================================================

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final Ref _ref;

  CheckoutNotifier(this._ref) : super(const CheckoutState());

  OrderRepository get _orderRepository => _ref.read(orderRepositoryProvider);
  String? get _userId => _ref.read(userIdProvider);
  UserRepository get _userRepository => _ref.read(userRepositoryProvider);

  /// Calculate shipping cost for cart items and determine available delivery options
  Future<void> calculateShipping(List<CartItemDetailModel> items) async {
    if (items.isEmpty) {
      state = state.copyWith(shippingError: 'No items to ship');
      return;
    }

    final hasPhysicalItems = items.any((item) => !item.isDigital);
    if (state.address == null) {
      if (!hasPhysicalItems) {
        state = state.copyWith(
          baseShippingCost: 0,
          isLocalDelivery: false,
          availableDeliverySpeeds: const [],
          deliverySpeed: DeliverySpeed.standard,
          isCalculatingShipping: false,
          clearShippingError: true,
        );
        return;
      }
      state = state.copyWith(shippingError: 'No address found');
      return;
    }
    if (!hasPhysicalItems) {
      state = state.copyWith(
        baseShippingCost: 0,
        isLocalDelivery: false,
        availableDeliverySpeeds: const [],
        deliverySpeed: DeliverySpeed.standard,
        isCalculatingShipping: false,
        clearShippingError: true,
      );
      return;
    }

    state = state.copyWith(isCalculatingShipping: true, clearShippingError: true);

    try {
      final cost = await calculateShippingCost(items, state.address);

      // Determine if local delivery (check if any seller is within ~50km)
      final isLocal = await _checkLocalDelivery(items, state.address!);

      // Build delivery item checks from cart items
      final itemChecks = items
          .map((item) => DeliveryItemCheck(estimatedShipDays: item.estimatedShipDays, isPerishable: item.isPerishable, isLocalOnly: item.isLocalDeliveryOnly))
          .toList();

      // Determine available delivery speeds
      final availableSpeeds = DeliverySpeed.values.where((speed) => speed.isAvailableForItems(itemChecks, isLocal)).toList();

      state = state.copyWith(
        baseShippingCost: cost,
        isLocalDelivery: isLocal,
        availableDeliverySpeeds: availableSpeeds,
        deliverySpeed: DeliverySpeed.standard,
        isCalculatingShipping: false,
      );
    } catch (e) {
      state = state.copyWith(shippingError: 'Failed to calculate shipping', isCalculatingShipping: false);
    }
  }

  /// Calculate taxes based on address
  void calculateTaxes(double subtotal) {
    if (state.address == null) return;

    final taxes = calculateDetailedTaxes(state.address, subtotal);
    state = state.copyWith(taxBreakdown: taxes);
  }

  /// Initialize checkout with user's address
  Future<void> initialize() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final user = await _userRepository.getUserProfile(userId);
      if (user?.address != null) {
        state = state.copyWith(address: user!.address);
      }
    } catch (e) {
      debugPrint('Error initializing checkout: $e');
    }
  }

  /// Reset checkout state
  void reset() {
    state = const CheckoutState();
  }

  /// Update selected delivery speed
  void setDeliverySpeed(DeliverySpeed speed) {
    if (state.availableDeliverySpeeds.contains(speed)) {
      state = state.copyWith(deliverySpeed: speed);
    }
  }

  void setPaymentProvider(String provider) {
    if (provider == 'stripe' || provider == 'airwallex') {
      state = state.copyWith(paymentProvider: provider);
    }
  }

  /// Start Stripe checkout with idempotency
  Future<CheckoutResult> startCheckout({required List<CartItemDetailModel> items, required UserModel user, required double subtotal}) async {
    if (items.isEmpty) {
      return CheckoutError(message: 'Your cart is empty');
    }

    final hasPhysicalItems = items.any((item) => !item.isDigital);
    if (hasPhysicalItems && !hasValidAddress(state.address)) {
      return CheckoutError(message: 'Delivery address is required');
    }

    if (subtotal <= 0) {
      return CheckoutError(message: 'Invalid order total');
    }

    if (user.email.trim().isEmpty) {
      return CheckoutError(message: 'Missing customer email');
    }

    // EMAIL VERIFICATION CHECK - CRITICAL BUSINESS LOGIC
    // Prevent checkout if email is not verified
    try {
      final authRepository = _ref.read(authRepositoryProvider);
      final isEmailVerified = await authRepository.isEmailVerified();

      if (!isEmailVerified) {
        return CheckoutError(message: 'Please verify your email before checkout', code: 'email-not-verified');
      }
    } catch (e) {
      debugPrint('⚠️  Error checking email verification: $e');
      // Don't block checkout if we can't verify, but log it
    }

    if (state.isProcessing) {
      return CheckoutError(message: 'Checkout already in progress');
    }

    state = state.copyWith(isProcessing: true, clearCheckoutError: true);

    try {
      final userId = _userId;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Generate a per-attempt key (random). Reuse on retry after a failure.
      final idempotencyKey = state.idempotencyKey ?? _generateIdempotencyKey(userId);
      state = state.copyWith(idempotencyKey: idempotencyKey);

      final taxes = hasPhysicalItems && state.address != null ? calculateDetailedTaxes(state.address, subtotal) : <String, double>{};
      final tax = taxes.values.fold(0.0, (acc, v) => acc + v);
      final totalWithTax = subtotal + tax + state.shippingCost;
      final sellerIds = items.map((item) => item.sellerId).toSet().toList();

      final orderData = {
        'userId': userId,
        'customerId': user.customerId ?? '',
        'customerEmail': user.email,
        'items': items
            .map(
              (item) => {
                'sellerId': item.sellerId,
                'productId': item.productId,
                'name': item.name,
                'description': item.description,
                'price': item.price,
                'quantity': item.quantity,
                'imageUrls': item.imageUrls,
                'isDigital': item.isDigital,
              },
            )
            .toList(),
        'total': totalWithTax,
        'taxes': taxes,
        'shippingCost': state.shippingCost,
        'subtotal': subtotal,
        'deliveryInfo': state.address?.toMap(),
        'currency': 'cad',
        'amount': (totalWithTax * 100).toInt(),
        'sellerIds': sellerIds,
        'idempotencyKey': idempotencyKey,
        'deliverySpeed': state.deliverySpeed.value,
        'paymentProvider': state.paymentProvider,
      };

      debugPrint('Sending checkout request with idempotency key: $idempotencyKey');

      final result = await _orderRepository.createCheckoutSession(orderData);

      final checkoutUrl = result['url'] as String;
      final orderId = result['orderId'] as String;
      final sessionId = result['sessionId'] as String;

      await _orderRepository.updateLastSession(userId, sessionId, orderId);

      state = state.copyWith(isProcessing: false, clearIdempotencyKey: true);

      return CheckoutSuccess(checkoutUrl: checkoutUrl, orderId: orderId, sessionId: sessionId);
    } catch (e) {
      debugPrint('Checkout error: $e');
      state = state.copyWith(isProcessing: false, checkoutError: AppError.getMessage(e));
      return CheckoutError(message: AppError.getMessage(e));
    }
  }

  /// Update address and recalculate shipping
  void updateAddress(Address address) {
    // New address = new checkout attempt context
    state = state.copyWith(address: address, clearIdempotencyKey: true);
  }

  double _atan2(double y, double x) => _taylorAtan2(y, x);

  /// Calculate distance between two coordinates in km (Haversine formula)
  double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = _sin(dLat / 2) * _sin(dLat / 2) + _cos(_toRadians(lat1)) * _cos(_toRadians(lat2)) * _sin(dLon / 2) * _sin(dLon / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

    return earthRadiusKm * c;
  }

  /// Check if buyer is within local delivery range (~50km) of sellers
  Future<bool> _checkLocalDelivery(List<CartItemDetailModel> items, Address buyerAddress) async {
    if (buyerAddress.latitude == null || buyerAddress.longitude == null) {
      return false;
    }

    // Check if all sellers are within local range
    for (final item in items) {
      final sellerAddr = item.sellerAddress;
      if (sellerAddr.latitude == null || sellerAddr.longitude == null) {
        return false;
      }

      // Simple distance check using Haversine approximation
      final distance = _calculateDistanceKm(buyerAddress.latitude!, buyerAddress.longitude!, sellerAddr.latitude!, sellerAddr.longitude!);

      if (distance > 50) {
        return false; // Not local if any seller is > 50km away
      }
    }
    return true;
  }

  double _cos(double x) => _taylorSin(x + 1.5707963267948966);

  /// Generate per-attempt idempotency key for payment safety.
  ///
  /// - Random per attempt (prevents blocking legitimate repeat purchases)
  /// - Stored in state so immediate retries reuse the same key
  String _generateIdempotencyKey(String userId) {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final nonce = base64UrlEncode(bytes).replaceAll('=', '');
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'chk_${userId}_${ts}_$nonce';
  }

  double _newtonSqrt(double x) {
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _sin(double x) => _taylorSin(x);

  double _sqrt(double x) => x <= 0 ? 0 : _newtonSqrt(x);

  double _taylorAtan(double x) {
    if (x > 1) return 1.5707963267948966 - _taylorAtan(1 / x);
    if (x < -1) return -1.5707963267948966 - _taylorAtan(1 / x);
    double result = x;
    double term = x;
    for (int i = 1; i <= 20; i++) {
      term *= -x * x;
      result += term / (2 * i + 1);
    }
    return result;
  }

  double _taylorAtan2(double y, double x) {
    if (x > 0) return _taylorAtan(y / x);
    if (x < 0 && y >= 0) return _taylorAtan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _taylorAtan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 1.5707963267948966;
    if (x == 0 && y < 0) return -1.5707963267948966;
    return 0;
  }

  // Taylor series approximations for math functions
  double _taylorSin(double x) {
    x = x % 6.283185307179586;
    if (x > 3.141592653589793) x -= 6.283185307179586;
    if (x < -3.141592653589793) x += 6.283185307179586;
    double result = x;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  double _toRadians(double deg) => deg * 3.141592653589793 / 180;
}

// ============================================================================
// PROVIDERS
// ============================================================================

// ============================================================================
// CHECKOUT RESULT
// ============================================================================

sealed class CheckoutResult {}

// ============================================================================
// CHECKOUT STATE
// ============================================================================

@immutable
class CheckoutState {
  final Address? address;
  final double baseShippingCost; // Base shipping before delivery speed surcharge
  final DeliverySpeed deliverySpeed;
  final List<DeliverySpeed> availableDeliverySpeeds;
  final bool isLocalDelivery; // Within ~50km of seller
  final Map<String, double> taxBreakdown;
  final bool isCalculatingShipping;
  final String? shippingError;
  final bool isProcessing;
  final String? idempotencyKey;
  final String? checkoutError;
  final String paymentProvider;

  const CheckoutState({
    this.address,
    this.baseShippingCost = 0.0,
    this.deliverySpeed = DeliverySpeed.standard,
    this.availableDeliverySpeeds = const [DeliverySpeed.standard],
    this.isLocalDelivery = false,
    this.taxBreakdown = const {},
    this.isCalculatingShipping = false,
    this.shippingError,
    this.isProcessing = false,
    this.idempotencyKey,
    this.checkoutError,
    this.paymentProvider = 'stripe',
  });

  /// Total shipping cost including delivery speed surcharge
  /// Standard (free) uses base cost, express/same-day add surcharge
  double get shippingCost {
    if (deliverySpeed == DeliverySpeed.standard) {
      return baseShippingCost;
    }
    return baseShippingCost + deliverySpeed.baseSurcharge;
  }

  double get taxAmount => taxBreakdown.values.fold(0.0, (total, v) => total + v);

  CheckoutState copyWith({
    Address? address,
    double? baseShippingCost,
    DeliverySpeed? deliverySpeed,
    List<DeliverySpeed>? availableDeliverySpeeds,
    bool? isLocalDelivery,
    Map<String, double>? taxBreakdown,
    bool? isCalculatingShipping,
    String? shippingError,
    bool? isProcessing,
    String? idempotencyKey,
    String? checkoutError,
    String? paymentProvider,
    bool clearShippingError = false,
    bool clearCheckoutError = false,
    bool clearIdempotencyKey = false,
  }) {
    return CheckoutState(
      address: address ?? this.address,
      baseShippingCost: baseShippingCost ?? this.baseShippingCost,
      deliverySpeed: deliverySpeed ?? this.deliverySpeed,
      availableDeliverySpeeds: availableDeliverySpeeds ?? this.availableDeliverySpeeds,
      isLocalDelivery: isLocalDelivery ?? this.isLocalDelivery,
      taxBreakdown: taxBreakdown ?? this.taxBreakdown,
      isCalculatingShipping: isCalculatingShipping ?? this.isCalculatingShipping,
      shippingError: clearShippingError ? null : (shippingError ?? this.shippingError),
      isProcessing: isProcessing ?? this.isProcessing,
      idempotencyKey: clearIdempotencyKey ? null : (idempotencyKey ?? this.idempotencyKey),
      checkoutError: clearCheckoutError ? null : (checkoutError ?? this.checkoutError),
      paymentProvider: paymentProvider ?? this.paymentProvider,
    );
  }
}

class CheckoutSuccess extends CheckoutResult {
  final String checkoutUrl;
  final String orderId;
  final String sessionId;

  CheckoutSuccess({required this.checkoutUrl, required this.orderId, required this.sessionId});
}
