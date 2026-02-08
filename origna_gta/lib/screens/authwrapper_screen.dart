import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/screens/main_screen.dart';

// Splash removal is handled entirely by index.html JS (flutter-first-frame + 5s fallback).
// Old Dart splash files backed up in lib/screens/backup/

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state so downstream widgets get the user
    ref.watch(authStateProvider);

    // Always render MainScreen immediately — HTML splash covers the gap
    return const MainScreen();
  }
}
