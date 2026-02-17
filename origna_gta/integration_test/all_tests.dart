import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'flows/smoke_home_profile_test.dart' as smoke;
import 'flows/add_product_flow_test.dart' as add_product;
import 'flows/buyer_flow_test.dart' as buyer;
import 'flows/seller_flow_test.dart' as seller;
import 'flows/admin_flow_test.dart' as admin;

/// G00 — All Integration Flows
///
/// Aggregator that runs all 5 flow test suites:
/// - Smoke (Home + Profile)
/// - Add Product (Product creation flows)
/// - Buyer (Browse, cart, checkout)
/// - Seller (Seller tools, seller orders)
/// - Admin (Admin panel, privileged menu)
///
/// Run individually:
/// ```bash
/// flutter drive --target=integration_test/flows/smoke_home_profile_test.dart
/// flutter drive --target=integration_test/flows/add_product_flow_test.dart
/// flutter drive --target=integration_test/flows/buyer_flow_test.dart
/// flutter drive --target=integration_test/flows/seller_flow_test.dart
/// flutter drive --target=integration_test/flows/admin_flow_test.dart
/// ```
///
/// Run all:
/// ```bash
/// flutter drive --target=integration_test/all_tests.dart
/// ```
/// 
/// ## Flutter integration tests (web)
// ```bash
// # 1) Start ChromeDriver in a separate terminal
// chromedriver --port=4444

// # 2) Run the integration suite (no emulators)
// cd origna_gta
// flutter drive --driver=test_driver/integration_test.dart \
//   --target=integration_test/all_tests.dart \
//   -d chrome \
//   --dart-define=ENVIRONMENT=dev \
//   --dart-define=USE_EMULATORS=false
// ```

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('G00 — All Integration Flows', () {
    // smoke.main();
    add_product.main();
    // buyer.main();
    // seller.main();
    // admin.main();
  });
}
