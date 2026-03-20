import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer skeleton displayed while product data is loading.
class ProductDetailSkeleton extends StatelessWidget {
  const ProductDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? DesignTokens.darkCard : DesignTokens.outlineVariant;
    final highlightColor =
        isDark ? DesignTokens.darkSurfaceVariant : DesignTokens.surface;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                height: 340, width: double.infinity, color: DesignTokens.white),
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 28,
                    decoration: BoxDecoration(
                      color: DesignTokens.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacing8),
                  Container(
                    width: 200,
                    height: 28,
                    decoration: BoxDecoration(
                      color: DesignTokens.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacing12),
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 28,
                        decoration: BoxDecoration(
                          color: DesignTokens.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 50,
                        height: 16,
                        decoration: BoxDecoration(
                          color: DesignTokens.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spacing16),
                  Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(
                      color: DesignTokens.white,
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radius16),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacing20),
                  Container(
                    width: 120,
                    height: 20,
                    decoration: BoxDecoration(
                      color: DesignTokens.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacing12),
                  Container(
                    width: double.infinity,
                    height: 96,
                    decoration: BoxDecoration(
                      color: DesignTokens.white,
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radius16),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacing20),
                  Container(
                    width: 100,
                    height: 20,
                    decoration: BoxDecoration(
                      color: DesignTokens.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacing12),
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: DesignTokens.white,
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radius16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
