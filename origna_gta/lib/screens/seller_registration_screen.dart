import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart'; // For UserModel
import 'package:origna_gta/widgets/custom_app_bar.dart'; // Assuming this exists based on your code
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

import 'package:origna_gta/features/seller/seller_account_status_viewmodel.dart';
import 'package:origna_gta/features/seller/seller_registration_view_model.dart';

part 'parts/seller_registration_header_section.dart';
part 'parts/seller_registration_provider_section.dart';
part 'parts/seller_registration_action_section.dart';

/// Available payment providers - add new providers here.
const List<PaymentProviderConfig> availablePaymentProviders = [
  PaymentProviderConfig(
    id: PaymentProviderValues.stripe,
    name: 'Stripe',
    icon: Icons.flash_on,
    primaryColor: DesignTokens.stripeViolet,
    secondaryColor: DesignTokens.stripeCyan,
    payoutTiming: '7 days after delivery confirmation',
    features: [
      'Automatic payouts after 7-day hold period',
      'Best for Canada-based sellers',
      'Stripe Express instant setup',
      '2.9% + \$0.30 per transaction',
    ],
    recommendedFor: 'Recommended for local Canadian sellers.',
  ),
  PaymentProviderConfig(
    id: 'paypal', // Not in PaymentProviderValues — future provider
    name: 'PayPal',
    icon: Icons.account_balance_wallet,
    primaryColor: DesignTokens.paypalNavy,
    secondaryColor: DesignTokens.paypalBlue,
    payoutTiming: '3-5 days after delivery',
    features: [
      'Instant PayPal balance transfers',
      'Buyer/Seller protection included',
      'Wide international acceptance',
      '2.9% + \$0.30 per transaction',
    ],
    recommendedFor: 'Great for sellers with existing PayPal business accounts.',
    comingSoon: true,
  ),
  PaymentProviderConfig(
    id: 'wise', // Not in PaymentProviderValues — future provider
    name: 'Wise (TransferWise)',
    icon: Icons.swap_horiz,
    primaryColor: DesignTokens.wiseGreen,
    secondaryColor: DesignTokens.wiseSky,
    payoutTiming: '1-3 days international transfer',
    features: [
      'Low-cost international transfers',
      'Real mid-market exchange rates',
      'Multi-currency accounts',
      '0.35% - 1% transfer fees',
    ],
    recommendedFor:
        'Perfect for international sellers needing fast, cheap transfers.',
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

/// Stripe Connect onboarding: creates account link and redirects to Stripe.
class SellerRegistrationScreen extends ConsumerStatefulWidget {
  const SellerRegistrationScreen({super.key});

  @override
  ConsumerState<SellerRegistrationScreen> createState() =>
      _SellerRegistrationScreenState();
}

/// Private provider for seller registration terms acceptance
final _sellerTermsAcceptedProvider = StateProvider.autoDispose<bool>(
  (_) => false,
);

class _SellerRegistrationScreenState
    extends ConsumerState<SellerRegistrationScreen>
    with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    final termsAccepted = ref.watch(_sellerTermsAcceptedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Watch User Data
    final userProfileAsync = ref.watch(userProfileProvider);
    // Watch ViewModel State (Loading/Error)
    final viewState = ref.watch(sellerRegistrationViewModelProvider);
    final viewModel = ref.read(sellerRegistrationViewModelProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        gradient: DesignTokens.backgroundGradient(isDark: isDark),
      ),
      child: Scaffold(
        appBar: AppBarFactory.simple(title: 'seller.become_seller'.tr()),
        backgroundColor: DesignTokens.transparent,
        body: userProfileAsync.when(
          loading: () => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [DesignTokens.primary, DesignTokens.secondary],
                  ).createShader(bounds),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: ModernLoadingIndicator(
                      size: 50,
                      strokeWidth: 3,
                      color: DesignTokens.white.withValues(alpha: 0.8),
                      centered: false,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'seller.loading'.tr(),
                  style: TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'seller.error_loading_profile'.tr(
                  namedArgs: {'error': error.toString()},
                ),
              ),
            ),
          ),
          data: (userModel) {
            if (userModel == null) {
              return Center(child: Text('seller.please_login'.tr()));
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
                      const _HeaderCard(),

                      const SizedBox(height: 20),

                      _ProviderSelector(
                        user: userModel,
                        state: viewState,
                        viewModel: viewModel,
                      ),

                      const SizedBox(height: 20),

                      // --- Status Card (commented out - function needs refactoring) ---
                      // _buildStatusCard(userModel),
                      const SizedBox(height: 20),

                      // --- Benefits Card ---
                      const _BenefitsCard(),

                      const SizedBox(height: 20),

                      // --- Error Display ---
                      if (viewState.error != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                DesignTokens.error.withValues(alpha: 0.2),
                                DesignTokens.error.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radius12,
                            ),
                            border: Border.all(
                              color: DesignTokens.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: DesignTokens.error,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  viewState.error!,
                                  style: TextStyle(
                                    color: DesignTokens.error,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // --- Terms and Conditions ---
                      Semantics(
                        label: 'chk-seller-terms',
                        checked: termsAccepted,
                        child: CheckboxListTile(
                          key: const Key('seller_terms_checkbox'),
                          value: termsAccepted,
                          onChanged: (value) =>
                              ref
                                      .read(
                                        _sellerTermsAcceptedProvider.notifier,
                                      )
                                      .state =
                                  value ?? false,
                          title: Text('seller.accept_terms'.tr()),
                          subtitle: !termsAccepted
                              ? Text(
                                  'seller.accept_terms_required'.tr(),
                                  style: TextStyle(
                                    color: DesignTokens.warning,
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                          controlAffinity: ListTileControlAffinity.leading,
                          fillColor: WidgetStateProperty.resolveWith<Color?>((
                            states,
                          ) {
                            if (states.contains(WidgetState.selected)) {
                              return DesignTokens.primary;
                            }
                            return null;
                          }),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // --- Verification Status Card ---
                      _VerificationStatusCard(user: userModel),

                      // --- Action Button ---
                      _ActionButton(
                        user: userModel,
                        viewState: viewState,
                        viewModel: viewModel,
                      ),
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
      ref
          .read(sellerRegistrationViewModelProvider.notifier)
          .refreshAccountStatus();
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

  // Status row builder - reserved for future use if needed
}
