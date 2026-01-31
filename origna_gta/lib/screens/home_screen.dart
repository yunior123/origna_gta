import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/screens/addproduct_screen.dart';
import 'package:origna_gta/screens/cart_screen.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/features/home/home_viewmodel.dart';
import 'package:origna_gta/features/home/home_state.dart';
import 'package:origna_gta/screens/product_card_screen.dart';
import 'package:origna_gta/screens/profile_screen.dart';
import 'package:origna_gta/utils/utils.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final UserModel? userModel;
  const HomeScreen({super.key, this.userModel});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Get responsive aspect ratio for product cards
  double _getCardAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 0.6; // Very small phones
    if (width < 600) return 0.65; // Mobile phones
    return 0.75; // Tablets and desktop
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      ref.read(homeViewModelProvider.notifier).loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);
    final homeNotifier = ref.read(homeViewModelProvider.notifier);
    final userProfile = ref.watch(userProfileProvider).valueOrNull;

    return Scaffold(
      appBar: _buildAppBar(),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: homeNotifier.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
              ),
            ),
          ),

          // Category Chips
          SliverToBoxAdapter(child: _buildCategoryList(homeState, homeNotifier)),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Product Grid
          if (homeState.products.isEmpty && !homeState.isLoading)
            _buildEmptyState()
          else if (homeState.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35))),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: getCrossAxisCount(context),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: _getCardAspectRatio(context),
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = homeState.products[index];
                  return ProductCard(productId: product.id, product: product, userModel: userProfile ?? widget.userModel);
                }, childCount: homeState.products.length),
              ),
            ),

          // Pagination Loader
          if (homeState.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35))),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          boxShadow: [BoxShadow(color: const Color(0xFFFF6B35).withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(15)),
                            child: const Icon(Icons.shopping_bag, color: Colors.white, size: 28),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'OrignaGta',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22, letterSpacing: 0.5),
                    ),
                  ],
                ),
                const Row(
                  children: [
                    _SettingsButton(),
                    _AddProductButton(),
                    _CartBadge(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(HomeState state, HomeViewModel notifier) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: productCategories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final category = isAll ? null : productCategories[index - 1];
          final isSelected = isAll ? state.selectedCategoryId == null : state.selectedCategoryId == category?.categoryId;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(isAll ? 'All' : category!.name),
              selected: isSelected,
              onSelected: (selected) {
                notifier.onCategorySelected(isAll ? null : category!.categoryId);
              },
              selectedColor: const Color(0xFFFF6B35),
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(64),
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text('No products matching your filters'),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EXTRACTED WIDGETS - Each only rebuilds when its specific data changes
// ============================================================================

/// Settings button - only rebuilds when auth state changes
class _SettingsButton extends ConsumerWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return IconButton(
      icon: const Icon(Icons.settings_outlined, color: Colors.white),
      onPressed: () {
        if (user == null) {
          showLoginPrompt(context, text: "You need to sign in to access settings");
          return;
        }
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
      },
    );
  }
}

/// Add product button - only rebuilds when user profile changes
class _AddProductButton extends ConsumerWidget {
  const _AddProductButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).valueOrNull;

    // Only show for sellers or admins
    final isSeller = userProfile?.roles.contains(UserRoles.seller) ?? false;
    final isAdmin = userProfile?.roles.contains(UserRoles.admin) ?? false;

    if (!isSeller && !isAdmin) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.add_box_outlined, color: Colors.white),
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
      },
    );
  }
}

/// Cart badge - only rebuilds when cart count or auth state changes
class _CartBadge extends ConsumerWidget {
  const _CartBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final cartCount = ref.watch(cartItemCountProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
          onPressed: () {
            if (user == null) {
              showLoginPrompt(context);
              return;
            }
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
          },
        ),
        if (cartCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFF6B35), width: 2),
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Text(
                cartCount > 99 ? '99+' : '$cartCount',
                style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
