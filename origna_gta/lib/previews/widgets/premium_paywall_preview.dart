import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/previews/_preview_theme.dart';
import 'package:origna_gta/widgets/premium_paywall_widget.dart';

@Preview(name: 'Paywall — Mobile Dark', group: 'Premium Paywall', size: Size(390, 844), brightness: Brightness.dark)
Widget previewPaywallMobile() => previewMobile(
  child: const Center(child: PremiumPaywallWidget(featureName: 'Global Shipping Discounts')),
);

@Preview(name: 'Paywall — Tablet Dark', group: 'Premium Paywall', size: Size(768, 1024), brightness: Brightness.dark)
Widget previewPaywallTablet() => previewTablet(
  child: const Center(child: PremiumPaywallWidget(featureName: 'Global Shipping Discounts')),
);

@Preview(name: 'Paywall — Desktop Dark', group: 'Premium Paywall', size: Size(1280, 800), brightness: Brightness.dark)
Widget previewPaywallDesktop() => previewDesktop(
  child: const Center(child: PremiumPaywallWidget(featureName: 'Global Shipping Discounts')),
);

@Preview(name: 'Premium Paywall — Variants', group: 'PremiumPaywall')
Widget previewPaywallVariants() => previewGrid(
  children: [
    const PremiumPaywallWidget(featureName: 'Product Video Upload'),
    const PremiumPaywallWidget(featureName: 'Advanced Analytics', description: 'Upgrade for detailed insights into your shop sales and visitor behavior.'),
  ],
);

@Preview(name: 'Paywall Light — Mobile', group: 'Premium Paywall', size: Size(390, 844), brightness: Brightness.light)
Widget previewPaywallLightMobile() => previewMobile(
  theme: previewLightTheme,
  child: const Center(child: PremiumPaywallWidget(featureName: 'Global Shipping Discounts')),
);

@Preview(name: 'Paywall Light — Tablet', group: 'Premium Paywall', size: Size(768, 1024), brightness: Brightness.light)
Widget previewPaywallLightTablet() => previewTablet(
  theme: previewLightTheme,
  child: const Center(child: PremiumPaywallWidget(featureName: 'Global Shipping Discounts')),
);

@Preview(name: 'Paywall Light — Desktop', group: 'Premium Paywall', size: Size(1280, 800), brightness: Brightness.light)
Widget previewPaywallLightDesktop() => previewDesktop(
  theme: previewLightTheme,
  child: const Center(child: PremiumPaywallWidget(featureName: 'Global Shipping Discounts')),
);

@Preview(name: 'Premium Paywall Light — Variants', group: 'PremiumPaywall')
Widget previewPaywallVariantsLight() => previewGrid(
  theme: previewLightTheme,
  children: [
    const PremiumPaywallWidget(featureName: 'Product Video Upload'),
    const PremiumPaywallWidget(featureName: 'Advanced Analytics', description: 'Upgrade for detailed insights into your shop sales and visitor behavior.'),
  ],
);
