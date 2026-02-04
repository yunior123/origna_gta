import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/screens/home_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    // Safety timeout: if user profile takes more than 3 seconds, show home anyway
    // This prevents infinite loading if Firestore is slow or unresponsive
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final userProfileAsync = ref.read(userProfileProvider);
        if (userProfileAsync.isLoading) {
          setState(() => _timedOut = true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    // If profile loading takes too long, show HomeScreen without profile data
    // User remains logged in (Firebase Auth), just without Firestore profile
    if (_timedOut && userProfileAsync.isLoading) {
      return const HomeScreen(userModel: null);
    }

    return userProfileAsync.when(
      loading: () => Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1F235A), Color(0xFF2F3B8F), Color(0xFF764BA2)],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
          child: const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
        ),
      ),
      error: (error, stack) => const HomeScreen(userModel: null),
      data: (userModel) => HomeScreen(userModel: userModel),
    );
  }
}
