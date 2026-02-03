import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/admin/admin_actions_viewmodel.dart';
import 'package:origna_gta/admin/admin_providers.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/animations.dart';

class AdminProductsTab extends ConsumerStatefulWidget {
  const AdminProductsTab({super.key});

  @override
  ConsumerState<AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends ConsumerState<AdminProductsTab> {
  String _searchQuery = '';
  String _stockFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All Products', 'all'),
                    _buildFilterChip('In Stock', 'in_stock'),
                    _buildFilterChip('Out of Stock', 'out_of_stock'),
                    _buildFilterChip('Low Stock (<5)', 'low_stock'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Products List
        Expanded(
          child: ref
              .watch(adminProductsProvider(null))
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => const Center(child: Text('Error Fetching from Database')),
                data: (productsRaw) {
                  if (productsRaw.isEmpty) {
                    return const AnimatedEmptyState(icon: Icons.inventory_2_outlined, title: 'No products found');
                  }

                  final products = productsRaw.where((data) {
                    final name = data.name.toLowerCase();
                    final stock = data.stockQuantity;

                    final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery);

                    bool matchesStock = true;
                    switch (_stockFilter) {
                      case 'in_stock':
                        matchesStock = stock > 0;
                        break;
                      case 'out_of_stock':
                        matchesStock = stock == 0;
                        break;
                      case 'low_stock':
                        matchesStock = stock > 0 && stock < 5;
                        break;
                    }

                    return matchesSearch && matchesStock;
                  }).toList();

                  if (products.isEmpty) {
                    return const Center(child: Text('No products match your filters'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final data = products[index];
                      return FadeSlideIn(
                        delay: Duration(milliseconds: 30 * index),
                        child: _ProductCard(product: data),
                      );
                    },
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _stockFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _stockFilter = value),
        selectedColor: const Color(0xFF667EEA),
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final ProductModel product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = product.name;
    final price = product.price;
    final stock = product.stockQuantity;
    final imageUrls = product.imageUrls;

    Color stockColor;
    String stockText;
    if (stock == 0) {
      stockColor = Colors.red;
      stockText = 'Out of Stock';
    } else if (stock < 5) {
      stockColor = Colors.orange;
      stockText = 'Low Stock ($stock)';
    } else {
      stockColor = Colors.green;
      stockText = 'In Stock ($stock)';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrls.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrls.first,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(width: 70, height: 70, color: Colors.grey[200], child: const Icon(Icons.image)),
                      errorWidget: (context, url, error) => Container(width: 70, height: 70, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                    )
                  : Container(width: 70, height: 70, color: Colors.grey[200], child: const Icon(Icons.image)),
            ),
            const SizedBox(width: 12),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: const TextStyle(color: Color(0xFF667EEA), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: stockColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      stockText,
                      style: TextStyle(color: stockColor, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            PopupMenuButton<String>(
              onSelected: (value) => _handleAction(context, ref, value),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'set_stock', child: Text('Set Stock')),
                const PopupMenuItem(value: 'mark_out_of_stock', child: Text('Mark Out of Stock')),
                const PopupMenuItem(value: 'view_seller', child: Text('View Seller')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Product', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'set_stock':
        _showSetStockDialog(context, ref);
        break;
      case 'mark_out_of_stock':
        _setStock(context, ref, 0);
        break;
      case 'view_seller':
        _viewSeller(context, ref);
        break;
      case 'delete':
        _showDeleteDialog(context, ref);
        break;
    }
  }

  void _setStock(BuildContext context, WidgetRef ref, int quantity) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await ref.read(adminActionsViewModelProvider.notifier).updateProductStock(product.id, quantity);
    if (!context.mounted) return;
    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(quantity == 0 ? 'Product marked as out of stock' : 'Stock updated to $quantity'),
          backgroundColor: quantity == 0 ? Colors.orange : Colors.green,
        ),
      );
    } else {
      final error = ref.read(adminActionsViewModelProvider).errorMessage ?? 'Failed to update stock';
      messenger.showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final success = await ref.read(adminActionsViewModelProvider.notifier).deleteProduct(product.id);
              if (!context.mounted) return;
              if (success) {
                messenger.showSnackBar(const SnackBar(content: Text('Product deleted'), backgroundColor: Colors.red));
              } else {
                final error = ref.read(adminActionsViewModelProvider).errorMessage ?? 'Failed to delete product';
                messenger.showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSetStockDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: product.stockQuantity.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Stock Quantity'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Stock Quantity', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newStock = int.tryParse(controller.text) ?? 0;
              Navigator.pop(ctx);
              _setStock(context, ref, newStock);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _viewSeller(BuildContext context, WidgetRef ref) async {
    final sellerId = product.sellerId;

    final messenger = ScaffoldMessenger.of(context);
    final sellerData = await ref.read(adminActionsViewModelProvider.notifier).fetchUserById(sellerId);
    if (!context.mounted) return;
    if (sellerData == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Seller not found'), backgroundColor: Colors.red));
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Seller Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${sellerData.name.isNotEmpty ? sellerData.name : 'Unknown'}'),
              Text('Email: ${sellerData.email.isNotEmpty ? sellerData.email : 'Unknown'}'),
              Text('Stripe: ${sellerData.onboardingCompleted ? 'Connected' : 'Pending'}'),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
        ),
      );
    }
  }
}
