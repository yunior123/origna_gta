import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/models/generated/models.dart';
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

  const OrderDetailScreenLayout({super.key, required this.orderAsync, required this.onRefresh, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(gradient: DesignTokens.backgroundGradient(isDark: isDark)),
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
                    Icon(Icons.search_off_rounded, size: 64, color: DesignTokens.textSecondary),
                    const SizedBox(height: 16),
                    Semantics(
                      label: 'text-order-not-found',
                      child: Text('orders.not_found'.tr(), style: TextStyle(color: DesignTokens.textSecondary)),
                    ),
                    const SizedBox(height: 24),
                    Semantics(
                      button: true,
                      label: 'btn-back',
                      child: ModernButton(onPressed: onBack, label: 'common.back'.tr(), icon: Icons.arrow_back),
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
                  constraints: const BoxConstraints(maxWidth: ResponsiveBreakpoints.contentMaxWidth),
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
            Icon(Icons.error_outline_rounded, size: 60, color: DesignTokens.error),
            const SizedBox(height: 16),
            Semantics(
              label: 'text-order-load-error',
              child: Text('orders.unable_to_load'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              child: ModernButton(onPressed: onRefresh, label: 'orders.retry'.tr(), icon: Icons.refresh),
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
      children: [FadeSlideIn(child: BuyerOrderCard(order: order, isDetailView: true))],
    );
  }
}


// === Widget Previews ===


// ═══ Widget Previews ═══

Widget _orderDetailContent() => previewScopeLoggedIn(
  child: OrderDetailScreenLayout(orderAsync: const AsyncValue.loading(), onBack: () {}, onRefresh: () {}),
);

@Preview(name: 'Order Detail — Mobile', group: 'Order Screens', size: Size(390, 844))
Widget previewOrderDetailScreenMobile() => previewMobile(child: _orderDetailContent());

@Preview(name: 'Order Detail — Tablet', group: 'Order Screens', size: Size(768, 1024))
Widget previewOrderDetailScreenTablet() => previewTablet(child: _orderDetailContent());

@Preview(name: 'Order Detail — Desktop', group: 'Order Screens', size: Size(1280, 800))
Widget previewOrderDetailScreenDesktop() => previewDesktop(child: _orderDetailContent());

@Preview(name: 'Order Detail — Web', group: 'Order Screens', size: Size(1440, 900))
Widget previewOrderDetailScreenWeb() => previewWeb(child: _orderDetailContent());

// ── Light ────────────────────────────────────────────────────────────────────
@Preview(name: 'Order Detail Light — Mobile', group: 'Order Screens', size: Size(390, 844))
Widget previewOrderDetailScreenLightMobile() => previewMobile(theme: previewLightTheme, child: _orderDetailContent());

@Preview(name: 'Order Detail Light — Tablet', group: 'Order Screens', size: Size(768, 1024))
Widget previewOrderDetailScreenLightTablet() => previewTablet(theme: previewLightTheme, child: _orderDetailContent());

@Preview(name: 'Order Detail Light — Desktop', group: 'Order Screens', size: Size(1280, 800))
Widget previewOrderDetailScreenLightDesktop() => previewDesktop(theme: previewLightTheme, child: _orderDetailContent());

@Preview(name: 'Order Detail Light — Web', group: 'Order Screens', size: Size(1440, 900))
Widget previewOrderDetailScreenLightWeb() => previewWeb(theme: previewLightTheme, child: _orderDetailContent());

