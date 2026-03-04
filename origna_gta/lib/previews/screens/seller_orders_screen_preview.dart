import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/seller_orders_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Seller Orders — Mobile', group: 'Screens — Seller Management', size: Size(390, 844))
Widget previewSellerOrdersScreenMobile() => previewMobile(child: previewScope(child: SellerOrdersScreen()));

@Preview(name: 'Seller Orders — Tablet', group: 'Screens — Seller Management', size: Size(768, 1024))
Widget previewSellerOrdersScreenTablet() => previewTablet(child: previewScope(child: SellerOrdersScreen()));

@Preview(name: 'Seller Orders — Desktop', group: 'Screens — Seller Management', size: Size(1280, 800))
Widget previewSellerOrdersScreenDesktop() => previewDesktop(child: previewScope(child: SellerOrdersScreen()));

@Preview(name: 'Seller Orders — Web', group: 'Screens — Seller Management', size: Size(1440, 900))
Widget previewSellerOrdersScreenWeb() => previewWeb(child: previewScope(child: SellerOrdersScreen()));
