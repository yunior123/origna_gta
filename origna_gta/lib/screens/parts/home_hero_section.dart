part of '../home_screen.dart';

class _AddProductButton extends ConsumerWidget {
  const _AddProductButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProfileLoading = ref.watch(
      userProfileProvider.select((a) => a.isLoading),
    );
    final isVerifiedSeller = ref.watch(
      sellerAccountStatusProvider.select(
        (a) => a.whenOrNull(data: (s) => s.isComplete) ?? false,
      ),
    );

    // If provider is loading, hide button temporarily (will rebuild when loaded)
    if (isProfileLoading) {
      return const SizedBox.shrink();
    }

    final profileRoles = ref.watch(
      userProfileProvider.select((a) => a.valueOrNull?.roles),
    );
    final isSuspended =
        ref.watch(
          userProfileProvider.select((a) => a.valueOrNull?.suspended),
        ) ??
        false;

    // Only show for sellers or admins
    final isSeller = profileRoles?.contains(UserRole.seller) ?? false;
    final isAdmin = profileRoles?.contains(UserRole.admin) ?? false;

    final userCanAccess = isSeller || isAdmin;

    AppLogger.d(
      '_AddProductButton.build() → isSeller=$isSeller, isAdmin=$isAdmin, userCanAccess=$userCanAccess',
      tag: 'home',
    );

    // Show only for sellers/admins to match server-side validation.
    if (!userCanAccess) {
      AppLogger.d('User cannot access → returning shrink()', tag: 'home');
      return const SizedBox.shrink();
    }

    // Must match server-side validation: admin OR verified seller.
    final canAddProducts = isAdmin || isVerifiedSeller;
    AppLogger.d(
      'isVerifiedSeller=$isVerifiedSeller, canAddProducts=$canAddProducts',
      tag: 'home',
    );

    return Semantics(
      button: true,
      label: 'btn-add-product',
      child: IconButton(
        key: const Key('home_add_product_button'),
        tooltip: 'home.add_product'.tr(),
        icon: const Icon(
          Icons.add_box_outlined,
          color: DesignTokens.textOnPrimary,
        ),
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
      ),
    );
  }
}

// ============================================================================
// EXTRACTED WIDGETS - Each only rebuilds when its specific data changes
// ============================================================================

class _CategoryChips extends ConsumerWidget {
  final HomeViewModel homeNotifier;

  const _CategoryChips({required this.homeNotifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategoryId = ref.watch(
      homeViewModelProvider.select((state) => state.selectedCategoryId),
    );
    // All breakpoints: horizontal scroll — consistent UI across mobile/tablet/desktop
    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        physics: const ClampingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: productCategories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final category = isAll ? null : productCategories[index - 1];
          final isSelected = isAll
              ? selectedCategoryId == null
              : selectedCategoryId == category?.categoryId;
          return _buildChip(context, isAll, category, isSelected);
        },
      ),
    );
  }

  Widget _buildChip(
    BuildContext context,
    bool isAll,
    ProductCategories? category,
    bool isSelected,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBg = isDark
        ? DesignTokens.darkSurface
        : DesignTokens.surface;
    final unselectedText = isDark
        ? DesignTokens.textOnDark
        : DesignTokens.textPrimary;
    final unselectedBorder = isDark
        ? DesignTokens.primary.withValues(alpha: 0.25)
        : DesignTokens.textSecondary.withValues(alpha: 0.3);
    return Semantics(
      label: isAll
          ? 'category-chip-all'
          : 'category-chip-${category!.categoryId}',
      child: Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 4),
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
            color: !isSelected ? unselectedBg : null,
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            border: Border.all(
              color: isSelected ? DesignTokens.primary : unselectedBorder,
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
          child: Semantics(
            label: isAll
                ? 'btn-hero-category-all'
                : 'btn-hero-category-${category!.categoryId}',
            button: true,
            child: Material(
              color: DesignTokens.transparent,
              child: InkWell(
                onTap: () {
                  homeNotifier.onCategorySelected(
                    isAll ? null : category!.categoryId,
                  );
                },
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                splashColor: DesignTokens.white.withValues(alpha: 0.2),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Text(
                    isAll ? 'home.category_all'.tr() : category!.name.tr(),
                    style: TextStyle(
                      color: isSelected
                          ? DesignTokens.textOnPrimary
                          : unselectedText,
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
          physics: const ClampingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: subcategories.length + 1, // +1 for "All"
          itemBuilder: (context, index) {
            final isAll = index == 0;
            final subcategory = isAll ? null : subcategories[index - 1];
            final isSelected = isAll
                ? selectedSubcategory == null
                : selectedSubcategory == subcategory;

            return Semantics(
              label: isAll
                  ? 'subcategory-chip-all'
                  : 'subcategory-chip-$subcategory',
              child: Padding(
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
                    color: DesignTokens.transparent,
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
              ),
            );
          },
        ),
      ),
    );
  }
}
