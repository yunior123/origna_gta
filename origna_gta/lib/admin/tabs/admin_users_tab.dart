import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/admin/admin_actions_viewmodel.dart';
import 'package:origna_gta/admin/admin_providers.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/animations.dart';

class AdminUsersTab extends ConsumerStatefulWidget {
  const AdminUsersTab({super.key});

  @override
  ConsumerState<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<AdminUsersTab> {
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
                  DropdownMenuItem(value: UserRoles.buyer, child: Text('Buyers')),
                ],
                onChanged: (value) => setState(() => _roleFilter = value ?? 'all'),
              ),
            ],
          ),
        ),

        // Users List
        Expanded(
          child: ref
              .watch(adminUsersProvider)
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => const Center(child: Text('Error Fetching from Database')),
                data: (usersRaw) {
                  if (usersRaw.isEmpty) {
                    return const AnimatedEmptyState(icon: Icons.people_outline, title: 'No users found');
                  }

                  final users = usersRaw.where((data) {
                    final name = data.name.toLowerCase();
                    final email = data.email.toLowerCase();
                    final roles = data.roles;

                    final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery) || email.contains(_searchQuery);
                    final matchesRole = _roleFilter == 'all'
                        ? true
                        : _roleFilter == 'buyer'
                        ? !roles.contains(UserRoles.seller) && !roles.contains(UserRoles.admin)
                        : roles.contains(_roleFilter);

                    return matchesSearch && matchesRole;
                  }).toList();

                  if (users.isEmpty) {
                    return const Center(child: Text('No users match your filters'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final data = users[index];
                      return FadeSlideIn(
                        delay: Duration(milliseconds: 30 * index),
                        child: _UserCard(user: data),
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

class _UserCard extends ConsumerWidget {
  final UserModel user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = user.name.isNotEmpty ? user.name : 'Unknown';
    final email = user.email;
    final roles = user.roles;
    final isSuspended = user.suspended;
    final createdAt = user.createdAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSuspended ? Colors.red : const Color(0xFF667EEA),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'U',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            ...roles.map(
              (role) => Padding(
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
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text('Joined: ${_formatDate(createdAt)}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleAction(context, ref, value),
          itemBuilder: (context) => [
            if (!roles.contains(UserRoles.seller)) const PopupMenuItem(value: 'make_seller', child: Text('Make Seller')),
            if (roles.contains(UserRoles.seller) && !roles.contains(UserRoles.admin))
              const PopupMenuItem(value: 'remove_seller', child: Text('Remove Seller Role')),
            if (!roles.contains(UserRoles.admin)) const PopupMenuItem(value: 'make_admin', child: Text('Make Admin')),
            if (!isSuspended) const PopupMenuItem(value: 'suspend', child: Text('Suspend User')),
            if (isSuspended) const PopupMenuItem(value: 'unsuspend', child: Text('Unsuspend User')),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) async {
    final messenger = ScaffoldMessenger.of(context);
    final viewModel = ref.read(adminActionsViewModelProvider.notifier);
    bool success = false;

    switch (action) {
      case 'make_seller':
        success = await viewModel.updateUserRoles(user.uid, add: [UserRoles.seller]);
        break;
      case 'remove_seller':
        success = await viewModel.updateUserRoles(user.uid, remove: [UserRoles.seller]);
        break;
      case 'make_admin':
        success = await viewModel.updateUserRoles(user.uid, add: [UserRoles.admin]);
        break;
      case 'suspend':
        success = await viewModel.setUserSuspended(user.uid, true);
        break;
      case 'unsuspend':
        success = await viewModel.setUserSuspended(user.uid, false);
        break;
    }

    if (!context.mounted) return;
    if (success) {
      switch (action) {
        case 'make_seller':
          messenger.showSnackBar(const SnackBar(content: Text('User is now a seller'), backgroundColor: Colors.green));
          break;
        case 'remove_seller':
          messenger.showSnackBar(const SnackBar(content: Text('Seller role removed'), backgroundColor: Colors.orange));
          break;
        case 'make_admin':
          messenger.showSnackBar(const SnackBar(content: Text('User is now an admin'), backgroundColor: Colors.green));
          break;
        case 'suspend':
          messenger.showSnackBar(const SnackBar(content: Text('User suspended'), backgroundColor: Colors.orange));
          break;
        case 'unsuspend':
          messenger.showSnackBar(const SnackBar(content: Text('User unsuspended'), backgroundColor: Colors.green));
          break;
      }
    } else {
      final error = ref.read(adminActionsViewModelProvider).errorMessage ?? 'Action failed';
      messenger.showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
    }
  }
}
