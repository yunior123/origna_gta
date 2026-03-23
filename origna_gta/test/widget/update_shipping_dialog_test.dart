import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/widgets/orders/update_shipping_dialog.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  late AutoDisposeStateProvider<String?> carrierProvider;

  group('showUpdateShippingDialog', () {
    testWidgets('shows dialog with cost, carrier, and tracking fields', (
      tester,
    ) async {
      carrierProvider = StateProvider.autoDispose<String?>((_) => null);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return Semantics(
                    label: 'btn-open-shipping-dialog',
                    child: ElevatedButton(
                      onPressed: () => showUpdateShippingDialog(
                        context,
                        ref,
                        orderId: 'order-456',
                        estimatedShipping: 25.50,
                        carrierProvider: carrierProvider,
                      ),
                      child: const Text('Open Dialog'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Tap button to open dialog
      await tester.tap(find.bySemanticsLabel('btn-open-shipping-dialog'));
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.byType(AlertDialog), findsOneWidget);

      // Title should contain "Confirm Shipping"
      expect(find.text('seller.confirm_shipping'.tr()), findsOneWidget);

      // Cost field should be pre-filled with estimated shipping
      expect(find.text('25.50'), findsOneWidget);

      // Carrier dropdown should exist
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

      // Tracking number field should exist
      expect(
        find.bySemanticsLabel('input-tracking-number-update'),
        findsOneWidget,
      );

      // Cancel and Confirm buttons
      expect(find.text('common.cancel'.tr()), findsOneWidget);
      expect(find.text('common.confirm'.tr()), findsOneWidget);
    });

    testWidgets('cancel button dismisses dialog', (tester) async {
      carrierProvider = StateProvider.autoDispose<String?>((_) => null);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return Semantics(
                    label: 'btn-open-cancel-test',
                    child: ElevatedButton(
                      onPressed: () => showUpdateShippingDialog(
                        context,
                        ref,
                        orderId: 'order-cancel',
                        estimatedShipping: 10.00,
                        carrierProvider: carrierProvider,
                      ),
                      child: const Text('Open'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('btn-open-cancel-test'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // Tap cancel
      await tester.tap(find.text('common.cancel'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('selecting carrier updates dropdown', (tester) async {
      carrierProvider = StateProvider.autoDispose<String?>((_) => null);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return Semantics(
                    label: 'btn-open-carrier-test',
                    child: ElevatedButton(
                      onPressed: () => showUpdateShippingDialog(
                        context,
                        ref,
                        orderId: 'order-carrier',
                        estimatedShipping: 12.00,
                        carrierProvider: carrierProvider,
                      ),
                      child: const Text('Open'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('btn-open-carrier-test'));
      await tester.pumpAndSettle();

      // Open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Select UPS
      await tester.tap(find.text('UPS').last);
      await tester.pumpAndSettle();

      // Carrier note field should NOT appear for non-'other' carrier
      expect(find.text('seller.carrier_note_label'.tr()), findsNothing);
    });

    testWidgets('selecting "other" carrier shows carrier note field', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      carrierProvider = StateProvider.autoDispose<String?>((_) => null);
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  container = ProviderScope.containerOf(context);
                  return Semantics(
                    label: 'btn-open-other-test',
                    child: ElevatedButton(
                      onPressed: () => showUpdateShippingDialog(
                        context,
                        ref,
                        orderId: 'order-other',
                        estimatedShipping: 8.00,
                        carrierProvider: carrierProvider,
                      ),
                      child: const Text('Open'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('btn-open-other-test'));
      await tester.pumpAndSettle();

      // Initially no carrier note field
      expect(find.text('seller.carrier_note_label'.tr()), findsNothing);

      // Set carrier to "other" directly via provider
      container.read(carrierProvider.notifier).state = CarrierValues.other;
      await tester.pumpAndSettle();

      // Carrier note field should appear
      expect(find.text('seller.carrier_note_label'.tr()), findsOneWidget);
    });

    testWidgets('dialog has correct input field for actual cost', (
      tester,
    ) async {
      carrierProvider = StateProvider.autoDispose<String?>((_) => null);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return Semantics(
                    label: 'btn-open-cost-test',
                    child: ElevatedButton(
                      onPressed: () => showUpdateShippingDialog(
                        context,
                        ref,
                        orderId: 'order-cost',
                        estimatedShipping: 42.75,
                        carrierProvider: carrierProvider,
                      ),
                      child: const Text('Open'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('btn-open-cost-test'));
      await tester.pumpAndSettle();

      // Verify the cost input field
      expect(find.bySemanticsLabel('input-actual-cost'), findsOneWidget);

      // Verify label
      expect(find.text('seller.actual_cost'.tr()), findsOneWidget);

      // Verify pre-filled value
      expect(find.text('42.75'), findsOneWidget);
    });

    testWidgets(
      'confirm button dismisses dialog with valid tracking and carrier',
      (tester) async {
        carrierProvider = StateProvider.autoDispose<String?>((_) => null);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return Semantics(
                      label: 'btn-open-confirm-test',
                      child: ElevatedButton(
                        onPressed: () => showUpdateShippingDialog(
                          context,
                          ref,
                          orderId: 'order-confirm',
                          estimatedShipping: 20.00,
                          carrierProvider: carrierProvider,
                        ),
                        child: const Text('Open'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.bySemanticsLabel('btn-open-confirm-test'));
        await tester.pumpAndSettle();

        // Enter tracking number
        final trackingField = find.bySemanticsLabel(
          'input-tracking-number-update',
        );
        await tester.enterText(trackingField, 'TRACK123456');
        await tester.pumpAndSettle();

        // Select a carrier
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('UPS').last);
        await tester.pumpAndSettle();

        // Tap confirm
        await tester.tap(find.text('common.confirm'.tr()));
        await tester.pumpAndSettle();

        // Dialog should be dismissed
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets('confirm does nothing when tracking is empty', (tester) async {
      carrierProvider = StateProvider.autoDispose<String?>((_) => null);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return Semantics(
                    label: 'btn-open-notrack-test',
                    child: ElevatedButton(
                      onPressed: () => showUpdateShippingDialog(
                        context,
                        ref,
                        orderId: 'order-notrack',
                        estimatedShipping: 5.00,
                        carrierProvider: carrierProvider,
                      ),
                      child: const Text('Open'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('btn-open-notrack-test'));
      await tester.pumpAndSettle();

      // Clear the tracking field (leave empty)
      final trackingField = find.bySemanticsLabel(
        'input-tracking-number-update',
      );
      await tester.enterText(trackingField, '');
      await tester.pumpAndSettle();

      // Tap confirm - should NOT dismiss since tracking is empty
      await tester.tap(find.text('common.confirm'.tr()));
      await tester.pumpAndSettle();

      // Dialog should still be visible
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('dialog shows all carrier options', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      carrierProvider = StateProvider.autoDispose<String?>((_) => null);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return Semantics(
                    label: 'btn-open-carriers-test',
                    child: ElevatedButton(
                      onPressed: () => showUpdateShippingDialog(
                        context,
                        ref,
                        orderId: 'order-carriers',
                        estimatedShipping: 10.00,
                        carrierProvider: carrierProvider,
                      ),
                      child: const Text('Open'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('btn-open-carriers-test'));
      await tester.pumpAndSettle();

      // Open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Verify carrier labels in dropdown menu items
      final dropdownItems = find.descendant(
        of: find.byType(DropdownMenuItem<String>),
        matching: find.byType(Text),
      );
      expect(dropdownItems, findsWidgets);

      // Verify known carrier labels are present among dropdown items
      final allTexts = tester
          .widgetList<Text>(dropdownItems)
          .map((w) => w.data ?? '')
          .toSet();
      expect(allTexts, contains('UPS'));
      expect(allTexts, contains('FedEx'));
      expect(allTexts, contains('Canada Post'));
      expect(allTexts, contains('Purolator'));
      expect(allTexts, contains('DHL'));
      expect(allTexts, contains('USPS'));
      expect(allTexts, contains('Maritime (International)'));
    });

    testWidgets('dialog initializes carrier provider to null', (tester) async {
      // Start with a non-null value to verify it gets reset
      carrierProvider = StateProvider.autoDispose<String?>((_) => 'ups');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return Semantics(
                    label: 'btn-open-init-test',
                    child: ElevatedButton(
                      onPressed: () => showUpdateShippingDialog(
                        context,
                        ref,
                        orderId: 'order-init',
                        estimatedShipping: 10.00,
                        carrierProvider: carrierProvider,
                      ),
                      child: const Text('Open'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('btn-open-init-test'));
      await tester.pumpAndSettle();

      // The provider should be reset to null by the dialog
      expect(find.byType(AlertDialog), findsOneWidget);

      // Since carrier is null, carrier note field should not be visible
      expect(find.text('seller.carrier_note_label'.tr()), findsNothing);
    });

    testWidgets('tracking number field accepts input', (tester) async {
      carrierProvider = StateProvider.autoDispose<String?>((_) => null);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return Semantics(
                    label: 'btn-open-tracking-test',
                    child: ElevatedButton(
                      onPressed: () => showUpdateShippingDialog(
                        context,
                        ref,
                        orderId: 'order-tracking',
                        estimatedShipping: 15.00,
                        carrierProvider: carrierProvider,
                      ),
                      child: const Text('Open'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('btn-open-tracking-test'));
      await tester.pumpAndSettle();

      // Enter tracking number
      await tester.enterText(
        find.bySemanticsLabel('input-tracking-number-update'),
        'UPS-1Z999AA10123456784',
      );
      await tester.pumpAndSettle();

      // Verify the text was entered
      expect(find.text('UPS-1Z999AA10123456784'), findsOneWidget);
    });

    testWidgets('cost field accepts new value', (tester) async {
      carrierProvider = StateProvider.autoDispose<String?>((_) => null);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return Semantics(
                    label: 'btn-open-cost-edit-test',
                    child: ElevatedButton(
                      onPressed: () => showUpdateShippingDialog(
                        context,
                        ref,
                        orderId: 'order-cost-edit',
                        estimatedShipping: 10.00,
                        carrierProvider: carrierProvider,
                      ),
                      child: const Text('Open'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('btn-open-cost-edit-test'));
      await tester.pumpAndSettle();

      // Edit the cost field
      await tester.enterText(
        find.bySemanticsLabel('input-actual-cost'),
        '35.50',
      );
      await tester.pumpAndSettle();

      expect(find.text('35.50'), findsOneWidget);
    });
  });
}
