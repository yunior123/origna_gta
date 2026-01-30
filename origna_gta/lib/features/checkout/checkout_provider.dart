import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/utils.dart';

// ============================================================================
// CHECKOUT STATE
// ============================================================================

@immutable
class CheckoutState {
  final Address? address;
  final double shippingCost;
  final Map<String, double> taxBreakdown;
  final bool isCalculatingShipping;
  final String? shippingError;
  final bool isProcessing;
  final String? idempotencyKey;
  final String? checkoutError;

  const CheckoutState({
    this.address,
    this.shippingCost = 0.0,
    this.taxBreakdown = const {},
    this.isCalculatingShipping = false,
    this.shippingError,
    this.isProcessing = false,
    this.idempotencyKey,
    this.checkoutError,
  });

  double get taxAmount => taxBreakdown.values.fold(0.0, (total, v) => total + v);

  CheckoutState copyWith({
    Address? address,
    double? shippingCost,
    Map<String, double>? taxBreakdown,
    bool? isCalculatingShipping,
    String? shippingError,
    bool? isProcessing,
    String? idempotencyKey,
    String? checkoutError,
    bool clearShippingError = false,
    bool clearCheckoutError = false,
  }) {
    return CheckoutState(
      address: address ?? this.address,
      shippingCost: shippingCost ?? this.shippingCost,
      taxBreakdown: taxBreakdown ?? this.taxBreakdown,
      isCalculatingShipping: isCalculatingShipping ?? this.isCalculatingShipping,
      shippingError: clearShippingError ? null : (shippingError ?? this.shippingError),
      isProcessing: isProcessing ?? this.isProcessing,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      checkoutError: clearCheckoutError ? null : (checkoutError ?? this.checkoutError),
    );
  }
}

// ============================================================================
// CHECKOUT RESULT
// ============================================================================

sealed class CheckoutResult {}

class CheckoutSuccess extends CheckoutResult {
  final String checkoutUrl;
  final String orderId;
  final String sessionId;

  CheckoutSuccess({required this.checkoutUrl, required this.orderId, required this.sessionId});
}

class CheckoutError extends CheckoutResult {
  final String message;
  final String? code;

  CheckoutError({required this.message, this.code});
}

class CheckoutAlreadyProcessed extends CheckoutResult {
  final String existingOrderId;

  CheckoutAlreadyProcessed({required this.existingOrderId});
}

