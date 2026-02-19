import 'package:flutter/material.dart';

import '../utils/design_tokens.dart';

/// Modern 2100 Product Card with glassmorphism
class ModernProductCard extends StatefulWidget {
  final String productName;
  final double price;
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

  const ModernProductCard({
    super.key,
    required this.productName,
    required this.price,
    required this.imageUrl,
    required this.sellerName,
    this.rating = 4.5,
    this.reviewCount = 0,
    required this.onTap,
    this.onAddToCart,
    this.shipFromCity,
    this.shipFromProvince,
    this.shipFromCountry,
    this.shipFromCountries,
  });

  @override
  State<ModernProductCard> createState() => _ModernProductCardState();
}

class _ModernProductCardState extends State<ModernProductCard> with SingleTickerProviderStateMixin {
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
        return 'Ships from: ${countries.join(' · ')}';
      }
      return 'Ships from: ${countries.length} locations worldwide';
    }
    // Single location — show full city, province, country
    final parts = [
      if (widget.shipFromCity != null) widget.shipFromCity!,
      if (widget.shipFromProvince != null) widget.shipFromProvince!,
      if (widget.shipFromCountry != null) widget.shipFromCountry!,
    ];
    return parts.isEmpty ? '' : 'Ships from: ${parts.join(', ')}';
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
          label: '${widget.productName}, \$${widget.price.toStringAsFixed(2)}, ${widget.rating.toStringAsFixed(1)} stars',
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
            decoration: BoxDecoration(
              color: isDark ? DesignTokens.darkSurfaceVariant.withValues(alpha: 0.6) : DesignTokens.surface,
              borderRadius: BorderRadius.circular(DesignTokens.radius16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
              boxShadow: DesignTokens.shadowMd,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radius16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Stack(
                    children: [
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [DesignTokens.primary.withValues(alpha: 0.1), DesignTokens.secondary.withValues(alpha: 0.1)],
                          ),
                        ),
                        child: widget.imageUrl.isNotEmpty
                            ? Image.network(
                                widget.imageUrl,
                                fit: BoxFit.cover,
                                semanticLabel: '${widget.productName} product image',
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported_outlined, color: DesignTokens.textSecondary, size: 48),
                              )
                            : const Icon(Icons.image_not_supported_outlined, color: DesignTokens.textSecondary, size: 48),
                      ),
                      // Badge (optional)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing8, vertical: DesignTokens.spacing4),
                          decoration: BoxDecoration(gradient: DesignTokens.primaryGradient, borderRadius: BorderRadius.circular(DesignTokens.radius8)),
                          child: const Text(
                            'New',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(DesignTokens.spacing12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.productName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
                          ),
                          const SizedBox(height: DesignTokens.spacing4),
                          Text(
                            widget.sellerName,
                            style: TextStyle(fontSize: 12, color: DesignTokens.textSecondary, fontWeight: FontWeight.w500),
                          ),
                          if (widget.shipFromCity != null || (widget.shipFromCountries != null && widget.shipFromCountries!.isNotEmpty)) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded, size: 11, color: DesignTokens.textTertiary),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    _shipFromLabel,
                                    style: TextStyle(fontSize: 11, color: DesignTokens.textTertiary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Spacer(),
                          // Rating
                          Row(
                            children: [
                              Icon(Icons.star_rounded, size: 14, color: DesignTokens.warning),
                              const SizedBox(width: 4),
                              Text(widget.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              if (widget.reviewCount > 0) ...[
                                const SizedBox(width: 4),
                                Text('(${widget.reviewCount})', style: TextStyle(fontSize: 11, color: DesignTokens.textSecondary)),
                              ],
                            ],
                          ),
                          const SizedBox(height: DesignTokens.spacing8),
                          // Price and CTA
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '\$${widget.price.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: DesignTokens.primary),
                              ),
                              if (widget.onAddToCart != null)
                                Semantics(
                                  button: true,
                                  label: 'Add ${widget.productName} to cart',
                                  child: GestureDetector(
                                    onTap: widget.onAddToCart,
                                    child: Container(
                                      padding: const EdgeInsets.all(14), // WCAG 2.5.8: ≥48dp touch target
                                      decoration: BoxDecoration(
                                        gradient: DesignTokens.primaryGradient,
                                        borderRadius: BorderRadius.circular(DesignTokens.radius8),
                                      ),
                                      child: const Icon(Icons.add, size: 20, color: Colors.white),
                                    ),
                                  ),
                                ),
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
    _controller = AnimationController(duration: DesignTokens.durationNormal, vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _controller, curve: DesignTokens.easeOutCubic));
  }
}
