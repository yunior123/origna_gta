import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/shared/cart_badge.dart';
import 'package:flutter/widget_previews.dart';

/// Factory methods for common AppBar configurations
class AppBarFactory {
  /// AppBar with custom leading widget
  static CustomAppBar custom({
    required String title,
    String? subtitle,
    Widget? leading,
    List<Widget>? actions,
    bool showCartBadge = false,
  }) {
    return CustomAppBar(
      title: title,
      subtitle: subtitle,
      leading: leading,
      actions: actions,
      showBackButton: false,
      showCartBadge: showCartBadge,
    );
  }

  /// AppBar without back button (for main screens)
  static CustomAppBar main({
    required String title,
    List<Widget>? actions,
    bool showCartBadge = false,
  }) {
    return CustomAppBar(
      title: title,
      actions: actions,
      showBackButton: false,
      showCartBadge: showCartBadge,
    );
  }

  /// Simple AppBar with just title and back button
  static CustomAppBar simple({
    required String title,
    String? subtitle,
    VoidCallback? onBackPressed,
  }) {
    return CustomAppBar(
      title: title,
      subtitle: subtitle,
      onBackPressed: onBackPressed,
    );
  }

  /// AppBar with cart badge
  static CustomAppBar withCart({
    required String title,
    List<Widget>? actions,
    VoidCallback? onBackPressed,
  }) {
    return CustomAppBar(
      title: title,
      actions: actions,
      showCartBadge: true,
      onBackPressed: onBackPressed,
    );
  }
}

/// Styled icon button for use in CustomAppBar actions
class AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String
  tooltip; // WCAG 4.1.2: Required — every IconButton needs a tooltip

  const AppBarIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'btn-${tooltip.toLowerCase().replaceAll(' ', '-')}',
      child: IconButton(
        icon: Icon(icon, color: DesignTokens.white),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}

/// Reusable custom AppBar with gradient background.
/// Provides consistent styling across the app.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final bool showCartBadge;
  final VoidCallback? onBackPressed;
  final double height;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.showCartBadge = false,
    this.onBackPressed,
    this.height = 60,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            DesignTokens.gradientStart,
            DesignTokens.gradientMiddle,
            DesignTokens.gradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.gradientStart.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              // Leading widget or back button
              if (leading != null)
                leading!
              else if (showBackButton)
                _buildIconButton(
                  icon: Icons.arrow_back,
                  tooltip: 'common.back'.tr(),
                  onPressed:
                      onBackPressed ??
                      () => appPopOrGo(context, AppRoutes.home),
                ),

              // Title (+ optional subtitle)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: subtitle != null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: DesignTokens.white,
                                fontSize: 17,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                color: DesignTokens.white.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 12,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        )
                      : Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: DesignTokens.white,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ),

              // Actions
              if (actions != null) ...actions!,

              // Cart badge (optional)
              if (showCartBadge) const CartBadge.appBar(),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Semantics(
      button: true,
      label: 'btn-${tooltip?.toLowerCase().replaceAll(' ', '-') ?? 'action'}',
      child: IconButton(
        icon: Icon(icon, color: DesignTokens.white),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}

// === Widget Previews ===

// ═══ Widget Previews ═══

// ─── Standard app bar (title + back button via custom leading) ────────────────
// Note: showBackButton triggers easy_localization .tr() for the tooltip.
// We supply a custom leading icon to stay locale-independent in previews.

@Preview(name: 'Standard — back button', group: 'AppBar')
Widget previewAppBarStandard() => previewWrapper(
  padding: EdgeInsets.zero,
  child: SizedBox(
    height: 80,
    child: CustomAppBar(
      title: 'Product Details',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: DesignTokens.white),
        onPressed: () {},
        tooltip: 'Back',
      ),
      showBackButton: false,
    ),
  ),
);

// ─── App bar with subtitle ────────────────────────────────────────────────────

@Preview(name: 'With subtitle', group: 'AppBar')
Widget previewAppBarWithSubtitle() => previewWrapper(
  padding: EdgeInsets.zero,
  child: SizedBox(
    height: 80,
    child: CustomAppBar(
      title: 'Order #ORD-4821',
      subtitle: 'Placed on March 3, 2026',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: DesignTokens.white),
        onPressed: () {},
        tooltip: 'Back',
      ),
      showBackButton: false,
    ),
  ),
);

// ─── App bar with actions (search + notification) ─────────────────────────────

@Preview(name: 'With actions', group: 'AppBar')
Widget previewAppBarWithActions() => previewWrapper(
  padding: EdgeInsets.zero,
  child: SizedBox(
    height: 80,
    child: CustomAppBar(
      title: 'Marketplace',
      showBackButton: false,
      actions: [
        AppBarIconButton(
          icon: Icons.search,
          onPressed: () {},
          tooltip: 'Search',
        ),
        AppBarIconButton(
          icon: Icons.notifications_outlined,
          onPressed: () {},
          tooltip: 'Notifications',
        ),
      ],
    ),
  ),
);

