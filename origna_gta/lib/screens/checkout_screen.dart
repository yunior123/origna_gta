import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/checkout/checkout_provider.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

/// Provider for terms acceptance state — shared between _TermsText and _CheckoutButton
final _termsAcceptedProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Tracks whether the user has interacted with the terms checkbox — gates error state
final _termsInteractedProvider = StateProvider.autoDispose<bool>((ref) => false);

class CheckoutScreen extends ConsumerStatefulWidget {
  final List<CartItemDetailModel> items;
  final double total;

  const CheckoutScreen({super.key, required this.items, required this.total});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _AddressSection extends StatelessWidget {
  final Address address;
  final VoidCallback onRefreshShipping;

  const _AddressSection({required this.address, required this.onRefreshShipping});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      key: const Key('checkout_address_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [DesignTokens.primary, DesignTokens.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'checkout.delivery_address_title'.tr(),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            Semantics(
              button: true,
              label: 'btn-edit-address',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('checkout_edit_address_button'),
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.addressManagement).then((_) => onRefreshShipping());
                  },
                  borderRadius: BorderRadius.circular(8),
                  splashColor: DesignTokens.primary.withValues(alpha: 0.3),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: DesignTokens.primary),
                        const SizedBox(width: 6),
                        Text(
                          'checkout.edit_action'.tr(),
                          style: TextStyle(color: DesignTokens.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (address.label != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [DesignTokens.primary.withValues(alpha: 0.2), DesignTokens.secondary.withValues(alpha: 0.2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    address.label!,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DesignTokens.primary),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(address.formattedAddress, style: TextStyle(fontSize: 15, height: 1.6, color: isDark ? DesignTokens.outline : DesignTokens.textPrimary)),
              if (address.phoneNumber != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 16, color: DesignTokens.primary),
                    const SizedBox(width: 10),
                    Text(address.phoneNumber!, style: TextStyle(color: isDark ? DesignTokens.outline : DesignTokens.textPrimary)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckoutButton extends ConsumerWidget {
  final List<CartItemDetailModel> items;
  final UserModel userModel;
  final double subtotal;
  final double total;

  const _CheckoutButton({required this.items, required this.userModel, required this.subtotal, required this.total});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref.watch(checkoutStateProvider.select((state) => state.isProcessing));
    final isCalculating = ref.watch(checkoutStateProvider.select((state) => state.isCalculatingShipping));
    final shippingError = ref.watch(checkoutStateProvider.select((state) => state.shippingError));
    final termsAccepted = ref.watch(_termsAcceptedProvider);
    final isDisabled = isProcessing || isCalculating || shippingError != null || !termsAccepted;

    return Container(
      padding: EdgeInsets.all(ResponsiveBreakpoints.getSpacing(context, SpacingSize.md)),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? DesignTokens.textPrimary : DesignTokens.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -8))],
      ),
      child: Semantics(
        button: true,
        label: 'btn-place-order',
        child: ModernButton(
          key: const Key('checkout_place_order_button'),
          label: isProcessing ? 'common.processing'.tr() : 'checkout.place_order'.tr(),
          onPressed: isDisabled ? null : () => _showOrderReview(context, ref),
          isLoading: isProcessing,
          icon: Icons.payment,
        ),
      ),
    );
  }

  void _showOrderReview(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderReviewSheet(
        items: items,
        subtotal: subtotal,
        onConfirm: () {
          Navigator.of(context).pop();
          _startCheckout(context, ref);
        },
      ),
    );
  }

  Future<void> _redirectToStripe(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('checkout.stripe_redirect_failed'.tr()),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'common.copy_link'.tr(),
            onPressed: () => Clipboard.setData(ClipboardData(text: url)),
          ),
        ),
      );
    }
  }

  Future<void> _startCheckout(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(checkoutStateProvider.notifier);

    final result = await notifier.startCheckout(items: items, user: userModel, subtotal: subtotal);
    if (!context.mounted) return;

    switch (result) {
      case CheckoutSuccess(:final checkoutUrl):
        // Persist terms acceptance server-side (fire-and-forget — never blocks checkout redirect)
        ref.read(userRepositoryProvider).recordTermsAcceptance().catchError((_) {});
        await _redirectToStripe(checkoutUrl, context);
      case CheckoutError(:final message):
        messenger.showSnackBar(
          SnackBar(
            content: Text('checkout.checkout_error'.tr(namedArgs: {'message': message})),
            backgroundColor: DesignTokens.error,
            duration: const Duration(seconds: 5),
          ),
        );
      case CheckoutAlreadyProcessed(:final existingOrderId):
        messenger.showSnackBar(
          SnackBar(
            content: Text('checkout.order_already_exists'.tr(namedArgs: {'id': existingOrderId})),
            backgroundColor: DesignTokens.primary,
          ),
        );
    }
  }
}

