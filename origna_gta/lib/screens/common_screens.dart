import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/screens/email_verification_screen.dart';
import 'package:origna_gta/screens/error_screen.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/env_config.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/utils/preview_helpers.dart';

// Re-export extracted screens for backward compatibility
export 'package:origna_gta/screens/admin_required_gate.dart';
export 'package:origna_gta/screens/email_verification_screen.dart';
export 'package:origna_gta/screens/error_screen.dart';

/// Gate widget that requires user to be authenticated before showing child
class AuthRequiredGate extends ConsumerWidget {
  final Widget child;

  const AuthRequiredGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return authState.when(
      loading: () => Container(
        decoration: BoxDecoration(
          gradient: DesignTokens.backgroundGradient(isDark: isDark),
        ),
        child: Scaffold(
          backgroundColor: DesignTokens.transparent,
          body: Center(
            child: ShaderMask(
              shaderCallback: (bounds) =>
                  DesignTokens.primaryGradient.createShader(bounds),
              child: const ModernLoadingIndicator(
                color: DesignTokens.white,
                strokeWidth: 3,
                centered: false,
              ),
            ),
          ),
        ),
      ),
      error: (error, _) => ErrorScreen(
        message: 'errors.auth_error'.tr(namedArgs: {'error': error.toString()}),
      ),
      data: (user) {
        if (user == null) {
          return Container(
            decoration: BoxDecoration(
              gradient: DesignTokens.backgroundGradient(isDark: isDark),
            ),
            child: Scaffold(
              appBar: AppBarFactory.simple(title: 'auth.sign_in_required'.tr()),
              backgroundColor: DesignTokens.transparent,
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Padding(
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
                                  DesignTokens.primary.withValues(alpha: 0.12),
                                  DesignTokens.secondary.withValues(
                                    alpha: 0.08,
                                  ),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_outline_rounded,
                              size: 56,
                              color: DesignTokens.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 50),
                          child: Text(
                            'auth.please_sign_in'.tr(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? DesignTokens.white
                                  : DesignTokens.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 100),
                          child: Text(
                            'auth.need_account_access'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              color: DesignTokens.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 32),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 150),
                          child: ModernButton(
                            label: 'auth.sign_in'.tr(),
                            icon: Icons.login_rounded,
                            onPressed: () => Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.login),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 200),
                          child: Tooltip(
                            message: 'btn-common-go-home',
                            child: TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    AppRoutes.home,
                                    (route) => false,
                                  ),
                              child: Text(
                                'seller.go_home'.tr(),
                                style: TextStyle(
                                  color: DesignTokens.primary,
                                  fontWeight: FontWeight.w600,
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
        // Gate: block suspended users from all protected routes.
        // Wait for profile to load before granting access — null profile is not a pass.
        final userProfileAsync = ref.watch(userProfileProvider);
        if (userProfileAsync.isLoading) {
          return const Scaffold(
            body: Center(child: ModernLoadingIndicator(centered: false)),
          );
        }
        // Fail closed on error — never grant access when profile can't be loaded
        if (userProfileAsync.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: DesignTokens.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'auth.profile_load_error'.tr(),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final userProfile = userProfileAsync.valueOrNull;
        if (userProfile?.suspended == true) {
          return Container(
            decoration: BoxDecoration(
              gradient: DesignTokens.backgroundGradient(isDark: isDark),
            ),
            child: Scaffold(
              appBar: AppBarFactory.simple(
                title: 'auth.account_suspended'.tr(),
              ),
              backgroundColor: DesignTokens.transparent,
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: FadeSlideIn(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: DesignTokens.error.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.block_rounded,
                            size: 56,
                            color: DesignTokens.error,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spacing20),
                        Text(
                          'auth.account_suspended'.tr(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spacing8),
                        Text(
                          'auth.contact_support'.tr(),
                          style: TextStyle(color: DesignTokens.textSecondary),
                        ),
                        const SizedBox(height: 32),
                        ModernButton(
                          label: 'seller.go_home'.tr(),
                          icon: Icons.home_outlined,
                          isPrimary: false,
                          isOutlined: true,
                          onPressed: () =>
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                AppRoutes.home,
                                (route) => false,
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
        // Gate: block unverified email users from protected routes
        if (!user.emailVerified && !EnvConfig().isEmulator) {
          return const EmailVerificationRequiredScreen();
        }
        return child;
      },
    );
  }
}

// ─── Flutter Previews ────────────────────────────────────────────────────────

// === Widget Previews ===

// ═══ Widget Previews ═══

@Preview(
  name: 'Email Verification — Mobile',
  group: 'Screens — Auth Flows',
  size: Size(390, 844),
)
Widget previewEmailVerificationRequiredScreenMobile() => previewMobile(
  child: previewScope(child: EmailVerificationRequiredScreen()),
);

@Preview(
  name: 'Email Verification — Tablet',
  group: 'Screens — Auth Flows',
  size: Size(768, 1024),
)
Widget previewEmailVerificationRequiredScreenTablet() => previewTablet(
  child: previewScope(child: EmailVerificationRequiredScreen()),
);

@Preview(
  name: 'Email Verification — Desktop',
  group: 'Screens — Auth Flows',
  size: Size(1280, 800),
)
Widget previewEmailVerificationRequiredScreenDesktop() => previewDesktop(
  child: previewScope(child: EmailVerificationRequiredScreen()),
);

@Preview(
  name: 'Email Verification — Web',
  group: 'Screens — Auth Flows',
  size: Size(1440, 900),
)
Widget previewEmailVerificationRequiredScreenWeb() =>
    previewWeb(child: previewScope(child: EmailVerificationRequiredScreen()));

// ── Light ────────────────────────────────────────────────────────────────────
@Preview(
  name: 'Email Verification Light — Mobile',
  group: 'Screens — Auth Flows',
  size: Size(390, 844),
)
Widget previewEmailVerificationLightMobile() => previewMobile(
  theme: previewLightTheme,
  child: previewScope(child: EmailVerificationRequiredScreen()),
);

@Preview(
  name: 'Email Verification Light — Tablet',
  group: 'Screens — Auth Flows',
  size: Size(768, 1024),
)
Widget previewEmailVerificationLightTablet() => previewTablet(
  theme: previewLightTheme,
  child: previewScope(child: EmailVerificationRequiredScreen()),
);

@Preview(
  name: 'Email Verification Light — Desktop',
  group: 'Screens — Auth Flows',
  size: Size(1280, 800),
)
Widget previewEmailVerificationLightDesktop() => previewDesktop(
  theme: previewLightTheme,
  child: previewScope(child: EmailVerificationRequiredScreen()),
);

@Preview(
  name: 'Email Verification Light — Web',
  group: 'Screens — Auth Flows',
  size: Size(1440, 900),
)
Widget previewEmailVerificationLightWeb() => previewWeb(
  theme: previewLightTheme,
  child: previewScope(child: EmailVerificationRequiredScreen()),
);
