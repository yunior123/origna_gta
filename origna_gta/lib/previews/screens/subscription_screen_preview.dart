import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/subscription_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Premium Subscription Plans — Mobile', group: 'Screens — Premium Flow', size: Size(390, 844))
Widget previewSubscriptionScreenMobile() => previewMobile(child: previewScope(child: SubscriptionScreen()));

@Preview(name: 'Premium Subscription Plans — Tablet', group: 'Screens — Premium Flow', size: Size(768, 1024))
Widget previewSubscriptionScreenTablet() => previewTablet(child: previewScope(child: SubscriptionScreen()));

@Preview(name: 'Premium Subscription Plans — Desktop', group: 'Screens — Premium Flow', size: Size(1280, 800))
Widget previewSubscriptionScreenDesktop() => previewDesktop(child: previewScope(child: SubscriptionScreen()));

@Preview(name: 'Premium Subscription Plans — Web', group: 'Screens — Premium Flow', size: Size(1440, 900))
Widget previewSubscriptionScreenWeb() => previewWeb(child: previewScope(child: SubscriptionScreen()));
