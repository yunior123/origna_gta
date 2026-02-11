import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/widgets/legal_screen_body.dart';

// ============================================================================
// TERMS OF SERVICE CONTENT
// ============================================================================

const String _termsOfServiceContent = '''
1. Acceptance of Terms
By creating an account, browsing, or making purchases on OrignaGTA, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service, as well as our Privacy Policy. If you do not agree, you must not use the platform.

2. Account Registration & Responsibilities
To use certain features, you must register for an account. You agree to:
- Provide accurate and complete information during registration.
- Maintain the security of your account credentials.
- Accept responsibility for all activities under your account.
- Notify us immediately of any unauthorized use.
- Verify your email address before making purchases.

3. Purchases & Payments
When you make a purchase on OrignaGTA:
- All prices are in Canadian Dollars (CAD) unless otherwise stated.
- Prices include applicable taxes as required by law.
- Payment is processed securely through Stripe or Airwallex.
- You agree to pay all charges at the prices in effect when incurred.
- We reserve the right to refuse or cancel orders at our discretion.
- All payments are final unless covered by our return policy.

4. Shipping & Delivery
- Shipping costs are calculated dynamically using a tiered model benchmarked against major Canadian platforms.
- Hyper-Local Rates (within 15km): Starting at \$1.99 standard delivery.
- National Rates: Capped at \$26.99 ceiling to remain competitive.
- Delivery times are estimates and may vary based on carrier and distance.
- Sellers are responsible for timely dispatch within 3 business days.
- International shipping times may be longer (15-45 business days depending on supplier).

5. Returns & Refunds
- Return Window: 14 days from delivery confirmation.
- Items must be unused and in original packaging.
- Refunds are processed within 3-5 business days after item inspection.
- Contact the seller directly for return requests.
- Non-returnable items: perishable goods, hygiene products, custom items, digital products, and items marked "Final Sale."

6. Seller Responsibilities
If you sell products on OrignaGTA, you agree to:
- Provide accurate product descriptions, images, weights, and dimensions.
- Ship products within the specified timeframe.
- Respond to buyer inquiries promptly.
- Comply with all applicable laws, regulations, and tax obligations.
- Accept responsibility for the quality of your products.
- Maintain accurate inventory and stock levels.

7. Prohibited Activities
You may not:
- Violate any laws or regulations.
- Infringe on intellectual property rights.
- Post false, misleading, or deceptive information.
- Engage in fraudulent activities or price manipulation.
- Attempt to hack, disrupt, or exploit the platform.
- Use multiple accounts to circumvent restrictions.
- Share customer data with unauthorized third parties.

8. Intellectual Property
All content on OrignaGTA, including logos, designs, text, and software, is our property or licensed to us. You may not use, reproduce, or distribute this content without written permission.

9. Limitation of Liability
OrignaGTA is provided "as is" without warranties. We are not liable for:
- Indirect, incidental, or consequential damages.
- Loss of data, profits, or business opportunities.
- Actions of third-party sellers or payment providers.
- Service interruptions or technical issues beyond our control.

10. Privacy
Your use of OrignaGTA is governed by our Privacy Policy. By using our platform, you consent to the collection and use of your information as described therein.

11. Termination
We reserve the right to terminate or suspend your account for violations of these Terms, fraudulent behavior, or any other reason at our sole discretion. Upon termination, pending payouts for sellers may be held for up to 90 days.

12. Changes to Terms
We may modify these Terms at any time. Continued use of the platform after changes constitutes acceptance. Material changes will be communicated via email and in-app notification at least 14 days before taking effect.

13. Governing Law
These Terms are governed by the laws of Ontario, Canada. Any disputes shall be resolved in the courts of Ontario.

14. Contact Us
For questions about these Terms, please contact us at:
- Email: support@orignaventures.ca
- Website: orignaventures.ca

By using OrignaGTA, you acknowledge that you have read and understood these Terms and agree to be bound by them.
''';

// ============================================================================
// TERMS OF SERVICE SCREEN
// ============================================================================

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LegalScreenBody(
        rawContent: _termsOfServiceContent,
        heroTitle: 'legal.terms_of_service_hero'.tr(),
        heroBadge: 'legal.legal_agreement'.tr(),
        heroBadgeIcon: Icons.verified_outlined,
      ),
    );
  }
}
