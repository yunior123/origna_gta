import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:origna_gta/widgets/modern_textfield.dart';

import 'package:origna_gta/features/auth/reset_password_view_model.dart';
import 'package:flutter/widget_previews.dart';

/// Password reset flow: enter email, receive reset link, set new password.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String oobCode;

  const ResetPasswordScreen({super.key, required this.oobCode});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

/// Private providers for ResetPasswordScreen visibility toggles
final _obscurePasswordProvider = StateProvider.autoDispose<bool>((_) => true);
final _obscureConfirmProvider = StateProvider.autoDispose<bool>((_) => true);

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordViewModelProvider(widget.oobCode));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.isVerifying) {
      return const Scaffold(body: Center(child: ModernLoadingIndicator()));
    }

    if (state.isSuccess) {
      return Container(
        decoration: BoxDecoration(
          gradient: DesignTokens.backgroundGradient(isDark: isDark),
        ),
        child: Scaffold(
          backgroundColor: DesignTokens.transparent,
          appBar: AppBarFactory.simple(title: 'auth.reset_password_title'.tr()),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.spacing24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: DesignTokens.success,
                    size: 80,
                  ),
                  const SizedBox(height: DesignTokens.spacing24),
                  Text(
                    'auth.reset_success_title'.tr(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: isDark
                          ? DesignTokens.white
                          : DesignTokens.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.spacing16),
                  Text(
                    'auth.reset_success_desc'.tr(),
                    style: TextStyle(color: DesignTokens.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.spacing32),
                  Semantics(
                    button: true,
                    label: 'reset_password_go_to_login_button',
                    child: ModernButton(
                      label: 'auth.go_to_login'.tr(),
                      onPressed: () =>
                          Navigator.of(context).pushReplacementNamed('/'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: DesignTokens.backgroundGradient(isDark: isDark),
      ),
      child: Scaffold(
        backgroundColor: DesignTokens.transparent,
        appBar: AppBarFactory.simple(title: 'auth.reset_password_title'.tr()),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.spacing24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'auth.create_new_password'.tr(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? DesignTokens.white
                          : DesignTokens.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (state.userEmail != null) ...[
                    const SizedBox(height: DesignTokens.spacing8),
                    Text(
                      '${'auth.resetting_for'.tr()}: ${state.userEmail}',
                      style: TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: DesignTokens.spacing32),
                  if (state.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.spacing12),
                      margin: const EdgeInsets.only(
                        bottom: DesignTokens.spacing24,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radius8,
                        ),
                        border: Border.all(
                          color: DesignTokens.error.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: DesignTokens.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ModernTextField(
                    key: const Key('reset_password_new_password_field'),
                    semanticsLabel: 'reset_password_new_password_field',
                    label: 'auth.new_password'.tr(),
                    hint: '••••••••',
                    controller: _passwordController,
                    isPassword: ref.watch(_obscurePasswordProvider),
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: ref.watch(_obscurePasswordProvider)
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    onSuffixTap: () =>
                        ref.read(_obscurePasswordProvider.notifier).state = !ref
                            .read(_obscurePasswordProvider),
                  ),
                  const SizedBox(height: DesignTokens.spacing16),
                  ModernTextField(
                    key: const Key('reset_password_confirm_password_field'),
                    semanticsLabel: 'reset_password_confirm_password_field',
                    label: 'auth.confirm_new_password'.tr(),
                    hint: '••••••••',
                    controller: _confirmController,
                    isPassword: ref.watch(_obscureConfirmProvider),
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: ref.watch(_obscureConfirmProvider)
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    onSuffixTap: () =>
                        ref.read(_obscureConfirmProvider.notifier).state = !ref
                            .read(_obscureConfirmProvider),
                  ),
                  const SizedBox(height: DesignTokens.spacing32),
                  Semantics(
                    button: true,
                    label: 'reset_password_submit_button',
                    child: ModernButton(
                      label: 'auth.reset_password_button'.tr(),
                      isLoading: state.isLoading,
                      onPressed: () => ref
                          .read(
                            resetPasswordViewModelProvider(
                              widget.oobCode,
                            ).notifier,
                          )
                          .resetPassword(
                            _passwordController.text.trim(),
                            _confirmController.text.trim(),
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

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}


// === Widget Previews ===


// ═══ Widget Previews ═══

Widget _resetPasswordContent() =>
    previewScope(child: ResetPasswordScreen(oobCode: 'preview-oob-code'));

@Preview(name: 'Reset Password — Mobile', group: 'Auth Screens', size: Size(390, 844))
Widget previewResetPasswordScreenMobile() => previewMobile(child: _resetPasswordContent());

@Preview(name: 'Reset Password — Tablet', group: 'Auth Screens', size: Size(768, 1024))
Widget previewResetPasswordScreenTablet() => previewTablet(child: _resetPasswordContent());

@Preview(name: 'Reset Password — Desktop', group: 'Auth Screens', size: Size(1280, 800))
Widget previewResetPasswordScreenDesktop() => previewDesktop(child: _resetPasswordContent());

@Preview(name: 'Reset Password — Web', group: 'Auth Screens', size: Size(1440, 900))
Widget previewResetPasswordScreenWeb() => previewWeb(child: _resetPasswordContent());

// ── Light ────────────────────────────────────────────────────────────────────
@Preview(name: 'Reset Password Light — Mobile', group: 'Auth Screens', size: Size(390, 844))
Widget previewResetPasswordScreenLightMobile() => previewMobile(theme: previewLightTheme, child: _resetPasswordContent());

@Preview(name: 'Reset Password Light — Tablet', group: 'Auth Screens', size: Size(768, 1024))
Widget previewResetPasswordScreenLightTablet() => previewTablet(theme: previewLightTheme, child: _resetPasswordContent());

@Preview(name: 'Reset Password Light — Desktop', group: 'Auth Screens', size: Size(1280, 800))
Widget previewResetPasswordScreenLightDesktop() => previewDesktop(theme: previewLightTheme, child: _resetPasswordContent());

@Preview(name: 'Reset Password Light — Web', group: 'Auth Screens', size: Size(1440, 900))
Widget previewResetPasswordScreenLightWeb() => previewWeb(theme: previewLightTheme, child: _resetPasswordContent());

