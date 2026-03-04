import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/shipping_approval_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Verify Shipping — Mobile', group: 'Screens — Seller Management', size: Size(390, 844))
Widget previewShippingApprovalScreenMobile() => previewMobile(child: previewScope(child: ShippingApprovalScreen()));

@Preview(name: 'Verify Shipping — Tablet', group: 'Screens — Seller Management', size: Size(768, 1024))
Widget previewShippingApprovalScreenTablet() => previewTablet(child: previewScope(child: ShippingApprovalScreen()));

@Preview(name: 'Verify Shipping — Desktop', group: 'Screens — Seller Management', size: Size(1280, 800))
Widget previewShippingApprovalScreenDesktop() => previewDesktop(child: previewScope(child: ShippingApprovalScreen()));

@Preview(name: 'Verify Shipping — Web', group: 'Screens — Seller Management', size: Size(1440, 900))
Widget previewShippingApprovalScreenWeb() => previewWeb(child: previewScope(child: ShippingApprovalScreen()));
