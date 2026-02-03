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

  Widget _buildProviderSelector(UserModel user, SellerRegistrationState state, SellerRegistrationViewModel viewModel) {
    final provider = user.paymentProvider.isNotEmpty ? user.paymentProvider : state.paymentProvider;
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Provider',
            style: TextStyle(fontWeight: FontWeight.w700, color: DesignTokens.primary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Stripe'),
                selected: provider == 'stripe',
                onSelected: (selected) {
                  if (selected) viewModel.setPaymentProvider('stripe');
                },
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('Airwallex'),
                selected: provider == 'airwallex',
                onSelected: (selected) {
                  if (selected) viewModel.setPaymentProvider('airwallex');
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            provider == 'airwallex' ? 'Best for international sellers and multi-currency payouts.' : 'Best for Canada-based sellers with Stripe Express.',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Status row builder - reserved for future use if needed
}

// import 'package:cloud_functions/cloud_functions.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:origna_gta/constants.dart';
// import 'package:origna_gta/core/providers.dart';
// import 'package:origna_gta/features/auth/auth_provider.dart';
// import 'package:origna_gta/utils.dart';
// import 'package:origna_gta/widgets/custom_app_bar.dart';
// import 'package:url_launcher/url_launcher.dart';

// class SellerRegistrationScreen extends ConsumerStatefulWidget {
//   const SellerRegistrationScreen({super.key});

//   @override
//   ConsumerState<SellerRegistrationScreen> createState() => _SellerRegistrationScreenState();
// }

// class _SellerRegistrationScreenState extends ConsumerState<SellerRegistrationScreen> with WidgetsBindingObserver {
//   bool _isLoading = false;
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       _refreshAccountStatus();
//     }
//   }

//   Future<void> _refreshAccountStatus() async {
//     try {
//       final repository = ref.read(userRepositoryProvider);
//       // Wait, userRepository doesn't have refreshAccountStatus.
//       // Let's call the function directly via repository if I add it.
//       // For now, I'll keep the direct call but use providers.
//       final functions = ref.read(firebaseFunctionsProvider);
//       final callable = functions.httpsCallable('get_connect_account_status');
//       await callable.call();
//     } catch (e) {
//       // Silently fail
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final userProfileAsync = ref.watch(userProfileProvider);

//     return Scaffold(
//       appBar: AppBarFactory.simple(title: 'Become a Seller'),
//       backgroundColor: const Color(0xFFF5F5F5),
//       body: userProfileAsync.when(
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (error, stack) => Center(child: Text('Error: $error')),
//         data: (userModel) {
//           if (userModel == null) {
//             return const Center(child: Text('Please log in to continue'));
//           }

//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Center(
//               child: ConstrainedBox(
//                 constraints: const BoxConstraints(maxWidth: 600),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     Card(
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                       child: Padding(
//                         padding: const EdgeInsets.all(24),
//                         child: Column(
//                           children: [
//                             Container(
//                               width: 80,
//                               height: 80,
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFF667EEA).withValues(alpha: 0.1),
//                                 borderRadius: BorderRadius.circular(40),
//                               ),
//                               child: const Icon(Icons.store, size: 40, color: Color(0xFF667EEA)),
//                             ),
//                             const SizedBox(height: 16),
//                             const Text(
//                               'Sell on OrignaGTA',
//                               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                             ),
//                             const SizedBox(height: 8),
//                             Text(
//                               'Reach customers across the GTA and grow your business',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(color: Colors.grey[600]),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     _buildStatusCard(userModel),
//                     const SizedBox(height: 16),
//                     Card(
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                       child: Padding(
//                         padding: const EdgeInsets.all(20),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Why sell with us?',
//                               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                             ),
//                             const SizedBox(height: 16),
//                             _buildBenefitItem(Icons.people, 'Access thousands of customers'),
//                             _buildBenefitItem(Icons.credit_card, 'Secure payment processing'),
//                             _buildBenefitItem(Icons.speed, 'Fast payouts via Stripe'),
//                             _buildBenefitItem(Icons.analytics, 'Track your sales easily'),
//                             const SizedBox(height: 12),
//                             Container(
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 color: Colors.blue.withValues(alpha: 0.1),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Row(
//                                 children: [
//                                   const Icon(Icons.info_outline, color: Colors.blue, size: 20),
//                                   const SizedBox(width: 8),
//                                   Expanded(
//                                     child: Text(
//                                       'Platform fee: ${(AppConfig.platformFeePercent * 100).toStringAsFixed(1)}% per sale',
//                                       style: const TextStyle(color: Colors.blue, fontSize: 13),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     if (_error != null)
//                       Container(
//                         padding: const EdgeInsets.all(12),
//                         margin: const EdgeInsets.only(bottom: 16),
//                         decoration: BoxDecoration(
//                           color: Colors.red.withValues(alpha: 0.1),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Row(
//                           children: [
//                             const Icon(Icons.error_outline, color: Colors.red),
//                             const SizedBox(width: 8),
//                             Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
//                           ],
//                         ),
//                       ),
//                     _buildActionButton(userModel),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildStatusCard(UserModel user) {
//     final hasAccount = user.stripeAccountId != null && user.stripeAccountId!.isNotEmpty;
//     final isComplete = user.onboardingCompleted;
//     final canReceivePayouts = user.payoutsEnabled;

//     Color statusColor;
//     String statusText;
//     String statusDescription;
//     IconData statusIcon;

//     if (canReceivePayouts) {
//       statusColor = Colors.green;
//       statusText = 'Active Seller';
//       statusDescription = 'Your account is ready to receive payouts';
//       statusIcon = Icons.check_circle;
//     } else if (isComplete) {
//       statusColor = Colors.orange;
//       statusText = 'Verification Pending';
//       statusDescription = 'Stripe is reviewing your account';
//       statusIcon = Icons.hourglass_empty;
//     } else if (hasAccount) {
//       statusColor = Colors.orange;
//       statusText = 'Onboarding Incomplete';
//       statusDescription = 'Complete your Stripe setup to start selling';
//       statusIcon = Icons.warning;
//     } else {
//       statusColor = Colors.grey;
//       statusText = 'Not Registered';
//       statusDescription = 'Start the registration process to become a seller';
//       statusIcon = Icons.person_add;
//     }

//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 Container(
//                   width: 48,
//                   height: 48,
//                   decoration: BoxDecoration(
//                     color: statusColor.withValues(alpha: 0.1),
//                     borderRadius: BorderRadius.circular(24),
//                   ),
//                   child: Icon(statusIcon, color: statusColor),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         statusText,
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: statusColor,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         statusDescription,
//                         style: TextStyle(color: Colors.grey[600], fontSize: 13),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             if (hasAccount) ...[
//               const Divider(height: 32),
//               _buildStatusRow('Stripe Account', hasAccount),
//               _buildStatusRow('Onboarding Complete', isComplete),
//               _buildStatusRow('Can Receive Payouts', canReceivePayouts),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusRow(String label, bool isActive) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           Icon(
//             isActive ? Icons.check_circle : Icons.cancel,
//             size: 18,
//             color: isActive ? Colors.green : Colors.grey,
//           ),
//           const SizedBox(width: 8),
//           Text(label, style: TextStyle(color: isActive ? Colors.black : Colors.grey)),
//         ],
//       ),
//     );
//   }

//   Widget _buildBenefitItem(IconData icon, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           Icon(icon, color: const Color(0xFF667EEA), size: 20),
//           const SizedBox(width: 12),
//           Expanded(child: Text(text)),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButton(UserModel user) {
//     final hasAccount = user.stripeAccountId != null && user.stripeAccountId!.isNotEmpty;
//     final canReceivePayouts = user.payoutsEnabled;

//     String buttonText;
//     VoidCallback onPressed;

//     if (canReceivePayouts) {
//       buttonText = 'Manage Stripe Account';
//       onPressed = () => _openStripeDashboard();
//     } else if (hasAccount) {
//       buttonText = 'Complete Stripe Setup';
//       onPressed = () => _continueOnboarding();
//     } else {
//       buttonText = 'Start Seller Registration';
//       onPressed = () => _startRegistration();
//     }

//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: _isLoading ? null : onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: const Color(0xFF667EEA),
//           foregroundColor: Colors.white,
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//         child: _isLoading
//             ? const SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
//               )
//             : Text(buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//       ),
//     );
//   }

//   Future<void> _startRegistration() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });

//     try {
//       final functions = ref.read(firebaseFunctionsProvider);
//       final createAccount = functions.httpsCallable('create_connect_account');
//       final result = await createAccount.call();

//       final data = result.data as Map<String, dynamic>;

//       if (data['alreadyExists'] == true) {
//         await _continueOnboarding();
//       } else {
//         await _continueOnboarding();
//       }
//     } catch (e) {
//       setState(() {
//         _error = e.toString();
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _continueOnboarding() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });

//     try {
//       final functions = ref.read(firebaseFunctionsProvider);
//       final createLink = functions.httpsCallable('create_account_link');
//       final result = await createLink.call({
//         'refreshUrl': 'https://orignagta.ca/seller/refresh',
//         'returnUrl': 'https://orignagta.ca/seller/return',
//       });

//       final data = result.data as Map<String, dynamic>;
//       final url = data['url'] as String?;

//       if (url != null) {
//         final uri = Uri.parse(url);
//         if (await canLaunchUrl(uri)) {
//           await launchUrl(uri, mode: LaunchMode.externalApplication);
//         } else {
//           setState(() {
//             _error = 'Could not open onboarding link';
//           });
//         }
//       }
//     } catch (e) {
//       setState(() {
//         _error = e.toString();
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _openStripeDashboard() async {
//     final uri = Uri.parse('https://dashboard.stripe.com/express');
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     }
//   }
// }

//   Widget _buildStatusCard(UserModel user) {
//     final hasAccount = user.stripeAccountId != null && user.stripeAccountId!.isNotEmpty;
//     final isComplete = user.onboardingCompleted;
//     final canReceivePayouts = user.payoutsEnabled;

//     Color statusColor;
//     String statusText;
//     String statusDescription;
//     IconData statusIcon;

//     if (canReceivePayouts) {
//       statusColor = Colors.green;
//       statusText = 'Active Seller';
//       statusDescription = 'Your account is ready to receive payouts';
//       statusIcon = Icons.check_circle;
//     } else if (isComplete) {
//       statusColor = Colors.orange;
//       statusText = 'Verification Pending';
//       statusDescription = 'Stripe is reviewing your account';
//       statusIcon = Icons.hourglass_empty;
//     } else if (hasAccount) {
//       statusColor = Colors.orange;
//       statusText = 'Onboarding Incomplete';
//       statusDescription = 'Complete your Stripe setup to start selling';
//       statusIcon = Icons.warning;
//     } else {
//       statusColor = Colors.grey;
//       statusText = 'Not Registered';
//       statusDescription = 'Start the registration process to become a seller';
//       statusIcon = Icons.person_add;
//     }

//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 Container(
//                   width: 48,
//                   height: 48,
//                   decoration: BoxDecoration(
//                     color: statusColor.withValues(alpha: 0.1),
//                     borderRadius: BorderRadius.circular(24),
//                   ),
//                   child: Icon(statusIcon, color: statusColor),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         statusText,
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: statusColor,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         statusDescription,
//                         style: TextStyle(color: Colors.grey[600], fontSize: 13),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),

//             if (hasAccount) ...[
//               const Divider(height: 32),
//               _buildStatusRow('Stripe Account', hasAccount),
//               _buildStatusRow('Onboarding Complete', isComplete),
//               _buildStatusRow('Can Receive Payouts', canReceivePayouts),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusRow(String label, bool isActive) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           Icon(
//             isActive ? Icons.check_circle : Icons.cancel,
//             size: 18,
//             color: isActive ? Colors.green : Colors.grey,
//           ),
//           const SizedBox(width: 8),
//           Text(label, style: TextStyle(color: isActive ? Colors.black : Colors.grey)),
//         ],
//       ),
//     );
//   }

//   Widget _buildBenefitItem(IconData icon, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           Icon(icon, color: const Color(0xFF667EEA), size: 20),
//           const SizedBox(width: 12),
//           Expanded(child: Text(text)),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButton(UserModel user) {
//     final hasAccount = user.stripeAccountId != null && user.stripeAccountId!.isNotEmpty;
//     final canReceivePayouts = user.payoutsEnabled;

//     String buttonText;
//     VoidCallback onPressed;

//     if (canReceivePayouts) {
//       buttonText = 'Manage Stripe Account';
//       onPressed = () => _openStripeDashboard();
//     } else if (hasAccount) {
//       buttonText = 'Complete Stripe Setup';
//       onPressed = () => _continueOnboarding();
//     } else {
//       buttonText = 'Start Seller Registration';
//       onPressed = () => _startRegistration();
//     }

//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: _isLoading ? null : onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: const Color(0xFF667EEA),
//           foregroundColor: Colors.white,
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//         child: _isLoading
//             ? const SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
//               )
//             : Text(buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//       ),
//     );
//   }

//   Future<void> _startRegistration() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });

//     try {
//           final functions = FirebaseFunctions.instance;
//       if (kDebugMode) {
//         functions.useFunctionsEmulator('127.0.0.1', 8081);
//       }
//       // Create Stripe Connect account
//       final createAccount = functions.httpsCallable('create_connect_account');
//       final result = await createAccount.call();

//       final data = result.data as Map<String, dynamic>;

//       if (data['alreadyExists'] == true) {
//         // Account already exists, continue to onboarding
//         await _continueOnboarding();
//       } else {
//         // New account created, get onboarding link
//         await _continueOnboarding();
//       }
//     } on FirebaseFunctionsException catch (e) {
//       setState(() {
//         _error = e.message ?? 'Failed to create seller account';
//       });
//     } catch (e) {
//       setState(() {
//         _error = 'An unexpected error occurred: $e';
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _continueOnboarding() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });

//     try {
//            final functions = FirebaseFunctions.instance;
//       if (kDebugMode) {
//         functions.useFunctionsEmulator('127.0.0.1', 8081);
//       }
//       // Get onboarding link
//       final createLink = functions.httpsCallable('create_account_link');
//       final result = await createLink.call({
//         'refreshUrl': 'https://orignagta.ca/seller/refresh',
//         'returnUrl': 'https://orignagta.ca/seller/return',
//       });

//       final data = result.data as Map<String, dynamic>;
//       final url = data['url'] as String?;

//       if (url != null) {
//         final uri = Uri.parse(url);
//         if (await canLaunchUrl(uri)) {
//           await launchUrl(uri, mode: LaunchMode.externalApplication);
//         } else {
//           setState(() {
//             _error = 'Could not open onboarding link';
//           });
//         }
//       }
//     } on FirebaseFunctionsException catch (e) {
//       setState(() {
//         _error = e.message ?? 'Failed to get onboarding link';
//       });
//     } catch (e) {
//       setState(() {
//         _error = 'An unexpected error occurred: $e';
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _openStripeDashboard() async {
//     final uri = Uri.parse('https://dashboard.stripe.com/express');
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     }
//   }
// }