// ============================================================================
// CHECKOUT NOTIFIER
// ============================================================================

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final Ref _ref;

  CheckoutNotifier(this._ref) : super(const CheckoutState());

  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);
  String? get _userId => _ref.read(userIdProvider);

  /// Initialize checkout with user's address
  Future<void> initialize() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final addressMap = userDoc.data()?['address'] as Map<String, dynamic>?;

      if (addressMap != null) {
        final address = Address.fromMap(addressMap);
        state = state.copyWith(address: address);
      }
    } catch (e) {
      debugPrint('Error initializing checkout: $e');
    }
  }

  /// Calculate shipping cost for cart items
  Future<void> calculateShipping(List<CartItemDetailModel> items) async {
    if (state.address == null) {
      state = state.copyWith(shippingError: 'No address found');
      return;
    }

    state = state.copyWith(isCalculatingShipping: true, clearShippingError: true);

    try {
      final cost = await calculateShippingCost(items, state.address);
      state = state.copyWith(shippingCost: cost, isCalculatingShipping: false);
    } catch (e) {
      state = state.copyWith(
        shippingError: 'Failed to calculate shipping',
        isCalculatingShipping: false,
      );
    }
  }

  /// Calculate taxes based on address
  void calculateTaxes(double subtotal) {
    if (state.address == null) return;

    final taxes = calculateDetailedTaxes(state.address, subtotal);
    state = state.copyWith(taxBreakdown: taxes);
  }

  /// Update address and recalculate shipping
  void updateAddress(Address address) {
    state = state.copyWith(address: address);
  }

  /// Generate idempotency key for payment safety
  String _generateIdempotencyKey(String userId, List<CartItemDetailModel> items) {
    final itemsHash = items.map((i) => '${i.productId}:${i.quantity}').join(',').hashCode;
    return '${userId}_${itemsHash}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Start Stripe checkout with idempotency
  Future<CheckoutResult> startCheckout({
    required List<CartItemDetailModel> items,
    required UserModel user,
    required double subtotal,
  }) async {
    if (state.address == null) {
      return CheckoutError(message: 'No delivery address');
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

      // Generate idempotency key
      final idempotencyKey = _generateIdempotencyKey(userId, items);
      state = state.copyWith(idempotencyKey: idempotencyKey);

      // Calculate totals
      final taxRate = getTaxRate(state.address!.state);
      final tax = subtotal * taxRate;
      final totalWithTax = subtotal + tax + state.shippingCost;

      // Get detailed taxes
      final taxes = calculateDetailedTaxes(state.address, subtotal);

      // Get seller IDs
      final sellerIds = items.map((item) => item.sellerId).toSet().toList();

      // Prepare delivery info
      final deliveryInfo = state.address!.toMap();

      // Build checkout request data for cloud function
      // Note: Cloud function creates the actual OrderModel server-side
      final orderData = {
        'userId': userId,
        'customerId': user.customerId ?? '',
        'customerEmail': user.email,
        'items': items
            .map((item) => {
                  'sellerId': item.sellerId,
                  'productId': item.productId,
                  'name': item.name,
                  'description': item.description,
                  'price': item.price,
                  'quantity': item.quantity,
                  'imageUrls': item.imageUrls,
                })
            .toList(),
        'total': totalWithTax,
        'taxes': taxes,
        'shippingCost': state.shippingCost,
        'subtotal': subtotal,
        'deliveryInfo': deliveryInfo,
        'currency': 'cad',
        'amount': (totalWithTax * 100).toInt(),
        'sellerIds': sellerIds,
        'idempotencyKey': idempotencyKey,
      };

      debugPrint('Sending checkout request with idempotency key: $idempotencyKey');

      final functions = FirebaseFunctions.instance;
      if (kDebugMode) {
        functions.useFunctionsEmulator('127.0.0.1', 8081);
      }

      final callable = functions.httpsCallable('create_checkout_session');
      final response = await callable.call(orderData);

      final checkoutUrl = response.data['url'] as String;
      final orderId = response.data['orderId'] as String;
      final sessionId = response.data['sessionId'] as String;

      // Update user with checkout tracking
      await _firestore.collection('users').doc(userId).update({
        'lastCheckoutSession': sessionId,
        'lastOrderId': orderId,
        'lastCheckoutTimestamp': FieldValue.serverTimestamp(),
      });

      state = state.copyWith(isProcessing: false);

      return CheckoutSuccess(
        checkoutUrl: checkoutUrl,
        orderId: orderId,
        sessionId: sessionId,
      );
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Firebase Function Error: ${e.code} - ${e.message}');
      state = state.copyWith(
        isProcessing: false,
        checkoutError: e.message ?? e.code,
      );
      return CheckoutError(message: e.message ?? e.code, code: e.code);
    } catch (e) {
      debugPrint('Checkout error: $e');
      state = state.copyWith(isProcessing: false, checkoutError: e.toString());
      return CheckoutError(message: e.toString());
    }
  }

  /// Reset checkout state
  void reset() {
    state = const CheckoutState();
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// StateNotifierProvider for checkout
final checkoutStateProvider = StateNotifierProvider.autoDispose<CheckoutNotifier, CheckoutState>((ref) {
  return CheckoutNotifier(ref);
});

/// Computed provider for checkout total
final checkoutTotalProvider = Provider.autoDispose<double>((ref) {
  final checkoutState = ref.watch(checkoutStateProvider);
  final subtotal = ref.watch(cartSubtotalProvider);
  return subtotal + checkoutState.taxAmount + checkoutState.shippingCost;
});

/// Computed provider for tax rate based on address
final checkoutTaxRateProvider = Provider.autoDispose<double>((ref) {
  final checkoutState = ref.watch(checkoutStateProvider);
  if (checkoutState.address == null) return 0.13; // Default Ontario HST
  return getTaxRate(checkoutState.address!.state);
});
