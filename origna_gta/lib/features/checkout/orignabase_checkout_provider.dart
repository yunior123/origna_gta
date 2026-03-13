// coverage:ignore-file
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

/// OrignaBase checkout state provider.
final obCheckoutStateProvider =
    StateNotifierProvider.autoDispose<OrignaBaseCheckoutNotifier, CheckoutState>(
        (ref) {
  return OrignaBaseCheckoutNotifier(ref);
});

final _shippingCircuitBreaker = CircuitBreakerRegistry.get('ob_shipping_calc',
    config: CircuitBreakerConfig.searchDefault);
final _stripeCircuitBreaker = CircuitBreakerRegistry.get('ob_stripe_checkout',
    config: CircuitBreakerConfig.paymentDefault);

/// OrignaBase checkout notifier.
class OrignaBaseCheckoutNotifier extends StateNotifier<CheckoutState> {
  static const double _localDeliveryRadiusKm =
      BusinessRules.localDeliveryRadiusKm;

  final Ref _ref;

  OrignaBaseCheckoutNotifier(this._ref) : super(const CheckoutState());

  OrignaBase get _ob => _ref.read(orignabaseProvider);
  OrderRepository get _orderRepository => _ref.read(orderRepositoryProvider);
  String? get _userId => _ref.read(obUserIdProvider);
  UserRepository get _userRepository => _ref.read(userRepositoryProvider);

