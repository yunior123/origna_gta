import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/screens/editproduct_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Edit Product Details', group: 'Screens')
Widget previewEditProductScreen() => previewResponsiveBreakpoints(
  builder: (breakpoint) => previewScope(
    child: EditProductScreen(
      product: Product(
        productId: 'mock-id',
        name: 'Mock Product',
        price: 100.0,
        description: 'Mock Description',
        imageUrls: ['https://via.placeholder.com/150'],
        sellerId: 'mock-seller',
        categoryId: 1,
        stockQuantity: 10,
        createdAt: DateTime.now(),
      ),
    ),
  ),
);
