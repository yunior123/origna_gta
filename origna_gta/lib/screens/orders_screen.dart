import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/models/generated/base_models.dart' as base;
import 'package:origna_gta/models/generated/models.dart' hide Address;
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/order_widgets.dart';
import 'package:origna_gta/widgets/modern_skeleton_loader.dart';

/// Buyer orders list with status badges, sorted by creation date descending.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _FilterRow extends StatelessWidget {
  final String selectedFilter;

  final ValueChanged<String> onFilterSelected;
  const _FilterRow({
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _OrderFilterChip(
            label: 'orders.filter_all'.tr(),
            selected: selectedFilter == _OrderFilter.all,
            onTap: () => onFilterSelected(_OrderFilter.all),
          ),
          const SizedBox(width: 8),
          _OrderFilterChip(
            label: 'orders.filter_active'.tr(),
            selected: selectedFilter == _OrderFilter.active,
            onTap: () => onFilterSelected(_OrderFilter.active),
          ),
          const SizedBox(width: 8),
          _OrderFilterChip(
            label: 'orders.filter_delivered'.tr(),
            selected: selectedFilter == _OrderFilter.delivered,
            onTap: () => onFilterSelected(_OrderFilter.delivered),
          ),
          const SizedBox(width: 8),
          _OrderFilterChip(
            label: 'orders.filter_cancelled'.tr(),
            selected: selectedFilter == _OrderFilter.cancelled,
            onTap: () => onFilterSelected(_OrderFilter.cancelled),
          ),
        ],
      ),
    );
  }
}

// Filter identifiers — no magic strings
class _OrderFilter {
  static const String all = 'all';
  static const String active = 'active';
  static const String delivered = OrderStatusValues.delivered;
  static const String cancelled = OrderStatusValues.cancelled;
}

class _OrderFilterChip extends StatelessWidget {
  final String label;