// ─── Main screen app bar (no back button, no leading) ─────────────────────────

@Preview(name: 'Main screen — no back', group: 'AppBar')
Widget previewAppBarMain() => previewWrapper(
  padding: EdgeInsets.zero,
  child: SizedBox(
    height: 80,
    child: AppBarFactory.main(
      title: 'Home',
      actions: [
        AppBarIconButton(
          icon: Icons.search,
          onPressed: () {},
          tooltip: 'Search',
        ),
      ],
    ),
  ),
);

// ─── Light theme variant ──────────────────────────────────────────────────────

@Preview(name: 'Light theme', group: 'AppBar', brightness: Brightness.light)
Widget previewAppBarLight() => previewWrapper(
  theme: previewLightTheme,
  background: DesignTokens.surface,
  padding: EdgeInsets.zero,
  child: SizedBox(
    height: 80,
    child: CustomAppBar(
      title: 'Settings',
      subtitle: 'Account preferences',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: DesignTokens.white),
        onPressed: () {},
        tooltip: 'Back',
      ),
      showBackButton: false,
    ),
  ),
);

// ─── All variants stacked ─────────────────────────────────────────────────────

@Preview(name: 'All variants', group: 'AppBar')
Widget previewAppBarAllVariants() => previewGrid(
  children: [
    SizedBox(
      height: 80,
      child: CustomAppBar(
        title: 'Product Details',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignTokens.white),
          onPressed: () {},
          tooltip: 'Back',
        ),
        showBackButton: false,
      ),
    ),
    SizedBox(
      height: 80,
      child: CustomAppBar(
        title: 'Order #ORD-4821',
        subtitle: 'Placed on March 3, 2026',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignTokens.white),
          onPressed: () {},
          tooltip: 'Back',
        ),
        showBackButton: false,
      ),
    ),
    SizedBox(
      height: 80,
      child: AppBarFactory.main(
        title: 'Marketplace',
        actions: [
          AppBarIconButton(
            icon: Icons.search,
            onPressed: () {},
            tooltip: 'Search',
          ),
          AppBarIconButton(
            icon: Icons.notifications_outlined,
            onPressed: () {},
            tooltip: 'Notifications',
          ),
        ],
      ),
    ),
  ],
);

// ═══ Widget Previews ═══

@Preview(name: 'Custom AppBar — Cart Scenarios', group: 'CustomAppBar')
Widget previewAppBarCart() => previewGrid(
  children: [
    previewScope(
      extraOverrides: [cartItemCountProvider.overrideWith((ref) => 0)],
      child: AppBarFactory.withCart(title: 'Empty Cart'),
    ),
    previewScope(
      extraOverrides: [cartItemCountProvider.overrideWith((ref) => 105)],
      child: AppBarFactory.withCart(title: 'Full Cart'),
    ),
  ],
);

@Preview(name: 'Custom AppBar — Variants', group: 'CustomAppBar')
Widget previewAppBarVariants() => previewScope(
  extraOverrides: [
    cartItemCountProvider.overrideWith((ref) => 3),
    currentUserProvider.overrideWith((ref) => null), // Not logged in
  ],
  child: previewGrid(
    children: [
      AppBarFactory.main(title: 'OrignaGTA', showCartBadge: true),
      AppBarFactory.simple(title: 'Settings', subtitle: 'Manage your account'),
      AppBarFactory.custom(
        title: 'Search Results',
        leading: const Icon(Icons.search, color: DesignTokens.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
            tooltip: 'Filter',
          ),
        ],
      ),
    ],
  ),
);

@Preview(name: 'Custom AppBar Light — Cart Scenarios', group: 'CustomAppBar')
Widget previewAppBarCartLight() => previewGrid(
  theme: previewLightTheme,
  children: [
    previewScope(
      extraOverrides: [cartItemCountProvider.overrideWith((ref) => 0)],
      child: AppBarFactory.withCart(title: 'Empty Cart'),
    ),
    previewScope(
      extraOverrides: [cartItemCountProvider.overrideWith((ref) => 105)],
      child: AppBarFactory.withCart(title: 'Full Cart'),
    ),
  ],
);

@Preview(name: 'Custom AppBar Light — Variants', group: 'CustomAppBar')
Widget previewAppBarVariantsLight() => previewScope(
  extraOverrides: [
    cartItemCountProvider.overrideWith((ref) => 3),
    currentUserProvider.overrideWith((ref) => null),
  ],
  child: previewGrid(
    theme: previewLightTheme,
    children: [
      AppBarFactory.main(title: 'OrignaGTA', showCartBadge: true),
      AppBarFactory.simple(title: 'Settings', subtitle: 'Manage your account'),
      AppBarFactory.custom(
        title: 'Search Results',
        leading: const Icon(Icons.search, color: DesignTokens.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
            tooltip: 'Filter',
          ),
        ],
      ),
    ],
  ),
);
