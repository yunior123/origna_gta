import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/models/generated/base_models.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

/// Gate widget that requires user to have admin role before showing child.
/// Must be placed inside [AuthRequiredGate] to guarantee user is authenticated.
class AdminRequiredGate extends ConsumerWidget {
  final Widget child;

  const AdminRequiredGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileRoles = ref.watch(
      userProfileProvider.select((a) => a.valueOrNull?.roles),
    );

    if (profileRoles == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: DesignTokens.backgroundGradient(isDark: isDark),
        ),
        child: const Scaffold(
          backgroundColor: DesignTokens.transparent,
          body: Center(child: ModernLoadingIndicator()),
        ),
      );
    }

    if (!profileRoles.contains(UserRole.admin)) {
      return Container(
        decoration: BoxDecoration(
          gradient: DesignTokens.backgroundGradient(isDark: isDark),
        ),
        child: Scaffold(
          appBar: AppBarFactory.simple(title: 'admin.access_denied'.tr()),
          backgroundColor: DesignTokens.transparent,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: FadeSlideIn(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: DesignTokens.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 56,
                        color: DesignTokens.error,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacing20),
                    Text(
                      'admin.privileges_required'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ModernButton(
                      label: 'seller.go_home'.tr(),
                      icon: Icons.home_outlined,
                      isPrimary: false,
                      isOutlined: true,
                      onPressed: () =>
                          appPushNamedAndRemoveUntil(context,
                            AppRoutes.home,
                            (route) => false,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return child;
  }
}

@Preview(
  name: 'Admin Gate — Loading',
  group: 'AdminRequiredGate',
  size: Size(390, 844),
)
Widget previewAdminGateLoading() => previewWrapper(
  child: previewScope(
    child: const AdminRequiredGate(child: Text('Admin Content')),
  ),
  breakpoint: PreviewBreakpoint.mobile,
);

@Preview(
  name: 'Admin Gate — Access Denied',
  group: 'AdminRequiredGate',
  size: Size(390, 844),
)
Widget previewAdminGateDenied() => previewWrapper(
  child: previewScope(
    child: const AdminRequiredGate(child: Text('Admin Content')),
  ),
  breakpoint: PreviewBreakpoint.mobile,
);

@Preview(
  name: 'Admin Gate — Desktop',
  group: 'AdminRequiredGate',
  size: Size(1280, 800),
)
Widget previewAdminGateDesktop() => previewWrapper(
  child: previewScope(
    child: const AdminRequiredGate(child: Text('Admin Content')),
  ),
  breakpoint: PreviewBreakpoint.desktop,
);

@Preview(
  name: 'Admin Gate — Light',
  group: 'AdminRequiredGate',
  brightness: Brightness.light,
  size: Size(390, 844),
)
Widget previewAdminGateLight() => previewWrapper(
  theme: previewLightTheme,
  background: DesignTokens.surface,
  child: previewScope(
    child: const AdminRequiredGate(child: Text('Admin Content')),
  ),
  breakpoint: PreviewBreakpoint.mobile,
);
