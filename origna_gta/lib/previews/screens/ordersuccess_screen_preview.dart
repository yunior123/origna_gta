import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/ordersuccess_screen.dart';

import '../_preview_theme.dart';

Widget _orderSuccessContent() => previewScope(
  child: Scaffold(body: Center(child: OrderSuccessScreen(orderId: 'preview-id'))),
);

@Preview(name: 'Order Success — Mobile', group: 'Order Screens', size: Size(390, 844))
Widget previewOrderSuccessScreenMobile() => previewMobile(child: _orderSuccessContent());

@Preview(name: 'Order Success — Tablet', group: 'Order Screens', size: Size(768, 1024))
Widget previewOrderSuccessScreenTablet() => previewTablet(child: _orderSuccessContent());

@Preview(name: 'Order Success — Desktop', group: 'Order Screens', size: Size(1280, 800))
Widget previewOrderSuccessScreenDesktop() => previewDesktop(child: _orderSuccessContent());

@Preview(name: 'Order Success — Web', group: 'Order Screens', size: Size(1440, 900))
Widget previewOrderSuccessScreenWeb() => previewWeb(child: _orderSuccessContent());
