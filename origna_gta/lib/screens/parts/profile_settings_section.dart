part of '../profile_screen.dart';

// ─── Riverpod state for profile settings ─────────────────────────────────────
// Note: These providers are defined in the part file but accessible via the library.
final _deleteConfirmTextProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);
final _emailVerifyCheckingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);
final _emailVerifyResendingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  late final TextEditingController confirmController;
  ProviderSubscription<ProfileState>? _deleteAccountSubscription;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileState = ref.watch(profileViewModelProvider);
    final viewModel = ref.read(profileViewModelProvider.notifier);
    // Watch the confirm text so the button enables/disables reactively
    ref.watch(_deleteConfirmTextProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius20),
      ),
      backgroundColor: isDark ? DesignTokens.darkSurface : DesignTokens.white,
      title: Row(
        children: [
          Icon(Icons.warning_rounded, color: DesignTokens.error, size: 28),
          const SizedBox(width: 12),
          Text(
            'profile.delete_account'.tr(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? DesignTokens.textOnDark
                  : DesignTokens.textPrimary,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'profile.delete_warning_short'.tr(),
              style: TextStyle(
                color: DesignTokens.error,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'profile.type_delete'.tr(),
              style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ModernTextField(
              controller: confirmController,
              hint: 'profile.type_delete_hint'.tr(),
              prefixIcon: Icons.lock_outline,
              onChanged: (value) =>
                  ref.read(_deleteConfirmTextProvider.notifier).state = value,
            ),
          ],
        ),
      ),
      actions: [
        Semantics(
          label: 'btn-profile-delete-cancel',
          button: true,
          child: TextButton(
            onPressed: () => appPop(context),
            style: TextButton.styleFrom(
              foregroundColor: DesignTokens.textSecondary,
            ),
            child: Text('common.cancel'.tr()),
          ),
        ),
        ModernButton(
          onPressed:
              confirmController.text == 'profile.type_delete_keyword'.tr() &&
                  !profileState.isLoading
              ? () => viewModel.deleteAccount(confirmController.text.trim())
              : null,
          label: 'profile.delete_account'.tr(),
          isLoading: profileState.isLoading,
          backgroundColor:
              confirmController.text == 'profile.type_delete_keyword'.tr()
              ? DesignTokens.error
              : DesignTokens.textDisabled,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _deleteAccountSubscription?.close();
    confirmController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    confirmController = TextEditingController();
    _deleteAccountSubscription = ref.listenManual(profileViewModelProvider, (
      _,
      next,
    ) {
      if (!mounted) return;
      if (next.isDeleted) {
        appPop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auth.account_deleted'.tr()),
            backgroundColor: DesignTokens.success,
          ),
        );
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: DesignTokens.error,
          ),
        );
      }
    });
  }
}

/// Widget shown inside ProfileScreen when user is authenticated but email is not verified
class _EmailVerificationRequiredView extends ConsumerStatefulWidget {
  final AppAuthUser user;
  const _EmailVerificationRequiredView({required this.user});

  @override
  ConsumerState<_EmailVerificationRequiredView> createState() =>
      _EmailVerificationRequiredViewState();
}