class _CheckoutContent extends ConsumerWidget {
  final List<CartItemDetailModel> items;
  final double subtotal;
  final UserModel userModel;
  final VoidCallback onRefreshShipping;

  const _CheckoutContent({required this.items, required this.subtotal, required this.userModel, required this.onRefreshShipping});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = ref.watch(checkoutStateProvider.select((state) => state.address));
    final shippingCost = ref.watch(checkoutStateProvider.select((state) => state.shippingCost));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPhysicalItems = items.any((item) => !item.isDigital);
    final paymentProvider = ref.watch(checkoutStateProvider.select((state) => state.paymentProvider));
    final notifier = ref.read(checkoutStateProvider.notifier);

    if (address == null) {
      if (!hasPhysicalItems) {
        // Digital-only: use profile address province for tax, fallback to Ontario
        final rawState = userModel.address?.state;
        final digitalProvince = (rawState != null && rawState.trim().isNotEmpty) ? rawState.trim() : ProvinceCodeValues.ontario;
        final digitalTaxRate = getTaxRate(digitalProvince);
        final digitalTax = subtotal * digitalTaxRate;
        final digitalTotal = subtotal + digitalTax;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [isDark ? DesignTokens.textPrimary : DesignTokens.surface, isDark ? DesignTokens.textPrimary : Colors.white],
            ),
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
                            Icon(Icons.download_done, color: DesignTokens.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'checkout.digital_delivery_no_address'.tr(),
                                style: TextStyle(color: isDark ? DesignTokens.outline : DesignTokens.textPrimary, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      _PaymentProviderSection(selectedProvider: paymentProvider, onChanged: notifier.setPaymentProvider),
                      const SizedBox(height: 28),
                      _CouponSection(subtotalCents: (subtotal * 100).round()),
                      const SizedBox(height: 28),
                      _OrderSummary(items: items, subtotal: subtotal, state: digitalProvince),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              const _BuyerProtectionBanner(),
              _CheckoutButton(items: items, userModel: userModel, subtotal: subtotal, total: digitalTotal),
              _TermsText(),
              const SizedBox(height: 16),
              _SecurityInfo(),
            ],
          ),
        );
      }
      return _NoAddressView(onRefreshShipping: onRefreshShipping);
    }

    final couponDiscountCents = ref.watch(checkoutStateProvider.select((s) => s.couponDiscountCents));
    final discount = couponDiscountCents / 100.0;
    final effectiveSubtotal = (subtotal - discount).clamp(0.0, double.infinity);
    final taxRate = getTaxRate(address.state);
    final taxableAmount = effectiveSubtotal + shippingCost; // GST/HST applies to shipping in Canada
    final tax = taxableAmount * taxRate;
    final totalWithTax = effectiveSubtotal + tax + shippingCost;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [isDark ? DesignTokens.textPrimary : DesignTokens.surface, isDark ? DesignTokens.textPrimary : Colors.white],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(ResponsiveBreakpoints.getSpacing(context, SpacingSize.lg)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AddressSection(address: address, onRefreshShipping: onRefreshShipping),
                  SizedBox(height: ResponsiveBreakpoints.getSpacing(context, SpacingSize.xl)),
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
                              style: TextStyle(color: isDark ? DesignTokens.outline : DesignTokens.textPrimary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                  _PaymentProviderSection(selectedProvider: paymentProvider, onChanged: notifier.setPaymentProvider),
                  const SizedBox(height: 28),
                  _CouponSection(subtotalCents: (subtotal * 100).round()),
                  const SizedBox(height: 28),
                  _OrderSummary(items: items, subtotal: subtotal, state: address.state),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          const _BuyerProtectionBanner(),
          _CheckoutButton(items: items, userModel: userModel, subtotal: subtotal, total: totalWithTax),
          _TermsText(),
          const SizedBox(height: 16),
          _SecurityInfo(),
        ],
      ),
    );
  }
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      key: const Key('checkout_screen_root'),
      appBar: AppBarFactory.simple(title: 'checkout.checkout'.tr()),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: userProfileAsync.when(
            loading: () => const ModernLoadingIndicator.fullScreen(),
            error: (error, stack) => Center(child: Text(AppError.getMessage(error))),
            data: (userProfile) {
              if (userProfile == null) {
                return Center(child: Text('checkout.please_login'.tr()));
              }
              return _CheckoutContent(items: widget.items, subtotal: widget.total, userModel: userProfile, onRefreshShipping: _refreshShipping);
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

    final state = ref.read(checkoutStateProvider);
    if (state.address != null) {
      await notifier.calculateShipping(widget.items);
      final shipping = ref.read(checkoutStateProvider).shippingCost;
      notifier.calculateTaxes(widget.total, shippingCost: shipping);
    }
  }

  Future<void> _refreshShipping() async {
    final notifier = ref.read(checkoutStateProvider.notifier);
    // Re-initialize to fetch the newly selected default address
    await notifier.initialize();

    final state = ref.read(checkoutStateProvider);
    if (state.address != null) {
      await notifier.calculateShipping(widget.items);
      final shipping = ref.read(checkoutStateProvider).shippingCost;
      notifier.calculateTaxes(widget.total, shippingCost: shipping);
    }
  }
}

