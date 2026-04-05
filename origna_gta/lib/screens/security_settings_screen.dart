import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/features/auth/mfa_state.dart';
import 'package:origna_gta/features/auth/mfa_viewmodel.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/utils/app_logger.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

part 'parts/security_mfa_section.dart';
part 'parts/security_alerts_section.dart';
part 'parts/security_login_history_section.dart';
part 'parts/security_devices_section.dart';

/// Security data loaded via Riverpod provider instead of manual setState.
final _securityDataProvider =
    FutureProvider.autoDispose<
      ({
        List<Map<String, dynamic>> loginHistory,
        List<Map<String, dynamic>> knownDevices,
        List<Map<String, dynamic>> securityAlerts,
      })
    >((ref) async {
      final auth = ref.watch(orignabaseProvider).auth;
      final results = await Future.wait<List<Map<String, dynamic>>>([
        auth.getLoginHistory(limit: 10),
        auth.getKnownDevices(),
        auth.getSecurityAlerts(),
      ]);
      return (
        loginHistory: results[0],
        knownDevices: results[1],
        securityAlerts: results[2],
      );
    });

/// Security settings screen — lets users enable/disable MFA,
/// view login history, manage known devices, and review security alerts.
class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends ConsumerState<SecuritySettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mfaViewModelProvider.notifier).checkStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mfaState = ref.watch(mfaViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final loginHistory =
        ref.watch(
          _securityDataProvider.select((a) => a.valueOrNull?.loginHistory),
        ) ??
        [];
    final knownDevices =
        ref.watch(
          _securityDataProvider.select((a) => a.valueOrNull?.knownDevices),
        ) ??
        [];
    final securityAlerts =
        ref.watch(
          _securityDataProvider.select((a) => a.valueOrNull?.securityAlerts),
        ) ??
        [];
    final isLoadingSecurity = ref.watch(
      _securityDataProvider.select((a) => a.isLoading),
    );

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
                  _buildMfaStatusCard(
                    mfaState,
                    isDark,
                    _enableMfa,
                    _showDisableMfaDialog,
                  ),
                  if (mfaState.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: ModernLoadingIndicator(),
                    ),
                  if (mfaState.errorMessage != null)
                    _buildErrorBanner(mfaState.errorMessage!),
                  if (securityAlerts.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSecurityAlerts(
                      securityAlerts,
                      isDark,
                      _acknowledgeAlert,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildLoginHistoryCard(
                    loginHistory,
                    isLoadingSecurity,
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildKnownDevicesCard(
                    knownDevices,
                    isLoadingSecurity,
                    isDark,
                    _removeDevice,
                  ),
                  if (isLoadingSecurity)
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
      // Invalidate provider to reload security data
      ref.invalidate(_securityDataProvider);
    } catch (e) {
      AppLogger.w(
        'SecuritySettings: failed to acknowledge alert',
        tag: 'security',
        error: e,
      );
    }
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
        // Invalidate provider to reload security data
        ref.invalidate(_securityDataProvider);
      }
    } catch (e) {
      AppLogger.w(
        'SecuritySettings: failed to remove device',
        tag: 'security',
        error: e,
      );
    }
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
                style: const TextStyle(
                  fontSize: 20,
                  letterSpacing: 6,
                  fontFamily: 'monospace',
                ),
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
          Semantics(
            button: true,
            label: 'btn-dialog-cancel',
            child: TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('common.cancel'.tr()),
            ),
          ),
          Semantics(
            button: true,
            label: 'btn-dialog-confirm-disable-mfa',
            child: TextButton(
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
          ),
        ],
      ),
    );
  }
}

// ═══ Widget Previews ═══

Widget _securityMfaEnabledContent() => previewScope(
  extraOverrides: [
    mfaViewModelProvider.overrideWith(
      (ref) => _PreviewSecurityViewModel(mfaEnabled: true),
    ),
  ],
  child: const SecuritySettingsScreen(),
);

Widget _securityMfaDisabledContent() => previewScope(
  extraOverrides: [
    mfaViewModelProvider.overrideWith(
      (ref) => _PreviewSecurityViewModel(mfaEnabled: false),
    ),
  ],
  child: const SecuritySettingsScreen(),
);

// ── MFA Enabled — Dark ──────────────────────────────────────────────────────
@Preview(
  name: 'Security MFA Enabled Dark — Mobile',
  group: 'Security Screens',
  size: Size(390, 844),
)
Widget previewSecurityEnabledDarkMobile() =>
    previewMobile(child: _securityMfaEnabledContent());

@Preview(
  name: 'Security MFA Enabled Dark — Tablet',
  group: 'Security Screens',
  size: Size(768, 1024),
)
Widget previewSecurityEnabledDarkTablet() =>
    previewTablet(child: _securityMfaEnabledContent());

@Preview(
  name: 'Security MFA Enabled Dark — Desktop',
  group: 'Security Screens',
  size: Size(1280, 800),
)
Widget previewSecurityEnabledDarkDesktop() =>
    previewDesktop(child: _securityMfaEnabledContent());

@Preview(
  name: 'Security MFA Enabled Dark — Web',
  group: 'Security Screens',
  size: Size(1440, 900),
)
Widget previewSecurityEnabledDarkWeb() =>
    previewWeb(child: _securityMfaEnabledContent());

// ── MFA Disabled — Dark ─────────────────────────────────────────────────────
@Preview(
  name: 'Security MFA Disabled Dark — Mobile',
  group: 'Security Screens',
  size: Size(390, 844),
)
Widget previewSecurityDisabledDarkMobile() =>
    previewMobile(child: _securityMfaDisabledContent());

@Preview(
  name: 'Security MFA Disabled Dark — Desktop',
  group: 'Security Screens',
  size: Size(1280, 800),
)
Widget previewSecurityDisabledDarkDesktop() =>
    previewDesktop(child: _securityMfaDisabledContent());

// ── Light ────────────────────────────────────────────────────────────────────
@Preview(
  name: 'Security Light — Mobile',
  group: 'Security Screens',
  size: Size(390, 844),
)
Widget previewSecurityLightMobile() => previewMobile(
  theme: previewLightTheme,
  child: _securityMfaDisabledContent(),
);

@Preview(
  name: 'Security Light — Desktop',
  group: 'Security Screens',
  size: Size(1280, 800),
)
Widget previewSecurityLightDesktop() => previewDesktop(
  theme: previewLightTheme,
  child: _securityMfaDisabledContent(),
);

/// Preview ViewModel for security settings — no backend calls.
class _PreviewSecurityViewModel extends MfaViewModel {
  final bool _mfaEnabled;

  _PreviewSecurityViewModel({required bool mfaEnabled})
    : _mfaEnabled = mfaEnabled,
      super(_FakeRef());

  @override
  void checkStatus() {
    state = MfaState(mfaEnabled: _mfaEnabled);
  }
}

class _FakeRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
