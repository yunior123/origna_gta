import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
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

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBarFactory.simple(title: 'orders.my_orders'.tr()),
        body: AnimatedEmptyState(icon: Icons.lock_outline_rounded, title: 'auth.sign_in_required'.tr(), subtitle: 'orders.order_history_desc'.tr()),
      );
    }

    final ordersAsync = ref.watch(buyerOrdersProvider);

    return Container(
      decoration: BoxDecoration(gradient: DesignTokens.backgroundGradient(isDark: isDark)),
      child: Scaffold(
        key: const Key('orders_screen_app_bar'),
        appBar: AppBarFactory.simple(title: 'orders.my_orders'.tr()),
        backgroundColor: Colors.transparent,
        body: ordersAsync.when(
          loading: () => const Center(child: ModernLoadingIndicator()),
          error: (error, stack) => _buildErrorState(context, ref, error),
          data: (orders) {
            if (orders.isEmpty) {
              return AnimatedEmptyState(
                key: const Key('orders_empty_message'),
                icon: Icons.shopping_bag_outlined,
                title: 'orders.no_orders'.tr(),
                subtitle: 'orders.no_orders_desc'.tr(),
              );
            }

            final pendingApprovalsCount = orders.where((o) => o.shippingApprovalStatus == ShippingApprovalStatus.pending).length;

            return Column(
              children: [
                if (pendingApprovalsCount > 0) PendingApprovalsBanner(count: pendingApprovalsCount),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: ResponsiveBreakpoints.contentMaxWidth),
                  child: RefreshIndicator(
                    color: DesignTokens.primary,
                    onRefresh: () async => ref.invalidate(buyerOrdersProvider),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        return FadeSlideIn(
                          delay: Duration(milliseconds: 50 * index.clamp(0, 8)),
                          child: BuyerOrderCard(order: orders[index]),
                        );
                      },
                    ),
                  ),
                    ), // ConstrainedBox
                  ), // Align
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    final message = AppError.getMessage(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 60, color: DesignTokens.error),
            const SizedBox(height: 16),
            Text('orders.unable_to_load'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: DesignTokens.textSecondary),
            ),
            const SizedBox(height: 24),
            ModernButton(onPressed: () => ref.invalidate(buyerOrdersProvider), label: 'orders.retry'.tr(), icon: Icons.refresh),
          ],
        ),
      ),
    );
  }
}
