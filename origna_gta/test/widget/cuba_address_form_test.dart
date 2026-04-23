import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/screens/editaddress_screen.dart';

import '../test_utils.dart';

void main() {
  setUpAll(initTestMocks);

  testWidgets('Cuba address flow shows maritime notice and Cuba validators', (
    WidgetTester tester,
  ) async {
    final cubaAddress = Address(
      street: '123 Malecon',
      city: 'Havana',
      state: 'HAB',
      postalCode: '10100',
      country: 'Cuba',
      phoneNumber: '+5355512345',
      latitude: 23.1136,
      longitude: -82.3666,
    );

    await tester.pumpWidget(
      TestWrapper(
        overrides: [],
        child: AddEditAddressScreen(address: cubaAddress),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Shipping to Cuba is via maritime freight (21-45 business days). Weight-based rates apply.',
      ),
      findsOneWidget,
    );
    expect(find.text('Cuban postal code (5 digits)'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('address_postal_code_field')),
      '1234',
    );
    await tester.enterText(
      find.byKey(const Key('address_phone_field')),
      '+53123',
    );
    await tester.ensureVisible(find.byKey(const Key('btn_save_address')));
    await tester.tap(find.byKey(const Key('btn_save_address')));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter a valid Cuban postal code (5 digits)'),
      findsOneWidget,
    );
    expect(
      find.text('Enter a valid Cuban phone number (+53 prefix)'),
      findsOneWidget,
    );
  });
}
