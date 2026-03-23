part of '../cart_screen.dart';

/// Individual cart item widget - only rebuilds when THIS item's data changes
class _CartItemWidget extends ConsumerWidget {
  final String cartItemDocId;

  const _CartItemWidget({super.key, required this.cartItemDocId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch only this specific item's details via family provider
    final itemAsync = ref.watch(cartItemDetailProvider(cartItemDocId));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return itemAsync.when(
      loading: () => ModernSkeletonLoader.wrap(
        isDark: isDark,
        child: Container(
          margin: const EdgeInsets.only(bottom: DesignTokens.spacing12),
          padding: const EdgeInsets.all(DesignTokens.spacing12),
          height: 104,
          decoration: BoxDecoration(
            color: DesignTokens.white,
            borderRadius: BorderRadius.circular(DesignTokens.radius16),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: DesignTokens.white,
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                ),
              ),
              const SizedBox(width: DesignTokens.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: DesignTokens.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 60,
                      height: 14,
                      decoration: BoxDecoration(
                        color: DesignTokens.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: DesignTokens.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: DesignTokens.error.withValues(alpha: 0.2),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: DesignTokens.error,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'cart.item_load_error'.tr(),
                  style: TextStyle(color: DesignTokens.error, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.invalidate(cartItemDetailProvider(cartItemDocId)),
                style: TextButton.styleFrom(
                  foregroundColor: DesignTokens.primary,
                ),
                child: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
      ),
      data: (item) {
        if (item == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: DesignTokens.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                border: Border.all(
                  color: DesignTokens.warning.withValues(alpha: 0.25),
                ),
              ),
              padding: const EdgeInsets.all(DesignTokens.spacing12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: DesignTokens.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'cart.item_no_longer_available'.tr(),
                      style: TextStyle(
                        color: DesignTokens.warningText,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref
                        .read(cartControllerProvider)
                        .removeFromCart(cartItemDocId),
                    style: TextButton.styleFrom(
                      foregroundColor: DesignTokens.warning,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: Text('common.remove'.tr()),
                  ),
                ],
              ),
            ),
          );
        }
        return CartItemScreen(
          productId: item.productId,
          cartItemId: cartItemDocId,
          item: item.toMap(),
          onRemove: () =>
              ref.read(cartControllerProvider).removeFromCart(cartItemDocId),
        );
      },
    );
  }
}
