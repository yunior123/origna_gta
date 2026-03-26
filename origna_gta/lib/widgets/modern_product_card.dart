import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/modern_skeleton_loader.dart';
import 'package:origna_gta/widgets/shared/trending_badge.dart';
import 'package:flutter/widget_previews.dart';

/// Modern 2100 Product Card with glassmorphism
class ModernProductCard extends StatefulWidget {
  final String productName;
  final int priceCents;
  final String imageUrl;
  final String sellerName;
  final double rating;
  final int reviewCount;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;
  final String? shipFromCity;
  final String? shipFromProvince;
  final String? shipFromCountry;
  final List<String>? shipFromCountries;

  /// Original/crossed-out price shown next to the sale price in cents (null = no active sale)
  final int? compareAtPriceCents;

  /// When true, show a Trending badge on the image corner
  final bool isTrending;

  /// Trending score: ≥50 = HOT (fire), <50 = RISING (teal)
  final int trendingScore;

  /// SRCH-M1: When true, show "Out of Stock" overlay and disable CTA
  final bool isOutOfStock;

  const ModernProductCard({
    super.key,
    required this.productName,
    required this.priceCents,
    required this.imageUrl,
    required this.sellerName,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.onTap,
    this.onAddToCart,
    this.shipFromCity,
    this.shipFromProvince,
    this.shipFromCountry,
    this.shipFromCountries,
    this.compareAtPriceCents,
    this.isTrending = false,
    this.trendingScore = 0,
    this.isOutOfStock = false,
  });

  @override
  State<ModernProductCard> createState() => _ModernProductCardState();
}

