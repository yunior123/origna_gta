import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/features/products/product_detail_viewmodel.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:shimmer/shimmer.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  final Map<String, dynamic>? product; // Optional initial data

  const ProductDetailScreen({super.key, required this.productId, this.product});

  void _showImageDialog(BuildContext context, List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              PageView.builder(
                itemCount: imageUrls.length,
                controller: PageController(initialPage: initialIndex),
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: imageUrls[index],
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, size: 100, color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productByIdProvider(productId));
    final viewModel = ref.read(productDetailViewModelProvider.notifier);

    return Scaffold(
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return const Center(child: Text('Product not found'));
          }
          final imageUrls = product.imageUrls;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                automaticallyImplyLeading: false,
                pinned: true,
                floating: true,
                expandedHeight: 300,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      imageUrls.isNotEmpty
                          ? PageView.builder(
                              itemCount: imageUrls.length,
                              onPageChanged: viewModel.setImageIndex,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () => _showImageDialog(context, imageUrls, index),
                                  child: SizedBox.expand(
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrls[index],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Container(color: Colors.white),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported, size: 100)),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported, size: 100)),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 5,
                        left: 16,
                        child: Container(
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      Positioned(bottom: 16, left: 0, right: 0, child: _ImageDots(imageCount: imageUrls.length)),
                    ],
                  ),
                ),
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(20),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.star, size: 20, color: Colors.amber[700]),
                              const SizedBox(width: 4),
                              Text(product.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFFF6B35)),
                          ),
                          const SizedBox(height: 24),
                          const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(product.description, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5)),
                          const SizedBox(height: 24),
                          _QuantitySelector(viewModel: viewModel),
                          const SizedBox(height: 24),
                          _AddToCartButton(productId: productId),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ImageDots extends ConsumerWidget {
  final int imageCount;

  const _ImageDots({required this.imageCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (imageCount <= 1) return const SizedBox.shrink();

    final currentIndex = ref.watch(productDetailViewModelProvider.select((state) => state.currentImageIndex));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        imageCount,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: currentIndex == index ? Colors.white : Colors.white.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

class _QuantitySelector extends ConsumerWidget {
  final ProductDetailViewModel viewModel;

  const _QuantitySelector({required this.viewModel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantity = ref.watch(productDetailViewModelProvider.select((state) => state.quantity));

    return Row(
      children: [
        const Text('Quantity:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(width: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.remove), onPressed: quantity > 1 ? viewModel.decrementQuantity : null),
              Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add), onPressed: viewModel.incrementQuantity),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddToCartButton extends ConsumerWidget {
  final String productId;

  const _AddToCartButton({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantity = ref.watch(productDetailViewModelProvider.select((state) => state.quantity));

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () async {
          final user = ref.read(currentUserProvider);
          if (user == null) {
            showLoginPrompt(context);
            return;
          }
          final messenger = ScaffoldMessenger.of(context);
          final success = await ref.read(cartControllerProvider).addToCart(productId, quantity);
          if (success) {
            messenger.showSnackBar(const SnackBar(content: Text('Added to cart'), backgroundColor: Colors.green));
          } else {
            messenger.showSnackBar(const SnackBar(content: Text('Failed to add to cart'), backgroundColor: Colors.red));
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B35),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Add to Cart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
