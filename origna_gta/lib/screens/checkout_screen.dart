import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/screens/editaddress_screen.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/checkout/checkout_provider.dart';
import 'package:origna_gta/screens/terms_screen.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final List<CartItemDetailModel> items;
  final double total;

  const CheckoutScreen({super.key, required this.items, required this.total});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCheckout();
    });
  }

  Future<void> _initializeCheckout() async {
    final notifier = ref.read(checkoutStateProvider.notifier);
    await notifier.initialize();

    final state = ref.read(checkoutStateProvider);
    if (state.address != null) {
      await notifier.calculateShipping(widget.items);
      notifier.calculateTaxes(widget.total);
    }
  }

  Future<void> _refreshShipping() async {
    final notifier = ref.read(checkoutStateProvider.notifier);
    await notifier.calculateShipping(widget.items);
    notifier.calculateTaxes(widget.total);
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBarFactory.simple(title: 'Checkout'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: userProfileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text(AppError.getMessage(error))),
            data: (userProfile) {
              if (userProfile == null) {
                return const Center(child: Text('Please log in to checkout'));
              }
              return _CheckoutContent(items: widget.items, subtotal: widget.total, userModel: userProfile, onRefreshShipping: _refreshShipping);
            },
          ),
        ),
      ),
    );
  }
}

class _CheckoutContent extends ConsumerWidget {
  final List<CartItemDetailModel> items;
  final double subtotal;
  final UserModel userModel;
  final VoidCallback onRefreshShipping;

  const _CheckoutContent({required this.items, required this.subtotal, required this.userModel, required this.onRefreshShipping});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutState = ref.watch(checkoutStateProvider);
    final address = checkoutState.address;

    if (address == null) {
      return _NoAddressView(onRefreshShipping: onRefreshShipping);
    }

    final taxRate = getTaxRate(address.state);
    final tax = subtotal * taxRate;
    final totalWithTax = subtotal + tax + checkoutState.shippingCost;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AddressSection(address: address, onRefreshShipping: onRefreshShipping),
                const SizedBox(height: 24),
                const _DeliveryOptionsSection(),
                const SizedBox(height: 24),
                _OrderSummary(items: items, subtotal: subtotal, state: address.state),
              ],
            ),
          ),
        ),
        _CheckoutButton(items: items, userModel: userModel, subtotal: subtotal, total: totalWithTax),
        _TermsText(),
        const SizedBox(height: 16),
        _SecurityInfo(),
      ],
    );
  }
}

class _NoAddressView extends StatelessWidget {
  final VoidCallback onRefreshShipping;

  const _NoAddressView({required this.onRefreshShipping});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text('No Delivery Address', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Please add a delivery address to continue with checkout',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditAddressScreen())).then((_) => onRefreshShipping());
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
}

class _AddressSection extends StatelessWidget {
  final Address address;
  final VoidCallback onRefreshShipping;

  const _AddressSection({required this.address, required this.onRefreshShipping});

