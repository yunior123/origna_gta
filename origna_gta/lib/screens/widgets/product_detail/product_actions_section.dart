// coverage:ignore-file
import 'package:origna_gta/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/features/products/product_detail_viewmodel.dart';
import 'package:origna_gta/features/products/stock_notification_provider.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/modern_button.dart';

/// Variant selector + quantity + add-to-cart / buy-now section.
class VariantAndCartSection extends ConsumerWidget {
  final Product product;
  final ProductDetailViewModel viewModel;

  const VariantAndCartSection({
    super.key,
    required this.product,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productDetailViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasVariants =
        product.hasVariants && product.variantOptions.isNotEmpty;

    final selectedOptions = state.selectedOptions;
    final selectedVariantId = state.selectedVariantId;

    bool allOptionsSelected() {
      if (!hasVariants) return true;
      return product.variantOptions.every(
        (opt) => selectedOptions.containsKey(opt.name),
      );
    }

    ProductVariant? matchedVariant() {
      if (!hasVariants || selectedOptions.isEmpty) return null;
      for (final v in product.variants) {
        bool match = true;
        for (final entry in selectedOptions.entries) {
          final optName = entry.key.toLowerCase();
          final optVal = entry.value;
          if (v.optionValues[optName] != optVal &&
              v.optionValues[entry.key] != optVal) {
            match = false;
            break;
          }
        }
        if (match) return v;
      }
      return null;
    }

    final selectionIncomplete = hasVariants && !allOptionsSelected();
    final effectiveStock = product.hasVariants
        ? (selectionIncomplete ? null : matchedVariant()?.stockQuantity ?? 0)
        : product.stockQuantity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasVariants) ...[
          ...product.variantOptions.map((opt) {
            final optName = opt.name;
            final values = opt.values;
            final selected = selectedOptions[optName];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    optName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? DesignTokens.white : DesignTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: values.map((val) {
                      final isSelected = selected == val;
                      return GestureDetector(
                        onTap: () {
                          final newOptions = {...selectedOptions, optName: val};
                          String? newVariantId;
                          for (final v in product.variants) {
                            bool match = true;
                            for (final entry in newOptions.entries) {
                              final name = entry.key.toLowerCase();
                              final value = entry.value;
                              if (v.optionValues[name] != value &&
                                  v.optionValues[entry.key] != value) {
                                match = false;
                                break;
                              }
                            }
                            if (match) {
                              newVariantId = v.variantId;
                              break;
                            }
                          }
                          viewModel.setSelectedOption(
                            optName,
                            val,
                            variantId: newVariantId,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? DesignTokens.primary
                                : (isDark
                                      ? DesignTokens.darkCard
                                      : DesignTokens.white),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? DesignTokens.primary
                                  : DesignTokens.outline.withValues(alpha: 0.4),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            val,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? DesignTokens.white
                                  : (isDark
                                        ? DesignTokens.white
                                        : DesignTokens.textPrimary),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
          if (!allOptionsSelected())
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'product.select_all_options'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  color: DesignTokens.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
        if ((effectiveStock ?? 0) > 0 && (effectiveStock ?? 0) <= 10)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 16,
                  color: DesignTokens.warning,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'product.low_stock'.tr(
                      namedArgs: {'count': '${effectiveStock ?? 0}'},
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: DesignTokens.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        QuantitySelector(viewModel: viewModel),
        const SizedBox(height: 24),
        AddToCartButton(
          productId: product.productId,
          sellerId: product.sellerId,
          stockQuantity: effectiveStock ?? 0,
          variantKey: selectedVariantId,
          selectionIncomplete: selectionIncomplete,
        ),
      ],
    );
  }
}

/// Quantity selector row with +/- buttons.
class QuantitySelector extends ConsumerWidget {
  final ProductDetailViewModel viewModel;

  const QuantitySelector({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantity = ref.watch(
      productDetailViewModelProvider.select((state) => state.quantity),
    );

    return Row(
      children: [
        Text(
          '${'product.quantity'.tr()}:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).brightness == Brightness.dark
                ? DesignTokens.white
                : DesignTokens.textPrimary,
          ),
        ),
        const SizedBox(width: 20),
        GlassContainer(
          child: Row(
            children: [
              _QuantityButton(
                key: const Key('product_qty_minus'),
                icon: Icons.remove,
                onPressed: quantity > 1 ? viewModel.decrementQuantity : null,
                semanticLabel: 'btn-product-qty-minus',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$quantity',
                  key: const Key('product_qty_value'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _QuantityButton(
                key: const Key('product_qty_plus'),
                icon: Icons.add,
                onPressed: viewModel.incrementQuantity,
                semanticLabel: 'btn-product-qty-plus',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;

  const _QuantityButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      child: Material(
        color: DesignTokens.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          splashColor: DesignTokens.primary.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: onPressed != null
                  ? DesignTokens.primary
                  : DesignTokens.textDisabled,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// Add to cart + buy now buttons with stock notification support.
class AddToCartButton extends ConsumerStatefulWidget {
  final String productId;
  final String sellerId;
  final int stockQuantity;
  final String? variantKey;
  final bool selectionIncomplete;

  const AddToCartButton({
    super.key,
    required this.productId,
    required this.sellerId,
    required this.stockQuantity,
    this.variantKey,
    this.selectionIncomplete = false,
  });

  @override
  ConsumerState<AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends ConsumerState<AddToCartButton> {
  bool _isBuyingNow = false;

  @override
  Widget build(BuildContext context) {
    final quantity = ref.watch(
      productDetailViewModelProvider.select((state) => state.quantity),
    );
    final currentUser = ref.watch(currentUserProvider);
    final isOwnProduct =
        currentUser != null && currentUser.uid == widget.sellerId;

    if (isOwnProduct) {
      return Semantics(
        label: 'product_own_product_message',
        container: true,
        child: Column(
          key: const Key('product_own_product_message'),
          children: [
            ModernButton(
              label: 'product.own_product_title'.tr(),
              onPressed: null,
              fullWidth: true,
              icon: Icons.storefront,
            ),
            const SizedBox(height: 8),
            Text(
              'product.own_product_msg'.tr(),
              style: TextStyle(
                fontSize: 13,
                color: DesignTokens.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.selectionIncomplete) {
      return Semantics(
        label: 'product_variant_selection_required',
        container: true,
        child: Column(
          key: const Key('product_variant_selection_required'),
          children: [
            ModernButton(
              label: 'product.select_all_options'.tr(),
              onPressed: null,
              fullWidth: true,
              icon: Icons.tune_rounded,
            ),
            const SizedBox(height: 8),
            Text(
              'product.select_all_options'.tr(),
              style: TextStyle(
                fontSize: 13,
                color: DesignTokens.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.stockQuantity <= 0) {
      final notifState = ref.watch(
        stockNotificationNotifierProvider((
          productId: widget.productId,
          variantKey: widget.variantKey,
        )),
      );
      final isSubscribed = notifState.value ?? false;
      final isLoading = notifState.isLoading;
      return Semantics(
        label: 'product_notify_section',
        container: true,
        child: Column(
          key: const Key('product_notify_section'),
          children: [
            ModernButton(
              key: const Key('product_notify_me_button'),
              semanticsLabel: 'product_notify_me_button',
              label: isSubscribed
                  ? 'product.notify_cancel'.tr()
                  : 'product.notify_me'.tr(),
              onPressed: isLoading
                  ? null
                  : () => _toggleNotification(
                      context,
                      ref.read(currentUserProvider),
                    ),
              fullWidth: true,
              icon: isSubscribed
                  ? Icons.notifications_off_outlined
                  : Icons.notifications_outlined,
            ),
            const SizedBox(height: 8),
            Text(
              'product.out_of_stock'.tr(),
              style: TextStyle(
                fontSize: 13,
                color: DesignTokens.error,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ModernButton(
          label: 'product.buy_now'.tr(),
          semanticsLabel: 'product_buy_now_button',
          onPressed: _isBuyingNow
              ? null
              : () => _handleBuyNow(context, quantity),
          isLoading: _isBuyingNow,
          key: const Key('product_buy_now_button'),
          fullWidth: true,
          icon: Icons.bolt_rounded,
        ),
        const SizedBox(height: 12),
        ModernButton(
          label: 'product.add_to_cart'.tr(),
          semanticsLabel: 'product_add_to_cart_button',
          isOutlined: true,
          onPressed: () async {
            final user = ref.read(currentUserProvider);
            if (user == null) {
              if (context.mounted) showLoginPrompt(context);
              return;
            }
            if (context.mounted) {
              final verified = await checkEmailVerifiedOrPrompt(context, ref);
              if (!verified) return;
            }
            if (!context.mounted) return;
            final messenger = ScaffoldMessenger.of(context);
            final success = await ref
                .read(cartControllerProvider)
                .addToCart(
                  widget.productId,
                  quantity,
                  variantId: widget.variantKey,
                );

            if (success) {
              HapticFeedback.mediumImpact();
            } else {
              HapticFeedback.vibrate();
            }

            if (context.mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'cart.added_success'.tr()
                        : 'cart.added_failure'.tr(),
                  ),
                  backgroundColor: success
                      ? DesignTokens.success
                      : DesignTokens.error,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          },
          key: const Key('product_add_to_cart_button'),
          fullWidth: true,
          icon: Icons.shopping_cart_checkout,
        ),
      ],
    );
  }

  Future<void> _handleBuyNow(BuildContext context, int quantity) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (context.mounted) showLoginPrompt(context);
      return;
    }
    if (context.mounted) {
      final verified = await checkEmailVerifiedOrPrompt(context, ref);
      if (!verified) return;
    }
    if (!context.mounted) return;

    setState(() => _isBuyingNow = true);
    try {
      final success = await ref
          .read(cartControllerProvider)
          .addToCart(widget.productId, quantity,
              variantId: widget.variantKey);
      if (!success || !context.mounted) return;

      final cartDetails = await ref.read(cartWithDetailsProvider.future);
      if (!context.mounted) return;
      if (cartDetails.isEmpty) return;

      final subtotal = cartDetails.fold(
        0.0,
        (total, item) => total + (item.price * item.quantity),
      );
      Navigator.pushNamed(
        context,
        AppRoutes.checkout,
        arguments: CheckoutArgs(items: cartDetails, total: subtotal),
      );
    } finally {
      if (mounted) setState(() => _isBuyingNow = false);
    }
  }

  Future<void> _toggleNotification(
    BuildContext context,
    AppAuthUser? currentUser,
  ) async {
    if (currentUser == null) {
      showLoginPrompt(context);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(
      stockNotificationNotifierProvider((
        productId: widget.productId,
        variantKey: widget.variantKey,
      )).notifier,
    );
    final isSubscribed =
        ref
            .read(
              stockNotificationNotifierProvider((
                productId: widget.productId,
                variantKey: widget.variantKey,
              )),
            )
            .value ??
        false;
    try {
      if (isSubscribed) {
        await notifier.unsubscribe();
        if (context.mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('product.notify_cancelled'.tr()),
              backgroundColor: DesignTokens.textSecondary,
            ),
          );
        }
      } else {
        await notifier.subscribe();
        if (context.mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('product.notify_subscribed'.tr()),
              backgroundColor: DesignTokens.success,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content:
                Text(AppError.getMessage(e, 'product.notify_error'.tr())),
            backgroundColor: DesignTokens.error,
          ),
        );
      }
    }
  }
}

/// Sticky bottom CTA bar for mobile — shows price + add-to-cart.
class StickyBottomCTA extends ConsumerWidget {
  final Product product;
  final bool isOutOfStock;
  final bool isDark;

  const StickyBottomCTA({
    super.key,
    required this.product,
    required this.isOutOfStock,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantity = ref.watch(
      productDetailViewModelProvider.select((s) => s.quantity),
    );

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? DesignTokens.darkSurface.withValues(alpha: 0.96)
              : DesignTokens.white.withValues(alpha: 0.96),
          border: Border(
            top: BorderSide(
              color: DesignTokens.primary.withValues(alpha: 0.15),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${(product.price * quantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: DesignTokens.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (quantity > 1)
                    Text(
                      '\$${product.price.toStringAsFixed(2)} × $quantity',
                      style: const TextStyle(
                        fontSize: 11,
                        color: DesignTokens.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AddToCartButton(
                productId: product.productId,
                sellerId: product.sellerId,
                stockQuantity: product.stockQuantity,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
