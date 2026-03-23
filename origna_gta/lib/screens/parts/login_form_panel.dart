part of '../login_screen.dart';

/// Full login/register layout widget. Stateless — all callbacks passed in.
class LoginScreenLayout extends StatelessWidget {
  final bool isLogin;
  final bool isLoading;
  final bool showGoogleSignIn;
  final bool obscurePassword;
  final bool acceptedTerms;
  final bool marketingOptIn;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final Animation<double>? fadeAnimation;
  final Animation<Offset>? slideAnimation;
  final VoidCallback onAuthToggle;
  final VoidCallback onAuthSubmit;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onAppleSignIn;
  final VoidCallback onForgotPassword;
  final VoidCallback onToggleObscurePassword;
  final ValueChanged<bool?> onTermsChanged;
  final ValueChanged<bool?> onMarketingOptInChanged;

  const LoginScreenLayout({
    super.key,
    required this.isLogin,
    required this.isLoading,
    required this.showGoogleSignIn,
    required this.obscurePassword,
    required this.acceptedTerms,
    required this.marketingOptIn,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.formKey,
    this.fadeAnimation,
    this.slideAnimation,
    required this.onAuthToggle,
    required this.onAuthSubmit,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
    required this.onForgotPassword,
    required this.onToggleObscurePassword,
    required this.onTermsChanged,
    required this.onMarketingOptInChanged,
  });

