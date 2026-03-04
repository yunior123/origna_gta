import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/screens/shipping_approval_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Verify Shipping Details', group: 'Screens — Seller Management')
Widget previewShippingApprovalScreen() => previewResponsiveBreakpoints(builder: (breakpoint) => const ProviderScope(child: ShippingApprovalScreen()));
