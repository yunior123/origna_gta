import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/screens/orders_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Orders Screen', group: 'Order Screens')
Widget previewOrdersScreen() {
  return previewResponsiveBreakpoints(builder: (breakpoint) => const ProviderScope(child: OrdersScreen()));
}
