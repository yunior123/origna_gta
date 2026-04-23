import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:origna_gta/features/admin/admin_actions_viewmodel.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

/// Private providers for AdminSecurityTab MFA setup wizard state
final _mfaSecretProvider = StateProvider.autoDispose<String?>((_) => null);
final _mfaQrCodeUriProvider = StateProvider.autoDispose<String?>((_) => null);
final _mfaBackupCodesProvider = StateProvider.autoDispose<List<String>>(
  (_) => [],
);

/// Admin security tab: MFA enforcement, rate limit config, audit log.
class AdminSecurityTab extends ConsumerStatefulWidget {
  const AdminSecurityTab({super.key});

  @override
  ConsumerState<AdminSecurityTab> createState() => _AdminSecurityTabState();
}

class _AdminSecurityTabState extends ConsumerState<AdminSecurityTab> {
  final TextEditingController _mfaCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final secret = ref.watch(_mfaSecretProvider);
    final qrCodeUri = ref.watch(_mfaQrCodeUriProvider);
    final backupCodes = ref.watch(_mfaBackupCodesProvider);
    final isActionsLoading = ref.watch(
      adminActionsViewModelProvider.select((s) => s.isLoading),
    );
    final actionsErrorMessage = ref.watch(
      adminActionsViewModelProvider.select((s) => s.errorMessage),
    );
    // Read MFA status reactively from user profile provider
    final mfaEnabled =
        ref.watch(
          userProfileProvider.select((a) => a.valueOrNull?.mfaEnabled),
        ) ??
        false;

