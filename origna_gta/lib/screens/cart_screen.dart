import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/screens/cartitem_screen.dart';
import 'package:origna_gta/screens/checkout_screen.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';

/// Cart screen using optimized Riverpod patterns
/// - Main screen only watches cart item IDs (lightweight)
/// - Each cart item widget watches its own data via family provider
/// - Summary widget only watches what it needs
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Sign in to view cart',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      );
    }

    // Use select to only rebuild when product IDs change (not quantities)
    final productIdsAsync = ref.watch(cartItemsProvider.select((async) => async.whenData((items) => items.map((i) => i.productId).toList())));

    return Scaffold(
      appBar: AppBarFactory.simple(title: 'Shopping Cart'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [isDark ? Colors.grey[900]! : Colors.grey[50]!, isDark ? Colors.grey[800]! : Colors.white],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: productIdsAsync.when(
              loading: () => Center(
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [DesignTokens.primary, DesignTokens.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text('Error: $error', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  ],
                ),
              ),
              data: (productIds) {
                if (productIds.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [DesignTokens.primary.withValues(alpha: 0.1), DesignTokens.secondary.withValues(alpha: 0.1)],
                            ),
                          ),
                          child: Icon(Icons.shopping_cart_outlined, size: 100, color: DesignTokens.primary.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Your cart is empty',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey[900]),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Looks like you haven\'t added any items yet.',
                          style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: 200,
                          child: ModernButton(
                            label: 'Start Shopping',
                            icon: Icons.arrow_back,
                            onPressed: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: productIds.length,
                        itemBuilder: (context, index) {
                          final productId = productIds[index];
                          return FadeSlideIn(
                            delay: Duration(milliseconds: 50 * index),
                            child: _CartItemWidget(key: ValueKey(productId), productId: productId),
                          );
                        },
                      ),
                    ),
                    FadeSlideIn(
                      delay: Duration(milliseconds: 50 * productIds.length),
                      beginOffset: const Offset(0, 0.2),
                      child: const _CartSummary(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual cart item widget - only rebuilds when THIS item's data changes
class _CartItemWidget extends ConsumerWidget {
  final String productId;

  const _CartItemWidget({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch only this specific item's details via family provider
    final itemAsync = ref.watch(cartItemDetailProvider(productId));

    return itemAsync.when(
      loading: () => const ListTile(
        leading: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
        title: Text('Loading...'),
      ),
      error: (error, stack) => const SizedBox.shrink(),
      data: (item) {
        if (item == null) return const SizedBox.shrink();
        return CartItemScreen(productId: productId, item: item.toMap(), onRemove: () => ref.read(cartControllerProvider).removeFromCart(productId));
      },
    );
  }
}

/// Cart summary - only watches what it needs for display
class _CartSummary extends ConsumerWidget {
  const _CartSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch only if cart is empty (for visibility logic)
    final isEmpty = ref.watch(cartWithDetailsProvider.select((async) => async.whenData((items) => items.isEmpty)));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isEmpty.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (isEmpty) {
        if (isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -8))],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [const _CartTotalDisplay(), const SizedBox(height: 20), const _CheckoutButton()]),
        );
      },
    );
  }
}

/// Cart total display - only rebuilds when subtotal changes
class _CartTotalDisplay extends ConsumerWidget {
  const _CartTotalDisplay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only watch the subtotal calculation
    final subtotalAsync = ref.watch(
      cartWithDetailsProvider.select((async) => async.whenData((items) => items.fold(0.0, (total, item) => total + (item.price * item.quantity)))),
    );

    return subtotalAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (subtotal) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [DesignTokens.primary.withValues(alpha: 0.08), DesignTokens.secondary.withValues(alpha: 0.08)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radius16),
            border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.2), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[900],
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [DesignTokens.primary, DesignTokens.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  NumberFormat.currency(locale: "en_CA", symbol: "CAD \$").format(subtotal),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Checkout button - only rebuilds when cart items change
class _CheckoutButton extends ConsumerWidget {
  const _CheckoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch cart details for checkout navigation
    final cartDetailsAsync = ref.watch(cartWithDetailsProvider);

    return cartDetailsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (itemsWithDetails) {
        return ModernButton(
          label: 'Proceed to Checkout',
          onPressed: itemsWithDetails.isEmpty
              ? null
              : () {
                  final subtotal = itemsWithDetails.fold(0.0, (total, item) => total + (item.price * item.quantity));
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckoutScreen(items: itemsWithDetails, total: subtotal),
                    ),
                  );
                },
          fullWidth: true,
          icon: Icons.payment,
        );
      },
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
    List<String>? imageUrls,
    int? quantity,
    dynamic dateCreated,
    Address? sellerAddress,
    String? sellerId,
    String? deliveryStatus,
    bool? isDigital,
  }) {
    return CartItemDetailModel(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrls: imageUrls ?? this.imageUrls,
      quantity: quantity ?? this.quantity,
      dateCreated: dateCreated ?? this.dateCreated,
      sellerAddress: sellerAddress ?? this.sellerAddress,
      sellerId: sellerId ?? this.sellerId,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      isDigital: isDigital ?? this.isDigital,
    );
  }
}
