import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/home/home_viewmodel.dart';
import 'package:origna_gta/screens/product_card_screen.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart';

/// Full category browser: grid of all 21 categories → subcategory filter →
/// product results. Reuses [homeViewModelProvider] for filtering.
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> with SingleTickerProviderStateMixin {
  int? _selectedCategoryId;
  String? _selectedSubcategory;

  static const _categoryColors = [
    [Color(0xFF667EEA), Color(0xFF764BA2)],
    [Color(0xFF5CE1E6), Color(0xFF3B82F6)],
    [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFF093FB), Color(0xFFF5576C)],
    [Color(0xFF4FC3F7), Color(0xFF0288D1)],
    [Color(0xFFFFD700), Color(0xFFFF8C00)],
    [Color(0xFFE040FB), Color(0xFF7C4DFF)],
    [Color(0xFF26C6DA), Color(0xFF00897B)],
    [Color(0xFFEF9A9A), Color(0xFFE53935)],
    [Color(0xFF81C784), Color(0xFF388E3C)],
    [Color(0xFFFFB74D), Color(0xFFF57C00)],
    [Color(0xFF90CAF9), Color(0xFF1565C0)],
    [Color(0xFFA5D6A7), Color(0xFF2E7D32)],
    [Color(0xFFF48FB1), Color(0xFFC2185B)],
    [Color(0xFFCE93D8), Color(0xFF6A1B9A)],
    [Color(0xFF80CBC4), Color(0xFF00695C)],
    [Color(0xFFFFCC80), Color(0xFFE65100)],
    [Color(0xFFB0BEC5), Color(0xFF37474F)],
    [Color(0xFFFFD54F), Color(0xFFF9A825)],
    [Color(0xFF80DEEA), Color(0xFF00838F)],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [DesignTokens.gradientStart, DesignTokens.gradientMiddle, DesignTokens.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.grid_view_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              _selectedCategoryId == null
                  ? 'categories.browse_title'.tr()
                  : productCategories[_selectedCategoryId! - 1].name.tr(),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        leading: _selectedCategoryId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() {
                  _selectedCategoryId = null;
                  _selectedSubcategory = null;
                }),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ResponsiveBreakpoints.contentMaxWidth),
          child: _selectedCategoryId == null
              ? _buildCategoryGrid()
              : _buildCategoryDetail(_selectedCategoryId!),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'categories.browse_subtitle'.tr(),
                  style: TextStyle(fontSize: 14, color: DesignTokens.textSecondary),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final cat = productCategories[index];
                final colors = _categoryColors[index % _categoryColors.length];
                return _CategoryTile(
                  category: cat,
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => setState(() {
                    _selectedCategoryId = cat.categoryId;
                    _selectedSubcategory = null;
                  }),
                );
              },
              childCount: productCategories.length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }

  Widget _buildCategoryDetail(int categoryId) {
    final subcategories = SubcategoryConstants.forCategoryId(categoryId);
    final homeNotifier = ref.read(homeViewModelProvider.notifier);

    return Column(
      children: [
        // Subcategory chips
        if (subcategories.isNotEmpty) ...[
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: subcategories.length + 1,
                separatorBuilder: (context, i) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isAll = index == 0;
                  final sub = isAll ? null : subcategories[index - 1];
                  final isSelected = isAll ? _selectedSubcategory == null : _selectedSubcategory == sub;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedSubcategory = sub);
                      homeNotifier.onCategorySelected(categoryId);
                      homeNotifier.onSubcategorySelected(sub);
                    },
                    child: AnimatedContainer(
                      duration: DesignTokens.durationFast,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [DesignTokens.gradientStart, DesignTokens.gradientEnd],
                              )
                            : null,
                        color: isSelected ? null : DesignTokens.surfaceVariant,
                        borderRadius: BorderRadius.circular(18),
                        border: isSelected ? null : Border.all(color: DesignTokens.outline),
                      ),
                      child: Text(
                        isAll ? 'home.category_all'.tr() : sub!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? Colors.white : DesignTokens.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),
        ],
        // Products for this category
        Expanded(child: _CategoryProductList(categoryId: categoryId, subcategory: _selectedSubcategory)),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ProductCategories category;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _CategoryTile({required this.category, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(category.icon, size: 26, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                category.name.tr(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Products list filtered by [categoryId] and optional [subcategory].
/// Delegates to [homeViewModelProvider] so the search/filter logic is shared.
class _CategoryProductList extends ConsumerStatefulWidget {
  final int categoryId;
  final String? subcategory;

  const _CategoryProductList({required this.categoryId, this.subcategory});

  @override
  ConsumerState<_CategoryProductList> createState() => _CategoryProductListState();
}

class _CategoryProductListState extends ConsumerState<_CategoryProductList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(homeViewModelProvider.notifier);
      notifier.onCategorySelected(widget.categoryId);
      notifier.onSubcategorySelected(widget.subcategory);
    });
  }

  @override
  void didUpdateWidget(_CategoryProductList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId || oldWidget.subcategory != widget.subcategory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final notifier = ref.read(homeViewModelProvider.notifier);
        notifier.onCategorySelected(widget.categoryId);
        notifier.onSubcategorySelected(widget.subcategory);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);
    final products = state.products;
    final isLoading = state.isLoading;

    if (isLoading && products.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: DesignTokens.primary),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [DesignTokens.gradientStart, DesignTokens.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: DesignTokens.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: const Icon(Icons.search_off_rounded, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text('categories.no_products'.tr(), style: TextStyle(fontWeight: FontWeight.w600, color: DesignTokens.textPrimary, fontSize: 16)),
            const SizedBox(height: 6),
            Text('categories.no_products_hint'.tr(), style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final fallback = UserModel(uid: '', email: '', name: '', roles: const [UserRoles.buyer], createdAt: DateTime(2024));

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          key: Key('cat_product_${product.productId}'),
          productId: product.productId,
          product: product,
          userModel: userProfile ?? fallback,
        );
      },
    );
  }
}
