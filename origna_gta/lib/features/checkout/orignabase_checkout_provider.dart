import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/order_repository.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/services/orignabase_analytics_service.dart';
import 'package:origna_gta/utils/circuit_breaker.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:uuid/uuid.dart';

import 'checkout_state.dart';

export 'checkout_state.dart';

/// Riverpod provider for [OrignaBaseCheckoutNotifier].
///
/// Auto-disposed on navigation away from checkout — fresh state prevents
/// stale address/coupon/shipping data from leaking between checkout sessions.
final checkoutStateProvider =
    StateNotifierProvider.autoDispose<
      OrignaBaseCheckoutNotifier,
      CheckoutState
    >((ref) {
      return OrignaBaseCheckoutNotifier(ref);
    });

final _shippingCircuitBreaker = CircuitBreakerRegistry.get(
  'ob_shipping_calc',
  config: CircuitBreakerConfig.searchDefault,
);
final _stripeCircuitBreaker = CircuitBreakerRegistry.get(
  'ob_stripe_checkout',
  config: CircuitBreakerConfig.paymentDefault,
);

/// Manages the entire checkout flow: address selection, shipping calculation,
/// tax computation, coupon application, and Stripe session creation.
///
/// ## State Flow
/// ```
/// Initialized (address loaded) → Shipping calculated → Taxes computed
///   → Coupon applied (optional) → Checkout started → Stripe redirect
/// ```
///
/// ## Key Decisions
/// - Circuit breakers wrap shipping ([_shippingCircuitBreaker]) and Stripe
///   ([_stripeCircuitBreaker]) calls — degraded services return user-friendly
///   errors instead of hanging.
/// - Idempotency keys prevent duplicate orders on retry — the server returns
///   the existing session if the key matches.
/// - Biometric auth required for transactions >= $100 CAD — security guard
///   via [LocalAuthentication].
/// - Cart price verification runs before checkout — catches price drift between
///   add-to-cart and checkout time. Fails open (continues on verification error).
/// - Free shipping threshold checked against post-coupon subtotal — coupons can
///   trigger free shipping.
/// - All monetary values use integer cents internally; dollars only for display.
///
/// See also:
/// - [CheckoutState] for the state shape
/// - [OrderRepository] for persistence layer
/// - [cartSubtotalProvider] for subtotal computation
///
/// Gotchas:
/// - This notifier mixes synchronous state transitions with async side effects, so
///   callers should avoid assuming that one state update means the whole checkout
///   pipeline has completed.
/// - Client-side tax and shipping are estimates; the backend remains authoritative.
class OrignaBaseCheckoutNotifier extends StateNotifier<CheckoutState> {
  static const double _localDeliveryRadiusKm =
      BusinessRules.localDeliveryRadiusKm;

  final Ref _ref;

  OrignaBaseCheckoutNotifier(this._ref) : super(const CheckoutState());

  OrignaBase get _ob => _ref.read(orignabaseProvider);
  OrderRepository get _orderRepository => _ref.read(orderRepositoryProvider);
  String? get _userId => _ref.read(obUserIdProvider);
  UserRepository get _userRepository => _ref.read(userRepositoryProvider);

