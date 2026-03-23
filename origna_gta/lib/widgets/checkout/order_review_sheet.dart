import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/checkout/checkout_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/modern_button.dart';

/// Draggable bottom sheet that shows the full order review before payment.
///
/// Displays cart items, shipping address, price breakdown (subtotal, coupon,
/// shipping, tax), and a confirm-and-pay button.
class OrderReviewSheet extends ConsumerWidget {
  final List<CartItemDetailModel> items;
  final double subtotal;
  final VoidCallback onConfirm;

  const OrderReviewSheet({
    super.key,
    required this.items,
    required this.subtotal,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use targeted selects so this sheet only rebuilds when the fields it
    // actually reads change — not on every checkoutStateProvider mutation.
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
                                            const _ItemImagePlaceholder(),
                                        errorWidget: (context, url, error) =>
                                            const _ItemImagePlaceholder(),
                                      )
                                    : const _ItemImagePlaceholder(),
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
                                      '\u00d7${item.quantity}',
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

/// Placeholder image shown when a cart item has no image or while loading.
class _ItemImagePlaceholder extends StatelessWidget {
  const _ItemImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            DesignTokens.primary.withValues(alpha: 0.1),
            DesignTokens.secondary.withValues(alpha: 0.07),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: DesignTokens.primary.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Icon(
        Icons.camera_alt_outlined,
        size: 22,
        color: DesignTokens.primary.withValues(alpha: 0.5),
      ),
    );
  }
}
