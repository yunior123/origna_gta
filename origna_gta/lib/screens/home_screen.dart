import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/features/seller/seller_account_status_viewmodel.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/features/home/home_viewmodel.dart';
import 'package:origna_gta/screens/product_card_screen.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/widgets/mascot/shop_mascot.dart';
import 'package:origna_gta/widgets/mascot/mascot_provider.dart';
import 'package:origna_gta/widgets/mascot/canadian_moose.dart';
import 'package:origna_gta/widgets/mascot/moose_provider.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:shimmer/shimmer.dart';

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
    final userProfileAsync = ref.watch(userProfileProvider);
    final sellerStatus = ref.watch(sellerAccountStatusProvider);

    // If provider is loading, hide button temporarily (will rebuild when loaded)
    if (userProfileAsync.isLoading) {
      return const SizedBox.shrink();
    }

    final userProfile = userProfileAsync.valueOrNull;

    // Only show for sellers or admins
    final isSeller = userProfile?.roles.contains(UserRoles.seller) ?? false;
    final isAdmin = userProfile?.roles.contains(UserRoles.admin) ?? false;
    final isSuspended = userProfile?.suspended ?? false;

    final userCanAccess = isSeller || isAdmin;

    if (kDebugMode) {
      debugPrint(
        '🔍 _AddProductButton.build() → isSeller=$isSeller, isAdmin=$isAdmin, userCanAccess=$userCanAccess',
      );
    }

    // Show only for sellers/admins to match Firestore rules.
    if (!userCanAccess) {
      if (kDebugMode) debugPrint('🔍 User cannot access → returning shrink()');
      return const SizedBox.shrink();
    }

    // Check if seller account is fully verified (charges AND payouts enabled)
    final isVerified =
        sellerStatus.whenOrNull(data: (status) => status.isComplete) ?? false;

    // Must match Firestore rules: admin OR verified seller.
    final canAddProducts = isAdmin || isVerified;
    if (kDebugMode) {
      debugPrint('🔍 isVerified=$isVerified, canAddProducts=$canAddProducts');
    }

    return IconButton(
      key: const Key('home_add_product_button'),
      tooltip: 'home.add_product'.tr(),
      icon: const Icon(Icons.add_box_outlined, color: Colors.white),
      onPressed: () {
        if (isSuspended) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('auth.seller_suspended'.tr()),
              backgroundColor: DesignTokens.primary,
            ),
          );
          return;
        }
        if (!canAddProducts) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('auth.complete_stripe_verification'.tr()),
              backgroundColor: DesignTokens.primary,
            ),
          );
          return;
        }
        Navigator.pushNamed(context, AppRoutes.addProduct);
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

