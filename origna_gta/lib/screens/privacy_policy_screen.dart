import 'package:flutter/widget_previews.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/widgets/legal_screen_body.dart';

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

@Preview(name: 'PrivacyPolicyScreen — Dark', group: 'PrivacyPolicyScreen')
Widget previewPrivacyPolicyScreenDark() => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const PrivacyPolicyScreen(),
    );

@Preview(name: 'PrivacyPolicyScreen — Light', group: 'PrivacyPolicyScreen')
Widget previewPrivacyPolicyScreenLight() => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: const PrivacyPolicyScreen(),
    );
