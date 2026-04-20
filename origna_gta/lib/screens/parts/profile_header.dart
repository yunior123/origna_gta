part of '../profile_screen.dart';

class ProfileScreenLayout extends StatelessWidget {
  final AsyncValue<UserModel?> userProfileAsync;
  final AppAuthUser? currentUser;
  final bool isExportLoading;
  final ThemeMode themeMode;
  final bool isPremium;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;
  final VoidCallback onDeleteAccountRequested;
  final VoidCallback onExportData;
  final void Function(ThemeMode) onThemeChange;
  final void Function(String) onLanguageChange;

  const ProfileScreenLayout({
    super.key,
    required this.userProfileAsync,
    required this.currentUser,
    required this.isExportLoading,
    required this.themeMode,
    required this.isPremium,
    required this.onSignIn,
    required this.onSignOut,
    required this.onDeleteAccountRequested,
    required this.onExportData,
    required this.onThemeChange,
    required this.onLanguageChange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBarFactory.simple(title: 'profile.settings'.tr()),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark ? DesignTokens.darkSurface : DesignTokens.surface,
              isDark ? DesignTokens.darkSurfaceVariant : DesignTokens.white,
            ],
          ),
        ),
        child: userProfileAsync.when(
          loading: () => Center(
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [DesignTokens.primary, DesignTokens.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const ModernLoadingIndicator(
                color: DesignTokens.white,
                strokeWidth: 3,
                centered: false,
              ),
            ),
          ),
          error: (err, stack) => AnimatedEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'profile.error_loading'.tr(),
            subtitle: 'common.retry_later'.tr(),
          ),
          data: (userModel) {
            if (userModel == null) {
              return _buildNullUserState(context, isDark);
            }
            return _buildAuthenticatedContent(context, userModel, isDark);
          },
        ),
      ),
    );
  }

  Widget _buildNullUserState(BuildContext context, bool isDark) {
    if (currentUser != null) {
      final needsVerification =
          !currentUser!.emailVerified && !EnvConfig().isEmulator;
      if (needsVerification) {
        return _EmailVerificationRequiredView(user: currentUser!);
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [DesignTokens.primary, DesignTokens.secondary],
              ).createShader(bounds),
              child: const ModernLoadingIndicator(
                color: DesignTokens.white,
                strokeWidth: 3,
                centered: false,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'profile.setting_up'.tr(),
              style: TextStyle(fontSize: 16, color: DesignTokens.textSecondary),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 80, color: DesignTokens.textDisabled),
          const SizedBox(height: 16),
          Text(
            'profile.sign_in_prompt'.tr(),
            style: TextStyle(fontSize: 18, color: DesignTokens.textPrimary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 220,
            child: ModernButton(
              key: const Key('profile_sign_in_button'),
              label: 'auth.sign_in'.tr(),
              icon: Icons.login_rounded,
              onPressed: onSignIn,
              semanticsLabel: 'btn-sign-in',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticatedContent(
    BuildContext context,
    UserModel userModel,
    bool isDark,
  ) {
    final isSeller =
        userModel.roles.contains(UserRole.seller) ||
        userModel.roles.contains(UserRole.admin);
    final isAdmin = userModel.roles.contains(UserRole.admin);

    final maxWidth = ResponsiveBreakpoints.getValue<double>(
      context: context,
      mobile: double.infinity,
      mobilePlus: 500,
      tablet: 600,
      desktop: 700,
    );
    final padding = ResponsiveBreakpoints.getSpacing(context, SpacingSize.lg);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            children: [
              FadeSlideIn(
                child: ProfileHeaderCard(
                  userModel: userModel,
                  isDark: isDark,
                  isPremium: isPremium,
                  profileCompletionBar: _ProfileCompletionBar(
                    userModel: userModel,
                    isPremium: isPremium,
                  ),
                ),
              ),
              SizedBox(
                height: ResponsiveBreakpoints.getSpacing(
                  context,
                  SpacingSize.xl,
                ),
              ),

              // Navigation section
              FadeSlideIn(
                delay: const Duration(milliseconds: 50),
                child: _buildNavigationSection(
                  context,
                  isSeller: isSeller,
                  isAdmin: isAdmin,
                ),
              ),
              const SizedBox(height: 24),

              // Premium menu item
              FadeSlideIn(
                delay: const Duration(milliseconds: 75),
                child: PremiumMenuItem(isPremium: isPremium),
              ),
              const SizedBox(height: 24),

              // Settings section
              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: _buildSettingsSection(context, isDark),
              ),
              const SizedBox(height: 32),

              // Support section
              FadeSlideIn(
                delay: const Duration(milliseconds: 125),
                child: _buildSupportSection(context, isDark),
              ),
              const SizedBox(height: 24),

              // Sign out & delete
              FadeSlideIn(
                delay: const Duration(milliseconds: 150),
                child: _buildAccountActions(context),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationSection(
    BuildContext context, {
    required bool isSeller,
    required bool isAdmin,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'profile.section_navigation'.tr()),
        ProfileMenuItem(
          key: const Key('profile_my_orders_button'),
          icon: Icons.shopping_bag_outlined,
          semanticLabel: 'menu-my-orders',
          title: 'profile.my_orders'.tr(),
          subtitle: 'profile.view_purchases'.tr(),
          onTap: () => Navigator.pushNamed(context, AppRoutes.orders),
        ),
        if (FeatureFlags.kSellerOnboardingEnabled && isSeller) ...[
          ProfileMenuItem(
            key: const Key('profile_seller_orders_button'),
            icon: Icons.store_outlined,
            semanticLabel: 'menu-seller-orders',
            title: 'profile.seller_orders'.tr(),
            subtitle: 'profile.manage_sales'.tr(),
            onTap: () => Navigator.pushNamed(context, AppRoutes.sellerOrders),
          ),
          ProfileMenuItem(
            key: const Key('profile_seller_dashboard_button'),
            icon: Icons.dashboard_outlined,
            semanticLabel: 'menu-seller-dashboard',
            title: 'profile.seller_dashboard'.tr(),
            subtitle: 'profile.manage_products_account'.tr(),
            onTap: () => Navigator.pushNamed(context, AppRoutes.sellerProducts),
          ),
          ProfileMenuItem(
            key: const Key('profile_seller_analytics_button'),
            icon: Icons.analytics_outlined,
            semanticLabel: 'menu-seller-analytics',
            title: 'profile.seller_analytics'.tr(),
            subtitle: 'profile.view_sales_insights'.tr(),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.sellerAnalytics),
          ),
        ] else if (FeatureFlags.kSellerOnboardingEnabled)
          ProfileMenuItem(
            key: const Key('profile_become_seller_button'),
            icon: Icons.storefront,
            semanticLabel: 'menu-become-seller',
            title: 'profile.become_seller'.tr(),
            subtitle: 'profile.start_selling'.tr(),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.sellerRegistration),
          ),
        if (isAdmin)
          ProfileMenuItem(
            key: const Key('profile_admin_panel_button'),
            icon: Icons.admin_panel_settings,
            semanticLabel: 'menu-admin-panel',
            title: 'profile.admin_panel'.tr(),
            subtitle: 'profile.platform_management'.tr(),
            onTap: () => Navigator.pushNamed(context, AppRoutes.adminPanel),
          ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'profile.section_settings'.tr()),
        if (isPremium)
          ProfileMenuItem(
            key: const Key('profile_notifications_button'),
            icon: Icons.notifications_outlined,
            semanticLabel: 'menu-notifications',
            title: 'profile.notifications'.tr(),
            subtitle: 'profile.manage_notifications'.tr(),
            onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
        ProfileMenuItem(
          key: const Key('profile_messages_button'),
          icon: Icons.chat_bubble_outline_rounded,
          semanticLabel: 'menu-my-messages',
          title: 'chat.inbox_title'.tr(),
          subtitle: 'chat.inbox_subtitle'.tr(),
          onTap: () => Navigator.pushNamed(context, AppRoutes.chatInbox),
        ),
        ProfileMenuItem(
          key: const Key('profile_favorites_button'),
          icon: Icons.bookmark_border_rounded,
          semanticLabel: 'menu-favorites',
          title: 'favorites.my_favorites'.tr(),
          subtitle: 'profile.your_saved_products'.tr(),
          onTap: () => Navigator.pushNamed(context, AppRoutes.favorites),
        ),
        ProfileMenuItem(
          key: const Key('profile_address_button'),
          icon: Icons.location_on_outlined,
          semanticLabel: 'menu-address',
          title: 'profile.address'.tr(),
          subtitle: 'profile.manage_delivery_address'.tr(),
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.addressManagement),
        ),
        ProfileMenuItem(
          key: const Key('profile_terms_button'),
          icon: Icons.description_outlined,
          semanticLabel: 'menu-terms',
          title: 'profile.terms_conditions'.tr(),
          subtitle: 'profile.legal_agreements'.tr(),
          onTap: () => openTermsOfService(context),
        ),
        ProfileMenuItem(
          key: const Key('profile_privacy_button'),
          icon: Icons.lock_outline,
          semanticLabel: 'menu-privacy',
          title: 'profile.privacy_policy'.tr(),
          subtitle: 'profile.how_we_protect'.tr(),
          onTap: () => openPrivacyPolicy(context),
        ),
        ProfileMenuItem(
          key: const Key('profile_language_button'),
          icon: Icons.language,
          semanticLabel: 'menu-language',
          title: 'profile.language'.tr(),
          subtitle: context.locale.languageCode == 'fr'
              ? 'language.french'.tr()
              : 'language.english'.tr(),
          onTap: () {
            final newLocale = context.locale.languageCode == 'fr' ? 'en' : 'fr';
            onLanguageChange(newLocale);
          },
        ),
        ProfileThemeToggle(
          themeMode: themeMode,
          onThemeChange: onThemeChange,
          themePillBuilder:
              ({
                required IconData icon,
                required String label,
                required bool selected,
                required bool isDark,
                required VoidCallback onTap,
              }) => _ThemePill(
                icon: icon,
                label: label,
                selected: selected,
                isDark: isDark,
                onTap: onTap,
              ),
        ),
        ProfileMenuItem(
          key: const Key('profile_export_button'),
          icon: Icons.download_for_offline_outlined,
          semanticLabel: 'menu-export-data',
          title: 'profile.export_data'.tr(),
          subtitle: 'profile.export_desc'.tr(),
          isLoading: isExportLoading,
          onTap: onExportData,
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'profile.section_support'.tr()),
        ProfileMenuItem(
          key: const Key('profile_get_help_button'),
          icon: Icons.support_agent_rounded,
          semanticLabel: 'menu-get-help',
          title: 'support.get_help_title'.tr(),
          subtitle: 'support.get_help_subtitle'.tr(),
          onTap: () => Navigator.pushNamed(context, AppRoutes.support),
        ),
        _buildAppInfoSection(context, isDark),
      ],
    );
  }

  Widget _buildAccountActions(BuildContext context) {
    return Column(
      children: [
        Semantics(
          button: true,
          label: 'btn-sign-out',
          excludeSemantics: true,
          child: ModernButton(
            key: const Key('profile_sign_out_button'),
            label: 'auth.sign_out'.tr(),
            onPressed: onSignOut,
            icon: Icons.logout,
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          button: true,
          label: 'btn-delete-account',
          excludeSemantics: true,
          child: GestureDetector(
            key: const Key('profile_delete_account_button'),
            onTap: onDeleteAccountRequested,
            behavior: HitTestBehavior.opaque,
            child: Semantics(
              container: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'profile.delete_account'.tr(),
                    style: TextStyle(
                      color: DesignTokens.error,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppInfoSection(BuildContext context, bool isDark) {
    const appVersion = AppConfig.appVersion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'profile.app_info'.tr(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        ProfileMenuItem(
          key: const Key('profile_rate_app_button'),
          icon: Icons.star_outline_rounded,
          semanticLabel: 'menu-rate-app',
          title: 'profile.rate_app'.tr(),
          subtitle: 'profile.rate_app_desc'.tr(),
          onTap: () {},
        ),
        ProfileMenuItem(
          key: const Key('profile_share_app_button'),
          icon: Icons.share_outlined,
          semanticLabel: 'menu-share-app',
          title: 'profile.share_app'.tr(),
          subtitle: 'profile.share_app_desc'.tr(),
          onTap: () => SharePlus.instance.share(
            ShareParams(text: 'profile.share_text'.tr()),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? DesignTokens.darkSurfaceVariant.withValues(alpha: 0.5)
                : DesignTokens.white,
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            border: Border.all(
              color: isDark
                  ? DesignTokens.darkOutline
                  : DesignTokens.outlineVariant,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DesignTokens.primary.withValues(alpha: 0.15),
                      DesignTokens.secondary.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: DesignTokens.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'profile.app_version'.tr(namedArgs: {'version': appVersion}),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark
                        ? DesignTokens.textOnDark
                        : DesignTokens.textPrimary,
                  ),
                ),
              ),
              Text(
                AppConfig.appName,
                style: TextStyle(
                  fontSize: 13,
                  color: DesignTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: DesignTokens.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
