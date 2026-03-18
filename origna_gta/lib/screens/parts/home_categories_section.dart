// coverage:ignore-file
part of '../home_screen.dart';
// ============================================================================
// GAP #7 — Search autocomplete overlay
// ============================================================================

class _SearchOverlay extends StatelessWidget {
  final bool isDark;
  final bool showRecent;
  final List<String> recentSearches;
  final List<String> suggestions;
  final ValueChanged<String> onTap;
  final VoidCallback onClearRecent;

  const _SearchOverlay({
    required this.isDark,
    required this.showRecent,
    required this.recentSearches,
    required this.suggestions,
    required this.onTap,
    required this.onClearRecent,
  });

  @override
  Widget build(BuildContext context) {
    final items = showRecent ? recentSearches : suggestions;
    final label = showRecent
        ? 'home.recent_searches'.tr()
        : 'home.suggestions'.tr();

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(DesignTokens.radius12),
      color: isDark ? DesignTokens.darkSurface : DesignTokens.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  if (showRecent)
                    Semantics(
                      label: 'btn-clear-recent-searches',
                      button: true,
                      child: TextButton(
                        onPressed: onClearRecent,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          foregroundColor: DesignTokens.primary,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(fontSize: 11),
                        ),
                        child: Text('home.clear_recent'.tr()),
                      ),
                    ),
                ],
              ),
            ),
            for (final item in items)
              Semantics(
                label: 'btn-search-history-item',
                button: true,
                child: InkWell(
                  onTap: () => onTap(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          showRecent
                              ? Icons.history_rounded
                              : Icons.search_rounded,
                          size: 16,
                          color: DesignTokens.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? DesignTokens.textOnDark
                                  : DesignTokens.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
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
              excludeSemantics: true,
              child: IconButton(
                key: const Key('home_settings_button'),
                tooltip: 'home.settings'.tr(),
                icon: const Icon(Icons.settings_outlined, color: DesignTokens.textOnPrimary),
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

// ============================================================================
// GAP #1 + GAP #2 — Sort & Filter row
// ============================================================================

class _SortAndFilterRow extends ConsumerWidget {
  final HomeViewModel homeNotifier;

  const _SortAndFilterRow({required this.homeNotifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSort = ref.watch(
      homeViewModelProvider.select((s) => s.selectedSort),
    );
    final hasPriceFilter = ref.watch(
      homeViewModelProvider.select((s) => s.hasPriceFilter),
    );
    final minCents = ref.watch(
      homeViewModelProvider.select((s) => s.minPriceCents),
    );
    final maxCents = ref.watch(
      homeViewModelProvider.select((s) => s.maxPriceCents),
    );
    final canadaOnly = ref.watch(
      homeViewModelProvider.select((s) => s.canadaOnly),
    );

    final isSortActive = selectedSort != SortOption.relevance;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          // Sort chip (GAP #1)
          Semantics(
            label: 'btn-home-sort',
            button: true,
            child: GestureDetector(
              onTap: () => _showSortSheet(context, selectedSort),
              child: AnimatedContainer(
                duration: DesignTokens.durationFast,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSortActive
                      ? DesignTokens.primary.withValues(alpha: 0.12)
                      : DesignTokens.surfaceVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                  border: Border.all(
                    color: isSortActive
                        ? DesignTokens.primary
                        : DesignTokens.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sort_rounded,
                      size: 14,
                      color: isSortActive
                          ? DesignTokens.primary
                          : DesignTokens.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isSortActive
                          ? _sortLabel(selectedSort)
                          : 'home.sort_by'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSortActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSortActive
                            ? DesignTokens.primary
                            : DesignTokens.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: isSortActive
                          ? DesignTokens.primary
                          : DesignTokens.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Price filter chip (GAP #2)
          Semantics(
            label: 'btn-home-price-filter',
            button: true,
            child: GestureDetector(
              onTap: () => _showPriceSheet(context, minCents, maxCents),
              child: AnimatedContainer(
                duration: DesignTokens.durationFast,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: hasPriceFilter
                      ? DesignTokens.secondary.withValues(alpha: 0.12)
                      : DesignTokens.surfaceVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                  border: Border.all(
                    color: hasPriceFilter
                        ? DesignTokens.secondary
                        : DesignTokens.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.attach_money_rounded,
                      size: 14,
                      color: hasPriceFilter
                          ? DesignTokens.secondary
                          : DesignTokens.textSecondary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      hasPriceFilter
                          ? 'home.filter_price_range'.tr(
                              namedArgs: {
                                'min': '\$${(minCents ?? 0) ~/ 100}',
                                'max': '\$${(maxCents ?? 50000) ~/ 100}',
                              },
                            )
                          : 'home.filter_price'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: hasPriceFilter
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: hasPriceFilter
                            ? DesignTokens.secondary
                            : DesignTokens.textSecondary,
                      ),
                    ),
                    if (hasPriceFilter) ...[
                      const SizedBox(width: 4),
                      Semantics(
                        label: 'btn-close-price-filter',
                        button: true,
                        child: GestureDetector(
                          onTap: homeNotifier.clearPriceFilter,
                          child: Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: DesignTokens.secondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Canada Only toggle chip
          Semantics(
            label: 'btn-home-canada-only',
            button: true,
            toggled: canadaOnly,
            child: GestureDetector(
              onTap: homeNotifier.onToggleCanadaOnly,
              child: AnimatedContainer(
                duration: DesignTokens.durationFast,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: canadaOnly
                      ? DesignTokens.canadaRed.withValues(alpha: 0.12)
                      : DesignTokens.surfaceVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                  border: Border.all(
                    color: canadaOnly
                        ? DesignTokens.canadaRed
                        : DesignTokens.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🍁', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      'home.canada_only'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: canadaOnly
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: canadaOnly
                            ? DesignTokens.canadaRed
                            : DesignTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPriceSheet(BuildContext context, int? currentMin, int? currentMax) {
    // RangeSlider values in dollars (0–500), step handled by divisions
    double rangeMin = (currentMin ?? 0) / 100.0;
    double rangeMax = (currentMax ?? 50000) / 100.0;
    const double sliderMin = 0;
    const double sliderMax = 500;
    const int divisions = 100; // $5 steps

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radius16),
        ),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'home.filter_price'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        homeNotifier.clearPriceFilter();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: DesignTokens.primary,
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                      child: Text('home.filter_price_any'.tr()),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${rangeMin.toInt()}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '\$${rangeMax.toInt()}${rangeMax >= sliderMax ? "+" : ""}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                RangeSlider(
                  values: RangeValues(
                    rangeMin.clamp(sliderMin, sliderMax),
                    rangeMax.clamp(sliderMin, sliderMax),
                  ),
                  min: sliderMin,
                  max: sliderMax,
                  divisions: divisions,
                  activeColor: DesignTokens.primary,
                  inactiveColor: DesignTokens.outline.withValues(alpha: 0.3),
                  onChanged: (values) {
                    setSheetState(() {
                      rangeMin = values.start;
                      rangeMax = values.end;
                    });
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: Semantics(
                    label: 'btn-price-filter-apply',
                    button: true,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: DesignTokens.primary,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        final minC = (rangeMin * 100).round();
                        final maxC = (rangeMax * 100).round();
                        homeNotifier.onPriceFilterChanged(
                          minC > 0 ? minC : null,
                          maxC < sliderMax * 100 ? maxC : null,
                        );
                      },
                      child: Text('home.filter_apply'.tr()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSortSheet(BuildContext context, SortOption current) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radius16),
        ),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text(
                  'home.sort_by'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Divider(height: 1),
              for (final option in SortOption.values)
                ListTile(
                  dense: true,
                  title: Text(
                    _sortLabel(option),
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: current == option
                      ? Icon(
                          Icons.check_rounded,
                          color: DesignTokens.primary,
                          size: 18,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    homeNotifier.onSortChanged(option);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _sortLabel(SortOption sort) {
    return switch (sort) {
      SortOption.relevance => 'home.sort_relevance'.tr(),
      SortOption.priceLowToHigh => 'home.sort_price_low'.tr(),
      SortOption.priceHighToLow => 'home.sort_price_high'.tr(),
      SortOption.newest => 'home.sort_newest'.tr(),
    };
  }
}
