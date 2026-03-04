import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/checkout_screen.dart';

import '../_preview_theme.dart';

Widget _checkoutContent() => previewScope(child: CheckoutScreen(items: [], total: 150.00));

@Preview(name: 'Checkout — Mobile', group: 'Cart Screens', size: Size(390, 844))
Widget previewCheckoutScreenMobile() => previewMobile(child: _checkoutContent());

@Preview(name: 'Checkout — Tablet', group: 'Cart Screens', size: Size(768, 1024))
Widget previewCheckoutScreenTablet() => previewTablet(child: _checkoutContent());

@Preview(name: 'Checkout — Desktop', group: 'Cart Screens', size: Size(1280, 800))
Widget previewCheckoutScreenDesktop() => previewDesktop(child: _checkoutContent());

@Preview(name: 'Checkout — Web', group: 'Cart Screens', size: Size(1440, 900))
Widget previewCheckoutScreenWeb() => previewWeb(child: _checkoutContent());
