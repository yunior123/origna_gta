// coverage:ignore-file
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/features/auth/mfa_state.dart';
import 'package:origna_gta/features/auth/mfa_viewmodel.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

/// Security settings screen — lets users enable/disable MFA,
/// view login history, manage known devices, and review security alerts.
class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  List<Map<String, dynamic>> _loginHistory = [];
  List<Map<String, dynamic>> _knownDevices = [];
  List<Map<String, dynamic>> _securityAlerts = [];
  bool _isLoadingSecurity = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mfaViewModelProvider.notifier).checkStatus();
      _loadSecurityData();
    });
  }

  Future<void> _loadSecurityData() async {
    setState(() => _isLoadingSecurity = true);
    try {
      final auth = ref.read(orignabaseProvider).auth;
      final results = await Future.wait([
        auth.getLoginHistory(limit: 10),
        auth.getKnownDevices(),
        auth.getSecurityAlerts(),
      ]);
      if (mounted) {
        setState(() {
          _loginHistory = results[0];
          _knownDevices = results[1];
          _securityAlerts = results[2];
          _isLoadingSecurity = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSecurity = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mfaState = ref.watch(mfaViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SensitiveContent(
      sensitivity: ContentSensitivity.sensitive,
      child: Scaffold(
      backgroundColor: isDark ? DesignTokens.darkBackground : null,
      appBar: AppBar(
        title: Text('security.title'.tr()),
        backgroundColor: isDark ? DesignTokens.darkSurface : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                _buildMfaStatusCard(mfaState, isDark),
                if (mfaState.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: ModernLoadingIndicator(),
                  ),
                if (mfaState.errorMessage != null)
                  _buildErrorBanner(mfaState.errorMessage!),
                if (_securityAlerts.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSecurityAlerts(isDark),
                ],
                const SizedBox(height: 16),
                _buildLoginHistoryCard(isDark),
                const SizedBox(height: 16),
                _buildKnownDevicesCard(isDark),
                if (_isLoadingSecurity)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: ModernLoadingIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildMfaStatusCard(MfaState mfaState, bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
      ),
      color: isDark ? DesignTokens.darkCard : null,
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
                      Text(
                        'security.title'.tr(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'security.subtitle'.tr(),
                        style: TextStyle(fontSize: 12, color: DesignTokens.textSecondary),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: mfaState.mfaEnabled
                          ? DesignTokens.success.withValues(alpha: 0.12)
                          : DesignTokens.outlineVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          mfaState.mfaEnabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          size: 14,
                          color: mfaState.mfaEnabled ? DesignTokens.success : DesignTokens.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            mfaState.mfaEnabled
                                ? 'security.mfa_enabled'.tr()
                                : 'security.mfa_disabled'.tr(),
                            style: TextStyle(
                              color: mfaState.mfaEnabled ? DesignTokens.success : DesignTokens.textSecondary,
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
              'security.description'.tr(),
              style: TextStyle(color: DesignTokens.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            if (!mfaState.mfaEnabled)
              Semantics(
                label: 'btn-enable-mfa',
                child: FilledButton.icon(
                  onPressed: mfaState.isLoading ? null : _enableMfa,
                  icon: const Icon(Icons.security_rounded),
                  label: Text('security.enable_mfa'.tr()),
                  style: FilledButton.styleFrom(
                    backgroundColor: DesignTokens.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    ),
                  ),
                ),
              )
            else
              Semantics(
                label: 'btn-disable-mfa',
                child: FilledButton.icon(
                  onPressed: mfaState.isLoading ? null : _showDisableMfaDialog,
                  icon: const Icon(Icons.close_rounded),
                  label: Text('security.disable_mfa'.tr()),
                  style: FilledButton.styleFrom(
                    backgroundColor: DesignTokens.error,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityAlerts(bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
      ),
      color: DesignTokens.warning.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: DesignTokens.warning, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'security.security_alerts'.tr(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(_securityAlerts.length, (index) {
              final alert = _securityAlerts[index];
              final alertType = alert['type'] as String? ?? '';
              final alertDetails = alert['details'] as String? ?? '';
              final alertId = alert['id'] as String? ?? '';
              return Container(
                margin: EdgeInsets.only(top: index > 0 ? 10 : 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? DesignTokens.darkCard
                      : DesignTokens.warning.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  border: Border.all(
                    color: DesignTokens.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alertType,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    if (alertDetails.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        alertDetails,
                        style: TextStyle(
                          color: DesignTokens.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      'security.was_this_you'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: DesignTokens.warning,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Semantics(
                          label: 'btn-alert-yes-$alertId',
                          child: FilledButton(
                            onPressed: () => _acknowledgeAlert(alertId),
                            style: FilledButton.styleFrom(
                              backgroundColor: DesignTokens.success,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(DesignTokens.radius12),
                              ),
                            ),
                            child: Text('security.yes_it_was_me'.tr()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Semantics(
                          label: 'btn-alert-no-$alertId',
                          child: OutlinedButton(
                            onPressed: () => _acknowledgeAlert(alertId),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: DesignTokens.error,
                              side: BorderSide(color: DesignTokens.error),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(DesignTokens.radius12),
                              ),
                            ),
                            child: Text('common.no'.tr()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginHistoryCard(bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
      ),
      color: isDark ? DesignTokens.darkCard : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_rounded, color: DesignTokens.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'security.login_history'.tr(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loginHistory.isEmpty && !_isLoadingSecurity)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'security.no_login_history'.tr(),
                    style: TextStyle(color: DesignTokens.textSecondary, fontSize: 14),
                  ),
                ),
              )
            else
              Semantics(
                label: 'login-history-list',
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _loginHistory.length,
                  separatorBuilder: (_, __) => Divider(
                    color: DesignTokens.outlineVariant.withValues(alpha: 0.3),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final entry = _loginHistory[index];
                    final ip = entry['ip'] as String? ?? '';
                    final device = entry['device'] as String? ?? '';
                    final status = entry['status'] as String? ?? '';
                    final date = entry['date'] as String? ?? '';
                    final isSuccess = status == 'success';

                    String formattedDate = date;
                    try {
                      formattedDate = DateFormat('MMM d, yyyy HH:mm')
                          .format(DateTime.parse(date));
                    } catch (_) {}

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (device.isNotEmpty)
                                  Text(
                                    device,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                const SizedBox(height: 2),
                                Text(
                                  '${'security.ip_address'.tr()}: $ip',
                                  style: TextStyle(
                                    color: DesignTokens.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    color: DesignTokens.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSuccess
                                  ? DesignTokens.success.withValues(alpha: 0.12)
                                  : DesignTokens.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: isSuccess
                                    ? DesignTokens.success
                                    : DesignTokens.error,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKnownDevicesCard(bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
      ),
      color: isDark ? DesignTokens.darkCard : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.devices_rounded, color: DesignTokens.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'security.known_devices'.tr(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_knownDevices.isEmpty && !_isLoadingSecurity)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'security.no_devices'.tr(),
                    style: TextStyle(color: DesignTokens.textSecondary, fontSize: 14),
                  ),
                ),
              )
            else
              Semantics(
                label: 'known-devices-list',
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _knownDevices.length,
                  separatorBuilder: (_, __) => Divider(
                    color: DesignTokens.outlineVariant.withValues(alpha: 0.3),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final device = _knownDevices[index];
                    final deviceName = device['device_name'] as String? ?? '';
                    final lastUsed = device['last_used'] as String? ?? '';
                    final deviceId = device['id'] as String? ?? '';

                    String formattedDate = lastUsed;
                    try {
                      formattedDate = DateFormat('MMM d, yyyy HH:mm')
                          .format(DateTime.parse(lastUsed));
                    } catch (_) {}

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.smartphone_rounded,
                            color: DesignTokens.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  deviceName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    color: DesignTokens.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Semantics(
                            label: 'btn-remove-device-$deviceId',
                            child: IconButton(
                              onPressed: () => _removeDevice(deviceId),
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: DesignTokens.error,
                                size: 20,
                              ),
                              tooltip: 'security.remove_device'.tr(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
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
          Expanded(child: Text(message, style: TextStyle(color: DesignTokens.error))),
        ],
      ),
    );
  }

  Future<void> _enableMfa() async {
    final result = await Navigator.pushNamed(context, AppRoutes.mfaSetup);
    if (result == true && mounted) {
      ref.read(mfaViewModelProvider.notifier).checkStatus();
    }
  }

  Future<void> _acknowledgeAlert(String alertId) async {
    try {
      final auth = ref.read(orignabaseProvider).auth;
      await auth.acknowledgeAlert(alertId);
      if (mounted) {
        setState(() {
          _securityAlerts.removeWhere((a) => a['id'] == alertId);
        });
      }
    } catch (_) {}
  }

  Future<void> _removeDevice(String deviceId) async {
    try {
      final auth = ref.read(orignabaseProvider).auth;
      await auth.removeDevice(deviceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('security.device_removed'.tr()),
            backgroundColor: DesignTokens.success,
          ),
        );
        await _loadSecurityData();
      }
    } catch (_) {}
  }

  void _showDisableMfaDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('security.disable_mfa_title'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('security.disable_mfa_desc'.tr()),
            const SizedBox(height: 16),
            Semantics(
              label: 'input-disable-mfa-code',
              child: TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, letterSpacing: 6, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  labelText: 'security.totp_code'.tr(),
                  hintText: '000000',
                  counterText: '',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.length != 6) return;
              Navigator.pop(dialogContext);
              final viewModel = ref.read(mfaViewModelProvider.notifier);
              await viewModel.disable(code);
              if (mounted) {
                final newState = ref.read(mfaViewModelProvider);
                if (!newState.mfaEnabled && newState.errorMessage == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('security.mfa_disabled_success'.tr()),
                      backgroundColor: DesignTokens.success,
                    ),
                  );
                }
              }
            },
            child: Text(
              'security.disable_mfa'.tr(),
              style: const TextStyle(color: DesignTokens.error),
            ),
          ),
        ],
      ),
    );
  }
}
