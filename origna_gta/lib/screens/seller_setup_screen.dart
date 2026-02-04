import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/features/app/seller_account_status_viewmodel.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/screens/seller_registration_screen.dart';
import 'package:origna_gta/utils/design_tokens.dart';

/// Screen shown when seller returns from Stripe Connect onboarding
class SellerSetupCompleteScreen extends ConsumerStatefulWidget {
  const SellerSetupCompleteScreen({super.key});

  @override
  ConsumerState<SellerSetupCompleteScreen> createState() => _SellerSetupCompleteScreenState();
}

class _SellerSetupCompleteScreenState extends ConsumerState<SellerSetupCompleteScreen> {
  bool _isRefreshing = false;
  String? _statusMessage;
  DateTime? _lastCheckTime;
  static const _minCheckInterval = Duration(seconds: 10); // Rate limit: 10 seconds between checks

  Future<void> _checkStatusAgain() async {
    // Rate limiting - prevent spam clicking
    if (_lastCheckTime != null) {
      final elapsed = DateTime.now().difference(_lastCheckTime!);
      if (elapsed < _minCheckInterval) {
        final remaining = _minCheckInterval - elapsed;
        setState(() {
          _statusMessage = '⏳ Please wait ${remaining.inSeconds} seconds before checking again.';
        });
        return;
      }
    }
    
    _lastCheckTime = DateTime.now();
    
    setState(() {
      _isRefreshing = true;
      _statusMessage = null;
    });
    
    try {
      // Use refreshSellerStatusProvider to manually sync with Stripe backend
      // This is the ONLY place where we call the backend - user explicitly requested it
      final status = await ref.read(refreshSellerStatusProvider(null).future);
      
      // Also invalidate userProfileProvider so HomeScreen gets fresh data
      ref.invalidate(userProfileProvider);
      
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          if (status.isComplete) {
            // Account is fully verified - charges enabled
            _statusMessage = '✅ Verification complete! You can now add products.';
          } else {
            // Still waiting for Stripe verification
            _statusMessage = '⏳ Verification still in progress. Stripe is reviewing your documents.';
          }
        });
        
        // Clear message after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) setState(() => _statusMessage = null);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _statusMessage = '❌ Could not check status. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(sellerAccountStatusProvider);

    if (_isRefreshing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Checking status...')],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: statusAsync.when(
            loading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Verifying your seller account...')],
              ),
            ),
            error: (error, _) => _buildError(context, error.toString()),
            data: (status) {
              if (status.isComplete) {
                return _buildSuccess(context);
              } else if (status.isPendingVerification) {
                return _buildPendingVerification(context);
              } else {
                return _buildIncomplete(context, status);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 80, color: DesignTokens.error),
        const SizedBox(height: 24),
        Text(error, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _checkStatusAgain,
            style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.primary, foregroundColor: Colors.white),
            child: const Text('Retry'),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false), child: const Text('Go Home')),
      ],
    );
  }

  Future<void> _goToHome() async {
    // Show loading indicator
    setState(() => _isRefreshing = true);

    try {
      // Call backend to sync Stripe status with Firestore
      // This ensures chargesEnabled, payoutsEnabled, onboardingCompleted are updated
      await ref.read(refreshSellerStatusProvider(null).future);
    } catch (e) {
      // Ignore errors - we'll still navigate home
      debugPrint('Error syncing status before going home: $e');
    }

    // Refresh user profile to get updated seller status from Firestore
    ref.invalidate(userProfileProvider);

    if (mounted) {
      // Use pushNamedAndRemoveUntil to properly update browser URL on web
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  /// User has NOT completed all Stripe requirements yet
  Widget _buildIncomplete(BuildContext context, SellerAccountStatus status) {
    final hasDocumentRequirements = status.needsIdentityDocuments;
    final requirementsDescription = status.pendingRequirementsDescription;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(
            hasDocumentRequirements ? Icons.badge_outlined : Icons.assignment_outlined, 
            size: 100, 
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          hasDocumentRequirements 
              ? 'Identity Verification Required' 
              : 'Complete Your Setup',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          hasDocumentRequirements
              ? 'Stripe needs to verify your identity before you can start selling. Please submit the required documents.'
              : 'You need to finish providing your information to Stripe before you can start selling.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
        ),
        if (requirementsDescription.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Still needed:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• $requirementsDescription',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SellerRegistrationScreen()),
              );
            },
            icon: const Icon(Icons.arrow_forward),
            label: Text(
              hasDocumentRequirements ? 'Submit Documents' : 'Continue Setup',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange, 
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _goToHome,
          child: const Text('Go to Home'),
        ),
      ],
    );
  }

  /// User has submitted the form but Stripe is verifying identity
  Widget _buildPendingVerification(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.hourglass_empty, size: 100, color: Colors.orange),
        ),
        const SizedBox(height: 32),
        const Text(
          'Identity Verification Pending',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Stripe is reviewing your identity documents. This usually takes a few minutes but can take up to 2 business days.\n\nYou will be able to add products once your verification is complete.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _goToHome,
            style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.primary, foregroundColor: Colors.white),
            child: const Text('Go to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _checkStatusAgain,
          child: const Text('Check Verification Status'),
        ),
        if (_statusMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _statusMessage!.startsWith('✅') 
                  ? DesignTokens.success.withValues(alpha: 0.1)
                  : _statusMessage!.startsWith('❌')
                      ? DesignTokens.error.withValues(alpha: 0.1)
                      : DesignTokens.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _statusMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _statusMessage!.startsWith('✅')
                    ? DesignTokens.success
                    : _statusMessage!.startsWith('❌')
                        ? DesignTokens.error
                        : DesignTokens.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: DesignTokens.success.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(Icons.check_circle, size: 100, color: DesignTokens.success),
        ),
        const SizedBox(height: 32),
        const Text(
          'Seller Account Ready!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Your account is set up and you can now start selling products.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _goToHome,
            style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.primary, foregroundColor: Colors.white),
            child: const Text('Start Selling', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

/// Screen shown when seller needs to refresh/retry Stripe Connect onboarding
class SellerSetupRefreshScreen extends StatelessWidget {
  const SellerSetupRefreshScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: DesignTokens.info.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.refresh, size: 100, color: DesignTokens.info),
              ),
              const SizedBox(height: 32),
              const Text(
                'Continue Your Setup',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your seller account setup needs to be completed. Please continue to finish setting up your account.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SellerRegistrationScreen()));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.primary, foregroundColor: Colors.white),
                  child: const Text('Continue Setup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false), child: const Text('Back to Home')),
            ],
          ),
        ),
      ),
    );
  }
}
