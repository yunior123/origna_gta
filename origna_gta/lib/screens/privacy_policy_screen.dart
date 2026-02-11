import 'package:easy_localization/easy_localization.dart';
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
- Payment Information: Payment card details and billing addresses, processed securely by our payment partners (Stripe, Airwallex). We do not store full card numbers on our servers.
- Order Information: Purchase history, items ordered, amounts paid, and delivery details.
- Usage Data: Pages visited, search queries, features used, device type, browser, and IP address.
- Communications: Messages between buyers and sellers, and customer support requests.

2. Google User Data — Data Accessed
Origna GTA uses Google Firebase Authentication to allow you to sign in with your Google account. When you choose to sign in with Google, we access the following limited Google user data:
- Your Google account email address — to create your account and send notifications.
- Your Google display name — to personalize your profile within the app.
- Your Google profile photo URL — to display your avatar in the app.
- Your Google unique account identifier (UID) — to authenticate your identity.
We do NOT access your Google contacts, Google Drive files, Gmail messages, calendar, or any other Google service data beyond the authentication scopes listed above.

3. Google User Data — Data Usage
We use your Google user data exclusively for the following purposes:
- Account Creation & Authentication: To create and authenticate your Origna GTA account securely.
- Profile Display: To display your name and profile photo within the marketplace application.
- Transactional Communications: To send order confirmations, shipping updates, and security alerts to your email address.
We do NOT use your Google user data for advertising, marketing to third parties, training AI models, profiling, behavioral targeting, or any purpose unrelated to providing and improving Origna GTA marketplace services.

4. Google User Data — Data Sharing
We treat your Google user data with the highest level of care:
- We do NOT sell, rent, or trade your Google user data to any third party.
- Payment Processors: Your Google email may be shared with Stripe or Airwallex solely for payment processing and receipts.
- Order Fulfillment: Your display name and delivery address may be shared with sellers only to fulfill your orders.
- Legal Requirements: We may disclose data if required by Canadian law, court order, or to protect the rights and safety of our users.
No other third parties receive your Google user data. We comply with the Google API Services User Data Policy, including the Limited Use requirements.

5. Google User Data — Data Storage & Protection
We implement robust security measures to protect your Google user data:
- Encrypted Storage: Google user data is stored in Google Cloud Firestore, encrypted at rest (AES-256) and in transit (TLS 1.2+).
- Access Controls: Access to user data is restricted by Firebase Security Rules, ensuring only authorized operations are permitted.
- Encrypted Communication: All communication between the app and our servers is encrypted using TLS/SSL.
- No Token Storage: We do not store Google OAuth tokens or Google passwords on our servers.
- Administrative Access: Only the application owner has administrative access to the database. No employee or contractor has bulk access to user data.
- Regular Audits: We perform regular security audits and monitoring for vulnerabilities.

6. Google User Data — Data Retention & Deletion
We retain your Google user data only as long as necessary to provide our services:
- Active Accounts: Your Google user data is retained only while your account is active on Origna GTA.
- Account Deletion: You may request deletion of your account and all associated Google user data at any time by emailing support@orignaventures.ca.
- Deletion Timeline: Upon receiving a deletion request, we will permanently remove your Google user data from our systems within 30 days.
- Revoke Access: You can also revoke Origna GTA's access to your Google account at any time via your Google Account permissions page (https://myaccount.google.com/permissions).

7. How We Use Your Information
Beyond Google user data, we use the information we collect to:
- Process and fulfill your orders, including shipping, payment, and delivery.
- Create and manage your account and authenticate your identity.
- Send important notifications: order updates, shipping confirmations, and security alerts.
- Improve our platform through analytics and usage patterns.
- Detect and prevent fraud, abuse, and unauthorized access.
- Comply with legal obligations and enforce our Terms of Service.
- Provide customer support and respond to your inquiries.

8. Data Sharing & Third Parties
We do not sell your personal data. We share information only with:
- Payment Processors: Stripe and Airwallex for secure payment processing.
- Cloud Services: Firebase (Google) for authentication, database, and hosting.
- Search Services: Algolia for product search functionality.
- Shipping Partners: Carrier services when fulfilling deliveries.
- Sellers: Order details necessary to fulfill your purchases (name, delivery address).
- Legal Requirements: When required by Canadian law, court order, or to protect rights and safety.

9. Seller-Specific Data
If you are a seller on Origna GTA, we additionally collect:
- Business registration information and tax IDs (GST/HST).
- Government-issued identification for verification purposes.
- Payout information (bank account or payment provider details).
- Sales data, commission records, and payout history.
This data is used exclusively for identity verification, payout processing, tax compliance, and fraud prevention.

10. Your Rights & Choices
You have the right to:
- Access your personal data stored by us.
- Correct inaccurate or incomplete information.
- Delete your account and all associated data (including all Google user data).
- Opt out of marketing communications at any time.
- Data portability — request a copy of your data in a portable format.
- Revoke access — remove Origna GTA's access to your Google account via https://myaccount.google.com/permissions.
To exercise any of these rights, contact us at support@orignaventures.ca.

11. Data Security
We implement industry-standard security measures to protect all user data:
- All data transmitted is encrypted using TLS/SSL (TLS 1.2+).
- Payment data is handled by PCI-DSS compliant processors (Stripe, Airwallex).
- Access to personal data is restricted to authorized personnel only.
- Regular security audits and vulnerability monitoring.
- Firebase Security Rules protect database access at the field level.
- Google user data is stored in encrypted Google Cloud infrastructure (AES-256 at rest).

