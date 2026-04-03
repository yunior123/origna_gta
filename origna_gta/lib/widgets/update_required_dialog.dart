import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class UpdateRequiredDialog extends StatelessWidget {
  final String minVersion;

  const UpdateRequiredDialog({super.key, required this.minVersion});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Non-dismissible
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
    // TODO: Replace with real App Store / Play Store IDs when published (see APP_UPDATE_MECHANISM.md)
    final url = Platform.isIOS
        ? 'https://apps.apple.com/app/orignagta/id000000000'
        : 'https://play.google.com/store/apps/details?id=ca.orignagta.app';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
