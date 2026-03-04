import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/screens/productdetails_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Product Details', group: 'Screens')
Widget previewProductDetailScreen() => previewResponsiveBreakpoints(
  builder: (breakpoint) => ProviderScope(
    overrides: [
      productByIdProvider('preview-id').overrideWith(
        (ref) => Future.value(
          Product(
            productId: 'preview-id',
            sellerId: 'test-seller',
            name: 'Premium Headphones',
            description: 'Experience high-quality sound with these noise-canceling headphones.',
            price: 299.99,
            stockQuantity: 5,
            imageUrls: ['https://picsum.photos/800'],
            categoryId: 1,
            createdAt: DateTime.now(),
          ),
        ),
      ),
      userProfileProvider.overrideWith((ref) => Stream.value(null)),
    ],
    child: const ProductDetailScreen(productId: 'preview-id'),
  ),
);
