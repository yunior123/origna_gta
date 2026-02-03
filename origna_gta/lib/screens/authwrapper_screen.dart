import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/screens/main_screen.dart';
import 'package:origna_gta/services/splash_service.dart';
import 'package:origna_gta/utils/design_tokens.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Remove splash screen when auth state is determined
    if (!authState.isLoading) {
      // Defer slightly to ensure first frame of app is painted
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SplashService.removeSplash();
      });
    }

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primary))),
      ),
      error: (error, stack) => const MainScreen(),
      data: (_) => const MainScreen(),
    );
  }
}
