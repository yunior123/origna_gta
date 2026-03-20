import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/auth/mfa_viewmodel.dart';
import 'package:origna_gta/features/auth/mfa_state.dart';
import 'package:origna_gta/screens/security_settings_screen.dart';

import 'package:origna_gta/previews/_preview_theme.dart';

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
@Preview(name: 'Security MFA Enabled Dark — Mobile', group: 'Security Screens', size: Size(390, 844))
Widget previewSecurityEnabledDarkMobile() => previewMobile(child: _securityMfaEnabledContent());

@Preview(name: 'Security MFA Enabled Dark — Tablet', group: 'Security Screens', size: Size(768, 1024))
Widget previewSecurityEnabledDarkTablet() => previewTablet(child: _securityMfaEnabledContent());

@Preview(name: 'Security MFA Enabled Dark — Desktop', group: 'Security Screens', size: Size(1280, 800))
Widget previewSecurityEnabledDarkDesktop() => previewDesktop(child: _securityMfaEnabledContent());

@Preview(name: 'Security MFA Enabled Dark — Web', group: 'Security Screens', size: Size(1440, 900))
Widget previewSecurityEnabledDarkWeb() => previewWeb(child: _securityMfaEnabledContent());

// ── MFA Disabled — Dark ─────────────────────────────────────────────────────
@Preview(name: 'Security MFA Disabled Dark — Mobile', group: 'Security Screens', size: Size(390, 844))
Widget previewSecurityDisabledDarkMobile() => previewMobile(child: _securityMfaDisabledContent());

@Preview(name: 'Security MFA Disabled Dark — Desktop', group: 'Security Screens', size: Size(1280, 800))
Widget previewSecurityDisabledDarkDesktop() => previewDesktop(child: _securityMfaDisabledContent());

// ── Light ────────────────────────────────────────────────────────────────────
@Preview(name: 'Security Light — Mobile', group: 'Security Screens', size: Size(390, 844))
Widget previewSecurityLightMobile() => previewMobile(theme: previewLightTheme, child: _securityMfaDisabledContent());

@Preview(name: 'Security Light — Desktop', group: 'Security Screens', size: Size(1280, 800))
Widget previewSecurityLightDesktop() => previewDesktop(theme: previewLightTheme, child: _securityMfaDisabledContent());

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
