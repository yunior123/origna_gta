import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/checkout/checkout_provider.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:origna_gta/utils/safe_url_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

part 'parts/checkout_address_section.dart';
part 'parts/checkout_items_section.dart';
part 'parts/checkout_payment_section.dart';
part 'parts/checkout_summary_section.dart';

/// Compact 3-step progress indicator for the checkout flow.
/// Steps: Cart (0) → Details (1) → Confirm (2)
class _CheckoutStepper extends StatelessWidget {
  final int currentStep; // 0 = cart, 1 = address, 2 = payment/confirm

  const _CheckoutStepper({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = [
      'checkout.step_cart'.tr(),
      'checkout.step_details'.tr(),
      'checkout.step_confirm'.tr(),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurface : DesignTokens.white,
        boxShadow: [
          BoxShadow(
            color: DesignTokens.primary.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIndex = (i + 1) ~/ 2;
            final isCompleted = stepIndex <= currentStep;
            return Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: isCompleted
                      ? const LinearGradient(
                          colors: [
                            DesignTokens.primary,
                            DesignTokens.secondary,
                          ],
                        )
                      : null,
                  color: isCompleted
                      ? null
                      : DesignTokens.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isCompleted = stepIndex < currentStep;
          final isCurrent = stepIndex == currentStep;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? DesignTokens.success
                      : isCurrent
                      ? DesignTokens.primary
                      : DesignTokens.primary.withValues(alpha: 0.12),
                  border: isCurrent
                      ? Border.all(color: DesignTokens.primary, width: 2)
                      : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: DesignTokens.white,
                        )
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isCurrent
                                ? DesignTokens.white
                                : DesignTokens.primary.withValues(alpha: 0.5),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                steps[stepIndex],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isCurrent
                      ? DesignTokens.primary
                      : DesignTokens.textSecondary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Documentation for CheckoutScreen
class CheckoutScreen extends ConsumerStatefulWidget {
  final List<CartItemDetailModel> items;
  final double total;

  const CheckoutScreen({super.key, required this.items, required this.total});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutContent extends ConsumerWidget {
  final List<CartItemDetailModel> items;
  final double subtotal;
  final UserModel userModel;
  final VoidCallback onRefreshShipping;

  const _CheckoutContent({
    required this.items,
    required this.subtotal,
    required this.userModel,
    required this.onRefreshShipping,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = ref.watch(
      checkoutStateProvider.select((state) => state.address),
    );
    final shippingCost = ref.watch(
      checkoutStateProvider.select((state) => state.shippingCost),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPhysicalItems = items.any((item) => !item.isDigital);
    final paymentProvider = ref.watch(
      checkoutStateProvider.select((state) => state.paymentProvider),
    );
    final notifier = ref.read(checkoutStateProvider.notifier);

    if (address == null) {
      if (!hasPhysicalItems) {
        // Digital-only: use profile address province for tax, fallback to Ontario
        final rawState = userModel.address?.state;
        final digitalProvince = (rawState != null && rawState.trim().isNotEmpty)
            ? rawState.trim()
            : ProvinceCodeValues.ontario;
        final digitalTaxRate = getTaxRate(digitalProvince);
        final digitalCouponDiscountCents = ref.watch(
          checkoutStateProvider.select((s) => s.couponDiscountCents),
        );
        final digitalEffective = (subtotal - digitalCouponDiscountCents / 100.0)
            .clamp(0.0, double.infinity);
        // Platform fee is deducted from the seller's payout — NOT added to the buyer's charge.
        // Stripe PaymentIntent = discounted_subtotal + tax only. The fee row is informational only.
        final digitalTax = digitalEffective * digitalTaxRate;
        final digitalTotal = digitalEffective + digitalTax;
        return Container(
          decoration: BoxDecoration(
            gradient: DesignTokens.backgroundGradient(isDark: isDark),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassContainer(
                        child: Row(
                          children: [
                            Icon(
                              Icons.download_done,
                              color: DesignTokens.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'checkout.digital_delivery_no_address'.tr(),
                                style: TextStyle(
                                  color: isDark
                                      ? DesignTokens.outline
                                      : DesignTokens.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      _PaymentProviderSection(
                        selectedProvider: paymentProvider,
                        onChanged: notifier.setPaymentProvider,
                      ),
                      const SizedBox(height: 28),
                      _CouponSection(
                        subtotalCents: (subtotal * 100).round(),
                        sellerIds: items
                            .map((i) => i.sellerId)
                            .where((id) => id.isNotEmpty)
                            .toSet()
                            .toList(),
                      ),
                      const SizedBox(height: 28),
                      _OrderSummary(
                        items: items,
                        subtotal: subtotal,
                        state: digitalProvince,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              const _BuyerProtectionBanner(),
              _CheckoutButton(
                items: items,
                userModel: userModel,
                subtotal: subtotal,
                total: digitalTotal,
              ),
              const _DigitalEulaText(),
              if (items.any((item) => item.isAgeRestricted))
                const _AgeGateText(),
              _TermsText(),
              const SizedBox(height: 16),
              _SecurityInfo(),
            ],
          ),
        );
      }
      return _NoAddressView(onRefreshShipping: onRefreshShipping);
    }

    final couponDiscountCents = ref.watch(
      checkoutStateProvider.select((s) => s.couponDiscountCents),
    );
    final discount = couponDiscountCents / 100.0;
    final effectiveSubtotal = (subtotal - discount).clamp(0.0, double.infinity);
    final taxRate = getTaxRate(address.state);
    // Platform fee is deducted from the seller's payout — NOT added to the buyer's charge.
    // Stripe PaymentIntent = discounted_subtotal + shipping + tax only. Fee row is informational.
    final taxableAmount =
        effectiveSubtotal +
        shippingCost; // GST/HST applies to shipping in Canada
    final tax = taxableAmount * taxRate;
    final totalWithTax = effectiveSubtotal + tax + shippingCost;

    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final hPad = ResponsiveBreakpoints.getSpacing(context, SpacingSize.lg);
    final bgDecoration = BoxDecoration(
      gradient: DesignTokens.backgroundGradient(isDark: isDark),
    );

    // Form sections (shared between both layouts)
    final formSections = <Widget>[
      _AddressSection(address: address, onRefreshShipping: onRefreshShipping),
      SizedBox(
        height: ResponsiveBreakpoints.getSpacing(context, SpacingSize.xl),
      ),
      if (hasPhysicalItems) ...[
        _FreeShippingBanner(subtotal: subtotal),
        const SizedBox(height: 12),
        const _DeliveryOptionsSection(),
        const SizedBox(height: 28),
      ] else ...[
        GlassContainer(
          child: Row(
            children: [
              Icon(Icons.download_done, color: DesignTokens.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'checkout.digital_delivery_no_shipping'.tr(),
                  style: TextStyle(
                    color: isDark
                        ? DesignTokens.outline
                        : DesignTokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
      ],
      _PaymentProviderSection(
        selectedProvider: paymentProvider,
        onChanged: notifier.setPaymentProvider,
      ),
      const SizedBox(height: 28),
      _CouponSection(
        subtotalCents: (subtotal * 100).round(),
        sellerIds: items
            .map((i) => i.sellerId)
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList(),
      ),
    ];

    // Sticky bottom actions (same in both layouts)
    final bottomActions = <Widget>[
      const _BuyerProtectionBanner(),
      _CheckoutButton(
        items: items,
        userModel: userModel,
        subtotal: subtotal,
        total: totalWithTax,
      ),
      if (items.any((item) => item.isDigital)) const _DigitalEulaText(),
      if (items.any((item) => item.isAgeRestricted)) const _AgeGateText(),
      _TermsText(),
      const SizedBox(height: 16),
      _SecurityInfo(),
    ];

    final orderSummary = _OrderSummary(
      items: items,
      subtotal: subtotal,
      state: address.state,
    );

    // Desktop: 2-column — form left (60%), sticky order summary right (40%)
    if (isDesktop) {
      return Container(
        decoration: bgDecoration,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(hPad, hPad, hPad / 2, hPad),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: formSections,
                      ),
                    ),
                  ),
                  ...bottomActions,
                ],
              ),
            ),
            // Order summary sidebar
            SizedBox(
              width: 360,
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad / 2, hPad, hPad, hPad),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? DesignTokens.darkCard : DesignTokens.white,
                    borderRadius: BorderRadius.circular(DesignTokens.radius16),
                    border: Border.all(
                      color: isDark
                          ? DesignTokens.white.withValues(alpha: 0.06)
                          : DesignTokens.outline.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DesignTokens.primary.withValues(
                          alpha: isDark ? 0.1 : 0.06,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: orderSummary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile/tablet: single-column stacked layout
    return Container(
      decoration: bgDecoration,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(hPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...formSections,
                  const SizedBox(height: 28),
                  orderSummary,
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          ...bottomActions,
        ],
      ),
    );
  }
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    final address = ref.watch(checkoutStateProvider.select((s) => s.address));
    // Step 0: Cart ✓ — Step 1: Address — Step 2: Payment/Confirm
    final stepIndex = address != null ? 2 : 1;

    return Scaffold(
      key: const Key('checkout_screen_root'),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140),
        child: Column(
          children: [
            AppBarFactory.simple(title: 'checkout.checkout'.tr()),
            _CheckoutStepper(currentStep: stepIndex),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveBreakpoints.isDesktop(context)
                ? ResponsiveBreakpoints.contentMaxWidth
                : 800,
          ),
          child: userProfileAsync.when(
            loading: () => const ModernLoadingIndicator.fullScreen(),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: DesignTokens.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppError.getMessage(error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ModernButton(
                      label: 'common.retry'.tr(),
                      icon: Icons.refresh,
                      isPrimary: false,
                      onPressed: () => ref.invalidate(userProfileProvider),
                    ),
                  ],
                ),
              ),
            ),
            data: (userProfile) {
              if (userProfile == null) {
                return Center(child: Text('checkout.please_login'.tr()));
              }
              return _CheckoutContent(
                items: widget.items,
                subtotal: widget.total,
                userModel: userProfile,
                onRefreshShipping: _refreshShipping,
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCheckout();
    });
  }

  Future<void> _initializeCheckout() async {
    final notifier = ref.read(checkoutStateProvider.notifier);
    await notifier.initialize();
    if (!mounted) return; // Guard: widget may be disposed during async gap

    final state = ref.read(checkoutStateProvider);
    if (state.address != null) {
      await notifier.calculateShipping(widget.items);
      if (!mounted) return; // Guard: widget may be disposed during async gap
      final shipping = ref.read(checkoutStateProvider).shippingCost;
      notifier.calculateTaxes(widget.total, shippingCost: shipping);
    }
  }

  Future<void> _refreshShipping() async {
    final notifier = ref.read(checkoutStateProvider.notifier);
    // Re-initialize to fetch the newly selected default address
    await notifier.initialize();
    if (!mounted) return; // Guard: widget may be disposed during async gap

    final state = ref.read(checkoutStateProvider);
    if (state.address != null) {
      await notifier.calculateShipping(widget.items);
      if (!mounted) return; // Guard: widget may be disposed during async gap
      final shipping = ref.read(checkoutStateProvider).shippingCost;
      notifier.calculateTaxes(widget.total, shippingCost: shipping);
    }
  }
}
