import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

class AddressManagementScreen extends ConsumerWidget {
  const AddressManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: DesignTokens.backgroundGradient(isDark: isDark),
      ),
      child: Scaffold(
        appBar: AppBarFactory.simple(title: 'profile.addresses'.tr()),
        backgroundColor: Colors.transparent,
        body: userProfileAsync.when(
          loading: () => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => DesignTokens.primaryGradient.createShader(bounds),
                  child: const ModernLoadingIndicator(strokeWidth: 3, color: Colors.white, centered: false),
                ),
                const SizedBox(height: 16),
                Text('address.loading'.tr(), style: TextStyle(color: DesignTokens.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          error: (error, stack) => AnimatedEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'address.error_loading'.tr(),
            subtitle: '$error',
          ),
          data: (userModel) {
            if (userModel == null) {
              return AnimatedEmptyState(
                icon: Icons.lock_outline_rounded,
                title: 'address.sign_in_to_view'.tr(),
                subtitle: 'address.saved_appear_here'.tr(),
              );
            }

            final address = userModel.address;

            if (address == null) {
              return AnimatedEmptyState(
                icon: Icons.location_off_outlined,
                title: 'address.no_address'.tr(),
                subtitle: 'address.add_to_speed_up'.tr(),
                action: SizedBox(
                  width: 220,
                  child: Semantics(
                    button: true,
                    label: 'btn-add-address',
                    child: ModernButton(
                    label: 'address.add_address'.tr(),
                    icon: Icons.add_location_alt_outlined,
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.addEditAddress);
                    },
                  ),
                  ),
                ),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  padding: const EdgeInsets.all(DesignTokens.spacing20),
                  children: [
                    FadeSlideIn(child: _buildAddressCard(context, address, isDark)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, dynamic address, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing20),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurfaceVariant.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radius20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : DesignTokens.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(color: DesignTokens.primary.withValues(alpha: isDark ? 0.15 : 0.08), blurRadius: 20, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (address.label != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [DesignTokens.primary.withValues(alpha: 0.15), DesignTokens.secondary.withValues(alpha: 0.15)],
                    ),
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        address.label == 'Home' ? Icons.home_outlined : address.label == 'Work' ? Icons.business_outlined : Icons.location_on_outlined,
                        size: 14,
                        color: DesignTokens.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(address.label!, style: const TextStyle(color: DesignTokens.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                )
              else
                const SizedBox.shrink(),
              Semantics(
                button: true,
                label: 'btn-edit-address',
                child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(context, AppRoutes.addEditAddress, arguments: address);
                  },
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                  splashColor: DesignTokens.primary.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined, size: 16, color: DesignTokens.primary),
                        const SizedBox(width: 6),
                        Text('common.edit'.tr(), style: TextStyle(color: DesignTokens.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.spacing16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : DesignTokens.surfaceVariant,
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, size: 20, color: DesignTokens.primary.withValues(alpha: 0.7)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(address.formattedAddress, style: TextStyle(fontSize: 14, height: 1.6, color: DesignTokens.textSecondary)),
                ),
              ],
            ),
          ),
          if (address.phoneNumber != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DesignTokens.spacing12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : DesignTokens.surfaceVariant,
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone_outlined, size: 18, color: DesignTokens.primary.withValues(alpha: 0.7)),
                  const SizedBox(width: 12),
                  Text(address.phoneNumber!, style: TextStyle(fontSize: 14, color: DesignTokens.textSecondary, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
