import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/cart_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Shopping Cart', group: 'Screens')
Widget previewCartScreen() => previewResponsiveBreakpoints(builder: (breakpoint) => previewScope(child: CartScreen()));
