// coverage:ignore-file
part of '../home_screen.dart';
// ============================================================================
// GAP #6 — Recently Viewed horizontal section
// ============================================================================

class _RecentlyViewedSection extends ConsumerStatefulWidget {
  const _RecentlyViewedSection();

  @override
  ConsumerState<_RecentlyViewedSection> createState() =>
      _RecentlyViewedSectionState();
}

class _RecentlyViewedSectionState
    extends ConsumerState<_RecentlyViewedSection> {
  List<Product> _products = [];
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _products.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'home.recently_viewed'.tr(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? DesignTokens.textOnDark : DesignTokens.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _products.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = _products[index];
              return SizedBox(
                width: 150,
                child: ProductCard(
                  key: Key('recently_viewed_${product.productId}'),
                  productId: product.productId,
                  product: product,
                  userModel: null,
                  heroTagPrefix: 'recently_viewed_image',
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadRecentlyViewed();
  }

  Future<void> _loadRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(LocalStorageKeys.recentlyViewed);
      if (raw == null) {
        if (mounted) setState(() => _loaded = true);
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        if (mounted) setState(() => _loaded = true);
        return;
      }
      final ids = decoded.cast<String>().take(10).toList();
      if (ids.isEmpty) {
        if (mounted) setState(() => _loaded = true);
        return;
      }

      // Fetch products by IDs using the repository
      final repository = ref.read(productRepositoryProvider);
      final products = await repository.fetchProductsByIds(ids);

      // Keep the same order as the stored IDs
      final productMap = {for (final p in products) p.productId: p};
      final ordered = ids
          .where((id) => productMap.containsKey(id))
          .map((id) => productMap[id]!)
          .toList();

      if (mounted) {
        setState(() {
          _products = ordered;
          _loaded = true;
        });
      }
    } catch (e) {
      AppLogger.w('Failed to load recently viewed: $e', tag: 'home');
      if (mounted) setState(() => _loaded = true);
    }
  }
}
