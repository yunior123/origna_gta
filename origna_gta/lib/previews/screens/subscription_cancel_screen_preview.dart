import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/subscription_cancel_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Cancel Subscription Confirmation', group: 'Screens — Premium Flow')
Widget previewSubscriptionCancelScreen() => previewResponsiveBreakpoints(builder: (breakpoint) => const SubscriptionCancelScreen());