/// Delivery speed options selection
class _DeliveryOptionsSection extends ConsumerWidget {
  const _DeliveryOptionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableSpeeds = ref.watch(checkoutStateProvider.select((state) => state.availableDeliverySpeeds));
    final selectedSpeed = ref.watch(checkoutStateProvider.select((state) => state.deliverySpeed));
    final isCalculating = ref.watch(checkoutStateProvider.select((state) => state.isCalculatingShipping));
    final baseShippingCost = ref.watch(checkoutStateProvider.select((state) => state.baseShippingCost));

    if (isCalculating) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('checkout.delivery_speed_title'.tr(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(
              onPressed: () => _showDeliveryInfo(context),
              icon: const Icon(Icons.info_outline, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'checkout.delivery_options_tooltip'.tr(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...DeliverySpeed.values.map((speed) {
          final isAvailable = availableSpeeds.contains(speed);
          final isSelected = selectedSpeed == speed;
          // Show total shipping cost (base + surcharge), not just surcharge
          final totalCost = speed == DeliverySpeed.standard ? baseShippingCost : baseShippingCost + speed.baseSurcharge;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Semantics(
              button: true,
              label: 'btn-delivery-speed-${speed.name}',
              child: GestureDetector(
                key: Key('checkout_delivery_speed_${speed.name}'),
                onTap: isAvailable ? () => ref.read(checkoutStateProvider.notifier).setDeliverySpeed(speed) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? DesignTokens.primary.withValues(alpha: 0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? DesignTokens.primary : DesignTokens.outlineVariant, width: isSelected ? 1.5 : 1),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 1))],
                  ),
                  child: Opacity(
                    opacity: isAvailable ? 1.0 : 0.5,
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? DesignTokens.primary : DesignTokens.outline, width: 2),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: DesignTokens.primary),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    speed.displayName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: isAvailable ? DesignTokens.textPrimary : DesignTokens.textSecondary,
                                    ),
                                  ),
                                  if (speed == DeliverySpeed.sameDay) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: DesignTokens.success, borderRadius: BorderRadius.circular(4)),
                                      child: Text(
                                        'checkout.local'.tr(),
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(speed.estimatedTime, style: TextStyle(fontSize: 13, color: DesignTokens.textSecondary)),
                              if (!isAvailable && speed == DeliverySpeed.sameDay)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'checkout.local_only_50km'.tr(),
                                    style: TextStyle(fontSize: 11, color: DesignTokens.tertiary, fontStyle: FontStyle.italic),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          totalCost > 0 ? '\$${totalCost.toStringAsFixed(2)}' : 'checkout.free'.tr(),
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: totalCost > 0 ? DesignTokens.textPrimary : DesignTokens.success),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  static void _showDeliveryInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('checkout.delivery_options'.tr()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: DeliverySpeed.values.map((speed) {
              final surcharge = speed == DeliverySpeed.standard ? 0.0 : speed.baseSurcharge;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(speed.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        if (speed == DeliverySpeed.sameDay) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: DesignTokens.success, borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              'checkout.local'.tr(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(speed.estimatedTime, style: TextStyle(fontSize: 13, color: DesignTokens.textSecondary)),
                    if (speed == DeliverySpeed.sameDay)
                      Text(
                        'checkout.available_local_50km'.tr(),
                        style: TextStyle(fontSize: 12, color: DesignTokens.textSecondary, fontStyle: FontStyle.italic),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      surcharge > 0 ? 'checkout.additional_cost'.tr(namedArgs: {'amount': surcharge.toStringAsFixed(2)}) : 'checkout.no_additional_cost'.tr(),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: surcharge > 0 ? DesignTokens.textPrimary : DesignTokens.success),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('common.close'.tr()))],
      ),
    );
  }
}

class _NoAddressView extends StatelessWidget {
  final VoidCallback onRefreshShipping;

