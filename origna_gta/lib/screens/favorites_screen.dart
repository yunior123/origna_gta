import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/screens/product_card_screen.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritedProductsProvider);
    final userModel = ref.watch(userProfileProvider.select((value) => value.valueOrNull));

    return Scaffold(
      appBar: AppBarFactory.simple(title: 'Favorites'),
      body: favoritesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)))),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_outline, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No favorites yet', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Tap the heart icon on products to save them here', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: getCrossAxisCount(context),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: _getCardAspectRatio(context),
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(productId: product.productId, product: product, userModel: userModel);
            },
          );
        },
      ),
    );
  }

  double _getCardAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 0.6;
    if (width < 600) return 0.65;
    return 0.75;
  }
}
