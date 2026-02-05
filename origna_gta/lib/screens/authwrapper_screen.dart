import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/screens/main_screen.dart';
import 'package:origna_gta/services/splash_service.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _timedOut = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // Remove splash screen when auth state is determined OR timeout
    if (!authState.isLoading || _timedOut) {
      // Defer slightly to ensure first frame of app is painted
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SplashService.removeSplash();
      });
    }

    // If timed out, proceed to MainScreen anyway (user just won't be logged in)
    if (_timedOut && authState.isLoading) {
      return const MainScreen();
    }

    // Always show MainScreen - the HTML splash covers loading state
    // This prevents any flash between splash removal and MainScreen render
    return const MainScreen();
  }

  @override
  void initState() {
    super.initState();
    // Safety timeout: if auth takes more than 5 seconds, proceed anyway
    // This prevents infinite splash on emulator connection issues
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_timedOut) {
        final authState = ref.read(authStateProvider);
        if (authState.isLoading) {
          setState(() => _timedOut = true);
          SplashService.removeSplash();
        }
      }
    });
  }
}
