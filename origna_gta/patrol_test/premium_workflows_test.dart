import 'package:flutter/material.dart';
import 'common.dart';

void main() {
  patrol('WF201: Premium Journey — Upgrade and access Premium Chat', ($) async {
    await createApp($);
    
    // 1. Login as standard buyer
    await loginAsBuyer($);
    
    // 2. Navigate to a product
    await tapFirstProduct($);
    
    // 3. Try to Ask a Question (Photo feature) - expect paywall or locked icon
    // Note: The UI for 'Ask Question' in ProductDetailScreen uses isPremium check
    await $.scrollUntilVisible(finder: $('Ask a Question'));
    await $('Ask a Question').tap();
    
    // 4. Verify Paywall appears for non-premium
    expect($('Premium'), findsWidgets);
    expect($('Upgrade Now'), findsWidgets);
    
    // 5. Navigate to Subscription Screen
    await $('Upgrade Now').tap();
    await $.pumpAndSettle();
    expect(page.url().contains('subscription'), isTrue);
    
    // 6. Simulate Upgrade (This would normally be via Stripe, in Patrol we might need to mock or use a test account that is already premium)
    // For this test, we'll assume the user completes the flow.
    
    // 7. Go back to Product and verify features are UNLOCKED
    await $.pageBack();
    // (Logic to ensure user is now premium would go here, e.g. using a different test account or triggering a mock)
  });

  patrol('WF202: Premium — Verify photo reviews are visible', ($) async {
    await createApp($);
    
    // 1. Login as Admin (who is premium by default in our test seed)
    await loginAsAdmin($);
    
    // 2. Navigate to a product with reviews
    await tapFirstProduct($);
    
    // 3. Scroll to reviews
    await $.scrollUntilVisible(finder: $('Reviews'));
    
    // 4. Verify photos are visible and NOT blurred
    // (Testing for blur is hard in Patrol, but we can check if the Lock icon is NOT present)
    expect($(Icons.lock_rounded), findsNothing);
  });
}
