import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/admin/admin_providers.dart';
import 'package:origna_gta/admin/tabs/admin_orders_tab.dart';
import 'package:origna_gta/admin/tabs/admin_payment_providers_tab.dart';
import 'package:origna_gta/admin/tabs/admin_products_tab.dart';
import 'package:origna_gta/admin/tabs/admin_security_tab.dart';
import 'package:origna_gta/admin/tabs/admin_sellers_tab.dart';
import 'package:origna_gta/admin/tabs/admin_users_tab.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  static const _tabs = [
    _AdminTab(icon: Icons.store_rounded, label: 'Sellers'),
    _AdminTab(icon: Icons.people_rounded, label: 'Users'),
    _AdminTab(icon: Icons.receipt_long_rounded, label: 'Orders'),
    _AdminTab(icon: Icons.inventory_2_rounded, label: 'Products'),
    _AdminTab(icon: Icons.payment_rounded, label: 'Payments'),
    _AdminTab(icon: Icons.security_rounded, label: 'Security'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userProfile = ref.watch(userProfileProvider);
    final isWide = MediaQuery.of(context).size.width >= 900;

    return userProfile.when(
      loading: () => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: DesignTokens.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text('Loading admin panel...', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            ],
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 56, color: DesignTokens.error),
              const SizedBox(height: 16),
              Text('Error: $e', style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
      data: (profile) {
        if (user == null || profile == null || !profile.roles.contains(UserRoles.admin)) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: DesignTokens.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.admin_panel_settings_rounded, size: 56, color: DesignTokens.error),
                  ),
                  const SizedBox(height: 24),
                  const Text('Access Denied', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Admin privileges required to view this page', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        if (isWide) {
          return _buildWideLayout();
        }
        return _buildNarrowLayout();
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedIndex = _tabController.index);
      }
    });
  }

  Widget _buildNarrowLayout() {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: DesignTokens.primaryGradient),
        ),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, size: 22),
            SizedBox(width: 10),
            Text('Admin Panel', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
          tabs: _tabs
              .map((t) => Tab(
                    icon: Icon(t.icon, size: 20),
                    text: t.label,
                  ))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [AdminSellersTab(), AdminUsersTab(), AdminOrdersTab(), AdminProductsTab(), AdminPaymentProvidersTab(), AdminSecurityTab()],
      ),
    );
  }

  Widget _buildWideLayout() {
    final tabContent = [
      const AdminSellersTab(),
      const AdminUsersTab(),
      const AdminOrdersTab(),
      const AdminProductsTab(),
      const AdminPaymentProvidersTab(),
      const AdminSecurityTab(),
    ];

    return Scaffold(
      body: Row(
        children: [
          // Side Navigation Rail
          Container(
            width: 240,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [DesignTokens.gradientStart, DesignTokens.gradientEnd],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(DesignTokens.radius12),
                          ),
                          child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                              Text('Panel', style: TextStyle(color: Colors.white60, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Nav Items
                  ...List.generate(_tabs.length, (index) {
                    final tab = _tabs[index];
                    final isSelected = _selectedIndex == index;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(DesignTokens.radius12),
                        child: InkWell(
                          onTap: () {
                            setState(() => _selectedIndex = index);
                            _tabController.animateTo(index);
                          },
                          borderRadius: BorderRadius.circular(DesignTokens.radius12),
                          child: AnimatedContainer(
                            duration: DesignTokens.durationFast,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
                              borderRadius: BorderRadius.circular(DesignTokens.radius12),
                            ),
                            child: Row(
                              children: [
                                Icon(tab.icon, color: isSelected ? Colors.white : Colors.white54, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  tab.label,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white54,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  // Stats summary at bottom
                  _AdminQuickStats(ref: ref),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Icon(_tabs[_selectedIndex].icon, color: DesignTokens.primary, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        _tabs[_selectedIndex].label,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1a1a2e)),
                      ),
                      const Spacer(),
                      Text(
                        'Origna GTA Admin',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(child: tabContent[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminQuickStats extends StatelessWidget {
  final WidgetRef ref;
  const _AdminQuickStats({required this.ref});

  @override
  Widget build(BuildContext context) {
    final sellers = ref.watch(adminSellersProvider);
    final users = ref.watch(adminUsersProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Stats', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          _statRow(Icons.store_rounded, 'Sellers', sellers.whenOrNull(data: (s) => s.length.toString()) ?? '...'),
          const SizedBox(height: 6),
          _statRow(Icons.people_rounded, 'Users', users.whenOrNull(data: (u) => u.length.toString()) ?? '...'),
        ],
      ),
    );
  }

  Widget _statRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 14),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}

class _AdminTab {
  final IconData icon;
  final String label;
  const _AdminTab({required this.icon, required this.label});
}
