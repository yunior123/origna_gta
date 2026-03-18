// coverage:ignore-file
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/features/auth/mfa_viewmodel.dart';
import 'package:origna_gta/utils/design_tokens.dart';

/// MFA challenge screen shown when a user with MFA enabled logs in.
/// Accepts a TOTP code or recovery code to complete authentication.
class MfaChallengeScreen extends ConsumerStatefulWidget {
  const MfaChallengeScreen({required this.challengeToken, super.key});

  final String challengeToken;

  @override
  ConsumerState<MfaChallengeScreen> createState() => _MfaChallengeScreenState();
}

class _MfaChallengeScreenState extends ConsumerState<MfaChallengeScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _recoveryController = TextEditingController();
  bool _isRecoveryMode = false;
  bool _isLoading = false;
  int _attempts = 0;
  static const int _maxAttempts = 5;

  @override
  void dispose() {
    _codeController.dispose();
    _recoveryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    final code = _isRecoveryMode
        ? _recoveryController.text.trim()
        : _codeController.text.trim();

    if (code.isEmpty) return;
    if (!_isRecoveryMode && code.length != 6) return;

    setState(() => _isLoading = true);

    final viewModel = ref.read(mfaViewModelProvider.notifier);
    final success = _isRecoveryMode
        ? await viewModel.useRecoveryCode(widget.challengeToken, code)
        : await viewModel.verifyChallenge(widget.challengeToken, code);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (_) => false,
      );
      return;
    }

    final mfaState = ref.read(mfaViewModelProvider);
    _onFailedAttempt(mfaState.errorMessage ?? 'mfa.invalid_code'.tr());
  }

  void _onFailedAttempt(String message) {
    setState(() {
      _isLoading = false;
      _attempts++;
      _codeController.clear();
      _recoveryController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DesignTokens.error,
      ),
    );
  }

  void _toggleRecoveryMode() {
    setState(() {
      _isRecoveryMode = !_isRecoveryMode;
      _codeController.clear();
      _recoveryController.clear();
    });
  }

  void _navigateToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final attemptsExhausted = _attempts >= _maxAttempts;

    return SensitiveContent(
      sensitivity: ContentSensitivity.sensitive,
      child: Scaffold(
      backgroundColor: isDark ? DesignTokens.darkBackground : null,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Shield icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: DesignTokens.primaryGradient,
                    borderRadius: BorderRadius.circular(DesignTokens.radius16),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    size: 40,
                    color: DesignTokens.textOnPrimary,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'mfa.challenge_title'.tr(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  _isRecoveryMode
                      ? 'mfa.enter_recovery_code'.tr()
                      : 'mfa.enter_code'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    color: DesignTokens.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radius16),
                  ),
                  color: isDark ? DesignTokens.darkCard : null,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: attemptsExhausted
                        ? _buildAttemptsExhausted()
                        : _buildInputForm(),
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

  Widget _buildAttemptsExhausted() {
    return Column(
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 48,
          color: DesignTokens.error,
        ),
        const SizedBox(height: 16),
        Text(
          'mfa.too_many_attempts'.tr(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: DesignTokens.error,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _navigateToLogin,
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
              ),
            ),
            child: Text('mfa.back_to_login'.tr()),
          ),
        ),
      ],
    );
  }

  Widget _buildInputForm() {
    return Column(
      children: [
        if (_isRecoveryMode)
          Semantics(
            label: 'input-recovery-code',
            child: TextField(
              controller: _recoveryController,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                letterSpacing: 4,
              ),
              decoration: InputDecoration(
                hintText: 'mfa.enter_recovery_code'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                ),
                counterText: '',
              ),
            ),
          )
        else
          Semantics(
            label: 'input-mfa-code',
            child: TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 24,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                hintText: '000000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                ),
                counterText: '',
              ),
            ),
          ),

        const SizedBox(height: 20),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: Semantics(
            label: 'btn-mfa-submit',
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: DesignTokens.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DesignTokens.textOnPrimary,
                      ),
                    )
                  : Text('mfa.submit'.tr()),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Toggle recovery mode
        Semantics(
          label: 'btn-use-recovery-code',
          child: TextButton(
            onPressed: _toggleRecoveryMode,
            child: Text(
              _isRecoveryMode
                  ? 'mfa.use_totp_code'.tr()
                  : 'mfa.use_recovery_code'.tr(),
              style: TextStyle(color: DesignTokens.primary),
            ),
          ),
        ),

        // Remaining attempts indicator
        if (_attempts > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_maxAttempts - _attempts} ${'mfa.attempts_remaining'.tr()}',
              style: TextStyle(
                fontSize: 12,
                color: DesignTokens.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}
