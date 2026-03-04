import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/addproduct_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Add Product — Mobile', group: 'Product Screens', size: Size(390, 844))
Widget previewAddProductScreenMobile() => previewMobile(child: previewScope(child: AddProductScreen()));

@Preview(name: 'Add Product — Tablet', group: 'Product Screens', size: Size(768, 1024))
Widget previewAddProductScreenTablet() => previewTablet(child: previewScope(child: AddProductScreen()));

@Preview(name: 'Add Product — Desktop', group: 'Product Screens', size: Size(1280, 800))
Widget previewAddProductScreenDesktop() => previewDesktop(child: previewScope(child: AddProductScreen()));

@Preview(name: 'Add Product — Web', group: 'Product Screens', size: Size(1440, 900))
Widget previewAddProductScreenWeb() => previewWeb(child: previewScope(child: AddProductScreen()));
