import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/screens/common_screens.dart';

import '../_preview_theme.dart';

@Preview(name: 'Email Verification Required', group: 'Screens — Auth Flows')
Widget previewEmailVerificationRequiredScreen() =>
    previewResponsiveBreakpoints(builder: (breakpoint) => const ProviderScope(child: EmailVerificationRequiredScreen()));
