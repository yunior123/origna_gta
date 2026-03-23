import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/env_config.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:origna_gta/widgets/modern_textfield.dart';
import 'package:share_plus/share_plus.dart';

import 'package:origna_gta/core/theme_provider.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/profile/profile_viewmodel.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:origna_gta/widgets/profile/premium_menu_item.dart';
import 'package:origna_gta/widgets/profile/profile_header_card.dart';
import 'package:origna_gta/widgets/profile/profile_menu_item.dart';
import 'package:origna_gta/widgets/profile/profile_theme_toggle.dart';

part 'parts/profile_header.dart';
part 'parts/profile_settings_section.dart';

/// Documentation for ProfileScreen
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  ProviderSubscription<ProfileState>? _profileSubscription;

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final isExportLoading = ref.watch(
      profileViewModelProvider.select((s) => s.isLoading),
    );
    final viewModel = ref.read(profileViewModelProvider.notifier);
    final currentUser = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isPremium =
        ref.watch(
          subscriptionStreamProvider.select((a) => a.valueOrNull?.isPremium),
        ) ??
        userProfileAsync.valueOrNull?.isPremium ??
        false;

    return ProfileScreenLayout(
      userProfileAsync: userProfileAsync,
      currentUser: currentUser,
      isExportLoading: isExportLoading,
      themeMode: themeMode,
      isPremium: isPremium,
      onSignIn: () => Navigator.pushNamed(context, AppRoutes.login),
      onSignOut: () async {
        await viewModel.signOut();
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
        }
      },
      onDeleteAccountRequested: () => showDialog(
        context: context,
        builder: (context) => const _DeleteAccountDialog(),
      ),
      onExportData: () => viewModel.exportData(),
      onThemeChange: (mode) =>
          ref.read(themeModeProvider.notifier).state = mode,
      onLanguageChange: (lang) async {
        final newLocale = Locale(lang);
        await context.setLocale(newLocale);
        await viewModel.updateLanguage(lang);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _profileSubscription = ref.listenManual(profileViewModelProvider, (
      _,
      next,
    ) {
      if (!mounted) return;
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: DesignTokens.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: DesignTokens.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _profileSubscription?.close();
    super.dispose();
  }
}

/// Documentation for ProfileScreenLayout
