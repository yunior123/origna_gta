import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';

/// Screen shown when user needs to verify their email before accessing a feature
class EmailVerificationRequiredScreen extends ConsumerStatefulWidget {
  const EmailVerificationRequiredScreen({super.key});

  @override
  ConsumerState<EmailVerificationRequiredScreen> createState() =>
      _EmailVerificationRequiredScreenState();
}

// ─── Riverpod state for EmailVerificationRequiredScreen ──────────────────────
final _evrsCheckingProvider = StateProvider.autoDispose<bool>((ref) => false);
final _evrsResendingProvider = StateProvider.autoDispose<bool>((ref) => false);

class _EmailVerificationRequiredScreenState
    extends ConsumerState<EmailVerificationRequiredScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isChecking = ref.watch(_evrsCheckingProvider);
    final isResending = ref.watch(_evrsResendingProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: DesignTokens.backgroundGradient(isDark: isDark),
      ),
      child: Scaffold(
        appBar: AppBarFactory.simple(title: 'email_verification.title'.tr()),
        backgroundColor: DesignTokens.transparent,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spacing24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                      'email_verification.title'.tr(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? DesignTokens.white
                            : DesignTokens.textPrimary,
                      ),
                    ),
                  ),
                  if (user?.email != null) ...[
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
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? DesignTokens.darkSurfaceVariant.withValues(
                                alpha: 0.5,
                              )
                            : DesignTokens.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? DesignTokens.textPrimary
                              : DesignTokens.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'email_verification.instruction_title'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              color: DesignTokens.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStep(
                            context,
                            '1',
                            'email_verification.step1'.tr(),
                          ),
                          _buildStep(
                            context,
                            '2',
                            'email_verification.step2'.tr(),
                          ),
                          _buildStep(
                            context,
                            '3',
                            'email_verification.step3'.tr(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 150),
                    child: ModernButton(
                      label: isChecking
                          ? 'email_verification.checking'.tr()
                          : 'email_verification.verify_button'.tr(),
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
                          ? 'email_verification.sending'.tr()
                          : 'email_verification.resend_button'.tr(),
                      icon: Icons.send_outlined,
                      isPrimary: false,
                      isLoading: isResending,
                      onPressed: isResending ? () {} : _resendEmail,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: Semantics(
                      label: 'btn-email-different-account',
                      button: true,
                      child: TextButton.icon(
                        onPressed: () async {
                          await ref.read(authActionsProvider).signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.home,
                              (route) => false,
                            );
                          }
                        },
                        icon: Icon(
                          Icons.logout,
                          size: 16,
                          color: DesignTokens.textSecondary,
                        ),
                        label: Text(
                          'email_verification.different_account'.tr(),
                          style: TextStyle(
                            color: DesignTokens.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, String number, String text) {
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
    ref.read(_evrsCheckingProvider.notifier).state = true;
    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final verified = await ref.read(authActionsProvider).isEmailVerified();
        if (verified) {
          await ref.read(authActionsProvider).ensureUserDocumentExists();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '🎉 ${'email_verification.verified_success'.tr()}',
                ),
                backgroundColor: DesignTokens.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('email_verification.not_verified_error'.tr()),
                backgroundColor: DesignTokens.warning,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
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
      if (mounted) ref.read(_evrsCheckingProvider.notifier).state = false;
    }
  }

  Future<void> _resendEmail() async {
    ref.read(_evrsResendingProvider.notifier).state = true;
    try {
      await ref.read(authActionsProvider).sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${'email_verification.sent_success'.tr()}'),
            backgroundColor: DesignTokens.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('too-many-requests')
                  ? 'email_verification.too_many_requests'.tr()
                  : 'email_verification.send_failed'.tr(),
            ),
            backgroundColor: DesignTokens.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) ref.read(_evrsResendingProvider.notifier).state = false;
    }
  }
}
