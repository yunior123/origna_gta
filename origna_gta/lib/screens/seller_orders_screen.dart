import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/core/schema/schema_constants.dart'
    show CarrierValues;
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/features/orders/seller_orders_viewmodel.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

part 'parts/seller_orders_earnings_card.dart';
part 'parts/seller_orders_order_card.dart';
part 'parts/seller_orders_badges.dart';

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
                            totalRevenue: earnings.totalRevenue,
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
