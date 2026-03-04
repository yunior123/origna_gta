import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/screens/seller_registration_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Become a Seller', group: 'Screens — Seller Management')
Widget previewSellerRegistrationScreen() => previewResponsiveBreakpoints(builder: (breakpoint) => const ProviderScope(child: SellerRegistrationScreen()));
