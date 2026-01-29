import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/constants.dart';
import 'package:origna_gta/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class SellerRegistrationScreen extends StatefulWidget {
  const SellerRegistrationScreen({super.key});

  @override
  State<SellerRegistrationScreen> createState() => _SellerRegistrationScreenState();
}

class _SellerRegistrationScreenState extends State<SellerRegistrationScreen> with WidgetsBindingObserver {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh account status when app resumes (after returning from Stripe onboarding)
    if (state == AppLifecycleState.resumed) {
      _refreshAccountStatus();
    }
  }

  Future<void> _refreshAccountStatus() async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('get_connect_account_status');
      await callable.call();
      // The StreamBuilder will automatically update the UI
    } catch (e) {
      // Silently fail - the user will see the current cached status
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Become a Seller')),
        body: const Center(child: Text('Please log in to continue')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Seller', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection(Collections.users).doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User not found'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final userModel = UserModel.fromMap(userData);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: const Icon(Icons.store, size: 40, color: Color(0xFFFF6B35)),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Sell on OrignaGTA',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Reach customers across the GTA and grow your business',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Status Card
                    _buildStatusCard(userModel),

                    const SizedBox(height: 16),

                    // Benefits Card
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Why sell with us?',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            _buildBenefitItem(Icons.people, 'Access thousands of customers'),
                            _buildBenefitItem(Icons.credit_card, 'Secure payment processing'),
                            _buildBenefitItem(Icons.speed, 'Fast payouts via Stripe'),
                            _buildBenefitItem(Icons.analytics, 'Track your sales easily'),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Platform fee: ${(AppConfig.platformFeePercent * 100).toStringAsFixed(1)}% per sale',
                                      style: const TextStyle(color: Colors.blue, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Error Display
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),

                    // Action Button
                    _buildActionButton(userModel),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(UserModel user) {
    final hasAccount = user.stripeAccountId != null && user.stripeAccountId!.isNotEmpty;
    final isComplete = user.onboardingCompleted;
    final canReceivePayouts = user.payoutsEnabled;

    Color statusColor;
    String statusText;
    String statusDescription;
    IconData statusIcon;

    if (canReceivePayouts) {
      statusColor = Colors.green;
      statusText = 'Active Seller';
      statusDescription = 'Your account is ready to receive payouts';
      statusIcon = Icons.check_circle;
    } else if (isComplete) {
      statusColor = Colors.orange;
      statusText = 'Verification Pending';
      statusDescription = 'Stripe is reviewing your account';
      statusIcon = Icons.hourglass_empty;
    } else if (hasAccount) {
      statusColor = Colors.orange;
      statusText = 'Onboarding Incomplete';
      statusDescription = 'Complete your Stripe setup to start selling';
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.grey;
      statusText = 'Not Registered';
      statusDescription = 'Start the registration process to become a seller';
      statusIcon = Icons.person_add;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(statusIcon, color: statusColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusDescription,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (hasAccount) ...[
              const Divider(height: 32),
              _buildStatusRow('Stripe Account', hasAccount),
              _buildStatusRow('Onboarding Complete', isComplete),
              _buildStatusRow('Can Receive Payouts', canReceivePayouts),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: isActive ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: isActive ? Colors.black : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF6B35), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildActionButton(UserModel user) {
    final hasAccount = user.stripeAccountId != null && user.stripeAccountId!.isNotEmpty;
    final canReceivePayouts = user.payoutsEnabled;

    String buttonText;
    VoidCallback onPressed;

    if (canReceivePayouts) {
      buttonText = 'Manage Stripe Account';
      onPressed = () => _openStripeDashboard();
    } else if (hasAccount) {
      buttonText = 'Complete Stripe Setup';
      onPressed = () => _continueOnboarding();
    } else {
      buttonText = 'Start Seller Registration';
      onPressed = () => _startRegistration();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B35),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _startRegistration() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Create Stripe Connect account
      final createAccount = FirebaseFunctions.instance.httpsCallable('create_connect_account');
      final result = await createAccount.call();

      final data = result.data as Map<String, dynamic>;

      if (data['alreadyExists'] == true) {
        // Account already exists, continue to onboarding
        await _continueOnboarding();
      } else {
        // New account created, get onboarding link
        await _continueOnboarding();
      }
    } on FirebaseFunctionsException catch (e) {
      setState(() {
        _error = e.message ?? 'Failed to create seller account';
      });
    } catch (e) {
      setState(() {
        _error = 'An unexpected error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _continueOnboarding() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get onboarding link
      final createLink = FirebaseFunctions.instance.httpsCallable('create_account_link');
      final result = await createLink.call({
        'refreshUrl': 'https://orignagta.ca/seller/refresh',
        'returnUrl': 'https://orignagta.ca/seller/return',
      });

      final data = result.data as Map<String, dynamic>;
      final url = data['url'] as String?;

      if (url != null) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          setState(() {
            _error = 'Could not open onboarding link';
          });
        }
      }
    } on FirebaseFunctionsException catch (e) {
      setState(() {
        _error = e.message ?? 'Failed to get onboarding link';
      });
    } catch (e) {
      setState(() {
        _error = 'An unexpected error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openStripeDashboard() async {
    final uri = Uri.parse('https://dashboard.stripe.com/express');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
