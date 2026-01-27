import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/login_screen.dart';
import 'package:origna_gta/productdetails_screen.dart';
import 'package:origna_gta/utils.dart';
import 'package:shimmer/shimmer.dart';

class ProductCard extends StatefulWidget {
  final String productId;
  final ProductModel product;
  final UserModel? userModel;

  const ProductCard({super.key, required this.productId, required this.product, required this.userModel});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> with SingleTickerProviderStateMixin {
  bool _isFavorite = false;
  late AnimationController _controller;
  int _currentImageIndex = 0;
  final int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _checkFavorite();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> imageUrls = (widget.product.imageUrls as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final name = widget.product.name;
    final price = widget.product.price;
    final rating = (widget.product.rating).toDouble();
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
                          onTap: () {
                            _toggleFavorite(context);
                          },
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
                            onTap: () async {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) {
                                showLoginPrompt(context);
                                return;
                              }
                              await addToCart(productId: widget.productId, quantity: _quantity, context: context);
                            },
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

  // Check if product is favorited using subcollection
  Future<void> _checkFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Check if document exists in favorites subcollection
        final favoriteDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .doc(widget.productId)
            .get();

        if (mounted) {
          setState(() => _isFavorite = favoriteDoc.exists);
        }
      } catch (e) {
        debugPrint('Error checking favorite: $e');
      }
    }
  }

  Future<void> _deleteProduct(BuildContext context) async {
    try {
      final productId = widget.productId;
      //TODO: delete in backend, call cloud fn
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted and removed from all carts & favorites')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting product: $e')));
      }
    }
  }

  // Toggle favorite using subcollection
  Future<void> _toggleFavorite(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showLoginPrompt(context, text: "You need to sign in to add favorites");
      return;
    }

    // Optimistic UI update
    if (!mounted) return;
    setState(() => _isFavorite = !_isFavorite);

    // Animate the heart
    if (!mounted) return;
    await _controller.forward();
    if (mounted) await _controller.reverse();

    // Reference to the favorite document
    final favoriteRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.productId);

    try {
      if (_isFavorite) {
        // Add to favorites subcollection
        await favoriteRef.set({
          'productId': widget.productId,
          'dateFavorited': FieldValue.serverTimestamp(),
        });
      } else {
        // Remove from favorites subcollection
        await favoriteRef.delete();
      }
    } catch (e) {
      // Revert optimistic update on error
      if (mounted) {
        setState(() => _isFavorite = !_isFavorite);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating favorites: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
      debugPrint('Error toggling favorite: $e');
    }
  }
}