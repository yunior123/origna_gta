import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/productcard_screen.dart';
import 'package:origna_gta/utils.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view favorites')),
      );
    }

    return Scaffold(
      appBar: AppBarFactory.simple(title: 'Favorites'),
      body: StreamBuilder<DocumentSnapshot>(
        // Still need user data for UserModel
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
              ),
            );
          }

          if (!userSnapshot.hasData) {
            return const Center(child: Text('Error loading user data'));
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          final userModel = UserModel.fromMap(userData ?? {});

          // Stream favorites from subcollection instead of array
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('favorites')
                .orderBy('dateFavorited', descending: true)
                .snapshots(),
            builder: (context, favoritesSnapshot) {
              if (favoritesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                  ),
                );
              }

              if (!favoritesSnapshot.hasData || favoritesSnapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_outline, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No favorites yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the heart icon on products to save them here',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              // Extract product IDs from favorites subcollection
              final favoriteProductIds = favoritesSnapshot.data!.docs
                  .map((doc) => doc.id)
                  .toList();

              // Firestore 'whereIn' has a limit of 10 items
              // If more than 10 favorites, we need to handle it differently
              if (favoriteProductIds.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_outline, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No favorites yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              // Handle the whereIn limit (max 10 items)
              if (favoriteProductIds.length > 10) {
                return _buildFavoritesWithPagination(favoriteProductIds, userModel);
              }

              // For 10 or fewer favorites, use the simple whereIn query
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .where(FieldPath.documentId, whereIn: favoriteProductIds)
                    .snapshots(),
                builder: (context, productsSnapshot) {
                  if (!productsSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final products = productsSnapshot.data!.docs;

                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Some favorited products are no longer available',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: kIsWeb ? 4 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final productDoc = products[index];
                      final product = ProductModel.fromDocument(productDoc);
                      return ProductCard(
                        productId: product.id,
                        product: product,
                        userModel: userModel,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Handle more than 10 favorites by fetching products individually
  Widget _buildFavoritesWithPagination(List<String> productIds, UserModel userModel) {
    return FutureBuilder<List<ProductModel>>(
      future: _fetchProductsInBatches(productIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading favorite products',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final products = snapshot.data!;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: getCrossAxisCount(context),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
           // childAspectRatio: 0.75,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCard(
              productId: product.id,
              product: product,
              userModel: userModel,
            );
          },
        );
      },
    );
  }

  // Fetch products in batches of 10 to work around Firestore's whereIn limitation
  Future<List<ProductModel>> _fetchProductsInBatches(List<String> productIds) async {
    final List<ProductModel> allProducts = [];
    
    // Split into chunks of 10
    for (int i = 0; i < productIds.length; i += 10) {
      final chunk = productIds.skip(i).take(10).toList();
      
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      
      final products = snapshot.docs
          .map((doc) => ProductModel.fromDocument(doc))
          .toList();
      
      allProducts.addAll(products);
    }
    
    return allProducts;
  }
}