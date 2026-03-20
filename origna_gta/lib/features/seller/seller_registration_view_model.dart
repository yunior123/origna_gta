// Migrated: delegates to OrignaBase seller registration viewmodel.
// Screens continue using paymentProviderStatusProvider, sellerRegistrationViewModelProvider.

export 'seller_registration_state.dart';
export 'orignabase_seller_registration_view_model.dart';

import 'orignabase_seller_registration_view_model.dart';

/// Backward-compatible aliases — screens use these names.
final paymentProviderStatusProvider = obPaymentProviderStatusProvider;
final sellerRegistrationViewModelProvider = obSellerRegistrationViewModelProvider;

/// Backward-compatible typedef.
typedef SellerRegistrationViewModel = OrignaBaseSellerRegistrationViewModel;
