// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/auth/mfa_viewmodel.dart';
import 'package:origna_gta/screens/mfa_challenge_screen.dart';

import '../_preview_theme.dart';

Widget _challengeContent() => previewScope(
  extraOverrides: [
    mfaViewModelProvider.overrideWith((ref) => _PreviewMfaViewModel()),
  ],
  child: const MfaChallengeScreen(challengeToken: 'preview-token'),
);

// ── Dark ─────────────────────────────────────────────────────────────────────
@Preview(name: 'MFA Challenge Dark — Mobile', group: 'MFA Screens', size: Size(390, 844))
Widget previewMfaChallengeDarkMobile() => previewMobile(child: _challengeContent());

@Preview(name: 'MFA Challenge Dark — Tablet', group: 'MFA Screens', size: Size(768, 1024))
Widget previewMfaChallengeDarkTablet() => previewTablet(child: _challengeContent());

@Preview(name: 'MFA Challenge Dark — Desktop', group: 'MFA Screens', size: Size(1280, 800))
Widget previewMfaChallengeDarkDesktop() => previewDesktop(child: _challengeContent());

@Preview(name: 'MFA Challenge Dark — Web', group: 'MFA Screens', size: Size(1440, 900))
Widget previewMfaChallengeDarkWeb() => previewWeb(child: _challengeContent());

// ── Light ────────────────────────────────────────────────────────────────────
@Preview(name: 'MFA Challenge Light — Mobile', group: 'MFA Screens', size: Size(390, 844))
Widget previewMfaChallengeLightMobile() => previewMobile(theme: previewLightTheme, child: _challengeContent());

@Preview(name: 'MFA Challenge Light — Desktop', group: 'MFA Screens', size: Size(1280, 800))
Widget previewMfaChallengeLightDesktop() => previewDesktop(theme: previewLightTheme, child: _challengeContent());

/// No-op MFA ViewModel for previews — prevents backend calls.
class _PreviewMfaViewModel extends MfaViewModel {
  _PreviewMfaViewModel() : super(_FakeRef());

  @override
  void checkStatus() {}

  @override
  Future<bool> verifyChallenge(String token, String code) async => false;

  @override
  Future<bool> useRecoveryCode(String token, String code) async => false;
}

/// Minimal Ref stub for preview ViewModel instantiation.
class _FakeRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
