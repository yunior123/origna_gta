part of '../seller_orders_screen.dart';

class _SellerOrderCard extends ConsumerWidget {
  final Order order;
  final String sellerId;

  const _SellerOrderCard({required this.order, required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerItems = order.items
        .where((item) => item.sellerId == sellerId)
        .toList();
    if (sellerItems.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sellerTotal = sellerItems.fold<double>(
      0.0,
      (acc, item) => acc + (item.price * item.quantity),
    );
    // Per-seller fee = seller's own subtotal × platform fee rate (not the full order fee)
    final platformFee =
        sellerTotal * (BusinessRules.platformFeePercent / 100.0);
    final sellerNet = sellerTotal - platformFee;

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacing16),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurfaceVariant : DesignTokens.white,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(
          color: isDark
              ? DesignTokens.white.withValues(alpha: 0.06)
              : DesignTokens.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(sellerTotal, platformFee, sellerNet),
            const SizedBox(height: 12),
            _buildAddressRow(isDark),
            Divider(
              height: 28,
              color: isDark
                  ? DesignTokens.white.withValues(alpha: 0.08)
                  : DesignTokens.outlineVariant,
            ),
            if (order.paymentStatus == PaymentStatus.awaitingPayment)
              _buildAuthorizationBanner(context, ref, isDark),
            // Delivery instructions from buyer
            if (order.deliveryInstructions != null &&
                order.deliveryInstructions!.isNotEmpty)
              _buildDeliveryInstructionsBanner(isDark),
            Text(
              'seller.your_items'.tr(),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isDark ? DesignTokens.white : DesignTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...sellerItems.map(
              (item) => SellerOrderItemTile(
                item: item,
                isDark: isDark,
                isAuthorized:
                    order.paymentStatus == PaymentStatus.awaitingPayment,
                onMarkShipped: () =>
                    _showMarkAsShippedDialog(context, ref, item),
                onEditTracking: () => _showMarkAsShippedDialog(
                  context,
                  ref,
                  item,
                  prefillTracking: item.trackingNumber,
                  prefillCarrier: item.carrier,
                  prefillCarrierNote: item.carrierNote,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    double sellerTotal,
    double platformFee,
    double sellerNet,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${'seller.order_prefix'.tr()}${order.orderId.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMM dd, yyyy').format(order.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: DesignTokens.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: DesignTokens.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Tooltip(
            message:
                'Gross: \$${sellerTotal.toStringAsFixed(2)} − \$${platformFee.toStringAsFixed(2)} fee',
            child: Text(
              '\$${sellerNet.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: DesignTokens.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressRow(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? DesignTokens.white.withValues(alpha: 0.04)
            : DesignTokens.surfaceVariant,
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 14,
            color: DesignTokens.textSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              order.shippingAddress?.formattedAddress ?? '',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? DesignTokens.textDisabled
                    : DesignTokens.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorizationBanner(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    final actualShipping = order.actualShipping;
    final approvalStatus = order.shippingApprovalStatus;
    final isLoading = ref.watch(
      sellerOrdersViewModelProvider.select((state) => state.isLoading),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.primary.withValues(alpha: 0.08),
            DesignTokens.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: DesignTokens.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.payment_rounded,
                  size: 16,
                  color: DesignTokens.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'seller.payment_authorized'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.primary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            actualShipping <= 0.0
                ? 'seller.enter_shipping_cost'.tr()
                : (approvalStatus == ShippingApprovalStatus.pending
                      ? 'seller.waiting_buyer_approval'.tr()
                      : 'seller.ready_to_capture'.tr()),
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? DesignTokens.textDisabled
                  : DesignTokens.textSecondary,
            ),
          ),
          if (actualShipping <= 0.0) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: ModernButton(
                label: 'seller.confirm_shipping_ship'.tr(),
                onPressed: isLoading
                    ? null
                    : () => showUpdateShippingDialog(
                        context,
                        ref,
                        orderId: order.orderId,
                        estimatedShipping: order.shippingCost,
                        carrierProvider: _updateShippingDialogCarrierProvider,
                      ),
                isLoading: isLoading,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryInstructionsBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: DesignTokens.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: DesignTokens.info.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: DesignTokens.info.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.edit_note_outlined,
              size: 16,
              color: DesignTokens.info,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'seller.delivery_instructions'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.info,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.deliveryInstructions!,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? DesignTokens.outlineVariant
                        : DesignTokens.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMarkAsShippedDialog(
    BuildContext context,
    WidgetRef ref,
    OrderItem item, {
    String? prefillTracking,
    String? prefillCarrier,
    String? prefillCarrierNote,
  }) {
    showMarkShippedDialog(
      context,
      ref,
      orderId: order.orderId,
      productId: item.productId,
      carrierProvider: _shippedDialogCarrierProvider,
      prefillTracking: prefillTracking,
      prefillCarrier: prefillCarrier,
      prefillCarrierNote: prefillCarrierNote,
    );
  }
}
