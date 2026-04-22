import 'package:origna_gta/utils/preview_helpers.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/home/home_state.dart';
import 'package:origna_gta/features/home/home_viewmodel.dart';
import 'package:origna_gta/features/seller/seller_account_status_viewmodel.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/screens/product_card_screen.dart';
import 'package:origna_gta/utils/app_logger.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/core/feature_flag_provider.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/mascot/canadian_moose.dart';
import 'package:origna_gta/widgets/mascot/mascot_provider.dart';
import 'package:origna_gta/widgets/mascot/moose_provider.dart';
import 'package:origna_gta/widgets/mascot/shop_mascot.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:origna_gta/widgets/shared/cart_badge.dart';
import 'package:origna_gta/widgets/language_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:origna_gta/widgets/modern_skeleton_loader.dart';
import 'package:flutter/widget_previews.dart';

part 'parts/home_hero_section.dart';
part 'parts/home_featured_products.dart';
part 'parts/home_recent_products.dart';
part 'parts/home_categories_section.dart';

/// Main marketplace screen with product grid, search, category filters, and hero section.
///
/// Watches [homeViewModelProvider] for product data and search state.
/// Supports infinite scroll pagination, debounced search with autocomplete,
/// and category/sort/price filtering.
class HomeScreen extends ConsumerStatefulWidget {
  final UserModel? userModel;
  const HomeScreen({super.key, this.userModel});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

/// Add product button - only rebuilds when user profile changes

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isPaginating = false;

