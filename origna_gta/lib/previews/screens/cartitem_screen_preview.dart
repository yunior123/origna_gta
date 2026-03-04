import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/cartitem_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Cart Item Screen', group: 'Cart Screens')
Widget previewCartItemScreen() {
  return previewResponsiveBreakpoints(
    builder: (breakpoint) => previewScope(
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: CartItemScreen(
              productId: 'preview-id',
              cartItemId: 'preview-cart-item-id',
              item: const {'name': 'Preview Product', 'price': 9.99, 'quantity': 1},
              onRemove: () {},
            ),
          ),
        ),
      ),
    ),
  );
}
