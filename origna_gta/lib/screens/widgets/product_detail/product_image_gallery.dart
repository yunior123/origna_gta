import 'package:origna_gta/utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/products/product_detail_viewmodel.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/media_url_resolver.dart';
import 'package:origna_gta/widgets/modern_skeleton_loader.dart';

/// Image gallery with PageView for product images and optional video thumbnail.
/// Used in both mobile (SliverAppBar) and desktop (side-by-side) layouts.
class ProductImageGallery extends ConsumerWidget {
  final List<String> imageUrls;
  final bool hasVideo;
  final String? videoUrl;
  final double height;
  final bool isWideScreen;
  final VoidCallback? onVideoTap;
  final void Function(List<String> urls, int index)? onImageTap;

  const ProductImageGallery({
    super.key,
    required this.imageUrls,
    required this.hasVideo,
    this.videoUrl,
    required this.height,
    this.isWideScreen = false,
    this.onVideoTap,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalMediaCount = imageUrls.length + (hasVideo ? 1 : 0);
    final viewModel = ref.read(productDetailViewModelProvider.notifier);

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.primary.withValues(alpha: 0.1),
            DesignTokens.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: isWideScreen
            ? BorderRadius.circular(DesignTokens.radius16)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageUrls.isNotEmpty || hasVideo
              ? PageView.builder(
                  itemCount: totalMediaCount,
                  onPageChanged: viewModel.setImageIndex,
                  itemBuilder: (context, index) {
                    if (hasVideo && index == 0) {
                      return _VideoThumbnail(
                        imageUrls: imageUrls,
                        onTap: onVideoTap,
                      );
                    }

                    final imgIndex = hasVideo ? index - 1 : index;
                    return Semantics(
                      label: 'product.image_semantics'.tr(
                        namedArgs: {
                          'n': '${imgIndex + 1}',
                          'total': '${imageUrls.length}',
                        },
                      ),
                      button: true,
                      image: true,
                      child: GestureDetector(
                        onTap: () => onImageTap?.call(imageUrls, imgIndex),
                        child: SizedBox.expand(
                          child: _GalleryImage(
                            imageSource: imageUrls[imgIndex],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                )
              : const _ImageErrorPlaceholder(),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: ImageDots(imageCount: totalMediaCount),
          ),
        ],
      ),
    );
  }
}

/// Video thumbnail overlay shown as the first page in the image gallery.
class _VideoThumbnail extends StatelessWidget {
  final List<String> imageUrls;
  final VoidCallback? onTap;

  const _VideoThumbnail({required this.imageUrls, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'btn-play-video',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: DesignTokens.black.withValues(alpha: 0.87),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (imageUrls.isNotEmpty)
                Opacity(
                  opacity: 0.5,
                  child: _GalleryImage(
                    imageSource: imageUrls[0],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: DesignTokens.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DesignTokens.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 64,
                  color: DesignTokens.white,
                ),
              ),
              Positioned(
                bottom: 40,
                child: Text(
                  'product.watch_video'.tr(),
                  style: const TextStyle(
                    color: DesignTokens.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(blurRadius: 10, color: DesignTokens.black),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryImage extends StatelessWidget {
  final String imageSource;
  final BoxFit fit;
  final double? width;
  final double? height;

  const _GalleryImage({
    required this.imageSource,
    required this.fit,
    this.width,
    this.height,
  });

  bool get _isAssetImage =>
      imageSource.startsWith('assets/') || imageSource.startsWith('images/');

  @override
  Widget build(BuildContext context) {
    final resolvedSource = resolveMediaUrl(imageSource);
    if (_isAssetImage) {
      return Image.asset(
        resolvedSource,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => const _ImageErrorPlaceholder(),
      );
    }

    final resolvedUri = Uri.tryParse(resolvedSource);
    if (resolvedSource.isEmpty ||
        resolvedUri == null ||
        !resolvedUri.hasScheme ||
        !(resolvedUri.scheme == 'http' || resolvedUri.scheme == 'https')) {
      return const _ImageErrorPlaceholder();
    }

    return CachedNetworkImage(
      imageUrl: resolvedSource,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) => ModernSkeletonLoader.imagePlaceholder(),
      errorWidget: (context, url, error) => const _ImageErrorPlaceholder(),
    );
  }
}

/// Placeholder shown when a product image fails to load.
class _ImageErrorPlaceholder extends StatelessWidget {
  const _ImageErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? DesignTokens.darkSurfaceVariant
            : DesignTokens.surfaceVariant,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(
          color: isDark
              ? DesignTokens.white.withValues(alpha: 0.1)
              : DesignTokens.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? DesignTokens.white.withValues(alpha: 0.08)
                    : DesignTokens.primary.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                size: 32,
                color: isDark
                    ? DesignTokens.white.withValues(alpha: 0.5)
                    : DesignTokens.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'product.no_image'.tr(),
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? DesignTokens.textSecondary
                    : DesignTokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page indicator dots for the image gallery.
class ImageDots extends ConsumerWidget {
  final int imageCount;

  const ImageDots({super.key, required this.imageCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (imageCount <= 1) return const SizedBox.shrink();

    final currentIndex = ref.watch(
      productDetailViewModelProvider.select((state) => state.currentImageIndex),
    );

    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          imageCount,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: currentIndex == index
                  ? DesignTokens.white
                  : DesignTokens.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
