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
                          colors: [
                            DesignTokens.primary,
                            DesignTokens.secondary,
                          ],
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
                        style: TextStyle(
                          fontSize: 16,
                          color: DesignTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: DesignTokens.textDisabled,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'profile.sign_in_prompt'.tr(),
                      style: TextStyle(
                        fontSize: 18,
                        color: DesignTokens.textPrimary,
                      ),
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
            final padding = ResponsiveBreakpoints.getSpacing(
              context,
              SpacingSize.lg,
            );

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    children: [
                      FadeSlideIn(
                        child: _buildProfileHeader(
                          userModel,
                          isDark,
                          isPremium: isPremium,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveBreakpoints.getSpacing(
                          context,
                          SpacingSize.xl,
                        ),
                      ),

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 50),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              context,
                              'profile.section_navigation'.tr(),
                            ),
                            _buildMenuItem(
                              context,
                              key: const Key('profile_my_orders_button'),
                              icon: Icons.shopping_bag_outlined,
                              semanticLabel: 'menu-my-orders',
                              title: 'profile.my_orders'.tr(),
                              subtitle: 'profile.view_purchases'.tr(),
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.orders,
                              ),
                            ),
                            if (isSeller) ...[
                              _buildMenuItem(
                                context,
                                key: const Key('profile_seller_orders_button'),
                                icon: Icons.store_outlined,
                                semanticLabel: 'menu-seller-orders',
                                title: 'profile.seller_orders'.tr(),
                                subtitle: 'profile.manage_sales'.tr(),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.sellerOrders,
                                ),
                              ),
                              _buildMenuItem(
                                context,
                                key: const Key(
                                  'profile_seller_dashboard_button',
                                ),
                                icon: Icons.dashboard_outlined,
                                semanticLabel: 'menu-seller-dashboard',
                                title: 'profile.seller_dashboard'.tr(),
                                subtitle: 'profile.manage_products_account'
                                    .tr(),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.sellerProducts,
                                ),
                              ),
                              _buildMenuItem(
                                context,
                                key: const Key(
                                  'profile_seller_analytics_button',
                                ),
                                icon: Icons.analytics_outlined,
                                semanticLabel: 'menu-seller-analytics',
                                title: 'profile.seller_analytics'.tr(),
                                subtitle: 'profile.view_sales_insights'.tr(),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.sellerAnalytics,
                                ),
                              ),
                            ] else
                              _buildMenuItem(
                                context,
                                key: const Key('profile_become_seller_button'),
                                icon: Icons.storefront,
                                semanticLabel: 'menu-become-seller',
                                title: 'profile.become_seller'.tr(),
                                subtitle: 'profile.start_selling'.tr(),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.sellerRegistration,
                                ),
                              ),
                            if (isAdmin)
                              _buildMenuItem(
                                context,
                                key: const Key('profile_admin_panel_button'),
                                icon: Icons.admin_panel_settings,
                                semanticLabel: 'menu-admin-panel',
                                title: 'profile.admin_panel'.tr(),
                                subtitle: 'profile.platform_management'.tr(),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.adminPanel,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 75),
                        child: _buildPremiumMenuItem(context, isPremium),
                      ),
                      const SizedBox(height: 24),

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              context,
                              'profile.section_settings'.tr(),
                            ),
                            if (isPremium)
                              _buildMenuItem(
                                context,
                                key: const Key('profile_notifications_button'),
                                icon: Icons.notifications_outlined,
                                semanticLabel: 'menu-notifications',
                                title: 'profile.notifications'.tr(),
                                subtitle: 'profile.manage_notifications'.tr(),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.notifications,
                                ),
                              ),
                            _buildMenuItem(
                              context,
                              key: const Key('profile_messages_button'),
                              icon: Icons.chat_bubble_outline_rounded,
                              semanticLabel: 'menu-my-messages',
                              title: 'chat.inbox_title'.tr(),
                              subtitle: 'chat.inbox_subtitle'.tr(),
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.chatInbox,
                              ),
                            ),
                            _buildMenuItem(
                              context,
                              key: const Key('profile_favorites_button'),
                              icon: Icons.bookmark_border_rounded,
                              semanticLabel: 'menu-favorites',
                              title: 'favorites.my_favorites'.tr(),
                              subtitle: 'profile.your_saved_products'.tr(),
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.favorites,
                              ),
                            ),
                            _buildMenuItem(
                              context,
                              key: const Key('profile_address_button'),
                              icon: Icons.location_on_outlined,
                              semanticLabel: 'menu-address',
                              title: 'profile.address'.tr(),
                              subtitle: 'profile.manage_delivery_address'.tr(),
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.addressManagement,
                              ),
                            ),
                            _buildMenuItem(
                              context,
                              key: const Key('profile_terms_button'),
                              icon: Icons.description_outlined,
                              semanticLabel: 'menu-terms',
                              title: 'profile.terms_conditions'.tr(),
                              subtitle: 'profile.legal_agreements'.tr(),
                              onTap: () => openTermsOfService(context),
                            ),
                            _buildMenuItem(
                              context,
                              key: const Key('profile_privacy_button'),
                              icon: Icons.lock_outline,
                              semanticLabel: 'menu-privacy',
                              title: 'profile.privacy_policy'.tr(),
                              subtitle: 'profile.how_we_protect'.tr(),
                              onTap: () => openPrivacyPolicy(context),
                            ),
                            _buildMenuItem(
                              context,
                              key: const Key('profile_language_button'),
                              icon: Icons.language,
                              semanticLabel: 'menu-language',
                              title: 'profile.language'.tr(),
                              subtitle: context.locale.languageCode == 'fr'
                                  ? 'language.french'.tr()
                                  : 'language.english'.tr(),
                              onTap: () {
                                final newLocale =
                                    context.locale.languageCode == 'fr'
                                    ? 'en'
                                    : 'fr';
                                onLanguageChange(newLocale);
                              },
                            ),
                            _buildThemeToggle(context, isDark),
                            _buildMenuItem(
                              context,
                              key: const Key('profile_export_button'),
                              icon: Icons.download_for_offline_outlined,
                              semanticLabel: 'menu-export-data',
                              title: 'profile.export_data'.tr(),
                              subtitle: 'profile.export_desc'.tr(),
                              isLoading: isExportLoading,
                              onTap: onExportData,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 125),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              context,
                              'profile.section_support'.tr(),
                            ),
                            _buildMenuItem(
                              context,
                              key: const Key('profile_get_help_button'),
                              icon: Icons.support_agent_rounded,
                              semanticLabel: 'menu-get-help',
                              title: 'support.get_help_title'.tr(),
                              subtitle: 'support.get_help_subtitle'.tr(),
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.support,
                              ),
                            ),
                            _buildAppInfoSection(context, isDark),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 150),
                        child: Column(
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
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
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppInfoSection(BuildContext context, bool isDark) {
    const appVersion = '1.1.0';

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
        _buildMenuItem(
          context,
          key: const Key('profile_rate_app_button'),
          icon: Icons.star_outline_rounded,
          semanticLabel: 'menu-rate-app',
          title: 'profile.rate_app'.tr(),
          subtitle: 'profile.rate_app_desc'.tr(),
          onTap: () {},
        ),
        _buildMenuItem(
          context,
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
                'OrignaGTA',
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

  Widget _buildMenuItem(
    BuildContext context, {
    Key? key,
    required IconData icon,
    String? semanticLabel,
    required String title,
    String? subtitle,
    bool isLoading = false,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
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
        boxShadow: [
          BoxShadow(
            color: DesignTokens.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Semantics(
        button: true,
        label:
            semanticLabel ?? 'menu-${title.toLowerCase().replaceAll(' ', '-')}',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          behavior: HitTestBehavior.opaque,
          child: Semantics(
            container: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    child: Icon(icon, color: DesignTokens.primary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? DesignTokens.textOnDark
                                : DesignTokens.textPrimary,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: DesignTokens.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isLoading)
                    const ModernLoadingIndicator.small()
                  else
                    Icon(
                      Icons.chevron_right,
                      color: DesignTokens.textDisabled,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumMenuItem(BuildContext context, bool isPremium) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.primary.withValues(alpha: isPremium ? 0.1 : 0.06),
            DesignTokens.secondary.withValues(alpha: isPremium ? 0.1 : 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: DesignTokens.primary.withValues(alpha: isPremium ? 0.3 : 0.15),
          width: isPremium ? 1.5 : 1,
        ),
      ),
      child: Semantics(
        button: true,
        label: 'menu-premium',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(context, AppRoutes.subscription);
          },
          behavior: HitTestBehavior.opaque,
          child: Semantics(
            container: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [DesignTokens.primary, DesignTokens.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(DesignTokens.radius8),
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      color: DesignTokens.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'subscription.premium_label'.tr(),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? DesignTokens.textOnDark
                                    : DesignTokens.textPrimary,
                              ),
                            ),
                            if (isPremium) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: DesignTokens.success.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'subscription.status_active'.tr(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: DesignTokens.success,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPremium
                              ? 'subscription.menu_manage_desc'.tr()
                              : 'subscription.menu_upgrade_desc'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: DesignTokens.textDisabled,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    UserModel userModel,
    bool isDark, {
    required bool isPremium,
  }) {
    final initials = userModel.name.isNotEmpty
        ? userModel.name[0].toUpperCase()
        : 'U';
    final isSeller =
        userModel.roles.contains(UserRole.seller) ||
        userModel.roles.contains(UserRole.admin);
    final isAdmin = userModel.roles.contains(UserRole.admin);

    return Builder(
      builder: (context) {
        final headerPadding = ResponsiveBreakpoints.getSpacing(
          context,
          SpacingSize.xl,
        );
        final avatarSize = ResponsiveBreakpoints.getValue<double>(
          context: context,
          mobile: 76.0,
          mobilePlus: 86.0,
          tablet: 96.0,
          desktop: 106.0,
        );
        final fontSize = ResponsiveBreakpoints.getValue<double>(
          context: context,
          mobile: 32.0,
          mobilePlus: 36.0,
          tablet: 40.0,
          desktop: 44.0,
        );

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                DesignTokens.gradientStart,
                DesignTokens.gradientMiddle,
                DesignTokens.gradientEnd,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radius20),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.primary.withValues(alpha: 0.45),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: DesignTokens.secondary.withValues(alpha: 0.2),
                blurRadius: 44,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Decorative blob — top right (cyan)
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        DesignTokens.accent.withValues(alpha: 0.28),
                        DesignTokens.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Decorative blob — bottom left (coral)
              Positioned(
                bottom: -15,
                left: -15,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        DesignTokens.tertiary.withValues(alpha: 0.22),
                        DesignTokens.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: EdgeInsets.all(headerPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar with triple concentric glow rings
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Outermost pulse ring — golden for premium
                        Container(
                          width: avatarSize + 32,
                          height: avatarSize + 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPremium
                                ? DesignTokens.warning.withValues(alpha: 0.1)
                                : DesignTokens.white.withValues(alpha: 0.06),
                          ),
                        ),
                        // Middle ring
                        Container(
                          width: avatarSize + 16,
                          height: avatarSize + 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: DesignTokens.white.withValues(alpha: 0.1),
                            border: Border.all(
                              color: isPremium
                                  ? DesignTokens.warning.withValues(alpha: 0.5)
                                  : DesignTokens.white.withValues(alpha: 0.18),
                              width: isPremium ? 1.5 : 1,
                            ),
                          ),
                        ),
                        // Inner avatar circle
                        Container(
                          width: avatarSize,
                          height: avatarSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                DesignTokens.white.withValues(alpha: 0.3),
                                DesignTokens.white.withValues(alpha: 0.14),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: DesignTokens.white.withValues(alpha: 0.5),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: DesignTokens.black.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 22,
                                offset: const Offset(0, 8),
                              ),
                              if (isPremium)
                                BoxShadow(
                                  color: DesignTokens.warning.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: TextStyle(
                                fontSize: fontSize,
                                color: DesignTokens.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -2,
                              ),
                            ),
                          ),
                        ),
                        // Premium crown badge — bottom-right of avatar
                        if (isPremium)
                          Positioned(
                            right: (avatarSize + 32) / 2 - avatarSize / 2 - 2,
                            bottom: (avatarSize + 32) / 2 - avatarSize / 2 - 2,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    DesignTokens.warning,
                                    DesignTokens.tertiary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: DesignTokens.warning.withValues(
                                      alpha: 0.6,
                                    ),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                                border: Border.all(
                                  color: DesignTokens.white,
                                  width: 2,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.workspace_premium,
                                  size: 14,
                                  color: DesignTokens.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      userModel.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: DesignTokens.white,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      userModel.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: DesignTokens.white.withValues(alpha: 0.72),
                        letterSpacing: 0.1,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isAdmin || isSeller) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: DesignTokens.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAdmin
                                  ? Icons.admin_panel_settings_rounded
                                  : Icons.storefront_rounded,
                              color: DesignTokens.white,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isAdmin ? 'Admin' : 'Seller',
                              style: const TextStyle(
                                color: DesignTokens.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _ProfileCompletionBar(
                      userModel: userModel,
                      isPremium: isPremium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _buildThemeToggle(BuildContext context, bool isDark) {
    final themeMode = this.themeMode;

    return Container(
      key: const Key('profile_theme_button'),
      margin: const EdgeInsets.only(bottom: 12),
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
        boxShadow: [
          BoxShadow(
            color: DesignTokens.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Semantics(
        label: 'menu-appearance',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                child: Icon(
                  themeMode == ThemeMode.dark
                      ? Icons.dark_mode_rounded
                      : themeMode == ThemeMode.light
                      ? Icons.light_mode_rounded
                      : Icons.brightness_auto_rounded,
                  color: DesignTokens.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'profile.theme'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isDark
                            ? DesignTokens.textOnDark
                            : DesignTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'profile.theme_desc'.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 3-segment pill toggle: Light | System | Dark
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? DesignTokens.darkSurface
                      : DesignTokens.surfaceVariant,
                  borderRadius: BorderRadius.circular(DesignTokens.radius20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ThemePill(
                      icon: Icons.light_mode_rounded,
                      label: 'profile.theme_light'.tr(),
                      selected: themeMode == ThemeMode.light,
                      isDark: isDark,
                      onTap: () => onThemeChange(ThemeMode.light),
                    ),
                    _ThemePill(
                      icon: Icons.brightness_auto_rounded,
                      label: 'profile.theme_system'.tr(),
                      selected: themeMode == ThemeMode.system,
                      isDark: isDark,
                      onTap: () => onThemeChange(ThemeMode.system),
                    ),
                    _ThemePill(
                      icon: Icons.dark_mode_rounded,
                      label: 'profile.theme_dark'.tr(),
                      selected: themeMode == ThemeMode.dark,
                      isDark: isDark,
                      onTap: () => onThemeChange(ThemeMode.dark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
