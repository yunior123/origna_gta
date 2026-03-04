import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/addressmanagement_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Address Management — Mobile', group: 'Screens', size: Size(390, 844))
Widget previewAddressManagementScreenMobile() => previewMobile(child: previewScope(child: AddressManagementScreen()));

@Preview(name: 'Address Management — Tablet', group: 'Screens', size: Size(768, 1024))
Widget previewAddressManagementScreenTablet() => previewTablet(child: previewScope(child: AddressManagementScreen()));

@Preview(name: 'Address Management — Desktop', group: 'Screens', size: Size(1280, 800))
Widget previewAddressManagementScreenDesktop() => previewDesktop(child: previewScope(child: AddressManagementScreen()));

@Preview(name: 'Address Management — Web', group: 'Screens', size: Size(1440, 900))
Widget previewAddressManagementScreenWeb() => previewWeb(child: previewScope(child: AddressManagementScreen()));
