import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class UpdateRequiredDialog extends StatelessWidget {
  final String minVersion;

  const UpdateRequiredDialog({super.key, required this.minVersion});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: DesignTokens.darkCard,
        title: Text(
          'app.update_required_title'.tr(),
          style: TextStyle(color: DesignTokens.textPrimary),
        ),
        content: Text(
          'app.update_required_message'.tr(args: [minVersion]),
          style: TextStyle(color: DesignTokens.textSecondary),
        ),
        actions: [
          Semantics(
            label: 'btn-update-app',
            button: true,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primary,
              ),
              onPressed: _openStore,
              child: Text('app.update_now'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  void _openStore() {
    final url = Platform.isIOS
        ? 'https://apps.apple.com/app/orignagta/id000000000'
        : 'https://play.google.com/store/apps/details?id=ca.orignagta.app';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

@Preview(
  name: 'Update Dialog — Mobile',
  group: 'UpdateRequiredDialog',
  size: Size(390, 844),
)
Widget previewUpdateDialogMobile() => previewWrapper(
  child: const UpdateRequiredDialog(minVersion: '1.2.0'),
  breakpoint: PreviewBreakpoint.mobile,
);

@Preview(
  name: 'Update Dialog — Light',
  group: 'UpdateRequiredDialog',
  brightness: Brightness.light,
  size: Size(390, 844),
)
Widget previewUpdateDialogLight() => previewWrapper(
  theme: previewLightTheme,
  background: DesignTokens.surface,
  child: const UpdateRequiredDialog(minVersion: '1.2.0'),
  breakpoint: PreviewBreakpoint.mobile,
);
