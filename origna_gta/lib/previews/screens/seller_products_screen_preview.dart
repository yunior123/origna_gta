import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/screens/seller_products_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Seller Inventory List', group: 'Screens — Seller Management')
Widget previewSellerProductsScreen() => previewResponsiveBreakpoints(builder: (breakpoint) => const ProviderScope(child: SellerProductsScreen()));
