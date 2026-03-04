import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/orders_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Orders Screen — Mobile', group: 'Order Screens', size: Size(390, 844))
Widget previewOrdersScreenMobile() => previewMobile(child: previewScope(child: OrdersScreen()));

@Preview(name: 'Orders Screen — Tablet', group: 'Order Screens', size: Size(768, 1024))
Widget previewOrdersScreenTablet() => previewTablet(child: previewScope(child: OrdersScreen()));

@Preview(name: 'Orders Screen — Desktop', group: 'Order Screens', size: Size(1280, 800))
Widget previewOrdersScreenDesktop() => previewDesktop(child: previewScope(child: OrdersScreen()));

@Preview(name: 'Orders Screen — Web', group: 'Order Screens', size: Size(1440, 900))
Widget previewOrdersScreenWeb() => previewWeb(child: previewScope(child: OrdersScreen()));
