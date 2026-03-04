import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/seller_registration_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Become a Seller — Mobile', group: 'Screens — Seller Management', size: Size(390, 844))
Widget previewSellerRegistrationScreenMobile() => previewMobile(child: previewScope(child: SellerRegistrationScreen()));

@Preview(name: 'Become a Seller — Tablet', group: 'Screens — Seller Management', size: Size(768, 1024))
Widget previewSellerRegistrationScreenTablet() => previewTablet(child: previewScope(child: SellerRegistrationScreen()));

@Preview(name: 'Become a Seller — Desktop', group: 'Screens — Seller Management', size: Size(1280, 800))
Widget previewSellerRegistrationScreenDesktop() => previewDesktop(child: previewScope(child: SellerRegistrationScreen()));

@Preview(name: 'Become a Seller — Web', group: 'Screens — Seller Management', size: Size(1440, 900))
Widget previewSellerRegistrationScreenWeb() => previewWeb(child: previewScope(child: SellerRegistrationScreen()));
