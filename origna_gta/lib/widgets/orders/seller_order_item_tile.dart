import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';

/// A single order-item tile shown inside the seller order card.
///
/// Displays item thumbnail, name, quantity, delivery status chip,
/// carrier info, refund date, buyer note, and action buttons
/// (mark-shipped / edit-tracking).
class SellerOrderItemTile extends StatelessWidget {
  final OrderItem item;
  final bool isDark;
  final bool isAuthorized;
  final VoidCallback? onMarkShipped;
  final VoidCallback? onEditTracking;

  const SellerOrderItemTile({
    super.key,
    required this.item,
    required this.isDark,
    required this.isAuthorized,
    this.onMarkShipped,
    this.onEditTracking,
  });

  @override
  Widget build(BuildContext context) {
    final statusStr = item.status;
    final isRefunded = statusStr == DeliveryStatusValues.refunded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: _buildThumbnail(),
        title: _buildTitle(),
        subtitle: _buildSubtitle(statusStr),
        // Suppress mark-shipped button for digital items — fulfilled automatically
        trailing: !item.isDigital && !isAuthorized
            ? (statusStr == DeliveryStatusValues.pending && !isRefunded
                  ? _buildMarkShippedButton()
                  : (statusStr == DeliveryStatusValues.shipped
                        ? _buildEditTrackingButton()
                        : null))
            : null,
      ),
    );
  }

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radius8),
      child: item.imageUrls.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: item.imageUrls.first,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: DesignTokens.surfaceVariant,
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                  gradient: LinearGradient(
                    colors: [
                      DesignTokens.primary.withValues(alpha: 0.1),
                      DesignTokens.secondary.withValues(alpha: 0.07),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: DesignTokens.primary.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  color: DesignTokens.primary.withValues(alpha: 0.5),
                  size: 18,
                ),
              ),
            )
          : Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: DesignTokens.surfaceVariant,
                borderRadius: BorderRadius.circular(DesignTokens.radius8),
              ),
              child: Icon(
                Icons.image_outlined,
                color: DesignTokens.textDisabled,
                size: 20,
              ),
            ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Flexible(
          child: Text(
            item.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (item.isDigital) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: DesignTokens.digital.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.download_outlined,
                  size: 10,
                  color: DesignTokens.digital,
                ),
                const SizedBox(width: 3),
                const Text(
                  'Digital',
                  style: TextStyle(
                    fontSize: 10,
                    color: DesignTokens.digital,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubtitle(String statusStr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${'seller.qty_prefix'.tr()} ${item.quantity}',
                style: TextStyle(
                  fontSize: 12,
                  color: DesignTokens.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusChip(statusStr),
          ],
        ),
        if (item.carrier != null)
          Text(
            '${'seller.carrier_prefix'.tr()} ${item.carrier}',
            style: TextStyle(fontSize: 11, color: DesignTokens.textSecondary),
          ),
        if (item.refundedAt != null)
          Text(
            '${'seller.refunded_prefix'.tr()} ${DateFormat.yMd().format(item.refundedAt!)}',
            style: TextStyle(fontSize: 11, color: DesignTokens.warning),
          ),
        if (item.buyerNote != null && item.buyerNote!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignTokens.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: DesignTokens.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  size: 14,
                  color: DesignTokens.warning,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${'cart.item_note_label'.tr()}: ${item.buyerNote}',
                    style: TextStyle(
                      fontSize: 12,
                      color: DesignTokens.textPrimary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    if (status == DeliveryStatusValues.delivered) {
      color = DesignTokens.success;
    } else if (status == DeliveryStatusValues.shipped) {
      color = DesignTokens.primary;
    } else if (status == DeliveryStatusValues.refunded) {
      color = DesignTokens.warning;
    } else {
      color = DesignTokens.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusDisplayText(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  static String _getStatusDisplayText(String status) {
    if (status == DeliveryStatusValues.pending) {
      return 'seller.status.pending'.tr();
    }
    if (status == DeliveryStatusValues.shipped) {
      return 'seller.status.shipped'.tr();
    }
    if (status == DeliveryStatusValues.delivered) {
      return 'seller.status.delivered'.tr();
    }
    if (status == DeliveryStatusValues.refunded) {
      return 'seller.status.refunded'.tr();
    }
    return status;
  }

  Widget _buildMarkShippedButton() {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
      ),
      child: Semantics(
        button: true,
        label: 'btn-mark-shipped',
        child: IconButton(
          icon: Icon(
            Icons.local_shipping_rounded,
            color: DesignTokens.primary,
            size: 22,
          ),
          tooltip: 'seller.mark_shipped'.tr(),
          onPressed: () {
            HapticFeedback.lightImpact();
            onMarkShipped?.call();
          },
        ),
      ),
    );
  }

  Widget _buildEditTrackingButton() {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
      ),
      child: Semantics(
        button: true,
        label: 'btn-edit-tracking',
        child: IconButton(
          icon: Icon(Icons.edit_rounded, color: DesignTokens.info, size: 20),
          tooltip: 'seller.edit_tracking'.tr(),
          onPressed: () {
            HapticFeedback.lightImpact();
            onEditTracking?.call();
          },
        ),
      ),
    );
  }
}
