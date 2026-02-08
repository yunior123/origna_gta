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

2. Google User Data
OrignaGTA uses Google Firebase Authentication to allow you to sign in with your Google account. When you choose to sign in with Google, we access the following Google user data:

Data Accessed:
- Your Google account email address.
- Your Google display name.
- Your Google profile photo URL.
- Your unique Google account identifier (UID).

How We Use Google User Data:
- To create and authenticate your OrignaGTA account.
- To display your name and profile photo within the app.
- To send order confirmations, shipping updates, and security alerts to your email address.
- We do NOT use your Google user data for advertising, marketing to third parties, or any purpose unrelated to providing and improving OrignaGTA marketplace services.

How We Share Google User Data:
- We do NOT sell, rent, or trade your Google user data to any third party.
- Your Google email may be shared with Stripe or Airwallex solely for payment processing and receipts.
- Your display name and delivery address may be shared with sellers only to fulfill your orders.
- We may disclose data if required by Canadian law, court order, or to protect the rights and safety of our users.

How We Store and Protect Google User Data:
- Google user data is stored in Google Cloud Firestore, which is encrypted at rest and in transit.
- Access to user data is restricted by Firebase Security Rules, ensuring only authorized operations are permitted.
- All communication between the app and our servers is encrypted using TLS/SSL.
- We do not store Google OAuth tokens or Google passwords on our servers.
- Only the application owner has administrative access to the database.

Data Retention and Deletion:
- Your Google user data is retained only while your account is active.
- You may request deletion of your account and all associated Google user data at any time by contacting support@orignaventures.ca.
- Upon receiving a deletion request, we will permanently remove your Google user data from our systems within 30 days.
- You can also revoke OrignaGTA access to your Google account at any time via your Google Account permissions page (https://myaccount.google.com/permissions).

3. How We Use Your Information
We use your information to:
- Process and fulfill your orders, including shipping, payment, and delivery.
- Create and manage your account and authenticate your identity.
- Send important notifications: order updates, shipping confirmations, and security alerts.
- Improve our platform through analytics and usage patterns.
- Detect and prevent fraud, abuse, and unauthorized access.
- Comply with legal obligations and enforce our Terms of Service.
- Provide customer support and respond to your inquiries.

4. Data Sharing & Third Parties
We do not sell your personal data. We share information only with:
- Payment Processors: Stripe and Airwallex for secure payment processing.
- Cloud Services: Firebase (Google) for authentication, database, and hosting.
- Search Services: Algolia for product search functionality.
- Shipping Partners: Carrier services when fulfilling deliveries.
- Sellers: Order details necessary to fulfill your purchases (name, address).
- Legal Requirements: When required by law, court order, or to protect rights and safety.

5. Seller-Specific Data
If you are a seller on OrignaGTA, we additionally collect:
- Business registration information and tax IDs (GST/HST).
- Government-issued identification for verification purposes.
- Payout information (bank account or payment provider details).
- Sales data, commission records, and payout history.
This data is used for verification, payout processing, tax compliance, and fraud prevention.

6. Your Rights & Choices
You have the right to:
- Access your personal data stored by us.
- Correct inaccurate or incomplete information.
- Request deletion of your account and associated data (including all Google user data).
- Opt out of marketing communications at any time.
- Request a copy of your data in a portable format.
- Revoke OrignaGTA access to your Google account via https://myaccount.google.com/permissions.
To exercise any of these rights, contact us at support@orignaventures.ca.

7. Data Security
We implement industry-standard security measures:
- All data transmitted is encrypted using TLS/SSL.
- Payment data is handled by PCI-DSS compliant processors.
- Access to personal data is restricted to authorized personnel only.
- Regular security audits and monitoring for vulnerabilities.
- Firebase Security Rules protect database access at the field level.
- Google user data is stored in encrypted Google Cloud infrastructure.

8. Data Retention
- Account data is retained while your account is active.
- Order records are kept for 7 years for tax and legal compliance.
- Deleted accounts have personal data (including Google user data) removed within 30 days.
- Anonymized analytics data may be retained indefinitely.

9. Cookies & Tracking
We use essential cookies and local storage for:
- Maintaining your login session and authentication state.
- Remembering your preferences and cart contents.
- Analytics to improve platform performance (no third-party ad tracking).

10. Children's Privacy
OrignaGTA is not intended for children under 16. We do not knowingly collect personal information from minors. If you believe a child has provided us data, contact us for removal.

11. Changes to This Policy
We may update this Privacy Policy periodically. Material changes will be notified:
- Via email to your registered address.
- Through an in-app notification banner.
- Changes take effect 14 days after notification.

12. Contact Us
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
