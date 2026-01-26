// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter/foundation.dart';
// // curl -X POST
// //  http://127.0.0.1:5001/orignagta/us-central1/create_customer \
// //   -H "Content-Type: application/json" \
// //   -d '{
// //     "email": "test@example.com",
// //     "name": "Test User"
// //   }'
// // {"error": "Error creating customer: Invalid API Key provided: mk_1Stdj***************gbqJ", "success": false}% 
// /// Service class for handling Stripe payments via Firebase Cloud Functions
// class StripeService {
//   //TODO: Replace with your actual Firebase Cloud Functions base URL
//   // Replace with your actual Firebase Cloud Functions base URL
//   static const String _baseUrl = 'https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net';
  
//   // Endpoints
//   static const String _createPaymentIntentEndpoint = '$_baseUrl/create_payment_intent';
//   static const String _createCustomerEndpoint = '$_baseUrl/create_customer';
//   static const String _confirmPaymentEndpoint = '$_baseUrl/confirm_payment';
//   static const String _getPaymentMethodsEndpoint = '$_baseUrl/get_payment_methods';
//   static const String _refundPaymentEndpoint = '$_baseUrl/refund_payment';
//   static const String _healthCheckEndpoint = '$_baseUrl/health_check';

//   /// Create a payment intent
//   /// 
//   /// [amount] - Amount in cents (e.g., 1000 = $10.00)
//   /// [currency] - Currency code (default: 'usd')
//   /// [customerId] - Optional Stripe customer ID
//   /// [description] - Optional payment description
//   /// [metadata] - Optional metadata map
//   /// [receiptEmail] - Optional email for receipt
//   Future<Map<String, dynamic>> createPaymentIntent({
//     required int amount,
//     String currency = 'cad',
//     String? customerId,
//     String? description,
//     Map<String, dynamic>? metadata,
//     String? receiptEmail,
//   }) async {
//     try {
//       final requestBody = {
//         'amount': amount,
//         'currency': currency,
//         if (customerId != null) 'customerId': customerId,
//         if (description != null) 'description': description,
//         if (metadata != null) 'metadata': metadata,
//         if (receiptEmail != null) 'receiptEmail': receiptEmail,
//       };

//       final response = await http.post(
//         Uri.parse(_createPaymentIntentEndpoint),
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: json.encode(requestBody),
//       );

//       return _handleResponse(response);
//     } catch (e) {
//       debugPrint('Error creating payment intent: $e');
//       rethrow;
//     }
//   }

//   /// Create a Stripe customer
//   /// 
//   /// [email] - Customer email (required)
//   /// [name] - Customer name
//   /// [phone] - Customer phone
//   /// [userId] - Firebase user ID
//   /// [metadata] - Optional metadata
//   Future<Map<String, dynamic>> createCustomer({
//     required String email,
//     String? name,
//     String? phone,
//     String? userId,
//     Map<String, dynamic>? metadata,
//   }) async {
//     try {
//       final requestBody = {
//         'email': email,
//         if (name != null) 'name': name,
//         if (phone != null) 'phone': phone,
//         if (userId != null) 'userId': userId,
//         if (metadata != null) 'metadata': metadata,
//       };

//       final response = await http.post(
//         Uri.parse(_createCustomerEndpoint),
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: json.encode(requestBody),
//       );

//       return _handleResponse(response);
//     } catch (e) {
//       debugPrint('Error creating customer: $e');
//       rethrow;
//     }
//   }

//   /// Confirm and retrieve payment status
//   /// 
//   /// [paymentIntentId] - The payment intent ID to confirm
//   Future<Map<String, dynamic>> confirmPayment({
//     required String paymentIntentId,
//   }) async {
//     try {
//       final requestBody = {
//         'paymentIntentId': paymentIntentId,
//       };

//       final response = await http.post(
//         Uri.parse(_confirmPaymentEndpoint),
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: json.encode(requestBody),
//       );

