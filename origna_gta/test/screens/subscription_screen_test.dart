import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:origna_gta/screens/subscription_screen.dart';
import 'package:origna_gta/utils/utils.dart';

import '../test_utils.dart';

class _TestSubscriptionViewModel extends OrignaBaseSubscriptionViewModel {
  _TestSubscriptionViewModel(super.ref);
}

void main() {
  setUpAll(() {
    initTestMocks();
  });

  testWidgets('builds without error with mocked providers', (tester) async {
    final user = AppAuthUser(uid: 'buyer_123', email: 'buyer@example.com');
    final profile = UserModel(
      uid: 'buyer_123',
      email: 'buyer@example.com',
      name: 'Buyer',
      roles: const [UserRole.buyer],
      createdAt: DateTime(2026, 3, 1),
      notifyNewProducts: true,
      notifyTrending: false,
    );

    await tester.pumpWidget(
      TestWrapper(
        overrides: [
          currentUserProvider.overrideWithValue(user),
          userProfileProvider.overrideWith((ref) => Stream.value(profile)),
          subscriptionStreamProvider.overrideWith(
            (ref) => Stream.value(
              const SubscriptionInfo(status: 'inactive', isPremium: false),
            ),
          ),
          subscriptionViewModelProvider.overrideWith(
            (ref) => _TestSubscriptionViewModel(ref),
          ),
        ],
        child: const SubscriptionScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SubscriptionScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
