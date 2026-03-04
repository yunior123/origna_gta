import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/screens/order_detail_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Order Detail Screen', group: 'Order Screens')
Widget previewOrderDetailScreen() {
  return previewResponsiveBreakpoints(
    builder: (breakpoint) => previewScope(
      child: OrderDetailScreenLayout(orderAsync: const AsyncValue.loading(), onBack: () {}, onRefresh: () {}),
    ),
  );
}
