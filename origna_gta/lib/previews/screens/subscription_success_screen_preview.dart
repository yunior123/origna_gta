import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/subscription_success_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Premium Upgrade Success', group: 'Screens — Premium Flow')
Widget previewSubscriptionSuccessScreen() => previewResponsiveBreakpoints(builder: (breakpoint) => previewScope(child: SubscriptionSuccessScreen()));
