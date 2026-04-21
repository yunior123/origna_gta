part of '../addproduct_screen.dart';

// ============================================================================
// SHARED FORM WIDGETS — Glass text field, toggle, dropdown, section cards, etc.
// ============================================================================

extension _AddProductFormWidgets on _AddProductScreenState {
  Widget buildGlassTextField({
    Key? key,
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? hint,
    String? prefixText,
    String? suffixText,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool readOnly = false,
    String? errorText,
    String? semanticsLabel,
  }) {
    return Semantics(
      label: semanticsLabel ?? label,
      textField: true,
      child: TextFormField(
        key: key,
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        validator: validator,
        onChanged: onChanged,
        readOnly: readOnly,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: prefixText,
          suffixText: suffixText,
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          errorText: errorText,
          filled: true,
          fillColor: _formFillColor(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: DesignTokens.outline.withValues(alpha: 0.5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: DesignTokens.outline.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: DesignTokens.primary,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: DesignTokens.error),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          labelStyle: TextStyle(
            color: DesignTokens.textSecondary,
            fontSize: 13,
          ),
          hintStyle: TextStyle(color: DesignTokens.textDisabled, fontSize: 13),
        ),
      ),
    );
  }

  Widget buildGlassToggle({
    Key? key,
    required String label,
    String? subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? infoTitle,
    String? infoBody,
    String? semanticsLabel,
  }) {
    return Semantics(
      button: true,
      label:
          semanticsLabel ??
          'btn-toggle-${label.toLowerCase().replaceAll(' ', '-')}',
      toggled: value,
      child: GestureDetector(
        key: key,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: DesignTokens.durationFast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: value
                ? DesignTokens.primary.withValues(alpha: 0.06)
                : (Theme.of(context).brightness == Brightness.dark
                          ? DesignTokens.darkSurfaceVariant
                          : DesignTokens.surfaceVariant)
                      .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: value
                  ? DesignTokens.primary.withValues(alpha: 0.3)
                  : DesignTokens.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: value
                    ? DesignTokens.primary
                    : DesignTokens.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: value
                            ? DesignTokens.primary
                            : DesignTokens.textPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: DesignTokens.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (infoTitle != null && infoBody != null)
                Semantics(
                  button: true,
                  label: 'btn-info-${label.toLowerCase().replaceAll(' ', '-')}',
                  child: GestureDetector(
                    onTap: () => showInfoSheet(infoTitle, infoBody),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: DesignTokens.info.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              Semantics(
                label: label,
                child: SizedBox(
                  height: 28,
                  child: Switch.adaptive(
                    value: value,
                    onChanged: onChanged,
                    activeThumbColor: DesignTokens.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildGlassDropdown({
    Key? key,
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
    String? semanticsLabel,
  }) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: DropdownButtonFormField<String>(
        key: key,
        menuMaxHeight: ResponsiveBreakpoints.dropdownMaxHeight(context),
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: _formFillColor(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: DesignTokens.outline.withValues(alpha: 0.5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: DesignTokens.outline.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: DesignTokens.primary,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          labelStyle: TextStyle(
            color: DesignTokens.textSecondary,
            fontSize: 13,
          ),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget buildSectionCard({
    Key? key,
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required AddProductState state,
    required AddProductViewModel viewModel,
    required List<Widget> children,
  }) {
    return TapRegion(
      key: key,
      onTapInside: (_) {
        if (state.activeStep != index) viewModel.setActiveStep(index);
      },
      child: AnimatedContainer(
        duration: DesignTokens.durationNormal,
        decoration: BoxDecoration(
          color: DesignTokens.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: state.activeStep == index
                ? DesignTokens.primary.withValues(alpha: 0.3)
                : DesignTokens.outlineVariant,
            width: state.activeStep == index ? 1.5 : 1,
          ),
          boxShadow: state.activeStep == index
              ? [
                  BoxShadow(
                    color: DesignTokens.primary.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
              : DesignTokens.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: DesignTokens.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: DesignTokens.textOnPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: DesignTokens.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.activeStep == index)
                    Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: DesignTokens.primary,
                    ),
                ],
              ),
            ),
            const Divider(height: 24, indent: 20, endIndent: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCollapsibleSection({
    Key? key,
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return AnimatedContainer(
      key: key,
      duration: DesignTokens.durationNormal,
      decoration: BoxDecoration(
        color: DesignTokens.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.outlineVariant),
        boxShadow: DesignTokens.shadowSm,
      ),
      child: Theme(
        data: Theme.of(
          context,
        ).copyWith(dividerColor: DesignTokens.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [DesignTokens.secondary, DesignTokens.primary],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: DesignTokens.textOnPrimary, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: DesignTokens.textSecondary),
            ),
          ),
          children: children,
        ),
      ),
    );
  }

  Widget buildInfoBanner(String text, IconData icon, Color color) {
    // FIX [HIGH] WCAG 2.1 AA: amber (#F59E0B) on white is ~2:1 contrast — fails 4.5:1.
    // Use DesignTokens.warningText (#92400E, ~7:1) for text when banner is warning-colored.
    final isWarning = color == DesignTokens.warning;
    final textColor = isWarning ? DesignTokens.warningText : color;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTappableInfoHint(String shortText, String title, String body) {
    return Semantics(
      button: true,
      label: 'btn-info-hint-${title.toLowerCase().replaceAll(' ', '-')}',
      child: GestureDetector(
        onTap: () => showInfoSheet(title, body),
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: DesignTokens.info.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  shortText,
                  style: TextStyle(
                    fontSize: 11,
                    color: DesignTokens.textSecondary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: DesignTokens.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSubSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: DesignTokens.secondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: DesignTokens.textPrimary,
          ),
        ),
      ],
    );
  }

  // FIX [HIGH] Inconsistent styling: was bare default TextFormField, now matches buildGlassTextField.
  Widget buildUrlField({
    required String label,
    required String placeholder,
    required String? value,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        label:
            'input-add-product-url-${label.toLowerCase().replaceAll(' ', '-')}',
        textField: true,
        child: TextFormField(
          initialValue: value,
          decoration: InputDecoration(
            labelText: label,
            hintText: placeholder,
            prefixIcon: const Icon(Icons.link_rounded, size: 20),
            filled: true,
            fillColor: _formFillColor(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: DesignTokens.outline.withValues(alpha: 0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: DesignTokens.outline.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: DesignTokens.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: DesignTokens.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            labelStyle: const TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: 13,
            ),
            hintStyle: const TextStyle(
              color: DesignTokens.textDisabled,
              fontSize: 13,
            ),
          ),
          keyboardType: TextInputType.url,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          onChanged: (v) => onChanged(v.trim().isEmpty ? null : v.trim()),
        ),
      ),
    );
  }

  // FIX [MEDIUM] Missing SafeArea: bottom sheet content was clipped on notched devices.
  void showInfoSheet(String title, String body) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        minimum: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: DesignTokens.darkCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DesignTokens.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lightbulb_rounded,
                      color: DesignTokens.info,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.textPrimary,
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'btn-close-info-sheet',
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? DesignTokens.darkSurfaceVariant
                              : DesignTokens.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: DesignTokens.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                body,
                style: TextStyle(
                  fontSize: 14,
                  color: DesignTokens.textPrimary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ), // SafeArea
    );
  }
}
