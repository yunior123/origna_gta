import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:origna_gta/widgets/modern_textfield.dart';

import '../features/auth/login_viewmodel.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginViewModelProvider);
    final viewModel = ref.read(loginViewModelProvider.notifier);

    // Listen for success or error
    ref.listen(loginViewModelProvider, (previous, next) {
      if (next.isSuccess) {
        _onAuthSuccess();
      } else if (next.successMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.successMessage!), backgroundColor: DesignTokens.success, behavior: SnackBarBehavior.floating));
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!), backgroundColor: DesignTokens.error, behavior: SnackBarBehavior.floating));
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [DesignTokens.primary.withValues(alpha: 0.05), DesignTokens.secondary.withValues(alpha: 0.05)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing20, vertical: DesignTokens.spacing24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo with animation
                          Hero(
                            tag: 'app_logo',
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: DesignTokens.primaryGradient,
                                borderRadius: BorderRadius.circular(DesignTokens.radius24),
                                boxShadow: DesignTokens.shadowLg,
                              ),
                              child: const Icon(Icons.shopping_bag_outlined, size: 56, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Title
                          ShaderMask(
                            shaderCallback: (bounds) => DesignTokens.primaryGradient.createShader(bounds),
                            child: const Text(
                              'OrignaGta',
                              style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            state.isLogin ? 'auth.welcome_back_subtitle'.tr() : 'auth.start_today'.tr(),
                            style: TextStyle(fontSize: 15, color: DesignTokens.textSecondary, fontWeight: FontWeight.w500, letterSpacing: 0.2),
                          ),
                          const SizedBox(height: 40),

                          // Form fields in glass container
                          GlassContainer(
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: Column(
                                children: [
                                  if (!state.isLogin) ...[
                                    ModernTextField(
                                      key: const Key('login_name_field'),
                                      label: 'auth.full_name'.tr(),
                                      hint: 'John Doe',
                                      controller: _nameController,
                                      prefixIcon: Icons.person_outline,
                                      validator: (value) {
                                        if (state.isLogin) return null;
                                        if (value == null || value.isEmpty) {
                                          return 'auth.name_required'.tr();
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: DesignTokens.spacing16),
                                  ],
                                  ModernTextField(
                                    key: const Key('login_email_field'),
                                    semanticsLabel: 'login_email_field',
                                    label: 'auth.email_address'.tr(),
                                    hint: 'you@example.com',
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: Icons.mail_outline,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'auth.email_required'.tr();
                                      }
                                      if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                                        return 'auth.email_invalid'.tr();
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: DesignTokens.spacing16),
                                  ModernTextField(
                                    key: const Key('login_password_field'),
                                    semanticsLabel: 'login_password_field',
                                    label: 'auth.password'.tr(),
                                    hint: '••••••••',
                                    controller: _passwordController,
                                    isPassword: state.obscurePassword,
                                    prefixIcon: Icons.lock_outline,
                                    suffixIcon: state.obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    onSuffixTap: viewModel.toggleObscurePassword,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'auth.password_required'.tr();
                                      }
                                      if (!state.isLogin && value.length < 8) {
                                        return 'auth.validation.password_min_8'.tr();
                                      }
                                      if (state.isLogin && value.length < 6) {
                                        return 'auth.password_min_length'.tr();
                                      }
                                      return null;
                                    },
                                  ),
                                  if (!state.isLogin) ...[
                                    const SizedBox(height: DesignTokens.spacing16),
                                    Row(
                                      children: [
                                        Semantics(
                                          label: 'checkbox-accept-terms',
                                          child: Checkbox(
                                            key: const Key('login_terms_checkbox'),
                                            value: state.acceptedTerms,
                                            onChanged: (v) => viewModel.setAcceptedTerms(v ?? false),
                                            fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                              if (states.contains(WidgetState.selected)) {
                                                return DesignTokens.primary;
                                              }
                                              return null;
                                            }),
                                          ),
                                        ),
                                        Expanded(
                                          child: RichText(
                                            text: TextSpan(
                                              style: TextStyle(fontSize: 13, color: DesignTokens.textPrimary, height: 1.4),
                                              children: [
                                                TextSpan(text: 'auth.agree_to_prefix'.tr()),
                                                TextSpan(
                                                  text: 'auth.terms_conditions'.tr(),
                                                  style: const TextStyle(
                                                    color: DesignTokens.primary,
                                                    fontWeight: FontWeight.w600,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                  recognizer: TapGestureRecognizer()..onTap = () => openTermsOfService(context),
                                                ),
                                                TextSpan(text: 'auth.and_conjunction'.tr()),
                                                TextSpan(
                                                  text: 'auth.privacy_policy_link'.tr(),
                                                  style: const TextStyle(
                                                    color: DesignTokens.primary,
                                                    fontWeight: FontWeight.w600,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                  recognizer: TapGestureRecognizer()..onTap = () => openPrivacyPolicy(context),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  // FIX #8: Separate marketing opt-in (CASL / Loi 25)
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Semantics(
                                        label: 'checkbox-marketing-opt-in',
                                        child: Checkbox(
                                          value: state.marketingOptIn,
                                          onChanged: (v) => viewModel.setMarketingOptIn(v ?? false),
                                          fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                            if (states.contains(WidgetState.selected)) {
                                              return DesignTokens.primary;
                                            }
                                            return null;
                                          }),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'auth.marketing_opt_in'.tr(),
                                          style: TextStyle(fontSize: 12, color: DesignTokens.textSecondary, height: 1.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Primary action button
                          ModernButton(
                            key: const Key('login_submit_button'),
                            semanticsLabel: 'login_submit_button',
                            label: state.isLogin ? 'auth.sign_in'.tr() : 'auth.create_account'.tr(),
                            isLoading: state.isLoading,
                            isPrimary: true,
                            onPressed: () {
                              // Terms Validation check
                              if (!state.isLogin && !state.acceptedTerms) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('auth.accept_terms_required'.tr()),
                                    backgroundColor: DesignTokens.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              if (_formKey.currentState!.validate()) {
                                viewModel.handleAuth(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text.trim(),
                                  name: !state.isLogin ? _nameController.text.trim() : null,
                                  marketingOptIn: !state.isLogin ? state.marketingOptIn : false,
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          if (state.isLogin) ...[
                            Semantics(
                              label: 'btn-forgot-password',
                              button: true,
                              child: TextButton(
                                key: const Key('login_forgot_password_button'),
                                onPressed: () => _showForgotPasswordDialog(context),
                                child: Text(
                                  'auth.forgot_password'.tr(),
                                  style: TextStyle(color: DesignTokens.primary, fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: Divider(color: DesignTokens.outlineVariant, thickness: 0.8)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing12),
                                  child: Text(
                                    'auth.or_continue_with'.tr(),
                                    style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Expanded(child: Divider(color: DesignTokens.outlineVariant, thickness: 0.8)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ModernButton(
                              key: const Key('login_google_button'),
                              label: 'Google',
                              icon: Icons.g_mobiledata,
                              isPrimary: false,
                              isLoading: state.isLoading,
                              onPressed: state.isLoading ? null : viewModel.handleGoogleSignIn,
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Toggle auth mode
                          Semantics(
                            label: 'btn-toggle-auth-mode',
                            button: true,
                            child: GestureDetector(
                              key: const Key('login_toggle_mode_button'),
                              onTap: state.isLoading
                                  ? null
                                  : () {
                                      viewModel.toggleAuthMode();
                                      _formKey.currentState?.reset();
                                    },
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 14, color: DesignTokens.textSecondary, fontWeight: FontWeight.w500),
                                  children: [
                                    TextSpan(text: state.isLogin ? "auth.no_account".tr() : 'auth.already_have_account'.tr()),
                                    TextSpan(
                                      text: state.isLogin ? 'auth.sign_up'.tr() : 'auth.sign_in'.tr(),
                                      style: const TextStyle(color: DesignTokens.primary, fontWeight: FontWeight.w700),
                                    ),
                                  ],
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
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  void _onAuthSuccess() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('auth.welcome_back_msg'.tr()), backgroundColor: DesignTokens.success, behavior: SnackBarBehavior.floating));
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController(text: _emailController.text.trim());
    final formKey = GlobalKey<FormState>();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('auth.reset_password'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('auth.reset_password_desc'.tr(), style: TextStyle(fontSize: 14, color: DesignTokens.textSecondary)),
                  const SizedBox(height: 20),
                  Form(
                    key: formKey,
                    child: TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: 'auth.email'.tr(), prefixIcon: Icon(Icons.email_outlined)),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'auth.please_enter_email'.tr();
                        if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) return 'auth.enter_valid_email'.tr();
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                Semantics(
                  label: 'btn-forgot-cancel',
                  button: true,
                  child: TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('common.cancel'.tr())),
                ),
                Semantics(
                  label: 'btn-forgot-send',
                  button: true,
                  child: ElevatedButton(
                    onPressed: isSending
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            final messenger = ScaffoldMessenger.of(dialogContext);
                            setState(() => isSending = true);
                            try {
                              await ref.read(loginViewModelProvider.notifier).resetPassword(emailController.text.trim());
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                                messenger.showSnackBar(SnackBar(content: Text('auth.reset_link_sent'.tr()), backgroundColor: DesignTokens.success));
                              }
                            } catch (e) {
                              if (dialogContext.mounted) {
                                messenger.showSnackBar(SnackBar(content: Text('auth.reset_link_failed'.tr()), backgroundColor: DesignTokens.error));
                              }
                            } finally {
                              if (mounted) setState(() => isSending = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.primary, foregroundColor: Colors.white),
                    child: isSending ? const ModernLoadingIndicator.small(color: Colors.white) : Text('auth.send'.tr()),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
