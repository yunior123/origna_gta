import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/shipping_approval_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Verify Shipping Details', group: 'Screens — Seller Management')
Widget previewShippingApprovalScreen() => previewResponsiveBreakpoints(builder: (breakpoint) => previewScope(child: ShippingApprovalScreen()));
