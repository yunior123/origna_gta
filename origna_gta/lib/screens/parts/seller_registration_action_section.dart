part of '../seller_registration_screen.dart';

/// CTA button that adapts based on seller registration / onboarding state.
class _ActionButton extends ConsumerWidget {
  final UserModel user;
  final SellerRegistrationState viewState;
  final SellerRegistrationViewModel viewModel;

  const _ActionButton({
    required this.user,
    required this.viewState,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = viewState.isLoading;

    final status = ref.watch(
      sellerAccountStatusProvider.select((a) => a.valueOrNull),
    );

    // C-5: Read from sellerAccountStatusProvider instead of UserModel
    final hasAccount =
        status != null &&
        status.isSeller; // isSeller implies a seller profile exists
    final canReceivePayouts =
        status?.chargesEnabled ??
        false; // In SellerAccountStatus, chargesEnabled implies payoutsEnabled
    final onboardingCompleted = status?.detailsSubmitted ?? false;
    final hasPendingRequirements = status?.hasPendingRequirements ?? false;
    final hasError = viewState.error != null && viewState.error!.isNotEmpty;

    String buttonText;
    VoidCallback? onPressed;

    if (canReceivePayouts) {
      // Already set up - can manage without accepting terms again
      buttonText = 'seller.manage_stripe'.tr();
      onPressed = viewModel.openStripeDashboard;
    } else if (hasAccount &&
        onboardingCompleted &&
        hasPendingRequirements &&
        !hasError) {
      // Has account, submitted details, but still has requirements to complete
      buttonText = 'seller.complete_documents'.tr();
      onPressed = viewModel.continueOnboarding;
    } else if (hasAccount && onboardingCompleted && !hasError) {
      // Has account, submitted all details, waiting for Stripe verification
      buttonText = 'seller.check_verification'.tr();
      onPressed = viewModel.openStripeDashboard;
    } else if (hasAccount && !onboardingCompleted && !hasError) {
      // Has account but hasn't finished providing info to Stripe
      buttonText = 'seller.complete_stripe_setup'.tr();
      onPressed = viewModel.continueOnboarding;
    } else if (hasAccount && hasError) {
      // Has account but onboarding link failed - allow retry
      buttonText = 'seller.retry_stripe_setup'.tr();
      onPressed = viewModel.continueOnboarding;
    } else {
      // New registration - MUST accept terms
      buttonText = 'seller.start_registration'.tr();
      onPressed = ref.watch(_sellerTermsAcceptedProvider)
          ? viewModel.startRegistration
          : null;
    }

    return Semantics(
      button: true,
      label: 'btn-seller-action',
      child: ModernButton(
        key: const Key('seller_action_button'),
        onPressed: isLoading ? null : onPressed,
        label: buttonText,
        isLoading: isLoading,
        icon: canReceivePayouts
            ? Icons.dashboard
            : hasAccount
            ? Icons.check_circle
            : Icons.store,
      ),
    );
  }
}

/// Verification status info card — reads Stripe status from seller_profiles/{uid}
/// via sellerAccountStatusProvider (not UserModel, which only reads users/{uid}).
class _VerificationStatusCard extends ConsumerWidget {
  final UserModel user;

  const _VerificationStatusCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Stripe status fields live in seller_profiles/{uid}, not users/{uid}.
    // Use sellerAccountStatusProvider which correctly combines both collections.
    final status = ref.watch(
      sellerAccountStatusProvider.select((a) => a.valueOrNull),
    );

    final hasAccount =
        user.stripeAccountId != null && user.stripeAccountId!.isNotEmpty;
    final onboardingCompleted = status?.detailsSubmitted ?? false;
    final chargesEnabled = status?.chargesEnabled ?? false;
    final payoutsEnabled =
        status?.chargesEnabled ??
        false; // chargesEnabled combines both in SellerAccountStatus

    // Only show if user has account but verification is pending
    if (!hasAccount || (chargesEnabled && payoutsEnabled)) {
      return const SizedBox.shrink();
    }

    String title;
    String message;
    IconData icon;
    Color color;

    if (!onboardingCompleted) {
      title = 'seller.complete_your_setup'.tr();
      message = 'seller.complete_setup_card_body'.tr();
      icon = Icons.assignment_outlined;
      color = DesignTokens.primary;
    } else if (!chargesEnabled || !payoutsEnabled) {
      title = 'seller.identity_pending'.tr();
      message = 'seller.identity_pending_card_body'.tr();
      icon = Icons.hourglass_empty;
      color = DesignTokens.warning;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
