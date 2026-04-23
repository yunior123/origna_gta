import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';

/// Generic error screen
class ErrorScreen extends StatelessWidget {
  final String message;

  const ErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: DesignTokens.backgroundGradient(isDark: isDark),
      ),
      child: Scaffold(
        appBar: AppBarFactory.simple(title: 'errors.error_title'.tr()),
        backgroundColor: DesignTokens.transparent,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.spacing24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeSlideIn(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            DesignTokens.error.withValues(alpha: 0.15),
                            DesignTokens.error.withValues(alpha: 0.08),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: DesignTokens.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 50),
                    child: Text(
                      'errors.generic_error'.tr(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? DesignTokens.white
                            : DesignTokens.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: DesignTokens.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 150),
                    child: ModernButton(
                      label: 'seller.go_home'.tr(),
                      icon: Icons.home_outlined,
                      onPressed: () =>
                          appPushNamedAndRemoveUntil(context,
                            AppRoutes.home,
                            (route) => false,
                          ),
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
}

@Preview(name: 'Error — Mobile', group: 'ErrorScreen', size: Size(390, 844))
Widget previewErrorMobile() => previewWrapper(
  child: const ErrorScreen(message: 'Something went wrong. Please try again.'),
  breakpoint: PreviewBreakpoint.mobile,
);

@Preview(name: 'Error — Desktop', group: 'ErrorScreen', size: Size(1280, 800))
Widget previewErrorDesktop() => previewWrapper(
  child: const ErrorScreen(message: 'Something went wrong. Please try again.'),
  breakpoint: PreviewBreakpoint.desktop,
);

@Preview(
  name: 'Error — Light Desktop',
  group: 'ErrorScreen',
  brightness: Brightness.light,
  size: Size(1280, 800),
)
Widget previewErrorLightDesktop() => previewWrapper(
  theme: previewLightTheme,
  background: DesignTokens.surface,
  child: const ErrorScreen(message: 'Something went wrong. Please try again.'),
  breakpoint: PreviewBreakpoint.desktop,
);

@Preview(name: 'Error — Network', group: 'ErrorScreen', size: Size(390, 844))
Widget previewErrorNetwork() => previewWrapper(
  child: const ErrorScreen(
    message: 'Unable to connect to the server. Check your internet connection.',
  ),
  breakpoint: PreviewBreakpoint.mobile,
);

@Preview(name: 'Error — Not Found', group: 'ErrorScreen', size: Size(390, 844))
Widget previewErrorNotFound() => previewWrapper(
  child: const ErrorScreen(
    message: 'The page you are looking for does not exist.',
  ),
  breakpoint: PreviewBreakpoint.mobile,
);
