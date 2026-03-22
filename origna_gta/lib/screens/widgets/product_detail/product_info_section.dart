import 'package:origna_gta/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/products/product_detail_viewmodel.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_card.dart';
import 'package:origna_gta/widgets/premium_paywall_widget.dart';

/// Seller info card with metrics and trust badges.
class SellerInfoCard extends ConsumerWidget {
  final Product product;
  const SellerInfoCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPremium =
        ref.watch(
          subscriptionStreamProvider.select((a) => a.valueOrNull?.isPremium),
        ) ??
        false;
    final currentUserId = ref.watch(obUserIdProvider);
    final isOwnProduct = currentUserId == product.sellerId;

    return ModernCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: DesignTokens.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  size: 16,
                  color: DesignTokens.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'product.seller_info'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? DesignTokens.white
                        : DesignTokens.textPrimary,
                  ),
                ),
              ),
              if (!isOwnProduct)
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ModernButton(
                      label: 'chat.title'.tr(),
                      icon: Icons.chat_bubble_outline_rounded,
                      isPrimary: false,
                      isOutlined: true,
                      fullWidth: false,
                      height: 40,
                      onPressed: () {
                        if (currentUserId == null) {
                          Navigator.pushNamed(context, AppRoutes.login);
                          return;
                        }
                        if (isPremium) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.chat,
                            arguments: ChatArgs(
                              productId: product.productId,
                              productTitle: product.name,
                            ),
                          );
                        } else {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: DesignTokens.transparent,
                            builder: (context) => Container(
                              height: MediaQuery.of(context).size.height * 0.7,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).scaffoldBackgroundColor,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              child: PremiumPaywallWidget(
                                featureName: 'subscription.chat_with_sellers'
                                    .tr(),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SellerMetricsRow(sellerId: product.sellerId),
          const SizedBox(height: 8),
          TrustBadges(product: product),
        ],
      ),
    );
  }
}

/// Row of seller performance metric pills.
class SellerMetricsRow extends ConsumerWidget {
  final String sellerId;

  const SellerMetricsRow({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(sellerMetricsProvider(sellerId));
    final metrics = metricsAsync.valueOrNull;
    if (metricsAsync.isLoading || metrics == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    String fmt(double? v, String suffix) {
      if (v == null) return '--';
      return '${v.toStringAsFixed(1)}$suffix';
    }

    String fmtPct(double? v) {
      if (v == null) return '--';
      return '${v.toStringAsFixed(0)}%';
    }

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        MetricPill(
          icon: Icons.schedule_rounded,
          label: 'product.metric_response'.tr(),
          value: fmt(metrics.avgResponseHours, 'h'),
          isDark: isDark,
        ),
        MetricPill(
          icon: Icons.local_shipping_outlined,
          label: 'product.metric_ships_in'.tr(),
          value: fmt(metrics.avgShipDays, 'd'),
          isDark: isDark,
        ),
        MetricPill(
          icon: Icons.thumb_up_alt_outlined,
          label: 'product.metric_positive'.tr(),
          value: fmtPct(metrics.positiveRatePct),
          isDark: isDark,
        ),
        if (metrics.totalReviews != null && metrics.totalReviews! > 0)
          MetricPill(
            icon: Icons.rate_review_outlined,
            label: 'product.reviews_title'.tr(),
            value: '${metrics.totalReviews}',
            isDark: isDark,
          ),
      ],
    );
  }
}

/// Small pill displaying a seller metric (response time, ship days, etc.).
class MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const MetricPill({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkCard : DesignTokens.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? DesignTokens.darkOutline
              : DesignTokens.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: DesignTokens.primary),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? DesignTokens.textOnDarkSecondary
                  : DesignTokens.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Trust badges (Verified Seller, Fast Shipper, Ships CA).
class TrustBadges extends ConsumerWidget {
  final Product product;

  const TrustBadges({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref
        .watch(sellerMetricsProvider(product.sellerId))
        .valueOrNull;

    final isVerifiedSeller = (metrics?.positiveRatePct ?? 0) >= 90;
    final isFastShipper = (metrics?.avgShipDays ?? double.infinity) <= 2;
    final shipsCA =
        product.shipFromCountry == null || product.shipFromCountry == 'CA';

    final badges = <({IconData icon, String label, Color color})>[];
    if (isVerifiedSeller) {
      badges.add((
        icon: Icons.verified_rounded,
        label: 'product.trust_verified_seller'.tr(),
        color: DesignTokens.success,
      ));
    }
    if (isFastShipper) {
      badges.add((
        icon: Icons.local_shipping_rounded,
        label: 'product.trust_fast_shipper'.tr(),
        color: DesignTokens.primary,
      ));
    }
    if (shipsCA) {
      badges.add((
        icon: Icons.flag_rounded,
        label: 'product.trust_ships_ca'.tr(),
        color: DesignTokens.error,
      ));
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: badges
          .map(
            (b) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: b.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: b.color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(b.icon, size: 12, color: b.color),
                  const SizedBox(width: 4),
                  Text(
                    b.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: b.color,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Expandable description with "Read more / Show less" toggle.
class ExpandableDescription extends StatefulWidget {
  final String description;
  const ExpandableDescription({super.key, required this.description});

  @override
  State<ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<ExpandableDescription> {
  static const _collapseThreshold = 100;
  static const _maxLines = 4;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLong = widget.description.length > _collapseThreshold;
    final textStyle = TextStyle(
      fontSize: 15,
      color: isDark ? DesignTokens.outlineVariant : DesignTokens.textPrimary,
      height: 1.6,
      fontWeight: FontWeight.w400,
    );

    return GlassContainer(
      key: const Key('product_description_section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.description,
            style: textStyle,
            maxLines: (_expanded || !isLong) ? null : _maxLines,
            overflow: (_expanded || !isLong)
                ? TextOverflow.visible
                : TextOverflow.fade,
          ),
          if (isLong) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'common.see_less'.tr() : 'common.see_more'.tr(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Digital product info badge (software/book type, available platforms).
class DigitalProductInfo extends StatelessWidget {
  final Product product;
  const DigitalProductInfo({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final builds = product.digitalBuilds ?? {};
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.digital.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DesignTokens.digital.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.download_outlined,
                size: 16,
                color: DesignTokens.digital,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  product.digitalType == DigitalTypeValues.software
                      ? 'product.desktop_software'.tr()
                      : 'product.digital_book'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: DesignTokens.digital,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (builds.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'product.available_for'.tr(),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: builds.keys.map((p) {
                final label =
                    const {
                      'macos': 'macOS',
                      'windows': 'Windows',
                      'linux': 'Linux',
                    }[p] ??
                    p;
                return Chip(
                  label: Text(label, style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'product.digital_license_delivery'.tr(),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
