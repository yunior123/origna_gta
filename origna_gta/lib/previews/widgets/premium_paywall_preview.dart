import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/previews/_preview_theme.dart';
import 'package:origna_gta/widgets/premium_paywall_widget.dart';

@Preview(name: 'Premium Paywall — Responsive', group: 'PremiumPaywall')
Widget previewPaywallResponsive() => previewResponsiveBreakpoints(
  builder: (bp) => const Center(child: PremiumPaywallWidget(featureName: 'Global Shipping Discounts')),
);

@Preview(name: 'Premium Paywall — Variants', group: 'PremiumPaywall')
Widget previewPaywallVariants() => previewGrid(
  children: [
    const PremiumPaywallWidget(featureName: 'Product Video Upload'),
    const PremiumPaywallWidget(featureName: 'Advanced Analytics', description: 'Upgrade for detailed insights into your shop sales and visitor behavior.'),
  ],
);
