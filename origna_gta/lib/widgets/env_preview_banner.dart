import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/env_config.dart';
import 'package:origna_gta/utils/preview_helpers.dart';

/// A wrapper widget that displays a "DEV", "STAGING", or "BETA" ribbon
/// on the web platform during the early launch period.
class EnvPreviewBanner extends StatelessWidget {
  final Widget child;

  const EnvPreviewBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    String? bannerText;
    Color bannerColor = DesignTokens.primary;

    if (envConfig.isEmulator || envConfig.isDev) {
      bannerText = 'DEV';
      bannerColor = DesignTokens.warning;
    } else if (envConfig.isStaging) {
      bannerText = 'STAGING';
      bannerColor = DesignTokens.secondary;
    } else if (envConfig.isProduction) {
      final now = DateTime.now();
      final cutoffDate = DateTime(2026, 6, 1);
      if (now.isBefore(cutoffDate)) {
        bannerText = 'BETA';
        bannerColor = DesignTokens.info;
      }
    }

    if (bannerText == null) return child;

    return Stack(
      children: [
        child,
        Positioned(
          top: 12,
          right: 12,
          child: IgnorePointer(
            child: SafeArea(
              bottom: false,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bannerColor.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.black.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Text(
                    bannerText,
                    style: const TextStyle(
                      color: DesignTokens.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

@Preview(
  name: 'Env Banner — Mobile',
  group: 'EnvPreviewBanner',
  size: Size(390, 844),
)
Widget previewEnvBannerMobile() => previewWrapper(
  child: const EnvPreviewBanner(child: Text('Content')),
  breakpoint: PreviewBreakpoint.mobile,
);

@Preview(
  name: 'Env Banner — Desktop',
  group: 'EnvPreviewBanner',
  size: Size(1280, 800),
)
Widget previewEnvBannerDesktop() => previewWrapper(
  child: const EnvPreviewBanner(child: Text('Content')),
  breakpoint: PreviewBreakpoint.desktop,
);
