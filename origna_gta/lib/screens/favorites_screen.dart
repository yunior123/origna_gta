import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/screens/product_card_screen.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

/// Grid of favorited products with remove/toggle and empty state.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritedProductsProvider);
    final userModel = ref.watch(
      userProfileProvider.select((value) => value.valueOrNull),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: DesignTokens.backgroundGradient(isDark: isDark),
      ),
      child: Scaffold(
        appBar: AppBarFactory.simple(
          title: 'favorites.my_favorites'.tr(),
          subtitle: (favoritesAsync.valueOrNull?.isNotEmpty ?? false)
              ? 'favorites.items_count'.tr(
                  namedArgs: {
                    'count': '${favoritesAsync.valueOrNull?.length ?? 0}',
                  },
                )
              : null,
        ),
        backgroundColor: DesignTokens.transparent,
        body: favoritesAsync.when(
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
                  'favorites.loading_favorites'.tr(),
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
            title: 'favorites.unable_to_load'.tr(),
            subtitle: AppError.getMessage(error),
            action: ModernButton(
              label: 'common.retry'.tr(),
              icon: Icons.refresh,
              isOutlined: true,
              onPressed: () => ref.invalidate(favoritedProductsProvider),
            ),
          ),
          data: (products) {
            if (products.isEmpty) {
              return AnimatedEmptyState(
                icon: Icons.bookmark_border_rounded,
                title: 'favorites.empty_favorites'.tr(),
                subtitle: 'favorites.empty_favorites_desc'.tr(),
                showMascot: true,
              );
            }

            final available = products
                .where(
                  (p) =>
                      p.lifecycleStatus == ProductLifecycleStatusValues.active,
                )
                .toList();
            final unavailable = products
                .where(
                  (p) =>
                      p.lifecycleStatus != ProductLifecycleStatusValues.active,
                )
                .toList();
            final displayList = [...available, ...unavailable];

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: ResponsiveBreakpoints.contentMaxWidth,
                ),
                child: RefreshIndicator(
                  color: DesignTokens.primary,
                  onRefresh: () async =>
                      ref.invalidate(favoritedProductsProvider),
                  semanticsLabel: 'btn-refresh-favorites',
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (unavailable.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.warning.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: DesignTokens.warning.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: DesignTokens.warning,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Semantics(
                                    label: 'text-unavailable-items-warning',
                                    child: Text(
                                      'favorites.items_unavailable'.tr(
                                        namedArgs: {
                                          'count': '${unavailable.length}',
                                        },
                                      ),
                                      style: TextStyle(
                                        color: DesignTokens.warning,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.all(DesignTokens.spacing16),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: getCrossAxisCount(context),
                                crossAxisSpacing: DesignTokens.spacing12,
                                mainAxisSpacing: DesignTokens.spacing12,
                                childAspectRatio: _getCardAspectRatio(context),
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final product = displayList[index];
                              final isUnavailable =
                                  product.lifecycleStatus !=
                                  ProductLifecycleStatusValues.active;
                              return FadeSlideIn(
                                delay: Duration(
                                  milliseconds: 50 * index.clamp(0, 8),
                                ),
                                child: Semantics(
                                  label:
                                      'card-favorite-product-${product.productId}',
                                  child: Opacity(
                                    opacity: isUnavailable ? 0.60 : 1.0,
                                    child: ProductCard(
                                      productId: product.productId,
                                      product: product,
                                      userModel: userModel,
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: displayList.length,
                            addAutomaticKeepAlives: false,
                            addRepaintBoundaries: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _getCardAspectRatio(BuildContext context) {
    // Favorites cards need slightly more vertical room in previews and runtime
    // because unavailable-state copy and longer saved-product titles make the
    // grid taller than the generic home grid assumptions.
    return ResponsiveBreakpoints.getValue(
      context: context,
      mobile: 0.63,
      mobilePlus: 0.67,
      tablet: 0.76,
      desktop: 0.84,
    );
  }
}

// ═══ Widget Previews ═══

const _previewFavoriteImageBase = 'https://fastly.picsum.photos/id';

String _previewFavoriteImage(int id, {int width = 900, int height = 900}) =>
    '$_previewFavoriteImageBase/$id/$width/$height.jpg';

final _previewFavoritesUser = UserModel(
  uid: 'preview-favorites-user',
  email: 'favorites.preview@origna.ca',
  name: 'Morgan Chen',
  roles: const [UserRole.buyer],
  createdAt: DateTime(2026, 1, 12),
  verified: true,
);

final _previewFavoriteProducts = [
  Product(
    productId: 'favorite-preview-1',
    sellerId: 'favorite-seller-1',
    name: 'Canadian Wool Throw Blanket',
    description: 'Soft charcoal wool throw woven in Halifax.',
    priceCents: 8900,
    stockQuantity: 8,
    imageUrls: [_previewFavoriteImage(1011)],
    categoryId: 7,
    createdAt: DateTime(2026, 3, 2),
    lifecycleStatus: ProductLifecycleStatusValues.active,
    rating: 4.9,
    ratingCount: 52,
    freeShipping: true,
    shipFromCountry: 'CA',
    shipFromCity: 'Halifax',
    shipFromProvince: 'NS',
    isTrending: true,
    trendingScore: 92,
  ),
  Product(
    productId: 'favorite-preview-2',
    sellerId: 'favorite-seller-2',
    name: 'Stoneware Matcha Bowl',
    description: 'Hand-thrown bowl with speckled sage glaze.',
    priceCents: 4200,
    stockQuantity: 11,
    imageUrls: [_previewFavoriteImage(1025)],
    categoryId: 5,
    createdAt: DateTime(2026, 2, 24),
    lifecycleStatus: ProductLifecycleStatusValues.active,
    rating: 4.7,
    ratingCount: 19,
    shipFromCountry: 'CA',
    shipFromCity: 'Montreal',
    shipFromProvince: 'QC',
  ),
  Product(
    productId: 'favorite-preview-3',
    sellerId: 'favorite-seller-3',
    name: 'Seasonal Chocolate Box',
    description: 'Limited artisan assortment, currently unavailable.',
    priceCents: 2600,
    stockQuantity: 0,
    imageUrls: [_previewFavoriteImage(1060)],
    categoryId: 1,
    createdAt: DateTime(2026, 1, 28),
    lifecycleStatus: ProductLifecycleStatusValues.rejected,
    approvalRejectionReason: 'Seasonal run ended.',
    shipFromCountry: 'CA',
    shipFromCity: 'Toronto',
    shipFromProvince: 'ON',
  ),
  Product(
    productId: 'favorite-preview-4',
    sellerId: 'favorite-seller-4',
    name: 'Nordic Oak Desk Lamp',
    description: 'Warm LED lamp with FSC-certified oak base.',
    priceCents: 6800,
    stockQuantity: 14,
    imageUrls: [_previewFavoriteImage(1040)],
    categoryId: 4,
    createdAt: DateTime(2026, 3, 9),
    lifecycleStatus: ProductLifecycleStatusValues.active,
    rating: 4.6,
    ratingCount: 31,
    shipFromCountry: 'CA',
    shipFromCity: 'Ottawa',
    shipFromProvince: 'ON',
  ),
  Product(
    productId: 'favorite-preview-5',
    sellerId: 'favorite-seller-5',
    name: 'Premium Over-Ear Studio Headphones',
    description: 'Wireless ANC headphones with 40-hour battery life.',
    priceCents: 22900,
    compareAtPriceCents: 27900,
    stockQuantity: 5,
    imageUrls: [_previewFavoriteImage(180)],
    categoryId: 8,
    createdAt: DateTime(2026, 3, 12),
    lifecycleStatus: ProductLifecycleStatusValues.active,
    rating: 4.8,
    ratingCount: 144,
    shipFromCountry: 'CA',
    shipFromCity: 'Calgary',
    shipFromProvince: 'AB',
  ),
  Product(
    productId: 'favorite-preview-6',
    sellerId: 'favorite-seller-6',
    name: 'Small-Batch Espresso Beans',
    description: 'Roasted weekly with dark chocolate and cherry notes.',
    priceCents: 2400,
    stockQuantity: 18,
    imageUrls: [_previewFavoriteImage(431)],
    categoryId: 2,
    createdAt: DateTime(2026, 3, 16),
    lifecycleStatus: ProductLifecycleStatusValues.active,
    rating: 4.9,
    ratingCount: 86,
    shipFromCountry: 'CA',
    shipFromCity: 'Vancouver',
    shipFromProvince: 'BC',
    freeShipping: true,
  ),
];

final _previewDenseFavoriteProducts = [
  ..._previewFavoriteProducts,
  Product(
    productId: 'favorite-preview-7',
    sellerId: 'favorite-seller-7',
    name: 'Handwoven Prairie Basket',
    description: 'Natural reed basket for blankets, plants, or storage.',
    priceCents: 5400,
    stockQuantity: 9,
    imageUrls: [_previewFavoriteImage(433)],
    categoryId: 6,
    createdAt: DateTime(2026, 3, 20),
    lifecycleStatus: ProductLifecycleStatusValues.active,
    rating: 4.5,
    ratingCount: 22,
    shipFromCountry: 'CA',
    shipFromCity: 'Winnipeg',
    shipFromProvince: 'MB',
  ),
  Product(
    productId: 'favorite-preview-8',
    sellerId: 'favorite-seller-8',
    name: 'Limited Pinot Cherry Preserve',
    description: 'Fruit preserve from Okanagan cherries and pinot noir.',
    priceCents: 1890,
    stockQuantity: 0,
    imageUrls: [_previewFavoriteImage(292)],
    categoryId: 1,
    createdAt: DateTime(2026, 3, 22),
    lifecycleStatus: ProductLifecycleStatusValues.archived,
    approvalRejectionReason: 'Vintage batch sold out.',
    shipFromCountry: 'CA',
    shipFromCity: 'Kelowna',
    shipFromProvince: 'BC',
  ),
];

Widget _favorites({List<Product>? products}) => previewScopeLoggedIn(
  uid: _previewFavoritesUser.uid,
  extraOverrides: [
    userProfileProvider.overrideWith((ref) => Stream.value(_previewFavoritesUser)),
    favoritedProductsProvider.overrideWith(
      (ref) => Future.value(products ?? _previewFavoriteProducts),
    ),
  ],
  child: const FavoritesScreen(),
);

Widget _favoritesEmpty() => previewScopeLoggedIn(
  uid: _previewFavoritesUser.uid,
  extraOverrides: [
    userProfileProvider.overrideWith((ref) => Stream.value(_previewFavoritesUser)),
    favoritedProductsProvider.overrideWith((ref) => Future.value([])),
  ],
  child: const FavoritesScreen(),
);

// ── Core states ─────────────────────────────────────────────────────────────
@Preview(
  name: 'Favorites Dark — Mobile',
  group: 'Favorites Screens',
  size: Size(390, 844),
)
Widget previewFavoritesScreenMobile() => previewMobile(child: _favorites());

@Preview(
  name: 'Favorites Dark — Tablet',
  group: 'Favorites Screens',
  size: Size(768, 1024),
)
Widget previewFavoritesScreenTablet() => previewTablet(child: _favorites());

@Preview(
  name: 'Favorites Dark — Desktop',
  group: 'Favorites Screens',
  size: Size(1280, 800),
)
Widget previewFavoritesScreenDesktop() => previewDesktop(child: _favorites());

@Preview(
  name: 'Favorites Light — Desktop',
  group: 'Favorites Screens',
  size: Size(1280, 800),
)
Widget previewFavoritesLightDesktop() =>
    previewDesktop(theme: previewLightTheme, child: _favorites());

@Preview(
  name: 'Favorites Empty — Mobile',
  group: 'Favorites Screens',
  size: Size(390, 844),
)
Widget previewFavoritesEmptyMobile() => previewMobile(child: _favoritesEmpty());

@Preview(
  name: 'Favorites Empty — Desktop',
  group: 'Favorites Screens',
  size: Size(1280, 800),
)
Widget previewFavoritesEmptyDesktop() =>
    previewDesktop(child: _favoritesEmpty());

// ── Richer mockups ───────────────────────────────────────────────────────────
@Preview(
  name: 'Favorites Dense Grid — Desktop',
  group: 'Favorites Screens',
  size: Size(1280, 900),
)
Widget previewFavoritesDenseDesktop() =>
    previewDesktop(child: _favorites(products: _previewDenseFavoriteProducts));

@Preview(
  name: 'Favorites Dense Grid — Web',
  group: 'Favorites Screens',
  size: Size(1440, 900),
)
Widget previewFavoritesDenseWeb() =>
    previewWeb(child: _favorites(products: _previewDenseFavoriteProducts));

@Preview(
  name: 'Favorites Light Dense — Web',
  group: 'Favorites Screens',
  size: Size(1440, 900),
)
Widget previewFavoritesLightDenseWeb() => previewWeb(
  theme: previewLightTheme,
  child: _favorites(products: _previewDenseFavoriteProducts),
);
