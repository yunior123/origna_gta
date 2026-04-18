import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/features/orders/seller_orders_viewmodel.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/models/generated/base_models.dart' as base;
import 'package:origna_gta/models/generated/models.dart' hide Address;
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:origna_gta/widgets/orders/mark_shipped_dialog.dart';
import 'package:origna_gta/widgets/orders/seller_order_item_tile.dart';
import 'package:origna_gta/widgets/orders/update_shipping_dialog.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/utils/preview_helpers.dart';

part 'parts/seller_orders_earnings_card.dart';
part 'parts/seller_orders_order_card.dart';
part 'parts/seller_orders_badges.dart';

final _shippedDialogCarrierProvider = StateProvider.autoDispose<String?>(
  (_) => null,
);

final _updateShippingDialogCarrierProvider = StateProvider.autoDispose<String?>(
  (_) => null,
);

/// Seller orders screen — composes parts from parts/ sub-files:
/// - parts/seller_orders_earnings_card.dart (_EarningsSummaryCard, _StatPill)
/// - parts/seller_orders_order_card.dart (_SellerOrderCard)
/// - parts/seller_orders_badges.dart (_UnansweredQaBadge)
class SellerOrdersScreen extends ConsumerWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(currentUserProvider.select((u) => u != null));
    final userUid = ref.watch(currentUserProvider.select((u) => u?.uid));
    final isSuspended =
        ref.watch(
          userProfileProvider.select((a) => a.valueOrNull?.suspended),
        ) ??
        false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isLoggedIn) {
      return Container(
        decoration: BoxDecoration(
          gradient: DesignTokens.backgroundGradient(isDark: isDark),
        ),
        child: Scaffold(
          appBar: AppBarFactory.simple(title: 'seller.manage_orders'.tr()),
          backgroundColor: DesignTokens.transparent,
          body: AnimatedEmptyState(
            icon: Icons.login_rounded,
            title: 'seller.login_required'.tr(),
            subtitle: 'seller.login_to_view'.tr(),
          ),
        ),
      );
    }

    if (isSuspended) {
      return Container(
        decoration: BoxDecoration(
          gradient: DesignTokens.backgroundGradient(isDark: isDark),
        ),
        child: Scaffold(
          appBar: AppBarFactory.simple(title: 'seller.manage_orders'.tr()),
          backgroundColor: DesignTokens.transparent,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: FadeSlideIn(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: DesignTokens.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.block_rounded,
                        size: 56,
                        color: DesignTokens.error,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacing20),
                    Text(
                      'seller.account_suspended'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacing8),
                    Text(
                      'seller.contact_support'.tr(),
                      style: TextStyle(color: DesignTokens.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final ordersAsync = ref.watch(sellerOrdersProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: DesignTokens.backgroundGradient(isDark: isDark),
      ),
      child: Scaffold(
        key: const Key('seller_orders_screen_title'),
        appBar: AppBarFactory.custom(
          title: 'seller.manage_orders'.tr(),
          actions: [
            _UnansweredQaBadge(sellerId: userUid!),
            Semantics(
              button: true,
              label: 'btn-seller-integration',
              child: IconButton(
                icon: const Icon(Icons.integration_instructions_outlined),
                tooltip: 'seller_integration.title'.tr(),
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.sellerIntegration),
              ),
            ),
          ],
        ),
        backgroundColor: DesignTokens.transparent,
        body: ordersAsync.when(
          loading: () => Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? DesignTokens.white.withValues(alpha: 0.05)
                    : DesignTokens.white,
                shape: BoxShape.circle,
                boxShadow: DesignTokens.shadowMd,
              ),
              child: ShaderMask(
                shaderCallback: (bounds) =>
                    DesignTokens.primaryGradient.createShader(bounds),
                child: const ModernLoadingIndicator(
                  strokeWidth: 3,
                  color: DesignTokens.white,
                  centered: false,
                ),
              ),
            ),
          ),
          error: (error, _) => AnimatedEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'seller.something_wrong'.tr(),
            subtitle: AppError.getMessage(error),
            action: ModernButton(
              label: 'common.retry'.tr(),
              icon: Icons.refresh,
              onPressed: () => ref.invalidate(sellerOrdersProvider),
              isOutlined: true,
            ),
          ),
          data: (orders) {
            if (orders.isEmpty) {
              return AnimatedEmptyState(
                icon: Icons.storefront_outlined,
                title: 'seller.no_orders_yet'.tr(),
                subtitle: 'seller.orders_appear_here'.tr(),
              );
            }

            // Earnings computed in provider — no business logic in build()
            final earnings = ref.watch(sellerEarningsSummaryProvider);

            // Cap to 840px on desktop for readability — cards shouldn't stretch to 1200px
            final ordersMaxWidth = ResponsiveBreakpoints.isDesktop(context)
                ? 840.0
                : ResponsiveBreakpoints.contentMaxWidth.toDouble();
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: ordersMaxWidth),
                child: RefreshIndicator(
                  color: DesignTokens.primary,
                  onRefresh: () async => ref.invalidate(sellerOrdersProvider),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(DesignTokens.spacing16),
                    itemCount: orders.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: DesignTokens.spacing16,
                          ),
                          child: _EarningsSummaryCard(
                            totalRevenueCents: earnings.totalRevenueCents,
                            pendingCount: earnings.pendingCount,
                            completedCount: earnings.completedCount,
                            isDark: isDark,
                          ),
                        );
                      }
                      final order = orders[index - 1];
                      return FadeSlideIn(
                        delay: Duration(
                          milliseconds: 50 * (index - 1).clamp(0, 8),
                        ),
                        child: _SellerOrderCard(
                          order: order,
                          sellerId: userUid,
                        ),
                      );
                    },
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


