import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/widgets/legal_screen_body.dart';
import 'package:flutter/widget_previews.dart';

/// Displays the current Privacy Policy (PIPEDA/Quebec Law 25 compliant).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LegalScreenBody(
        rawContent: 'legal.privacy_policy_content'.tr(),
        heroTitle: 'legal.privacy_policy_hero'.tr(),
        heroBadge: 'legal.your_privacy_matters'.tr(),
        heroBadgeIcon: Icons.lock_outlined,
      ),
    );
  }
}

// ─── Flutter Previews ────────────────────────────────────────────────────────

// === Widget Previews ===

// ═══ Widget Previews ═══

@Preview(
  name: 'Privacy Policy — Mobile',
  group: 'Screens — Legal',
  size: Size(390, 844),
)
Widget previewPrivacyPolicyScreenMobile() =>
    previewMobile(child: const PrivacyPolicyScreen());

@Preview(
  name: 'Privacy Policy — Desktop',
  group: 'Screens — Legal',
  size: Size(1280, 800),
)
Widget previewPrivacyPolicyScreenDesktop() =>
    previewDesktop(child: const PrivacyPolicyScreen());

@Preview(
  name: 'Privacy Policy Light — Desktop',
  group: 'Screens — Legal',
  size: Size(1280, 800),
)
Widget previewPrivacyPolicyLightDesktop() => previewDesktop(
  theme: previewLightTheme,
  child: const PrivacyPolicyScreen(),
);
