import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:flutter/widget_previews.dart';

/// Promotional banner widget for homepage featured deals and campaigns.
class StandalonePromoWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String discountText;
  final bool isDark;
  final VoidCallback? onTap;

  const StandalonePromoWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.discountText,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  DesignTokens.promoSurfaceDark,
                  DesignTokens.promoSurfaceDarkAlt,
                ]
              : [
                  DesignTokens.promoSurfaceLight,
                  DesignTokens.promoSurfaceLightAlt,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 6.0,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? DesignTokens.promoBadgeDark
                  : DesignTokens.promoBadgeLight,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Text(
              discountText,
              style: const TextStyle(
                color: DesignTokens.white,
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            title,
            style: TextStyle(
              fontSize: 28.0,
              fontWeight: FontWeight.w900,
              color: isDark
                  ? DesignTokens.white
                  : DesignTokens.promoAccentLight,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? DesignTokens.white.withValues(alpha: 0.7)
                  : DesignTokens.promoTextLight,
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24.0),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? DesignTokens.white
                        : DesignTokens.promoAccentLight,
                    foregroundColor: isDark
                        ? DesignTokens.black
                        : DesignTokens.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'promotions.shop_now'.tr(),
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// === Widget Previews ===


// ═══ Widget Previews ═══

@Preview(name: 'PromoBanner - Dark', group: 'Promotions')
Widget previewPromoBannerDark() => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData.dark(),
  home: const Scaffold(
    backgroundColor: DesignTokens.black,
    body: Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: StandalonePromoWidget(
          title: 'Spring Clearance Event',
          subtitle: 'Save up to 50% on select items this weekend only.',
          discountText: '50% OFF',
          isDark: true,
        ),
      ),
    ),
  ),
);

@Preview(name: 'PromoBanner - Light', group: 'Promotions')
Widget previewPromoBannerLight() => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData.light(),
  home: const Scaffold(
    body: Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: StandalonePromoWidget(
          title: 'Spring Clearance Event',
          subtitle: 'Save up to 50% on select items this weekend only.',
          discountText: '50% OFF',
          isDark: false,
        ),
      ),
    ),
  ),
);

