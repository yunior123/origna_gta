// Test driver for Flutter integration tests
// Used with: flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d chrome

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
