/// Barrel file for backward compatibility
///
/// This file allows existing code to continue working while gradually migrating
/// to the new Freezed models. Import this file to get access to both old and new models.
///
/// Migration path:
/// 1. Import 'package:origna_gta/models/generated/models.dart' (new)
/// 2. Replace ProductModel with Product
/// 3. Replace OrderModel with Order
/// 4. Replace UserModel with User
/// 5. Use copyWith() instead of manual copying
/// 6. Remove imports of old 'package:origna_gta/models/models.dart'
library;

// Keep old models available for backward compatibility during migration
export '../models/models.dart' hide Address, AddressDetails, SellerPayout; // Hide to avoid conflicts
// Export new Freezed models (preferred)
export 'generated/models.dart';

/// Alias old models to new ones for smooth migration
/// Usage: 
/// ```dart
/// // Old code (still works):
/// ProductModel product = ProductModel.fromDocument(doc);
/// 
/// // New code (preferred):
/// Product product = Product.fromFirestore(doc);
/// ```
