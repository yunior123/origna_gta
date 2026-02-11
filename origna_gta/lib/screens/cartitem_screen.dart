import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:shimmer/shimmer.dart';

class CartItemScreen extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> item;
  final VoidCallback onRemove;

  const CartItemScreen({super.key, required this.productId, required this.item, required this.onRemove});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Extract item fields using schema constants (static - won't rebuild on quantity change)
    final imageUrlsList = (item[Fields.imageUrls] as List<dynamic>?)?.cast<String>() ?? [];
    final name = item[Fields.name] as String? ?? 'Product';
    final unitPrice = (item[Fields.price] ?? 0.0).toDouble();

    return Dismissible(
      key: ValueKey('dismiss_$productId'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        return true;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: DesignTokens.spacing12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [DesignTokens.error.withValues(alpha: 0.8), DesignTokens.error],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: DesignTokens.spacing12),
        padding: const EdgeInsets.all(DesignTokens.spacing12),
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : DesignTokens.outline.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.primary.withValues(alpha: isDark ? 0.08 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              child: SizedBox(
                width: 80,
                height: 80,
                child: _buildImage(imageUrlsList, isDark),
              ),
            ),
            const SizedBox(width: DesignTokens.spacing12),
            // Name + price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Price display wrapped in Consumer - only this rebuilds when quantity changes
                  Consumer(
                    builder: (context, ref, _) {
                      final quantityAsync = ref.watch(cartItemQuantityProvider(productId));
                      final quantity = quantityAsync.valueOrNull ?? 1;
                      final totalPrice = unitPrice * quantity;
                      return ShaderMask(
                        shaderCallback: (bounds) => DesignTokens.primaryGradient.createShader(bounds),
                        child: Text(
                          '\$${totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      );
                    },
                  ),
                  // Unit price hint when qty > 1
                  Consumer(
                    builder: (context, ref, _) {
                      final quantityAsync = ref.watch(cartItemQuantityProvider(productId));
                      final quantity = quantityAsync.valueOrNull ?? 1;
                      if (quantity <= 1) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '\$${unitPrice.toStringAsFixed(2)} each',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Quantity controls + delete
            Column(
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final quantityAsync = ref.watch(cartItemQuantityProvider(productId));
                    final quantity = quantityAsync.valueOrNull ?? 0;
                    final cartController = ref.read(cartControllerProvider);

                    if (quantity <= 0) return const SizedBox.shrink();

                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : DesignTokens.surfaceVariant,
                        borderRadius: BorderRadius.circular(DesignTokens.radius12),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : DesignTokens.outline.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _QuantityButton(
                            icon: Icons.remove_rounded,
                            onPressed: quantity > 1 ? () => cartController.updateQuantity(productId, quantity - 1) : null,
                            isDark: isDark,
                            semanticLabel: 'btn-cart-qty-minus',
                          ),
                          AnimatedSwitcher(
                            duration: DesignTokens.durationFast,
                            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                            child: Padding(
                              key: ValueKey(quantity),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                '$quantity',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.grey[900],
                                ),
                              ),
                            ),
                          ),
                          _QuantityButton(
                            icon: Icons.add_rounded,
                            onPressed: () => cartController.updateQuantity(productId, quantity + 1),
                            isDark: isDark,
                            semanticLabel: 'btn-cart-qty-plus',
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: DesignTokens.spacing8),
                IconButton(
                  tooltip: 'Remove from cart',
                  icon: Icon(Icons.delete_outline_rounded, color: DesignTokens.error.withValues(alpha: 0.7), size: 20),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(List<String> imageUrlsList, bool isDark) {
    if (imageUrlsList.isEmpty) {
      return Container(
        color: isDark ? const Color(0xFF2A2A3E) : Colors.grey[100],
        child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[400]),
      );
    }

    if (imageUrlsList.length == 1) {
      return CachedNetworkImage(
        imageUrl: imageUrlsList[0],
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
          child: Container(color: isDark ? Colors.grey[900] : Colors.white),
        ),
        errorWidget: (context, url, error) => Container(
          color: isDark ? const Color(0xFF2A2A3E) : Colors.grey[100],
          child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[400]),
        ),
      );
    }

    // Multiple images - swipeable PageView
    return Stack(
      children: [
        PageView.builder(
          itemCount: imageUrlsList.length,
          itemBuilder: (context, index) {
            return CachedNetworkImage(
              imageUrl: imageUrlsList[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                child: Container(color: isDark ? Colors.grey[900] : Colors.white),
              ),
              errorWidget: (context, url, error) => Container(
                color: isDark ? const Color(0xFF2A2A3E) : Colors.grey[100],
                child: Icon(Icons.image_not_supported_outlined, size: 24, color: Colors.grey[400]),
              ),
            );
          },
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.collections, color: Colors.white, size: 10),
                const SizedBox(width: 2),
                Text('${imageUrlsList.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact quantity +/- button with haptic feedback
class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isDark;
  final String semanticLabel;

  const _QuantityButton({required this.icon, this.onPressed, required this.isDark, required this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: !isDisabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignTokens.radius8),
          onTap: isDisabled
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onPressed!();
                },
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 18,
              color: isDisabled ? Colors.grey[400] : (isDark ? Colors.white70 : DesignTokens.primary),
            ),
          ),
        ),
      ),
    );
  }
}
