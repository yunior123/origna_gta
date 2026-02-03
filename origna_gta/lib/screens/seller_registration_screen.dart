// seller_registration_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart'; // For UserModel
import 'package:origna_gta/widgets/custom_app_bar.dart'; // Assuming this exists based on your code
import 'package:origna_gta/widgets/modern_button.dart';

import '../features/seller/seller_registration_state.dart';
import '../features/seller/seller_registration_view_model.dart';

/// Available payment providers - add new providers here
const List<PaymentProviderConfig> availablePaymentProviders = [
  PaymentProviderConfig(
    id: 'stripe',
    name: 'Stripe',
    icon: Icons.flash_on,
    primaryColor: Color(0xFF635BFF),
    secondaryColor: Color(0xFF00D4AA),
    payoutTiming: '7 days after delivery confirmation',
    features: ['Automatic payouts after 7-day hold period', 'Best for Canada-based sellers', 'Stripe Express instant setup', '2.9% + \$0.30 per transaction'],
    recommendedFor: 'Recommended for local Canadian sellers.',
  ),
  PaymentProviderConfig(
    id: 'airwallex',
    name: 'Airwallex',
    icon: Icons.public,
    primaryColor: Color(0xFF0066FF),
    secondaryColor: Color(0xFF00CCFF),
    payoutTiming: 'Every Friday (weekly batch)',
    features: [
      'Weekly batch payouts every Friday at 4 PM EST',
      'Best for international sellers (China, Korea, etc.)',
      'Multi-currency support (CAD, USD, CNY, EUR)',
      'Lower fees for high volume',
      '7-14 days total processing time',
    ],
    recommendedFor: 'Ideal for dropshipping & international suppliers.',
  ),
  PaymentProviderConfig(
    id: 'paypal',
    name: 'PayPal',
    icon: Icons.account_balance_wallet,
    primaryColor: Color(0xFF003087),
    secondaryColor: Color(0xFF009CDE),
    payoutTiming: '3-5 days after delivery',
    features: ['Instant PayPal balance transfers', 'Buyer/Seller protection included', 'Wide international acceptance', '2.9% + \$0.30 per transaction'],
    recommendedFor: 'Great for sellers with existing PayPal business accounts.',
    comingSoon: true,
  ),
  PaymentProviderConfig(
    id: 'wise',
    name: 'Wise (TransferWise)',
    icon: Icons.swap_horiz,
    primaryColor: Color(0xFF9FE870),
    secondaryColor: Color(0xFF00B9FF),
    payoutTiming: '1-3 days international transfer',
    features: ['Low-cost international transfers', 'Real mid-market exchange rates', 'Multi-currency accounts', '0.35% - 1% transfer fees'],
    recommendedFor: 'Perfect for international sellers needing fast, cheap transfers.',
    comingSoon: true,
  ),
];

/// Payment provider configuration for seller registration
class PaymentProviderConfig {
  final String id;
  final String name;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final String payoutTiming;
  final List<String> features;
  final String recommendedFor;
  final bool comingSoon;

  const PaymentProviderConfig({
    required this.id,
    required this.name,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.payoutTiming,
    required this.features,
    required this.recommendedFor,
    this.comingSoon = false,
  });
}

// ============================================================================
// PAYMENT PROVIDER CONFIGURATION - Extensible for future providers
// ============================================================================

class SellerRegistrationScreen extends ConsumerStatefulWidget {
  const SellerRegistrationScreen({super.key});

  @override
  ConsumerState<SellerRegistrationScreen> createState() => _SellerRegistrationScreenState();
}

