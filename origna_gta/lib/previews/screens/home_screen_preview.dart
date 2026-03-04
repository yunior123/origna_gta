import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/home_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Home Screen — Mobile', group: 'Home Screens', size: Size(390, 844))
Widget previewHomeScreenMobile() => previewMobile(child: previewScope(child: HomeScreen()));

@Preview(name: 'Home Screen — Tablet', group: 'Home Screens', size: Size(768, 1024))
Widget previewHomeScreenTablet() => previewTablet(child: previewScope(child: HomeScreen()));

@Preview(name: 'Home Screen — Desktop', group: 'Home Screens', size: Size(1280, 800))
Widget previewHomeScreenDesktop() => previewDesktop(child: previewScope(child: HomeScreen()));

@Preview(name: 'Home Screen — Web', group: 'Home Screens', size: Size(1440, 900))
Widget previewHomeScreenWeb() => previewWeb(child: previewScope(child: HomeScreen()));
