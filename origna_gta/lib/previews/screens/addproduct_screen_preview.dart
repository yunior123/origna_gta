import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/screens/addproduct_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Add Product Screen', group: 'Product Screens')
Widget previewAddProductScreen() {
  return previewResponsiveBreakpoints(builder: (breakpoint) => const ProviderScope(child: AddProductScreen()));
}
