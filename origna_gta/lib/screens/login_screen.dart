import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/constants/validation_constants.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:origna_gta/widgets/modern_textfield.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:origna_gta/features/auth/login_state.dart';
import 'package:origna_gta/features/auth/login_viewmodel.dart';
import 'mfa_challenge_screen.dart';
import 'package:flutter/widget_previews.dart';

part 'parts/login_form_panel.dart';
part 'parts/login_google_button.dart';

final _forgotPasswordSendingProvider = StateProvider.autoDispose<bool>(
  (_) => false,
);

/// Login/register screen — composes parts from parts/ sub-files:
/// - parts/login_form_panel.dart (LoginScreenLayout)
/// - parts/login_google_button.dart (_GoogleGLogo, _GoogleGPainter, _GoogleSignInButton)
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  ProviderSubscription<LoginState>? _loginSubscription;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginViewModelProvider);
    final googleEnabled =
        ref.watch(
          googleAuthAvailabilityProvider.select((a) => a.valueOrNull?.enabled),
        ) ??
        false;
    final viewModel = ref.read(loginViewModelProvider.notifier);
    final showGoogleSignIn = !kIsWeb || googleEnabled;

    return LoginScreenLayout(
      isLogin: state.isLogin,
      isLoading: state.isLoading,
      showGoogleSignIn: showGoogleSignIn,
      obscurePassword: state.obscurePassword,
      acceptedTerms: state.acceptedTerms,
      marketingOptIn: state.marketingOptIn,
      nameController: _nameController,
      emailController: _emailController,
      passwordController: _passwordController,
      formKey: _formKey,
      fadeAnimation: _fadeAnimation,
      slideAnimation: _slideAnimation,
      onAuthToggle: () {
        viewModel.toggleAuthMode();
        _formKey.currentState?.reset();
      },
      onAuthSubmit: () {
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
            password: _passwordController.text,
            name: !state.isLogin ? _nameController.text.trim() : null,
            marketingOptIn: !state.isLogin ? state.marketingOptIn : false,
          );
        }
      },
      onGoogleSignIn: viewModel.handleGoogleSignIn,
      onAppleSignIn: viewModel.handleAppleSignIn,
      onForgotPassword: () => _showForgotPasswordDialog(context),
      onToggleObscurePassword: viewModel.toggleObscurePassword,
      onTermsChanged: (v) => viewModel.setAcceptedTerms(v ?? false),
      onMarketingOptInChanged: (v) => viewModel.setMarketingOptIn(v ?? false),
    );
  }

  @override
  void dispose() {
    _loginSubscription?.close();
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loginSubscription = ref.listenManual(loginViewModelProvider, (_, next) {
      if (!mounted) return;
      if (next.mfaRequired && next.challengeToken != null) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                MfaChallengeScreen(challengeToken: next.challengeToken!),
          ),
        );
      } else if (next.isSuccess) {
        _onAuthSuccess();
      } else if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: DesignTokens.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: DesignTokens.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  void _onAuthSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('auth.welcome_back_msg'.tr()),
        backgroundColor: DesignTokens.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, dialogRef, _) {
            final isSending = dialogRef.watch(_forgotPasswordSendingProvider);
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text('auth.reset_password'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'auth.reset_password_desc'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: formKey,
                    child: TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'auth.email'.tr(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'auth.please_enter_email'.tr();
                        }
                        if (!ValidationConstants.emailRegex.hasMatch(value)) {
                          return 'auth.enter_valid_email'.tr();
                        }
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
                  excludeSemantics: true,
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      foregroundColor: DesignTokens.textSecondary,
                    ),
                    child: Text('common.cancel'.tr()),
                  ),
                ),
                Semantics(
                  label: 'btn-forgot-send',
                  button: true,
                  excludeSemantics: true,
                  child: ModernButton(
                    label: 'auth.send'.tr(),
                    isLoading: isSending,
                    fullWidth: false,
                    height: 44,
                    onPressed: isSending
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            final messenger = ScaffoldMessenger.of(
                              dialogContext,
                            );
                            dialogRef
                                    .read(
                                      _forgotPasswordSendingProvider.notifier,
                                    )
                                    .state =
                                true;
                            try {
                              await ref
                                  .read(loginViewModelProvider.notifier)
                                  .resetPassword(emailController.text.trim());
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('auth.reset_link_sent'.tr()),
                                    backgroundColor: DesignTokens.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (dialogContext.mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'auth.reset_link_failed'.tr(),
                                    ),
                                    backgroundColor: DesignTokens.error,
                                  ),
                                );
                              }
                            } finally {
                              if (dialogContext.mounted) {
                                dialogRef
                                        .read(
                                          _forgotPasswordSendingProvider
                                              .notifier,
                                        )
                                        .state =
                                    false;
                              }
                            }
                          },
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


// === Widget Previews ===
