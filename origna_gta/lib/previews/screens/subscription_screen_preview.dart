import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/screens/subscription_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Premium Subscription Plans', group: 'Screens — Premium Flow')
Widget previewSubscriptionScreen() => previewResponsiveBreakpoints(builder: (breakpoint) => const ProviderScope(child: SubscriptionScreen()));
