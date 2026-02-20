
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/env_config.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../features/auth/auth_provider.dart';
import '../features/profile/profile_viewmodel.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final viewModel = ref.read(profileViewModelProvider.notifier);
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
              isDark ? DesignTokens.darkSurfaceVariant : Colors.white,
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
                color: Colors.white,
                strokeWidth: 3,
                centered: false,
              ),
            ),
          ),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: DesignTokens.error),
                const SizedBox(height: 16),
                Text(
                  'profile.error_loading'.tr(),
                  style: TextStyle(color: DesignTokens.textSecondary),
                ),
              ],
            ),
          ),
          data: (userModel) {
            if (userModel == null) {
              final currentUser = ref.watch(currentUserProvider);
              if (currentUser != null) {
                // User is authenticated but has no Firestore profile
                // Check if email verification is needed
                final needsVerification =
                    !currentUser.emailVerified &&
                    !currentUser.providerData.any(
                      (p) => p.providerId == 'google.com',
                    ) &&
                    !EnvConfig().isEmulator;
                if (needsVerification) {
                  return _EmailVerificationRequiredView(user: currentUser);
                }
                // Email is verified but Firestore doc not yet created - transient state
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
                          color: Colors.white,
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
                    Semantics(
                      button: true,
                      label: 'btn-sign-in',
                      child: ElevatedButton.icon(
                      key: const Key('profile_sign_in_button'),
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.login,
                      ),
                      icon: const Icon(Icons.login_rounded),
                      label: Text('auth.sign_in'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    ),
                  ],
                ),
              );
            }

            final isSeller =
                userModel.roles.contains(UserRoles.seller) ||
                userModel.roles.contains(UserRoles.admin);
            final isAdmin = userModel.roles.contains(UserRoles.admin);

            final maxWidth = ResponsiveBreakpoints.getValue<double>(
              context: context,
              mobile: double.infinity, // 320px - full width
              mobilePlus: 500, // 480px - constrained
              tablet: 600, // 768px - comfortable
              desktop: 700, // 1024px+ - spacious
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
                      // Profile Header
                      FadeSlideIn(
                        child: _buildProfileHeader(userModel, isDark),
                      ),
                      SizedBox(
                        height: ResponsiveBreakpoints.getSpacing(
                          context,
                          SpacingSize.xl,
                        ),
                      ),

                      // Main Navigation Menu
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 50),
                        child: Column(
                          children: [
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
                                key: const Key('profile_seller_dashboard_button'),
                                icon: Icons.dashboard_outlined,
                                semanticLabel: 'menu-seller-dashboard',
                                title: 'profile.seller_dashboard'.tr(),
                                subtitle: 'profile.manage_products_account'.tr(),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.sellerRegistration,
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

                      // Premium Subscription Section
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 75),
                        child: _buildPremiumMenuItem(context, userModel.isPremium),
                      ),
                      const SizedBox(height: 24),

                      // Account Settings Section
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: Column(
                          children: [
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
                              key: const Key('profile_contact_button'),
                              icon: Icons.mail_outline,
                              semanticLabel: 'menu-contact-us',
                              title: 'profile.contact_us'.tr(),
                              subtitle: 'profile.get_in_touch'.tr(),
                              onTap: () => _showContactDialog(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Danger Zone
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 150),
                        child: Column(
                          children: [
                            Semantics(
                              button: true,
                              label: 'btn-sign-out',
                              child: ModernButton(
                                key: const Key('profile_sign_out_button'),
                                label: 'auth.sign_out'.tr(),
                                onPressed: () async {
                                  await viewModel.signOut();
                                  if (context.mounted) {
                                    Navigator.of(context).pushNamedAndRemoveUntil(
                                      AppRoutes.home,
                                      (route) => false,
                                    );
                                  }
                                },
                                icon: Icons.logout,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Semantics(
                              button: true,
                              label: 'btn-delete-account',
                              child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                key: const Key('profile_delete_account_button'),
                                onTap: () =>
                                    _showDeleteAccountDialog(context, ref),
                                borderRadius: BorderRadius.circular(12),
                                splashColor: DesignTokens.error.withValues(alpha: 0.1),
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

  Widget _buildMenuItem(
    BuildContext context, {
    Key? key,
    required IconData icon,
    String? semanticLabel,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurfaceVariant.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: isDark ? DesignTokens.darkOutline : DesignTokens.outlineVariant,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Semantics(
        button: true,
        label: semanticLabel ?? 'menu-${title.toLowerCase().replaceAll(' ', '-')}',
        child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          splashColor: DesignTokens.primary.withValues(alpha: 0.1),
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
                          color: isDark ? DesignTokens.textOnDark : DesignTokens.textPrimary,
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
                Icon(Icons.chevron_right, color: DesignTokens.textDisabled, size: 20),
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, AppRoutes.subscription);
            },
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
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
                    child: const Icon(Icons.workspace_premium, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Premium Membership',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? DesignTokens.textOnDark : DesignTokens.textPrimary,
                              ),
                            ),
                            if (isPremium) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: DesignTokens.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    fontSize: 10,
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
                              ? 'Manage subscription & notifications'
                              : 'Upgrade for no fees & seller chat — CAD \$7.86/mo',
                          style: TextStyle(fontSize: 12, color: DesignTokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: DesignTokens.textDisabled, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel userModel, bool isDark) {
    final initials = userModel.name.isNotEmpty
        ? userModel.name[0].toUpperCase()
        : 'U';

    return Builder(
      builder: (context) {
        final headerPadding = ResponsiveBreakpoints.getSpacing(
          context,
          SpacingSize.xl,
        );
        final avatarSize = ResponsiveBreakpoints.getValue<double>(
          context: context,
          mobile: 60.0, // 320px - compact
          mobilePlus: 70.0, // 480px - medium
          tablet: 80.0, // 768px - comfortable
          desktop: 90.0, // 1024px+ - spacious
        );
        final fontSize = ResponsiveBreakpoints.getValue<double>(
          context: context,
          mobile: 28.0, // 320px
          mobilePlus: 32.0, // 480px
          tablet: 36.0, // 768px
          desktop: 40.0, // 1024px+
        );

        return Container(
          padding: EdgeInsets.all(headerPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.primary.withValues(alpha: 0.95),
                DesignTokens.secondary.withValues(alpha: 0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radius20),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                userModel.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                userModel.email,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius20),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? DesignTokens.darkSurface
            : Colors.white,
        title: Text(
          'profile.contact_us'.tr(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).brightness == Brightness.dark
                ? DesignTokens.textOnDark
                : DesignTokens.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'profile.contact_us_desc'.tr(),
              style: TextStyle(color: DesignTokens.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Semantics(
              link: true,
              label: 'link-email-support',
              child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  const url = 'mailto:support@orignaventures.ca';
                  if (await canLaunchUrlString(url)) {
                    await launchUrlString(
                      url,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                splashColor: DesignTokens.primary.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        color: DesignTokens.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'support@orignaventures.ca',
                        style: TextStyle(
                          color: DesignTokens.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ),
            Semantics(
              link: true,
              label: 'link-website',
              child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  const url = 'https://orignaventures.ca';
                  if (await canLaunchUrlString(url)) {
                    await launchUrlString(
                      url,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                splashColor: DesignTokens.primary.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.language,
                        color: DesignTokens.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'orignaventures.ca',
                        style: TextStyle(
                          color: DesignTokens.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.close'.tr(), style: TextStyle(color: DesignTokens.primary)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _DeleteAccountDialog(),
    );
  }
}

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  late final TextEditingController confirmController;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileState = ref.watch(profileViewModelProvider);
    final viewModel = ref.read(profileViewModelProvider.notifier);

    ref.listen(profileViewModelProvider, (previous, next) {
      if (next.isDeleted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auth.account_deleted'.tr()),
            backgroundColor: DesignTokens.success,
          ),
        );
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: DesignTokens.error,
          ),
        );
      }
    });

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius20),
      ),
      backgroundColor: isDark ? DesignTokens.darkSurface : Colors.white,
      title: Row(
        children: [
          Icon(Icons.warning_rounded, color: DesignTokens.error, size: 28),
          const SizedBox(width: 12),
          Text(
            'profile.delete_account'.tr(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? DesignTokens.textOnDark : DesignTokens.textPrimary,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'profile.delete_warning_short'.tr(),
              style: TextStyle(
                color: DesignTokens.error,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'profile.type_delete'.tr(),
              style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                hintText: 'profile.type_delete_hint'.tr(),
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('common.cancel'.tr(), style: TextStyle(color: DesignTokens.textSecondary)),
        ),
        ModernButton(
          onPressed:
              confirmController.text == 'profile.type_delete_keyword'.tr() && !profileState.isLoading
              ? () => viewModel.deleteAccount(confirmController.text.trim())
              : null,
          label: 'profile.delete_account'.tr(),
          isLoading: profileState.isLoading,
          backgroundColor: confirmController.text == 'profile.type_delete_keyword'.tr()
              ? DesignTokens.error
              : DesignTokens.textDisabled,
        ),
      ],
    );
  }

  @override
  void dispose() {
    confirmController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    confirmController = TextEditingController();
  }
}

/// Widget shown inside ProfileScreen when user is authenticated but email is not verified
class _EmailVerificationRequiredView extends ConsumerStatefulWidget {
  final User user;
  const _EmailVerificationRequiredView({required this.user});

  @override
  ConsumerState<_EmailVerificationRequiredView> createState() =>
      _EmailVerificationRequiredViewState();
}

class _EmailVerificationRequiredViewState
    extends ConsumerState<_EmailVerificationRequiredView> {
  bool _isChecking = false;
  bool _isResending = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              FadeSlideIn(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFF3E0),
                        const Color(0xFFFFE0B2).withValues(alpha: 0.5),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 56,
                    color: Color(0xFFF57C00),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: const Duration(milliseconds: 50),
                child: Text(
                  'Verify Your Email',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? DesignTokens.textOnDark : DesignTokens.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeSlideIn(
                delay: const Duration(milliseconds: 75),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.user.email ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? DesignTokens.darkSurfaceVariant.withValues(alpha: 0.5)
                        : DesignTokens.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? DesignTokens.darkOutline : DesignTokens.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To access your settings and use all features, please verify your email:',
                        style: TextStyle(
                          fontSize: 14,
                          color: DesignTokens.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStep(
                        '1',
                        'Check your email inbox (and spam folder)',
                      ),
                      _buildStep(
                        '2',
                        'Click the verification link in the email',
                      ),
                      _buildStep(
                        '3',
                        'Return here and tap "I\'ve Verified" below',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FadeSlideIn(
                delay: const Duration(milliseconds: 150),
                child: ModernButton(
                  label: _isChecking ? 'Checking...' : "I've Verified My Email",
                  icon: Icons.check_circle_outline,
                  isLoading: _isChecking,
                  onPressed: _isChecking ? () {} : _checkVerification,
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 175),
                child: ModernButton(
                  label: _isResending
                      ? 'Sending...'
                      : 'Resend Verification Email',
                  icon: Icons.send_outlined,
                  isPrimary: false,
                  isLoading: _isResending,
                  onPressed: _isResending ? () {} : _resendEmail,
                ),
              ),
              const SizedBox(height: 20),
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: TextButton.icon(
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
                    }
                  },
                  icon: Icon(Icons.logout, size: 16, color: DesignTokens.textSecondary),
                  label: Text(
                    'Sign in with a different account',
                    style: TextStyle(
                      color: DesignTokens.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: DesignTokens.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? DesignTokens.outlineVariant : DesignTokens.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        final freshUser = FirebaseAuth.instance.currentUser;
        if (freshUser != null && freshUser.emailVerified) {
          // Email is now verified! Create the Firestore document
          await ref.read(authRepositoryProvider).ensureUserDocumentExists();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🎉 ${'profile.email_verified_snackbar'.tr()}'),
                backgroundColor: DesignTokens.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            // userProfileProvider stream will auto-update with the new Firestore document
            // ProfileScreen will automatically rebuild and show the full profile
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Email not verified yet. Check your inbox and click the verification link.',
                ),
                backgroundColor: DesignTokens.warning,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('errors.verification_error'.tr()),
            backgroundColor: DesignTokens.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.verification_sent'.tr()),
            backgroundColor: DesignTokens.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('too-many-requests')
                  ? 'Please wait before requesting another email.'
                  : 'Failed to send email. Please try again later.',
            ),
            backgroundColor: DesignTokens.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }
}
