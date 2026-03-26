import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/screens/home_screen.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/utils/preview_helpers.dart';

/// Root scaffold with bottom navigation: Home, Orders, Cart, Profile tabs.
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

/// Private provider for MainScreen timeout state
final _mainScreenTimedOutProvider = StateProvider.autoDispose<bool>(
  (_) => false,
);

class _MainScreenState extends ConsumerState<MainScreen> {
  Timer? _timeoutTimer;
  ProviderSubscription<AsyncValue<UserModel?>>? _userProfileSubscription;

  @override
  Widget build(BuildContext context) {
    final timedOut = ref.watch(_mainScreenTimedOutProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    // If profile loading takes too long, show HomeScreen without profile data
    // User remains logged in (auth session active), just without database profile
    if (timedOut && userProfileAsync.isLoading) {
      return const HomeScreen(userModel: null);
    }

    return userProfileAsync.when(
      // Show HomeScreen immediately - no loading indicator to avoid flash after splash
      loading: () => const HomeScreen(userModel: null),
      error: (error, stack) => const HomeScreen(userModel: null),
      data: (userModel) => HomeScreen(userModel: userModel),
    );
  }

  @override
  void dispose() {
    _userProfileSubscription?.close();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _userProfileSubscription = ref.listenManual(userProfileProvider, (_, next) {
      if ((next.hasValue || next.hasError) &&
          ref.read(_mainScreenTimedOutProvider) &&
          mounted) {
        ref.read(_mainScreenTimedOutProvider.notifier).state = false;
      }
    });
    // Safety timeout: if user profile takes more than 3 seconds, show home anyway
    // This prevents infinite loading if the database is slow or unresponsive
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        final userProfileAsync = ref.read(userProfileProvider);
        if (userProfileAsync.isLoading) {
          ref.read(_mainScreenTimedOutProvider.notifier).state = true;
        }
      }
    });
  }
}


// === Widget Previews ===


// ═══ Widget Previews ═══

@Preview(name: 'Main Screen — Mobile', group: 'Home Screens', size: Size(390, 844))
Widget previewMainScreenMobile() => previewMobile(child: previewScope(child: MainScreen()));

@Preview(name: 'Main Screen — Tablet', group: 'Home Screens', size: Size(768, 1024))
Widget previewMainScreenTablet() => previewTablet(child: previewScope(child: MainScreen()));

@Preview(name: 'Main Screen — Desktop', group: 'Home Screens', size: Size(1280, 800))
Widget previewMainScreenDesktop() => previewDesktop(child: previewScope(child: MainScreen()));

@Preview(name: 'Main Screen — Web', group: 'Home Screens', size: Size(1440, 900))
Widget previewMainScreenWeb() => previewWeb(child: previewScope(child: MainScreen()));

// ── Light ────────────────────────────────────────────────────────────────────
@Preview(name: 'Main Screen Light — Mobile', group: 'Home Screens', size: Size(390, 844))
Widget previewMainScreenLightMobile() => previewMobile(theme: previewLightTheme, child: previewScope(child: MainScreen()));

@Preview(name: 'Main Screen Light — Tablet', group: 'Home Screens', size: Size(768, 1024))
Widget previewMainScreenLightTablet() => previewTablet(theme: previewLightTheme, child: previewScope(child: MainScreen()));

@Preview(name: 'Main Screen Light — Desktop', group: 'Home Screens', size: Size(1280, 800))
Widget previewMainScreenLightDesktop() => previewDesktop(theme: previewLightTheme, child: previewScope(child: MainScreen()));

@Preview(name: 'Main Screen Light — Web', group: 'Home Screens', size: Size(1440, 900))
Widget previewMainScreenLightWeb() => previewWeb(theme: previewLightTheme, child: previewScope(child: MainScreen()));

