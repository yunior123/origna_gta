part of '../checkout_screen.dart';

class _DeliveryOptionsSection extends ConsumerWidget {
  const _DeliveryOptionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableSpeeds = ref.watch(
      checkoutStateProvider.select((state) => state.availableDeliverySpeeds),
    );
    final selectedSpeed = ref.watch(
      checkoutStateProvider.select((state) => state.deliverySpeed),
    );
    final isCalculating = ref.watch(
      checkoutStateProvider.select((state) => state.isCalculatingShipping),
    );
    final baseShippingCost = ref.watch(
      checkoutStateProvider.select((state) => state.baseShippingCost),
    );

    if (isCalculating) {
      final isDarkCalc = Theme.of(context).brightness == Brightness.dark;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'checkout.delivery_speed_title'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(
                width: 20,
                height: 20,
                child: ModernLoadingIndicator(
                  strokeWidth: 2.5,
                  color: DesignTokens.primary,
                  centered: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── AUDIT FIX [HIGH]: Skeleton cards replace blank space while calculating ──
          for (int i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: isDarkCalc
                      ? DesignTokens.darkCard.withValues(alpha: 0.7)
                      : DesignTokens.outlineVariant.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'checkout.delivery_speed_title'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
          final totalCost = speed == DeliverySpeed.standard
              ? baseShippingCost
              : baseShippingCost + speed.baseSurcharge;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Semantics(
              button: true,
              label: 'btn-delivery-speed-${speed.name}',
              child: GestureDetector(
                key: Key('checkout_delivery_speed_${speed.name}'),
                onTap: isAvailable
                    ? () => ref
                          .read(checkoutStateProvider.notifier)
                          .setDeliverySpeed(speed)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // ── AUDIT FIX [HIGH]: was DesignTokens.white — not dark-mode safe ──
                    color: isSelected
                        ? DesignTokens.primary.withValues(alpha: 0.08)
                        : (Theme.of(context).brightness == Brightness.dark
                              ? DesignTokens.darkCard
                              : DesignTokens.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? DesignTokens.primary
                          : DesignTokens.outlineVariant,
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DesignTokens.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
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
                            border: Border.all(
                              color: isSelected
                                  ? DesignTokens.primary
                                  : DesignTokens.outline,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: DesignTokens.primary,
                                    ),
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
                                  Flexible(
                                    child: Text(
                                      speed.translatedName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: isAvailable
                                            ? DesignTokens.textPrimary
                                            : DesignTokens.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (speed == DeliverySpeed.sameDay) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: DesignTokens.success,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'checkout.local'.tr(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: DesignTokens.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                speed.translatedTime,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: DesignTokens.textSecondary,
                                ),
                              ),
                              if (!isAvailable &&
                                  speed == DeliverySpeed.sameDay)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'checkout.local_only_50km'.tr(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: DesignTokens.tertiary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          totalCost > 0
                              ? '\$${totalCost.toStringAsFixed(2)}'
                              : 'checkout.free'.tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: totalCost > 0
                                ? DesignTokens.textPrimary
                                : DesignTokens.success,
                          ),
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
              final surcharge = speed == DeliverySpeed.standard
                  ? 0.0
                  : speed.baseSurcharge;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          speed.translatedName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (speed == DeliverySpeed.sameDay) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.success,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'checkout.local'.tr(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: DesignTokens.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      speed.translatedTime,
                      style: TextStyle(
                        fontSize: 13,
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                    if (speed == DeliverySpeed.sameDay)
                      Text(
                        'checkout.available_local_50km'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: DesignTokens.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      surcharge > 0
                          ? 'checkout.additional_cost'.tr(
                              namedArgs: {
                                'amount': surcharge.toStringAsFixed(2),
                              },
                            )
                          : 'checkout.no_additional_cost'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: surcharge > 0
                            ? DesignTokens.textPrimary
                            : DesignTokens.success,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.close'.tr()),
          ),
        ],
      ),
    );
  }
}

class _OrderReviewSheet extends ConsumerWidget {
  final List<CartItemDetailModel> items;
  final double subtotal;
  final VoidCallback onConfirm;

  const _OrderReviewSheet({
    required this.items,
    required this.subtotal,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use targeted selects so this sheet only rebuilds when the fields it
    // actually reads change — not on every checkoutStateProvider mutation.
    final couponDiscountCents = ref.watch(
      checkoutStateProvider.select((s) => s.couponDiscountCents),
    );
    final addressState = ref.watch(
      checkoutStateProvider.select((s) => s.address?.state),
    );
    final formattedAddress = ref.watch(
      checkoutStateProvider.select((s) => s.address?.formattedAddress),
    );
    final couponCode = ref.watch(
      checkoutStateProvider.select((s) => s.couponCode),
    );
    final shippingCost = ref.watch(
      checkoutStateProvider.select((s) => s.shippingCost),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // All business logic computed in providers — screen only renders.
    final province = addressState ?? ProvinceCodeValues.ontario;
    final taxRate = ref.watch(checkoutProvinceTaxRateProvider(province));
    final couponDiscount = ref.watch(checkoutCouponDiscountDollarsProvider);
    final total = ref.watch(
      checkoutBuyerTotalProvider((subtotal: subtotal, province: province)),
    );
    final tax = ref.watch(
      checkoutTaxAmountProvider((subtotal: subtotal, province: province)),
    );

    final bgColor = isDark ? DesignTokens.darkCard : DesignTokens.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DesignTokens.outline.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Flexible(
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [DesignTokens.primary, DesignTokens.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'checkout.order_review_title'.tr(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: DesignTokens.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'checkout.order_review_subtitle'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  color: DesignTokens.textSecondary,
                ),
              ),
            ),
            const Divider(height: 1),
            // Scrollable content
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: items.length + 1, // items + summary section
                itemBuilder: (context, index) {
                  // Item rows
                  if (index < items.length) {
                    final item = items[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        top: index == 0 ? 0 : 0,
                        bottom: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (index == 0) ...[
                            Text(
                              'checkout.order_review_items'.tr(
                                namedArgs: {'count': '${items.length}'},
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: item.imageUrls.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: item.imageUrls.first,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            _ItemImagePlaceholder(),
                                        errorWidget: (context, url, error) =>
                                            _ItemImagePlaceholder(),
                                      )
                                    : _ItemImagePlaceholder(),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '×${item.quantity}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: DesignTokens.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                  // Summary section (last item)
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shipping address
                      if (formattedAddress != null) ...[
                        const Divider(height: 24),
                        Text(
                          'checkout.order_review_shipping_to'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GlassContainer(
                          child: Text(
                            formattedAddress,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: isDark
                                  ? DesignTokens.outline
                                  : DesignTokens.textPrimary,
                            ),
                          ),
                        ),
                      ],
                      // Price breakdown
                      const Divider(height: 24),
                      _buildPriceLine('cart.subtotal'.tr(), subtotal),
                      if (couponDiscount > 0)
                        _buildCouponLine(couponCode, couponDiscount),
                      _buildPriceLine(
                        'checkout.estimated_shipping'.tr(),
                        shippingCost,
                      ),
                      _buildPriceLine(
                        'checkout.tax_estimate_label'.tr(
                          namedArgs: {
                            'name': 'checkout.tax_label'.tr(),
                            'rate': (taxRate * 100).toStringAsFixed(2),
                          },
                        ),
                        tax,
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'checkout.estimated_total'.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: DesignTokens.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'checkout.tax_confirm_notice'.tr(),
                        style: TextStyle(
                          fontSize: 11,
                          color: DesignTokens.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ),
            // Confirm & Pay button
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).padding.bottom + 16,
              ),
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
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: DesignTokens.textSecondary),
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 14, color: DesignTokens.textSecondary),
          ),
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
          Flexible(
            child: Row(
              children: [
                const Icon(
                  Icons.local_offer_rounded,
                  size: 14,
                  color: DesignTokens.success,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    code != null
                        ? 'checkout.coupon_applied_label'.tr(
                            namedArgs: {'code': code},
                          )
                        : 'checkout.coupon_applied_generic'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: DesignTokens.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '-\$${discount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              color: DesignTokens.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsText extends ConsumerWidget {
  const _TermsText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termsAccepted = ref.watch(checkoutTermsAcceptedProvider);
    final hasInteracted = ref.watch(checkoutTermsInteractedProvider);
    final showError = hasInteracted && !termsAccepted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DesignTokens.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: showError ? DesignTokens.error : DesignTokens.outlineVariant,
            width: 1,
          ),
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
                    ref.read(checkoutTermsInteractedProvider.notifier).state =
                        true;
                    ref.read(checkoutTermsAcceptedProvider.notifier).state =
                        value ?? false;
                  },
                  side: BorderSide(
                    color: showError
                        ? DesignTokens.error
                        : DesignTokens.textDisabled,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    color: DesignTokens.textPrimary,
                    height: 1.4,
                  ),
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

/// EULA checkbox shown when digital products (software, ebooks, etc.) are in the cart.
/// Canadian consumer law requires explicit license acceptance before digital delivery.
class _DigitalEulaText extends ConsumerWidget {
  const _DigitalEulaText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eulaAccepted = ref.watch(checkoutEulaAcceptedProvider);
    final hasInteracted = ref.watch(checkoutEulaInteractedProvider);
    final showError = hasInteracted && !eulaAccepted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DesignTokens.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: showError ? DesignTokens.error : DesignTokens.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          key: const Key('checkout_digital_eula'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: Semantics(
                label: 'chk-eula-accepted',
                checked: eulaAccepted,
                child: Checkbox(
                  key: const Key('checkout_eula_checkbox'),
                  value: eulaAccepted,
                  onChanged: (value) {
                    ref.read(checkoutEulaInteractedProvider.notifier).state =
                        true;
                    ref.read(checkoutEulaAcceptedProvider.notifier).state =
                        value ?? false;
                  },
                  side: BorderSide(
                    color: showError
                        ? DesignTokens.error
                        : DesignTokens.textDisabled,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'checkout.digital_eula_agree'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  color: DesignTokens.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Age gate widget — shown when cart contains age-restricted items.
/// Canadian law (CRTC / provincial liquor/tobacco acts) requires age confirmation before purchase.
class _AgeGateText extends ConsumerWidget {
  const _AgeGateText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ageVerifAccepted = ref.watch(checkoutAgeVerifAcceptedProvider);
    final hasInteracted = ref.watch(checkoutAgeVerifInteractedProvider);
    final showError = hasInteracted && !ageVerifAccepted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DesignTokens.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: showError ? DesignTokens.error : DesignTokens.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          key: const Key('checkout_age_gate'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: Semantics(
                label: 'chk-age-gate-accepted',
                checked: ageVerifAccepted,
                child: Checkbox(
                  key: const Key('checkout_age_gate_checkbox'),
                  value: ageVerifAccepted,
                  onChanged: (value) {
                    ref
                            .read(checkoutAgeVerifInteractedProvider.notifier)
                            .state =
                        true;
                    ref.read(checkoutAgeVerifAcceptedProvider.notifier).state =
                        value ?? false;
                  },
                  side: BorderSide(
                    color: showError
                        ? DesignTokens.error
                        : DesignTokens.textDisabled,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'checkout.age_gate_agree'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  color: DesignTokens.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// @Preview skipped — requires live auth/navigation context
// CheckoutScreen requires List<CartItemDetailModel> which depends on live database/Timestamp.
