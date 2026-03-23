import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';

/// Free shipping progress bar shown above the checkout button.
class FreeShippingBar extends ConsumerWidget {
  const FreeShippingBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtotalAsync = ref.watch(
      cartWithDetailsProvider.select(
        (async) => async.whenData(
          (items) => items.fold(
            0.0,
            (total, item) => total + (item.price * item.quantity),
          ),
        ),
      ),
    );

    return subtotalAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (subtotalDollars) {
        final thresholdDollars =
            BusinessRules.freeShippingThresholdCents / 100.0;
        final qualified = subtotalDollars >= thresholdDollars;
        final progress = (subtotalDollars / thresholdDollars).clamp(0.0, 1.0);
        final remaining = thresholdDollars - subtotalDollars;
        final remainingFormatted = NumberFormat.currency(
          locale: 'en_CA',
          symbol: '\$',
          decimalDigits: 2,
        ).format(remaining);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: qualified
                ? DesignTokens.success.withValues(alpha: isDark ? 0.12 : 0.08)
                : (isDark
                      ? DesignTokens.primary.withValues(alpha: 0.10)
                      : DesignTokens.surfaceSubtle),
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            border: Border.all(
              color: qualified
                  ? DesignTokens.success.withValues(alpha: 0.35)
                  : DesignTokens.primary.withValues(alpha: 0.20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                qualified
                    ? 'cart.free_shipping_qualified'.tr()
                    : 'cart.free_shipping_progress'.tr(
                        namedArgs: {'amount': remainingFormatted},
                      ),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: qualified
                      ? DesignTokens.success
                      : (isDark
                            ? DesignTokens.white
                            : DesignTokens.textPrimary),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: isDark
                      ? DesignTokens.white.withValues(alpha: 0.10)
                      : DesignTokens.outline.withValues(alpha: 0.4),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    qualified ? DesignTokens.success : DesignTokens.primary,
                  ),
                ),
              ),
              if (!qualified) ...[
                const SizedBox(height: 6),
                Text(
                  'cart.free_shipping_threshold'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? DesignTokens.textSecondary
                        : DesignTokens.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
