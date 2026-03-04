import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/screens/productdetails_screen.dart';

import '../_preview_theme.dart';

Widget _productDetailsContent() => previewScope(
  extraOverrides: [
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
);

@Preview(name: 'Product Details — Mobile', group: 'Screens', size: Size(390, 844))
Widget previewProductDetailScreenMobile() => previewMobile(child: _productDetailsContent());

@Preview(name: 'Product Details — Tablet', group: 'Screens', size: Size(768, 1024))
Widget previewProductDetailScreenTablet() => previewTablet(child: _productDetailsContent());

@Preview(name: 'Product Details — Desktop', group: 'Screens', size: Size(1280, 800))
Widget previewProductDetailScreenDesktop() => previewDesktop(child: _productDetailsContent());

@Preview(name: 'Product Details — Web', group: 'Screens', size: Size(1440, 900))
Widget previewProductDetailScreenWeb() => previewWeb(child: _productDetailsContent());