class _SellerRegistrationScreenState extends ConsumerState<SellerRegistrationScreen> with WidgetsBindingObserver {
  bool _termsAccepted = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Watch User Data
    final userProfileAsync = ref.watch(userProfileProvider);
    // Watch ViewModel State (Loading/Error)
    final viewState = ref.watch(sellerRegistrationViewModelProvider);
    final viewModel = ref.read(sellerRegistrationViewModelProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [isDark ? Colors.grey[900]! : Colors.grey[50]!, isDark ? Colors.grey[800]! : Colors.white],
        ),
      ),
      child: Scaffold(
        appBar: AppBarFactory.simple(title: 'Become a Seller'),
        backgroundColor: Colors.transparent,
        body: userProfileAsync.when(
          loading: () => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(colors: [DesignTokens.primary, DesignTokens.secondary]).createShader(bounds),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.8))),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading...',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(padding: const EdgeInsets.all(24), child: Text('Error loading profile: $error')),
          ),
          data: (userModel) {
            if (userModel == null) {
              return const Center(child: Text('Please log in to continue'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Header Card ---
                      _buildHeaderCard(),

                      const SizedBox(height: 20),

                      _buildProviderSelector(userModel, viewState, viewModel),

                      const SizedBox(height: 20),

                      // --- Status Card (commented out - function needs refactoring) ---
                      // _buildStatusCard(userModel),
                      const SizedBox(height: 20),

                      // --- Benefits Card ---
                      _buildBenefitsCard(),

                      const SizedBox(height: 20),

                      // --- Error Display ---
                      if (viewState.error != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.red[300]!.withValues(alpha: 0.2), Colors.red[400]!.withValues(alpha: 0.1)]),
                            borderRadius: BorderRadius.circular(DesignTokens.radius12),
                            border: Border.all(color: Colors.red[400]!.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[400], size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  viewState.error!,
                                  style: TextStyle(color: Colors.red[600], fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // --- Terms and Conditions ---
                      CheckboxListTile(
                        value: _termsAccepted,
                        onChanged: (value) => setState(() => _termsAccepted = value ?? false),
                        title: const Text('I accept the Terms and Conditions'),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: DesignTokens.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 12),

                      // --- Action Button ---
                      _buildActionButton(userModel, viewState.isLoading, viewState.paymentProvider, viewModel),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user returns from the browser (Stripe onboarding), refresh their status
    if (state == AppLifecycleState.resumed) {
      ref.read(sellerRegistrationViewModelProvider.notifier).refreshAccountStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  Widget _buildActionButton(UserModel user, bool isLoading, String paymentProvider, SellerRegistrationViewModel viewModel) {
    if (paymentProvider == 'airwallex') {
      final hasAirwallex = user.airwallexAccountId != null && user.airwallexAccountId!.isNotEmpty;
      return ModernButton(
        onPressed: isLoading
            ? null
            : () {
                if (!_termsAccepted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please accept the Terms and Conditions to continue')));
                  return;
                }
                viewModel.startRegistration();
              },
        label: hasAirwallex ? 'Airwallex Connected' : 'Connect Airwallex',
        isLoading: isLoading,
        icon: Icons.public,
      );
    }

    final hasAccount = user.stripeAccountId != null && user.stripeAccountId!.isNotEmpty;
    final canReceivePayouts = user.payoutsEnabled;

    String buttonText;
    VoidCallback onPressed;

    if (canReceivePayouts) {
      buttonText = 'Manage Stripe Account';
      onPressed = viewModel.openStripeDashboard;
    } else if (hasAccount) {
      buttonText = 'Complete Stripe Setup';
      onPressed = viewModel.continueOnboarding;
    } else {
      buttonText = 'Start Seller Registration';
      onPressed = viewModel.startRegistration;
    }

    // Wrap onPressed with usage check
    Null finalOnPressed() {
      if (!_termsAccepted && !canReceivePayouts && !hasAccount) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please accept the Terms and Conditions to continue')));
        return;
      }
      onPressed();
    }

    return ModernButton(
      onPressed: isLoading ? null : finalOnPressed,
      label: buttonText,
      isLoading: isLoading,
      icon: canReceivePayouts
          ? Icons.dashboard
          : hasAccount
          ? Icons.check_circle
          : Icons.store,
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [DesignTokens.primary.withValues(alpha: 0.2), DesignTokens.secondary.withValues(alpha: 0.1)]),
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
          ),
          child: Icon(icon, color: DesignTokens.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4)),
        ),
      ],
    );
  }

  Widget _buildBenefitsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? Colors.grey[800]!.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.8),
            isDark ? Colors.grey[900]!.withValues(alpha: 0.4) : Colors.grey[50]!.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.2), width: 1),
        boxShadow: [BoxShadow(color: DesignTokens.primary.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(colors: [DesignTokens.primary, DesignTokens.secondary]).createShader(bounds),
            child: const Text(
              'Why sell with us?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          _buildBenefitItem(Icons.people, 'Access thousands of customers'),
          const SizedBox(height: 12),
          _buildBenefitItem(Icons.credit_card, 'Secure payment processing'),
          const SizedBox(height: 12),
          _buildBenefitItem(Icons.speed, 'Fast payouts via Stripe'),
          const SizedBox(height: 12),
          _buildBenefitItem(Icons.analytics, 'Track your sales easily'),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [DesignTokens.primary.withValues(alpha: 0.95), DesignTokens.secondary.withValues(alpha: 0.95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius20),
        boxShadow: [BoxShadow(color: DesignTokens.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(Icons.store, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sell on OrignaGTA',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Reach customers across the GTA and grow your business',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderInfoCard(PaymentProviderConfig config) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [config.primaryColor.withValues(alpha: 0.1), config.secondaryColor.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: config.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(config.icon, size: 18, color: config.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Payout: ${config.payoutTiming}',
                style: TextStyle(fontWeight: FontWeight.w600, color: config.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(config.features.map((f) => '• $f').join('\n'), style: TextStyle(color: Colors.grey[700], fontSize: 12, height: 1.5)),
          if (config.comingSoon) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Coming Soon - Join waitlist',
                    style: TextStyle(fontSize: 11, color: Colors.orange.shade700, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderSelector(UserModel user, SellerRegistrationState state, SellerRegistrationViewModel viewModel) {
    final provider = user.paymentProvider.isNotEmpty ? user.paymentProvider : state.paymentProvider;
    final selectedConfig = availablePaymentProviders.firstWhere((p) => p.id == provider, orElse: () => availablePaymentProviders.first);

    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Provider',
            style: TextStyle(fontWeight: FontWeight.w700, color: DesignTokens.primary),
          ),
          const SizedBox(height: 12),
          // Dynamic provider chips from configuration
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availablePaymentProviders.map((config) {
              final isSelected = provider == config.id;
              return Stack(
                children: [
                  ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(config.icon, size: 16, color: isSelected ? Colors.white : config.primaryColor),
                        const SizedBox(width: 6),
                        Text(config.name),
                        if (config.comingSoon) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              'Soon',
                              style: TextStyle(fontSize: 9, color: Colors.orange.shade800, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                    selected: isSelected,
                    onSelected: config.comingSoon
                        ? null
                        : (selected) {
                            if (selected) viewModel.setPaymentProvider(config.id);
                          },
                    selectedColor: config.primaryColor,
                    backgroundColor: config.comingSoon ? Colors.grey.shade200 : null,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : (config.comingSoon ? Colors.grey : null)),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Dynamic payment timing info card based on selected provider
          _buildProviderInfoCard(selectedConfig),
          const SizedBox(height: 8),
          Text(selectedConfig.recommendedFor, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  // Status row builder - reserved for future use if needed
}