  @override
  Widget build(BuildContext context) {
    final homeNotifier = ref.read(homeViewModelProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine whether the management action row will be shown on product cards
    // so the grid aspect ratio can accommodate the extra row height.
    final profileRoles = ref.watch(
      userProfileProvider.select((a) => a.valueOrNull?.roles),
    );
    final canManageProducts =
        (profileRoles?.contains(UserRole.admin) ?? false) ||
        (profileRoles?.contains(UserRole.seller) ?? false);

    // Choix de la mascotte selon la parité du jour
    // Both providers are watched unconditionally to comply with Riverpod's
    // hook-like contract (ref.watch must not be called conditionally).
    final day = DateTime.now().day;
    final showSparky = day % 2 == 0;
    final mascotControllerRaw = ref.watch(mascotControllerProvider);
    final mooseControllerRaw = ref.watch(mooseControllerProvider);
    final mascotController = showSparky ? mascotControllerRaw : null;
    final mooseController = !showSparky ? mooseControllerRaw : null;

    return Scaffold(
      appBar: _buildModernAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: DesignTokens.backgroundGradient(isDark: isDark),
        ),
        child: Stack(
          children: [
            // Main scrollable content — centered with max-width on desktop/web
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: ResponsiveBreakpoints.contentMaxWidth,
                ),
                child: RefreshIndicator(
                  color: DesignTokens.primary,
                  onRefresh: () =>
                      ref.read(homeViewModelProvider.notifier).refresh(),
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
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

                      // Animated Search Bar + autocomplete overlay
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(
                            ResponsiveBreakpoints.getSpacing(
                              context,
                              SpacingSize.md,
                            ),
                          ),
                          child: _buildSearchBarWithOverlay(homeNotifier),
                        ),
                      ),

                      // Sort + Price filter row (GAP #1, GAP #2)
                      SliverToBoxAdapter(
                        child: _SortAndFilterRow(homeNotifier: homeNotifier),
                      ),

                      // Category Chips
                      SliverToBoxAdapter(
                        child: _CategoryChips(homeNotifier: homeNotifier),
                      ),

                      // Subcategory Chips (shown when a category is selected)
                      SliverToBoxAdapter(
                        child: _SubcategoryChips(homeNotifier: homeNotifier),
                      ),

                      // GAP #6 — Recently Viewed horizontal section
                      const SliverToBoxAdapter(child: _RecentlyViewedSection()),

                      const SliverToBoxAdapter(
                        child: SizedBox(height: DesignTokens.spacing20),
                      ),

                      // Product Grid
                      _ProductGrid(
                        cardAspectRatio: _getCardAspectRatio(
                          context,
                          canManageProduct: canManageProducts,
                        ),
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
                              const SizedBox(height: 16),
                              // Origna Ventures Company Specs
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.business,
                                    size: 16,
                                    color: DesignTokens.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'home.platform_by_origna_ventures'.tr(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: DesignTokens.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'home.company_details'.tr(),
                                style: TextStyle(
                                  color: DesignTokens.textSecondary.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                children: [
                                  Semantics(
                                    label: 'btn-home-privacy-policy',
                                    button: true,
                                    child: TextButton(
                                      onPressed: () {
                                        openPrivacyPolicy(context);
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: DesignTokens.primary,
                                        textStyle: const TextStyle(
                                          fontSize: 13,
                                        ),
                                      ),
                                      child: Text('home.privacy_policy'.tr()),
                                    ),
                                  ),
                                  Text(
                                    '|',
                                    style: TextStyle(
                                      color: DesignTokens.textSecondary
                                          .withValues(alpha: 0.4),
                                      fontSize: 13,
                                    ),
                                  ),
                                  Semantics(
                                    label: 'btn-home-terms-of-service',
                                    button: true,
                                    child: TextButton(
                                      onPressed: () {
                                        openTermsOfService(context);
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: DesignTokens.primary,
                                        textStyle: const TextStyle(
                                          fontSize: 13,
                                        ),
                                      ),
                                      child: Text('home.terms_of_service'.tr()),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Language Selector
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.language,
                                    size: 16,
                                    color: DesignTokens.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'language.select_language'.tr(),
                                    style: TextStyle(
                                      color: DesignTokens.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const LanguageSelector(),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'home.copyright'.tr(
                                  namedArgs: {
                                    'year': DateTime.now().year.toString(),
                                  },
                                ),
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
                ), // RefreshIndicator
              ), // ConstrainedBox
            ), // Align
            // --- MASCOTTE CANADIENNE --- (mobile + tablet only)
            if (!ResponsiveBreakpoints.isDesktop(context))
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
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // No root setState listener — suffix icon uses ValueListenableBuilder below
    _searchFocusNode.addListener(() {
      final homeNotifier = ref.read(homeViewModelProvider.notifier);
      homeNotifier.onSearchFocusChanged(_searchFocusNode.hasFocus);
    });
  }

  PreferredSizeWidget _buildModernAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 430;
          return Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  DesignTokens.gradientStart,
                  DesignTokens.gradientMiddle,
                  DesignTokens.gradientEnd,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.gradientStart.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SafeArea(
              child: Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: ResponsiveBreakpoints.contentMaxWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.elasticOut,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Container(
                                      padding: EdgeInsets.all(
                                        isCompact ? 8 : 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: DesignTokens.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          DesignTokens.radius16,
                                        ),
                                        border: Border.all(
                                          color: DesignTokens.white.withValues(
                                            alpha: 0.3,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.shopping_bag,
                                        color: DesignTokens.white,
                                        size: isCompact ? 24 : 28,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(width: isCompact ? 8 : 12),
                              Flexible(
                                child: Semantics(
                                  header: true,
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [
                                        DesignTokens.white,
                                        DesignTokens.white.withValues(
                                          alpha: 0.8,
                                        ),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds),
                                    child: Text(
                                      key: Key('home_screen_title'),
                                      AppConfig.appName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: DesignTokens.white,
                                        fontSize: isCompact ? 20 : 24,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const _SettingsButton(),
                                _NotificationBellButton(),
                                const _AddProductButton(),
                                const CartBadge.animated(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ), // ConstrainedBox
              ), // Align
            ),
          );
        },
      ),
    );
  }

  /// Search bar wrapped in an overlay-capable column for autocomplete (GAP #7).
  Widget _buildSearchBarWithOverlay(HomeViewModel homeNotifier) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showOverlay = ref.watch(
      homeViewModelProvider.select((s) => s.showSearchOverlay),
    );
    final recentSearches = ref.watch(
      homeViewModelProvider.select((s) => s.recentSearches),
    );
    final suggestions = ref.watch(
      homeViewModelProvider.select((s) => s.searchSuggestions),
    );
    final query = _searchController.text;

    // Decide what to show in the overlay
    final showRecent =
        showOverlay && query.isEmpty && recentSearches.isNotEmpty;
    final showSuggestions =
        showOverlay && query.length >= 2 && suggestions.isNotEmpty;
    final overlayVisible = showRecent || showSuggestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cap search bar width on desktop to avoid stretching across full 1200px
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: GlassContainer(
              child: Semantics(
                label: 'input-home-search',
                child: TextField(
                  key: const Key('home_search_field'),
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: homeNotifier.onSearchChanged,
                  onSubmitted: (v) {
                    homeNotifier.onSearchSubmitted(v);
                    _searchFocusNode.unfocus();
                    // Scroll to top so search results in product grid are visible
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        0,
                        duration: DesignTokens.durationNormal,
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  style: TextStyle(
                    color: isDark
                        ? DesignTokens.textOnDark
                        : DesignTokens.textPrimary,
                  ),
                  cursorColor: DesignTokens.primary,
                  decoration: InputDecoration(
                    hintText: 'home.search_products'.tr(),
                    hintStyle: TextStyle(color: DesignTokens.textSecondary),
                    prefixIcon: Icon(Icons.search, color: DesignTokens.primary),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, _) {
                        if (value.text.isEmpty) return const SizedBox.shrink();
                        return Semantics(
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
                        );
                      },
                    ),
                    filled: true,
                    fillColor: DesignTokens.transparent,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radius12,
                      ),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radius12,
                      ),
                      borderSide: BorderSide(
                        color: DesignTokens.textSecondary.withValues(
                          alpha: 0.2,
                        ),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radius12,
                      ),
                      borderSide: BorderSide(
                        color: DesignTokens.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          ), // ConstrainedBox
        ), // Center
        // GAP #7 — Autocomplete dropdown
        if (overlayVisible)
          _SearchOverlay(
            isDark: isDark,
            showRecent: showRecent,
            recentSearches: recentSearches,
            suggestions: showSuggestions ? suggestions : [],
            onTap: (value) {
              _searchController.text = value;
              _searchController.selection = TextSelection.fromPosition(
                TextPosition(offset: value.length),
              );
              homeNotifier.onSearchSubmitted(value);
              _searchFocusNode.unfocus();
              // Scroll to top so the product grid results are visible
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  0,
                  duration: DesignTokens.durationNormal,
                  curve: Curves.easeOut,
                );
              }
            },
            onClearRecent: homeNotifier.clearRecentSearches,
          ),
      ],
    );
  }

