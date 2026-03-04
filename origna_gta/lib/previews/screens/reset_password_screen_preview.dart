import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/reset_password_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Reset Password', group: 'Auth Screens')
Widget previewResetPasswordScreen() {
  return previewResponsiveBreakpoints(
    builder: (breakpoint) => previewScope(child: ResetPasswordScreen(oobCode: 'preview-oob-code')),
  );
}
