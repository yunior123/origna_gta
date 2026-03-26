import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/previews/_preview_theme.dart';
import 'package:origna_gta/widgets/legal_screen_body.dart';

const _kPrivacyMock = '''
# Privacy Policy
We value your privacy. Your data is handled securely and not shared with third parties without your consent. 
''';

const _kTermsMock = '''
# Terms of Service
By using our service, you agree to our terms.
''';

@Preview(name: 'Legal — Mobile Dark', group: 'Legal Content', size: Size(390, 844), brightness: Brightness.dark)
Widget previewLegalMobile() => previewMobile(
  child: const LegalScreenBody(
    heroTitle: 'Privacy Policy',
    heroBadge: 'PRIVACY',
    heroBadgeIcon: Icons.shield_outlined,
    rawContent: _kPrivacyMock,
  ),
);

@Preview(name: 'Legal — Tablet Dark', group: 'Legal Content', size: Size(768, 1024), brightness: Brightness.dark)
Widget previewLegalTablet() => previewTablet(
  child: const LegalScreenBody(
    heroTitle: 'Privacy Policy',
    heroBadge: 'PRIVACY',
    heroBadgeIcon: Icons.shield_outlined,
    rawContent: _kPrivacyMock,
  ),
);

@Preview(name: 'Legal — Desktop Dark', group: 'Legal Content', size: Size(1280, 800), brightness: Brightness.dark)
Widget previewLegalDesktop() => previewDesktop(
  child: const LegalScreenBody(
    heroTitle: 'Privacy Policy',
    heroBadge: 'PRIVACY',
    heroBadgeIcon: Icons.shield_outlined,
    rawContent: _kPrivacyMock,
  ),
);

@Preview(name: 'Legal Content — Variants', group: 'LegalScreenBody')
Widget previewLegalVariants() => previewGrid(
  children: [
    SizedBox(
      height: 700,
      child: const LegalScreenBody(
        heroTitle: 'Privacy Policy',
        heroBadge: 'PRIVACY',
        heroBadgeIcon: Icons.shield_outlined,
        rawContent: _kPrivacyMock,
      ),
    ),
    SizedBox(
      height: 700,
      child: const LegalScreenBody(
        heroTitle: 'Terms of Service',
        heroBadge: 'TERMS',
        heroBadgeIcon: Icons.gavel_outlined,
        rawContent: _kTermsMock,
      ),
    ),
  ],
);

@Preview(name: 'Legal Light — Mobile', group: 'Legal Content', size: Size(390, 844), brightness: Brightness.light)
Widget previewLegalLightMobile() => previewMobile(
  theme: previewLightTheme,
  child: const LegalScreenBody(
    heroTitle: 'Privacy Policy',
    heroBadge: 'PRIVACY',
    heroBadgeIcon: Icons.shield_outlined,
    rawContent: _kPrivacyMock,
  ),
);

@Preview(name: 'Legal Light — Tablet', group: 'Legal Content', size: Size(768, 1024), brightness: Brightness.light)
Widget previewLegalLightTablet() => previewTablet(
  theme: previewLightTheme,
  child: const LegalScreenBody(
    heroTitle: 'Privacy Policy',
    heroBadge: 'PRIVACY',
    heroBadgeIcon: Icons.shield_outlined,
    rawContent: _kPrivacyMock,
  ),
);

@Preview(name: 'Legal Light — Desktop', group: 'Legal Content', size: Size(1280, 800), brightness: Brightness.light)
Widget previewLegalLightDesktop() => previewDesktop(
  theme: previewLightTheme,
  child: const LegalScreenBody(
    heroTitle: 'Privacy Policy',
    heroBadge: 'PRIVACY',
    heroBadgeIcon: Icons.shield_outlined,
    rawContent: _kPrivacyMock,
  ),
);

@Preview(name: 'Legal Content Light — Variants', group: 'LegalScreenBody')
Widget previewLegalVariantsLight() => previewGrid(
  theme: previewLightTheme,
  children: [
    SizedBox(
      height: 700,
      child: const LegalScreenBody(
        heroTitle: 'Privacy Policy',
        heroBadge: 'PRIVACY',
        heroBadgeIcon: Icons.shield_outlined,
        rawContent: _kPrivacyMock,
      ),
    ),
    SizedBox(
      height: 700,
      child: const LegalScreenBody(
        heroTitle: 'Terms of Service',
        heroBadge: 'TERMS',
        heroBadgeIcon: Icons.gavel_outlined,
        rawContent: _kTermsMock,
      ),
    ),
  ],
);
