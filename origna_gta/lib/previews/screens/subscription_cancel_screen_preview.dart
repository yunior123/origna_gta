import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/subscription_cancel_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Cancel Subscription — Mobile', group: 'Screens — Premium Flow', size: Size(390, 844))
Widget previewSubscriptionCancelScreenMobile() => previewMobile(child: const SubscriptionCancelScreen());

@Preview(name: 'Cancel Subscription — Tablet', group: 'Screens — Premium Flow', size: Size(768, 1024))
Widget previewSubscriptionCancelScreenTablet() => previewTablet(child: const SubscriptionCancelScreen());

@Preview(name: 'Cancel Subscription — Desktop', group: 'Screens — Premium Flow', size: Size(1280, 800))
Widget previewSubscriptionCancelScreenDesktop() => previewDesktop(child: const SubscriptionCancelScreen());

@Preview(name: 'Cancel Subscription — Web', group: 'Screens — Premium Flow', size: Size(1440, 900))
Widget previewSubscriptionCancelScreenWeb() => previewWeb(child: const SubscriptionCancelScreen());
