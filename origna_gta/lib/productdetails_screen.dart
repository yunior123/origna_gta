


import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/cart_screen.dart';
import 'package:origna_gta/utils.dart';
import 'package:shimmer/shimmer.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.productId, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}


class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final imageUrls = widget.product['imageUrls'] ?? '';
    final name = widget.product['name'] ?? 'Product';
    final price = widget.product['price'] ?? 0.0;
    final description = widget.product['description'] ?? 'No description available';
    final rating = (widget.product['rating'] ?? 0.0).toDouble();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
       StreamBuilder<QuerySnapshot>(
            stream: user != null 
                ? FirebaseFirestore.instance.collection('users').doc(user.uid).collection('cart').snapshots() 
                : null,
            builder: (context, snapshot) {
              int itemCount = 0;
              if (snapshot.hasData) {
                // Sum quantities across all documents in the sub-collection
                itemCount = snapshot.data!.docs.fold(0, (sum, doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return sum + (data['quantity'] as int? ?? 0);
                });
              }
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                    },
                  ),
                  if (itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Color(0xFFFF6B35), shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          itemCount > 99 ? '99+' : '$itemCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'product_${widget.productId}',
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: imageUrls.isNotEmpty
                        ? StatefulBuilder(
                            builder: (context, setState) {
                              int currentPage = 0;

                              return Stack(
                                children: [
                                  // Swipeable images
                                  PageView.builder(
                                    itemCount: imageUrls.length,
                                    onPageChanged: (index) {
                                      setState(() => currentPage = index);
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
                                            Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported, size: 100)),
                                      );
                                    },
                                  ),

                                  // Dot indicators (top center - AliExpress style)
                                  if (imageUrls.length > 1)
                                    Positioned(
                                      top: 16,
                                      left: 0,
                                      right: 0,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: List.generate(
                                          imageUrls.length,
                                          (index) => AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            margin: const EdgeInsets.symmetric(horizontal: 3),
                                            width: currentPage == index ? 8 : 6,
                                            height: currentPage == index ? 8 : 6,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: currentPage == index ? Colors.white : Colors.white.withOpacity(0.5),
                                              boxShadow: currentPage == index ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)] : null,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          )
                        : Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported, size: 100)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star, size: 20, color: Colors.amber[700]),
                          const SizedBox(width: 4),
                          Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFFF6B35)),
                      ),
                      const SizedBox(height: 24),
                      const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(description, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5)),
                      const SizedBox(height: 24),
                      Row(
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
                                IconButton(icon: const Icon(Icons.remove), onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null),
                                Text('$_quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _quantity++)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () async {
                            await addToCart(productId: widget.productId, quantity: _quantity, context: context);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
                          child: const Text('Add to Cart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