  // ignore: override_on_non_overriding_member
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Always navigate to home when back is pressed on login — covers both
        // in-app back and browser back button on Flutter Web. Using
        // pushNamedAndRemoveUntil ensures the browser URL updates to '/' and
        // clears the Flutter route stack, preventing the tab-close bug where
        // Navigator.pop() pops the widget but the browser back stays on /login.
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [DesignTokens.darkBackground, DesignTokens.darkSurface]
                  : [
                      DesignTokens.primary.withValues(alpha: 0.05),
                      DesignTokens.secondary.withValues(alpha: 0.05),
                    ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (_, constraints) {
                    final isDesktop = constraints.maxWidth >= 900;
                    final formPanel = SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacing20,
                        vertical: DesignTokens.spacing24,
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Hero(
                              tag: 'app_logo',
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      DesignTokens.gradientStart,
                                      DesignTokens.gradientMiddle,
                                      DesignTokens.gradientEnd,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    DesignTokens.radius24,
                                  ),
                                  boxShadow: [
                                    ...DesignTokens.shadowLg,
                                    BoxShadow(
                                      color: DesignTokens.gradientStart
                                          .withValues(alpha: 0.35),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 56,
                                  color: DesignTokens.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            ShaderMask(
                              shaderCallback: (bounds) => DesignTokens
                                  .primaryGradient
                                  .createShader(bounds),
                              child: const Text(
                                'OrignaGta',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  color: DesignTokens.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isLogin
                                  ? 'auth.welcome_back_subtitle'.tr()
                                  : 'auth.start_today'.tr(),
                              style: TextStyle(
                                fontSize: 15,
                                color: DesignTokens.textSecondary,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 40),
                            GlassContainer(
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: Column(
                                  children: [
                                    if (!isLogin) ...[
                                      ModernTextField(
                                        key: const Key('login_name_field'),
                                        label: 'auth.full_name'.tr(),
                                        hint: 'auth.full_name_hint'.tr(),
                                        controller: nameController,
                                        prefixIcon: Icons.person_outline,
                                        validator: (value) {
                                          if (isLogin) return null;
                                          if (value == null || value.isEmpty) {
                                            return 'auth.name_required'.tr();
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(
                                        height: DesignTokens.spacing16,
                                      ),
                                    ],
                                    ModernTextField(
                                      key: const Key('login_email_field'),
                                      semanticsLabel: 'login_email_field',
                                      label: 'auth.email_address'.tr(),
                                      hint: 'auth.email_hint'.tr(),
                                      controller: emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      prefixIcon: Icons.mail_outline,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'auth.email_required'.tr();
                                        }
                                        if (!ValidationConstants.emailRegex
                                            .hasMatch(value)) {
                                          return 'auth.email_invalid'.tr();
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(
                                      height: DesignTokens.spacing16,
                                    ),
                                    ModernTextField(
                                      key: const Key('login_password_field'),
                                      semanticsLabel: 'login_password_field',
                                      label: 'auth.password'.tr(),
                                      hint: '••••••••',
                                      controller: passwordController,
                                      isPassword: obscurePassword,
                                      prefixIcon: Icons.lock_outline,
                                      suffixIcon: obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      onSuffixTap: onToggleObscurePassword,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'auth.password_required'.tr();
                                        }
                                        if (!isLogin) {
                                          if (value.length <
                                              ValidationConstants
                                                  .minPasswordLength) {
                                            return 'auth.validation.password_min_8'
                                                .tr();
                                          }
                                          if (!ValidationConstants.passwordRegex
                                              .hasMatch(value)) {
                                            return 'auth.validation.password_weak'
                                                .tr();
                                          }
                                        }
                                        if (isLogin && value.length < 6) {
                                          return 'auth.password_min_length'
                                              .tr();
                                        }
                                        return null;
                                      },
                                    ),
                                    if (!isLogin) ...[
                                      const SizedBox(
                                        height: DesignTokens.spacing16,
                                      ),
                                      Row(
                                        children: [
                                          Semantics(
                                            label: 'checkbox-accept-terms',
                                            child: Checkbox(
                                              key: const Key(
                                                'login_terms_checkbox',
                                              ),
                                              value: acceptedTerms,
                                              onChanged: onTermsChanged,
                                              fillColor:
                                                  WidgetStateProperty.resolveWith<
                                                    Color?
                                                  >((states) {
                                                    if (states.contains(
                                                      WidgetState.selected,
                                                    )) {
                                                      return DesignTokens
                                                          .primary;
                                                    }
                                                    return null;
                                                  }),
                                            ),
                                          ),
                                          Expanded(
                                            child: RichText(
                                              text: TextSpan(
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDark
                                                      ? DesignTokens.textOnDark
                                                      : DesignTokens
                                                            .textPrimary,
                                                  height: 1.4,
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text: 'auth.agree_to_prefix'
                                                        .tr(),
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        'auth.terms_conditions'
                                                            .tr(),
                                                    style: const TextStyle(
                                                      color:
                                                          DesignTokens.primary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      decoration: TextDecoration
                                                          .underline,
                                                    ),
                                                    recognizer:
                                                        TapGestureRecognizer()
                                                          ..onTap = () =>
                                                              openTermsOfService(
                                                                context,
                                                              ),
                                                  ),
                                                  TextSpan(
                                                    text: 'auth.and_conjunction'
                                                        .tr(),
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        'auth.privacy_policy_link'
                                                            .tr(),
                                                    style: const TextStyle(
                                                      color:
                                                          DesignTokens.primary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      decoration: TextDecoration
                                                          .underline,
                                                    ),
                                                    recognizer:
                                                        TapGestureRecognizer()
                                                          ..onTap = () =>
                                                              openPrivacyPolicy(
                                                                context,
                                                              ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (!isLogin) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Semantics(
                                            label: 'checkbox-marketing-opt-in',
                                            child: Checkbox(
                                              value: marketingOptIn,
                                              onChanged:
                                                  onMarketingOptInChanged,
                                              fillColor:
                                                  WidgetStateProperty.resolveWith<
                                                    Color?
                                                  >((states) {
                                                    if (states.contains(
                                                      WidgetState.selected,
                                                    )) {
                                                      return DesignTokens
                                                          .primary;
                                                    }
                                                    return null;
                                                  }),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              'auth.marketing_opt_in'.tr(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    DesignTokens.textSecondary,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: DesignTokens.spacing16,
                              ),
                              child: Column(
                                children: [
                                  ModernButton(
                                    key: const Key('login_submit_button'),
                                    semanticsLabel: 'login_submit_button',
                                    label: isLogin
                                        ? 'auth.sign_in'.tr()
                                        : 'auth.create_account'.tr(),
                                    isLoading: isLoading,
                                    isPrimary: true,
                                    onPressed: onAuthSubmit,
                                  ),
                                  const SizedBox(height: 16),
                                  if (isLogin) ...[
                                    Semantics(
                                      label: 'btn-forgot-password',
                                      button: true,
                                      excludeSemantics: true,
                                      child: TextButton(
                                        key: const Key(
                                          'login_forgot_password_button',
                                        ),
                                        onPressed: onForgotPassword,
                                        style: TextButton.styleFrom(
                                          foregroundColor: DesignTokens.primary,
                                          textStyle: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        child: Text(
                                          'auth.forgot_password'.tr(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: DesignTokens.outlineVariant,
                                          thickness: 0.8,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: DesignTokens.spacing12,
                                        ),
                                        child: Text(
                                          'auth.or_continue_with'.tr(),
                                          style: TextStyle(
                                            color: DesignTokens.textSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: DesignTokens.outlineVariant,
                                          thickness: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (showGoogleSignIn)
                                    _GoogleSignInButton(
                                      key: const Key('login_google_button'),
                                      label: isLogin
                                          ? 'auth.google_sign_in'.tr()
                                          : 'auth.sign_up_with_google'.tr(),
                                      isLoading: isLoading,
                                      onPressed: isLoading
                                          ? null
                                          : onGoogleSignIn,
                                    ),
                                  if (!kIsWeb &&
                                      (Theme.of(context).platform ==
                                              TargetPlatform.iOS ||
                                          Theme.of(context).platform ==
                                              TargetPlatform.macOS)) ...[
                                    const SizedBox(height: 12),
                                    Semantics(
                                      label: 'login_apple_button',
                                      button: true,
                                      excludeSemantics: true,
                                      child: SignInWithAppleButton(
                                        key: const Key('login_apple_button'),
                                        text: isLogin
                                            ? 'auth.apple_sign_in'.tr()
                                            : 'auth.sign_up_with_apple'.tr(),
                                        style: isDark
                                            ? SignInWithAppleButtonStyle.white
                                            : SignInWithAppleButtonStyle.black,
                                        height: 52,
                                        borderRadius: const BorderRadius.all(
                                          Radius.circular(
                                            DesignTokens.radius16,
                                          ),
                                        ),
                                        onPressed: isLoading
                                            ? () {}
                                            : onAppleSignIn,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Semantics(
                              label: 'btn-toggle-auth-mode',
                              button: true,
                              child: GestureDetector(
                                key: const Key('login_toggle_mode_button'),
                                onTap: isLoading ? null : onAuthToggle,
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: DesignTokens.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: isLogin
                                            ? "auth.no_account".tr()
                                            : 'auth.already_have_account'.tr(),
                                      ),
                                      TextSpan(
                                        text: isLogin
                                            ? 'auth.sign_up'.tr()
                                            : 'auth.sign_in'.tr(),
                                        style: const TextStyle(
                                          color: DesignTokens.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                    if (isDesktop) {
                      return Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 48,
                                vertical: 40,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    DesignTokens.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    DesignTokens.secondary.withValues(
                                      alpha: 0.08,
                                    ),
                                  ],
                                ),
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (b) => DesignTokens
                                          .primaryGradient
                                          .createShader(b),
                                      child: const Text(
                                        'OrignaGTA',
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w900,
                                          color: DesignTokens.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'app.tagline'.tr(),
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: DesignTokens.textSecondary,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 48),
                                    ...[
                                      'auth.feature_1',
                                      'auth.feature_2',
                                      'auth.feature_3',
                                    ].map(
                                      (key) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 20,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                gradient: DesignTokens
                                                    .primaryGradient,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check_rounded,
                                                size: 14,
                                                color: DesignTokens.white,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Text(
                                                key.tr(),
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 500, child: formPanel),
                        ],
                      );
                    }
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: formPanel,
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: Semantics(
                    label: 'btn-back-to-home',
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: DesignTokens.textPrimary,
                      ),
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.home,
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (fadeAnimation != null && slideAnimation != null) {
      return FadeTransition(
        opacity: fadeAnimation!,
        child: SlideTransition(position: slideAnimation!, child: content),
      );
    }

    return content;
  }
}