  /// Get responsive aspect ratio for product cards.
  /// [canManageProduct] = true when the management action row is visible
  /// (seller/admin), which adds ~32–48 dp and requires taller cards.
  double _getCardAspectRatio(
    BuildContext context, {
    bool canManageProduct = false,
  }) {
    if (canManageProduct) {
      return ResponsiveBreakpoints.getValue(
        context: context,
        mobile: ResponsiveBreakpoints.cardAspectMobileManage,
        mobilePlus: ResponsiveBreakpoints.cardAspectMobilePlusManage,
        tablet: ResponsiveBreakpoints.cardAspectTabletManage,
        desktop: ResponsiveBreakpoints.cardAspectDesktopManage,
      );
    }
    return ResponsiveBreakpoints.getValue(
      context: context,
      mobile: ResponsiveBreakpoints.cardAspectMobile,
      mobilePlus: ResponsiveBreakpoints.cardAspectMobilePlus,
      tablet: ResponsiveBreakpoints.cardAspectTablet,
      desktop: ResponsiveBreakpoints.cardAspectDesktop,
    );
  }

  void _onScroll() {
    // Guard: controller must be attached and not already paginating
    if (_isPaginating) return;
    if (!_scrollController.hasClients) return;

    // Dismiss search overlay and unfocus keyboard when the user scrolls —
    // this ensures product card taps are never eaten by the focus system on
    // mobile web (first-tap-unfocuses-then-second-tap-navigates issue).
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
      try {
        ref.read(homeViewModelProvider.notifier).dismissSearchOverlay();
      } catch (e, st) {
        AppError.log(
          e,
          stackTrace: st,
          context: 'HomeScreen._onScroll.dismissSearchOverlay',
        );
      }
    }

    try {
      final position = _scrollController.position;
      if (position.pixels >= position.maxScrollExtent - 300) {
        final state = ref.read(homeViewModelProvider);
        if (state.products.isNotEmpty &&
            !state.isLoadingMore &&
            state.hasMore) {
          _isPaginating = true;
          Future.microtask(() async {
            try {
              await ref.read(homeViewModelProvider.notifier).loadProducts();
            } catch (e, st) {
              AppError.log(
                e,
                stackTrace: st,
                context: 'HomeScreen._onScroll.loadProducts',
              );
            } finally {
              _isPaginating = false;
            }
          });
        }
      }
    } catch (e, st) {
      AppError.log(
        e,
        stackTrace: st,
        context: 'HomeScreen._onScroll.pagination',
      );
    }
  }
}

// === Widget Previews ===

// ═══ Widget Previews ═══

const _previewHomeImageBase = 'https://fastly.picsum.photos/id';

