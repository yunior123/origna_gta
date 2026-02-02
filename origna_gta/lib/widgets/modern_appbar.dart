import 'package:flutter/material.dart';

import '../utils/design_tokens.dart';

class BottomNavItem {
  final IconData icon;
  final String label;

  BottomNavItem({required this.icon, required this.label});
}

/// Modern 2100 AppBar with glassmorphism
class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;
  final VoidCallback? onBackPressed;
  final Widget? leadingIcon;
  final bool centerTitle;
  final bool showBackButton;
  final Color? backgroundColor;

  const ModernAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.onBackPressed,
    this.leadingIcon,
    this.centerTitle = true,
    this.showBackButton = true,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200.withOpacity(0.3), width: 0.5)),
      ),
      child: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: centerTitle,
        leading: showBackButton
            ? IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: onBackPressed ?? () => Navigator.pop(context))
            : leadingIcon,
        title: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        actions: actions,
      ),
    );
  }
}

/// Modern 2100 Bottom Navigation Bar with glassmorphism
class ModernBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onIndexChanged;
  final List<BottomNavItem> items;

  const ModernBottomNavBar({super.key, required this.currentIndex, required this.onIndexChanged, required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurface.withOpacity(0.95) : Colors.white.withOpacity(0.95),
        border: Border(top: BorderSide(color: Colors.grey.shade200.withOpacity(0.3), width: 0.5)),
        boxShadow: [BoxShadow(color: DesignTokens.primary.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing8, vertical: DesignTokens.spacing8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              items.length,
              (index) => _NavBarItem(item: items[index], isActive: currentIndex == index, onTap: () => onIndexChanged(index)),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final BottomNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({super.key, required this.item, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DesignTokens.durationNormal,
        padding: EdgeInsets.symmetric(horizontal: isActive ? DesignTokens.spacing16 : DesignTokens.spacing8, vertical: DesignTokens.spacing8),
        decoration: BoxDecoration(gradient: isActive ? DesignTokens.primaryGradient : null, borderRadius: BorderRadius.circular(DesignTokens.radius12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: isActive ? Colors.white : Colors.grey.shade500, size: 20),
            if (isActive) ...[
              const SizedBox(width: DesignTokens.spacing8),
              Text(
                item.label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
