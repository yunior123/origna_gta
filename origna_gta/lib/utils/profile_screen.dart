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
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../features/auth/auth_provider.dart';
import '../../features/profile/profile_viewmodel.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final viewModel = ref.read(profileViewModelProvider.notifier);

    ref.listen(profileViewModelProvider, (previous, next) {
      if (next.isDeleted && previous?.isDeleted != true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted'), backgroundColor: Colors.green));
      } else if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!), backgroundColor: Colors.red));
      }
    });

    return Scaffold(
      appBar: AppBarFactory.simple(title: 'Settings & Profile'),
      body: userProfileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(child: Text('Error loading profile')),
        data: (userModel) {
          if (userModel == null) {
            return const Center(child: Text('Please log in'));
          }

          final isSeller = userModel.roles.contains(UserRoles.seller) || userModel.roles.contains(UserRoles.admin);
          final isAdmin = userModel.roles.contains(UserRoles.admin);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    FadeSlideIn(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFFFF6B35),
                        child: Text(
                          userModel.name.isNotEmpty ? userModel.name[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 50),
                      child: Text(userModel.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 4),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 100),
                      child: Text(userModel.email, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ),
                    const SizedBox(height: 32),
                    _buildMenuItem(
                      context,
                      icon: Icons.shopping_bag_outlined,
                      title: 'My Orders',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen())),
                    ),
                    if (isSeller) ...[
                      _buildMenuItem(
                        context,
                        icon: Icons.store_outlined,
                        title: 'Seller Orders',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerOrdersScreen())),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.account_balance,
                        title: 'Seller Dashboard',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerRegistrationScreen())),
                      ),
                    ] else
                      _buildMenuItem(
                        context,
                        icon: Icons.storefront,
                        title: 'Become a Seller',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerRegistrationScreen())),
                      ),
                    if (isAdmin)
                      _buildMenuItem(
                        context,
                        icon: Icons.admin_panel_settings,
                        title: 'Admin Panel',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen())),
                      ),
                    _buildMenuItem(
                      context,
                      icon: Icons.favorite_outline,
                      title: 'Favorites',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.location_on_outlined,
                      title: 'Address',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressManagementScreen())),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.description_outlined,
                      title: 'Terms & Conditions',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
                    ),
                    _buildMenuItem(context, icon: Icons.mail_outline, title: 'Contact Us', onTap: () => _showContactDialog(context)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: viewModel.signOut,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Sign Out', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _showDeleteAccountDialog(context, ref),
                      child: Text('Delete Account', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFFF6B35)),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Contact Us'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Have questions or need help? Reach out to us!', style: TextStyle(color: Colors.grey)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email, color: Color(0xFFFF6B35)),
              title: const Text(AppConfig.supportEmail),
              onTap: () async {
                final uri = Uri(scheme: 'mailto', path: AppConfig.supportEmail, queryParameters: {'subject': 'Support Request'});
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.language, color: Color(0xFFFF6B35)),
              title: const Text('orignaventures.ca'),
              subtitle: const Text('Website'),
              onTap: () async {
                const url = 'https://orignaventures.ca';
                if (await canLaunchUrlString(url)) {
                  await launchUrlString(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final confirmController = TextEditingController();
    bool listenerAttached = false;
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final profileState = ref.watch(profileViewModelProvider);
          final viewModel = ref.read(profileViewModelProvider.notifier);
          if (!listenerAttached) {
            ref.listen(profileViewModelProvider, (previous, next) {
              if (next.isDeleted && previous?.isDeleted != true) {
                Navigator.pop(context);
              }
            });
            listenerAttached = true;
          }

          return AlertDialog(
            title: const Text('Delete Account'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Permanent action. Type "DELETE" to confirm:', style: TextStyle(color: Colors.red)),
                TextField(
                  controller: confirmController,
                  decoration: const InputDecoration(hintText: 'DELETE'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: profileState.isLoading ? null : () => viewModel.deleteAccount(confirmController.text.trim()),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: profileState.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Delete'),
              ),
            ],
          );
        },
      ),
    );
  }
}
