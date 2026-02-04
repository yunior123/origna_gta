import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/app/seller_account_status_viewmodel.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/features/home/home_viewmodel.dart';
import 'package:origna_gta/screens/addproduct_screen.dart';
import 'package:origna_gta/screens/cart_screen.dart';
import 'package:origna_gta/screens/product_card_screen.dart';
import 'package:origna_gta/screens/profile_screen.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final UserModel? userModel;
  const HomeScreen({super.key, this.userModel});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

/// Add product button - only rebuilds when user profile changes
class _AddProductButton extends ConsumerWidget {
  const _AddProductButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final sellerStatus = ref.watch(sellerAccountStatusProvider);

    // Only show for sellers or admins
    final isSeller = userProfile?.roles.contains(UserRoles.seller) ?? false;
    final isAdmin = userProfile?.roles.contains(UserRoles.admin) ?? false;
    final isSuspended = userProfile?.suspended ?? false;

    // Don't show button if user is not a seller/admin
    if (!isSeller && !isAdmin) {
      return const SizedBox.shrink();
    }

    // Check if seller account is fully verified (charges AND payouts enabled)
    final isVerified = sellerStatus.whenOrNull(
      data: (status) => status.isComplete,
    ) ?? false;

    // Admins can always add products, sellers only when verified
    final canAddProducts = isAdmin || isVerified;

    return IconButton(
      key: const Key('home_add_product_button'),
      icon: const Icon(Icons.add_box_outlined, color: Colors.white),
      onPressed: () {
        if (isSuspended) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Seller account suspended. Contact support.'), 
              backgroundColor: DesignTokens.primary,
            ),
          );
          return;
        }
        if (!canAddProducts) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Complete Stripe identity verification first to add products.'), 
              backgroundColor: DesignTokens.primary,
            ),
          );
          return;
        }
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
      },
    );
  }
}

// ============================================================================
// EXTRACTED WIDGETS - Each only rebuilds when its specific data changes
// ============================================================================

/// Cart badge - only rebuilds when cart count or auth state changes
class _CartBadge extends ConsumerStatefulWidget {
  const _CartBadge();

  @override
  ConsumerState<_CartBadge> createState() => _CartBadgeState();
}

