import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/screens/addressmanagement_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Address Management', group: 'Screens')
Widget previewAddressManagementScreen() => previewResponsiveBreakpoints(builder: (breakpoint) => const ProviderScope(child: AddressManagementScreen()));
