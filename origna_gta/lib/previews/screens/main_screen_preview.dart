import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/main_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Main Screen', group: 'Home Screens')
Widget previewMainScreen() {
  return previewResponsiveBreakpoints(builder: (breakpoint) => previewScope(child: MainScreen()));
}