class _CartBadgeState extends ConsumerState<_CartBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final cartCount = ref.watch(cartItemCountProvider);

    return MouseRegion(
      onEnter: (_) => _triggerAnimation(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                  onPressed: () {
                    _triggerAnimation();
                    if (user == null) {
                      showLoginPrompt(context);
                      return;
                    }
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                  },
                ),
              );
            },
          ),
          if (cartCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF667EEA), width: 2),
                        boxShadow: [BoxShadow(color: const Color(0xFF667EEA).withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)],
                      ),
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      child: Text(
                        cartCount > 99 ? '99+' : '$cartCount',
                        style: const TextStyle(color: Color(0xFF667EEA), fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void _triggerAnimation() {
    _controller.forward().then((_) => _controller.reverse());
  }
}

class _CategoryChips extends ConsumerWidget {
  final HomeViewModel homeNotifier;

  const _CategoryChips({required this.homeNotifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategoryId = ref.watch(homeViewModelProvider.select((state) => state.selectedCategoryId));

    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: productCategories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final category = isAll ? null : productCategories[index - 1];
          final isSelected = isAll ? selectedCategoryId == null : selectedCategoryId == category?.categoryId;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: DesignTokens.durationNormal,
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [DesignTokens.primary.withValues(alpha: 0.9), DesignTokens.secondary.withValues(alpha: 0.9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: !isSelected ? DesignTokens.surface : null,
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                border: Border.all(color: isSelected ? DesignTokens.primary : Colors.grey.withValues(alpha: 0.3), width: 1.5),
                boxShadow: isSelected ? [BoxShadow(color: DesignTokens.primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))] : [],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    homeNotifier.onCategorySelected(isAll ? null : category!.categoryId);
                  },
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  splashColor: Colors.white.withValues(alpha: 0.2),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Center(
                      child: Text(
                        isAll ? 'All' : category!.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final homeNotifier = ref.read(homeViewModelProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildModernAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [isDark ? Colors.grey[900]! : Colors.grey[50]!, isDark ? Colors.grey[800]! : Colors.white],
          ),
        ),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Animated Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(ResponsiveBreakpoints.getSpacing(context, SpacingSize.md)),
                child: _buildModernSearchBar(homeNotifier),
              ),
            ),

            // Category Chips
            SliverToBoxAdapter(child: _CategoryChips(homeNotifier: homeNotifier)),

            const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.spacing20)),

            // Product Grid
            _ProductGrid(cardAspectRatio: _getCardAspectRatio(context), fallbackUserModel: widget.userModel),

            // Pagination Loader
            const _PaginationLoader(),

            const SliverToBoxAdapter(child: SizedBox(height: 50)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() => setState(() {}));
  }

  PreferredSizeWidget _buildModernAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [DesignTokens.primary.withValues(alpha: 0.95), DesignTokens.secondary.withValues(alpha: 0.95)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [BoxShadow(color: DesignTokens.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
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
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(DesignTokens.radius16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                            ),
                            child: const Icon(Icons.shopping_bag, color: Colors.white, size: 28),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.white, Colors.white.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Text(
                        'OrignaGta',
                        style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 24, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
                const Row(children: [_SettingsButton(), _AddProductButton(), _CartBadge()]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernSearchBar(HomeViewModel homeNotifier) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      child: TextField(
        controller: _searchController,
        onChanged: homeNotifier.onSearchChanged,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        cursorColor: DesignTokens.primary,
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: DesignTokens.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    homeNotifier.onSearchChanged('');
                  },
                  child: Icon(Icons.close, color: Colors.grey[500]),
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radius12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            borderSide: BorderSide(color: DesignTokens.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  /// Get responsive aspect ratio for product cards
  double _getCardAspectRatio(BuildContext context) {
    return ResponsiveBreakpoints.getValue(
      context: context,
      mobile: 0.6, // 320px - small phones
      mobilePlus: 0.65, // 480px - medium phones
      tablet: 0.7, // 768px - tablets
      desktop: 0.75, // 1024px+ - desktop
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      ref.read(homeViewModelProvider.notifier).loadProducts();
    }
  }
}

class _PaginationLoader extends ConsumerWidget {
  const _PaginationLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoadingMore = ref.watch(homeViewModelProvider.select((state) => state.isLoadingMore));

    if (!isLoadingMore) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [DesignTokens.primary, DesignTokens.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
          ),
        ),
      ),
    );
  }
}

class _ProductGrid extends ConsumerWidget {
  final double cardAspectRatio;
  final UserModel? fallbackUserModel;

  const _ProductGrid({required this.cardAspectRatio, required this.fallbackUserModel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(homeViewModelProvider.select((state) => state.isLoading));
    final products = ref.watch(homeViewModelProvider.select((state) => state.products));
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (products.isEmpty && !isLoading) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(64),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [DesignTokens.primary.withValues(alpha: 0.1), DesignTokens.secondary.withValues(alpha: 0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(Icons.inventory_2_outlined, size: 80, color: DesignTokens.primary.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 24),
                Text(
                  'No products found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text('Try adjusting your filters or search terms', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              ],
            ),
          ),
        ),
      );
    }

    if (isLoading) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 64),
          child: Center(
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [DesignTokens.primary, DesignTokens.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            ),
          ),
        ),
      );
    }

    final spacing = ResponsiveBreakpoints.getSpacing(context, SpacingSize.md);
    
    return SliverPadding(
      padding: EdgeInsets.all(spacing),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveBreakpoints.getGridColumns(context),
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: cardAspectRatio,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = products[index];
          return FadeTransition(
            opacity: AlwaysStoppedAnimation(1.0),
            child: ProductCard(productId: product.productId, product: product, userModel: userProfile ?? fallbackUserModel),
          );
        }, childCount: products.length),
      ),
    );
  }
}

/// Settings button - only rebuilds when auth state changes
class _SettingsButton extends ConsumerStatefulWidget {
  const _SettingsButton();

  @override
  ConsumerState<_SettingsButton> createState() => _SettingsButtonState();
}

class _SettingsButtonState extends ConsumerState<_SettingsButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return MouseRegion(
      onEnter: (_) => _triggerAnimation(),
      child: AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value * 3.14159,
            child: IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () {
                _triggerAnimation();
                if (user == null) {
                  showLoginPrompt(context, text: "You need to sign in to access settings");
                  return;
                }
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void _triggerAnimation() {
    _controller.forward().then((_) => _controller.reverse());
  }
}
