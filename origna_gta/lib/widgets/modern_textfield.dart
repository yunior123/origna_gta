import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:origna_gta/utils/design_tokens.dart';
import 'package:flutter/widget_previews.dart';

/// Modern 2100 Text Input Field with glassmorphism
class ModernTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final bool isMultiline;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final int minLines;
  final int? maxLength;
  final bool showCounter;
  final Key? textFieldKey;
  final String? semanticsLabel;

  const ModernTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.isMultiline = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.minLines = 1,
    this.maxLength,
    this.showCounter = false,
    this.textFieldKey,
    this.semanticsLabel,
  });

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField> {
  late FocusNode _focusNode;
  late bool _obscureText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? DesignTokens.textOnDark
                  : DesignTokens.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing8),
        ],
        Semantics(
          label: widget.semanticsLabel ?? widget.label,
          textField: true,
          container: true,
          child: TextFormField(
            key: widget.textFieldKey,
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            obscureText: _obscureText,
            maxLines: _obscureText ? 1 : widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            validator: widget.validator,
            onChanged: widget.onChanged,
            cursorColor: DesignTokens.primary,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: isDark
                    ? DesignTokens.textOnDarkSecondary
                    : DesignTokens.textDisabled,
                fontSize: 14,
              ),
              filled: true,
              fillColor: isDark
                  ? DesignTokens.darkCard
                  : DesignTokens.surfaceVariant.withValues(alpha: 0.7),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: DesignTokens.primary,
                      size: 20,
                    )
                  : null,
              suffixIcon: widget.suffixIcon != null
                  ? Semantics(
                      button: true,
                      label: 'common.toggle_password_visibility'.tr(),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: GestureDetector(
                          onTap: widget.onSuffixTap,
                          child: Center(
                            child: Icon(
                              widget.suffixIcon,
                              color: DesignTokens.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                borderSide: BorderSide(color: DesignTokens.transparent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                borderSide: BorderSide(
                  color: DesignTokens.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                borderSide: BorderSide(color: DesignTokens.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                borderSide: BorderSide(color: DesignTokens.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                borderSide: BorderSide(color: DesignTokens.error, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacing16,
                vertical: DesignTokens.spacing12,
              ),
              counterText: widget.showCounter ? null : '',
            ),
            style: TextStyle(
              fontSize: 15,
              color: isDark
                  ? DesignTokens.textOnDark
                  : DesignTokens.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(ModernTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPassword != widget.isPassword) {
      setState(() {
        _obscureText = widget.isPassword;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _obscureText = widget.isPassword;
  }
}

// === Widget Previews ===

// ═══ Widget Previews ═══

@Preview(name: 'Modern TextField — Variants', group: 'ModernTextField')
Widget previewTextFieldVariants() => previewGrid(
  children: [
    const ModernTextField(
      label: 'Email Address',
      hint: 'enter@email.com',
      prefixIcon: Icons.email_outlined,
    ),
    const ModernTextField(
      label: 'Password',
      hint: '••••••••',
      isPassword: true,
      prefixIcon: Icons.lock_outline_rounded,
    ),
    const ModernTextField(
      label: 'Search',
      hint: 'Search for products...',
      prefixIcon: Icons.search_rounded,
    ),
  ],
);

@Preview(name: 'Modern TextField — States', group: 'ModernTextField')
Widget previewTextFieldStates() => previewGrid(
  children: [
    const ModernTextField(
      label: 'Bio',
      hint: 'Tell us about yourself...',
      isMultiline: true,
      minLines: 3,
      maxLines: 5,
    ),
    const ModernTextField(
      label: 'Username',
      hint: 'yunior123',
      maxLength: 20,
      showCounter: true,
    ),
    ModernTextField(
      label: 'Validation Error',
      hint: 'Wrong input',
      validator: (v) => 'This field is required',
    ),
  ],
);

@Preview(name: 'Modern TextField Light — Variants', group: 'ModernTextField')
Widget previewTextFieldVariantsLight() => previewGrid(
  theme: previewLightTheme,
  children: [
    const ModernTextField(
      label: 'Email Address',
      hint: 'enter@email.com',
      prefixIcon: Icons.email_outlined,
    ),
    const ModernTextField(
      label: 'Password',
      hint: '••••••••',
      isPassword: true,
      prefixIcon: Icons.lock_outline_rounded,
    ),
    const ModernTextField(
      label: 'Search',
      hint: 'Search for products...',
      prefixIcon: Icons.search_rounded,
    ),
  ],
);

@Preview(name: 'Modern TextField Light — States', group: 'ModernTextField')
Widget previewTextFieldStatesLight() => previewGrid(
  theme: previewLightTheme,
  children: [
    const ModernTextField(
      label: 'Bio',
      hint: 'Tell us about yourself...',
      isMultiline: true,
      minLines: 3,
      maxLines: 5,
    ),
    const ModernTextField(
      label: 'Username',
      hint: 'yunior123',
      maxLength: 20,
      showCounter: true,
    ),
    ModernTextField(
      label: 'Validation Error',
      hint: 'Wrong input',
      validator: (v) => 'This field is required',
    ),
  ],
);

// ═══ Widget Previews ═══

@Preview(name: 'Email field — dark', group: 'Text Fields')
Widget previewEmailField() => previewWrapper(
  child: ModernTextField(
    label: 'Email Address',
    hint: 'you@example.com',
    keyboardType: TextInputType.emailAddress,
    prefixIcon: Icons.email_outlined,
  ),
);

@Preview(name: 'Password field', group: 'Text Fields')
Widget previewPasswordField() => previewWrapper(
  child: ModernTextField(
    label: 'Password',
    hint: '••••••••',
    isPassword: true,
    prefixIcon: Icons.lock_outlined,
  ),
);

@Preview(name: 'Search field', group: 'Text Fields')
Widget previewSearchField() => previewWrapper(
  child: ModernTextField(
    hint: 'Search products…',
    prefixIcon: Icons.search,
    suffixIcon: Icons.tune_outlined,
  ),
);

@Preview(name: 'Multiline — description', group: 'Text Fields')
Widget previewMultilineField() => previewWrapper(
  child: ModernTextField(
    label: 'Product Description',
    hint: 'Describe your product in detail…',
    isMultiline: true,
    maxLines: 5,
    minLines: 3,
    maxLength: 500,
    showCounter: true,
  ),
);

@Preview(name: 'Price field', group: 'Text Fields')
Widget previewPriceField() => previewWrapper(
  child: ModernTextField(
    label: 'Price (CAD)',
    hint: '0.00',
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    prefixIcon: Icons.attach_money,
  ),
);

@Preview(name: 'All variants', group: 'Text Fields')
Widget previewAllTextFields() => previewGrid(
  children: [
    ModernTextField(
      label: 'Email',
      hint: 'you@example.com',
      prefixIcon: Icons.email_outlined,
    ),
    ModernTextField(
      label: 'Password',
      hint: '••••••••',
      isPassword: true,
      prefixIcon: Icons.lock_outlined,
    ),
    ModernTextField(
      label: 'Price (CAD)',
      hint: '0.00',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      prefixIcon: Icons.attach_money,
    ),
    ModernTextField(
      label: 'Description',
      hint: 'Tell us about your product…',
      isMultiline: true,
      maxLines: 3,
      minLines: 2,
    ),
  ],
);

@Preview(name: 'Light mode', group: 'Text Fields', brightness: Brightness.light)
Widget previewTextFieldLight() => previewWrapper(
  theme: previewLightTheme,
  background: DesignTokens.surface,
  child: ModernTextField(
    label: 'Email Address',
    hint: 'you@example.com',
    prefixIcon: Icons.email_outlined,
  ),
);
