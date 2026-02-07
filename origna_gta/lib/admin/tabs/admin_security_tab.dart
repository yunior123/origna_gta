import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/admin/admin_actions_viewmodel.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';

class AdminSecurityTab extends ConsumerStatefulWidget {
  const AdminSecurityTab({super.key});

  @override
  ConsumerState<AdminSecurityTab> createState() => _AdminSecurityTabState();
}

class _AdminSecurityTabState extends ConsumerState<AdminSecurityTab> {
  bool _mfaEnabled = false;
  String? _secret;
  String? _qrCodeUri;
  List<String> _backupCodes = [];
  final TextEditingController _mfaCodeController = TextEditingController();
  // Backup codes visibility state - reserved for future use

  @override
  Widget build(BuildContext context) {
    final adminActionsState = ref.watch(adminActionsViewModelProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // MFA Status Card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radius16)),
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
                        borderRadius: BorderRadius.circular(DesignTokens.radius12),
                      ),
                      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Multi-Factor Authentication', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('Admin account protection', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _mfaEnabled ? DesignTokens.success.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _mfaEnabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            size: 14,
                            color: _mfaEnabled ? DesignTokens.success : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _mfaEnabled ? 'ENABLED' : 'DISABLED',
                            style: TextStyle(color: _mfaEnabled ? DesignTokens.success : Colors.grey, fontWeight: FontWeight.w700, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Protect your admin account with time-based one-time passwords (TOTP). '
                  'Required for high-risk admin actions: suspend/unsuspend sellers, update user roles, configure search.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 20),
                if (!_mfaEnabled)
                  FilledButton.icon(
                    onPressed: adminActionsState.isLoading ? null : _enableMfa,
                    icon: const Icon(Icons.security_rounded),
                    label: const Text('Enable MFA'),
                    style: FilledButton.styleFrom(
                      backgroundColor: DesignTokens.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radius12)),
                    ),
                  )
                else
                  FilledButton.icon(
                    onPressed: adminActionsState.isLoading ? null : _disableMfa,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Disable MFA'),
                    style: FilledButton.styleFrom(
                      backgroundColor: DesignTokens.error,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radius12)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // MFA Setup Instructions (if enabling)
        if (_secret != null && !_mfaEnabled)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radius16)),
            color: DesignTokens.info.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Step 1: Scan QR Code', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  const Text(
                    'Use an authenticator app (Google Authenticator, Microsoft Authenticator, Authy, etc.) '
                    'to scan this QR code:',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: _qrCodeUri != null
                          ? Image.network(
                              'https://chart.googleapis.com/chart?chs=300x300&chld=M|0&cht=qr&chl=${Uri.encodeComponent(_qrCodeUri!)}',
                              width: 250,
                              height: 250,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 250,
                                height: 250,
                                color: Colors.grey[300],
                                child: const Center(child: Text('QR Code\nUnavailable')),
                              ),
                            )
                          : Container(
                              width: 250,
                              height: 250,
                              color: Colors.grey[300],
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Or enter this secret manually:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(_secret!, style: const TextStyle(fontFamily: 'monospace', fontSize: 14, letterSpacing: 2)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Secret copied to clipboard')));
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Step 2: Verify Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Enter the 6-digit code from your authenticator app:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _mfaCodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8),
                    decoration: InputDecoration(
                      hintText: '000000',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: adminActionsState.isLoading ? null : _verifyAndCompleteMfa,
                      style: FilledButton.styleFrom(
                        backgroundColor: DesignTokens.success,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radius12)),
                      ),
                      child: const Text('Verify & Enable MFA'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Step 3: Save Backup Codes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  const Text(
                    'If you lose access to your authenticator, use these backup codes to regain access. '
                    'Each code can be used once.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  if (_backupCodes.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        border: Border.all(color: Colors.amber),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            itemCount: _backupCodes.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Text('${index + 1}.', style: const TextStyle(color: Colors.grey)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(_backupCodes[index], style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
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
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup codes copied to clipboard')));
                              },
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy All Codes'),
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
        if (adminActionsState.errorMessage != null)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DesignTokens.error.withValues(alpha: 0.08),
              border: Border.all(color: DesignTokens.error.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: DesignTokens.error, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(adminActionsState.errorMessage!, style: TextStyle(color: DesignTokens.error))),
              ],
            ),
          ),

        // Loading Indicator
        if (adminActionsState.isLoading)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _mfaCodeController.dispose();
    super.dispose();
  }

  Future<void> _disableMfa() async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Disable MFA?'),
        content: const Text(
          'Are you sure? This will remove multi-factor authentication from your admin account. '
          'You will no longer need to enter a code for sensitive admin actions.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final viewModel = ref.read(adminActionsViewModelProvider.notifier);
              final success = await viewModel.disableAdminMfa();
              if (success && mounted) {
                setState(() {
                  _mfaEnabled = false;
                  _secret = null;
                  _qrCodeUri = null;
                  _backupCodes = [];
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('MFA disabled'), backgroundColor: Colors.grey[800]));
              }
            },
            child: const Text('Disable', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _enableMfa() async {
    final viewModel = ref.read(adminActionsViewModelProvider.notifier);
    final result = await viewModel.enableAdminMfa();
    if (result != null && mounted) {
      setState(() {
        _secret = result[ApiKeys.secret];
        _qrCodeUri = result[ApiKeys.provisioningUri];
        _backupCodes = List<String>.from(result[ApiKeys.backupCodes] ?? []);
      });
    }
  }

  Future<void> _verifyAndCompleteMfa() async {
    final code = _mfaCodeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a 6-digit code')));
      return;
    }

    final viewModel = ref.read(adminActionsViewModelProvider.notifier);
    final success = await viewModel.verifyAdminMfa(code);
    if (success && mounted) {
      setState(() {
        _mfaEnabled = true;
        _mfaCodeController.clear();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('MFA enabled successfully! Save your backup codes in a secure location.'), backgroundColor: Colors.green));
    }
  }
}
