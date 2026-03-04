/// Flutter Widget Previewer — PremiumPaywallWidget variants.
library;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/premium_paywall_widget.dart';

import '_preview_theme.dart';

@Preview(name: 'With description — dark', group: 'PremiumPaywall')
Widget previewPaywallWithDescription() => previewWrapper(
  child: PremiumPaywallWidget(
    featureName: 'Photo Reviews',
    description: 'Attach photos to your product reviews and help other buyers make informed decisions.',
  ),
);

@Preview(name: 'Without description — dark', group: 'PremiumPaywall')
Widget previewPaywallNoDescription() => previewWrapper(
  child: const PremiumPaywallWidget(featureName: 'Chat with Seller'),
);

@Preview(name: 'With description — light', group: 'PremiumPaywall', brightness: Brightness.light)
Widget previewPaywallLight() => previewWrapper(
  theme: previewLightTheme,
  background: DesignTokens.surface,
  child: PremiumPaywallWidget(
    featureName: 'Priority Support',
    description: 'Get direct access to our support team with guaranteed 2-hour response times.',
  ),
);
