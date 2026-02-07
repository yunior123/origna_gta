import 'package:flutter/material.dart';
import 'package:origna_gta/widgets/legal_screen_body.dart';

// ============================================================================
// PRIVACY POLICY CONTENT
// ============================================================================

const String _privacyPolicyContent = '''
1. Information We Collect
We collect personal information to provide and improve our marketplace services:
- Account Information: Name, email address, and password when you register.
- Profile Information: Delivery addresses and phone numbers you provide.
- Payment Information: Payment card details and billing addresses, processed securely by our payment partners (Stripe, Airwallex). We do not store full card numbers.
- Order Information: Purchase history, items ordered, amounts paid, and delivery details.
- Usage Data: Pages visited, search queries, features used, device type, browser, and IP address.
- Communications: Messages between buyers and sellers, support requests.

2. How We Use Your Information
We use your information to:
- Process and fulfill your orders, including shipping, payment, and delivery.
- Create and manage your account and authenticate your identity.
- Send important notifications: order updates, shipping confirmations, and security alerts.
- Improve our platform through analytics and usage patterns.
- Detect and prevent fraud, abuse, and unauthorized access.
- Comply with legal obligations and enforce our Terms of Service.
- Provide customer support and respond to your inquiries.

3. Data Sharing & Third Parties
We do not sell your personal data. We share information only with:
- Payment Processors: Stripe and Airwallex for secure payment processing.
- Cloud Services: Firebase (Google) for authentication, database, and hosting.
- Search Services: Algolia for product search functionality.
- Shipping Partners: Carrier services when fulfilling deliveries.
- Sellers: Order details necessary to fulfill your purchases (name, address).
- Legal Requirements: When required by law, court order, or to protect rights and safety.

4. Seller-Specific Data
If you are a seller on OrignaGTA, we additionally collect:
- Business registration information and tax IDs (GST/HST).
- Government-issued identification for verification purposes.
- Payout information (bank account or payment provider details).
- Sales data, commission records, and payout history.
This data is used for verification, payout processing, tax compliance, and fraud prevention.

5. Your Rights & Choices
You have the right to:
- Access your personal data stored by us.
- Correct inaccurate or incomplete information.
- Request deletion of your account and associated data.
- Opt out of marketing communications at any time.
- Request a copy of your data in a portable format.
To exercise any of these rights, contact us at support@orignaventures.ca.

6. Data Security
We implement industry-standard security measures:
- All data transmitted is encrypted using TLS/SSL.
- Payment data is handled by PCI-DSS compliant processors.
- Access to personal data is restricted to authorized personnel only.
- Regular security audits and monitoring for vulnerabilities.
- Firebase Security Rules protect database access at the field level.

7. Data Retention
- Account data is retained while your account is active.
- Order records are kept for 7 years for tax and legal compliance.
- Deleted accounts have personal data removed within 30 days.
- Anonymized analytics data may be retained indefinitely.

8. Cookies & Tracking
We use essential cookies and local storage for:
- Maintaining your login session and authentication state.
- Remembering your preferences and cart contents.
- Analytics to improve platform performance (no third-party ad tracking).

9. Children's Privacy
OrignaGTA is not intended for children under 16. We do not knowingly collect personal information from minors. If you believe a child has provided us data, contact us for removal.

10. Changes to This Policy
We may update this Privacy Policy periodically. Material changes will be notified:
- Via email to your registered address.
- Through an in-app notification banner.
- Changes take effect 14 days after notification.

11. Contact Us
For privacy-related questions or concerns:
- Email: support@orignaventures.ca
- Website: orignaventures.ca
- Response time: Within 24 business hours (Mon-Fri, 9 AM - 6 PM EST).
''';

// ============================================================================
// PRIVACY POLICY SCREEN
// ============================================================================

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: LegalScreenBody(
        rawContent: _privacyPolicyContent,
        heroTitle: 'Privacy\nPolicy',
        heroBadge: 'Your Privacy Matters',
        heroBadgeIcon: Icons.lock_outlined,
      ),
    );
  }
}