//       return _handleResponse(response);
//     } catch (e) {
//       debugPrint('Error confirming payment: $e');
//       rethrow;
//     }
//   }

//   /// Get all payment methods for a customer
//   /// 
//   /// [customerId] - Stripe customer ID
//   Future<Map<String, dynamic>> getPaymentMethods({
//     required String customerId,
//   }) async {
//     try {
//       final requestBody = {
//         'customerId': customerId,
//       };

//       final response = await http.post(
//         Uri.parse(_getPaymentMethodsEndpoint),
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: json.encode(requestBody),
//       );

//       return _handleResponse(response);
//     } catch (e) {
//       debugPrint('Error getting payment methods: $e');
//       rethrow;
//     }
//   }

//   /// Refund a payment
//   /// 
//   /// [paymentIntentId] - Payment intent ID to refund
//   /// [amount] - Optional partial refund amount in cents
//   /// [reason] - Refund reason (duplicate, fraudulent, requested_by_customer)
//   Future<Map<String, dynamic>> refundPayment({
//     required String paymentIntentId,
//     int? amount,
//     String reason = 'requested_by_customer',
//   }) async {
//     try {
//       final requestBody = {
//         'paymentIntentId': paymentIntentId,
//         if (amount != null) 'amount': amount,
//         'reason': reason,
//       };

//       final response = await http.post(
//         Uri.parse(_refundPaymentEndpoint),
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: json.encode(requestBody),
//       );

//       return _handleResponse(response);
//     } catch (e) {
//       debugPrint('Error refunding payment: $e');
//       rethrow;
//     }
//   }

//   /// Health check to verify service is running
//   Future<Map<String, dynamic>> healthCheck() async {
//     try {
//       final response = await http.get(
//         Uri.parse(_healthCheckEndpoint),
//         headers: {
//           'Content-Type': 'application/json',
//         },
//       );

//       return _handleResponse(response);
//     } catch (e) {
//       debugPrint('Error checking health: $e');
//       rethrow;
//     }
//   }

//   /// Handle HTTP response and parse JSON
//   Map<String, dynamic> _handleResponse(http.Response response) {
//     final data = json.decode(response.body) as Map<String, dynamic>;

//     if (response.statusCode >= 200 && response.statusCode < 300) {
//       return data;
//     } else {
//       throw StripeException(
//         message: data['error'] ?? 'Unknown error occurred',
//         statusCode: response.statusCode,
//       );
//     }
//   }
// }

// /// Custom exception for Stripe-related errors
// class StripeException implements Exception {
//   final String message;
//   final int statusCode;

//   StripeException({
//     required this.message,
//     required this.statusCode,
//   });

//   @override
//   String toString() => 'StripeException: $message (Status: $statusCode)';
// }


// /// Models for payment data

// class PaymentIntent {
//   final String id;
//   final String clientSecret;
//   final int amount;
//   final String currency;
//   final String status;
//   final String? description;

//   PaymentIntent({
//     required this.id,
//     required this.clientSecret,
//     required this.amount,
//     required this.currency,
//     required this.status,
//     this.description,
//   });

//   factory PaymentIntent.fromJson(Map<String, dynamic> json) {
//     return PaymentIntent(
//       id: json['paymentIntentId'] as String,
//       clientSecret: json['clientSecret'] as String,
//       amount: json['amount'] as int,
//       currency: json['currency'] as String,
//       status: json['status'] as String,
//       description: json['description'] as String?,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'paymentIntentId': id,
//       'clientSecret': clientSecret,
//       'amount': amount,
//       'currency': currency,
//       'status': status,
//       'description': description,
//     };
//   }
// }

// class StripeCustomer {
//   final String id;
//   final String email;
//   final String? name;
//   final String? phone;
//   final bool alreadyExists;

//   StripeCustomer({
//     required this.id,
//     required this.email,
//     this.name,
//     this.phone,
//     this.alreadyExists = false,
//   });

