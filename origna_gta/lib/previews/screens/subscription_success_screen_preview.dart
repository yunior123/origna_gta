import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/subscription_success_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Premium Upgrade Success — Mobile', group: 'Screens — Premium Flow', size: Size(390, 844))
Widget previewSubscriptionSuccessScreenMobile() => previewMobile(child: previewScope(child: SubscriptionSuccessScreen()));

@Preview(name: 'Premium Upgrade Success — Tablet', group: 'Screens — Premium Flow', size: Size(768, 1024))
Widget previewSubscriptionSuccessScreenTablet() => previewTablet(child: previewScope(child: SubscriptionSuccessScreen()));

@Preview(name: 'Premium Upgrade Success — Desktop', group: 'Screens — Premium Flow', size: Size(1280, 800))
Widget previewSubscriptionSuccessScreenDesktop() => previewDesktop(child: previewScope(child: SubscriptionSuccessScreen()));

@Preview(name: 'Premium Upgrade Success — Web', group: 'Screens — Premium Flow', size: Size(1440, 900))
Widget previewSubscriptionSuccessScreenWeb() => previewWeb(child: previewScope(child: SubscriptionSuccessScreen()));