    final securityChildren = <Widget>[
      // MFA Status Card
      Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: DesignTokens.primaryGradient,
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radius12,
                      ),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: DesignTokens.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'admin.security.title'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'admin.security.subtitle'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: mfaEnabled
                            ? DesignTokens.success.withValues(alpha: 0.12)
                            : DesignTokens.outlineVariant.withValues(
                                alpha: 0.3,
                              ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            mfaEnabled
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            size: 14,
                            color: mfaEnabled
                                ? DesignTokens.success
                                : DesignTokens.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              mfaEnabled
                                  ? 'admin.security.mfa_enabled'.tr()
                                  : 'admin.security.mfa_disabled'.tr(),
                              style: TextStyle(
                                color: mfaEnabled
                                    ? DesignTokens.success
                                    : DesignTokens.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'admin.security.description'.tr(),
                style: TextStyle(
                  color: DesignTokens.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              if (!mfaEnabled)
                FilledButton.icon(
                  onPressed: isActionsLoading ? null : _enableMfa,
                  icon: const Icon(Icons.security_rounded),
                  label: Text('admin.security.enable_mfa'.tr()),
                  style: FilledButton.styleFrom(
                    backgroundColor: DesignTokens.primary,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radius12,
                      ),
                    ),
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: isActionsLoading ? null : _disableMfa,
                  icon: const Icon(Icons.close_rounded),
                  label: Text('admin.security.disable_mfa'.tr()),
                  style: FilledButton.styleFrom(
                    backgroundColor: DesignTokens.error,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radius12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),

      // MFA Setup Instructions (if enabling)
      if (secret != null && !mfaEnabled)
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius16),
          ),
          color: DesignTokens.info.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'admin.security.step1'.tr(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'admin.security.scan_qr_desc'.tr(),
                  style: TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: DesignTokens.white,
                    child: qrCodeUri != null
                        ? QrImageView(
                            data: qrCodeUri,
                            version: QrVersions.auto,
                            size: 250,
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                          )
                        : Container(
                            width: 250,
                            height: 250,
                            color: DesignTokens.outlineVariant,
                            child: const ModernLoadingIndicator.fullScreen(),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'admin.security.enter_secret_manual'.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DesignTokens.white,
                    border: Border.all(color: DesignTokens.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          secret,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'admin.security.copy_secret'.tr(),
                        icon: const Icon(Icons.copy),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await Clipboard.setData(ClipboardData(text: secret));
                          // Auto-clear clipboard after 30 seconds for security
                          Future.delayed(
                            const Duration(seconds: 30),
                            () => Clipboard.setData(
                              const ClipboardData(text: ''),
                            ),
                          );
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'admin.security.secret_copied'.tr(),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'admin.security.step2'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'admin.security.enter_code_desc'.tr(),
                  style: const TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _mfaCodeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  decoration: InputDecoration(
                    hintText: '000000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isActionsLoading ? null : _verifyAndCompleteMfa,
                    style: FilledButton.styleFrom(
                      backgroundColor: DesignTokens.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radius12,
                        ),
                      ),
                    ),
                    child: Text('admin.security.verify_enable'.tr()),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'admin.security.step3'.tr(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'admin.security.backup_codes_desc'.tr(),
                  style: TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                if (backupCodes.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DesignTokens.warning.withValues(alpha: 0.08),
                      border: Border.all(color: DesignTokens.warning),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: backupCodes.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Text(
                                    '${index + 1}.',
                                    style: const TextStyle(
                                      color: DesignTokens.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      backupCodes[index],
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await Clipboard.setData(
                                ClipboardData(text: backupCodes.join('\n')),
                              );
                              // Auto-clear clipboard after 30 seconds for security
                              Future.delayed(
                                const Duration(seconds: 30),
                                () => Clipboard.setData(
                                  const ClipboardData(text: ''),
                                ),
                              );
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'admin.security.backup_codes_copied'.tr(),
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy),
                            label: Text('admin.security.copy_all_codes'.tr()),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

      // Error Message
      if (actionsErrorMessage != null)
        Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DesignTokens.error.withValues(alpha: 0.08),
            border: Border.all(
              color: DesignTokens.error.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: DesignTokens.error,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  actionsErrorMessage,
                  style: TextStyle(color: DesignTokens.error),
                ),
              ),
            ],
          ),
        ),

      // Loading Indicator
      if (isActionsLoading)
        Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          child: const ModernLoadingIndicator(),
        ),
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: securityChildren.length,
      itemBuilder: (context, index) => securityChildren[index],
    );
  }

  @override
  void dispose() {
    _mfaCodeController.dispose();
    super.dispose();
  }

  Future<void> _disableMfa() async {
    final disableMfaController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('admin.security.disable_mfa_title'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('admin.security.disable_mfa_desc'.tr()),
            const SizedBox(height: 16),
            Semantics(
              label: 'textfield-disable-mfa-code',
              child: TextField(
                controller: disableMfaController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'admin.security.totp_code'.tr(),
                  hintText: '000000',
                  counterText: '',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => appPop(dialogContext),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              final code = disableMfaController.text.trim();
              if (code.length != 6) return;
              appPop(dialogContext);
              final viewModel = ref.read(
                adminActionsViewModelProvider.notifier,
              );
              final success = await viewModel.disableAdminMfa(code);
              if (success && mounted) {
                // Refresh user profile to pick up MFA status change
                ref.invalidate(userProfileProvider);
                ref.read(_mfaSecretProvider.notifier).state = null;
                ref.read(_mfaQrCodeUriProvider.notifier).state = null;
                ref.read(_mfaBackupCodesProvider.notifier).state = [];
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('admin.security.mfa_disabled_success'.tr()),
                    backgroundColor: DesignTokens.success,
                  ),
                );
              }
            },
            child: Text(
              'admin.security.disable_mfa'.tr(),
              style: const TextStyle(color: DesignTokens.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enableMfa() async {
    final viewModel = ref.read(adminActionsViewModelProvider.notifier);
    final result = await viewModel.enableAdminMfa();
    if (result != null && mounted) {
      ref.read(_mfaSecretProvider.notifier).state =
          result[ApiKeys.secret] as String?;
      ref.read(_mfaQrCodeUriProvider.notifier).state =
          result[ApiKeys.provisioningUri] as String?;
      ref.read(_mfaBackupCodesProvider.notifier).state = List<String>.from(
        result[ApiKeys.backupCodes] as Iterable? ?? [],
      );
    }
  }

  Future<void> _verifyAndCompleteMfa() async {
    final code = _mfaCodeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('admin.security.invalid_code_length'.tr())),
      );
      return;
    }

    final viewModel = ref.read(adminActionsViewModelProvider.notifier);
    final success = await viewModel.verifyAdminMfa(code);
    if (success && mounted) {
      // Refresh user profile to pick up MFA status change
      ref.invalidate(userProfileProvider);
      _mfaCodeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('admin.security.mfa_enabled_success'.tr()),
          backgroundColor: DesignTokens.success,
        ),
      );
    }
  }
}
