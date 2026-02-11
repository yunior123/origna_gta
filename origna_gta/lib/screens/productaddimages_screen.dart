import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart';

class _ProductAddImagesState extends State<ProductAddImages> {
  late List<ImageModel> _imageModels;

  @override
  void initState() {
    super.initState();
    _imageModels = List<ImageModel>.from(widget.imageModels);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image count indicator
        Row(
          children: [
            Text(
              '${_imageModels.length}/5 photos',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _imageModels.length >= 5 ? DesignTokens.warning : DesignTokens.textSecondary,
              ),
            ),
            if (_imageModels.length >= 5) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle_rounded, size: 16, color: DesignTokens.success),
            ],
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              // Existing images
              ..._imageModels.asMap().entries.map((entry) {
                final index = entry.key;
                final m = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _ImageTile(
                    imageModel: m,
                    index: index,
                    isPrimary: index == 0,
                    onRemove: () {
                      setState(() => _imageModels.remove(m));
                      widget.onImagesChanged?.call(List.unmodifiable(_imageModels));
                    },
                  ),
                );
              }),
              // Add button
              if (_imageModels.length < 5)
                Semantics(
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
                          child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Add Photo',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DesignTokens.primary),
                        ),
                      ],
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

  Future<void> _pickImage() async {
    final messenger = ScaffoldMessenger.of(context);

    if (_imageModels.length >= 5) {
      messenger.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Maximum 5 images allowed'),
            ],
          ),
          backgroundColor: DesignTokens.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null && pickedFile.path.isNotEmpty) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          if (bytes.isNotEmpty) {
            _imageModels.add(ImageModel(url: pickedFile.path, bytes: bytes));
          } else {
            messenger.showSnackBar(SnackBar(content: Text('Selected image is empty.')));
          }
        });
        if (bytes.isNotEmpty) {
          widget.onImagesChanged?.call(List.unmodifiable(_imageModels));
        }
      }
    } catch (e) {
      messenger.showSnackBar(const SnackBar(content: Text('Failed to pick image. Please try again.')));
    }
  }
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
                : Border.all(color: DesignTokens.outline.withValues(alpha: 0.2)),
            boxShadow: DesignTokens.shadowSm,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isPrimary ? 14 : 15),
            child: Image.memory(
              imageModel.bytes,
              width: 110,
              height: 110,
              fit: BoxFit.cover,
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
              child: const Text(
                'Cover',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
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
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
            ),
          ),
          ),
        ),
      ],
    );
  }
}

class ProductAddImages extends StatefulWidget {
  final List<ImageModel> imageModels;
  final ValueChanged<List<ImageModel>>? onImagesChanged;

  const ProductAddImages({super.key, required this.imageModels, this.onImagesChanged});

  @override
  State<ProductAddImages> createState() => _ProductAddImagesState();
}
