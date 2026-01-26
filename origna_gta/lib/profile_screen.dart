import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/addressmanagement_screen.dart';
import 'package:origna_gta/favorites_screen.dart';
import 'package:origna_gta/orders_screen.dart';
import 'package:origna_gta/utils.dart';

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
                final name = userData?['name'] ?? 'User';
                final email = userData?['email'] ?? user.email ?? '';
                final userModel = UserModel.fromMap(userData!);
                final isSeller = userModel.roles.contains('seller');
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
                              name[0].toUpperCase(),
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

                          if (isSeller)
                            _buildMenuItem(
                              context,
                              icon: Icons.shopping_bag_outlined,
                              title: 'Seller Orders',
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
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
                            title: 'Addresses',
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressManagementScreen()));
                            },
                          ),
                          // _buildMenuItem(
                          //   context,
                          //   icon: Icons.payment_outlined,
                          //   title: 'Payment Methods',
                          //   onTap: () {
                          //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment methods coming soon')));
                          //   },
                          // ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], foregroundColor: Colors.white),
                              child: const Text('Sign Out'),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFFF6B35)),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
