import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/auth/mfa_viewmodel.dart';
import 'package:origna_gta/features/auth/mfa_state.dart';
import 'package:origna_gta/screens/mfa_setup_screen.dart';

import 'package:origna_gta/previews/_preview_theme.dart';

Widget _setupContent() => previewScope(
  extraOverrides: [
    mfaViewModelProvider.overrideWith((ref) => _PreviewMfaSetupViewModel()),
  ],
  child: const MfaSetupScreen(),
);

// ── Dark ─────────────────────────────────────────────────────────────────────
@Preview(name: 'MFA Setup Dark — Mobile', group: 'MFA Screens', size: Size(390, 844))
Widget previewMfaSetupDarkMobile() => previewMobile(child: _setupContent());

@Preview(name: 'MFA Setup Dark — Tablet', group: 'MFA Screens', size: Size(768, 1024))
Widget previewMfaSetupDarkTablet() => previewTablet(child: _setupContent());

@Preview(name: 'MFA Setup Dark — Desktop', group: 'MFA Screens', size: Size(1280, 800))
Widget previewMfaSetupDarkDesktop() => previewDesktop(child: _setupContent());

@Preview(name: 'MFA Setup Dark — Web', group: 'MFA Screens', size: Size(1440, 900))
Widget previewMfaSetupDarkWeb() => previewWeb(child: _setupContent());

// ── Light ────────────────────────────────────────────────────────────────────
@Preview(name: 'MFA Setup Light — Mobile', group: 'MFA Screens', size: Size(390, 844))
Widget previewMfaSetupLightMobile() => previewMobile(theme: previewLightTheme, child: _setupContent());

@Preview(name: 'MFA Setup Light — Desktop', group: 'MFA Screens', size: Size(1280, 800))
Widget previewMfaSetupLightDesktop() => previewDesktop(theme: previewLightTheme, child: _setupContent());

/// Preview ViewModel that starts at step 1 (QR code) with mock data.
class _PreviewMfaSetupViewModel extends MfaViewModel {
  _PreviewMfaSetupViewModel() : super(_FakeRef());

  @override
  void checkStatus() {}

  @override
  Future<void> startSetup() async {
    state = MfaState(
      currentStep: 1,
      qrCodeBase64: '', // Empty = shows loading indicator in preview
      manualKey: 'JBSWY3DPEHPK3PXP',
      recoveryCodes: [
        'abc12-def34',
        'ghi56-jkl78',
        'mno90-pqr12',
        'stu34-vwx56',
        'yza78-bcd90',
      ],
    );
  }
}

class _FakeRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
