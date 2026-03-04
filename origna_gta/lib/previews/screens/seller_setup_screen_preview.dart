import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/screens/seller_setup_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Seller Onboarding — Success', group: 'Screens — Seller Management')
Widget previewSellerSetupCompleteScreen() => previewResponsiveBreakpoints(builder: (breakpoint) => const ProviderScope(child: SellerSetupCompleteScreen()));

@Preview(name: 'Seller Onboarding — Refresh Needed', group: 'Screens — Seller Management')
Widget previewSellerSetupRefreshScreen() => previewResponsiveBreakpoints(builder: (breakpoint) => const ProviderScope(child: SellerSetupRefreshScreen()));