  const _NoAddressView({required this.onRefreshShipping});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 80, color: DesignTokens.textDisabled),
            const SizedBox(height: 24),
            Text('checkout.no_address_title'.tr(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'checkout.no_address_desc'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: DesignTokens.textSecondary),
            ),
            const SizedBox(height: 32),
            Semantics(
              button: true,
              label: 'btn-add-address',
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.addressManagement).then((_) => onRefreshShipping());
                },
                icon: const Icon(Icons.add_location),
                label: Text('checkout.add_address'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSummary extends ConsumerWidget {
  final List<CartItemDetailModel> items;
  final double subtotal;
  final String state;

  const _OrderSummary({required this.items, required this.subtotal, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shippingCost = ref.watch(checkoutStateProvider.select((state) => state.shippingCost));
    final isCalculating = ref.watch(checkoutStateProvider.select((state) => state.isCalculatingShipping));
    final shippingError = ref.watch(checkoutStateProvider.select((state) => state.shippingError));

    return Column(
      key: const Key('checkout_summary_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('checkout.order_summary_title'.tr(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('${item.name} x${item.quantity}', style: const TextStyle(fontSize: 14))),
                      Text('\$${(item.price * item.quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('cart.subtotal'.tr(), style: TextStyle(fontSize: 16)),
                  Text('\$${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              _buildCouponDiscountRow(ref),
              ..._buildTaxBreakdown(state, subtotal + shippingCost),
              const SizedBox(height: 8),
              Row(
                key: const Key('checkout_shipping_section'),
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('checkout.estimated_shipping'.tr(), style: const TextStyle(color: DesignTokens.textSecondary)),
                  if (isCalculating)
                    const ModernLoadingIndicator.small()
                  else if (shippingError != null)
                    Text(shippingError, style: const TextStyle(color: DesignTokens.error, fontSize: 12))
                  else
                    Text('\$${shippingCost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              if (!isCalculating && shippingError == null && shippingCost > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'checkout.shipping_confirmed_by_seller'.tr(),
                    style: TextStyle(fontSize: 11, color: DesignTokens.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('checkout.estimated_total'.tr(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Builder(builder: (context) {
                    final discountCents = ref.watch(checkoutStateProvider.select((s) => s.couponDiscountCents));
                    final discount = discountCents / 100.0;
                    final effective = (subtotal - discount).clamp(0.0, double.infinity);
                    final total = effective + (getTaxRate(state) * (effective + shippingCost)) + shippingCost;
                    return Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: DesignTokens.primary),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'checkout.tax_confirm_notice'.tr(),
                style: TextStyle(fontSize: 12, color: DesignTokens.textSecondary, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCouponDiscountRow(WidgetRef ref) {
    final discountCents = ref.watch(checkoutStateProvider.select((s) => s.couponDiscountCents));
    final couponCode = ref.watch(checkoutStateProvider.select((s) => s.couponCode));
    if (discountCents <= 0 || couponCode == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer_rounded, size: 14, color: DesignTokens.success),
              const SizedBox(width: 4),
              Text('Coupon ($couponCode)', style: const TextStyle(fontSize: 14, color: DesignTokens.success)),
            ],
          ),
          Text('-\$${(discountCents / 100.0).toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: DesignTokens.success, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  List<Widget> _buildTaxBreakdown(String province, double total) {
    final taxes = taxConfig[province] ?? {'HST': 0.13};
    List<Widget> widgets = [];

    taxes.forEach((taxName, rate) {
      final taxAmount = total * rate;
      widgets.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'checkout.tax_estimate_label'.tr(namedArgs: {'name': taxName, 'rate': (rate * 100).toStringAsFixed(2)}),
              style: TextStyle(fontSize: 14, color: DesignTokens.textSecondary),
            ),
            Text('\$${taxAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, color: DesignTokens.textSecondary)),
          ],
        ),
      );
      widgets.add(const SizedBox(height: 4));
    });

    return widgets;
  }
}

// ============================================================================
// COUPON SECTION (N-07)
// ============================================================================

class _CouponSection extends ConsumerStatefulWidget {
  final int subtotalCents;

  const _CouponSection({required this.subtotalCents});

  @override
  ConsumerState<_CouponSection> createState() => _CouponSectionState();
}

class _CouponSectionState extends ConsumerState<_CouponSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final couponCode = ref.watch(checkoutStateProvider.select((s) => s.couponCode));
    final isLoading = ref.watch(checkoutStateProvider.select((s) => s.isCouponLoading));
    final couponError = ref.watch(checkoutStateProvider.select((s) => s.couponError));
    final notifier = ref.read(checkoutStateProvider.notifier);
    final applied = couponCode != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('checkout.coupon_title'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !applied && !isLoading,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'checkout.coupon_hint'.tr(),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: DesignTokens.outline.withValues(alpha: 0.3))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: DesignTokens.outline.withValues(alpha: 0.3))),
                  errorText: couponError,
                  prefixIcon: const Icon(Icons.local_offer_outlined, size: 20),
                  suffixIcon: applied
                      ? Icon(Icons.check_circle, color: DesignTokens.success, size: 20)
                      : null,
                ),
                onSubmitted: (_) => _apply(notifier),
              ),
            ),
            const SizedBox(width: 10),
            applied
                ? TextButton(
                    onPressed: () {
                      _controller.clear();
                      notifier.removeCoupon();
                    },
                    child: Text('common.remove'.tr(), style: TextStyle(color: DesignTokens.error)),
                  )
                : ElevatedButton(
                    key: const Key('checkout_apply_coupon_button'),
                    onPressed: isLoading ? null : () => _apply(notifier),
                    style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: isLoading ? const SizedBox(width: 18, height: 18, child: ModernLoadingIndicator(strokeWidth: 2)) : Text('common.apply'.tr()),
                  ),
          ],
        ),
      ],
    );
  }

  void _apply(CheckoutNotifier notifier) {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    notifier.applyCoupon(code, widget.subtotalCents);
  }
}

