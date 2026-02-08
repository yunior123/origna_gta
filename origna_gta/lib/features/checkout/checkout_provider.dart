import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/order_repository.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/utils/circuit_breaker.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/utils.dart';

import 'checkout_state.dart';
export 'checkout_state.dart';

/// Circuit breakers for external service calls
final _stripeCircuitBreaker = CircuitBreakerRegistry.get(
  'stripe_checkout',
  config: CircuitBreakerConfig.paymentDefault,
);
final _algoliaCircuitBreaker = CircuitBreakerRegistry.get(
  'algolia_search',
  config: CircuitBreakerConfig.searchDefault,
);

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
  /// 
  /// Uses circuit breaker pattern to handle Algolia/service outages gracefully
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
      // Use circuit breaker for external service calls
      final cost = await _algoliaCircuitBreaker.execute(
        () => calculateShippingCost(items, state.address),
      );

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
    } on CircuitBreakerOpenException catch (_) {
      // Algolia/service is temporarily unavailable
      state = state.copyWith(
        shippingError: 'Shipping calculation temporarily unavailable. Please try again.',
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
    } catch (_) {
      debugPrint('⚠️  Error checking email verification');
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

      // Backend expects: items, shippingAddress, subtotal, userId, deliverySpeed
      // Backend handles: tax calculation, shipping calculation, total calculation server-side
      final orderData = {
        Fields.userId: userId,
        Fields.items: items
            .map(
              (item) => {
                Fields.productId: item.productId,
                Fields.name: item.name,
                Fields.price: item.price,
                Fields.quantity: item.quantity,
                Fields.sellerId: item.sellerId,
                Fields.imageUrls: item.imageUrls,
              },
            )
            .toList(),
        'subtotal': subtotal,
        Fields.shippingAddress: state.address?.toMap() ?? {},
        // Bug #9: Send delivery speed so backend applies correct multiplier
        'deliverySpeed': state.deliverySpeed.value,
      };

      debugPrint('Sending checkout request for user: $userId');

      // Use circuit breaker for Stripe checkout calls
      final result = await _stripeCircuitBreaker.execute(
        () => _orderRepository.createCheckoutSession(orderData),
      );

      // Check if widget is still mounted after async operation
      if (!mounted) {
        return CheckoutError(message: 'Operation cancelled');
      }

      // Backend returns: {success, sessionId, orderId, checkoutUrl}
      final checkoutUrl = result[ApiKeys.checkoutUrl] as String;
      final orderId = result[Fields.orderId] as String;
      final sessionId = result[ApiKeys.sessionId] as String;

      await _orderRepository.updateLastSession(userId, sessionId, orderId);

      if (!mounted) {
        return CheckoutError(message: 'Operation cancelled');
      }

      state = state.copyWith(isProcessing: false, clearIdempotencyKey: true);

      // Invalidate cart so stale data doesn't persist after checkout
      _ref.invalidate(cartItemsProvider);

      return CheckoutSuccess(checkoutUrl: checkoutUrl, orderId: orderId, sessionId: sessionId);
    } on CircuitBreakerOpenException catch (e) {
      // Service is temporarily unavailable (circuit breaker open)
      debugPrint('⚠️ Checkout service temporarily unavailable: $e');
      if (!mounted) {
        return CheckoutError(message: 'Operation cancelled');
      }
      state = state.copyWith(
        isProcessing: false,
        checkoutError: 'Payment service is temporarily unavailable. Please try again in a moment.',
      );
      return CheckoutError(
        message: 'Payment service is temporarily unavailable. Please try again in a moment.',
        code: 'service-unavailable',
      );
    } catch (e) {
      debugPrint('Checkout error: $e');
      if (!mounted) {
        return CheckoutError(message: 'Operation cancelled');
      }
      state = state.copyWith(isProcessing: false, checkoutError: AppError.getMessage(e));
      return CheckoutError(message: AppError.getMessage(e));
    }
  }

  /// Update address and recalculate shipping
  void updateAddress(Address address) {
    // New address = new checkout attempt context
    state = state.copyWith(address: address, clearIdempotencyKey: true);
  }

  /// Calculate distance between two coordinates in km (Haversine formula)
  double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) + cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

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

  double _toRadians(double deg) => deg * pi / 180;
}