  /// Validates and applies a coupon code server-side, storing the discount in state.
  ///
  /// Parameters:
  /// - [code]: coupon code entered by the buyer; normalized before the request.
  /// - [subtotalCents]: current cart subtotal in integer cents.
  /// - [sellerIds]: optional seller scope when a coupon is seller-specific.
  ///
  /// Returns:
  /// - Completes after [state] reflects the applied discount or an error message.
  ///
  /// After successful application, triggers shipping recalculation and tax update
  /// via [_recalculateTotalsAfterCouponChange].
  ///
  /// Gotchas:
  /// - Empty coupon strings are ignored silently.
  /// - Shipping and tax are recomputed from the discounted subtotal, so applying a
  ///   coupon can change more than the discount line item.
  Future<void> applyCoupon(
    String code,
    int subtotalCents, {
    List<String>? sellerIds,
  }) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) return;
    state = state.copyWith(isCouponLoading: true, couponError: null);
    try {
      final result = await _ob.request(
        'POST',
        ApiEndpoints.couponsApply,
        body: {
          Fields.couponCode: trimmed,
          ApiKeys.cartSubtotalCents: subtotalCents,
          Fields.sellerIds: sellerIds ?? [],
        },
      );
      final data = Map<String, dynamic>.from(result as Map);
      final discountCents =
          (data[Fields.discountAmountCents] as num?)?.toInt() ?? 0;
      if (!mounted) return;
      state = state.copyWith(
        couponCode: trimmed,
        couponDiscountCents: discountCents,
        isCouponLoading: false,
      );
      final int postDiscountSubtotalCents = max(
        0,
        subtotalCents - discountCents,
      );
      _recalculateTotalsAfterCouponChange(postDiscountSubtotalCents);
    } on OrignaBaseException catch (e) {
      if (!mounted) return;
      state = state.copyWith(isCouponLoading: false, couponError: e.message);
    } catch (e, st) {
      if (!mounted) return;
      state = state.copyWith(
        isCouponLoading: false,
        couponError: 'checkout.coupon_apply_failed'.tr(),
      );
      AppError.log(e, stackTrace: st, context: 'ob_checkout_applyCoupon');
    }
  }

  /// Verifies cart prices against current product prices server-side.
  ///
  /// Parameters:
  /// - [items]: cart entries with product IDs, client prices, and quantities.
  ///
  /// Returns:
  /// - A decoded response map containing drift metadata such as `hasChanges`,
  ///   `priceChanges`, `stockChanges`, and `removedProducts`.
  ///
  /// Detects price drift, stock changes, and removed products between
  /// add-to-cart and checkout. Returns a map with `hasChanges`, `priceChanges`,
  /// `stockChanges`, and `removedProducts` arrays.
  ///
  /// Gotchas:
  /// - Errors are rethrown after logging so callers can decide whether checkout
  ///   should fail open or fail closed.
  Future<Map<String, dynamic>> verifyCartPrices(
    List<CartItemDetailModel> items,
  ) async {
    try {
      final result = await _ob.request(
        'POST',
        ApiEndpoints.checkoutVerifyPrices,
        body: {
          Fields.items: items
              .map(
                (item) => {
                  Fields.productId: item.productId,
                  Fields.priceCents: item.priceCents,
                  Fields.quantity: item.quantity,
                },
              )
              .toList(),
        },
      );
      return Map<String, dynamic>.from(result as Map);
    } catch (e, st) {
      AppError.log(e, stackTrace: st, context: 'ob_checkout_verifyCartPrices');
      rethrow;
    }
  }

  /// Calculates shipping cost for cart items based on seller locations, item
  /// dimensions, delivery speed, and buyer address.
  ///
  /// Parameters:
  /// - [items]: fully hydrated cart items, including seller metadata and shipping flags.
  ///
  /// Returns:
  /// - Completes after [state] is updated with shipping cost, available speeds,
  ///   local-delivery status, and any error message.
  ///
  /// Key behaviors:
  /// - Digital-only carts: shipping cost = 0, no address required.
  /// - Free shipping threshold: checked against post-coupon subtotal in integer cents.
  /// - Local delivery: determined by Haversine distance between buyer and seller
  ///   addresses (radius defined in [BusinessRules.localDeliveryRadiusKm]).
  /// - Available delivery speeds: computed per-item based on shipping metadata
  ///   (perishable, local-only, international).
  ///
  /// Wrapped by [_shippingCircuitBreaker] — returns user-friendly error on open circuit.
  ///
  /// Gotchas:
  /// - Missing coordinates on either side force local-delivery detection to `false`.
  /// - This method recalculates taxes as a follow-up side effect after shipping succeeds.
  Future<void> calculateShipping(List<CartItemDetailModel> items) async {
    if (items.isEmpty) {
      state = state.copyWith(shippingError: 'checkout.errors.no_items'.tr());
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
          shippingError: null,
        );
        return;
      }
      state = state.copyWith(shippingError: 'checkout.errors.no_address'.tr());
      return;
    }
    if (!hasPhysicalItems) {
      state = state.copyWith(
        baseShippingCost: 0,
        isLocalDelivery: false,
        availableDeliverySpeeds: const [],
        deliverySpeed: DeliverySpeed.standard,
        isCalculatingShipping: false,
        shippingError: null,
      );
      return;
    }

    state = state.copyWith(isCalculatingShipping: true, shippingError: null);

    try {
      // cartSubtotalProvider returns INTEGER CENTS — divide by 100.0 to get dollars for analytics/tax/biometric.
      final subtotal = _ref.read(cartSubtotalProvider) / 100.0;
      final sellerCosts = await _shippingCircuitBreaker.execute(
        () => calculateShippingCost(
          items,
          state.address,
          chosenSpeed: state.deliverySpeed,
          ob: _ob,
        ),
      );

      final double rawCost = sellerCosts.values.fold(
        0.0,
        (sum, cost) => sum + cost,
      );
      // Use priceCents (integer cents) — no floating-point rounding errors.
      final int subtotalCents = items.fold(
        0,
        (sum, item) => sum + item.priceCents * item.quantity,
      );
      // Apply coupon discount before checking free shipping threshold.
      final int postCouponSubtotalCents =
          subtotalCents - state.couponDiscountCents;
      final isFree =
          postCouponSubtotalCents >= BusinessRules.freeShippingThresholdCents;
      final cost = isFree ? 0.0 : rawCost;
      final adjustedSellerCosts = isFree
          ? sellerCosts.map((k, v) => MapEntry(k, 0.0))
          : sellerCosts;

      final Map<String, String> sellerNames = {};
      for (var item in items) {
        if (item.sellerId.isNotEmpty) {
          sellerNames[item.sellerId] = item.sellerName;
        }
      }

      final isLocal = await _checkLocalDelivery(items, state.address!);
      final itemChecks = items
          .map(
            (item) => DeliveryItemCheck(
              estimatedShipDays: item.estimatedShipDays,
              isPerishable: item.isPerishable,
              isLocalOnly: item.isLocalDeliveryOnly,
              isInternational:
                  item.madeInCountry != null &&
                  item.madeInCountry!.isNotEmpty &&
                  item.madeInCountry != CountryValues.canada &&
                  item.madeInCountry != CountryValues.canadaCode,
            ),
          )
          .toList();

      final availableSpeeds = DeliverySpeed.values
          .where((speed) => speed.isAvailableForItems(itemChecks, isLocal))
          .toList();

      final hasIntl = itemChecks.any((item) => item.isInternational);
      if (!mounted) return;

      state = state.copyWith(
        baseShippingCost: cost,
        sellerShippingCosts: adjustedSellerCosts,
        sellerNames: sellerNames,
        isLocalDelivery: isLocal,
        availableDeliverySpeeds: availableSpeeds,
        deliverySpeed: availableSpeeds.contains(state.deliverySpeed)
            ? state.deliverySpeed
            : (availableSpeeds.isNotEmpty
                  ? availableSpeeds.first
                  : DeliverySpeed.standard),
        isCalculatingShipping: false,
        hasInternationalItems: hasIntl,
      );

      final analytics = OrignaBaseAnalyticsService(_ob);
      unawaited(
        analytics.logAddShippingInfo(
          valueCad: subtotal,
          shippingCostCad: cost,
          shippingTier: state.deliverySpeed.name,
        ),
      );

      calculateTaxes(subtotal, shippingCost: cost);
    } on CircuitBreakerOpenException catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        shippingError: 'checkout.errors.shipping_unavailable'.tr(),
        isCalculatingShipping: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        shippingError: 'checkout.errors.shipping_calc_failed'.tr(),
        isCalculatingShipping: false,
      );
    }
  }

  /// Computes province-specific tax breakdown (GST/HST/PST/QST) for display.
  ///
  /// These are client-side estimates only — the server uses Stripe Tax API
  /// for the authoritative calculation. [subtotal] and [shippingCost] in dollars.
  void calculateTaxes(double subtotal, {double shippingCost = 0.0}) {
    if (state.address == null) return;
    final taxableAmount = subtotal + shippingCost;
    final taxes = calculateDetailedTaxes(state.address, taxableAmount);
    state = state.copyWith(taxBreakdown: taxes);
  }

  /// Loads the user's default shipping address into state on checkout entry.
  ///
  /// Tries the address book first (default address), falls back to the user profile address.
  /// Silently catches errors — checkout can proceed without a pre-loaded address.
  Future<void> initialize() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final addresses = await _ref.read(userAddressesProvider.future);
      if (addresses.isNotEmpty) {
        final defaultAddress = addresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => addresses.first,
        );
        state = state.copyWith(address: defaultAddress);
      } else {
        final user = await _userRepository.getUserProfile(userId);
        if (user?.address != null) {
          state = state.copyWith(address: user!.address);
        }
      }
    } catch (e, st) {
      AppError.log(e, stackTrace: st, context: 'ob_checkout_initialize');
    }
  }

  /// Removes the applied coupon and recalculates shipping/taxes without discount.
  ///
  /// Reads the current cart subtotal to recompute totals post-removal.
  void removeCoupon() {
    final subtotalCents = _ref.read(cartSubtotalProvider);
    state = state.copyWith(
      couponCode: null,
      couponDiscountCents: 0,
      couponError: null,
    );
    _recalculateTotalsAfterCouponChange(subtotalCents);
  }

  /// Resets checkout state to initial values (used on navigation away).
  void reset() => state = const CheckoutState();

  /// Sets the delivery speed and recalculates shipping cost for the cart.
  ///
  /// Only applies if [speed] is in [CheckoutState.availableDeliverySpeeds].
  /// Triggers a shipping recalculation via [calculateShipping].
  void setDeliverySpeed(DeliverySpeed speed) {
    if (state.availableDeliverySpeeds.contains(speed)) {
      state = state.copyWith(deliverySpeed: speed);
      _ref.read(cartWithDetailsProvider).whenData((items) {
        calculateShipping(items);
      });
    }
  }

  /// Sets the payment provider.
  ///
  /// Currently only [PaymentProviderValues.stripe] is accepted — other values are ignored.
  void setPaymentProvider(String provider) {
    if (provider == PaymentProviderValues.stripe) {
      state = state.copyWith(paymentProvider: provider);
    }
  }

  /// Creates a Stripe Checkout Session and returns the redirect URL.
  ///
  /// Parameters:
  /// - [items]: cart items being purchased.
  /// - [user]: currently authenticated buyer profile.
  /// - [subtotalCents]: authoritative client subtotal in integer cents.
  /// - [eulaAccepted]: whether digital-item terms were accepted.
  /// - [ageVerificationAccepted]: whether age-restricted items were acknowledged.
  ///
  /// Returns:
  /// - [CheckoutSuccess] with the redirect URL, order ID, and session ID.
  /// - [CheckoutAlreadyProcessed] when an idempotent retry hits an existing order.
  /// - [CheckoutError] when validation or remote checkout creation fails.
  ///
  /// Pre-flight validation: cart non-empty, address valid (for physical items),
  /// subtotal > 0, email present, not already processing.
  ///
  /// Security: biometric auth required for transactions >= $100 CAD.
  ///
  /// Flow:
  /// 1. Verify cart prices haven't changed (fail-open on error)
  /// 2. Create Stripe session via [OrderRepository.createCheckoutSession]
  /// 3. Handle duplicate session (idempotency) — returns existing URL
  /// 4. Store session ID and keep the cart until payment confirmation webhook
  ///
  /// Returns [CheckoutSuccess] with redirect URL, or [CheckoutError] on failure.
  ///
  /// Gotchas:
  /// - Price verification currently fails closed; any verification error blocks checkout.
  /// - High-value orders require local biometric auth before the server request is sent.
  /// - The cart stays intact until the payment-confirmation webhook performs
  ///   authoritative server-side cleanup.
  Future<CheckoutResult> startCheckout({
    required List<CartItemDetailModel> items,
    required UserModel user,
    required int subtotalCents,
    bool eulaAccepted = false,
    bool ageVerificationAccepted = false,
  }) async {
    if (items.isEmpty) {
      return CheckoutError(message: 'checkout.errors.cart_empty'.tr());
    }
    final hasPhysicalItems = items.any((item) => !item.isDigital);
    if (hasPhysicalItems && !hasValidAddress(state.address)) {
      return CheckoutError(message: 'checkout.errors.address_required'.tr());
    }
    if (subtotalCents <= 0) {
      return CheckoutError(message: 'checkout.errors.invalid_total'.tr());
    }
    if (user.email.trim().isEmpty) {
      return CheckoutError(message: 'checkout.errors.missing_email'.tr());
    }
    if (state.isProcessing) {
      return CheckoutError(message: 'checkout.errors.already_processing'.tr());
    }

    state = state.copyWith(isProcessing: true, checkoutError: null);
    final subtotalDollars = subtotalCents / 100.0;
    final analytics = OrignaBaseAnalyticsService(_ob);
    unawaited(
      analytics.logBeginCheckout(
        valueCad: subtotalDollars,
        itemCount: items.length,
      ),
    );

    try {
      // Biometric guard for high-value transactions ($100 CAD)
      if (subtotalCents >= 10000) {
        final localAuth = LocalAuthentication();
        final canAuthenticateWithBiometrics =
            await localAuth.canCheckBiometrics;
        final canAuthenticate =
            canAuthenticateWithBiometrics ||
            await localAuth.isDeviceSupported();

        if (canAuthenticate) {
          try {
            final didAuthenticate = await localAuth.authenticate(
              localizedReason: 'auth_biometric_required_higher_value'.tr(),
              biometricOnly: false,
            );
            if (!didAuthenticate) {
              state = state.copyWith(isProcessing: false);
              return CheckoutError(
                message: 'checkout.errors.biometric_failed'.tr(),
              );
            }
          } catch (e) {
            state = state.copyWith(isProcessing: false);
            return CheckoutError(
              message: 'checkout.errors.biometric_error'.tr(),
            );
          }
        } else {
          state = state.copyWith(isProcessing: false);
          return CheckoutError(
            message: 'checkout.errors.biometric_unavailable'.tr(),
          );
        }
      }

      final userId = _userId;
      if (userId == null) throw Exception('User not logged in');

      final idempotencyKey =
          state.idempotencyKey ?? _generateIdempotencyKey(userId);
      state = state.copyWith(idempotencyKey: idempotencyKey);

      final deliveryInstructions = _ref.read(deliveryInstructionsProvider);

      final orderData = {
        Fields.items: items
            .map(
              (item) => {
                Fields.productId: item.productId,
                Fields.name: item.name,
                Fields.priceCents: item.priceCents,
                Fields.quantity: item.quantity,
                Fields.sellerId: item.sellerId,
                Fields.imageUrls: item.imageUrls,
                Fields.isDigital: item.isDigital,
                if (item.buyerNote != null && item.buyerNote!.isNotEmpty)
                  Fields.buyerNote: item.buyerNote,
                if (item.variantId != null) Fields.variantId: item.variantId,
                if (item.variantTitle != null)
                  Fields.variantTitle: item.variantTitle,
                if (item.variantOptions != null)
                  Fields.variantOptions: item.variantOptions,
              },
            )
            .toList(),
        ApiKeys.subtotalCents: subtotalCents,
        Fields.shippingAddress: state.address?.toMap() ?? {},
        Fields.deliverySpeed: state.deliverySpeed.value,
        Fields.deliveryInstructions: deliveryInstructions,
        if (state.couponCode != null) Fields.couponCode: state.couponCode,
        ApiKeys.idempotencyKey: idempotencyKey,
        if (items.any((i) => i.isDigital)) ApiKeys.eulaAccepted: eulaAccepted,
        if (items.any((i) => i.isAgeRestricted))
          ApiKeys.ageVerificationAccepted: ageVerificationAccepted,
      };

      // Verify cart prices — fail closed
      try {
        final verifyData = await verifyCartPrices(items);
        if (verifyData[ApiKeys.hasChanges] == true) {
          state = state.copyWith(isProcessing: false);
          final priceChanges = verifyData[ApiKeys.priceChanges] as List? ?? [];
          final stockChanges = verifyData[ApiKeys.stockChanges] as List? ?? [];
          final removedProducts =
              verifyData[ApiKeys.removedProducts] as List? ?? [];
          final reasons = <String>[
            if (priceChanges.isNotEmpty)
              'checkout.errors.price_changed'.tr(
                namedArgs: {'count': priceChanges.length.toString()},
              ),
            if (stockChanges.isNotEmpty)
              'checkout.errors.stock_changed'.tr(
                namedArgs: {'count': stockChanges.length.toString()},
              ),
            if (removedProducts.isNotEmpty)
              'checkout.errors.items_removed'.tr(
                namedArgs: {'count': removedProducts.length.toString()},
              ),
          ];
          return CheckoutError(
            message: reasons.isEmpty
                ? 'checkout.errors.cart_changed'.tr()
                : reasons.join(' '),
            code: 'price-drift',
          );
        }
      } catch (e, st) {
        AppError.log(
          e,
          stackTrace: st,
          context: 'ob_checkout_verifyCartPrices',
        );
        state = state.copyWith(isProcessing: false);
        return CheckoutError(
          message: 'checkout.errors.unable_to_verify_prices'.tr(),
          code: 'price-verification-failed',
        );
      }

      final result = await _stripeCircuitBreaker.execute(
        () => _orderRepository.createCheckoutSession(orderData),
      );

      if (!mounted) return CheckoutError(message: 'Operation cancelled');

      if (result[ApiKeys.duplicate] == true) {
        final checkoutUrl = result[ApiKeys.checkoutUrl] as String?;
        final orderId = result[Fields.orderId] as String;
        if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
          state = state.copyWith(isProcessing: false, idempotencyKey: null);
          return CheckoutSuccess(
            checkoutUrl: checkoutUrl,
            orderId: orderId,
            sessionId: result[ApiKeys.sessionId] as String? ?? '',
          );
        }
        state = state.copyWith(isProcessing: false, idempotencyKey: null);
        return CheckoutAlreadyProcessed(existingOrderId: orderId);
      }

      final checkoutUrl = result[ApiKeys.checkoutUrl] as String;
      final orderId = result[Fields.orderId] as String;
      final sessionId = result[ApiKeys.sessionId] as String;
      final serverTaxAmountCents =
          (result[Fields.taxAmountCents] as num?)?.toInt() ?? 0;

      await _orderRepository.updateLastSession(userId, sessionId, orderId);

      if (!mounted) return CheckoutError(message: 'Operation cancelled');

      state = state.copyWith(
        isProcessing: false,
        idempotencyKey: null,
        serverTaxAmountCents: serverTaxAmountCents,
      );

      return CheckoutSuccess(
        checkoutUrl: checkoutUrl,
        orderId: orderId,
        sessionId: sessionId,
      );
    } on CircuitBreakerOpenException {
      if (!mounted) return CheckoutError(message: 'Operation cancelled');
      state = state.copyWith(
        isProcessing: false,
        checkoutError:
            'Payment service is temporarily unavailable. Please try again in a moment.',
      );
      return CheckoutError(
        message:
            'Payment service is temporarily unavailable. Please try again in a moment.',
        code: 'service-unavailable',
      );
    } on OrignaBaseException catch (e) {
      if (!mounted) return CheckoutError(message: 'Operation cancelled');
      state = state.copyWith(isProcessing: false, checkoutError: e.message);
      return CheckoutError(message: e.message);
    } catch (e, st) {
      if (!mounted) return CheckoutError(message: 'Operation cancelled');
      AppError.log(e, stackTrace: st, context: 'ob_checkout_startCheckout');
      state = state.copyWith(
        isProcessing: false,
        checkoutError: AppError.getMessage(e),
      );
      return CheckoutError(message: AppError.getMessage(e));
    }
  }

  /// Updates the shipping address and clears the cached idempotency key for re-checkout.
  ///
  /// Parameters:
  /// - [address]: new shipping address to use for the checkout.
  ///
  /// Clears the idempotency key so the next [startCheckout] creates a fresh session.
  void updateAddress(Address address) {
    state = state.copyWith(address: address, idempotencyKey: null);
  }

  /// Recalculates shipping and taxes after a coupon change.
  ///
  /// Parameters:
  /// - [subtotalCents]: post-discount subtotal in integer cents.
  void _recalculateTotalsAfterCouponChange(int subtotalCents) {
    _ref.read(cartWithDetailsProvider).whenData(calculateShipping);
    calculateTaxes(subtotalCents / 100.0, shippingCost: state.shippingCost);
  }

  /// Computes the Haversine distance in km between two coordinate pairs.
  double _calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Checks whether all items can be delivered locally (within [_localDeliveryRadiusKm]).
  ///
  /// Returns `false` if any item or the buyer address lacks coordinates.
  Future<bool> _checkLocalDelivery(
    List<CartItemDetailModel> items,
    Address buyerAddress,
  ) async {
    if (buyerAddress.latitude == null || buyerAddress.longitude == null) {
      return false;
    }
    for (final item in items) {
      final sellerAddr = item.sellerAddress;
      if (sellerAddr.latitude == null || sellerAddr.longitude == null) {
        return false;
      }
      final distance = _calculateDistanceKm(
        buyerAddress.latitude!,
        buyerAddress.longitude!,
        sellerAddr.latitude!,
        sellerAddr.longitude!,
      );
      if (distance > _localDeliveryRadiusKm) return false;
    }
    return true;
  }

  /// Generates a unique idempotency key: `chk_{userId}_{uuid}`.
  String _generateIdempotencyKey(String userId) {
    return 'chk_${userId}_${const Uuid().v4()}';
  }

  /// Converts degrees to radians.
  double _toRadians(double deg) => deg * pi / 180;
}
