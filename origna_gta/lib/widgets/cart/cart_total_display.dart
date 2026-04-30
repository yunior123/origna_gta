import 'package:flutter/material.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_textfield.dart';

/// Cart total display with info icons and delivery instructions
class CartTotalDisplay extends ConsumerWidget {
  const CartTotalDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deliveryInstructions = ref.watch(deliveryInstructionsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.primary.withValues(alpha: 0.08),
            DesignTokens.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(
          color: DesignTokens.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubtotalRow(isDark),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _buildServiceFeesRow(context, isDark),
          const SizedBox(height: 8),
          _buildTaxEstimateRow(context, isDark),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _buildEstimatedTotalRow(isDark),
          _buildDeliveryInstructionsRow(
            context,
            ref,
            isDark,
            deliveryInstructions,
          ),
        ],
      ),
    );
  }

  Widget _buildSubtotalRow(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Consumer(
            builder: (context, ref, _) {
              final totalItems = ref.watch(cartItemCountProvider);
              return Text(
                '${'cart.subtotal_with_count'.tr(namedArgs: {'count': totalItems.toString()})}:',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? DesignTokens.white : DesignTokens.textPrimary,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Consumer(
            builder: (context, ref, _) {
              final subtotalAsync = ref.watch(
                cartWithDetailsProvider.select(
                  (async) => async.whenData(
                    (items) => items.fold(
                      0.0,
                      (total, item) =>
                          total + ((item.priceCents * item.quantity) / 100.0),
                    ),
                  ),
                ),
              );
              return subtotalAsync.when(
                loading: () => const SizedBox(width: 100, height: 28),
                error: (_, _) => const SizedBox.shrink(),
                data: (subtotal) => ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [DesignTokens.primary, DesignTokens.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      NumberFormat.currency(
                        locale: "en_CA",
                        symbol: "CAD \$",
                      ).format(subtotal),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: DesignTokens.white,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceFeesRow(BuildContext context, bool isDark) {
    return Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: DesignTokens.info.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'cart.service_fees'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? DesignTokens.outlineVariant
                  : DesignTokens.textPrimary,
            ),
          ),
        ),
        Text(
          '${BusinessRules.platformFeePercent.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark
                ? DesignTokens.outlineVariant
                : DesignTokens.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: 'cart.service_fee_tooltip'.tr(
            namedArgs: {
              'percent': BusinessRules.platformFeePercent.toStringAsFixed(1),
            },
          ),
          child: Semantics(
            button: true,
            label: 'btn-info-service-fee',
            child: InkWell(
              onTap: () => _showInfoSheet(
                context,
                'cart.service_fees'.tr(),
                'cart.service_fee_info'.tr(
                  namedArgs: {
                    'percent': BusinessRules.platformFeePercent.toStringAsFixed(
                      1,
                    ),
                  },
                ),
              ),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: DesignTokens.info.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaxEstimateRow(BuildContext context, bool isDark) {
    return Row(
      children: [
        Icon(
          Icons.receipt_long_outlined,
          size: 16,
          color: DesignTokens.warning.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'cart.tax_estimate'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? DesignTokens.outlineVariant
                  : DesignTokens.textPrimary,
            ),
          ),
        ),
        Consumer(
          builder: (context, ref, _) {
            final profileProvince = ref.watch(
              userProfileProvider.select((a) => a.valueOrNull?.address?.state),
            );
            final province =
                (profileProvince == null || profileProvince.trim().isEmpty)
                ? ProvinceCodeValues.ontario
                : profileProvince.trim();
            final subtotalAsync = ref.watch(
              cartWithDetailsProvider.select(
                (async) => async.whenData(
                  (items) => items.fold(
                    0.0,
                    (total, item) =>
                        total + ((item.priceCents * item.quantity) / 100.0),
                  ),
                ),
              ),
            );
            return subtotalAsync.when(
              loading: () => const SizedBox(width: 70, height: 16),
              error: (_, _) => const SizedBox.shrink(),
              data: (subtotal) {
                final estimatedTax = subtotal * getTaxRate(province);
                return Text(
                  NumberFormat.currency(
                    locale: "en_CA",
                    symbol: "CAD \$",
                  ).format(estimatedTax),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? DesignTokens.outlineVariant
                        : DesignTokens.textPrimary,
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: 'cart.tax_tooltip'.tr(),
          child: Semantics(
            button: true,
            label: 'btn-info-tax-estimate',
            child: InkWell(
              onTap: () => _showInfoSheet(
                context,
                'cart.tax_estimate_title'.tr(),
                'cart.tax_info'.tr(),
              ),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: DesignTokens.info.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstimatedTotalRow(bool isDark) {
    return Consumer(
      builder: (context, ref, _) {
        final profileProvince = ref.watch(
          userProfileProvider.select((a) => a.valueOrNull?.address?.state),
        );
        final province =
            (profileProvince == null || profileProvince.trim().isEmpty)
            ? ProvinceCodeValues.ontario
            : profileProvince.trim();
        final subtotalAsync = ref.watch(
          cartWithDetailsProvider.select(
            (async) => async.whenData(
              (items) => items.fold(
                0.0,
                (t, item) => t + ((item.priceCents * item.quantity) / 100.0),
              ),
            ),
          ),
        );
        return subtotalAsync.maybeWhen(
          data: (subtotal) {
            final tax = subtotal * getTaxRate(province);
            final estimatedTotal = subtotal + tax;
            return Column(
              children: [
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'checkout.estimated_total'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? DesignTokens.white
                              : DesignTokens.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      NumberFormat.currency(
                        locale: 'en_CA',
                        symbol: 'CAD \$',
                      ).format(estimatedTotal),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildDeliveryInstructionsRow(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    String deliveryInstructions,
  ) {
    return Semantics(
      button: true,
      label: 'btn-delivery-instructions',
      child: InkWell(
        onTap: () =>
            _showDeliveryInstructionsDialog(context, ref, deliveryInstructions),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isDark
                ? DesignTokens.white.withValues(alpha: 0.05)
                : DesignTokens.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: deliveryInstructions.isNotEmpty
                  ? DesignTokens.primary.withValues(alpha: 0.3)
                  : DesignTokens.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.edit_note_outlined,
                size: 20,
                color: deliveryInstructions.isNotEmpty
                    ? DesignTokens.primary
                    : (isDark
                          ? DesignTokens.textDisabled
                          : DesignTokens.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'common.delivery_instructions'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? DesignTokens.white
                            : DesignTokens.textPrimary,
                      ),
                    ),
                    if (deliveryInstructions.isNotEmpty)
                      Text(
                        deliveryInstructions,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? DesignTokens.textDisabled
                              : DesignTokens.textSecondary,
                        ),
                      )
                    else
                      Text(
                        'cart.add_instructions_optional'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? DesignTokens.textSecondary
                              : DesignTokens.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: isDark
                    ? DesignTokens.textDisabled
                    : DesignTokens.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoSheet(BuildContext context, String title, String content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.darkCard : DesignTokens.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DesignTokens.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: DesignTokens.info,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? DesignTokens.white
                          : DesignTokens.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: isDark
                    ? DesignTokens.outlineVariant
                    : DesignTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            ModernButton(
              label: 'common.understood'.tr(),
              onPressed: () => appPop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeliveryInstructionsDialog(
    BuildContext context,
    WidgetRef ref,
    String currentInstructions,
  ) {
    final controller = TextEditingController(text: currentInstructions);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? DesignTokens.darkCard : DesignTokens.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit_note_outlined, color: DesignTokens.primary),
            const SizedBox(width: 12),
            Text('common.delivery_instructions'.tr()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'cart.delivery_instructions_desc'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? DesignTokens.outlineVariant
                    : DesignTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ModernTextField(
              controller: controller,
              hint: 'cart.delivery_hint'.tr(),
              isMultiline: true,
              maxLines: 4,
              minLines: 3,
              maxLength: 500,
              showCounter: true,
            ),
          ],
        ),
        actions: [
          Semantics(
            label: 'btn-cart-note-cancel',
            button: true,
            child: TextButton(
              onPressed: () => appPop(context),
              style: TextButton.styleFrom(
                foregroundColor: DesignTokens.textSecondary,
              ),
              child: Text('common.cancel'.tr()),
            ),
          ),
          ModernButton(
            label: 'common.save'.tr(),
            fullWidth: false,
            height: 40,
            onPressed: () {
              ref.read(deliveryInstructionsProvider.notifier).state = controller
                  .text
                  .trim();
              appPop(context);
            },
          ),
        ],
      ),
    );
  }
}
