
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/productdetails_screen.dart';
import 'package:origna_gta/utils.dart';
import 'package:shimmer/shimmer.dart';

class _ProductCardState extends State<ProductCard> with SingleTickerProviderStateMixin {
  bool _isFavorite = false;
  late AnimationController _controller;
  int _currentImageIndex = 0;
  final int _quantity = 1;
  @override
  Widget build(BuildContext context) {
    final List<String> imageUrls = (widget.product.imageUrls as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final name = widget.product.name ;
    final price = widget.product.price ;
    final rating = (widget.product.rating ).toDouble();
    //final user = FirebaseAuth.instance.currentUser;
    final isAdmin = widget.userModel?.roles.contains('admin') ?? false;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: widget.productId, product: widget.product.toMap()),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image section with favorite button
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: SizedBox.expand(
                      child: imageUrls.isNotEmpty
                          ? Stack(
                              children: [
                                // Image PageView
                                PageView.builder(
                                  itemCount: imageUrls.length,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentImageIndex = index;
                                    });
                                  },
                                  itemBuilder: (context, index) {
                                    return CachedNetworkImage(
                                      imageUrl: imageUrls[index],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Container(color: Colors.white),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported, size: 50)),
                                    );
                                  },
                                ),

                                // Page indicator (bottom right)
                                if (imageUrls.length > 1)
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
                                      child: Text(
                                        '${_currentImageIndex + 1}/${imageUrls.length}',
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ),

                        
                              ],
                            )
                          : Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported, size: 50)),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 1.3).animate(_controller),
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 4,
                        child: InkWell(
                          onTap: _toggleFavorite,
                          customBorder: const CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.red : Colors.grey[600], size: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product info section
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product name
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Rating
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),

                    // Price and Add to Cart
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${price.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFFF6B35)),
                        ),
                        Material(
                          color: const Color(0xFFFF6B35),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () => addToCart(productId: widget.productId, quantity: _quantity, context: context),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Icon(Icons.add_shopping_cart, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Builder(
              builder: (context) {
                if (!isAdmin) return const SizedBox.shrink();
                return Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteProduct(context),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final favorites = List<String>.from(userDoc.data()?['favorites'] ?? []);
      if (mounted) {
        setState(() => _isFavorite = favorites.contains(widget.productId));
      }
    }
  }

  // inside _ProductCardState

  Future<void> _deleteProduct(BuildContext context) async {
    try {
      final productId = widget.productId;
      final firestore = FirebaseFirestore.instance;

      // 1. Delete the actual product document
      await firestore.collection('products').doc(productId).delete();

      // 2. Find all users who have this product in their cart OR favorites
      // We fetch users who have a non-empty cart or favorites to minimize the search
      final usersSnapshot = await firestore.collection('users').get(); //TODO: In production, use Cloud Functions for scalability

      final WriteBatch batch = firestore.batch();
      bool adjustmentsMade = false;

      for (var userDoc in usersSnapshot.docs) {
        final data = userDoc.data();
        bool userNeedsUpdate = false;
        Map<String, dynamic> updates = {};

        // --- Handle Cart (Array of Objects) ---
        final List<dynamic> cart = data['cart'] ?? [];
        final bool hasInCart = cart.any((item) => item['productId'] == productId);
        if (hasInCart) {
          updates['cart'] = cart.where((item) => item['productId'] != productId).toList();
          userNeedsUpdate = true;
        }

        // --- Handle Favorites (Array of Strings/IDs) ---
        final List<dynamic> favorites = data['favorites'] ?? [];
        if (favorites.contains(productId)) {
          updates['favorites'] = FieldValue.arrayRemove([productId]);
          userNeedsUpdate = true;
        }

        if (userNeedsUpdate) {
          batch.update(userDoc.reference, updates);
          adjustmentsMade = true;
        }
      }

      // 3. Commit all changes across all affected user documents
      if (adjustmentsMade) {
        await batch.commit();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted and removed from all carts & favorites')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting product: $e')));
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (!mounted) return;
    setState(() => _isFavorite = !_isFavorite);
    if (!mounted) return;
    await _controller.forward();
    if (mounted) await _controller.reverse();

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    if (_isFavorite) {
      await userRef.update({
        'favorites': FieldValue.arrayUnion([widget.productId]),
      });
    } else {
      await userRef.update({
        'favorites': FieldValue.arrayRemove([widget.productId]),
      });
    }
  }
}

class ProductCard extends StatefulWidget {
  final String productId;
  final ProductModel product;
  final UserModel? userModel;

  const ProductCard({super.key, required this.productId, required this.product, required this.userModel});

  @override
  State<ProductCard> createState() => _ProductCardState();
}
