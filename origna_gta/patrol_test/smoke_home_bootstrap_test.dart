import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/main_test.dart' as app;
import 'package:patrol/patrol.dart';

import '../integration_test/helpers/test_helpers.dart';

void main() {
  patrolTest('boots the app and exposes stable home anchors', ($) async {
    await app.mainTest();
    await $.pumpAndSettle();

    final bootstrapped = await waitForAppBootstrap(
      $.tester,
      timeoutSeconds: 60,
    );

    expect(
      bootstrapped,
      isTrue,
      reason: 'Expected the app to reach a stable post-bootstrap surface.',
    );
    expect(find.byType(MaterialApp), findsWidgets);
    expect(find.byType(Scaffold), findsWidgets);

    final hasSettingsButton = find
        .byKey(const Key('home_settings_button'))
        .evaluate()
        .isNotEmpty;
    final hasCartButton = find
        .byKey(const Key('home_cart_button'))
        .evaluate()
        .isNotEmpty;

    expect(
      hasSettingsButton || hasCartButton,
      isTrue,
      reason: 'Expected at least one stable home action anchor after launch.',
    );
  });
}
