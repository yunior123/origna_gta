import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/editaddress_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Manage Address — Mobile', group: 'Screens', size: Size(390, 844))
Widget previewAddEditAddressScreenMobile() => previewMobile(child: previewScope(child: AddEditAddressScreen()));

@Preview(name: 'Manage Address — Tablet', group: 'Screens', size: Size(768, 1024))
Widget previewAddEditAddressScreenTablet() => previewTablet(child: previewScope(child: AddEditAddressScreen()));

@Preview(name: 'Manage Address — Desktop', group: 'Screens', size: Size(1280, 800))
Widget previewAddEditAddressScreenDesktop() => previewDesktop(child: previewScope(child: AddEditAddressScreen()));

@Preview(name: 'Manage Address — Web', group: 'Screens', size: Size(1440, 900))
Widget previewAddEditAddressScreenWeb() => previewWeb(child: previewScope(child: AddEditAddressScreen()));
