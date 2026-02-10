import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/admin/admin_actions_viewmodel.dart';
import 'package:origna_gta/features/admin/admin_providers.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
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
        // Modern Search and Filter Bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignTokens.radius16),
            boxShadow: DesignTokens.shadowSm,
          ),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: DesignTokens.primary),
                  filled: true,
                  fillColor: DesignTokens.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _filterChip('All', 'all'),
                  const SizedBox(width: 6),
                  _filterChip('Sellers', 'seller'),
                  const SizedBox(width: 6),
                  _filterChip('Admins', 'admin'),
                  const SizedBox(width: 6),
                  _filterChip('Buyers', UserRoles.buyer),
                ],
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
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: DesignTokens.error.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(Icons.cloud_off_rounded, size: 40, color: DesignTokens.error),
                      ),
                      const SizedBox(height: 16),
                      const Text('Error Fetching from Database', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
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
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_alt_off_rounded, size: 40, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text('No users match your filters', style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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

  Widget _filterChip(String label, String value) {
    final isSelected = _roleFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _roleFilter = value),
        child: AnimatedContainer(
          duration: DesignTokens.durationFast,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? DesignTokens.primary : DesignTokens.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radius12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: isSuspended
                    ? LinearGradient(colors: [DesignTokens.error, DesignTokens.error.withValues(alpha: 0.7)])
                    : DesignTokens.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      ...roles.map(
                        (role) => Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _roleColor(role).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              role,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _roleColor(role)),
                            ),
                          ),
                        ),
                      ),
                      if (isSuspended) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.block_rounded, size: 14, color: DesignTokens.error),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(email, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  Text('Joined ${_formatDate(createdAt)}', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ],
              ),
            ),
            // Actions
            PopupMenuButton<String>(
              onSelected: (value) => _handleAction(context, ref, value),
              icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400]),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radius12)),
              itemBuilder: (context) => [
                if (!roles.contains(UserRoles.seller))
                  _menuItem('make_seller', Icons.store_rounded, 'Make Seller', DesignTokens.primary),
                if (roles.contains(UserRoles.seller) && !roles.contains(UserRoles.admin))
                  _menuItem('remove_seller', Icons.store_rounded, 'Remove Seller Role', DesignTokens.warning),
                if (!roles.contains(UserRoles.admin))
                  _menuItem('make_admin', Icons.admin_panel_settings_rounded, 'Make Admin', DesignTokens.secondary),
                if (!isSuspended) _menuItem('suspend', Icons.block_rounded, 'Suspend User', DesignTokens.error),
                if (isSuspended) _menuItem('unsuspend', Icons.check_circle_rounded, 'Unsuspend User', DesignTokens.success),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
          messenger.showSnackBar(SnackBar(content: const Text('User is now a seller'), backgroundColor: DesignTokens.success));
          break;
        case 'remove_seller':
          messenger.showSnackBar(SnackBar(content: const Text('Seller role removed'), backgroundColor: DesignTokens.warning));
          break;
        case 'make_admin':
          messenger.showSnackBar(SnackBar(content: const Text('User is now an admin'), backgroundColor: DesignTokens.success));
          break;
        case 'suspend':
          messenger.showSnackBar(SnackBar(content: const Text('User suspended'), backgroundColor: DesignTokens.warning));
          break;
        case 'unsuspend':
          messenger.showSnackBar(SnackBar(content: const Text('User unsuspended'), backgroundColor: DesignTokens.success));
          break;
      }
    } else {
      final error = ref.read(adminActionsViewModelProvider).errorMessage ?? 'Action failed';
      messenger.showSnackBar(SnackBar(content: Text(error), backgroundColor: DesignTokens.error));
    }
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 13, color: color)),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    if (role == UserRoles.admin) return DesignTokens.secondary;
    if (role == UserRoles.seller) return DesignTokens.info;
    return Colors.grey;
  }
}
