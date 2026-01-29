import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/cart_screen.dart';
import 'package:origna_gta/utils.dart';

/// Reusable custom AppBar with gradient background.
/// Provides consistent styling across the app.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final bool showCartBadge;
  final VoidCallback? onBackPressed;
  final double height;

  const CustomAppBar({
    super.key,
    required this.title,
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
                  onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                ),

              // Title
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
              if (showCartBadge) _buildCartBadgeStream(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartBadgeStream(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildIconButton(
        icon: Icons.shopping_cart_outlined,
        onPressed: () => showLoginPrompt(context),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .snapshots(),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) {
          count = snapshot.data!.docs.fold(
            0,
            (total, doc) => total + ((doc.data() as Map<String, dynamic>)['quantity'] as int? ?? 0),
          );
        }
        return _buildCartBadge(context, count);
      },
    );
  }

  Widget _buildCartBadge(BuildContext context, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildIconButton(
          icon: Icons.shopping_cart_outlined,
          onPressed: () {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) {
              showLoginPrompt(context);
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          },
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Color(0xFFFF6B35),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  static Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: onPressed,
    );
  }
}

/// Factory methods for common AppBar configurations
class AppBarFactory {
  /// Simple AppBar with just title and back button
  static CustomAppBar simple({
    required String title,
    VoidCallback? onBackPressed,
  }) {
    return CustomAppBar(
      title: title,
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

  /// AppBar with custom leading widget
  static CustomAppBar custom({
    required String title,
    Widget? leading,
    List<Widget>? actions,
    bool showCartBadge = false,
  }) {
    return CustomAppBar(
      title: title,
      leading: leading,
      actions: actions,
      showBackButton: false,
      showCartBadge: showCartBadge,
    );
  }
}

/// Styled icon button for use in CustomAppBar actions
class AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const AppBarIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
}
