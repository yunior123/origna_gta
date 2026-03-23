import 'package:freezed_annotation/freezed_annotation.dart';

part 'seller_orders_state.freezed.dart';

@freezed
abstract class SellerOrdersState with _$SellerOrdersState {
  const factory SellerOrdersState({
    @Default(false) bool isLoading,
    String? errorMessage,
    @Default(false) bool isSuccess,
  }) = _SellerOrdersState;
}
