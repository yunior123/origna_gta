import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/authwrapper_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Auth Wrapper', group: 'Auth Screens')
Widget previewAuthWrapperScreen() {
  return previewResponsiveBreakpoints(builder: (breakpoint) => previewScope(child: AuthWrapper()));
}