class _PaymentProviderSection extends StatelessWidget {
  final String selectedProvider;
  final ValueChanged<String> onChanged;

  const _PaymentProviderSection({required this.selectedProvider, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Stripe is the only integrated payment provider
    return Column(
      key: const Key('checkout_payment_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('checkout.payment_method_title'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [ChoiceChip(label: Text('payment.stripe'.tr()), selected: true, onSelected: (_) {})],
        ),
        const SizedBox(height: 8),
        Text('checkout.stripe_secure_notice'.tr(), style: TextStyle(color: DesignTokens.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _BuyerProtectionBanner extends StatelessWidget {
  const _BuyerProtectionBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('checkout_buyer_protection_banner'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DesignTokens.success.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: DesignTokens.success, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'checkout.buyer_protection_title'.tr(),
                  style: TextStyle(color: DesignTokens.success, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'checkout.buyer_protection_message'.tr(),
                  style: TextStyle(color: DesignTokens.success.withValues(alpha: 0.85), fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 6),
                Semantics(
                  link: true,
                  label: 'link-buyer-protection',
                  child: GestureDetector(
                    onTap: () => launchUrl(Uri.parse('https://www.orignagta.ca/buyer-protection'), mode: LaunchMode.externalApplication),
                    child: Text(
                      'checkout.buyer_protection_link'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: DesignTokens.success,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: DesignTokens.success,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('checkout_secure_badge'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DesignTokens.info.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, color: DesignTokens.info, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'checkout.secure_payment'.tr(),
                  style: TextStyle(color: DesignTokens.info, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text('checkout.stripe_secure'.tr(), style: TextStyle(color: DesignTokens.info.withValues(alpha: 0.8), fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FREE SHIPPING THRESHOLD BANNER
// ============================================================================

/// Shows "Spend $X.XX more for free shipping!" when subtotal is below the threshold.
/// Disappears when shipping is already free or the threshold is reached.
class _FreeShippingBanner extends ConsumerWidget {
  final double subtotal;

  const _FreeShippingBanner({required this.subtotal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shippingCost = ref.watch(checkoutStateProvider.select((s) => s.shippingCost));
    final isCalculating = ref.watch(checkoutStateProvider.select((s) => s.isCalculatingShipping));

    if (isCalculating || shippingCost == 0) return const SizedBox.shrink();

    const thresholdCents = BusinessRules.freeShippingThresholdCents;
    final subtotalCents = (subtotal * 100).round();
    final remainingCents = thresholdCents - subtotalCents;
    if (remainingCents <= 0) return const SizedBox.shrink();

    final remaining = remainingCents / 100.0;
    final progress = (subtotalCents / thresholdCents).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [DesignTokens.tertiary.withValues(alpha: 0.12), DesignTokens.success.withValues(alpha: 0.10)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.tertiary.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_outlined, size: 17, color: DesignTokens.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'checkout.free_shipping_banner'.tr(namedArgs: {'amount': '\$${remaining.toStringAsFixed(2)}'}),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DesignTokens.tertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: DesignTokens.outlineVariant,
              valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.tertiary),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ORDER REVIEW SHEET
// ============================================================================

/// Bottom sheet shown before Stripe redirect — lets the user review the full order.
class _OrderReviewSheet extends ConsumerWidget {
  final List<CartItemDetailModel> items;
  final double subtotal;
  final VoidCallback onConfirm;

  const _OrderReviewSheet({required this.items, required this.subtotal, required this.onConfirm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkoutStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final couponDiscount = state.couponDiscountCents / 100.0;
    final effectiveSubtotal = (subtotal - couponDiscount).clamp(0.0, double.infinity);
    final province = state.address?.state ?? ProvinceCodeValues.ontario;
    final taxRate = getTaxRate(province);
    final tax = (effectiveSubtotal + state.shippingCost) * taxRate;
    final total = effectiveSubtotal + state.shippingCost + tax;

    final bgColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: DesignTokens.outline.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2)),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [DesignTokens.primary, DesignTokens.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'checkout.order_review_title'.tr(),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('checkout.order_review_subtitle'.tr(), style: TextStyle(fontSize: 13, color: DesignTokens.textSecondary)),
            ),
            const Divider(height: 1),
            // Scrollable content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  // Items
                  Text(
                    'checkout.order_review_items'.tr(namedArgs: {'count': '${items.length}'}),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: item.imageUrls.isNotEmpty
                                ? Image.network(
                                    item.imageUrls.first,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _ItemImagePlaceholder(),
                                  )
                                : _ItemImagePlaceholder(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text('×${item.quantity}', style: TextStyle(fontSize: 13, color: DesignTokens.textSecondary)),
                              ],
                            ),
                          ),
                          Text('\$${(item.price * item.quantity).toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  // Shipping address
                  if (state.address != null) ...[
                    const Divider(height: 24),
                    Text('checkout.order_review_shipping_to'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GlassContainer(
                      child: Text(
                        state.address!.formattedAddress,
                        style: TextStyle(fontSize: 14, height: 1.5, color: isDark ? DesignTokens.outline : DesignTokens.textPrimary),
                      ),
                    ),
                  ],
                  // Price breakdown
                  const Divider(height: 24),
                  _buildPriceLine('cart.subtotal'.tr(), subtotal),
                  if (couponDiscount > 0)
                    _buildCouponLine(state.couponCode, couponDiscount),
                  _buildPriceLine('checkout.estimated_shipping'.tr(), state.shippingCost),
                  _buildPriceLine(
                    'checkout.tax_estimate_label'.tr(namedArgs: {'name': 'Tax', 'rate': (taxRate * 100).toStringAsFixed(2)}),
                    tax,
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('checkout.estimated_total'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: DesignTokens.primary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('checkout.tax_confirm_notice'.tr(), style: TextStyle(fontSize: 11, color: DesignTokens.textSecondary, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // Confirm & Pay button
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
              child: Semantics(
                button: true,
                label: 'btn-confirm-pay',
                child: ModernButton(
                  key: const Key('checkout_confirm_pay_button'),
                  label: 'checkout.order_review_confirm'.tr(),
                  onPressed: onConfirm,
                  icon: Icons.payment,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceLine(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: DesignTokens.textSecondary))),
          Text('\$${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, color: DesignTokens.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildCouponLine(String? code, double discount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer_rounded, size: 14, color: DesignTokens.success),
              const SizedBox(width: 4),
              Text(code != null ? 'Coupon ($code)' : 'Coupon', style: const TextStyle(fontSize: 14, color: DesignTokens.success)),
            ],
          ),
          Text('-\$${discount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: DesignTokens.success, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Small placeholder shown when a product image fails to load or is unavailable.
class _ItemImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: DesignTokens.outlineVariant, borderRadius: BorderRadius.circular(8)),
      child: Icon(Icons.image_outlined, size: 24, color: DesignTokens.textDisabled),
    );
  }
}

class _TermsText extends ConsumerWidget {
  const _TermsText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termsAccepted = ref.watch(_termsAcceptedProvider);
    final hasInteracted = ref.watch(_termsInteractedProvider);
    final showError = hasInteracted && !termsAccepted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DesignTokens.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: showError ? DesignTokens.error : DesignTokens.outlineVariant, width: 1),
        ),
        child: Row(
          key: const Key('checkout_terms_link'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: Semantics(
                label: 'chk-terms-accepted',
                checked: termsAccepted,
                child: Checkbox(
                  key: const Key('checkout_terms_checkbox'),
                  value: termsAccepted,
                  onChanged: (value) {
                    ref.read(_termsInteractedProvider.notifier).state = true;
                    ref.read(_termsAcceptedProvider.notifier).state = value ?? false;
                  },
                  side: BorderSide(color: showError ? DesignTokens.error : DesignTokens.textDisabled),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 13, color: DesignTokens.textPrimary, height: 1.4),
                  children: [
                    TextSpan(text: 'checkout.terms_agree'.tr()),
                    WidgetSpan(
                      child: Semantics(
                        link: true,
                        label: 'link-terms-conditions',
                        child: GestureDetector(
                          onTap: () => openTermsOfService(context),
                          child: Text(
                            'checkout.terms_link'.tr(),
                            style: TextStyle(
                              fontSize: 13,
                              color: DesignTokens.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: DesignTokens.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    TextSpan(text: ' ${'checkout.and_label'.tr()} '),
                    WidgetSpan(
                      child: Semantics(
                        link: true,
                        label: 'link-privacy-policy',
                        child: GestureDetector(
                          onTap: () => openPrivacyPolicy(context),
                          child: Text(
                            'checkout.privacy_link'.tr(),
                            style: TextStyle(
                              fontSize: 13,
                              color: DesignTokens.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: DesignTokens.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