String _previewHomeImage(int id, {int width = 900, int height = 900}) =>
    '$_previewHomeImageBase/$id/$width/$height.jpg';

final _previewProducts = [
  Product(
    productId: 'preview-1',
    sellerId: 'seller-1',
    name: 'Érable Artisan Syrup',
    description: 'Pure Quebec maple syrup, Grade A Amber',
    priceCents: 1899,
    stockQuantity: 150,
    imageUrls: [_previewHomeImage(431)],
    categoryId: 1,
    createdAt: DateTime(2026, 1, 15),
    isTrending: true,
    trendingScore: 95,
    rating: 4.8,
    ratingCount: 124,
    shipFromCountry: 'CA',
    shipFromCity: 'Montreal',
    shipFromProvince: 'QC',
    freeShipping: true,
  ),
  Product(
    productId: 'preview-2',
    sellerId: 'seller-2',
    name: 'Handcrafted Leather Wallet',
    description: 'Full-grain leather, handmade in Toronto',
    priceCents: 7999,
    compareAtPriceCents: 9999,
    stockQuantity: 42,
    imageUrls: [_previewHomeImage(292)],
    categoryId: 3,
    createdAt: DateTime(2026, 2, 10),
    rating: 4.5,
    ratingCount: 67,
    shipFromCountry: 'CA',
    shipFromCity: 'Toronto',
    shipFromProvince: 'ON',
  ),
  Product(
    productId: 'preview-3',
    sellerId: 'seller-3',
    name: 'Organic Wild Blueberry Jam',
    description: 'Small-batch jam from Nova Scotia wild blueberries',
    priceCents: 1249,
    stockQuantity: 200,
    imageUrls: [_previewHomeImage(1025)],
    categoryId: 1,
    createdAt: DateTime(2026, 3, 1),
    isTrending: true,
    trendingScore: 88,
    rating: 4.9,
    ratingCount: 203,
    shipFromCountry: 'CA',
    shipFromCity: 'Halifax',
    shipFromProvince: 'NS',
    freeShipping: true,
  ),
  Product(
    productId: 'preview-4',
    sellerId: 'seller-1',
    name: 'Ceramic Coffee Mug Set',
    description: 'Set of 4 handmade ceramic mugs, dishwasher safe',
    priceCents: 5499,
    stockQuantity: 28,
    imageUrls: [_previewHomeImage(1062)],
    categoryId: 5,
    createdAt: DateTime(2026, 1, 28),
    rating: 4.3,
    ratingCount: 45,
    shipFromCountry: 'CA',
    shipFromCity: 'Vancouver',
    shipFromProvince: 'BC',
  ),
  Product(
    productId: 'preview-5',
    sellerId: 'seller-4',
    name: 'Premium Headphones',
    description: 'Noise-canceling wireless headphones, 40hr battery',
    priceCents: 29999,
    compareAtPriceCents: 39999,
    stockQuantity: 15,
    imageUrls: [_previewHomeImage(367)],
    categoryId: 8,
    createdAt: DateTime(2026, 2, 20),
    isTrending: true,
    trendingScore: 72,
    rating: 4.7,
    ratingCount: 312,
    shipFromCountry: 'CA',
    shipFromCity: 'Calgary',
    shipFromProvince: 'AB',
  ),
  Product(
    productId: 'preview-6',
    sellerId: 'seller-2',
    name: 'Artisan Quebec Cheese Board',
    description: 'Selection of aged Quebec cheeses, locally sourced',
    priceCents: 4500,
    stockQuantity: 10,
    imageUrls: [_previewHomeImage(433)],
    categoryId: 1,
    createdAt: DateTime(2026, 3, 5),
    rating: 4.6,
    ratingCount: 89,
    shipFromCountry: 'CA',
    shipFromCity: 'Quebec City',
    shipFromProvince: 'QC',
    isPerishable: true,
  ),
];

class _PreviewHomeViewModel extends HomeViewModel {
  _PreviewHomeViewModel(List<Product> mockProducts) : super(_FakeHomeRef()) {
    state = HomeState(
      products: mockProducts,
      isLoading: false,
      hasMore: false,
      recentSearches: ['maple syrup', 'leather wallet', 'headphones'],
    );
  }
}

class _FakeHomeRef extends Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Widget _home() => previewScope(
  extraOverrides: [
    homeViewModelProvider.overrideWith((ref) {
      return _PreviewHomeViewModel(_previewProducts);
    }),
  ],
  child: HomeScreen(),
);