// === Widget Previews ===


// ═══ Widget Previews ═══

final _previewSellerOrdersUser = AppAuthUser(
  uid: 'preview-seller-orders',
  email: 'seller.orders@origna.ca',
  emailVerified: true,
);

const _previewSellerOrdersImageBase = 'https://fastly.picsum.photos/id';

String _previewSellerOrdersImage(int id, {int width = 900, int height = 900}) =>
    '$_previewSellerOrdersImageBase/$id/$width/$height.jpg';

final _previewSellerOrdersProfile = UserModel(
  uid: 'preview-seller-orders',
  email: 'seller.orders@origna.ca',
  name: 'Prairie Goods Co.',
  roles: const [UserRole.buyer, UserRole.seller],
  createdAt: DateTime(2026, 1, 8),
  businessName: 'Prairie Goods Co.',
  verified: true,
);

final _previewSellerOrders = [
  Order(
    orderId: 'seller-order-preview-1',
    userId: 'buyer-preview-1',
    customerEmail: 'buyer.one@origna.ca',
    items: [
      OrderItem(
        productId: 'product-preview-1',
        cartItemId: 'cart-preview-1',
        name: 'Maple Breakfast Crate',
        description: 'Curated breakfast bundle with maple syrup and granola.',
        priceCents: 5400,
        quantity: 2,
        imageUrls: [_previewSellerOrdersImage(431)],
        sellerId: 'preview-seller-orders',
        sellerName: 'Prairie Goods Co.',
        status: DeliveryStatusValues.pending,
      ),
    ],
    totalAmountCents: 12204,
    subtotalCents: 10800,
    shippingCostCents: 900,
    taxAmountCents: 504,
    taxes: const Taxes(gstCents: 0, pstCents: 0, qstCents: 0, hstCents: 504),
    orderStatus: OrderStatus.processing,
    paymentStatus: PaymentStatus.paid,
    createdAt: DateTime(2026, 4, 15, 10, 30),
    shippingAddress: base.Address(
      street: '88 Front St W',
      city: 'Toronto',
      state: 'ON',
      postalCode: 'M5J 1E7',
      country: 'CA',
    ),
    sellerIds: const ['preview-seller-orders'],
    productIds: const ['product-preview-1'],
    platformFeeTotalCents: 540,
  ),
  Order(
    orderId: 'seller-order-preview-2',
    userId: 'buyer-preview-2',
    customerEmail: 'buyer.two@origna.ca',
    items: [
      OrderItem(
        productId: 'product-preview-2',
        cartItemId: 'cart-preview-2',
        name: 'Hand-thrown Tea Cup Set',
        description: 'Set of 4 ceramic cups made in Montreal.',
        priceCents: 7600,
        quantity: 1,
        imageUrls: [_previewSellerOrdersImage(1062)],
        sellerId: 'preview-seller-orders',
        sellerName: 'Prairie Goods Co.',
        status: DeliveryStatusValues.delivered,
        deliveredAt: DateTime(2026, 4, 10),
      ),
    ],
    totalAmountCents: 8588,
    subtotalCents: 7600,
    shippingCostCents: 600,
    taxAmountCents: 388,
    taxes: const Taxes(gstCents: 0, pstCents: 0, qstCents: 0, hstCents: 388),
    orderStatus: OrderStatus.delivered,
    paymentStatus: PaymentStatus.paid,
    createdAt: DateTime(2026, 4, 7, 14, 12),
    shippingAddress: base.Address(
      street: '44 Rue Saint-Paul O',
      city: 'Montreal',
      state: 'QC',
      postalCode: 'H2Y 1Y8',
      country: 'CA',
    ),
    sellerIds: const ['preview-seller-orders'],
    productIds: const ['product-preview-2'],
    platformFeeTotalCents: 380,
  ),
];

Widget _sellerOrdersPreview({List<Order>? orders}) => previewScopeLoggedIn(
  uid: _previewSellerOrdersUser.uid,
  extraOverrides: [
    currentUserProvider.overrideWith((ref) => _previewSellerOrdersUser),
    userProfileProvider.overrideWith(
      (ref) => Stream.value(_previewSellerOrdersProfile),
    ),
    sellerOrdersProvider.overrideWith(
      (ref) => Stream.value(orders ?? _previewSellerOrders),
    ),
  ],
  child: const SellerOrdersScreen(),
);

@Preview(name: 'Seller Orders — Mobile', group: 'Screens — Seller Management', size: Size(390, 844))
Widget previewSellerOrdersScreenMobile() =>
    previewMobile(child: _sellerOrdersPreview());

@Preview(name: 'Seller Orders — Desktop', group: 'Screens — Seller Management', size: Size(1280, 800))
Widget previewSellerOrdersScreenDesktop() =>
    previewDesktop(child: _sellerOrdersPreview());

@Preview(name: 'Seller Orders Light — Desktop', group: 'Screens — Seller Management', size: Size(1280, 800))
Widget previewSellerOrdersLightDesktop() =>
    previewDesktop(theme: previewLightTheme, child: _sellerOrdersPreview());

@Preview(name: 'Seller Orders Empty — Desktop', group: 'Screens — Seller Management', size: Size(1280, 800))
Widget previewSellerOrdersEmptyDesktop() =>
    previewDesktop(child: _sellerOrdersPreview(orders: const []));