class _ModernProductCardState extends State<ModernProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  /// Computes the "Ships from" label:
  /// - Single country: "Ships from: Toronto, ON, Canada"
  /// - 2–3 countries:  "Ships from: Canada · Germany"
  /// - 4+ countries:   "Ships from: 4 locations worldwide"
  String get _shipFromLabel {
    final countries = widget.shipFromCountries;
    if (countries != null && countries.length > 1) {
      if (countries.length <= 3) {
        return 'product.ships_from_label'.tr(
          namedArgs: {'locations': countries.join(' · ')},
        );
      }
      return 'product.ships_from_worldwide'.tr(
        namedArgs: {'count': countries.length.toString()},
      );
    }
    // Single location — show full city, province, country
    // FAV-L2: also fall back to single country from list when no individual fields
    final parts = [
      if (widget.shipFromCity != null) widget.shipFromCity!,
      if (widget.shipFromProvince != null) widget.shipFromProvince!,
      if (widget.shipFromCountry != null) widget.shipFromCountry!,
      // If no individual address fields but a single country is provided in the list, use it
      if (widget.shipFromCity == null &&
          widget.shipFromCountry == null &&
          countries != null &&
          countries.length == 1)
        countries[0],
    ];
    return parts.isEmpty
        ? ''
        : 'product.ships_from_label'.tr(
            namedArgs: {'locations': parts.join(', ')},
          );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Semantics(
          label: widget.compareAtPriceCents != null
              ? 'product.a11y_on_sale'.tr(
                  namedArgs: {
                    'name': widget.productName,
                    'price':
                        '\$${(widget.priceCents / 100).toStringAsFixed(2)}',
                    'originalPrice':
                        '\$${((widget.compareAtPriceCents ?? 0) / 100).toStringAsFixed(2)}',
                    'rating': widget.rating.toStringAsFixed(1),
                  },
                )
              : 'product.a11y_regular'.tr(
                  namedArgs: {
                    'name': widget.productName,
                    'price':
                        '\$${(widget.priceCents / 100).toStringAsFixed(2)}',
                    'rating': widget.rating.toStringAsFixed(1),
                  },
                ),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? DesignTokens.darkSurfaceVariant.withValues(alpha: 0.6)
                    : DesignTokens.surface,
                borderRadius: BorderRadius.circular(DesignTokens.radius16),
                border: Border.all(
                  color: DesignTokens.white.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: DesignTokens.shadowMd,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radius16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image — 60% of card height, adapts to any grid size
                    Expanded(
                      flex: 3,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  DesignTokens.primary.withValues(alpha: 0.1),
                                  DesignTokens.secondary.withValues(alpha: 0.1),
                                ],
                              ),
                            ),
                            child: widget.imageUrl.isNotEmpty
                                ? ColorFiltered(
                                    colorFilter: widget.isOutOfStock
                                        ? const ColorFilter.mode(
                                            DesignTokens.textSecondary,
                                            BlendMode.saturation,
                                          )
                                        : const ColorFilter.mode(
                                            DesignTokens.transparent,
                                            BlendMode.multiply,
                                          ),
                                    child: CachedNetworkImage(
                                      imageUrl: widget.imageUrl,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          ModernSkeletonLoader.imagePlaceholder(),
                                      errorWidget: (context, url, error) =>
                                          Center(
                                            child: Container(
                                              width: 52,
                                              height: 52,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: DesignTokens.primary
                                                    .withValues(alpha: 0.12),
                                                border: Border.all(
                                                  color: DesignTokens.primary
                                                      .withValues(alpha: 0.2),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.camera_alt_outlined,
                                                color: DesignTokens.primary,
                                                size: 26,
                                              ),
                                            ),
                                          ),
                                    ),
                                  )
                                : Center(
                                    child: Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: DesignTokens.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        border: Border.all(
                                          color: DesignTokens.primary
                                              .withValues(alpha: 0.2),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_outlined,
                                        color: DesignTokens.primary,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                          ),
                          // SRCH-M1: Out of Stock overlay
                          if (widget.isOutOfStock)
                            Positioned.fill(
                              child: Container(
                                color: DesignTokens.black.withValues(
                                  alpha: 0.3,
                                ),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: DesignTokens.black.withValues(
                                        alpha: 0.7,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: DesignTokens.white.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'product.out_of_stock_label'.tr(),
                                      style: const TextStyle(
                                        color: DesignTokens.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // N-10: isTrending badge (HOT / RISING)
                          if (widget.isTrending && !widget.isOutOfStock)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: TrendingBadge(
                                score: widget.trendingScore,
                                isCompact: false,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Content — 40% of card height
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(DesignTokens.spacing12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 14 * 1.4 * 2 + 2,
                              child: Text(
                                widget.productName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: DesignTokens.spacing4),
                            Text(
                              widget.sellerName,
                              style: TextStyle(
                                fontSize: 12,
                                color: DesignTokens.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            // FAV-L2: only render when label is non-empty (guards against single-country list
                            // with no city/province/country fields → avoids "Ships from: " with blank text)
                            if (_shipFromLabel.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 11,
                                    color: DesignTokens.textTertiary,
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      _shipFromLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: DesignTokens.textTertiary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const Spacer(),
                            // Rating
                            if (widget.reviewCount > 0)
                              Row(
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: DesignTokens.warning,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${widget.reviewCount})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: DesignTokens.textSecondary,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                'product.no_reviews_card'.tr(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: DesignTokens.textTertiary,
                                ),
                              ),
                            const SizedBox(height: DesignTokens.spacing8),
                            // Price and CTA
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '\$${(widget.priceCents / 100).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: DesignTokens.primary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (widget.compareAtPriceCents
                                          case final compareAtCents?)
                                        Text(
                                          '\$${(compareAtCents / 100).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: DesignTokens.textSecondary,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            decorationColor: DesignTokens.error,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                if (widget.onAddToCart != null &&
                                    !widget.isOutOfStock) ...[
                                  const SizedBox(width: 8),
                                  Semantics(
                                    button: true,
                                    label: 'common.add_to_cart_semantics'.tr(
                                      namedArgs: {'name': widget.productName},
                                    ),
                                    child: GestureDetector(
                                      onTap: widget.onAddToCart,
                                      child: Container(
                                        padding: const EdgeInsets.all(
                                          14,
                                        ), // WCAG 2.5.8: ≥48dp touch target
                                        decoration: BoxDecoration(
                                          gradient:
                                              DesignTokens.primaryGradient,
                                          borderRadius: BorderRadius.circular(
                                            DesignTokens.radius8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          size: 20,
                                          color: DesignTokens.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DesignTokens.durationNormal,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: DesignTokens.easeOutCubic),
    );
  }
}


// === Widget Previews ===


// ═══ Widget Previews ═══

/// [Align] escapes tight width constraints from [previewGrid]'s Column so the
/// card stays at 220 px instead of stretching to the full panel width.
Widget _card(Widget w) =>
    Align(child: SizedBox(width: 220, height: 460, child: w));

@Preview(name: 'Modern Product Card — States', group: 'ModernProductCard')
Widget previewProductCardStates() => previewGrid(
  children: [
    _card(
      ModernProductCard(
        productName: 'Limited Edition Winter Parka',
        priceCents: 29900,
        imageUrl:
            'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?q=80&w=3087&auto=format&fit=crop',
        sellerName: 'Northern Gear',
        onTap: () {},
        isOutOfStock: true,
      ),
    ),
    _card(
      ModernProductCard(
        productName: 'Pacific Salmon Fillets (Fresh)',
        priceCents: 1850,
        imageUrl: '', // Empty URL to trigger placeholder
        sellerName: 'Ocean Harvest',
        rating: 4.5,
        reviewCount: 22,
        onTap: () {},
        onAddToCart: () {},
        shipFromCountries: const ['Canada', 'USA'],
        isTrending: true,
        trendingScore: 40,
      ),
    ),
  ],
);

@Preview(name: 'Modern Product Card — Variants', group: 'ModernProductCard')
Widget previewProductCardVariants() => previewGrid(
  children: [
    _card(
      ModernProductCard(
        productName: 'Handmade Canadian Maple Syrup',
        priceCents: 2499,
        imageUrl:
            'https://images.unsplash.com/photo-1589182373726-e4f658ab50f0?q=80&w=3087&auto=format&fit=crop',
        sellerName: 'Maple Artisans Co.',
        rating: 4.8,
        reviewCount: 154,
        onTap: () {},
        onAddToCart: () {},
        shipFromCity: 'Toronto',
        shipFromProvince: 'ON',
        shipFromCountry: 'Canada',
      ),
    ),
    _card(
      ModernProductCard(
        productName: 'Artisan Quebec Cheese Board',
        priceCents: 4500,
        compareAtPriceCents: 5500,
        imageUrl:
            'https://images.unsplash.com/photo-1631451095765-2c91616fc9e6?q=80&w=3087&auto=format&fit=crop',
        sellerName: 'Fromagerie de Quebec',
        rating: 4.9,
        reviewCount: 89,
        onTap: () {},
        onAddToCart: () {},
        shipFromCity: 'Quebec City',
        shipFromProvince: 'QC',
        shipFromCountry: 'Canada',
        isTrending: true,
        trendingScore: 85,
      ),
    ),
  ],
);

@Preview(name: 'Modern Product Card Light — States', group: 'ModernProductCard')
Widget previewProductCardStatesLight() => previewGrid(
  theme: previewLightTheme,
  children: [
    _card(
      ModernProductCard(
        productName: 'Limited Edition Winter Parka',
        priceCents: 29900,
        imageUrl:
            'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?q=80&w=3087&auto=format&fit=crop',
        sellerName: 'Northern Gear',
        onTap: () {},
        isOutOfStock: true,
      ),
    ),
    _card(
      ModernProductCard(
        productName: 'Pacific Salmon Fillets (Fresh)',
        priceCents: 1850,
        imageUrl: '',
        sellerName: 'Ocean Harvest',
        rating: 4.5,
        reviewCount: 22,
        onTap: () {},
        onAddToCart: () {},
        shipFromCountries: const ['Canada', 'USA'],
        isTrending: true,
        trendingScore: 40,
      ),
    ),
  ],
);

@Preview(
  name: 'Modern Product Card Light — Variants',
  group: 'ModernProductCard',
)
Widget previewProductCardVariantsLight() => previewGrid(
  theme: previewLightTheme,
  children: [
    _card(
      ModernProductCard(
        productName: 'Handmade Canadian Maple Syrup',
        priceCents: 2499,
        imageUrl:
            'https://images.unsplash.com/photo-1589182373726-e4f658ab50f0?q=80&w=3087&auto=format&fit=crop',
        sellerName: 'Maple Artisans Co.',
        rating: 4.8,
        reviewCount: 154,
        onTap: () {},
        onAddToCart: () {},
        shipFromCity: 'Toronto',
        shipFromProvince: 'ON',
        shipFromCountry: 'Canada',
      ),
    ),
    _card(
      ModernProductCard(
        productName: 'Artisan Quebec Cheese Board',
        priceCents: 4500,
        compareAtPriceCents: 5500,
        imageUrl:
            'https://images.unsplash.com/photo-1631451095765-2c91616fc9e6?q=80&w=3087&auto=format&fit=crop',
        sellerName: 'Fromagerie de Quebec',
        rating: 4.9,
        reviewCount: 89,
        onTap: () {},
        onAddToCart: () {},
        shipFromCity: 'Quebec City',
        shipFromProvince: 'QC',
        shipFromCountry: 'Canada',
        isTrending: true,
        trendingScore: 85,
      ),
    ),
  ],
);



// ═══ Widget Previews ═══

// ─── Shared dummy data ────────────────────────────────────────────────────────

const _kProductName = 'Vintage Leather Jacket';
const _kPriceCents = 8999;
const _kCompareAtPriceCents = 12999;
const _kImageUrl = 'https://picsum.photos/seed/jacket/200/300';
const _kSellerName = 'Toronto Vintage';
const _kRating = 4.5;
const _kReviewCount = 42;
const _kShipFromCity = 'Toronto';
const _kShipFromProvince = 'ON';

/// Wrap a [ModernProductCard] in a fixed-size box so the Expanded flex inside
/// the card has a bounded constraint during preview rendering.
/// [Align] escapes tight width constraints from [previewGrid]'s Column so the
/// card stays at 220 px instead of stretching to the full panel width.
Widget _cardBox(Widget card) =>
    Align(child: SizedBox(width: 220, height: 460, child: card));

// ─── Standard card ────────────────────────────────────────────────────────────

@Preview(name: 'Standard — dark', group: 'ProductCard')
Widget previewProductCardStandard() => previewWrapper(
  child: _cardBox(
    ModernProductCard(
      productName: _kProductName,
      priceCents: _kPriceCents,
      imageUrl: _kImageUrl,
      sellerName: _kSellerName,
      rating: _kRating,
      reviewCount: _kReviewCount,
      shipFromCity: _kShipFromCity,
      shipFromProvince: _kShipFromProvince,
      onTap: () {},
      onAddToCart: () {},
    ),
  ),
);

@Preview(
  name: 'Standard — light',
  group: 'ProductCard',
  brightness: Brightness.light,
)
Widget previewProductCardStandardLight() => previewWrapper(
  theme: previewLightTheme,
  background: DesignTokens.surface,
  child: _cardBox(
    ModernProductCard(
      productName: _kProductName,
      priceCents: _kPriceCents,
      imageUrl: _kImageUrl,
      sellerName: _kSellerName,
      rating: _kRating,
      reviewCount: _kReviewCount,
      shipFromCity: _kShipFromCity,
      shipFromProvince: _kShipFromProvince,
      onTap: () {},
      onAddToCart: () {},
    ),
  ),
);

// ─── Trending HOT card ────────────────────────────────────────────────────────

@Preview(name: 'Trending HOT (score 80)', group: 'ProductCard')
Widget previewProductCardTrendingHot() => previewWrapper(
  child: _cardBox(
    ModernProductCard(
      productName: _kProductName,
      priceCents: _kPriceCents,
      imageUrl: _kImageUrl,
      sellerName: _kSellerName,
      rating: _kRating,
      reviewCount: _kReviewCount,
      shipFromCity: _kShipFromCity,
      shipFromProvince: _kShipFromProvince,
      isTrending: true,
      trendingScore: 80,
      onTap: () {},
      onAddToCart: () {},
    ),
  ),
);

// ─── Trending RISING card ─────────────────────────────────────────────────────

@Preview(name: 'Trending RISING (score 30)', group: 'ProductCard')
Widget previewProductCardTrendingRising() => previewWrapper(
  child: _cardBox(
    ModernProductCard(
      productName: _kProductName,
      priceCents: _kPriceCents,
      imageUrl: _kImageUrl,
      sellerName: _kSellerName,
      rating: _kRating,
      reviewCount: _kReviewCount,
      shipFromCity: _kShipFromCity,
      shipFromProvince: _kShipFromProvince,
      isTrending: true,
      trendingScore: 30,
      onTap: () {},
      onAddToCart: () {},
    ),
  ),
);

// ─── Sale / compare-at price card ─────────────────────────────────────────────

@Preview(name: 'On Sale (compare-at price)', group: 'ProductCard')
Widget previewProductCardOnSale() => previewWrapper(
  child: _cardBox(
    ModernProductCard(
      productName: _kProductName,
      priceCents: _kPriceCents,
      compareAtPriceCents: _kCompareAtPriceCents,
      imageUrl: _kImageUrl,
      sellerName: _kSellerName,
      rating: _kRating,
      reviewCount: _kReviewCount,
      shipFromCity: _kShipFromCity,
      shipFromProvince: _kShipFromProvince,
      onTap: () {},
      onAddToCart: () {},
    ),
  ),
);

// ─── Out of stock card ────────────────────────────────────────────────────────

@Preview(name: 'Out of Stock', group: 'ProductCard')
Widget previewProductCardOutOfStock() => previewWrapper(
  child: _cardBox(
    ModernProductCard(
      productName: _kProductName,
      priceCents: _kPriceCents,
      imageUrl: _kImageUrl,
      sellerName: _kSellerName,
      rating: _kRating,
      reviewCount: _kReviewCount,
      shipFromCity: _kShipFromCity,
      shipFromProvince: _kShipFromProvince,
      isOutOfStock: true,
      onTap: () {},
      onAddToCart: () {},
    ),
  ),
);

// ─── No reviews (new product) ─────────────────────────────────────────────────

@Preview(name: 'No Reviews (new product)', group: 'ProductCard')
Widget previewProductCardNoReviews() => previewWrapper(
  child: _cardBox(
    ModernProductCard(
      productName: 'New Arrival Jacket',
      priceCents: _kPriceCents,
      imageUrl: _kImageUrl,
      sellerName: _kSellerName,
      shipFromCity: _kShipFromCity,
      shipFromProvince: _kShipFromProvince,
      onTap: () {},
      onAddToCart: () {},
    ),
  ),
);

// ─── Multi-country shipping card ──────────────────────────────────────────────

@Preview(name: 'Ships from Multiple Countries', group: 'ProductCard')
Widget previewProductCardMultiCountry() => previewWrapper(
  child: _cardBox(
    ModernProductCard(
      productName: _kProductName,
      priceCents: _kPriceCents,
      imageUrl: _kImageUrl,
      sellerName: _kSellerName,
      rating: _kRating,
      reviewCount: _kReviewCount,
      shipFromCountries: const ['Canada', 'Germany', 'Japan'],
      onTap: () {},
      onAddToCart: () {},
    ),
  ),
);

// ─── All variants grid ────────────────────────────────────────────────────────

@Preview(name: 'All Variants', group: 'ProductCard')
Widget previewProductCardAllVariants() => previewGrid(
  children: [
    _cardBox(
      ModernProductCard(
        productName: _kProductName,
        priceCents: _kPriceCents,
        imageUrl: _kImageUrl,
        sellerName: _kSellerName,
        rating: _kRating,
        reviewCount: _kReviewCount,
        shipFromCity: _kShipFromCity,
        shipFromProvince: _kShipFromProvince,
        onTap: () {},
        onAddToCart: () {},
      ),
    ),
    _cardBox(
      ModernProductCard(
        productName: _kProductName,
        priceCents: _kPriceCents,
        imageUrl: _kImageUrl,
        sellerName: _kSellerName,
        rating: _kRating,
        reviewCount: _kReviewCount,
        shipFromCity: _kShipFromCity,
        shipFromProvince: _kShipFromProvince,
        isTrending: true,
        trendingScore: 80,
        onTap: () {},
        onAddToCart: () {},
      ),
    ),
    _cardBox(
      ModernProductCard(
        productName: _kProductName,
        priceCents: _kPriceCents,
        compareAtPriceCents: _kCompareAtPriceCents,
        imageUrl: _kImageUrl,
        sellerName: _kSellerName,
        rating: _kRating,
        reviewCount: _kReviewCount,
        shipFromCity: _kShipFromCity,
        shipFromProvince: _kShipFromProvince,
        onTap: () {},
        onAddToCart: () {},
      ),
    ),
    _cardBox(
      ModernProductCard(
        productName: _kProductName,
        priceCents: _kPriceCents,
        imageUrl: _kImageUrl,
        sellerName: _kSellerName,
        rating: _kRating,
        reviewCount: _kReviewCount,
        shipFromCity: _kShipFromCity,
        shipFromProvince: _kShipFromProvince,
        isOutOfStock: true,
        onTap: () {},
        onAddToCart: () {},
      ),
    ),
    _cardBox(
      ModernProductCard(
        productName: 'New Arrival Jacket',
        priceCents: _kPriceCents,
        imageUrl: _kImageUrl,
        sellerName: _kSellerName,
        shipFromCity: _kShipFromCity,
        shipFromProvince: _kShipFromProvince,
        onTap: () {},
        onAddToCart: () {},
      ),
    ),
    _cardBox(
      ModernProductCard(
        productName: _kProductName,
        priceCents: _kPriceCents,
        imageUrl: _kImageUrl,
        sellerName: _kSellerName,
        rating: _kRating,
        reviewCount: _kReviewCount,
        shipFromCountries: const ['Canada', 'Germany', 'Japan'],
        onTap: () {},
        onAddToCart: () {},
      ),
    ),
  ],
);