class _CartBadgeState extends ConsumerState<_CartBadge>
    with SingleTickerProviderStateMixin {
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
                  key: const Key('home_cart_button'),
                  tooltip: 'home.shopping_cart'.tr(),
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    _triggerAnimation();
                    if (user == null) {
                      showLoginPrompt(context);
                      return;
                    }
                    if (!context.mounted) return;
                    final verified = await checkEmailVerifiedOrPrompt(context);
                    if (!verified) return;
                    if (!context.mounted) return;
                    Navigator.pushNamed(context, AppRoutes.cart);
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
                        border: Border.all(
                          color: DesignTokens.primary,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: DesignTokens.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        cartCount > 99 ? '99+' : '$cartCount',
                        style: const TextStyle(
                          color: DesignTokens.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
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
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
    final selectedCategoryId = ref.watch(
      homeViewModelProvider.select((state) => state.selectedCategoryId),
    );

    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: productCategories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final category = isAll ? null : productCategories[index - 1];
          final isSelected = isAll
              ? selectedCategoryId == null
              : selectedCategoryId == category?.categoryId;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: DesignTokens.durationNormal,
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          DesignTokens.primary.withValues(alpha: 0.9),
                          DesignTokens.secondary.withValues(alpha: 0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: !isSelected ? DesignTokens.surface : null,
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                border: Border.all(
                  color: isSelected
                      ? DesignTokens.primary
                      : DesignTokens.textSecondary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: DesignTokens.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    homeNotifier.onCategorySelected(
                      isAll ? null : category!.categoryId,
                    );
                  },
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  splashColor: Colors.white.withValues(alpha: 0.2),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Center(
                      child: Text(
                        isAll ? 'home.category_all'.tr() : category!.name.tr(),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : DesignTokens.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
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

class _SubcategoryChips extends ConsumerWidget {
  final HomeViewModel homeNotifier;

  const _SubcategoryChips({required this.homeNotifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategoryId = ref.watch(
      homeViewModelProvider.select((state) => state.selectedCategoryId),
    );
    final selectedSubcategory = ref.watch(
      homeViewModelProvider.select((state) => state.selectedSubcategory),
    );

    if (selectedCategoryId == null) return const SizedBox.shrink();

    final subcategories = SubcategoryConstants.forCategoryId(
      selectedCategoryId,
    );
    if (subcategories.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 38,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: subcategories.length + 1, // +1 for "All"
          itemBuilder: (context, index) {
            final isAll = index == 0;
            final subcategory = isAll ? null : subcategories[index - 1];
            final isSelected = isAll
                ? selectedSubcategory == null
                : selectedSubcategory == subcategory;

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: AnimatedContainer(
                duration: DesignTokens.durationFast,
                decoration: BoxDecoration(
                  color: isSelected
                      ? DesignTokens.secondary.withValues(alpha: 0.15)
                      : DesignTokens.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                  border: Border.all(
                    color: isSelected
                        ? DesignTokens.secondary
                        : DesignTokens.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(DesignTokens.radius8),
                    onTap: () => homeNotifier.onSubcategorySelected(
                      isAll ? null : subcategory,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        isAll ? 'home.category_all'.tr() : subcategory!,
                        style: TextStyle(
                          color: isSelected
                              ? DesignTokens.secondary
                              : DesignTokens.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
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

    // Choix de la mascotte selon la parité du jour
    final day = DateTime.now().day;
    final showSparky = day % 2 == 0;
    final mascotController = showSparky
        ? ref.watch(mascotControllerProvider)
        : null;
    final mooseController = !showSparky
        ? ref.watch(mooseControllerProvider)
        : null;

    return Scaffold(
      appBar: _buildModernAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: DesignTokens.surfaceGradient(isDark: isDark),
        ),
        child: Stack(
          children: [
            // Main scrollable content
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                // App Purpose Tagline
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Text(
                      'home.tagline'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? DesignTokens.textDisabled
                            : DesignTokens.textSecondary,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),

                // Animated Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(
                      ResponsiveBreakpoints.getSpacing(context, SpacingSize.md),
                    ),
                    child: _buildModernSearchBar(homeNotifier),
                  ),
                ),

                // Category Chips
                SliverToBoxAdapter(
                  child: _CategoryChips(homeNotifier: homeNotifier),
                ),

                // Subcategory Chips (shown when a category is selected)
                SliverToBoxAdapter(
                  child: _SubcategoryChips(homeNotifier: homeNotifier),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.spacing20),
                ),

                // Product Grid
                _ProductGrid(
                  cardAspectRatio: _getCardAspectRatio(context),
                  fallbackUserModel: widget.userModel,
                ),

                // Pagination Loader
                const _PaginationLoader(),

                // Footer with legal links
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    child: Column(
                      children: [
                        Divider(
                          color: DesignTokens.textSecondary.withValues(
                            alpha: 0.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: [
                            Semantics(
                              label: 'btn-home-privacy-policy',
                              button: true,
                              child: TextButton(
                                onPressed: () {
                                  // Navigate to privacy policy URL
                                  // On web: goes to /privacy-policy (OAuth compliance)
                                  // On mobile: shows in-app screen
                                  openPrivacyPolicy(context);
                                },
                                child: Text(
                                  'Privacy Policy',
                                  style: TextStyle(
                                    color: DesignTokens.primary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              '|',
                              style: TextStyle(
                                color: DesignTokens.textSecondary.withValues(
                                  alpha: 0.4,
                                ),
                                fontSize: 13,
                              ),
                            ),
                            Semantics(
                              label: 'btn-home-terms-of-service',
                              button: true,
                              child: TextButton(
                                onPressed: () {
                                  // Navigate to terms URL
                                  // On web: goes to /terms-of-service (OAuth compliance)
                                  // On mobile: shows in-app screen
                                  openTermsOfService(context);
                                },
                                child: Text(
                                  'Terms of Service',
                                  style: TextStyle(
                                    color: DesignTokens.primary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '© 2026 Origna GTA. All rights reserved.',
                          style: TextStyle(
                            color: DesignTokens.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // --- MASCOTTE CANADIENNE ---
            Positioned(
              bottom: 12,
              right: 8,
              child: showSparky
                  ? ShopMascot(
                      controller: mascotController!,
                      size: 80,
                      showSpeechBubble: true,
                    )
                  : CanadianMoose(
                      controller: mooseController!,
                      size: 90,
                      showSpeechBubble: true,
                    ),
            ),
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
            colors: [
              DesignTokens.primary.withValues(alpha: 0.95),
              DesignTokens.secondary.withValues(alpha: 0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
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
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radius16,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.shopping_bag,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Semantics(
                      header: true,
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.white.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          key: Key('home_screen_title'),
                          'Origna GTA',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontSize: 24,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
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

  Widget _buildModernSearchBar(HomeViewModel homeNotifier) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      child: Semantics(
        label: 'input-home-search',
        child: TextField(
          key: const Key('home_search_field'),
          controller: _searchController,
          onChanged: homeNotifier.onSearchChanged,
          style: TextStyle(
            color: isDark ? Colors.white : DesignTokens.textPrimary,
          ),
          cursorColor: DesignTokens.primary,
          decoration: InputDecoration(
            hintText: 'home.search_products'.tr(),
            hintStyle: TextStyle(color: DesignTokens.textSecondary),
            prefixIcon: Icon(Icons.search, color: DesignTokens.primary),
            suffixIcon: _searchController.text.isNotEmpty
                ? Semantics(
                    label: 'btn-clear-search',
                    button: true,
                    child: IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: DesignTokens.textSecondary,
                        size: 20,
                      ),
                      tooltip: 'common.clear'.tr(),
                      onPressed: () {
                        _searchController.clear();
                        homeNotifier.onSearchChanged('');
                      },
                    ),
                  )
                : null,
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              borderSide: BorderSide(
                color: DesignTokens.textSecondary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              borderSide: BorderSide(color: DesignTokens.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  /// Get responsive aspect ratio for product cards
  double _getCardAspectRatio(BuildContext context) {
    return ResponsiveBreakpoints.getValue(
      context: context,
      // Higher ratio = shorter cards (more items visible)
      mobile: 0.9,
      mobilePlus: 0.95,
      tablet: 1.0,
      desktop: 1.05,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      // Only paginate when products already exist — initial load is handled by the ViewModel constructor
      final products = ref.read(homeViewModelProvider).products;
      if (products.isNotEmpty) {
        ref.read(homeViewModelProvider.notifier).loadProducts();
      }
    }
  }
}

class _PaginationLoader extends ConsumerWidget {
  const _PaginationLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoadingMore = ref.watch(
      homeViewModelProvider.select((state) => state.isLoadingMore),
    );

    if (!isLoadingMore) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Semantics(
            label: 'Loading more products',
            liveRegion: true,
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [DesignTokens.primary, DesignTokens.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const ModernLoadingIndicator(
                strokeWidth: 3,
                color: Colors.white,
                centered: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductGrid extends ConsumerWidget {
  final double cardAspectRatio;
  final UserModel? fallbackUserModel;

  const _ProductGrid({
    required this.cardAspectRatio,
    required this.fallbackUserModel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      homeViewModelProvider.select((state) => state.isLoading),
    );
    final products = ref.watch(
      homeViewModelProvider.select((state) => state.products),
    );
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (products.isEmpty && !isLoading) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(64),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        DesignTokens.primary.withValues(alpha: 0.1),
                        DesignTokens.secondary.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: DesignTokens.primary.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'home.no_products_found'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : DesignTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'home.try_adjusting'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    color: DesignTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isLoading) {
      final spacing = ResponsiveBreakpoints.getSpacing(context, SpacingSize.sm);
      final columns = ResponsiveBreakpoints.getGridColumns(context);
      return SliverPadding(
        padding: EdgeInsets.all(spacing),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: cardAspectRatio,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _ShimmerCard(isDark: isDark),
            childCount: columns * 2,
          ),
        ),
      );
    }

    final spacing = ResponsiveBreakpoints.getSpacing(context, SpacingSize.sm);

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
          return ProductCard(
            key: Key('product_card_${product.name}'),
            productId: product.productId,
            product: product,
            userModel: userProfile ?? fallbackUserModel,
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

class _SettingsButtonState extends ConsumerState<_SettingsButton>
    with SingleTickerProviderStateMixin {
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
            child: Semantics(
              label: 'btn-home-settings',
              button: true,
              child: IconButton(
                key: const Key('home_settings_button'),
                tooltip: 'home.settings'.tr(),
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () {
                  _triggerAnimation();
                  if (user == null) {
                    showLoginPrompt(
                      context,
                      text: "auth.sign_in_settings_required",
                    );
                    return;
                  }
                  Navigator.pushNamed(context, AppRoutes.profile);
                },
              ),
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
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void _triggerAnimation() {
    _controller.forward().then((_) => _controller.reverse());
  }
}

class _ShimmerCard extends StatelessWidget {
  final bool isDark;
  const _ShimmerCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark ? DesignTokens.darkOutline : DesignTokens.outline,
      highlightColor: isDark
          ? DesignTokens.darkSurfaceVariant
          : DesignTokens.outlineVariant,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(DesignTokens.radius16),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      height: 14,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      height: 14,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
