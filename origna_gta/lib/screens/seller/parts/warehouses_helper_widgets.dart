part of '../seller_warehouses_screen.dart';

// ---------------------------------------------------------------------------
// Small reusable widgets
// ---------------------------------------------------------------------------

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'btn-warehouse-type-$label',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? DesignTokens.primary.withValues(alpha: 0.15)
                    : isDark
                    ? DesignTokens.darkSurfaceVariant
                    : DesignTokens.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? DesignTokens.primary : DesignTokens.outline,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: selected
                        ? DesignTokens.primary
                        : DesignTokens.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? DesignTokens.primary
                          : DesignTokens.textSecondary,
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final int? maxLength;

  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'input-warehouse-$label',
      textField: true,
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLength: maxLength,
        style: TextStyle(
          color: isDark ? DesignTokens.white : DesignTokens.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: DesignTokens.textSecondary),
          hintStyle: TextStyle(color: DesignTokens.textTertiary),
          filled: true,
          fillColor: isDark
              ? DesignTokens.darkSurfaceVariant
              : DesignTokens.white,
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: DesignTokens.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: DesignTokens.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: DesignTokens.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