12. Data Retention
- Account data is retained while your account is active.
- Order records are kept for 7 years for tax and legal compliance (Canadian tax law).
- Deleted accounts have personal data (including Google user data) permanently removed within 30 days.
- Anonymized analytics data may be retained indefinitely for platform improvement.

13. Cookies & Tracking
We use essential cookies and local storage for:
- Maintaining your login session and authentication state.
- Remembering your preferences and cart contents.
- Analytics to improve platform performance.
We do NOT use third-party advertising cookies or tracking pixels.

14. Children's Privacy
Origna GTA is not intended for children under 16 years of age. We do not knowingly collect personal information from minors. If you believe a child has provided us with personal data, please contact us immediately at support@orignaventures.ca and we will delete the information promptly.

15. Changes to This Policy
We may update this Privacy Policy periodically. Material changes will be communicated through:
- Email notification to your registered address.
- An in-app notification banner.
Changes take effect 14 days after notification. Continued use of the platform after that period constitutes acceptance of the updated policy.

16. Contact Us
For privacy-related questions, data requests, or concerns:
- Email: support@orignaventures.ca
- Website: orignaventures.ca
- Response time: Within 24 business hours (Mon-Fri, 9 AM - 6 PM EST).

17. Privacy Officer (Quebec Law 25 Compliance)
As required by Quebec's Law 25 (Act respecting the protection of personal information in the private sector), Origna Ventures Inc. has designated a Privacy Officer responsible for ensuring compliance with all applicable Canadian privacy legislation:
- Privacy Officer: Yunior Rodriguez Osorio
- Email: support@orignaventures.ca
- Mailing Address: Origna Ventures Inc., 200 University Ave W, Suite 300, Waterloo, ON N2L 3G1, Canada
The Privacy Officer is responsible for:
- Overseeing compliance with PIPEDA, Quebec Law 25, and all provincial privacy legislation.
- Conducting Privacy Impact Assessments (PIAs) for new features and data processing activities.
- Responding to data access, correction, and deletion requests within 30 days.
- Managing data breach notifications and reporting to the Office of the Privacy Commissioner of Canada.
- Maintaining a register of personal information incidents (as required by Law 25 since September 2023).

18. Cross-Border Data Transfers
Origna GTA uses cloud services that may process or store data outside of Canada:
- Firebase (Google Cloud): Data is stored in Google Cloud's northamerica-northeast1 (Montreal) region where available. Some processing may occur in other Google data centers globally.
- Stripe: Payment data is processed by Stripe, Inc. (USA) under their PIPEDA-compliant data processing agreement.
- Algolia: Search indexing may occur on servers located in the United States and Europe.
- Cloudflare R2: Image storage may be distributed across Cloudflare's global network.
- Mailjet: Email delivery is processed by Mailjet SAS (France/EU).
By using Origna GTA, you consent to the transfer of your personal information to these third-party processors. All transfers are governed by contractual data protection agreements that provide a level of protection equivalent to Canadian privacy law. You may withdraw this consent at any time by contacting support@orignaventures.ca, though this may limit your ability to use certain platform features.

19. Data Breach Response Plan (PIPEDA Compliance)
In accordance with PIPEDA's mandatory data breach notification requirements (in effect since November 1, 2018), Origna Ventures Inc. maintains a Data Breach Response Plan:
- Detection & Containment: We monitor for security incidents 24/7 via Sentry and Firebase security alerts. Upon detection, the breach is immediately contained and assessed.
- Risk Assessment: Within 24 hours of detection, we assess whether the breach creates a "real risk of significant harm" (RROSH) to any individual, considering sensitivity of data, probability of misuse, and potential impact.
- Notification to Commissioner: If RROSH is determined, we notify the Office of the Privacy Commissioner of Canada (OPC) as soon as feasible, including: description of the breach, affected data types, estimated number of individuals, steps taken, and contact information.
- Notification to Affected Individuals: If RROSH is determined, we notify affected individuals as soon as feasible via email and in-app notification, including: description of the breach, data types involved, steps we are taking, steps the individual can take, and our Privacy Officer's contact information.
- Record Keeping: We maintain a record of every breach of security safeguards (regardless of whether RROSH exists) for a minimum of 24 months, as required by PIPEDA.
- Quebec Law 25: For Quebec residents, we additionally report to the Commission d'accès à l'information du Québec (CAI) and maintain an incident register accessible upon request.

20. Consent Tracking
We maintain detailed records of consent as required by CASL and Quebec Law 25:
- The date and time consent was given.
- The method by which consent was obtained (e.g., account signup, checkbox, double opt-in).
- The version of the privacy policy and terms of service that was accepted.
- Your marketing communication preferences and any changes to them.
You may withdraw consent at any time by updating your notification preferences in your account settings or contacting support@orignaventures.ca.

Origna GTA's use and transfer of information received from Google APIs adheres to the Google API Services User Data Policy, including the Limited Use requirements.
''';

// ============================================================================
// PRIVACY POLICY SCREEN
// ============================================================================

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LegalScreenBody(
        rawContent: _privacyPolicyContent,
        heroTitle: 'legal.privacy_policy_hero'.tr(),
        heroBadge: 'legal.your_privacy_matters'.tr(),
        heroBadgeIcon: Icons.lock_outlined,
      ),
    );
  }
}
