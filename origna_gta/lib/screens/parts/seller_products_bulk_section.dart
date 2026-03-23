part of '../seller_products_screen.dart';

// ============================================================================
// BULK ACTIONS — Action bar, skeleton loader, Q&A badge
// ============================================================================

class _BulkActionBar extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final bool isLoading;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback onActivate;
  final VoidCallback onPause;
  final VoidCallback onArchive;

  const _BulkActionBar({
    required this.selectedCount,
    required this.totalCount,
    required this.isLoading,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onActivate,
    required this.onPause,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: DesignTokens.primary.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(
            color: DesignTokens.primary.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'btn-clear-bulk-selection',
            child: GestureDetector(
              onTap: onClearSelection,
              child: const Icon(Icons.close_rounded, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            tr(
              'seller.selected_count',
              namedArgs: {'count': selectedCount.toString()},
            ),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          if (selectedCount < totalCount) ...[
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: 'btn-select-all-products',
              child: GestureDetector(
                onTap: onSelectAll,
                child: Text(
                  tr('seller.select_all'),
                  style: TextStyle(color: DesignTokens.primary, fontSize: 13),
                ),
              ),
            ),
          ],
          const Spacer(),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: ModernLoadingIndicator(strokeWidth: 2, centered: false),
            )
          else ...[
            _ActionChip(
              label: tr('seller.activate'),
              semanticsLabel: 'btn-bulk-activate',
              icon: Icons.check_circle_outline,
              color: DesignTokens.success,
              onTap: onActivate,
            ),
            const SizedBox(width: 6),
            _ActionChip(
              label: tr('seller.pause'),
              semanticsLabel: 'btn-bulk-pause',
              icon: Icons.pause_circle_outline,
              color: DesignTokens.warning,
              onTap: onPause,
            ),
            const SizedBox(width: 6),
            _ActionChip(
              label: tr('seller.archive'),
              semanticsLabel: 'btn-bulk-archive',
              icon: Icons.archive_outlined,
              color: DesignTokens.error,
              onTap: onArchive,
            ),
          ],
        ],
      ),
    );
  }
}

/// Shimmer skeleton for seller products list loading state.
class _SellerProductsSkeleton extends StatelessWidget {
  final bool isDark;
  const _SellerProductsSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ModernSkeletonLoader.wrap(
      isDark: isDark,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(DesignTokens.spacing16),
        itemCount: 5,
        itemBuilder: (_, index) => Container(
          margin: const EdgeInsets.only(bottom: DesignTokens.spacing12),
          height: 100,
          decoration: BoxDecoration(
            color: DesignTokens.white,
            borderRadius: BorderRadius.circular(DesignTokens.radius16),
          ),
        ),
      ),
    );
  }
}

// FE-M3: Q&A badge for seller products AppBar — matches seller_orders_screen pattern
class _UnansweredQaBadge extends ConsumerWidget {
  final String sellerId;
  const _UnansweredQaBadge({required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count =
        ref.watch(
          sellerUnansweredQaProvider(sellerId).select((a) => a.valueOrNull),
        ) ??
        0;
    return Tooltip(
      message: count > 0
          ? 'seller.unanswered_questions_plural'.tr(args: [count.toString()])
          : 'seller.no_pending_questions'.tr(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Semantics(
            button: true,
            label: 'btn-seller-qa-badge',
            child: IconButton(
              icon: const Icon(Icons.forum_outlined),
              tooltip: count > 0
                  ? 'seller.unanswered_questions_plural'.tr(
                      args: [count.toString()],
                    )
                  : 'seller.no_pending_questions'.tr(),
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.sellerOrders),
            ),
          ),
          if (count > 0)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: DesignTokens.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: DesignTokens.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: DesignTokens.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
