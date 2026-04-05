part of '../cart_screen.dart';

/// Cart summary - only watches what it needs for display
class _CartSummary extends ConsumerWidget {
  final bool isSidebar;
  const _CartSummary({this.isSidebar = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEmpty = ref.watch(
      cartWithDetailsProvider.select(
        (async) => async.whenData((items) => items.isEmpty),
      ),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? DesignTokens.white.withValues(alpha: 0.06)
        : DesignTokens.outline.withValues(alpha: 0.3);

    return isEmpty.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (isEmpty) {
        if (isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacing16,
            vertical: DesignTokens.spacing20,
          ),
          decoration: BoxDecoration(
            color: isDark ? DesignTokens.darkCard : DesignTokens.white,
            border: isSidebar
                ? Border.all(color: borderColor)
                : Border(top: BorderSide(color: borderColor)),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.primary.withValues(
                  alpha: isDark ? 0.1 : 0.06,
                ),
                blurRadius: isSidebar ? 12 : 20,
                offset: isSidebar ? const Offset(0, 4) : const Offset(0, -8),
              ),
            ],
            borderRadius: isSidebar
                ? BorderRadius.circular(DesignTokens.radius16)
                : const BorderRadius.vertical(
                    top: Radius.circular(DesignTokens.radius24),
                  ),
          ),
          child: const Column(
            children: [
              CartTotalDisplay(),
              SizedBox(height: DesignTokens.spacing12),
              FreeShippingBar(),
              SizedBox(height: DesignTokens.spacing12),
              _CheckoutButton(),
            ],
          ),
        );
      },
    );
  }
}

/// Checkout button - static widget, reads cart data lazily on press
class _CheckoutButton extends ConsumerWidget {
  const _CheckoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ModernButton(
      key: CartScreen.checkoutButtonKey,
      label: 'cart.proceed_to_checkout'.tr(),
      onPressed: () {
        final cartDetails = ref.read(cartWithDetailsProvider);
        cartDetails.whenData((itemsWithDetails) {
          if (itemsWithDetails.isEmpty) return;
          final subtotalCents = itemsWithDetails.fold<int>(
            0,
            (total, item) => total + (item.priceCents * item.quantity),
          );
          Navigator.pushNamed(
            context,
            AppRoutes.checkout,
            arguments: CheckoutArgs(
              items: itemsWithDetails,
              totalCents: subtotalCents,
            ),
          );
        });
      },
      fullWidth: true,
      icon: Icons.payment,
    );
  }
}

/// Extension to add copyWith method to CartItemDetailModel
extension CartItemDetailModelExtension on CartItemDetailModel {
  CartItemDetailModel copyWith({
    String? productId,
    String? name,
    String? description,
    double? price,
    int? priceCents,
    List<String>? imageUrls,
    int? quantity,
    DateTime? createdAt,
    Address? sellerAddress,
    String? sellerId,
    String? sellerName,
    String? status,
    String? trackingNumber,
    bool? confirmedByBuyer,
    String? madeInCountry,
    double? weightKg,
    String? weightUnit,
    double? lengthCm,
    double? widthCm,
    double? heightCm,
    String? dimensionUnit,
    bool? isLocalDeliveryOnly,
    bool? isPerishable,
    int? estimatedShipDays,
    List<SellerDeliveryOption>? deliveryOptions,
    int? minimumOrderQuantity,
    bool? freeShipping,
    bool? isDigital,
    bool? isAgeRestricted,
    String? buyerNote,
    bool? isSmallSupplier,
    String? variantId,
    String? variantTitle,
    Map<String, String>? variantOptions,
  }) {
    return CartItemDetailModel(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      priceCents: priceCents ?? this.priceCents,
      imageUrls: imageUrls ?? this.imageUrls,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      sellerAddress: sellerAddress ?? this.sellerAddress,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      status: status ?? this.status,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      confirmedByBuyer: confirmedByBuyer ?? this.confirmedByBuyer,
      madeInCountry: madeInCountry ?? this.madeInCountry,
      weightKg: weightKg ?? this.weightKg,
      weightUnit: weightUnit ?? this.weightUnit,
      lengthCm: lengthCm ?? this.lengthCm,
      widthCm: widthCm ?? this.widthCm,
      heightCm: heightCm ?? this.heightCm,
      dimensionUnit: dimensionUnit ?? this.dimensionUnit,
      isLocalDeliveryOnly: isLocalDeliveryOnly ?? this.isLocalDeliveryOnly,
      isPerishable: isPerishable ?? this.isPerishable,
      estimatedShipDays: estimatedShipDays ?? this.estimatedShipDays,
      deliveryOptions: deliveryOptions ?? this.deliveryOptions,
      minimumOrderQuantity: minimumOrderQuantity ?? this.minimumOrderQuantity,
      freeShipping: freeShipping ?? this.freeShipping,
      isDigital: isDigital ?? this.isDigital,
      isAgeRestricted: isAgeRestricted ?? this.isAgeRestricted,
      buyerNote: buyerNote ?? this.buyerNote,
      isSmallSupplier: isSmallSupplier ?? this.isSmallSupplier,
      variantId: variantId ?? this.variantId,
      variantTitle: variantTitle ?? this.variantTitle,
      variantOptions: variantOptions ?? this.variantOptions,
    );
  }
}
