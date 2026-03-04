import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/screens/product_card_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Product Card Component', group: 'Components')
Widget previewProductCardScreen() {
  final product = Product(
    productId: 'preview-id',
    sellerId: 'test-seller',
    name: 'Standard Product Instance',
    description: 'A fantastic product for preview purposes with some descriptive text here.',
    price: 19.99,
    stockQuantity: 10,
    imageUrls: ['https://picsum.photos/400'],
    categoryId: 1,
    createdAt: DateTime.now(),
  );
  return previewResponsiveBreakpoints(
    builder: (breakpoint) => ProviderScope(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: 200,
            height: 300,
            child: ProductCard(productId: 'preview-id', product: product, userModel: null),
          ),
        ),
      ),
    ),
  );
}
