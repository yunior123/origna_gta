import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/addressmanagement_screen.dart';
import 'package:origna_gta/constants.dart';
import 'package:origna_gta/favorites_screen.dart';
import 'package:origna_gta/orders_screen.dart';
import 'package:origna_gta/seller_orders_screen.dart';
import 'package:origna_gta/seller_registration_screen.dart';
import 'package:origna_gta/terms_screen.dart';
import 'package:origna_gta/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: user == null
          ? const Center(child: Text('Please log in'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                if (userData == null) {
                  return const Center(child: Text('User data not found'));
                }

                final userModel = UserModel.fromMap(userData);
                final name = userModel.name;
                final email = userModel.email;
                final isSeller = userModel.roles.contains(UserRoles.seller) ||
                    userModel.roles.contains(UserRoles.admin);

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFFFF6B35),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(email, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                          const SizedBox(height: 32),
                          _buildMenuItem(
                            context,
                            icon: Icons.shopping_bag_outlined,
                            title: 'My Orders',
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
                            },
                          ),
                          if (isSeller) ...[
                            _buildMenuItem(
                              context,
                              icon: Icons.store_outlined,
                              title: 'Seller Orders',
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerOrdersScreen()));
                              },
                            ),
                            _buildMenuItem(
                              context,
                              icon: Icons.account_balance,
                              title: 'Seller Dashboard',
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerRegistrationScreen()));
                              },
                            ),
                          ] else
                            _buildMenuItem(
                              context,
                              icon: Icons.storefront,
                              title: 'Become a Seller',
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerRegistrationScreen()));
                              },
                            ),
                          _buildMenuItem(
                            context,
                            icon: Icons.favorite_outline,
                            title: 'Favorites',
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
                            },
                          ),
                          _buildMenuItem(
                            context,
                            icon: Icons.location_on_outlined,
                            title: 'Address',
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressManagementScreen()));
                            },
                          ),
                          _buildMenuItem(
                            context,
                            icon: Icons.description_outlined,
                            title: 'Terms & Conditions',
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen()));
                            },
                          ),
                          _buildMenuItem(
                            context,
                            icon: Icons.mail_outline,
                            title: 'Contact Us',
                            onTap: () => _showContactDialog(context),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                              },
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
                            onPressed: () => _showDeleteAccountDialog(context),
                            child: Text(
                              'Delete Account',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
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
            const Text(
              'Have questions or need help? Reach out to us!',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email, color: Color(0xFFFF6B35)),
              title: const Text(AppConfig.supportEmail),
              subtitle: const Text('Email Support'),
              onTap: () async {
                final uri = Uri(
                  scheme: 'mailto',
                  path: AppConfig.supportEmail,
                  queryParameters: {'subject': 'Support Request - OrignaGTA'},
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.language, color: Color(0xFFFF6B35)),
              title: const Text('Visit our website'),
              subtitle: const Text(AppConfig.websiteUrl),
              onTap: () async {
                final uri = Uri.parse(AppConfig.websiteUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final confirmController = TextEditingController();
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 28),
              const SizedBox(width: 8),
              const Text('Delete Account'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This action is permanent and cannot be undone.',
                style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Deleting your account will:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              const Text('• Remove your profile and personal data'),
              const Text('• Delete your cart and favorites'),
              const Text('• Anonymize your order history'),
              const Text('• Remove your products (if seller)'),
              const Text('• Delete your Stripe account (if seller)'),
              const SizedBox(height: 16),
              const Text(
                'Type "DELETE" to confirm:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                decoration: InputDecoration(
                  hintText: 'DELETE',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                enabled: !isDeleting,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isDeleting
                  ? null
                  : () async {
                      if (confirmController.text.trim().toUpperCase() != 'DELETE') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please type DELETE to confirm'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      setState(() => isDeleting = true);

                      try {
                        final callable = FirebaseFunctions.instance.httpsCallable('delete_account');
                        await callable.call({'confirmation': 'DELETE_MY_ACCOUNT'});

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Account deleted successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } on FirebaseFunctionsException catch (e) {
                        setState(() => isDeleting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.message ?? 'Failed to delete account'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => isDeleting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
              child: isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }
}