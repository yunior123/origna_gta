import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:shimmer/shimmer.dart';

class CartItemScreen extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> item;
  final VoidCallback onRemove;

  const CartItemScreen({super.key, required this.productId, required this.item, required this.onRemove});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 80,
              height: 80,
              child: Builder(
                builder: (context) {
                  final List<String> imageUrlsList = (item['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [];

                  if (imageUrlsList.isEmpty) {
                    return Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported));
                  }

                  if (imageUrlsList.length == 1) {
                    // Single image - no need for PageView
                    return CachedNetworkImage(
                      imageUrl: imageUrlsList[0],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
                    );
                  }

                  // Multiple images - swipeable PageView
                  return Stack(
                    children: [
                      PageView.builder(
                        itemCount: imageUrlsList.length,
                        itemBuilder: (context, index) {
                          return CachedNetworkImage(
                            imageUrl: imageUrlsList[index],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(color: Colors.white),
                            ),
                            errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported, size: 24)),
                          );
                        },
                      ),
                      // Image counter indicator
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.collections, color: Colors.white, size: 10),
                              const SizedBox(width: 2),
                              Text(
                                '${imageUrlsList.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Product',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${(item['price'] ?? 0.0).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF6B35)),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final quantityAsync = ref.watch(cartItemQuantityProvider(productId));
                  final quantity = quantityAsync.valueOrNull ?? 0;
                  final cartController = ref.read(cartControllerProvider);

                  if (quantity <= 0) return const SizedBox.shrink();

                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          onPressed: quantity > 1 ? () => cartController.updateQuantity(productId, quantity - 1) : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          onPressed: () => cartController.updateQuantity(productId, quantity + 1),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
