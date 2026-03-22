import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:shimmer/shimmer.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/screens/cartitem_screen.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:origna_gta/widgets/modern_textfield.dart';

part 'parts/cart_item_widget.dart';
part 'parts/cart_summary_widgets.dart';

/// Cart screen using optimized Riverpod patterns
/// - Main screen only watches cart item IDs (lightweight)
/// - Each cart item widget watches its own data via family provider
/// - Summary widget only watches what it needs
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  static const checkoutButtonKey = Key('cart_checkout_button');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(currentUserProvider.select((u) => u != null));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBarFactory.simple(title: 'cart.your_cart'.tr()),
        body: AnimatedEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'auth.sign_in_required'.tr(),
          subtitle: 'cart.sign_in_subtitle'.tr(),
        ),
      );
    }

    // Use select to only rebuild when product IDs change (not quantities)
    final productIdsAsync = ref.watch(
      cartItemsProvider.select(
        (async) =>
            async.whenData((items) => items.map((i) => i.cartItemId).toList()),
      ),
    );

    return Scaffold(
      key: const Key('cart_screen_title'),
      appBar: AppBarFactory.simple(title: 'cart.your_cart'.tr()),
      backgroundColor: DesignTokens.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: DesignTokens.backgroundGradient(isDark: isDark),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  (ResponsiveBreakpoints.isTablet(context) ||
                      ResponsiveBreakpoints.isDesktop(context))
                  ? ResponsiveBreakpoints.contentMaxWidth
                  : double.infinity,
            ),
            child: productIdsAsync.when(
              loading: () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            DesignTokens.primary.withValues(alpha: 0.15),
                            DesignTokens.secondary.withValues(alpha: 0.15),
                          ],
                        ),
                      ),
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) =>
                              DesignTokens.primaryGradient.createShader(bounds),
                          child: const SizedBox(
                            width: 32,
                            height: 32,
                            child: ModernLoadingIndicator(
                              size: 32,
                              strokeWidth: 3,
                              color: DesignTokens.white,
                              centered: false,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'cart.loading_cart'.tr(),
                      style: TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              error: (error, stack) => AnimatedEmptyState(
                icon: Icons.error_outline_rounded,
                title: 'cart.unable_to_load'.tr(),
                subtitle: 'cart.load_error_subtitle'.tr(),
              ),
              data: (productIds) {
                if (productIds.isEmpty) {
                  return AnimatedEmptyState(
                    key: const Key('cart_empty_message'),
                    icon: Icons.shopping_cart_outlined,
                    title: 'cart.empty_cart'.tr(),
                    subtitle: 'cart.empty_cart_desc'.tr(),
                    showMascot: true,
                    action: SizedBox(
                      width: 240,
                      child: ModernButton(
                        label: 'common.go_shopping'.tr(),
                        icon: Icons.arrow_back,
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.home,
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ),
                  );
                }

                final isWideLayout =
                    ResponsiveBreakpoints.isTablet(context) ||
                    ResponsiveBreakpoints.isDesktop(context);
                final summaryWidth = ResponsiveBreakpoints.isDesktop(context)
                    ? 360.0
                    : 280.0;

                final unavailableBanner = Consumer(
                  builder: (context, ref, _) {
                    final unavailableAsync = ref.watch(
                      unavailableCartItemsProvider,
                    );
                    return unavailableAsync.maybeWhen(
                      data: (ids) {
                        if (ids.isEmpty) return const SizedBox.shrink();
                        return Container(
                          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: DesignTokens.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: DesignTokens.warning.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: DesignTokens.warning,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'cart.unavailable_items_warning'.tr(
                                    namedArgs: {'count': ids.length.toString()},
                                  ),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: DesignTokens.warning,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    );
                  },
                );

                final itemsList = Expanded(
                  child: RefreshIndicator(
                    color: DesignTokens.primary,
                    onRefresh: () async => ref.invalidate(cartItemsProvider),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: productIds.length,
                      itemBuilder: (context, index) {
                        final cartItemDocId = productIds[index];
                        return FadeSlideIn(
                          delay: Duration(milliseconds: 50 * index.clamp(0, 8)),
                          child: _CartItemWidget(
                            key: ValueKey(cartItemDocId),
                            cartItemDocId: cartItemDocId,
                          ),
                        );
                      },
                    ),
                  ),
                );

                if (isWideLayout) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(children: [unavailableBanner, itemsList]),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: summaryWidth,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 12, 16, 16),
                          child: const _CartSummary(isSidebar: true),
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    unavailableBanner,
                    itemsList,
                    FadeSlideIn(
                      delay: Duration(milliseconds: 50 * productIds.length),
                      beginOffset: const Offset(0, 0.2),
                      child: const _CartSummary(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Remaining classes extracted to:
// - parts/cart_item_widget.dart (_CartItemWidget)
// - parts/cart_summary_widgets.dart (_CartSummary, _CartTotalDisplay, _CheckoutButton, _FreeShippingBar, CartItemDetailModelExtension)
