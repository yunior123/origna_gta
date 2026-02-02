import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/admin/admin_panel_screen.dart';
import 'package:origna_gta/screens/addressmanagement_screen.dart';
import 'package:origna_gta/screens/favorites_screen.dart';
import 'package:origna_gta/screens/orders_screen.dart';
import 'package:origna_gta/screens/seller_orders_screen.dart';
import 'package:origna_gta/screens/seller_registration_screen.dart';
import 'package:origna_gta/screens/terms_screen.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
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
      appBar: AppBarFactory.simple(title: 'Settings & Profile'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [isDark ? Colors.grey[900]! : Colors.grey[50]!, isDark ? Colors.grey[800]! : Colors.white],
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
              child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            ),
          ),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error loading profile', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
          data: (userModel) {
            if (userModel == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('Please log in', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                  ],
                ),
              );
            }

            final isSeller = userModel.roles.contains(UserRoles.seller) || userModel.roles.contains(UserRoles.admin);
            final isAdmin = userModel.roles.contains(UserRoles.admin);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Profile Header
                      FadeSlideIn(child: _buildProfileHeader(userModel, isDark)),
                      const SizedBox(height: 32),

                      // Main Navigation Menu
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 50),
                        child: Column(
                          children: [
                            _buildMenuItem(
                              context,
                              icon: Icons.shopping_bag_outlined,
                              title: 'My Orders',
                              subtitle: 'View your purchases',
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen())),
                            ),
                            if (isSeller) ...[
                              _buildMenuItem(
                                context,
                                icon: Icons.store_outlined,
                                title: 'Seller Orders',
                                subtitle: 'Manage your sales',
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerOrdersScreen())),
                              ),
                              _buildMenuItem(
                                context,
                                icon: Icons.dashboard_outlined,
                                title: 'Seller Dashboard',
                                subtitle: 'Manage products & account',
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerRegistrationScreen())),
                              ),
                            ] else
                              _buildMenuItem(
                                context,
                                icon: Icons.storefront,
                                title: 'Become a Seller',
                                subtitle: 'Start selling on OrignaGta',
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerRegistrationScreen())),
                              ),
                            if (isAdmin)
                              _buildMenuItem(
                                context,
                                icon: Icons.admin_panel_settings,
                                title: 'Admin Panel',
                                subtitle: 'Platform management',
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen())),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Account Settings Section
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: Column(
                          children: [
                            _buildMenuItem(
                              context,
                              icon: Icons.favorite_outline,
                              title: 'Favorites',
                              subtitle: 'Your saved products',
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
                            ),
                            _buildMenuItem(
                              context,
                              icon: Icons.location_on_outlined,
                              title: 'Addresses',
                              subtitle: 'Manage delivery addresses',
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressManagementScreen())),
                            ),
                            _buildMenuItem(
                              context,
                              icon: Icons.description_outlined,
                              title: 'Terms & Conditions',
                              subtitle: 'Legal agreements',
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
                            ),
                            _buildMenuItem(
                              context,
                              icon: Icons.mail_outline,
                              title: 'Contact Us',
                              subtitle: 'Get in touch with support',
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
                            ModernButton(label: 'Sign Out', onPressed: viewModel.signOut, icon: Icons.logout),
                            const SizedBox(height: 12),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showDeleteAccountDialog(context, ref),
                                borderRadius: BorderRadius.circular(12),
                                splashColor: Colors.red.withValues(alpha: 0.1),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: Text(
                                      'Delete Account',
                                      style: TextStyle(color: Colors.red[600], fontSize: 15, fontWeight: FontWeight.w600),
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

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800]!.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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
                      colors: [DesignTokens.primary.withValues(alpha: 0.15), DesignTokens.secondary.withValues(alpha: 0.15)],
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
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.grey[900]),
                      ),
                      if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500]))],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel userModel, bool isDark) {
    final initials = userModel.name.isNotEmpty ? userModel.name[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [DesignTokens.primary.withValues(alpha: 0.95), DesignTokens.secondary.withValues(alpha: 0.95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius20),
        boxShadow: [BoxShadow(color: DesignTokens.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userModel.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(userModel.email, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radius20)),
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
        title: Text(
          'Contact Us',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[900]),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Have questions or need help? Reach out to us!', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  const url = 'https://orignaventures.ca';
                  if (await canLaunchUrlString(url)) {
                    await launchUrlString(url, mode: LaunchMode.externalApplication);
                  }
                },
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                splashColor: DesignTokens.primary.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    children: [
                      Icon(Icons.language, color: DesignTokens.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'orignaventures.ca',
                        style: TextStyle(color: DesignTokens.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: DesignTokens.primary)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (context) => const _DeleteAccountDialog());
  }
}

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Account deleted successfully'), backgroundColor: Colors.green[600]));
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!), backgroundColor: Colors.red[400]));
      }
    });

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radius20)),
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      title: Row(
        children: [
          Icon(Icons.warning_rounded, color: Colors.red[400], size: 28),
          const SizedBox(width: 12),
          Text(
            'Delete Account',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.grey[900]),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action cannot be undone. All your data will be permanently deleted.',
              style: TextStyle(color: Colors.red[400], fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text('Type DELETE to confirm:', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                hintText: 'Type DELETE',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radius12)),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
        ),
        ModernButton(
          onPressed: confirmController.text == 'DELETE' && !profileState.isLoading ? () => viewModel.deleteAccount(confirmController.text.trim()) : null,
          label: 'Delete Account',
          isLoading: profileState.isLoading,
          backgroundColor: confirmController.text == 'DELETE' ? Colors.red[400] : Colors.grey[400],
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
