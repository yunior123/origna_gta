part of '../checkout_screen.dart';

class _OrderSummary extends ConsumerWidget {
  final List<CartItemDetailModel> items;
  final double subtotal;
  final String state;

  const _OrderSummary({
    required this.items,
    required this.subtotal,
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shippingCost = ref.watch(
      checkoutStateProvider.select((state) => state.shippingCost),
    );
    final isCalculating = ref.watch(
      checkoutStateProvider.select((state) => state.isCalculatingShipping),
    );
    final shippingError = ref.watch(
      checkoutStateProvider.select((state) => state.shippingError),
    );
    final isPremium =
        ref.watch(
          subscriptionStreamProvider.select((a) => a.valueOrNull?.isPremium),
        ) ??
        false;
    // Tax breakdown and rates computed in providers — no business logic in build()
    final taxBreakdown = ref.watch(
      checkoutTaxBreakdownProvider((subtotal: subtotal, province: state)),
    );
    final taxRatesMap = ref.watch(checkoutProvinceRatesMapProvider(state));

    return Column(
      key: const Key('checkout_summary_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'checkout.order_summary_title'.tr(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? DesignTokens.darkCard
                : DesignTokens.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.name} x${item.quantity}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'cart.subtotal'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\$${subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildCouponDiscountRow(ref),
              _buildPlatformFeeRow(ref, isPremium),
              ..._buildTaxBreakdownRows(taxBreakdown, taxRatesMap),
              const SizedBox(height: 8),
              Row(
                key: const Key('checkout_shipping_section'),
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'checkout.estimated_shipping'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: DesignTokens.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isCalculating)
                    const ModernLoadingIndicator.small()
                  else if (shippingError != null)
                    Text(
                      shippingError,
                      style: const TextStyle(
                        color: DesignTokens.error,
                        fontSize: 12,
                      ),
                    )
                  else
                    Text(
                      '\$${shippingCost.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              if (!isCalculating &&
                  shippingError == null &&
                  shippingCost > 0) ...[
                const SizedBox(height: 4),
                // Per-seller shipping breakdown (FEAT-3)
                Builder(
                  builder: (context) {
                    final sellerCosts = ref.watch(
                      checkoutStateProvider.select(
                        (s) => s.sellerShippingCosts,
                      ),
                    );
                    final sellerNames = ref.watch(
                      checkoutStateProvider.select((s) => s.sellerNames),
                    );
                    if (sellerCosts.length <= 1) return const SizedBox.shrink();

                    return Column(
                      children: sellerCosts.entries.map((entry) {
                        final name = sellerNames[entry.key] ?? entry.key;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2, left: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ' • $name',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: DesignTokens.textTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '\$${entry.value.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: DesignTokens.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'checkout.shipping_confirmed_by_seller'.tr(),
                    style: TextStyle(
                      fontSize: 11,
                      color: DesignTokens.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'checkout.estimated_total'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Builder(
                    builder: (context) {
                      // Total computed in provider — no business logic in build()
                      final total = ref.watch(
                        checkoutBuyerTotalProvider((
                          subtotal: subtotal,
                          province: state,
                        )),
                      );
                      return Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: DesignTokens.primary,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'checkout.tax_confirm_notice'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  color: DesignTokens.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Builder(
                builder: (context) {
                  final hasIntl = ref.watch(
                    checkoutStateProvider.select(
                      (s) => s.hasInternationalItems,
                    ),
                  );
                  if (!hasIntl) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: DesignTokens.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: DesignTokens.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: DesignTokens.warning,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'checkout.brokerage_fee_warning'.tr(),
                              style: TextStyle(
                                fontSize: 11,
                                color: DesignTokens.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCouponDiscountRow(WidgetRef ref) {
    final discountCents = ref.watch(
      checkoutStateProvider.select((s) => s.couponDiscountCents),
    );
    final couponCode = ref.watch(
      checkoutStateProvider.select((s) => s.couponCode),
    );
    if (discountCents <= 0 || couponCode == null) {
      return const SizedBox.shrink();
    }
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
                    'checkout.coupon_applied_label'.tr(
                      namedArgs: {'code': couponCode},
                    ),
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
            '-\$${(discountCents / 100.0).toStringAsFixed(2)}',
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

  Widget _buildPlatformFeeRow(WidgetRef ref, bool isPremium) {
    // Platform fee computed in provider — no business logic in build()
    final feeAmount = ref.watch(checkoutPlatformFeeProvider(subtotal));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              children: [
                Icon(
                  isPremium ? Icons.star_rounded : Icons.info_outline_rounded,
                  size: 14,
                  color: isPremium
                      ? DesignTokens.secondary
                      : DesignTokens.textSecondary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'checkout.service_fee_label'.tr(
                      namedArgs: {
                        'rate': BusinessRules.platformFeePercent
                            .toStringAsFixed(1),
                      },
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: isPremium
                          ? DesignTokens.textSecondary
                          : DesignTokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isPremium)
            Row(
              children: [
                Text(
                  '\$${feeAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: DesignTokens.textDisabled,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: DesignTokens.textDisabled,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        DesignTokens.gradientStart,
                        DesignTokens.gradientEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'checkout.service_fee_free'.tr(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: DesignTokens.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              '\$${feeAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                color: DesignTokens.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  /// Renders pre-computed tax breakdown rows.
  /// Tax amounts are computed in [checkoutTaxBreakdownProvider] — this method
  /// only handles presentation.
  List<Widget> _buildTaxBreakdownRows(
    Map<String, double> taxBreakdown,
    Map<String, double> rates,
  ) {
    List<Widget> widgets = [];

    taxBreakdown.forEach((taxName, taxAmount) {
      final rate = rates[taxName] ?? 0.0;
      widgets.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'checkout.tax_estimate_label'.tr(
                  namedArgs: {
                    'name': taxName,
                    'rate': (rate * 100).toStringAsFixed(2),
                  },
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: DesignTokens.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '\$${taxAmount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 14, color: DesignTokens.textSecondary),
            ),
          ],
        ),
      );
      widgets.add(const SizedBox(height: 4));
    });

    // Excise Tax Act s.223: GST/HST registration number must appear on sales receipts
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          'GST/HST Reg: ${EmailConfig.gstHstNumber}',
          style: TextStyle(fontSize: 11, color: DesignTokens.textSecondary),
        ),
      ),
    );

    return widgets;
  }
}
