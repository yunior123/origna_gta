import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/seller_setup_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Seller Onboarding — Success', group: 'Screens — Seller Management')
Widget previewSellerSetupCompleteScreen() => previewResponsiveBreakpoints(builder: (breakpoint) => previewScope(child: SellerSetupCompleteScreen()));

@Preview(name: 'Seller Onboarding — Refresh Needed', group: 'Screens — Seller Management')
Widget previewSellerSetupRefreshScreen() => previewResponsiveBreakpoints(builder: (breakpoint) => previewScope(child: SellerSetupRefreshScreen()));
