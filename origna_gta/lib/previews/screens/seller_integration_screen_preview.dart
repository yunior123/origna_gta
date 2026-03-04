import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/seller_integration_screen.dart';
import '../_preview_theme.dart';

@Preview(name: 'SellerIntegrationScreen — Dark', group: 'SellerIntegrationScreen')
Widget previewSellerIntegrationScreenDark() => previewScope(
  child: MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData.dark(), home: const SellerIntegrationScreen()),
);

@Preview(name: 'SellerIntegrationScreen — Light', group: 'SellerIntegrationScreen')
Widget previewSellerIntegrationScreenLight() => previewScope(
  child: MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData.light(), home: const SellerIntegrationScreen()),
);
