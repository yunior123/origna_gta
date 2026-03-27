part of '../seller_products_screen.dart';

// ============================================================================
// PRODUCT CARD — Card, status badges, rejection banner, action chip
// ============================================================================

class _SellerProductCard extends StatelessWidget {
  final Product product;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;

  const _SellerProductCard({
    required this.product,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onToggle,
    required this.onLongPress,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: 'product-card-${product.productId}',
      child: GestureDetector(
        onTap: isSelectionMode ? onToggle : onEdit,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: DesignTokens.durationFast,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? DesignTokens.primary.withValues(alpha: 0.08)
                : isDark
                ? DesignTokens.darkSurfaceVariant
                : DesignTokens.white,
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            border: Border.all(
              color: isSelected
                  ? DesignTokens.primary
                  : DesignTokens.outline.withValues(alpha: 0.15),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.black.withValues(
                  alpha: isDark ? 0.15 : 0.04,
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Selection checkbox
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: isSelected
                        ? DesignTokens.primary
                        : DesignTokens.textDisabled,
                    size: 22,
                  ),
                ),
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrls.first,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            _placeholderImage(),
                        placeholder: (context, url) => _placeholderImage(),
                      )
                    : _placeholderImage(),
              ),
              const SizedBox(width: 12),
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _StatusBadge(status: product.lifecycleStatus),
                        if (product.lifecycleStatus !=
                            ProductLifecycleStatusValues.active) ...[
                          const SizedBox(width: 6),
                          _ApprovalBadge(
                            lifecycleStatus: product.lifecycleStatus,
                          ),
                        ],
                        const Spacer(),
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: DesignTokens.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tr(
                        'seller.stock_count',
                        namedArgs: {'count': product.stockQuantity.toString()},
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: product.stockQuantity <= 0
                            ? DesignTokens.error
                            : product.stockQuantity <= 5
                            ? DesignTokens.warning
                            : DesignTokens.textSecondary,
                      ),
                    ),
                    if (product.lifecycleStatus ==
                            ProductLifecycleStatusValues.rejected &&
                        product.approvalRejectionReason != null &&
                        product.approvalRejectionReason!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _RejectionBanner(
                        reason: product.approvalRejectionReason!,
                        onFixAndResubmit: onEdit,
                      ),
                    ],
                  ],
                ),
              ),
              // Edit arrow — hide when rejection banner is shown (button replaces it)
              if (!isSelectionMode &&
                  product.lifecycleStatus !=
                      ProductLifecycleStatusValues.rejected)
                ExcludeSemantics(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: DesignTokens.textDisabled,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            DesignTokens.primary.withValues(alpha: 0.12),
            DesignTokens.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: DesignTokens.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Icon(
        Icons.camera_alt_outlined,
        color: DesignTokens.primary.withValues(alpha: 0.6),
        size: 22,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      ProductLifecycleStatusValues.active => (
        DesignTokens.success,
        tr('seller.active'),
      ),
      ProductLifecycleStatusValues.paused => (
        DesignTokens.warning,
        tr('seller.pause'),
      ),
      ProductLifecycleStatusValues.archived => (
        DesignTokens.textDisabled,
        tr('seller.archived'),
      ),
      ProductLifecycleStatusValues.draft => (
        DesignTokens.info,
        tr('seller.draft'),
      ),
      ProductLifecycleStatusValues.underReview => (
        DesignTokens.info,
        tr('seller.under_review'),
      ),
      ProductLifecycleStatusValues.rejected => (
        DesignTokens.error,
        tr('seller.rejected'),
      ),
      ProductLifecycleStatusValues.approved => (
        DesignTokens.success,
        tr('seller.approved'),
      ),
      _ => (DesignTokens.textSecondary, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ApprovalBadge extends StatelessWidget {
  final String lifecycleStatus;
  const _ApprovalBadge({required this.lifecycleStatus});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (lifecycleStatus) {
      ProductLifecycleStatusValues.underReview => (
        DesignTokens.info,
        tr('seller.under_review'),
      ),
      ProductLifecycleStatusValues.rejected => (
        DesignTokens.error,
        tr('seller.rejected'),
      ),
      _ => (DesignTokens.textSecondary, lifecycleStatus),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _RejectionBanner extends StatelessWidget {
  final String reason;
  final VoidCallback onFixAndResubmit;
  const _RejectionBanner({
    required this.reason,
    required this.onFixAndResubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DesignTokens.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: DesignTokens.error.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 13,
                color: DesignTokens.error,
              ),
              const SizedBox(width: 4),
              Text(
                tr('seller.rejection_reason_label'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            reason,
            style: TextStyle(fontSize: 11, color: DesignTokens.textSecondary),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Semantics(
              button: true,
              label: 'btn-fix-and-resubmit',
              child: TextButton.icon(
                onPressed: onFixAndResubmit,
                icon: Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: DesignTokens.primary,
                ),
                label: Semantics(
                  label: 'btn-fix-resubmit',
                  button: true,
                  child: Text(
                    tr('seller.fix_and_resubmit'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.primary,
                    ),
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: DesignTokens.primary.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  minimumSize: Size.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final String semanticsLabel;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.semanticsLabel,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
