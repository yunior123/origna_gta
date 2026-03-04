import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/ordersuccess_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Order Success Screen', group: 'Order Screens')
Widget previewOrderSuccessScreen() {
  return previewResponsiveBreakpoints(
    builder: (breakpoint) => previewScope(
      child: Scaffold(
        body: Center(child: OrderSuccessScreen(orderId: 'preview-id')),
      ),
    ),
  );
}
