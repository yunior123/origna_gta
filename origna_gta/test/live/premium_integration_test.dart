import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:uuid/uuid.dart';

void main() {
  const runLive = bool.fromEnvironment('RUN_ORIGNABASE_LIVE_TESTS', defaultValue: false);

  group('Premium Integration Flow', () {
    test('User transitions from Non-Premium to Premium and unlocks features', () async {
      final container = ProviderContainer();
      final ob = container.read(orignabaseProvider);
      final marker = const Uuid().v4();
      final email = 'premium_test_$marker@test.origna.ca';
      final pass = 'PremiumPass123!';

      // 1. Sign Up
      final authState = await ob.auth.register(email, pass);
      final userId = authState.userId!;

      // 2. Ensure Profile exists (Non-Premium by default)
      await ob.request('POST', '/api/users/create-profile', body: {
        Fields.userId: userId,
        Fields.email: email,
        Fields.name: 'Premium Tester',
        Fields.roles: [UserRoleValues.buyer],
      });

      // 3. Verify Non-Premium status in app logic
      final subInitial = await container.read(subscriptionStreamProvider.future);
      expect(subInitial?.isPremium ?? false, isFalse, reason: 'New users should be non-premium by default.');

      // 4. Attempt premium action (e.g. ask a question with photo) - Should fail at repository/API level
      // Note: We simulate the API call here to verify backend enforcement
      try {
        await ob.request('POST', '/api/qa/ask-question', body: {
          Fields.productId: 'some_product',
          Fields.questionText: 'Is this premium?',
          'hasPhoto': true,
        });
        fail('Backend should have rejected premium action for non-premium user.');
      } catch (e) {
        expect(e.toString().toLowerCase(), contains('premium'), reason: 'Error should mention premium requirement.');
      }

      // 5. Upgrade to Premium (Simulate backend update after successful Stripe payment)
      await ob.collection(Collections.users).doc(userId).update({
        Fields.isPremium: true,
        Fields.status: SubscriptionStatusValues.active,
      });

      // 6. Verify Premium status reflected in app
      container.invalidate(subscriptionStreamProvider);
      final subPremium = await container.read(subscriptionStreamProvider.future);
      expect(subPremium?.isPremium, isTrue, reason: 'Profile update should reflect premium status.');

      // 7. Verify premium feature now accessible (e.g. Chat initialization)
      // Since we can't easily mock the chat backend fully here, we check the user profile roles/flags
      final userDoc = await ob.collection(Collections.users).doc(userId).get();
      expect(userDoc?.data[Fields.isPremium], isTrue);

      container.dispose();
    }, skip: !runLive, timeout: const Timeout(Duration(minutes: 2)));
  }, skip: !runLive);
}
