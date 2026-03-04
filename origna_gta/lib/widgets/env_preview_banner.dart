import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/env_config.dart';

/// A wrapper widget that displays a "DEV", "STAGING", or "BETA" ribbon
/// on the web platform during the early launch period.
class EnvPreviewBanner extends StatelessWidget {
  final Widget child;

  const EnvPreviewBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Only show on the web platform
    if (!kIsWeb) {
      return child;
    }

    String? bannerText;
    Color bannerColor = DesignTokens.primary;

    if (envConfig.isEmulator || envConfig.isDev) {
      bannerText = 'DEV';
      bannerColor = DesignTokens.warning;
    } else if (envConfig.isStaging) {
      bannerText = 'STAGING';
      bannerColor = DesignTokens.secondary;
    } else if (envConfig.isProduction) {
      // Show "BETA" during the first 3 months of launch.
      // Launch target is March 1, 2026. 3 months is June 1, 2026.
      final now = DateTime.now();
      final cutoffDate = DateTime(2026, 6, 1);

      if (now.isBefore(cutoffDate)) {
        bannerText = 'BETA';
        bannerColor = DesignTokens.info;
      }
    }

    // If no banner is needed, return the child as is
    if (bannerText == null) {
      return child;
    }

    return Banner(message: bannerText, location: BannerLocation.topEnd, color: bannerColor, child: child);
  }
}

// ─── Flutter Widget Previews ─────────────────────────────────────────────────

Widget _bannerScaffold(String label, Color color) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData.dark(),
  home: Scaffold(
    backgroundColor: DesignTokens.darkBackground,
    body: Banner(
      message: label,
      location: BannerLocation.topEnd,
      color: color,
      child: Center(child: Text('App Content', style: TextStyle(color: DesignTokens.textOnPrimary, fontSize: 16))),
    ),
  ),
);

@Preview(name: 'DEV Banner', group: 'EnvPreviewBanner')
Widget previewEnvDev() => _bannerScaffold('DEV', DesignTokens.warning);

@Preview(name: 'STAGING Banner', group: 'EnvPreviewBanner')
Widget previewEnvStaging() => _bannerScaffold('STAGING', DesignTokens.secondary);

@Preview(name: 'BETA Banner', group: 'EnvPreviewBanner')
Widget previewEnvBeta() => _bannerScaffold('BETA', DesignTokens.info);
