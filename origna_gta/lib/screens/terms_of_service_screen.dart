import 'package:flutter/widget_previews.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/widgets/legal_screen_body.dart';

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

@Preview(name: 'TermsOfServiceScreen — Dark', group: 'TermsOfServiceScreen')
Widget previewTermsOfServiceScreenDark() => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const TermsOfServiceScreen(),
    );

@Preview(name: 'TermsOfServiceScreen — Light', group: 'TermsOfServiceScreen')
Widget previewTermsOfServiceScreenLight() => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: const TermsOfServiceScreen(),
    );
