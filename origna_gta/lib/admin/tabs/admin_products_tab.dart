import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/widgets/animations.dart';

class AdminProductsTab extends StatefulWidget {
  const AdminProductsTab({super.key});

  @override
  State<AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends State<AdminProductsTab> {
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
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .orderBy('dateCreated', descending: true)
                .limit(100)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const AnimatedEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No products found',
                );
              }

              var products = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final stock = data['stockQuantity'] ?? 0;

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
                  final doc = products[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return FadeSlideIn(
                    delay: Duration(milliseconds: 30 * index),
                    child: _ProductCard(productId: doc.id, data: data),
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
        selectedColor: const Color(0xFFFF6B35),
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> data;

  const _ProductCard({required this.productId, required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Unknown';
    final price = (data['price'] ?? 0.0).toDouble();
    final stock = data['stockQuantity'] ?? 0;
    final imageUrls = List<String>.from(data['imageUrls'] ?? []);

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
                      placeholder: (context, url) => Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image),
                      ),
                    )
                  : Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image),
                    ),
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
                    style: const TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: stockColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
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
              onSelected: (value) => _handleAction(context, value),
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

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'set_stock':
        _showSetStockDialog(context);
        break;
      case 'mark_out_of_stock':
        _setStock(context, 0);
        break;
      case 'view_seller':
        _viewSeller(context);
        break;
      case 'delete':
        _showDeleteDialog(context);
        break;
    }
  }

  void _showSetStockDialog(BuildContext context) {
    final controller = TextEditingController(text: (data['stockQuantity'] ?? 0).toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Stock Quantity'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Stock Quantity',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newStock = int.tryParse(controller.text) ?? 0;
              Navigator.pop(ctx);
              _setStock(context, newStock);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _setStock(BuildContext context, int quantity) async {
    await FirebaseFirestore.instance.collection('products').doc(productId).update({
      'stockQuantity': quantity,
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(quantity == 0 ? 'Product marked as out of stock' : 'Stock updated to $quantity'),
          backgroundColor: quantity == 0 ? Colors.orange : Colors.green,
        ),
      );
    }
  }

  void _viewSeller(BuildContext context) async {
    final sellerId = data['sellerId'];
    if (sellerId == null) return;

    final sellerDoc = await FirebaseFirestore.instance.collection('users').doc(sellerId).get();
    if (!sellerDoc.exists) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seller not found'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final sellerData = sellerDoc.data()!;
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Seller Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${sellerData['name'] ?? 'Unknown'}'),
              Text('Email: ${sellerData['email'] ?? 'Unknown'}'),
              Text('Stripe: ${sellerData['stripeOnboardingComplete'] == true ? 'Connected' : 'Pending'}'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${data['name']}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('products').doc(productId).delete();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product deleted'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
