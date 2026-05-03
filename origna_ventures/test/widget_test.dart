import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:origna_ventures/main.dart';
import 'package:origna_ventures/tiers_config.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  required Size size,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(const OrignaVenturesApp());
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  tearDown(() {
    venturesHttpClient = null;
    venturesUrlLauncher = null;
  });

  test('Ventures API base points to the live OrignaVentures backend', () {
    expect(venturesApiBase, 'https://api.orignaventures.ca/api');
  });

  test('tier catalog contains the 3 expected service codes', () {
    final codes = TierDefinition.tiers.map((t) => t.serviceCode).toList();
    expect(codes, ['origna_code', 'origna_launch', 'origna_team']);
  });

  test('launch tier remains the popular plan at 3000 CAD one-time', () {
    final tier = TierDefinition.byId(TierId.orignaLaunch);
    expect(tier.isPopular, isTrue);
    expect(tier.priceCents, 300000);
    expect(tier.isSubscription, isFalse);
    expect(tier.displayPrice(), '3,000');
  });

  test('team tier remains subscription at 1000 CAD monthly', () {
    final tier = TierDefinition.byId(TierId.orignaTeam);
    expect(tier.isSubscription, isTrue);
    expect(tier.priceCents, 100000);
    expect(tier.displayPrice(), '1,000');
  });

  test('code tier remains source-code starter plan at 500 CAD', () {
    final tier = TierDefinition.byServiceCode('origna_code');
    expect(tier.tierId, TierId.orignaCode);
    expect(tier.priceCents, 50000);
    expect(tier.displayPrice(), '500');
  });

  testWidgets('desktop landing page renders upgraded hero and pricing copy', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpApp(tester, size: const Size(1440, 1600));

    expect(find.text('Origna Ventures'), findsWidgets);
    expect(find.text('Stripe'), findsWidgets);
    expect(find.text('OrignaCode'), findsWidgets);
    expect(find.text('OrignaLaunch'), findsWidgets);
    expect(find.text('OrignaTeam'), findsWidgets);
  });

  testWidgets('mobile landing page keeps proof panel visible', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpApp(tester, size: const Size(393, 1400));

    expect(find.text('Origna Ventures'), findsWidgets);
    expect(find.text('Hetzner'), findsWidgets);
    expect(find.text('OrignaLaunch'), findsWidgets);
  });

  testWidgets('desktop locale toggle updates pricing nav label',
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpApp(tester, size: const Size(1440, 1200));

    await tester.tap(find.text('FR'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Tarifs'), findsOneWidget);

    await tester.tap(find.text('ES'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Precios'), findsOneWidget);
  });

  testWidgets('desktop footer exposes Ventures support email', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpApp(tester, size: const Size(1440, 1100));

    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('support@orignaventures.ca'), findsWidgets);
  });

  testWidgets('mobile View plans CTA scrolls to pricing section',
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpApp(tester, size: const Size(393, 844));

    expect(find.text('Choose the operating model'), findsNothing);
    await tester.tap(find.text('View plans'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Choose the operating model'), findsOneWidget);
    expect(find.text('OrignaLaunch'), findsWidgets);
  });

  testWidgets('desktop pricing section keeps pricing metadata visible',
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpApp(tester, size: const Size(1440, 1600));

    expect(find.text('\$500'), findsOneWidget);
    expect(find.text('\$3,000'), findsOneWidget);
    expect(find.text('\$1,000'), findsOneWidget);
  });

  testWidgets('pricing cards explain post-payment DocuSeal signing',
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpApp(tester, size: const Size(1440, 1600));

    expect(
      find.text('DocuSeal agreements are sent after Stripe checkout.'),
      findsNWidgets(3),
    );
  });

  testWidgets('team tier supports adjusting developer count up to priced total',
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpApp(tester, size: const Size(1440, 1600));

    expect(find.text('Team size'), findsOneWidget);
    expect(find.textContaining('1 developer'), findsOneWidget);

    await tester.tap(find.byTooltip('Increase team size').first);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('2 developers'), findsOneWidget);
    expect(find.text('\$2,000'), findsOneWidget);
  });

  testWidgets('tier buy buttons post the expected checkout service codes', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final capturedBodies = <Map<String, dynamic>>[];
    final launchedUris = <Uri>[];

    venturesHttpClient = MockClient((request) async {
      expect(
        request.url.toString(),
        'https://api.orignaventures.ca/api/payments/create-checkout-session',
      );
      capturedBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
      return http.Response(
        jsonEncode({
          'checkoutUrl':
              'https://checkout.stripe.test/session-${capturedBodies.length}',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    venturesUrlLauncher = (
      uri, {
      mode = LaunchMode.platformDefault,
      webOnlyWindowName,
    }) async {
      launchedUris.add(uri);
      return true;
    };

    await _pumpApp(tester, size: const Size(1440, 3600));

    await tester
        .ensureVisible(find.bySemanticsLabel('btn-tier-buy-origna_code'));
    await tester.tap(find.bySemanticsLabel('btn-tier-buy-origna_code'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(
      find.bySemanticsLabel('btn-tier-buy-origna_launch'),
    );
    await tester.tap(find.bySemanticsLabel('btn-tier-buy-origna_launch'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.byTooltip('Increase team size').first);
    await tester.tap(find.byTooltip('Increase team size').first);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byTooltip('Increase team size').first);
    await tester.pump(const Duration(milliseconds: 100));
    await tester
        .ensureVisible(find.bySemanticsLabel('btn-tier-buy-origna_team'));
    await tester.tap(find.bySemanticsLabel('btn-tier-buy-origna_team'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(capturedBodies, hasLength(3));
    expect(launchedUris, hasLength(3));
    expect(
      launchedUris.map((uri) => uri.toString()).toList(),
      [
        'https://checkout.stripe.test/session-1',
        'https://checkout.stripe.test/session-2',
        'https://checkout.stripe.test/session-3',
      ],
    );

    expect(capturedBodies[0]['service_code'], 'origna_code');
    expect(capturedBodies[0]['developer_count'], 1);
    expect(capturedBodies[0]['payment_provider'], 'stripe');
    expect(capturedBodies[0]['locale'], 'en');

    expect(capturedBodies[1]['service_code'], 'origna_launch');
    expect(capturedBodies[1]['developer_count'], 1);
    expect(capturedBodies[1]['payment_provider'], 'stripe');
    expect(capturedBodies[1]['locale'], 'en');

    expect(capturedBodies[2]['service_code'], 'origna_team');
    expect(capturedBodies[2]['developer_count'], 3);
    expect(capturedBodies[2]['payment_provider'], 'stripe');
    expect(capturedBodies[2]['locale'], 'en');
  });

  testWidgets('mobile renders WhatsApp floating button', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpApp(tester, size: const Size(393, 844));

    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Chat with us'), findsOneWidget);
  });
}