//   factory StripeCustomer.fromJson(Map<String, dynamic> json) {
//     return StripeCustomer(
//       id: json['customerId'] as String,
//       email: json['email'] as String,
//       name: json['name'] as String?,
//       phone: json['phone'] as String?,
//       alreadyExists: json['alreadyExists'] as bool? ?? false,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'customerId': id,
//       'email': email,
//       'name': name,
//       'phone': phone,
//       'alreadyExists': alreadyExists,
//     };
//   }
// }

// class PaymentMethod {
//   final String id;
//   final String brand;
//   final String last4;
//   final int expMonth;
//   final int expYear;

//   PaymentMethod({
//     required this.id,
//     required this.brand,
//     required this.last4,
//     required this.expMonth,
//     required this.expYear,
//   });

//   factory PaymentMethod.fromJson(Map<String, dynamic> json) {
//     return PaymentMethod(
//       id: json['id'] as String,
//       brand: json['brand'] as String,
//       last4: json['last4'] as String,
//       expMonth: json['expMonth'] as int,
//       expYear: json['expYear'] as int,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'brand': brand,
//       'last4': last4,
//       'expMonth': expMonth,
//       'expYear': expYear,
//     };
//   }

//   String get displayText => '$brand •••• $last4 (${expMonth.toString().padLeft(2, '0')}/$expYear)';
// }

// class RefundResult {
//   final String refundId;
//   final int amount;
//   final String status;
//   final String paymentIntentId;

//   RefundResult({
//     required this.refundId,
//     required this.amount,
//     required this.status,
//     required this.paymentIntentId,
//   });

//   factory RefundResult.fromJson(Map<String, dynamic> json) {
//     return RefundResult(
//       refundId: json['refundId'] as String,
//       amount: json['amount'] as int,
//       status: json['status'] as String,
//       paymentIntentId: json['paymentIntentId'] as String,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'refundId': refundId,
//       'amount': amount,
//       'status': status,
//       'paymentIntentId': paymentIntentId,
//     };
//   }
// }

// class PaymentStatus {
//   final String status;
//   final int amount;
//   final String currency;
//   final String paymentIntentId;
//   final String? receiptUrl;
//   final String? description;

//   PaymentStatus({
//     required this.status,
//     required this.amount,
//     required this.currency,
//     required this.paymentIntentId,
//     this.receiptUrl,
//     this.description,
//   });

//   factory PaymentStatus.fromJson(Map<String, dynamic> json) {
//     return PaymentStatus(
//       status: json['status'] as String,
//       amount: json['amount'] as int,
//       currency: json['currency'] as String,
//       paymentIntentId: json['paymentIntentId'] as String,
//       receiptUrl: json['receiptUrl'] as String?,
//       description: json['description'] as String?,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'status': status,
//       'amount': amount,
//       'currency': currency,
//       'paymentIntentId': paymentIntentId,
//       'receiptUrl': receiptUrl,
//       'description': description,
//     };
//   }

//   bool get isSucceeded => status == 'succeeded';
//   bool get isFailed => status == 'failed';
//   bool get isPending => status == 'processing' || status == 'requires_action';
// }

// /// Helper class for currency formatting
// class CurrencyFormatter {
//   static String format(int amountInCents, String currency) {
//     final amount = amountInCents / 100;
//     final symbol = _getCurrencySymbol(currency);
//     return '$symbol${amount.toStringAsFixed(2)}';
//   }

//   static String _getCurrencySymbol(String currency) {
//     switch (currency.toUpperCase()) {
//       case 'USD':
//         return '\$';
//       case 'EUR':
//         return '€';
//       case 'GBP':
//         return '£';
//       case 'JPY':
//         return '¥';
//       case 'CAD':
//         return 'CA\$';
//       case 'AUD':
//         return 'A\$';
//       default:
//         return currency.toUpperCase();
//     }
//   }
// }