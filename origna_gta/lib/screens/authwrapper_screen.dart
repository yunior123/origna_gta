import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/screens/common_screens.dart';
import 'package:origna_gta/screens/main_screen.dart';
import 'package:origna_gta/utils/env_config.dart';
import 'package:origna_gta/utils/utils.dart';

// Splash removal is handled entirely by index.html JS (flutter-first-frame + 5s fallback).

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) {
        // Require email verification except in emulator (emulator doesn't persist emailVerified reliably)
        if (user != null && !user.emailVerified && !EnvConfig().isEmulator) {
          return const EmailVerificationRequiredScreen();
        }
        return const MainScreen();
      },
      loading: () => const MainScreen(), // HTML splash covers the gap
      error: (e, st) {
        // Log for Sentry observability — don't block the user
        AppError.log(e, stackTrace: st, context: 'auth_wrapper');
        return const MainScreen();
      },
    );
  }
}