// Logged-in: previewScopeLoggedIn — userIdProvider returns a uid
Widget _homeLoggedIn() => previewScopeLoggedIn(
  extraOverrides: [
    homeViewModelProvider.overrideWith((ref) {
      return _PreviewHomeViewModel(_previewProducts);
    }),
  ],
  child: HomeScreen(),
);

// ── Dark (default) ──────────────────────────────────────────────────────────
@Preview(
  name: 'Home Screen Dark — Mobile',
  group: 'Home Screens',
  size: Size(390, 844),
)
Widget previewHomeScreenMobile() => previewMobile(child: _home());

@Preview(
  name: 'Home Screen Dark — Tablet',
  group: 'Home Screens',
  size: Size(768, 1024),
)
Widget previewHomeScreenTablet() => previewTablet(child: _home());

@Preview(
  name: 'Home Screen Dark — Desktop',
  group: 'Home Screens',
  size: Size(1280, 800),
)
Widget previewHomeScreenDesktop() => previewDesktop(child: _home());

@Preview(
  name: 'Home Screen Dark — Web',
  group: 'Home Screens',
  size: Size(1440, 900),
)
Widget previewHomeScreenWeb() => previewWeb(child: _home());

// ── Light ────────────────────────────────────────────────────────────────────
@Preview(
  name: 'Home Screen Light — Mobile',
  group: 'Home Screens',
  size: Size(390, 844),
)
Widget previewHomeScreenLightMobile() =>
    previewMobile(theme: previewLightTheme, child: _home());

@Preview(
  name: 'Home Screen Light — Tablet',
  group: 'Home Screens',
  size: Size(768, 1024),
)
Widget previewHomeScreenLightTablet() =>
    previewTablet(theme: previewLightTheme, child: _home());

@Preview(
  name: 'Home Screen Light — Desktop',
  group: 'Home Screens',
  size: Size(1280, 800),
)
Widget previewHomeScreenLightDesktop() =>
    previewDesktop(theme: previewLightTheme, child: _home());

@Preview(
  name: 'Home Screen Light — Web',
  group: 'Home Screens',
  size: Size(1440, 900),
)
Widget previewHomeScreenLightWeb() =>
    previewWeb(theme: previewLightTheme, child: _home());

// ── Logged-In Dark ────────────────────────────────────────────────────────────
@Preview(
  name: 'Home Screen Logged-In Dark — Mobile',
  group: 'Home Screens',
  size: Size(390, 844),
)
Widget previewHomeScreenLoggedInMobile() =>
    previewMobile(child: _homeLoggedIn());

@Preview(
  name: 'Home Screen Logged-In Dark — Tablet',
  group: 'Home Screens',
  size: Size(768, 1024),
)
Widget previewHomeScreenLoggedInTablet() =>
    previewTablet(child: _homeLoggedIn());

@Preview(
  name: 'Home Screen Logged-In Dark — Desktop',
  group: 'Home Screens',
  size: Size(1280, 800),
)
Widget previewHomeScreenLoggedInDesktop() =>
    previewDesktop(child: _homeLoggedIn());

@Preview(
  name: 'Home Screen Logged-In Dark — Web',
  group: 'Home Screens',
  size: Size(1440, 900),
)
Widget previewHomeScreenLoggedInWeb() => previewWeb(child: _homeLoggedIn());

// ── Logged-In Light ───────────────────────────────────────────────────────────
@Preview(
  name: 'Home Screen Logged-In Light — Mobile',
  group: 'Home Screens',
  size: Size(390, 844),
)
Widget previewHomeScreenLoggedInLightMobile() =>
    previewMobile(theme: previewLightTheme, child: _homeLoggedIn());

@Preview(
  name: 'Home Screen Logged-In Light — Tablet',
  group: 'Home Screens',
  size: Size(768, 1024),
)
Widget previewHomeScreenLoggedInLightTablet() =>
    previewTablet(theme: previewLightTheme, child: _homeLoggedIn());

@Preview(
  name: 'Home Screen Logged-In Light — Desktop',
  group: 'Home Screens',
  size: Size(1280, 800),
)
Widget previewHomeScreenLoggedInLightDesktop() =>
    previewDesktop(theme: previewLightTheme, child: _homeLoggedIn());

@Preview(
  name: 'Home Screen Logged-In Light — Web',
  group: 'Home Screens',
  size: Size(1440, 900),
)
Widget previewHomeScreenLoggedInLightWeb() =>
    previewWeb(theme: previewLightTheme, child: _homeLoggedIn());
