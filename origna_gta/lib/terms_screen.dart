import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarFactory.simple(title: 'Terms & Conditions'),
      body: FutureBuilder<String>(
        future: _loadTermsContent(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final content = snapshot.data ?? _defaultTermsContent;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Terms and Conditions',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last updated: ${DateTime.now().year}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 24),
                Text(
                  content,
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<String> _loadTermsContent() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      final content = remoteConfig.getString('terms_and_conditions');
      if (content.isNotEmpty) {
        return content;
      }
    } catch (e) {
      debugPrint('Error loading terms from Remote Config: $e');
    }
    return _defaultTermsContent;
  }

  static const String _defaultTermsContent = '''
Welcome to OrignaGTA. By accessing or using our platform, you agree to be bound by these Terms and Conditions.

1. ACCEPTANCE OF TERMS

By creating an account, browsing, or making purchases on OrignaGTA, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions, as well as our Privacy Policy.

2. ACCOUNT REGISTRATION

To use certain features of our platform, you must register for an account. You agree to:
- Provide accurate and complete information
- Maintain the security of your account credentials
- Accept responsibility for all activities under your account
- Notify us immediately of any unauthorized use

3. PURCHASES AND PAYMENTS

When you make a purchase on OrignaGTA:
- All prices are in Canadian Dollars (CAD) unless otherwise stated
- Prices include applicable taxes as required by law
- Payment is processed securely through Stripe
- You agree to pay all charges at the prices in effect when incurred
- We reserve the right to refuse or cancel orders at our discretion

4. SHIPPING AND DELIVERY

- Shipping costs are calculated based on the delivery address and seller location
- Delivery times are estimates and not guaranteed
- Risk of loss passes to you upon delivery
- You are responsible for providing accurate shipping information

5. RETURNS AND REFUNDS

- Return policies are set by individual sellers
- Contact the seller directly for return requests
- Refunds will be processed to the original payment method
- Some items may not be eligible for return

6. SELLER RESPONSIBILITIES

If you sell products on OrignaGTA, you agree to:
- Provide accurate product descriptions and images
- Ship products within the specified timeframe
- Respond to buyer inquiries promptly
- Comply with all applicable laws and regulations
- Accept responsibility for the quality of your products

7. PROHIBITED ACTIVITIES

You may not:
- Violate any laws or regulations
- Infringe on intellectual property rights
- Post false or misleading information
- Engage in fraudulent activities
- Attempt to manipulate the platform

8. INTELLECTUAL PROPERTY

All content on OrignaGTA, including logos, designs, and text, is our property or licensed to us. You may not use, reproduce, or distribute this content without permission.

9. LIMITATION OF LIABILITY

OrignaGTA is provided "as is" without warranties. We are not liable for:
- Indirect, incidental, or consequential damages
- Loss of data or profits
- Actions of third-party sellers
- Service interruptions

10. PRIVACY

Your use of OrignaGTA is also governed by our Privacy Policy. By using our platform, you consent to the collection and use of your information as described therein.

11. CHANGES TO TERMS

We may modify these Terms at any time. Continued use of the platform after changes constitutes acceptance of the new Terms.

12. TERMINATION

We reserve the right to terminate or suspend your account for violations of these Terms or for any other reason at our sole discretion.

13. GOVERNING LAW

These Terms are governed by the laws of Ontario, Canada. Any disputes shall be resolved in the courts of Ontario.

14. CONTACT US

For questions about these Terms, please contact us at:
Email: support@orignagta.com

By using OrignaGTA, you acknowledge that you have read and understood these Terms and Conditions and agree to be bound by them.
''';
}
