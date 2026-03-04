import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/screens/terms_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Specific Legal Terms', group: 'Screens — Legal')
Widget previewTermsScreen() => previewResponsiveBreakpoints(builder: (breakpoint) => const ProviderScope(child: TermsScreen()));
