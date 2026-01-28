import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/constants.dart';
import 'package:origna_gta/editaddress_screen.dart';
import 'package:origna_gta/terms_screen.dart';
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
  double? _cachedShippingCost;
  bool _isCalculatingShipping = false;
  String? _shippingError;

  @override
  void initState() {
    super.initState();
    _calculateShippingCost();
  }

  Future<void> _calculateShippingCost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isCalculatingShipping = true;
      _shippingError = null;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final addressMap = userDoc.data()?['address'] as Map<String, dynamic>?;
      if (addressMap == null) {
        setState(() {
          _shippingError = 'No address found';
          _isCalculatingShipping = false;
        });
        return;
      }

      final address = Address.fromMap(addressMap);
      final cost = await calculateShippingCost(widget.items, address);

      if (mounted) {
        setState(() {
          _cachedShippingCost = cost;
          _isCalculatingShipping = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _shippingError = 'Failed to calculate shipping';
          _isCalculatingShipping = false;
        });
      }
    }
  }

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
            stream: user != null
                ? FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots()
                : null,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>?;
              final Address? savedAddress = userData?['address'] != null
                  ? Address.fromMap(userData!['address'] as Map<String, dynamic>)
                  : null;
              final userModel = UserModel.fromMap(userData ?? {});

              if (savedAddress == null) {
                return _buildNoAddressView();
              }

              final taxRate = getTaxRate(savedAddress.state);
              final tax = widget.total * taxRate;
              final shippingCost = _cachedShippingCost ?? 0.0;
              final totalWithTax = widget.total + tax + shippingCost;

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAddressSection(savedAddress),
                          const SizedBox(height: 24),
                          _buildOrderSummary(savedAddress.state, shippingCost)
                        ],
                      ),
                    ),
                  ),
                  _buildCheckoutButton(savedAddress, userModel, totalWithTax),
                  _buildTermsText(context),
                  const SizedBox(height: 16),
                  _buildSecurityInfo(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(String state, double shippingCost) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            children: [
              ...widget.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.name} x${item.quantity}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
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
              ..._buildTaxBreakdown(state, widget.total),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Shipping', style: TextStyle(color: Colors.grey)),
                  if (_isCalculatingShipping)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (_shippingError != null)
                    Text(_shippingError!, style: const TextStyle(color: Colors.red, fontSize: 12))
                  else
                    Text('\$${shippingCost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(
                    '\$${(widget.total + (getTaxRate(state) * widget.total) + shippingCost).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoAddressView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'No Delivery Address',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Please add a delivery address to continue with checkout',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditAddressScreen()),
                ).then((_) => _calculateShippingCost());
              },
              icon: const Icon(Icons.add_location),
              label: const Text('Add Address'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection(Address savedAddress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Delivery Address', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditAddressScreen(
                      address: savedAddress.formattedAddress.isEmpty ? null : savedAddress,
                    ),
                  ),
                ).then((_) => _calculateShippingCost());
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF6B35)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (savedAddress.label != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    savedAddress.label!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(savedAddress.formattedAddress, style: const TextStyle(fontSize: 14, height: 1.5)),
              if (savedAddress.phoneNumber != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16),
                    const SizedBox(width: 8),
                    Text(savedAddress.phoneNumber!)
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutButton(Address address, UserModel userModel, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: (_isProcessing || _isCalculatingShipping || _shippingError != null)
              ? null
              : () => _startStripeCheckout(widget.items, address, userModel),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
          ),
          child: _isProcessing
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : const Text('Place Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
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

  Widget _buildTermsText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                children: [
                  const TextSpan(text: 'By placing this order, you agree to our '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TermsScreen()),
                        );
                      },
                      child: const Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFF6B35),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Secure payment powered by Stripe. Your card information is encrypted.',
              style: TextStyle(color: Colors.blue.shade700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _redirectToStripe(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not redirect to Stripe');
    }
  }

  Future<void> _startStripeCheckout(
    List<CartItemDetailModel> items,
    Address address,
    UserModel userModel,
  ) async {
    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Calculate totals
      final taxRate = getTaxRate(address.state);
      final tax = widget.total * taxRate;
      final shippingCost = _cachedShippingCost ?? 0.0;
      final totalWithTax = widget.total + tax + shippingCost;

      // Get detailed taxes breakdown
      final taxes = calculateDetailedTaxes(address, widget.total);

      // Get seller IDs from items
      final sellerIds = items.map((item) => item.sellerId).toSet().toList();

      // Prepare delivery info map
      final deliveryInfo = {
        'formattedAddress': address.formattedAddress,
        'street': address.street,
        'apartment': address.apartment,
        'city': address.city,
        'state': address.state,
        'postalCode': address.postalCode,
        'country': address.country,
        'phoneNumber': address.phoneNumber,
        'label': address.label,
      };

      // Create OrderModel for type safety - this ensures all fields match
      // Note: orderId, createdAt, status, stripeSessionId will be set by backend
      final orderForValidation = OrderModel(
        orderId: '', // Will be set by backend
        userId: user.uid,
        customerId: userModel.customerId ?? '',
        customerEmail: userModel.email,
        items: items,
        total: totalWithTax,
        taxes: taxes,
        shippingCost: shippingCost,
        subtotal: widget.total,
        status: OrderStatus.pending.value, // Will be overridden by backend
        deliveryInfo: deliveryInfo,
        createdAt: DateTime.now(), // Will be overridden by backend
        currency: 'cad',
        amount: (totalWithTax * 100).toInt(),
        sellerIds: sellerIds,
        stripeSessionId: '', // Will be set by backend
      );

      // Convert to map for sending to backend
      // We use the model's toMap to ensure consistency, then remove fields set by backend
      final orderData = orderForValidation.toMap();
      // Remove fields that backend will generate
      orderData.remove('createdAt');
      orderData.remove('status');
      
      // Backend expects items as simple maps without sellerAddress since it's already in the item
      orderData['items'] = items.map((item) => {
        'sellerId': item.sellerId,
        'productId': item.productId,
        'name': item.name,
        'description': item.description,
        'price': item.price,
        'quantity': item.quantity,
        'imageUrls': item.imageUrls,
      }).toList();

      debugPrint('📤 Sending checkout request...');
      
      // Call the Cloud Function
      final callable = FirebaseFunctions.instance.httpsCallable('create_checkout_session');
      final response = await callable.call(orderData);

      debugPrint('✅ Received response from backend');
      
      // Extract response data
      final checkoutUrl = response.data['url'] as String;
      final orderId = response.data['orderId'] as String;
      final sessionId = response.data['sessionId'] as String;

      debugPrint('📝 Order ID: $orderId');
      debugPrint('🔗 Session ID: $sessionId');

      // Update user model with checkout tracking info
      final updatedUser = userModel.copyWith(
        lastCheckoutSession: sessionId,
        lastOrderId: orderId,
        lastCheckoutTimestamp: DateTime.now(),
      );
      
      // Save to Firestore using the model
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updatedUser.toMap());

      // Redirect to Stripe
      if (kIsWeb) {
        debugPrint('🌐 Redirecting to Stripe...');
        await _redirectToStripe(checkoutUrl);
      } else {
        // For mobile apps
        await _redirectToStripe(checkoutUrl);
      }
      
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Firebase Function Error: ${e.code} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout error: ${e.message ?? e.code}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}