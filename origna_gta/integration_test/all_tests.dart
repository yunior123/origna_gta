// Single entry point — ONE build, ALL integration tests.
//
// Run on physical iPhone:
//   flutter test integration_test/all_tests.dart \
//     -d 00008120-000174923ADB401E \
//     --dart-define=ENVIRONMENT=emulator
//
// Requires Firebase emulators running.

import 'app_test.dart' as app;
import 'critical_flows_test.dart' as critical_flows;
import 'human_workflows_test.dart' as human_workflows;
import 'checkout_critical_test.dart' as checkout_critical;
import 'checkout_flow_test.dart' as checkout_flow;
import 'complete_workflows_test.dart' as complete_workflows;
import 'database_reactivity_test.dart' as database_reactivity;
import 'full_e2e_test.dart' as full_e2e;
import 'marketplace_flows_test.dart' as marketplace_flows;
import 'payment_e2e_test.dart' as payment_e2e;
import 'product_creation_test.dart' as product_creation;
import 'shipping_product_e2e_test.dart' as shipping_product;

import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Core
  app.main();
  critical_flows.main();
  human_workflows.main();

  // Checkout & payment
  checkout_critical.main();
  checkout_flow.main();
  payment_e2e.main();

  // Full flows
  complete_workflows.main();
  full_e2e.main();
  marketplace_flows.main();

  // Product & shipping
  product_creation.main();
  shipping_product.main();

  // Data layer
  database_reactivity.main();
}
