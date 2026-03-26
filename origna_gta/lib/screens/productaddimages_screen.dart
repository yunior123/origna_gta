import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:flutter/widget_previews.dart';

// ─── Riverpod state for ProductAddImages ─────────────────────────────────────
final _productImagesProvider = StateProvider.autoDispose<List<ImageModel>>(
  (ref) => [],
);

/// Image picker/uploader for product creation: drag-drop, reorder, compress.
class ProductAddImages extends ConsumerStatefulWidget {
  final List<ImageModel> imageModels;
  final ValueChanged<List<ImageModel>>? onImagesChanged;

  const ProductAddImages({
    super.key,
    required this.imageModels,
    this.onImagesChanged,
  });

  @override
  ConsumerState<ProductAddImages> createState() => _ProductAddImagesState();
}

/// Individual image tile with overlay controls
class _ImageTile extends StatelessWidget {
  final ImageModel imageModel;
  final int index;
  final bool isPrimary;
  final VoidCallback onRemove;

  const _ImageTile({
    required this.imageModel,
    required this.index,
    required this.isPrimary,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Image
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isPrimary
                ? Border.all(color: DesignTokens.primary, width: 2)
                : Border.all(
                    color: DesignTokens.outline.withValues(alpha: 0.2),
                  ),
            boxShadow: DesignTokens.shadowSm,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isPrimary ? 14 : 15),
            child: Semantics(
              image: true,
              label: isPrimary
                  ? 'product-image-cover'
                  : 'product-image-${index + 1}',
              child: Image.memory(
                imageModel.bytes,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                cacheWidth: 110,
                cacheHeight: 110,
              ),
            ),
          ),
        ),
        // Primary badge
        if (isPrimary)
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: DesignTokens.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'product.cover'.tr(),
                style: const TextStyle(
                  color: DesignTokens.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        // Remove button
        Positioned(
          top: 4,
          right: 4,
          child: Semantics(
            button: true,
            label: 'btn-remove-image',
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: DesignTokens.error.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: DesignTokens.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductAddImagesState extends ConsumerState<ProductAddImages> {
  @override
  Widget build(BuildContext context) {
    final imageModels = ref.watch(_productImagesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image count indicator
        Row(
          children: [
            Text(
              'product.photos_count'.tr(
                namedArgs: {'count': imageModels.length.toString()},
              ),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: imageModels.length >= BusinessRules.maxProductImages
                    ? DesignTokens.warning
                    : DesignTokens.textSecondary,
              ),
            ),
            if (imageModels.length >= BusinessRules.maxProductImages) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: DesignTokens.success,
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: Row(
            children: [
              // Reorderable list of images
              if (imageModels.isNotEmpty)
                Expanded(
                  child: ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    itemCount: imageModels.length,
                    onReorder: (oldIndex, newIndex) {
                      final current = [...ref.read(_productImagesProvider)];
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = current.removeAt(oldIndex);
                      current.insert(newIndex, item);
                      ref.read(_productImagesProvider.notifier).state = current;
                      widget.onImagesChanged?.call(List.unmodifiable(current));
                    },
                    proxyDecorator: (child, index, animation) {
                      return Material(
                        color: DesignTokens.transparent,
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      final m = imageModels[index];
                      return ReorderableDelayedDragStartListener(
                        key: ValueKey(m.url + index.toString()),
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _ImageTile(
                            imageModel: m,
                            index: index,
                            isPrimary: index == 0,
                            onRemove: () {
                              final current = [
                                ...ref.read(_productImagesProvider),
                              ];
                              current.removeAt(index);
                              ref.read(_productImagesProvider.notifier).state =
                                  current;
                              widget.onImagesChanged?.call(
                                List.unmodifiable(current),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              // Add button (fixed at the end)
              if (imageModels.length < BusinessRules.maxProductImages)
                Padding(
                  padding: EdgeInsets.only(left: imageModels.isEmpty ? 0 : 4),
                  child: Semantics(
                    button: true,
                    label: 'btn-add-photo',
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: AnimatedContainer(
                        duration: DesignTokens.durationFast,
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: DesignTokens.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: DesignTokens.primary.withValues(alpha: 0.3),
                            width: 1.5,
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: DesignTokens.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_rounded,
                                color: DesignTokens.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'product.add_photo'.tr(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: DesignTokens.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(covariant ProductAddImages oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync internal list when parent passes new images (e.g., after edit screen loads saved images)
    if (widget.imageModels != oldWidget.imageModels) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(_productImagesProvider.notifier).state =
              List<ImageModel>.from(widget.imageModels);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(_productImagesProvider.notifier).state = List<ImageModel>.from(
        widget.imageModels,
      );
    });
  }

  // FIX [MEDIUM] UX: Single-pick replaced with multi-image select — sellers can pick multiple
  // photos in one tap instead of repeating the picker flow for each image.
  Future<void> _pickImage() async {
    final messenger = ScaffoldMessenger.of(context);
    final imageModels = ref.read(_productImagesProvider);

    if (imageModels.length >= BusinessRules.maxProductImages) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: DesignTokens.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text('product.max_images'.tr()),
            ],
          ),
          backgroundColor: DesignTokens.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      // Multi-select: allow picking up to remaining slots in a single gallery session
      final remaining = BusinessRules.maxProductImages - imageModels.length;
      final pickedFiles = await picker.pickMultiImage(limit: remaining);

      if (pickedFiles.isNotEmpty) {
        final newImages = <ImageModel>[...imageModels];
        int addedCount = 0;
        for (final pickedFile in pickedFiles) {
          if (newImages.length >= BusinessRules.maxProductImages) break;
          if (pickedFile.path.isEmpty) continue;
          final bytes = await pickedFile.readAsBytes();
          if (bytes.isNotEmpty) {
            newImages.add(ImageModel(url: pickedFile.path, bytes: bytes));
            addedCount++;
          }
        }
        if (addedCount > 0) {
          ref.read(_productImagesProvider.notifier).state = newImages;
          widget.onImagesChanged?.call(List.unmodifiable(newImages));
        } else {
          messenger.showSnackBar(
            SnackBar(content: Text('product.empty_image'.tr())),
          );
        }
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('product.pick_image_failed'.tr())),
      );
    }
  }
}


// === Widget Previews ===


// ═══ Widget Previews ═══

Widget _productAddImagesContent() => previewScope(
  child: Scaffold(body: Center(child: ProductAddImages(imageModels: []))),
);

@Preview(name: 'Product Add Images — Mobile', group: 'Product Screens', size: Size(390, 844))
Widget previewProductAddImagesMobile() => previewMobile(child: _productAddImagesContent());

@Preview(name: 'Product Add Images — Tablet', group: 'Product Screens', size: Size(768, 1024))
Widget previewProductAddImagesTablet() => previewTablet(child: _productAddImagesContent());

@Preview(name: 'Product Add Images — Desktop', group: 'Product Screens', size: Size(1280, 800))
Widget previewProductAddImagesDesktop() => previewDesktop(child: _productAddImagesContent());

@Preview(name: 'Product Add Images — Web', group: 'Product Screens', size: Size(1440, 900))
Widget previewProductAddImagesWeb() => previewWeb(child: _productAddImagesContent());

// ── Light ────────────────────────────────────────────────────────────────────
@Preview(name: 'Product Add Images Light — Mobile', group: 'Product Screens', size: Size(390, 844))
Widget previewProductAddImagesLightMobile() => previewMobile(theme: previewLightTheme, child: _productAddImagesContent());

@Preview(name: 'Product Add Images Light — Tablet', group: 'Product Screens', size: Size(768, 1024))
Widget previewProductAddImagesLightTablet() => previewTablet(theme: previewLightTheme, child: _productAddImagesContent());

@Preview(name: 'Product Add Images Light — Desktop', group: 'Product Screens', size: Size(1280, 800))
Widget previewProductAddImagesLightDesktop() => previewDesktop(theme: previewLightTheme, child: _productAddImagesContent());

@Preview(name: 'Product Add Images Light — Web', group: 'Product Screens', size: Size(1440, 900))
Widget previewProductAddImagesLightWeb() => previewWeb(theme: previewLightTheme, child: _productAddImagesContent());

