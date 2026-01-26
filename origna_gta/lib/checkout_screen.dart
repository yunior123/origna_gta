import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/editaddress_screen.dart';
import 'package:origna_gta/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItemDetailModel> items;
  final double total;

  const CheckoutScreen({super.key, required this.items, required this.total});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: StreamBuilder<DocumentSnapshot>(
            stream: user != null ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots() : null,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>?;
              final Address? savedAddress = userData?['address'] != null ? Address.fromMap(userData!['address'] as Map<String, dynamic>) : null;
              final userModel = UserModel.fromMap(userData ?? {});
              if (savedAddress == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off_outlined, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text('No delivery address found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(
                          'Please add a delivery address before checkout',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditAddressScreen()));
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Address'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final taxRate = getTaxRate(savedAddress.state);
              final tax = widget.total * taxRate;
              final totalWithTax = widget.total + tax;

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          const Text("Shipping Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFF6B35), width: 2),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (savedAddress.label != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(color: const Color(0xFFFF6B35), borderRadius: BorderRadius.circular(12)),
                                        child: Text(
                                          savedAddress.label!,
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AddEditAddressScreen(address: savedAddress.formattedAddress.isEmpty ? null : savedAddress),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      label: const Text('Edit'),
                                      style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF6B35)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(savedAddress.formattedAddress, style: const TextStyle(fontSize: 14, height: 1.5)),
                                if (savedAddress.phoneNumber != null) ...[
                                  const SizedBox(height: 8),
                                  Row(children: [const Icon(Icons.phone_outlined, size: 16), const SizedBox(width: 8), Text(savedAddress.phoneNumber!)]),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text('Order Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Column(
                              children: [
                                ...widget.items.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text('${item.name} x${item.quantity}', style: const TextStyle(fontSize: 14))),
                                        Text('\$${(item.price * item.quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Subtotal', style: TextStyle(fontSize: 16)),
                                    Text('\$${widget.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                ..._buildTaxBreakdown(savedAddress.state, widget.total),
                                const SizedBox(height: 8),
                                StreamBuilder<DocumentSnapshot>(
                                  // Listen to the user's document for real-time address updates
                                  stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
                                    }

                                    // Extract address from the stream
                                    final userData = snapshot.data?.data() as Map<String, dynamic>?;
                                    final addressMap = userData?['address'] as Map<String, dynamic>?;
                                    final buyerAddress = addressMap != null ? Address.fromMap(addressMap) : null;

                                    // Use a secondary FutureBuilder or a separate method to handle the calculation
                                    // only when the buyerAddress is actually available.
                                    if (buyerAddress == null) {
                                      return const Text('Select an address', style: TextStyle(color: Colors.red));
                                    }

                                    return StreamBuilder<double>(
                                      stream: Stream.fromFuture(calculateShippingCost(widget.items, buyerAddress)),
                                      builder: (context, AsyncSnapshot<double> costSnapshot) {
                                        final isCalculating = costSnapshot.connectionState == ConnectionState.waiting;
                                        final shippingCost = costSnapshot.data ?? 0.0;

                                        // if error
                                        if (costSnapshot.hasError) {
                                          return const Text('Error calculating shipping', style: TextStyle(color: Colors.red));
                                        }

                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Shipping', style: TextStyle(color: Colors.grey)),
                                            isCalculating
                                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                                : Text('\$${shippingCost.toStringAsFixed(2)} CAD', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),

                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    Text(
                                      '\$${totalWithTax.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFF6B35)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : () => _startStripeCheckout(widget.items, savedAddress, userModel),

                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
                        child: _isProcessing
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('Place Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildSecurityInfo(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _redirectToStripe(String url) async {
    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not redirect to Stripe');
    }
  }

  Future<void> _startStripeCheckout(List<CartItemDetailModel> items, Address address, UserModel userModel) async {
    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // 1️⃣ Calculate totals (same as before)
      final taxRate = getTaxRate(address.state);
      final tax = widget.total * taxRate;
      final shippingCost = await calculateShippingCost(items, address);
      final totalWithTax = widget.total + tax + shippingCost;
      final sellerIds = items.map((i) => i.sellerId).toList().toSet().toList();

      // 2️⃣ Call Firebase Function
      final callable = FirebaseFunctions.instance.httpsCallable('create_checkout_session');
      final taxes = calculateDetailedTaxes(address, widget.total);
      final order = OrderModel(
        orderId: user.uid,
        userId: userModel.uid,
        sellerIds: sellerIds,
        items: widget.items,
        total: totalWithTax,
        status: 'pending',
        deliveryInfo: address.toMap(),
        createdAt: DateTime.now(),
        customerId: '',
        customerEmail: userModel.email,
        taxes: taxes,
        shippingCost: shippingCost,
        subtotal: widget.total,
        currency: 'cad',
        amount: (totalWithTax * 100).toInt(), // cents,
      );
      final response = await callable.call(order.toMap());

      final checkoutUrl = response.data['url'];

      // 3️⃣ Redirect to Stripe Checkout (WEB)
      if (kIsWeb) {
        await _redirectToStripe(checkoutUrl);
      } else {
        throw Exception('Stripe Checkout redirect is web-only');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checkout error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Secure payment powered by Stripe. Your card information is encrypted.', style: TextStyle(color: Colors.blue.shade700, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTaxBreakdown(String province, double subtotal) {
    final taxes = taxConfig[province] ?? {'HST': 0.13};
    List<Widget> widgets = [];

    taxes.forEach((taxName, rate) {
      final taxAmount = subtotal * rate;
      widgets.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$taxName (${(rate * 100).toStringAsFixed(2)}%)', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            Text('\$${taxAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      );
      widgets.add(const SizedBox(height: 4));
    });

    return widgets;
  }
}



  // Future<void> _stripeCheckOut()async {
  //   final response = await createCheckoutSession();
  // }

  // Future<void> _processOrder1(List<CartItemDetailModel> itmes, Address address, UserModel userModel) async {
  //   setState(() => _isProcessing = true);

  //   try {
  //     final user = FirebaseAuth.instance.currentUser;
  //     if (user == null) throw Exception('User not logged in');

  //     // Steps 1: Calculate tax
  //     final taxRate = getTaxRate(address.state);
  //     final tax = widget.total * taxRate;
  //     // Step 2: Calculate shipping cost
  //     final shippingCost = await calculateShippingCost(itmes, address);
  //     // Step 3: Calculate total with tax and shipping
  //     final totalWithTax = widget.total + tax + shippingCost;

  //     // Step 1: Create or get customer
  //     String? customerId = userModel.customerId;
  //     if (customerId == null) {
  //       final customerResponse = await _stripeService.createCustomer(email: userModel.email, name: userModel.name);
  //       customerId = customerResponse['customerId'] as String?;
  //     }

  //     // Step 2: Update user with customerId in Firestore
  //     FirebaseFirestore.instance.collection('users').doc(user.uid).update({'customerId': customerId});

  //     // Step 3: Create Payment Intent
  //     final amountInCents = (totalWithTax * 100).toInt();
  //     final metadata = {'userId': user.uid, 'orderDescription': 'Order for ${userModel.name}, total: \$${totalWithTax.toStringAsFixed(2)}'};
  //     final description = 'Order Payment - ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}';
  //     final paymentIntentResponse = await _stripeService.createPaymentIntent(
  //       amount: amountInCents,
  //       currency: 'cad',
  //       customerId: customerId,
  //       description: description,
  //       metadata: metadata,
  //       receiptEmail: userModel.email,
  //     );

  //     final clientSecret = paymentIntentResponse['clientSecret'] as String;
  //     final paymentIntentId = paymentIntentResponse['paymentIntentId'] as String;
  //     // await Stripe.instance.initPaymentSheet(
  //     //   paymentSheetParameters: SetupPaymentSheetParameters(
  //     //     paymentIntentClientSecret: clientSecret, // Replace with real secret from backend
  //     //     merchantDisplayName: 'Origna GTA',
  //     //     style: ThemeMode.light,
  //     //   ),
  //     // );

  //     // Step 3: Confirm payment with Stripe
  //     // await Stripe.instance.confirmPayment(
  //     //   paymentIntentClientSecret: clientSecret,
  //     //   data: PaymentMethodParams.card(paymentMethodData: PaymentMethodData()),
  //     // );

  //     // await Stripe.instance.presentPaymentSheet();

  //     // Step 4: Verify payment status
  //     final confirmResponse = await _stripeService.confirmPayment(paymentIntentId: paymentIntentId);
  //     if (confirmResponse['status'] == 'succeeded') {
  //       final user = FirebaseAuth.instance.currentUser;
  //       if (user == null) return;
  //       final orderId = FirebaseFirestore.instance.collection('orders').doc().id;
  //       final taxes = calculateDetailedTaxes(_selectedAddress, widget.total);
  //       final order = OrderModel(
  //         orderId: orderId,
  //         userId: userModel.uid,
  //         items: widget.items,
  //         total: totalWithTax,
  //         status: 'paid',
  //         deliveryInfo: address.toMap(),
  //         createdAt: DateTime.now(),
  //         customerId: '',
  //         customerEmail: userModel.email,
  //         taxes: taxes,
  //         shippingCost: shippingCost,
  //         subtotal: widget.total,
  //       );
  //       await FirebaseFirestore.instance.collection('orders').doc(orderId).set(order.toMap());

  //       await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'cart': []});

  //       if (mounted) {
  //         final amount = (confirmResponse['amount'] / 100).toStringAsFixed(2);
  //         final paymentId = confirmResponse['paymentIntentId'];
  //         final receiptUrl = confirmResponse['receiptUrl'];
  //         final snackBar = SnackBar(content: Text('Payment of \$${amount.toStringAsFixed(2)} successful!'));
  //         ScaffoldMessenger.of(context).showSnackBar(snackBar);
  //         Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => OrderSuccessScreen(orderId: orderId)), (route) => route.isFirst);
  //       }
  //     } else {
  //       throw Exception('Payment not completed. Status: ${confirmResponse['status']}');
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
  //     }
  //   } finally {
  //     if (mounted) setState(() => _isProcessing = false);
  //   }
  // }

       // Error Message
                                // if (_errorMessage != null)
                                //   Container(
                                //     padding: const EdgeInsets.all(12),
                                //     margin: const EdgeInsets.only(bottom: 16),
                                //     decoration: BoxDecoration(
                                //       color: Colors.red.shade50,
                                //       borderRadius: BorderRadius.circular(8),
                                //       border: Border.all(color: Colors.red.shade200),
                                //     ),
                                //     child: Row(
                                //       children: [
                                //         Icon(Icons.error_outline, color: Colors.red.shade700),
                                //         const SizedBox(width: 12),
                                //         Expanded(
                                //           child: Text(
                                //             _errorMessage!,
                                //             style: TextStyle(color: Colors.red.shade700),
                                //           ),
                                //         ),
                                //       ],
                                //     ),
                                //   ),