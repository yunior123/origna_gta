import 'package:origna_gta/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/gradient_badge.dart';
import 'package:origna_gta/widgets/modern_card.dart';

/// Price card with gradient background, compare-at-price strike-through, and discount badge.
class ProductPriceCard extends StatelessWidget {
  final Product product;
  final double displayPrice;

  const ProductPriceCard({
    super.key,
    required this.product,
    required this.displayPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.primary.withValues(alpha: 0.95),
            DesignTokens.secondary.withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.compareAtPrice case final compareAt?
                    when compareAt > product.price) ...[
                  Text(
                    '${'product.price'.tr()}:',
                    style: TextStyle(
                      color: DesignTokens.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    '\$${compareAt.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: DesignTokens.white.withValues(alpha: 0.7),
                      decoration: TextDecoration.lineThrough,
                      decorationColor: DesignTokens.white.withValues(alpha: 0.7),
                    ),
                  ),
                ] else
                  Text(
                    '${'product.price'.tr()}:',
                    style: const TextStyle(
                      color: DesignTokens.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                Text(
                  '\$${displayPrice.toStringAsFixed(2)}',
                  key: const Key('product_detail_price'),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: DesignTokens.white,
                  ),
                ),
              ],
            ),
          ),
          if (product.compareAtPrice case final compareAtDiscount?
              when compareAtDiscount > displayPrice)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '-${((1 - displayPrice / compareAtDiscount) * 100).round()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact delivery estimate chip shown below the price.
class DeliveryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const DeliveryChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Card showing delivery information (estimated time, origin, tracking).
class DeliveryInfoCard extends StatelessWidget {
  final Product product;

  const DeliveryInfoCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deliveryInfo = product.deliveryInfo;

    return ModernCard(
      padding: const EdgeInsets.all(DesignTokens.spacing16),
      borderRadius:
          const BorderRadius.all(Radius.circular(DesignTokens.radius12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                product.isDigital
                    ? Icons.download_rounded
                    : Icons.local_shipping_outlined,
                color: DesignTokens.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'product.details.delivery_information'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? DesignTokens.white : DesignTokens.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DeliveryInfoRow(
            icon: Icons.access_time_rounded,
            label: 'checkout.estimated_delivery'.tr(),
            value: localizedDeliveryEstimate(product),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          if (deliveryInfo.supplierRegion != null) ...[
            _DeliveryInfoRow(
              icon: Icons.public_rounded,
              label: 'product.ships_from'.tr(),
              value: localizedShipsFrom(product),
              isDark: isDark,
              isWarning: deliveryInfo.isInternational,
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          _DeliveryInfoRow(
            icon: deliveryInfo.hasTracking
                ? Icons.track_changes_rounded
                : Icons.info_outline_rounded,
            label: 'product.tracking'.tr(),
            value: deliveryInfo.hasTracking
                ? 'product.tracking_available'.tr()
                : 'product.tracking_limited'.tr(),
            isDark: isDark,
          ),
          if (product.freeShipping) ...[
            const SizedBox(height: 10),
            GradientBadge(
              label: 'product.free_shipping'.tr(),
              gradient: const LinearGradient(
                colors: [DesignTokens.success, DesignTokens.successDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ],
          if (deliveryInfo.isInternational) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DesignTokens.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: DesignTokens.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: DesignTokens.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'product.details.international_disclaimer'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: DesignTokens.warning,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeliveryInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool isWarning;

  const _DeliveryInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isWarning
              ? DesignTokens.warning
              : (isDark
                    ? DesignTokens.textOnDarkSecondary
                    : DesignTokens.textSecondary),
        ),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? DesignTokens.textOnDarkSecondary
                : DesignTokens.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isWarning
                  ? DesignTokens.warning
                  : (isDark
                        ? DesignTokens.textOnDark
                        : DesignTokens.textPrimary),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Delivery estimate text helper.
String localizedDeliveryEstimate(Product product) {
  final deliveryInfo = product.deliveryInfo;

  if (product.isDigital) {
    return 'product.delivery_instant'.tr();
  }

  if (product.isLocalDeliveryOnly) {
    return 'product.delivery_local_business_days'.tr(
      namedArgs: {
        'min': deliveryInfo.minDays.toString(),
        'max': deliveryInfo.maxDays.toString(),
      },
    );
  }

  return 'product.delivery_business_days'.tr(
    namedArgs: {
      'min': deliveryInfo.minDays.toString(),
      'max': deliveryInfo.maxDays.toString(),
    },
  );
}

/// Ships-from region text helper.
String localizedShipsFrom(Product product) {
  final region = product.deliveryInfo.supplierRegion;
  if (region == null || region.trim().isEmpty || region.startsWith('Unknown')) {
    return 'product.delivery_unknown_origin'.tr();
  }
  return region;
}
