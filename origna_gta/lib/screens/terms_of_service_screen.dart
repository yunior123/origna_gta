import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/widgets/legal_screen_body.dart';
import 'package:flutter/widget_previews.dart';

/// Displays the current Terms of Service and records user acceptance.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LegalScreenBody(
        rawContent: 'legal.terms_of_service_content'.tr(),
        heroTitle: 'legal.terms_of_service_hero'.tr(),
        heroBadge: 'legal.legal_agreement'.tr(),
        heroBadgeIcon: Icons.verified_outlined,
      ),
    );
  }
}

// ─── Flutter Previews ────────────────────────────────────────────────────────



// === Widget Previews ===


// ═══ Widget Previews ═══

@Preview(name: 'Terms of Service — Mobile', group: 'Screens — Legal', size: Size(390, 844))
Widget previewTermsOfServiceScreenMobile() =>
    previewMobile(child: const TermsOfServiceScreen());

@Preview(name: 'Terms of Service — Desktop', group: 'Screens — Legal', size: Size(1280, 800))
Widget previewTermsOfServiceScreenDesktop() =>
    previewDesktop(child: const TermsOfServiceScreen());

@Preview(name: 'Terms of Service Light — Desktop', group: 'Screens — Legal', size: Size(1280, 800))
Widget previewTermsOfServiceLightDesktop() => previewDesktop(
  theme: previewLightTheme,
  child: const TermsOfServiceScreen(),
);

