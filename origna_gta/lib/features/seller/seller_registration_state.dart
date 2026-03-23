// seller_registration_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

part 'seller_registration_state.freezed.dart';

@freezed
abstract class SellerRegistrationState with _$SellerRegistrationState {
  const factory SellerRegistrationState({
    @Default(false) bool isLoading,
    String? error,
    String? successMessage,
    @Default(PaymentProviderValues.stripe) String paymentProvider,
  }) = _SellerRegistrationState;
}
