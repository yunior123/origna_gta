import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/utils/design_tokens.dart';

/// A styled premium/subscription menu item for the profile screen.
class PremiumMenuItem extends StatelessWidget {
  final bool isPremium;

  const PremiumMenuItem({super.key, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.primary.withValues(alpha: isPremium ? 0.1 : 0.06),
            DesignTokens.secondary.withValues(alpha: isPremium ? 0.1 : 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: DesignTokens.primary.withValues(alpha: isPremium ? 0.3 : 0.15),
          width: isPremium ? 1.5 : 1,
        ),
      ),
      child: Semantics(
        button: true,
        label: 'menu-premium',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(context, AppRoutes.subscription);
          },
          behavior: HitTestBehavior.opaque,
          child: Semantics(
            container: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [DesignTokens.primary, DesignTokens.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(DesignTokens.radius8),
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      color: DesignTokens.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'subscription.premium_label'.tr(),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? DesignTokens.textOnDark
                                    : DesignTokens.textPrimary,
                              ),
                            ),
                            if (isPremium)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: DesignTokens.success.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'subscription.status_active'.tr(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: DesignTokens.success,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPremium
                              ? 'subscription.menu_manage_desc'.tr()
                              : 'subscription.menu_upgrade_desc'.tr(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: DesignTokens.textDisabled,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
