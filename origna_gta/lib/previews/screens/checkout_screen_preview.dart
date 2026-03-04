import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/screens/checkout_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Checkout Screen', group: 'Cart Screens')
Widget previewCheckoutScreen() {
  return previewResponsiveBreakpoints(
    builder: (breakpoint) => const ProviderScope(child: CheckoutScreen(items: [], total: 150.00)),
  );
}