  /// Apply a coupon code — validates server-side and stores discount in state.
  Future<void> applyCoupon(String code, int subtotalCents,
      {List<String>? sellerIds}) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) return;
    state = state.copyWith(isCouponLoading: true, clearCouponError: true);
    try {
      final result =
          await _ob.request('POST', '/api/coupons/apply', body: {
        Fields.couponCode: trimmed,
        ApiKeys.cartSubtotalCents: subtotalCents,
        Fields.sellerIds: sellerIds ?? [],
      });
      final data = Map<String, dynamic>.from(result as Map);
      final discountCents =
          (data[Fields.discountAmountCents] as num?)?.toInt() ?? 0;
      state = state.copyWith(
          couponCode: trimmed,
          couponDiscountCents: discountCents,
          isCouponLoading: false);
      final postDiscountSubtotal = (subtotalCents - discountCents) / 100.0;
      calculateTaxes(postDiscountSubtotal, shippingCost: state.shippingCost);
    } on OrignaBaseException catch (e) {
      state = state.copyWith(
          isCouponLoading: false,
          couponError: e.message);
    } catch (e, st) {
      state = state.copyWith(
          isCouponLoading: false,
          couponError: 'checkout.coupon_apply_failed'.tr());
      AppError.log(e, stackTrace: st, context: 'ob_checkout_applyCoupon');
    }
  }

  /// Verify cart prices before checkout.
  Future<Map<String, dynamic>?> verifyCartPrices(
      List<CartItemDetailModel> items) async {
    try {
      final result = await _ob
          .request('POST', '/api/checkout/verify-prices', body: {
        Fields.items: items
            .map((item) => {
                  Fields.productId: item.productId,
                  Fields.price: item.price,
                  Fields.quantity: item.quantity,
                })
            .toList(),
      });
      return Map<String, dynamic>.from(result as Map);
    } catch (e, st) {
      AppError.log(e,
          stackTrace: st, context: 'ob_checkout_verifyCartPrices');
      return null;
    }
  }

  /// Calculate shipping cost for cart items.
  Future<void> calculateShipping(List<CartItemDetailModel> items) async {
    if (items.isEmpty) {
      state = state.copyWith(
          shippingError: 'checkout.errors.no_items'.tr());
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
      state = state.copyWith(
          shippingError: 'checkout.errors.no_address'.tr());
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

    state = state.copyWith(
        isCalculatingShipping: true, clearShippingError: true);

    try {
      final subtotal = _ref.read(cartSubtotalProvider);
      final sellerCosts = await _shippingCircuitBreaker.execute(
          () => calculateShippingCost(items, state.address,
              chosenSpeed: state.deliverySpeed));

      final double rawCost =
          sellerCosts.values.fold(0.0, (sum, cost) => sum + cost);
      final isFree = (subtotal * 100).round() >=
          BusinessRules.freeShippingThresholdCents;
      final cost = isFree ? 0.0 : rawCost;
      final adjustedSellerCosts =
          isFree ? sellerCosts.map((k, v) => MapEntry(k, 0.0)) : sellerCosts;

      final Map<String, String> sellerNames = {};
      for (var item in items) {
        if (item.sellerId.isNotEmpty) {
          sellerNames[item.sellerId] = item.sellerName;
        }
      }

      final isLocal = await _checkLocalDelivery(items, state.address!);
      final itemChecks = items
          .map((item) => DeliveryItemCheck(
                estimatedShipDays: item.estimatedShipDays,
                isPerishable: item.isPerishable,
                isLocalOnly: item.isLocalDeliveryOnly,
                isInternational: item.madeInCountry != null &&
                    item.madeInCountry!.isNotEmpty &&
                    item.madeInCountry != CountryValues.canada &&
                    item.madeInCountry != CountryValues.canadaCode,
              ))
          .toList();

      final availableSpeeds = DeliverySpeed.values
          .where((speed) => speed.isAvailableForItems(itemChecks, isLocal))
          .toList();

      final hasIntl = itemChecks.any((item) => item.isInternational);

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
      unawaited(analytics.logAddShippingInfo(
          valueCad: subtotal,
          shippingCostCad: cost,
          shippingTier: state.deliverySpeed.name));

      calculateTaxes(subtotal, shippingCost: cost);
    } on CircuitBreakerOpenException catch (_) {
      state = state.copyWith(
          shippingError: 'checkout.errors.shipping_unavailable'.tr(),
          isCalculatingShipping: false);
    } catch (e) {
      state = state.copyWith(
          shippingError: 'checkout.errors.shipping_calc_failed'.tr(),
          isCalculatingShipping: false);
    }
  }

  void calculateTaxes(double subtotal, {double shippingCost = 0.0}) {
    if (state.address == null) return;
    final taxableAmount = subtotal + shippingCost;
    final taxes = calculateDetailedTaxes(state.address, taxableAmount);
    state = state.copyWith(taxBreakdown: taxes);
  }

  Future<void> initialize() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final addresses = await _ref.read(userAddressesProvider.future);
      if (addresses.isNotEmpty) {
        final defaultAddress = addresses.firstWhere((a) => a.isDefault,
            orElse: () => addresses.first);
        state = state.copyWith(address: defaultAddress);
      } else {
        final user = await _userRepository.getUserProfile(userId);
        if (user?.address != null) {
          state = state.copyWith(address: user!.address);
        }
      }
    } catch (e, st) {
      AppError.log(e,
          stackTrace: st, context: 'ob_checkout_initialize');
    }
  }

  void removeCoupon() =>
      state = state.copyWith(clearCoupon: true, clearCouponError: true);

  void reset() => state = const CheckoutState();

  void setDeliverySpeed(DeliverySpeed speed) {
    if (state.availableDeliverySpeeds.contains(speed)) {
      state = state.copyWith(deliverySpeed: speed);
      _ref.read(cartWithDetailsProvider).whenData((items) {
        calculateShipping(items);
      });
    }
  }

  void setPaymentProvider(String provider) {
    if (provider == PaymentProviderValues.stripe) {
      state = state.copyWith(paymentProvider: provider);
    }
  }

  Future<CheckoutResult> startCheckout({
    required List<CartItemDetailModel> items,
    required UserModel user,
    required double subtotal,
    bool eulaAccepted = false,
    bool ageVerificationAccepted = false,
  }) async {
    if (items.isEmpty) {
      return CheckoutError(message: 'checkout.errors.cart_empty'.tr());
    }
    final hasPhysicalItems = items.any((item) => !item.isDigital);
    if (hasPhysicalItems && !hasValidAddress(state.address)) {
      return CheckoutError(
          message: 'checkout.errors.address_required'.tr());
    }
    if (subtotal <= 0) {
      return CheckoutError(
          message: 'checkout.errors.invalid_total'.tr());
    }
    if (user.email.trim().isEmpty) {
      return CheckoutError(
          message: 'checkout.errors.missing_email'.tr());
    }
    if (state.isProcessing) {
      return CheckoutError(
          message: 'checkout.errors.already_processing'.tr());
    }

    state = state.copyWith(isProcessing: true, clearCheckoutError: true);
    final analytics = OrignaBaseAnalyticsService(_ob);
    unawaited(analytics.logBeginCheckout(
        valueCad: subtotal, itemCount: items.length));

    try {
      // Biometric guard for high-value transactions
      if (subtotal >= 100.0) {
        final localAuth = LocalAuthentication();
        final canAuthenticateWithBiometrics =
            await localAuth.canCheckBiometrics;
        final canAuthenticate =
            canAuthenticateWithBiometrics ||
                await localAuth.isDeviceSupported();

        if (canAuthenticate) {
          try {
            final didAuthenticate = await localAuth.authenticate(
              localizedReason:
                  'auth_biometric_required_higher_value'.tr(),
              biometricOnly: false,
            );
            if (!didAuthenticate) {
              state = state.copyWith(isProcessing: false);
              return CheckoutError(
                  message: 'checkout.errors.biometric_failed'.tr());
            }
          } catch (e) {
            state = state.copyWith(isProcessing: false);
            return CheckoutError(
                message: 'checkout.errors.biometric_error'.tr());
          }
        }
      }

      final userId = _userId;
      if (userId == null) throw Exception('User not logged in');

      final idempotencyKey =
          state.idempotencyKey ?? _generateIdempotencyKey(userId);
      state = state.copyWith(idempotencyKey: idempotencyKey);

      final deliveryInstructions =
          _ref.read(deliveryInstructionsProvider);

      final orderData = {
        Fields.items: items
            .map((item) => {
                  Fields.productId: item.productId,
                  Fields.name: item.name,
                  Fields.price: item.price,
                  Fields.quantity: item.quantity,
                  Fields.sellerId: item.sellerId,
                  Fields.imageUrls: item.imageUrls,
                  Fields.isDigital: item.isDigital,
                  if (item.buyerNote != null &&
                      item.buyerNote!.isNotEmpty)
                    Fields.buyerNote: item.buyerNote,
                  if (item.variantId != null)
                    Fields.variantId: item.variantId,
                  if (item.variantTitle != null)
                    Fields.variantTitle: item.variantTitle,
                  if (item.variantOptions != null)
                    Fields.variantOptions: item.variantOptions,
                })
            .toList(),
        ApiKeys.subtotalCents: (subtotal * 100).round(),
        Fields.shippingAddress: state.address?.toMap() ?? {},
        Fields.deliverySpeed: state.deliverySpeed.value,
        Fields.deliveryInstructions: deliveryInstructions,
        if (state.couponCode != null)
          Fields.couponCode: state.couponCode,
        ApiKeys.idempotencyKey: idempotencyKey,
        if (items.any((i) => i.isDigital))
          ApiKeys.eulaAccepted: eulaAccepted,
        if (items.any((i) => i.isAgeRestricted))
          ApiKeys.ageVerificationAccepted: ageVerificationAccepted,
      };

      // Verify cart prices — fail open
      try {
        final verifyData = await verifyCartPrices(items);
        if (verifyData != null &&
            verifyData[ApiKeys.hasChanges] == true) {
          state = state.copyWith(isProcessing: false);
          final priceChanges =
              verifyData[ApiKeys.priceChanges] as List? ?? [];
          final stockChanges =
              verifyData[ApiKeys.stockChanges] as List? ?? [];
          final removedProducts =
              verifyData[ApiKeys.removedProducts] as List? ?? [];
          final reasons = <String>[
            if (priceChanges.isNotEmpty)
              'checkout.errors.price_changed'.tr(namedArgs: {
                'count': priceChanges.length.toString()
              }),
            if (stockChanges.isNotEmpty)
              'checkout.errors.stock_changed'.tr(namedArgs: {
                'count': stockChanges.length.toString()
              }),
            if (removedProducts.isNotEmpty)
              'checkout.errors.items_removed'.tr(namedArgs: {
                'count': removedProducts.length.toString()
              }),
          ];
          return CheckoutError(
              message: reasons.isEmpty
                  ? 'checkout.errors.cart_changed'.tr()
                  : reasons.join(' '),
              code: 'price-drift');
        }
      } catch (e, st) {
        AppError.log(e,
            stackTrace: st,
            context: 'ob_checkout_verifyCartPrices');
      }

      final result = await _stripeCircuitBreaker
          .execute(() => _orderRepository.createCheckoutSession(orderData));

      if (!mounted) return CheckoutError(message: 'Operation cancelled');

      if (result[ApiKeys.duplicate] == true) {
        final checkoutUrl = result[ApiKeys.checkoutUrl] as String?;
        final orderId = result[Fields.orderId] as String;
        if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
          state = state.copyWith(
              isProcessing: false, clearIdempotencyKey: true);
          _ref.invalidate(cartItemsProvider);
          return CheckoutSuccess(
              checkoutUrl: checkoutUrl,
              orderId: orderId,
              sessionId:
                  result[ApiKeys.sessionId] as String? ?? '');
        }
        state = state.copyWith(
            isProcessing: false, clearIdempotencyKey: true);
        return CheckoutAlreadyProcessed(
            existingOrderId: orderId);
      }

      final checkoutUrl = result[ApiKeys.checkoutUrl] as String;
      final orderId = result[Fields.orderId] as String;
      final sessionId = result[ApiKeys.sessionId] as String;
      final serverTaxAmountCents =
          (result[Fields.taxAmountCents] as num?)?.toInt() ?? 0;

      await _orderRepository.updateLastSession(
          userId, sessionId, orderId);

      if (!mounted) return CheckoutError(message: 'Operation cancelled');

      state = state.copyWith(
          isProcessing: false,
          clearIdempotencyKey: true,
          serverTaxAmountCents: serverTaxAmountCents);
      _ref.invalidate(cartItemsProvider);

      return CheckoutSuccess(
          checkoutUrl: checkoutUrl,
          orderId: orderId,
          sessionId: sessionId);
    } on CircuitBreakerOpenException {
      if (!mounted) return CheckoutError(message: 'Operation cancelled');
      state = state.copyWith(
          isProcessing: false,
          checkoutError:
              'Payment service is temporarily unavailable. Please try again in a moment.');
      return CheckoutError(
          message:
              'Payment service is temporarily unavailable. Please try again in a moment.',
          code: 'service-unavailable');
    } on OrignaBaseException catch (e) {
      if (!mounted) return CheckoutError(message: 'Operation cancelled');
      state = state.copyWith(
          isProcessing: false, checkoutError: e.message);
      return CheckoutError(message: e.message);
    } catch (e, st) {
      if (!mounted) return CheckoutError(message: 'Operation cancelled');
      AppError.log(e,
          stackTrace: st, context: 'ob_checkout_startCheckout');
      state = state.copyWith(
          isProcessing: false,
          checkoutError: AppError.getMessage(e));
      return CheckoutError(message: AppError.getMessage(e));
    }
  }

  void updateAddress(Address address) {
    state = state.copyWith(
        address: address, clearIdempotencyKey: true);
  }

  double _calculateDistanceKm(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  Future<bool> _checkLocalDelivery(
      List<CartItemDetailModel> items, Address buyerAddress) async {
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
          sellerAddr.longitude!);
      if (distance > _localDeliveryRadiusKm) return false;
    }
    return true;
  }

  String _generateIdempotencyKey(String userId) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'chk_${userId}_${ts}_${const Uuid().v4()}';
  }

  double _toRadians(double deg) => deg * pi / 180;
}
