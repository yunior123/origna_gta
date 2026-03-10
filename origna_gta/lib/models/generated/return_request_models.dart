import 'package:freezed_annotation/freezed_annotation.dart';

part 'return_request_models.freezed.dart';
part 'return_request_models.g.dart';

/// Safely parse a dynamic value (String, DateTime, int) to DateTime?
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

@Freezed(toJson: true, fromJson: true)
abstract class ReturnRequest with _$ReturnRequest {
  const factory ReturnRequest({
    required String returnId,
    required String orderId,
    required String orderItemId,
    required String buyerId,
    required String sellerId,
    required String productId,
    required String productName,
    @Default(1) int quantity,
    @Default('requested') String returnStatus,
    required String returnReason,
    String? returnAdminNote,
    String? returnTrackingNumber,
    int? returnRefundAmountCents,
    DateTime? requestedAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    DateTime? escalatedAt,
    String? escalationReason,
  }) = _ReturnRequest;

  factory ReturnRequest.fromJson(Map<String, dynamic> json) =>
      _$ReturnRequestFromJson(json);

  factory ReturnRequest.fromMap(Map<String, dynamic> data, String docId) {
    return ReturnRequest(
      returnId: docId,
      orderId: data['orderId'] as String? ?? '',
      // Backend writes 'cartItemId' (Fields.CART_ITEM_ID); fall back to 'orderItemId' for compat
      orderItemId: (data['cartItemId'] ?? data['orderItemId']) as String? ?? '',
      buyerId: data['buyerId'] as String? ?? '',
      sellerId: data['sellerId'] as String? ?? '',
      productId: data['productId'] as String? ?? '',
      productName: data['productName'] as String? ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      returnStatus: data['returnStatus'] as String? ?? 'requested',
      returnReason: data['returnReason'] as String? ?? '',
      returnAdminNote: data['returnAdminNote'] as String?,
      returnTrackingNumber: data['returnTrackingNumber'] as String?,
      returnRefundAmountCents:
          (data['returnRefundAmountCents'] as num?)?.toInt(),
      requestedAt: _parseDateTime(data['requestedAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      resolvedAt: _parseDateTime(data['resolvedAt']),
      escalatedAt: _parseDateTime(data['escalatedAt']),
      escalationReason: data['escalationReason'] as String?,
    );
  }
}
