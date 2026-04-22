import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_ventures/main.dart';
import 'package:origna_ventures/tiers_config.dart';

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

  testWidgets('mobile View plans CTA scrolls to pricing section', (tester) async {
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
}
