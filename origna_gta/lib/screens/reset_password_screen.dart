import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

import '../features/auth/reset_password_view_model.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String oobCode;

  const ResetPasswordScreen({super.key, required this.oobCode});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordViewModelProvider(widget.oobCode));

    if (state.isVerifying) {
      return const Scaffold(
        body: Center(child: ModernLoadingIndicator()),
      );
    }

    if (state.isSuccess) {
      return Scaffold(
        appBar: AppBar(title: Text('auth.reset_password_title'.tr())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacing24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, color: DesignTokens.success, size: 80),
                const SizedBox(height: DesignTokens.spacing24),
                Text(
                  'auth.reset_success_title'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spacing16),
                Text(
                  'auth.reset_success_desc'.tr(),
                  style: TextStyle(color: DesignTokens.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spacing32),
                ModernButton(
                  label: 'auth.go_to_login'.tr(),
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('auth.reset_password_title'.tr())),
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
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                if (state.userEmail != null) ...[
                  const SizedBox(height: DesignTokens.spacing8),
                  Text(
                    '${'auth.resetting_for'.tr()}: ${state.userEmail}',
                    style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: DesignTokens.spacing32),
                if (state.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.spacing12),
                    margin: const EdgeInsets.only(bottom: DesignTokens.spacing24),
                    decoration: BoxDecoration(
                      color: DesignTokens.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radius8),
                      border: Border.all(color: DesignTokens.error.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: DesignTokens.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (state.userEmail != null) ...[
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'auth.new_password'.tr(),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacing16),
                  TextField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'auth.confirm_new_password'.tr(),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacing32),
                  ModernButton(
                    label: 'auth.reset_password_button'.tr(),
                    isLoading: state.isLoading,
                    onPressed: () => ref
                        .read(resetPasswordViewModelProvider(widget.oobCode).notifier)
                        .resetPassword(
                          _passwordController.text.trim(),
                          _confirmController.text.trim(),
                        ),
                  ),
                ] else ...[
                  ModernButton(
                    label: 'auth.go_to_login'.tr(),
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
                  ),
                ],
              ],
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
