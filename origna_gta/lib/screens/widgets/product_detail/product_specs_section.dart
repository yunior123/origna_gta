import 'package:flutter/material.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/spec_templates.dart';
import 'package:origna_gta/widgets/modern_card.dart';

// ============================================================================
// SPEC COLORS — Domain-specific, consistent with NutritionColors pattern
// ============================================================================

class _SpecColors {
  static Color groupHeader = DesignTokens.primary;
  static Color specKey = DesignTokens.white.withValues(alpha: 0.7);
  static Color specValue = DesignTokens.white;
  static Color zebraRow = DesignTokens.darkCard.withValues(alpha: 0.5);
  static Color divider = DesignTokens.white.withValues(alpha: 0.08);
  static Color pillBg = DesignTokens.primary.withValues(alpha: 0.12);
  static Color pillText = DesignTokens.primary;
}

// ============================================================================
// PRODUCT SPECS SECTION — Main widget
// ============================================================================

/// Displays product specifications as a collapsible grouped table.
///
/// Only renders if product has [ProductSpecs] with non-empty specs list.
/// Best Buy-inspired layout: grouped subsections with zebra-striped key-value rows.
class ProductSpecsSection extends StatelessWidget {
  final Product product;
  const ProductSpecsSection({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final specs = product.specs;
    if (specs == null || specs.specs.isEmpty) return const SizedBox.shrink();

    // Group specs by group field
    final grouped = <String, List<ProductSpec>>{};
    for (final spec in specs.specs) {
      final group = spec.group ?? 'General';
      grouped.putIfAbsent(group, () => []).add(spec);
    }

    // Look up template for display label resolution
    final template = getSpecsForCategory(product.categoryId);

    return ModernCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Icon(
            Icons.list_alt_rounded,
            size: 20,
            color: DesignTokens.primary,
          ),
          title: const Text(
            'Specifications',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DesignTokens.white,
            ),
          ),
          trailing: _buildTrailingPills(specs),
          iconColor: DesignTokens.textSecondary,
          collapsedIconColor: DesignTokens.textSecondary,
          children: [
            // Brand / Color / Material pills at top
            if (specs.brand != null ||
                specs.color != null ||
                specs.material != null) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (specs.brand != null)
                    _SpecPill(label: 'Brand', value: specs.brand!),
                  if (specs.color != null)
                    _SpecPill(label: 'Color', value: specs.color!),
                  if (specs.material != null)
                    _SpecPill(label: 'Material', value: specs.material!),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Grouped spec tables
            ...grouped.entries.map((entry) {
              final groupName = entry.key;
              final groupSpecs = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group header
                    Semantics(
                      label: 'spec-group-$groupName',
                      header: true,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          groupName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _SpecColors.groupHeader,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                    // Divider under group header
                    Container(height: 1, color: _SpecColors.divider),
                    // Spec rows with zebra striping
                    ...groupSpecs.asMap().entries.map((specEntry) {
                      final index = specEntry.key;
                      final spec = specEntry.value;
                      final isZebra = index.isOdd;
                      final displayLabel = _resolveLabel(spec.key, template);

                      return _SpecRow(
                        label: displayLabel,
                        value: _formatValue(spec),
                        specKey: spec.key,
                        isZebra: isZebra,
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget? _buildTrailingPills(ProductSpecs specs) {
    if (specs.brand != null) {
      return Text(
        specs.brand!,
        style: TextStyle(fontSize: 13, color: _SpecColors.specKey),
      );
    }
    return null;
  }

  /// Resolve spec key to human-readable label via template lookup.
  String _resolveLabel(String key, CategorySpecConfig? template) {
    if (template != null) {
      for (final t in template.templates) {
        if (t.key == key) return t.labelEn;
      }
    }
    // Fallback: convert camelCase to Title Case
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
        .trim()
        .replaceRange(0, 1, key[0].toUpperCase());
  }

  /// Format spec value with optional unit.
  String _formatValue(ProductSpec spec) {
    if (spec.unit != null && spec.unit!.isNotEmpty) {
      return '${spec.value} ${spec.unit}';
    }
    // Boolean display
    if (spec.valueType == 'boolean') {
      return spec.value.toLowerCase() == 'true' ? 'Yes' : 'No';
    }
    return spec.value;
  }
}

// ============================================================================
// SPEC PILL — Brand/Color/Material summary
// ============================================================================

class _SpecPill extends StatelessWidget {
  final String label;
  final String value;
  const _SpecPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _SpecColors.pillBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: TextStyle(
                fontSize: 12,
                color: _SpecColors.pillText,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: DesignTokens.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SPEC ROW — Key-value row with zebra striping
// ============================================================================

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;
  final String specKey;
  final bool isZebra;

  const _SpecRow({
    required this.label,
    required this.value,
    required this.specKey,
    required this.isZebra,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'spec-$specKey: $label $value',
      child: Container(
        color: isZebra ? _SpecColors.zebraRow : DesignTokens.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: _SpecColors.specKey,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: _SpecColors.specValue,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
