import 'package:flutter/material.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';

/// The gradient profile header card with avatar, name, email, and role badge.
///
/// Requires [profileCompletionBar] to be passed as a widget since
/// `_ProfileCompletionBar` is defined in the profile_screen part file.
class ProfileHeaderCard extends StatelessWidget {
  final UserModel userModel;
  final bool isDark;
  final bool isPremium;
  final Widget profileCompletionBar;

  const ProfileHeaderCard({
    super.key,
    required this.userModel,
    required this.isDark,
    required this.isPremium,
    required this.profileCompletionBar,
  });

  @override
  Widget build(BuildContext context) {
    final initials = userModel.name.isNotEmpty
        ? userModel.name[0].toUpperCase()
        : 'U';
    final isSeller =
        userModel.roles.contains(UserRole.seller) ||
        userModel.roles.contains(UserRole.admin);
    final isAdmin = userModel.roles.contains(UserRole.admin);

    final headerPadding = ResponsiveBreakpoints.getSpacing(
      context,
      SpacingSize.xl,
    );
    final avatarSize = ResponsiveBreakpoints.getValue<double>(
      context: context,
      mobile: 76.0,
      mobilePlus: 86.0,
      tablet: 96.0,
      desktop: 106.0,
    );
    final fontSize = ResponsiveBreakpoints.getValue<double>(
      context: context,
      mobile: 32.0,
      mobilePlus: 36.0,
      tablet: 40.0,
      desktop: 44.0,
    );

    return Container(
      clipBehavior: Clip.antiAlias,
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
        borderRadius: BorderRadius.circular(DesignTokens.radius20),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.primary.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: DesignTokens.secondary.withValues(alpha: 0.2),
            blurRadius: 44,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative blob -- top right (cyan)
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DesignTokens.accent.withValues(alpha: 0.28),
                    DesignTokens.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Decorative blob -- bottom left (coral)
          Positioned(
            bottom: -15,
            left: -15,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DesignTokens.tertiary.withValues(alpha: 0.22),
                    DesignTokens.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main content
          Padding(
            padding: EdgeInsets.all(headerPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(avatarSize, fontSize, initials),
                const SizedBox(height: 18),
                Text(
                  userModel.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: DesignTokens.white,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  userModel.email,
                  style: TextStyle(
                    fontSize: 13,
                    color: DesignTokens.white.withValues(alpha: 0.72),
                    letterSpacing: 0.1,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isAdmin || isSeller) ...[
                  const SizedBox(height: 14),
                  _buildRoleBadge(isAdmin),
                ],
                const SizedBox(height: 18),
                profileCompletionBar,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(double avatarSize, double fontSize, String initials) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Outermost pulse ring
        Container(
          width: avatarSize + 32,
          height: avatarSize + 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPremium
                ? DesignTokens.warning.withValues(alpha: 0.1)
                : DesignTokens.white.withValues(alpha: 0.06),
          ),
        ),
        // Middle ring
        Container(
          width: avatarSize + 16,
          height: avatarSize + 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DesignTokens.white.withValues(alpha: 0.1),
            border: Border.all(
              color: isPremium
                  ? DesignTokens.warning.withValues(alpha: 0.5)
                  : DesignTokens.white.withValues(alpha: 0.18),
              width: isPremium ? 1.5 : 1,
            ),
          ),
        ),
        // Inner avatar circle
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                DesignTokens.white.withValues(alpha: 0.3),
                DesignTokens.white.withValues(alpha: 0.14),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: DesignTokens.white.withValues(alpha: 0.5),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.black.withValues(alpha: 0.3),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
              if (isPremium)
                BoxShadow(
                  color: DesignTokens.warning.withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                fontSize: fontSize,
                color: DesignTokens.white,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
              ),
            ),
          ),
        ),
        // Premium crown badge
        if (isPremium)
          Positioned(
            right: (avatarSize + 32) / 2 - avatarSize / 2 - 2,
            bottom: (avatarSize + 32) / 2 - avatarSize / 2 - 2,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [DesignTokens.warning, DesignTokens.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: DesignTokens.warning.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(color: DesignTokens.white, width: 2),
              ),
              child: const Center(
                child: Icon(
                  Icons.workspace_premium,
                  size: 14,
                  color: DesignTokens.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRoleBadge(bool isAdmin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: DesignTokens.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DesignTokens.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin
                ? Icons.admin_panel_settings_rounded
                : Icons.storefront_rounded,
            color: DesignTokens.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            isAdmin ? 'Admin' : 'Seller',
            style: const TextStyle(
              color: DesignTokens.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
