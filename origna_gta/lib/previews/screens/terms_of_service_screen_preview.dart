import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/terms_of_service_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'General Terms of Service', group: 'Screens — Legal')
Widget previewTermsOfServiceScreen() => previewResponsiveBreakpoints(builder: (breakpoint) => const TermsOfServiceScreen());