  final bool selected;
  final VoidCallback onTap;
  const _OrderFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'tab-order-filter-$label',
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: selected
              ? const BoxDecoration(
                  gradient: DesignTokens.primaryGradient,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                )
              : BoxDecoration(
                  border: Border.all(
                    color: isDark
                        ? DesignTokens.darkOutline
                        : DesignTokens.outline,
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  color: isDark ? DesignTokens.darkCard : DesignTokens.surface,
                ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? DesignTokens.textOnPrimary
                  : (isDark
                        ? DesignTokens.textOnDarkSecondary
                        : DesignTokens.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shimmer skeleton shown while the orders list loads.
class _OrdersLoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ModernSkeletonLoader.wrap(
      isDark: isDark,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 5,
        itemBuilder: (context, i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 90,
          decoration: BoxDecoration(
            color: isDark ? DesignTokens.darkCard : DesignTokens.white,
            borderRadius: BorderRadius.circular(DesignTokens.radius16),
          ),
        ),
      ),
    );
  }
}

/// Private provider for OrdersScreen filter state
final _ordersFilterProvider = StateProvider.autoDispose<String>(
  (_) => _OrderFilter.all,
);

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  static const List<OrderStatus> _activeStatuses = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.processing,
    OrderStatus.shipped,
    OrderStatus.inTransit,
  ];

  static const List<OrderStatus> _cancelledStatuses = [
    OrderStatus.cancelled,
    OrderStatus.failed,
    OrderStatus.expired,
    OrderStatus.refunded,
    OrderStatus.partiallyRefunded,
  ];

  @override
  Widget build(BuildContext context) {
    final selectedFilter = ref.watch(_ordersFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoggedIn = ref.watch(currentUserProvider.select((u) => u != null));

    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBarFactory.simple(title: 'orders.my_orders'.tr()),
        body: AnimatedEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'auth.sign_in_required'.tr(),
          subtitle: 'orders.order_history_desc'.tr(),
        ),
      );
    }

    final ordersAsync = ref.watch(buyerOrdersProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: DesignTokens.backgroundGradient(isDark: isDark),
      ),
      child: Scaffold(
        key: const Key('orders_screen_app_bar'),
        appBar: AppBarFactory.simple(title: 'orders.my_orders'.tr()),
        backgroundColor: DesignTokens.transparent,
        body: ordersAsync.when(
          loading: () => _OrdersLoadingSkeleton(),
          error: (error, stack) => _buildErrorState(context, error),
          data: (orders) {
            if (orders.isEmpty) {
              return AnimatedEmptyState(
                key: const Key('orders_empty_message'),
                icon: Icons.shopping_bag_outlined,
                title: 'orders.no_orders'.tr(),
                subtitle: 'orders.no_orders_desc'.tr(),
                showMascot: true,
                action: ModernButton(
                  label: 'cart.start_shopping'.tr(),
                  icon: Icons.storefront_outlined,
                  onPressed: () => appGoNamed(context, AppRoutes.home),
                ),
              );
            }

            final pendingApprovalsCount = orders
                .where(
                  (o) =>
                      o.shippingApprovalStatus ==
                      ShippingApprovalStatus.pending,
                )
                .length;
            final visibleOrders = _applyFilter(orders, selectedFilter);

            // On desktop, cap order list to readable width (840px) — cards shouldn't stretch to 1200px
            final ordersMaxWidth = ResponsiveBreakpoints.isDesktop(context)
                ? 840.0
                : ResponsiveBreakpoints.contentMaxWidth.toDouble();

            return Column(
              children: [
                if (pendingApprovalsCount > 0)
                  PendingApprovalsBanner(count: pendingApprovalsCount),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: ordersMaxWidth),
                    child: _FilterRow(
                      selectedFilter: selectedFilter,
                      onFilterSelected: (filter) =>
                          ref.read(_ordersFilterProvider.notifier).state =
                              filter,
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: ordersMaxWidth),
                      child: RefreshIndicator(
                        color: DesignTokens.primary,
                        onRefresh: () async =>
                            ref.invalidate(buyerOrdersProvider),
                        child: visibleOrders.isEmpty
                            ? _buildEmptyFilter()
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                itemCount: visibleOrders.length,
                                itemBuilder: (context, index) {
                                  return FadeSlideIn(
                                    delay: Duration(
                                      milliseconds: 50 * index.clamp(0, 8),
                                    ),
                                    child: BuyerOrderCard(
                                      order: visibleOrders[index],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Order> _applyFilter(List<Order> orders, String selectedFilter) {
    switch (selectedFilter) {
      case _OrderFilter.active:
        return orders
            .where((o) => _activeStatuses.contains(o.orderStatus))
            .toList();
      case _OrderFilter.delivered:
        return orders
            .where((o) => o.orderStatus == OrderStatus.delivered)
            .toList();
      case _OrderFilter.cancelled:
        return orders
            .where((o) => _cancelledStatuses.contains(o.orderStatus))
            .toList();
      default:
        return orders;
    }
  }

  Widget _buildEmptyFilter() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 1,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(top: 64),
        child: AnimatedEmptyState(
          icon: Icons.inbox_outlined,
          title: 'orders.no_orders_found'.tr(),
          subtitle: 'orders.no_orders_match'.tr(),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final message = AppError.getMessage(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: DesignTokens.error,
            ),
            const SizedBox(height: 16),
            Semantics(
              label: 'text-orders-load-error',
              child: Text(
                'orders.unable_to_load'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: DesignTokens.textSecondary),
            ),
            const SizedBox(height: 24),
            ModernButton(
              onPressed: () => ref.invalidate(buyerOrdersProvider),
              label: 'orders.retry'.tr(),
              semanticsLabel: 'btn-retry-load-orders',
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══ Widget Previews ═══

const _previewOrdersImageBase = 'https://fastly.picsum.photos/id';

String _previewOrdersImage(int id, {int width = 900, int height = 900}) =>
    '$_previewOrdersImageBase/$id/$width/$height.jpg';

final _previewBuyerOrdersUser = AppAuthUser(
  uid: 'preview-buyer-orders',
  email: 'buyer.orders@origna.ca',
  emailVerified: true,
);

final _previewBuyerOrders = [
  Order(
    orderId: 'buyer-order-preview-1',
    userId: 'preview-buyer-orders',
    items: [
      OrderItem(
        productId: 'buyer-product-1',
        cartItemId: 'buyer-cart-1',
        name: 'Premium Espresso Beans',
        description: 'Small-batch roasted beans from a Toronto roastery.',
        priceCents: 2200,
        quantity: 2,
        imageUrls: [_previewOrdersImage(431)],
        sellerId: 'seller-preview-1',
        sellerName: 'North Roast Co.',
        status: DeliveryStatusValues.shipped,
        shippedAt: DateTime(2026, 4, 14),
      ),
    ],
    totalAmountCents: 5424,
    subtotalCents: 4400,
    shippingCostCents: 700,
    taxAmountCents: 324,
    taxes: const Taxes(gstCents: 0, pstCents: 0, qstCents: 0, hstCents: 324),
    orderStatus: OrderStatus.shipped,
    paymentStatus: PaymentStatus.paid,
    createdAt: DateTime(2026, 4, 12),
    shippingAddress: base.Address(
      street: '101 Queen St E',
      city: 'Toronto',
      state: 'ON',
      postalCode: 'M5C 1S2',
      country: 'CA',
    ),
  ),
  Order(
    orderId: 'buyer-order-preview-2',
    userId: 'preview-buyer-orders',
    items: [
      OrderItem(
        productId: 'buyer-product-2',
        cartItemId: 'buyer-cart-2',
        name: 'Wool Throw Blanket',
        description: 'Soft Canadian wool blanket in charcoal grey.',
        priceCents: 8900,
        quantity: 1,
        imageUrls: [_previewOrdersImage(1062)],
        sellerId: 'seller-preview-2',
        sellerName: 'Halifax Loom',
        status: DeliveryStatusValues.delivered,
        deliveredAt: DateTime(2026, 4, 8),
      ),
    ],
    totalAmountCents: 10617,
    subtotalCents: 8900,
    shippingCostCents: 950,
    taxAmountCents: 767,
    taxes: const Taxes(gstCents: 0, pstCents: 0, qstCents: 0, hstCents: 767),
    orderStatus: OrderStatus.delivered,
    paymentStatus: PaymentStatus.paid,
    createdAt: DateTime(2026, 4, 4),
    shippingAddress: base.Address(
      street: '55 Bloor St W',
      city: 'Toronto',
      state: 'ON',
      postalCode: 'M4W 1A5',
      country: 'CA',
    ),
  ),
];

final _previewBuyerOrdersPendingApproval = [
  ..._previewBuyerOrders,
  Order(
    orderId: 'buyer-order-preview-3',
    userId: 'preview-buyer-orders',
    items: [
      OrderItem(
        productId: 'buyer-product-3',
        cartItemId: 'buyer-cart-3',
        name: 'Ultra Long Preview Product Name For Tight Mobile Cards',
        description:
            'Preview order that keeps shipping approval and long text visible.',
        priceCents: 14999,
        quantity: 1,
        imageUrls: [_previewOrdersImage(366)],
        sellerId: 'seller-preview-3',
        sellerName: 'Longform Atelier Montreal Preview Collective',
        status: DeliveryStatusValues.pending,
        isPerishable: true,
      ),
    ],
    totalAmountCents: 16949,
    subtotalCents: 14999,
    shippingCostCents: 0,
    taxAmountCents: 1950,
    taxes: const Taxes(gstCents: 0, pstCents: 0, qstCents: 0, hstCents: 1950),
    orderStatus: OrderStatus.confirmed,
    paymentStatus: PaymentStatus.authorized,
    shippingApprovalRequired: true,
    shippingApprovalStatus: ShippingApprovalStatus.pending,
    pendingTotalCents: 1200,
    actualShippingCents: 1200,
    createdAt: DateTime(2026, 4, 16),
    shippingAddress: base.Address(
      street: '777 Front St W',
      city: 'Toronto',
      state: 'ON',
      postalCode: 'M5V 2B7',
      country: 'CA',
    ),
  ),
];

Widget _orders({List<Order>? orders}) => previewScopeLoggedIn(
  uid: _previewBuyerOrdersUser.uid,
  extraOverrides: [
    currentUserProvider.overrideWith((ref) => _previewBuyerOrdersUser),
    buyerOrdersProvider.overrideWith(
      (ref) => Stream.value(orders ?? _previewBuyerOrders),
    ),
  ],
  child: const OrdersScreen(),
);

Widget _ordersEmpty() => previewScopeLoggedIn(
  uid: _previewBuyerOrdersUser.uid,
  extraOverrides: [
    currentUserProvider.overrideWith((ref) => _previewBuyerOrdersUser),
    buyerOrdersProvider.overrideWith((ref) => Stream.value([])),
  ],
  child: const OrdersScreen(),
);

Widget _ordersLoading() => previewScopeLoggedIn(
  uid: _previewBuyerOrdersUser.uid,
  extraOverrides: [
    currentUserProvider.overrideWith((ref) => _previewBuyerOrdersUser),
    buyerOrdersProvider.overrideWith((ref) => const Stream.empty()),
  ],
  child: const OrdersScreen(),
);

Widget _ordersFrench() => previewScopeLoggedIn(
  uid: _previewBuyerOrdersUser.uid,
  extraOverrides: [
    currentUserProvider.overrideWith((ref) => _previewBuyerOrdersUser),
    buyerOrdersProvider.overrideWith(
      (ref) => Stream.value(_previewBuyerOrdersPendingApproval),
    ),
  ],
  child: const OrdersScreen(),
);

Widget _ordersPendingApproval() => previewScopeLoggedIn(
  uid: _previewBuyerOrdersUser.uid,
  extraOverrides: [
    currentUserProvider.overrideWith((ref) => _previewBuyerOrdersUser),
    buyerOrdersProvider.overrideWith(
      (ref) => Stream.value(_previewBuyerOrdersPendingApproval),
    ),
  ],
  child: const OrdersScreen(),
);

@Preview(
  name: 'Orders Feed Dark — Mobile',
  group: 'Order Screens',
  size: Size(390, 844),
)
Widget previewOrdersScreenMobile() => previewMobile(child: _orders());

@Preview(
  name: 'Orders Feed Dark — Desktop',
  group: 'Order Screens',
  size: Size(1280, 800),
)
Widget previewOrdersScreenDesktop() => previewDesktop(child: _orders());

@Preview(
  name: 'Orders Feed Light — Desktop',
  group: 'Order Screens',
  size: Size(1280, 800),
)
Widget previewOrdersScreenLightDesktop() =>
    previewDesktop(theme: previewLightTheme, child: _orders());

@Preview(
  name: 'Orders Empty Dark — Mobile',
  group: 'Order Screens',
  size: Size(390, 844),
)
Widget previewOrdersEmptyMobile() => previewMobile(child: _ordersEmpty());

@Preview(
  name: 'Orders Empty Light — Desktop',
  group: 'Order Screens',
  size: Size(1280, 800),
)
Widget previewOrdersEmptyLightDesktop() =>
    previewDesktop(theme: previewLightTheme, child: _ordersEmpty());

@Preview(
  name: 'Orders Pending Approval — Mobile',
  group: 'Order Screens',
  size: Size(390, 844),
)
Widget previewOrdersPendingApprovalMobile() =>
    previewMobile(child: _ordersPendingApproval());

@Preview(
  name: 'Orders FR — Mobile',
  group: 'Order Screens',
  size: Size(390, 844),
)
Widget previewOrdersFrenchMobile() =>
    previewMobile(locale: const Locale('fr'), child: _ordersFrench());

@Preview(
  name: 'Orders Loading Dark — Tablet',
  group: 'Order Screens',
  size: Size(768, 1024),
)
Widget previewOrdersLoadingTablet() => previewTablet(child: _ordersLoading());
