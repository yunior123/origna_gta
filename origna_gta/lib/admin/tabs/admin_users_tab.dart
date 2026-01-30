import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/constants.dart';
import 'package:origna_gta/widgets/animations.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  String _searchQuery = '';
  String _roleFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _roleFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'seller', child: Text('Sellers')),
                  DropdownMenuItem(value: 'admin', child: Text('Admins')),
                  DropdownMenuItem(value: 'buyer', child: Text('Buyers')),
                ],
                onChanged: (value) => setState(() => _roleFilter = value ?? 'all'),
              ),
            ],
          ),
        ),

        // Users List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('createdAt', descending: true)
                .limit(100)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const AnimatedEmptyState(
                  icon: Icons.people_outline,
                  title: 'No users found',
                );
              }

              var users = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                final roles = List<String>.from(data['roles'] ?? []);

                final matchesSearch = _searchQuery.isEmpty ||
                    name.contains(_searchQuery) ||
                    email.contains(_searchQuery);

                final matchesRole = _roleFilter == 'all' ||
                    roles.contains(_roleFilter);

                return matchesSearch && matchesRole;
              }).toList();

              if (users.isEmpty) {
                return const Center(child: Text('No users match your filters'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final doc = users[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return FadeSlideIn(
                    delay: Duration(milliseconds: 30 * index),
                    child: _UserCard(userId: doc.id, data: data),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> data;

  const _UserCard({required this.userId, required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Unknown';
    final email = data['email'] ?? '';
    final roles = List<String>.from(data['roles'] ?? []);
    final isSuspended = data['suspended'] == true;
    final createdAt = data['createdAt'] as Timestamp?;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSuspended ? Colors.red : const Color(0xFFFF6B35),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'U',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
            ...roles.map((role) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Chip(
                label: Text(role, style: const TextStyle(fontSize: 10)),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                backgroundColor: role == UserRoles.admin
                    ? Colors.purple.withValues(alpha: 0.2)
                    : role == UserRoles.seller
                        ? Colors.blue.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
              ),
            )),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            if (createdAt != null)
              Text(
                'Joined: ${_formatDate(createdAt.toDate())}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleAction(context, value),
          itemBuilder: (context) => [
            if (!roles.contains(UserRoles.seller))
              const PopupMenuItem(value: 'make_seller', child: Text('Make Seller')),
            if (roles.contains(UserRoles.seller) && !roles.contains(UserRoles.admin))
              const PopupMenuItem(value: 'remove_seller', child: Text('Remove Seller Role')),
            if (!roles.contains(UserRoles.admin))
              const PopupMenuItem(value: 'make_admin', child: Text('Make Admin')),
            if (!isSuspended)
              const PopupMenuItem(value: 'suspend', child: Text('Suspend User')),
            if (isSuspended)
              const PopupMenuItem(value: 'unsuspend', child: Text('Unsuspend User')),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleAction(BuildContext context, String action) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final messenger = ScaffoldMessenger.of(context);

    switch (action) {
      case 'make_seller':
        await userRef.update({'roles': FieldValue.arrayUnion([UserRoles.seller])});
        messenger.showSnackBar(const SnackBar(content: Text('User is now a seller'), backgroundColor: Colors.green));
        break;
      case 'remove_seller':
        await userRef.update({'roles': FieldValue.arrayRemove([UserRoles.seller])});
        messenger.showSnackBar(const SnackBar(content: Text('Seller role removed'), backgroundColor: Colors.orange));
        break;
      case 'make_admin':
        await userRef.update({'roles': FieldValue.arrayUnion([UserRoles.admin])});
        messenger.showSnackBar(const SnackBar(content: Text('User is now an admin'), backgroundColor: Colors.green));
        break;
      case 'suspend':
        await userRef.update({'suspended': true, 'suspendedAt': FieldValue.serverTimestamp()});
        messenger.showSnackBar(const SnackBar(content: Text('User suspended'), backgroundColor: Colors.orange));
        break;
      case 'unsuspend':
        await userRef.update({'suspended': false, 'suspendedAt': FieldValue.delete()});
        messenger.showSnackBar(const SnackBar(content: Text('User unsuspended'), backgroundColor: Colors.green));
        break;
    }
  }
}
