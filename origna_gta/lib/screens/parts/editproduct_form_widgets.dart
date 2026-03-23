part of '../editproduct_screen.dart';

class _EditDigitalTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _EditDigitalTypeChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          'btn-edit-digital-type-${label.toLowerCase().replaceAll(' ', '-')}',
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? DesignTokens.primary.withValues(alpha: 0.15)
                : DesignTokens.transparent,
            border: Border.all(
              color: selected
                  ? DesignTokens.primary
                  : DesignTokens.textSecondary.withValues(alpha: 0.3),
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? DesignTokens.primary : null),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? DesignTokens.primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
