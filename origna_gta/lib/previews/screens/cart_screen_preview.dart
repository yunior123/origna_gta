import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/cart_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Shopping Cart — Mobile', group: 'Cart Screens', size: Size(390, 844))
Widget previewCartScreenMobile() => previewMobile(child: previewScope(child: CartScreen()));

@Preview(name: 'Shopping Cart — Tablet', group: 'Cart Screens', size: Size(768, 1024))
Widget previewCartScreenTablet() => previewTablet(child: previewScope(child: CartScreen()));

@Preview(name: 'Shopping Cart — Desktop', group: 'Cart Screens', size: Size(1280, 800))
Widget previewCartScreenDesktop() => previewDesktop(child: previewScope(child: CartScreen()));

@Preview(name: 'Shopping Cart — Web', group: 'Cart Screens', size: Size(1440, 900))
Widget previewCartScreenWeb() => previewWeb(child: previewScope(child: CartScreen()));
