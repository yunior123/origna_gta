import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/admin/admin_actions_viewmodel.dart';
import 'package:origna_gta/features/admin/admin_providers.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

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
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignTokens.radius16),
            boxShadow: DesignTokens.shadowSm,
          ),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: DesignTokens.primary),
                  filled: true,
                  fillColor: DesignTokens.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              ),
              const SizedBox(height: 10),
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
                loading: () => const ModernLoadingIndicator.fullScreen(),
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
      child: GestureDetector(
        onTap: () => setState(() => _stockFilter = value),
        child: AnimatedContainer(
          duration: DesignTokens.durationFast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? DesignTokens.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? DesignTokens.primary : Colors.grey.withValues(alpha: 0.2)),
            boxShadow: isSelected ? [BoxShadow(color: DesignTokens.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))] : [],
          ),
          child: Text(
            label,
            style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, fontSize: 12),
          ),
        ),
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
    IconData stockIcon;
    if (stock == 0) {
      stockColor = DesignTokens.error;
      stockText = 'Out of Stock';
      stockIcon = Icons.remove_circle_rounded;
    } else if (stock < 5) {
      stockColor = DesignTokens.warning;
      stockText = 'Low Stock ($stock)';
      stockIcon = Icons.warning_rounded;
    } else {
      stockColor = DesignTokens.success;
      stockText = 'In Stock ($stock)';
      stockIcon = Icons.check_circle_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radius16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              child: imageUrls.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrls.first,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(color: DesignTokens.surfaceVariant, borderRadius: BorderRadius.circular(DesignTokens.radius12)),
                        child: Icon(Icons.image_rounded, color: Colors.grey[400]),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(color: DesignTokens.surfaceVariant, borderRadius: BorderRadius.circular(DesignTokens.radius12)),
                        child: Icon(Icons.broken_image_rounded, color: Colors.grey[400]),
                      ),
                    )
                  : Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(color: DesignTokens.surfaceVariant, borderRadius: BorderRadius.circular(DesignTokens.radius12)),
                      child: Icon(Icons.image_rounded, color: Colors.grey[400]),
                    ),
            ),
            const SizedBox(width: 14),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(color: DesignTokens.primary, fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: stockColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(stockIcon, size: 13, color: stockColor),
                        const SizedBox(width: 4),
                        Text(stockText, style: TextStyle(color: stockColor, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            PopupMenuButton<String>(
              onSelected: (value) => _handleAction(context, ref, value),
              icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400]),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radius12)),
              itemBuilder: (context) => [
                _menuItem('set_stock', Icons.edit_rounded, 'Set Stock', DesignTokens.primary),
                _menuItem('mark_out_of_stock', Icons.remove_circle_outline_rounded, 'Mark Out of Stock', DesignTokens.warning),
                _menuItem('view_seller', Icons.person_rounded, 'View Seller', DesignTokens.info),
                _menuItem('delete', Icons.delete_rounded, 'Delete Product', DesignTokens.error),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radius16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: DesignTokens.error),
            const SizedBox(width: 10),
            const Text('Delete Product'),
          ],
        ),
        content: Text('Are you sure you want to delete "${product.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final success = await ref.read(adminActionsViewModelProvider.notifier).deleteProduct(product.id);
              if (!context.mounted) return;
              if (success) {
                messenger.showSnackBar(SnackBar(content: const Text('Product deleted'), backgroundColor: DesignTokens.error));
              } else {
                final error = ref.read(adminActionsViewModelProvider).errorMessage ?? 'Failed to delete product';
                messenger.showSnackBar(SnackBar(content: Text(error), backgroundColor: DesignTokens.error));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: DesignTokens.error),
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
      messenger.showSnackBar(SnackBar(content: const Text('Seller not found'), backgroundColor: DesignTokens.error));
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radius16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DesignTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.person_rounded, color: DesignTokens.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Seller Info'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Name', sellerData.name.isNotEmpty ? sellerData.name : 'Unknown'),
              const SizedBox(height: 8),
              _detailRow('Email', sellerData.email.isNotEmpty ? sellerData.email : 'Unknown'),
              const SizedBox(height: 8),
              _detailRow('Stripe', sellerData.onboardingCompleted ? 'Connected' : 'Pending'),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
        ),
      );
    }
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 60, child: Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 13, color: color)),
        ],
      ),
    );
  }
}