class _EmailVerificationRequiredViewState
    extends ConsumerState<_EmailVerificationRequiredView> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isChecking = ref.watch(_emailVerifyCheckingProvider);
    final isResending = ref.watch(_emailVerifyResendingProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              FadeSlideIn(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DesignTokens.warning.withValues(alpha: 0.15),
                        DesignTokens.warning.withValues(alpha: 0.08),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_unread_outlined,
                    size: 56,
                    color: DesignTokens.warning,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: const Duration(milliseconds: 50),
                child: Text(
                  'profile.verify_email_title'.tr(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? DesignTokens.textOnDark
                        : DesignTokens.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeSlideIn(
                delay: const Duration(milliseconds: 75),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.user.email ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? DesignTokens.darkSurfaceVariant.withValues(alpha: 0.5)
                        : DesignTokens.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? DesignTokens.darkOutline
                          : DesignTokens.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'profile.verify_email_desc'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: DesignTokens.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStep('1', 'profile.verify_step_1'.tr()),
                      _buildStep('2', 'profile.verify_step_2'.tr()),
                      _buildStep('3', 'profile.verify_step_3'.tr()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FadeSlideIn(
                delay: const Duration(milliseconds: 150),
                child: ModernButton(
                  label: isChecking
                      ? 'profile.checking_button'.tr()
                      : 'profile.verified_button'.tr(),
                  icon: Icons.check_circle_outline,
                  isLoading: isChecking,
                  onPressed: isChecking ? () {} : _checkVerification,
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 175),
                child: ModernButton(
                  label: isResending
                      ? 'profile.sending_button'.tr()
                      : 'profile.resend_verification_button'.tr(),
                  icon: Icons.send_outlined,
                  isPrimary: false,
                  isLoading: isResending,
                  onPressed: isResending ? () {} : _resendEmail,
                ),
              ),
              const SizedBox(height: 20),
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: ModernButton(
                  label: 'profile.sign_in_different'.tr(),
                  icon: Icons.logout,
                  isPrimary: false,
                  onPressed: () async {
                    await ref.read(authActionsProvider).signOut();
                    if (context.mounted) {
                      appPushNamedAndRemoveUntil(
                        context,
                        AppRoutes.home,
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: DesignTokens.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: DesignTokens.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? DesignTokens.outlineVariant
                    : DesignTokens.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkVerification() async {
    if (!mounted) return;
    ref.read(_emailVerifyCheckingProvider.notifier).state = true;
    try {
      final verified = await ref.read(authActionsProvider).isEmailVerified();
      if (!mounted) return;
      if (verified) {
        await ref.read(authActionsProvider).ensureUserDocumentExists();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 ${'profile.email_verified_snackbar'.tr()}'),
              backgroundColor: DesignTokens.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('profile.not_verified_error'.tr()),
              backgroundColor: DesignTokens.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('errors.verification_error'.tr()),
            backgroundColor: DesignTokens.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        ref.read(_emailVerifyCheckingProvider.notifier).state = false;
      }
    }
  }

  Future<void> _resendEmail() async {
    if (!mounted) return;
    ref.read(_emailVerifyResendingProvider.notifier).state = true;
    try {
      await ref.read(authActionsProvider).sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profile.verification_sent'.tr()),
          backgroundColor: DesignTokens.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('too-many-requests')
                  ? 'Please wait before requesting another email.'
                  : 'Failed to send email. Please try again later.',
            ),
            backgroundColor: DesignTokens.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        ref.read(_emailVerifyResendingProvider.notifier).state = false;
      }
    }
  }
}

/// Profile completion bar shown inside the profile header card.
/// 4 steps: name set · address added · notifications on · premium
class _ProfileCompletionBar extends StatelessWidget {
  final UserModel userModel;

  /// Authoritative premium flag from subscriptionStreamProvider — never
  /// use userModel.isPremium here as it can lag behind subscription updates.
  final bool isPremium;
  const _ProfileCompletionBar({
    required this.userModel,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      userModel.name.isNotEmpty, // Name set
      userModel.address != null, // Address added
      userModel.notifyNewProducts || userModel.notifyTrending, // Notifications
      isPremium, // Premium — from subscriptionStreamProvider (authoritative)
    ];
    final completed = steps.where((s) => s).length;
    final pct = completed / steps.length;

    if (pct >= 1.0) return const SizedBox.shrink(); // 100% — hide bar

    final pctInt = (pct * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'profile.completion'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: DesignTokens.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Text(
              '$pctInt%',
              style: const TextStyle(
                color: DesignTokens.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 5,
            backgroundColor: DesignTokens.white.withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(
              DesignTokens.accent,
            ),
          ),
        ),
      ],
    );
  }
}

/// Single pill segment for the theme toggle row.
class _ThemePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemePill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'btn-theme-$label',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: DesignTokens.durationFast,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: selected ? DesignTokens.primaryGradient : null,
            borderRadius: BorderRadius.circular(DesignTokens.radius20),
          ),
          child: Icon(
            icon,
            size: 16,
            color: selected ? DesignTokens.white : DesignTokens.textSecondary,
          ),
        ),
      ),
    );
  }
}
