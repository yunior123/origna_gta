// coverage:ignore-file
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/features/home/home_viewmodel.dart';
import 'package:origna_gta/features/seller/seller_account_status_viewmodel.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/screens/product_card_screen.dart';
import 'package:origna_gta/utils/app_logger.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/mascot/canadian_moose.dart';
import 'package:origna_gta/widgets/mascot/mascot_provider.dart';
import 'package:origna_gta/widgets/mascot/moose_provider.dart';
import 'package:origna_gta/widgets/mascot/shop_mascot.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';


part 'parts/home_hero_section.dart';
part 'parts/home_featured_products.dart';
part 'parts/home_recent_products.dart';
part 'parts/home_categories_section.dart';

/// Documentation for HomeScreen
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
    final profileRoles = ref.watch(userProfileProvider.select((a) => a.valueOrNull?.roles));
    final canManageProducts =
        (profileRoles?.contains(UserRoles.admin) ?? false) ||
        (profileRoles?.contains(UserRoles.seller) ?? false);

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
                                      style: TextButton.styleFrom(
                                        foregroundColor: DesignTokens.primary,
                                        textStyle: const TextStyle(fontSize: 13),
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
                                        // Navigate to terms URL
                                        // On web: goes to /terms-of-service (OAuth compliance)
                                        // On mobile: shows in-app screen
                                        openTermsOfService(context);
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: DesignTokens.primary,
                                        textStyle: const TextStyle(fontSize: 13),
                                      ),
                                      child: Text('home.terms_of_service'.tr()),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
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
      child: Container(
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
                                  color: DesignTokens.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(
                                    DesignTokens.radius16,
                                  ),
                                  border: Border.all(
                                    color: DesignTokens.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.shopping_bag,
                                  color: DesignTokens.white,
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
                                DesignTokens.white,
                                DesignTokens.white.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: const Text(
                              key: Key('home_screen_title'),
                              'Origna GTA',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: DesignTokens.white,
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
            ), // ConstrainedBox
          ), // Align
        ),
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
                    color: isDark ? DesignTokens.textOnDark : DesignTokens.textPrimary,
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
      ref.read(homeViewModelProvider.notifier).dismissSearchOverlay();
    }

    try {
      final position = _scrollController.position;
      if (position.pixels >= position.maxScrollExtent - 300) {
        final state = ref.read(homeViewModelProvider);
        if (state.products.isNotEmpty &&
            !state.isLoadingMore &&
            state.hasMore) {
          _isPaginating = true;
          ref.read(homeViewModelProvider.notifier).loadProducts().whenComplete(
            () {
              _isPaginating = false;
            },
          );
        }
      }
    } catch (_) {
      // Scroll position can throw during rapid layout changes — ignore
    }
  }
}
