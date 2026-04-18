import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/models/generated/base_models.dart' as generated_base;
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:origna_gta/widgets/order_widgets.dart';
import 'package:flutter/widget_previews.dart';

/// Full order details: items, status timeline, tracking, shipping cost approval.
class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderByIdProvider(orderId));

    return OrderDetailScreenLayout(
      orderAsync: orderAsync,
      onRefresh: () => ref.invalidate(orderByIdProvider(orderId)),
      onBack: () => Navigator.of(context).pop(),
    );
  }
}

/// Full order details: items, status timeline, tracking, shipping cost approval.Layout
class OrderDetailScreenLayout extends StatelessWidget {
  final AsyncValue<Order?> orderAsync;
  final VoidCallback onRefresh;
  final VoidCallback onBack;

  const OrderDetailScreenLayout({
    super.key,
    required this.orderAsync,
    required this.onRefresh,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: DesignTokens.backgroundGradient(isDark: isDark),
      ),
      child: Scaffold(
        appBar: AppBarFactory.simple(title: 'orders.order_details'.tr()),
        backgroundColor: DesignTokens.transparent,
        body: orderAsync.when(
          loading: () => const Center(child: ModernLoadingIndicator()),
          error: (error, stack) => _buildErrorState(error),
          data: (order) {
            if (order == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: DesignTokens.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      label: 'text-order-not-found',
                      child: Text(
                        'orders.not_found'.tr(),
                        style: TextStyle(color: DesignTokens.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Semantics(
                      button: true,
                      label: 'btn-back',
                      child: ModernButton(
                        onPressed: onBack,
                        label: 'common.back'.tr(),
                        icon: Icons.arrow_back,
                      ),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              color: DesignTokens.primary,
              onRefresh: () async => onRefresh(),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: ResponsiveBreakpoints.contentMaxWidth,
                  ),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: _OrderDetailView(order: order),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
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
              label: 'text-order-load-error',
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
            Semantics(
              button: true,
              label: 'btn-retry-load-order',
              child: ModernButton(
                onPressed: onRefresh,
                label: 'orders.retry'.tr(),
                icon: Icons.refresh,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderDetailView extends ConsumerWidget {
  final Order order;
  const _OrderDetailView({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        FadeSlideIn(child: BuyerOrderCard(order: order, isDetailView: true)),
      ],
    );
  }
}

// === Widget Previews ===

// ═══ Widget Previews ═══

const _previewOrderImageBase = 'https://fastly.picsum.photos/id';

String _previewOrderImage(int id, {int width = 900, int height = 900}) =>
    '$_previewOrderImageBase/$id/$width/$height.jpg';

OrderItem _previewOrderItem({
  required String productId,
  required String name,
  required int priceCents,
  required int quantity,
  required String sellerId,
  required String sellerName,
  required String status,
  required int imageId,
  String? trackingNumber,
  String? carrier,
  bool isDigital = false,
}) => OrderItem(
  productId: productId,
  cartItemId: 'cart-$productId',
  name: name,
  description: '$name preview item',
  priceCents: priceCents,
  quantity: quantity,
  imageUrls: [_previewOrderImage(imageId)],
  sellerId: sellerId,
  sellerName: sellerName,
  status: status,
  trackingNumber: trackingNumber,
  carrier: carrier,
  isDigital: isDigital,
);

final _previewShippingAddress = generated_base.Address(
  street: '123 King St W',
  apartment: 'Suite 901',
  city: 'Toronto',
  state: 'ON',
  postalCode: 'M5H 1J9',
  country: 'CA',
  isDefault: true,
);

final _previewDeliveredOrder = Order(
  orderId: 'preview-order-delivered',
  userId: 'preview-user',
  customerId: 'cus_preview_1',
  customerEmail: 'orders.preview@origna.ca',
  items: [
    _previewOrderItem(
      productId: 'product-espresso',
      name: 'Small-Batch Espresso Beans',
      priceCents: 2400,
      quantity: 2,
      sellerId: 'seller-coffee',
      sellerName: 'North Roast Co.',
      status: DeliveryStatusValues.delivered,
      imageId: 431,
      trackingNumber: '1Z999AA10123456784',
      carrier: 'UPS',
    ),
    _previewOrderItem(
      productId: 'product-mug',
      name: 'Stoneware Morning Mug',
      priceCents: 3600,
      quantity: 1,
      sellerId: 'seller-ceramics',
      sellerName: 'Clay Morning Studio',
      status: DeliveryStatusValues.delivered,
      imageId: 1025,
      trackingNumber: '1Z999AA10123456784',
      carrier: 'UPS',
    ),
  ],
  totalAmountCents: 9632,
  subtotalCents: 8400,
  shippingCostCents: 750,
  taxAmountCents: 482,
  taxes: const Taxes(hstCents: 482),
  orderStatus: OrderStatus.delivered,
  paymentStatus: PaymentStatus.captured,
  shippingAddress: _previewShippingAddress,
  createdAt: DateTime(2026, 4, 8, 14, 30),
  sellerIds: const ['seller-coffee', 'seller-ceramics'],
  productIds: const ['product-espresso', 'product-mug'],
  stripeSessionId: 'cs_preview_delivered',
  confirmedByClient: true,
  confirmedAt: DateTime(2026, 4, 12, 10, 15),
  capturedAt: DateTime(2026, 4, 8, 14, 32),
  autoConfirmed: true,
  autoCaptured: true,
  updatedAt: DateTime(2026, 4, 12, 10, 15),
);

final _previewShippingApprovalOrder = Order(
  orderId: 'preview-order-shipping-approval',
  userId: 'preview-user',
  customerId: 'cus_preview_2',
  customerEmail: 'orders.preview@origna.ca',
  items: [
    _previewOrderItem(
      productId: 'product-lamp',
      name: 'Nordic Oak Desk Lamp',
      priceCents: 6800,
      quantity: 1,
      sellerId: 'seller-lighting',
      sellerName: 'Luma North',
      status: DeliveryStatusValues.pending,
      imageId: 1040,
    ),
  ],
  totalAmountCents: 8110,
  subtotalCents: 6800,
  shippingCostCents: 0,
  taxAmountCents: 910,
  taxes: const Taxes(hstCents: 910),
  orderStatus: OrderStatus.confirmed,
  paymentStatus: PaymentStatus.captured,
  shippingAddress: _previewShippingAddress,
  createdAt: DateTime(2026, 4, 16, 9, 45),
  sellerIds: const ['seller-lighting'],
  productIds: const ['product-lamp'],
  shippingApprovalStatus: ShippingApprovalStatus.pending,
  shippingApprovalRequired: true,
  pendingTotalCents: 400,
  actualShippingCents: 400,
  stripeSessionId: 'cs_preview_shipping',
  capturedAt: DateTime(2026, 4, 16, 9, 47),
  updatedAt: DateTime(2026, 4, 16, 10, 10),
);

final _previewOrderUser = AppAuthUser(
  uid: 'preview-user',
  email: 'orders.preview@origna.ca',
  emailVerified: true,
);

Widget _orderDetailDelivered() => previewScopeLoggedIn(
  uid: _previewOrderUser.uid,
  extraOverrides: [
    currentUserProvider.overrideWith((ref) => _previewOrderUser),
  ],
  child: OrderDetailScreenLayout(
    orderAsync: AsyncValue.data(_previewDeliveredOrder),
    onBack: () {},
    onRefresh: () {},
  ),
);

Widget _orderDetailShippingApproval() => previewScopeLoggedIn(
  uid: _previewOrderUser.uid,
  extraOverrides: [
    currentUserProvider.overrideWith((ref) => _previewOrderUser),
  ],
  child: OrderDetailScreenLayout(
    orderAsync: AsyncValue.data(_previewShippingApprovalOrder),
    onBack: () {},
    onRefresh: () {},
  ),
);

Widget _orderDetailError() => previewScopeLoggedIn(
  uid: _previewOrderUser.uid,
  extraOverrides: [
    currentUserProvider.overrideWith((ref) => _previewOrderUser),
  ],
  child: OrderDetailScreenLayout(
    orderAsync: AsyncValue.error(
      Exception('Preview order failed to load'),
      StackTrace.empty,
    ),
    onBack: () {},
    onRefresh: () {},
  ),
);

@Preview(
  name: 'Order Detail Delivered — Mobile',
  group: 'Order Screens',
  size: Size(390, 844),
)
Widget previewOrderDetailScreenMobile() =>
    previewMobile(child: _orderDetailDelivered());

@Preview(
  name: 'Order Detail Delivered — Desktop',
  group: 'Order Screens',
  size: Size(1280, 800),
)
Widget previewOrderDetailScreenDesktop() =>
    previewDesktop(child: _orderDetailDelivered());

@Preview(
  name: 'Order Detail Shipping Approval — Desktop',
  group: 'Order Screens',
  size: Size(1280, 800),
)
Widget previewOrderDetailShippingApprovalDesktop() =>
    previewDesktop(child: _orderDetailShippingApproval());

@Preview(
  name: 'Order Detail Error — Desktop',
  group: 'Order Screens',
  size: Size(1280, 800),
)
Widget previewOrderDetailErrorDesktop() =>
    previewDesktop(child: _orderDetailError());

@Preview(
  name: 'Order Detail Delivered Light — Desktop',
  group: 'Order Screens',
  size: Size(1280, 800),
)
Widget previewOrderDetailScreenLightDesktop() =>
    previewDesktop(theme: previewLightTheme, child: _orderDetailDelivered());
