// coverage:ignore-file
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/auth/mfa_state.dart';
import 'package:origna_gta/features/auth/mfa_viewmodel.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

/// Multi-step MFA setup screen: QR scan -> verify code -> save backup codes.
class MfaSetupScreen extends ConsumerStatefulWidget {
  const MfaSetupScreen({super.key});

  @override
  ConsumerState<MfaSetupScreen> createState() => _MfaSetupScreenState();
}

class _MfaSetupScreenState extends ConsumerState<MfaSetupScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _codesSavedChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mfaViewModelProvider.notifier).startSetup();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mfaState = ref.watch(mfaViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SensitiveContent(
      sensitivity: (mfaState.currentStep == 1 || mfaState.currentStep == 3)
          ? ContentSensitivity.sensitive
          : ContentSensitivity.notSensitive,
      child: Scaffold(
      backgroundColor: isDark ? DesignTokens.darkBackground : null,
      appBar: AppBar(
        title: Text('mfa.setup_title'.tr()),
        backgroundColor: isDark ? DesignTokens.darkSurface : null,
      ),
      body: mfaState.isLoading && mfaState.currentStep == 0
          ? const Center(child: ModernLoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: _buildCurrentStep(mfaState, isDark),
                ),
              ),
            ),
    ),
    );
  }

  Widget _buildCurrentStep(MfaState mfaState, bool isDark) {
    if (mfaState.errorMessage != null && mfaState.currentStep == 0) {
      return _buildError(mfaState.errorMessage!);
    }

    switch (mfaState.currentStep) {
      case 1:
        return _buildStep1QrCode(mfaState, isDark);
      case 2:
        return _buildStep2Verify(mfaState, isDark);
      case 3:
        return _buildStep3BackupCodes(mfaState, isDark);
      case 4:
        return _buildStep4Done();
      default:
        return const Center(child: ModernLoadingIndicator());
    }
  }

  Widget _buildError(String message) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: DesignTokens.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(mfaViewModelProvider.notifier).startSetup(),
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1QrCode(MfaState mfaState, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'mfa.step1_scan'.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'mfa.step1_desc'.tr(),
          style: TextStyle(color: DesignTokens.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 24),

        // QR Code
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DesignTokens.white,
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
            ),
            child: mfaState.qrCodeBase64 != null && mfaState.qrCodeBase64!.isNotEmpty
                ? Image.memory(
                    base64Decode(mfaState.qrCodeBase64!),
                    width: 250,
                    height: 250,
                    fit: BoxFit.contain,
                  )
                : const SizedBox(
                    width: 250,
                    height: 250,
                    child: Center(child: ModernLoadingIndicator()),
                  ),
          ),
        ),
        const SizedBox(height: 20),

        // Manual key
        Text(
          'mfa.copy_manual_key'.tr(),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? DesignTokens.darkSurfaceVariant : DesignTokens.surface,
            border: Border.all(color: isDark ? DesignTokens.darkOutline : DesignTokens.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  mfaState.manualKey ?? '',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14, letterSpacing: 2),
                ),
              ),
              IconButton(
                tooltip: 'mfa.copy_manual_key'.tr(),
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(ClipboardData(text: mfaState.manualKey ?? ''));
                  // Auto-clear clipboard after 30 seconds for security
                  Future.delayed(const Duration(seconds: 30), () => Clipboard.setData(const ClipboardData(text: '')));
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('mfa.manual_key_copied'.tr())),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Next button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              ref.read(mfaViewModelProvider.notifier).goToStep(2);
            },
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
              ),
            ),
            child: Text('mfa.next'.tr()),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Verify(MfaState mfaState, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'mfa.step2_verify'.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'mfa.step2_desc'.tr(),
          style: TextStyle(color: DesignTokens.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 24),

        Semantics(
          label: 'input-mfa-setup-code',
          child: TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: '000000',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
              ),
              counterText: '',
            ),
          ),
        ),

        if (mfaState.errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignTokens.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 18, color: DesignTokens.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mfaState.errorMessage!,
                    style: TextStyle(color: DesignTokens.error, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: Semantics(
            label: 'btn-mfa-verify-setup',
            child: FilledButton(
              onPressed: mfaState.isLoading
                  ? null
                  : () {
                      final code = _codeController.text.trim();
                      if (code.length == 6) {
                        ref.read(mfaViewModelProvider.notifier).verifySetup(code);
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: DesignTokens.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                ),
              ),
              child: mfaState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('mfa.verify'.tr()),
            ),
          ),
        ),

        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {
              ref.read(mfaViewModelProvider.notifier).goToStep(1);
            },
            child: Text('common.back'.tr()),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3BackupCodes(MfaState mfaState, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'mfa.step3_backup'.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'mfa.step3_desc'.tr(),
          style: TextStyle(color: DesignTokens.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 20),

        // Warning banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DesignTokens.warning.withValues(alpha: 0.08),
            border: Border.all(color: DesignTokens.warning),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: DesignTokens.warning, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'mfa.save_codes_warning'.tr(),
                  style: TextStyle(
                    color: DesignTokens.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Recovery codes list
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? DesignTokens.darkSurfaceVariant : DesignTokens.surface,
            border: Border.all(color: isDark ? DesignTokens.darkOutline : DesignTokens.outlineVariant),
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
          ),
          child: Column(
            children: [
              ...List.generate(mfaState.recoveryCodes.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '${index + 1}.',
                        style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          mfaState.recoveryCodes[index],
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  label: 'btn-copy-backup-codes',
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await Clipboard.setData(
                        ClipboardData(text: mfaState.recoveryCodes.join('\n')),
                      );
                      // Auto-clear clipboard after 30 seconds for security
                      Future.delayed(const Duration(seconds: 30), () => Clipboard.setData(const ClipboardData(text: '')));
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('mfa.codes_copied'.tr())),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy),
                    label: Text('mfa.copy_all_codes'.tr()),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Confirm saved checkbox
        CheckboxListTile(
          value: _codesSavedChecked,
          onChanged: (val) => setState(() => _codesSavedChecked = val ?? false),
          title: Text('mfa.confirm_saved'.tr(), style: const TextStyle(fontSize: 14)),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: DesignTokens.primary,
        ),
        const SizedBox(height: 16),

        // Done button
        SizedBox(
          width: double.infinity,
          child: Semantics(
            label: 'btn-mfa-setup-done',
            child: FilledButton(
              onPressed: _codesSavedChecked
                  ? () {
                      ref.read(mfaViewModelProvider.notifier).confirmSaved();
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: DesignTokens.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                ),
              ),
              child: Text('mfa.done'.tr()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep4Done() {
    // Auto-navigate back after a brief delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('mfa.setup_complete'.tr()),
            backgroundColor: DesignTokens.success,
          ),
        );
        Navigator.pop(context, true); // true = MFA was enabled
      }
    });

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, size: 64, color: DesignTokens.success),
          const SizedBox(height: 16),
          Text(
            'mfa.setup_complete'.tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
