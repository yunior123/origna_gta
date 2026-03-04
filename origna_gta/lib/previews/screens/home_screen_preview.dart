import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/home_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Home Screen', group: 'Home Screens')
Widget previewHomeScreen() {
  return previewResponsiveBreakpoints(builder: (breakpoint) => previewScope(child: HomeScreen()));
}
