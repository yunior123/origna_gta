import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:origna_gta/screens/cartitem_screen.dart';
import 'package:origna_gta/screens/checkout_screen.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';

/// Cart screen using optimized Riverpod patterns
/// - Main screen only watches cart item IDs (lightweight)
/// - Each cart item widget watches its own data via family provider
/// - Summary widget only watches what it needs
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in to view cart')));
    }

    // Use select to only rebuild when product IDs change (not quantities)
    final productIdsAsync = ref.watch(cartItemsProvider.select((async) => async.whenData((items) => items.map((i) => i.productId).toList())));

    return Scaffold(
      appBar: AppBarFactory.simple(title: 'Shopping Cart'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: productIdsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
            data: (productIds) {
              if (productIds.isEmpty) {
                return const AnimatedEmptyState(icon: Icons.shopping_cart_outlined, title: 'Your cart is empty', subtitle: 'Add items to get started');
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: productIds.length,
                      itemBuilder: (context, index) {
                        final productId = productIds[index];
                        return FadeSlideIn(
                          delay: Duration(milliseconds: 50 * index),
                          // Each cart item is isolated - only rebuilds when its own data changes
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
    // Watch cart details for checkout navigation
    final cartDetailsAsync = ref.watch(cartWithDetailsProvider);

    return cartDetailsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (itemsWithDetails) {
        if (itemsWithDetails.isEmpty) return const SizedBox.shrink();

        // Calculate subtotal inline - no need for separate provider watch
        final subtotal = itemsWithDetails.fold(0.0, (total, item) => total + (item.price * item.quantity));

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(
                    NumberFormat.currency(locale: "en_CA", symbol: "CAD \$").format(subtotal),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFF6B35)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: itemsWithDetails.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutScreen(items: itemsWithDetails, total: subtotal),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
                  child: const Text('Proceed to Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
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
    );
  }
}