  @override
  Widget build(BuildContext context) {
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
                  MaterialPageRoute(builder: (_) => AddEditAddressScreen(address: address.formattedAddress.isEmpty ? null : address)),
                ).then((_) => onRefreshShipping());
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
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (address.label != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFFF6B35).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    address.label!,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF6B35)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(address.formattedAddress, style: const TextStyle(fontSize: 14, height: 1.5)),
              if (address.phoneNumber != null) ...[
                const SizedBox(height: 8),
                Row(children: [const Icon(Icons.phone_outlined, size: 16), const SizedBox(width: 8), Text(address.phoneNumber!)]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Delivery speed options selection
class _DeliveryOptionsSection extends ConsumerWidget {
  const _DeliveryOptionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutState = ref.watch(checkoutStateProvider);
    final availableSpeeds = checkoutState.availableDeliverySpeeds;
    final selectedSpeed = checkoutState.deliverySpeed;
    final isCalculating = checkoutState.isCalculatingShipping;

    if (isCalculating) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Delivery Speed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...DeliverySpeed.values.map((speed) {
          final isAvailable = availableSpeeds.contains(speed);
          final isSelected = selectedSpeed == speed;
          final surcharge = speed == DeliverySpeed.standard ? 0.0 : speed.baseSurcharge;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: isAvailable ? () => ref.read(checkoutStateProvider.notifier).setDeliverySpeed(speed) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFF6B35).withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFF6B35)
                        : isAvailable
                        ? Colors.grey.shade300
                        : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isAvailable ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))] : null,
                ),
                child: Opacity(
                  opacity: isAvailable ? 1.0 : 0.5,
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? const Color(0xFFFF6B35) : Colors.grey.shade400, width: 2),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF6B35)),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  speed.displayName,
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: isAvailable ? Colors.black : Colors.grey),
                                ),
                                if (speed == DeliverySpeed.sameDay) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                                    child: Text(
                                      'LOCAL',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(speed.estimatedTime, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                            if (!isAvailable && speed == DeliverySpeed.sameDay)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Only available for local orders within 50km',
                                  style: TextStyle(fontSize: 11, color: Colors.orange.shade700, fontStyle: FontStyle.italic),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        surcharge > 0 ? '+\$${surcharge.toStringAsFixed(2)}' : 'FREE',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: surcharge > 0 ? Colors.black : Colors.green.shade700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _OrderSummary extends ConsumerWidget {
  final List<CartItemDetailModel> items;
  final double subtotal;
  final String state;

  const _OrderSummary({required this.items, required this.subtotal, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutState = ref.watch(checkoutStateProvider);
    final shippingCost = checkoutState.shippingCost;
    final isCalculating = checkoutState.isCalculatingShipping;
    final shippingError = checkoutState.shippingError;

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
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              ...items.map(
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
                  Text('\$${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              ..._buildTaxBreakdown(state, subtotal),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estimated Shipping', style: TextStyle(color: Colors.grey)),
                  if (isCalculating)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  else if (shippingError != null)
                    Text(shippingError, style: const TextStyle(color: Colors.red, fontSize: 12))
                  else
                    Text('\$${shippingCost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              if (!isCalculating && shippingError == null && shippingCost > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Final shipping cost will be confirmed by seller before charge',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
                  ),
                ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estimated Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(
                    '\$${(subtotal + (getTaxRate(state) * subtotal) + shippingCost).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFF6B35)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Taxes and total will be confirmed at payment.',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTaxBreakdown(String province, double total) {
    final taxes = taxConfig[province] ?? {'HST': 0.13};
    List<Widget> widgets = [];

    taxes.forEach((taxName, rate) {
      final taxAmount = total * rate;
      widgets.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$taxName (Est. ${(rate * 100).toStringAsFixed(2)}%)', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            Text('\$${taxAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      );
      widgets.add(const SizedBox(height: 4));
    });

    return widgets;
  }
}

class _CheckoutButton extends ConsumerWidget {
  final List<CartItemDetailModel> items;
  final UserModel userModel;
  final double subtotal;
  final double total;

  const _CheckoutButton({required this.items, required this.userModel, required this.subtotal, required this.total});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutState = ref.watch(checkoutStateProvider);
    final isDisabled = checkoutState.isProcessing || checkoutState.isCalculatingShipping || checkoutState.shippingError != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: isDisabled ? null : () => _startCheckout(context, ref),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
          child: checkoutState.isProcessing
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Text('Place Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Future<void> _startCheckout(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(checkoutStateProvider.notifier);

    final result = await notifier.startCheckout(items: items, user: userModel, subtotal: subtotal);
    if (!context.mounted) return;

    switch (result) {
      case CheckoutSuccess(:final checkoutUrl):
        await _redirectToStripe(checkoutUrl);
      case CheckoutError(:final message):
        messenger.showSnackBar(SnackBar(content: Text('Checkout error: $message'), backgroundColor: Colors.red, duration: const Duration(seconds: 5)));
      case CheckoutAlreadyProcessed(:final existingOrderId):
        messenger.showSnackBar(SnackBar(content: Text('Order already exists: $existingOrderId'), backgroundColor: Colors.orange));
    }
  }

  Future<void> _redirectToStripe(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not redirect to Stripe');
    }
  }
}

class _TermsText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen()));
                      },
                      child: const Text(
                        'Terms & Conditions',
                        style: TextStyle(fontSize: 12, color: Color(0xFFFF6B35), fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
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
}

class _SecurityInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
}
