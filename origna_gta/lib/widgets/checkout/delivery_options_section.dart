import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/checkout/checkout_provider.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

/// Delivery speed selector for the checkout flow.
///
/// Shows skeleton cards while shipping costs are being calculated,
/// then renders selectable radio-style cards for each [DeliverySpeed].
class DeliveryOptionsSection extends ConsumerWidget {
  const DeliveryOptionsSection({super.key});

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
          Semantics(
            label: 'btn-delivery-options-close',
            button: true,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('common.close'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}
