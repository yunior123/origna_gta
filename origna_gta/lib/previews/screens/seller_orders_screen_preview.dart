import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/screens/seller_orders_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Seller Orders Management', group: 'Screens — Seller Management')
Widget previewSellerOrdersScreen() => previewResponsiveBreakpoints(builder: (breakpoint) => const ProviderScope(child: SellerOrdersScreen()));
