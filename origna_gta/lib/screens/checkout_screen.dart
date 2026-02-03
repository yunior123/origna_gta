import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/checkout/checkout_provider.dart';
import 'package:origna_gta/screens/editaddress_screen.dart';
import 'package:origna_gta/screens/terms_screen.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final List<CartItemDetailModel> items;
  final double total;

  const CheckoutScreen({super.key, required this.items, required this.total});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _AddressSection extends StatelessWidget {
  final Address address;
  final VoidCallback onRefreshShipping;

  const _AddressSection({required this.address, required this.onRefreshShipping});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [DesignTokens.primary, DesignTokens.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                'Delivery Address',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddEditAddressScreen(address: address.formattedAddress.isEmpty ? null : address)),
                  ).then((_) => onRefreshShipping());
                },
                borderRadius: BorderRadius.circular(8),
                splashColor: DesignTokens.primary.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: DesignTokens.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Edit',
                        style: TextStyle(color: DesignTokens.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (address.label != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [DesignTokens.primary.withValues(alpha: 0.2), DesignTokens.secondary.withValues(alpha: 0.2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    address.label!,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DesignTokens.primary),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(address.formattedAddress, style: TextStyle(fontSize: 15, height: 1.6, color: isDark ? Colors.grey[300] : Colors.grey[700])),
              if (address.phoneNumber != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 16, color: DesignTokens.primary),
                    const SizedBox(width: 10),
                    Text(address.phoneNumber!, style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700])),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
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
    final isProcessing = ref.watch(checkoutStateProvider.select((state) => state.isProcessing));
    final isCalculating = ref.watch(checkoutStateProvider.select((state) => state.isCalculatingShipping));
    final shippingError = ref.watch(checkoutStateProvider.select((state) => state.shippingError));
    final isDisabled = isProcessing || isCalculating || shippingError != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -8))],
      ),
      child: ModernButton(
        label: isProcessing ? 'Processing...' : 'Place Order',
        onPressed: isDisabled ? null : () => _startCheckout(context, ref),
        isLoading: isProcessing,
        icon: Icons.payment,
      ),
    );
  }

  Future<void> _redirectToStripe(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not redirect to Stripe');
    }
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
        messenger.showSnackBar(SnackBar(content: Text('Order already exists: $existingOrderId'), backgroundColor: const Color(0xFF667EEA)));
    }
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
    final address = ref.watch(checkoutStateProvider.select((state) => state.address));
    final shippingCost = ref.watch(checkoutStateProvider.select((state) => state.shippingCost));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPhysicalItems = items.any((item) => !item.isDigital);
    final paymentProvider = ref.watch(checkoutStateProvider.select((state) => state.paymentProvider));
    final notifier = ref.read(checkoutStateProvider.notifier);

    if (address == null) {
      if (!hasPhysicalItems) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [isDark ? Colors.grey[900]! : Colors.grey[50]!, isDark ? Colors.grey[800]! : Colors.white],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassContainer(
                        child: Row(
                          children: [
                            Icon(Icons.download_done, color: DesignTokens.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Digital delivery — no shipping or address required',
                                style: TextStyle(color: isDark ? Colors.grey[200] : Colors.grey[700], fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      _PaymentProviderSection(selectedProvider: paymentProvider, onChanged: notifier.setPaymentProvider),
                      const SizedBox(height: 28),
                      _OrderSummary(items: items, subtotal: subtotal, state: 'ON'),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              _CheckoutButton(items: items, userModel: userModel, subtotal: subtotal, total: subtotal),
              _TermsText(),
              const SizedBox(height: 16),
              _SecurityInfo(),
            ],
          ),
        );
      }
      return _NoAddressView(onRefreshShipping: onRefreshShipping);
    }

    final taxRate = getTaxRate(address.state);
    final tax = subtotal * taxRate;
    final totalWithTax = subtotal + tax + shippingCost;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [isDark ? Colors.grey[900]! : Colors.grey[50]!, isDark ? Colors.grey[800]! : Colors.white],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AddressSection(address: address, onRefreshShipping: onRefreshShipping),
                  const SizedBox(height: 28),
                  if (hasPhysicalItems) ...[
                    const _DeliveryOptionsSection(),
                    const SizedBox(height: 28),
                  ] else ...[
                    GlassContainer(
                      child: Row(
                        children: [
                          Icon(Icons.download_done, color: DesignTokens.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Digital delivery — no shipping required',
                              style: TextStyle(color: isDark ? Colors.grey[200] : Colors.grey[700], fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                  _PaymentProviderSection(selectedProvider: paymentProvider, onChanged: notifier.setPaymentProvider),
                  const SizedBox(height: 28),
                  _OrderSummary(items: items, subtotal: subtotal, state: address.state),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _CheckoutButton(items: items, userModel: userModel, subtotal: subtotal, total: totalWithTax),
          _TermsText(),
          const SizedBox(height: 16),
          _SecurityInfo(),
        ],
      ),
    );
  }
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
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
}

/// Delivery speed options selection
class _DeliveryOptionsSection extends ConsumerWidget {
  const _DeliveryOptionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableSpeeds = ref.watch(checkoutStateProvider.select((state) => state.availableDeliverySpeeds));
    final selectedSpeed = ref.watch(checkoutStateProvider.select((state) => state.deliverySpeed));
    final isCalculating = ref.watch(checkoutStateProvider.select((state) => state.isCalculatingShipping));

    if (isCalculating) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Delivery Speed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(
              onPressed: () => _showDeliveryInfo(context),
              icon: const Icon(Icons.info_outline, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Learn more about delivery options',
            ),
          ],
        ),
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
                  color: isSelected ? const Color(0xFF667EEA).withValues(alpha: 0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? const Color(0xFF667EEA) : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 1))],
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
                          border: Border.all(color: isSelected ? const Color(0xFF667EEA) : Colors.grey.shade300, width: 2),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF667EEA)),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  speed.displayName,
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: isAvailable ? Colors.black : Colors.grey.shade500),
                                ),
                                if (speed == DeliverySpeed.sameDay) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                                    child: Text(
                                      'LOCAL',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(speed.estimatedTime, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                            if (!isAvailable && speed == DeliverySpeed.sameDay)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Only available for local orders within 50km',
                                  style: TextStyle(fontSize: 11, color: const Color(0xFFFF6B6B), fontStyle: FontStyle.italic),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        surcharge > 0 ? '+\$${surcharge.toStringAsFixed(2)}' : 'FREE',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: surcharge > 0 ? Colors.black87 : Colors.green.shade700),
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

  static void _showDeliveryInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delivery Options'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: DeliverySpeed.values.map((speed) {
              final surcharge = speed == DeliverySpeed.standard ? 0.0 : speed.baseSurcharge;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(speed.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        if (speed == DeliverySpeed.sameDay) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              'LOCAL',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(speed.estimatedTime, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    if (speed == DeliverySpeed.sameDay)
                      Text(
                        'Available for local orders within 50km radius',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      surcharge > 0 ? 'Additional cost: +\$${surcharge.toStringAsFixed(2)}' : 'No additional cost',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: surcharge > 0 ? Colors.grey.shade700 : Colors.green.shade700),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
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
                backgroundColor: const Color(0xFF667EEA),
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

class _OrderSummary extends ConsumerWidget {
  final List<CartItemDetailModel> items;
  final double subtotal;
  final String state;

  const _OrderSummary({required this.items, required this.subtotal, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shippingCost = ref.watch(checkoutStateProvider.select((state) => state.shippingCost));
    final isCalculating = ref.watch(checkoutStateProvider.select((state) => state.isCalculatingShipping));
    final shippingError = ref.watch(checkoutStateProvider.select((state) => state.shippingError));

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
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF667EEA)),
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

class _PaymentProviderSection extends StatelessWidget {
  final String selectedProvider;
  final ValueChanged<String> onChanged;

  const _PaymentProviderSection({required this.selectedProvider, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            ChoiceChip(
              label: const Text('Stripe'),
              selected: selectedProvider == 'stripe',
              onSelected: (selected) {
                if (selected) onChanged('stripe');
              },
            ),
            const SizedBox(width: 12),
            ChoiceChip(
              label: const Text('Airwallex'),
              selected: selectedProvider == 'airwallex',
              onSelected: (selected) {
                if (selected) onChanged('airwallex');
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          selectedProvider == 'airwallex'
              ? 'Airwallex supports international cards and multi-currency settlement.'
              : 'Stripe is the default and fastest checkout experience.',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}

class _SecurityInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Payment',
                  style: TextStyle(color: Colors.blue.shade900, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Powered by Stripe. Your payment information is encrypted and secure.',
                  style: TextStyle(color: Colors.blue.shade700, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsText extends StatefulWidget {
  const _TermsText();

  @override
  State<_TermsText> createState() => _TermsTextState();
}

class _TermsTextState extends State<_TermsText> {
  bool _termsAccepted = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: Checkbox(
                value: _termsAccepted,
                onChanged: (value) => setState(() => _termsAccepted = value ?? false),
                side: BorderSide(color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen()));
                        },
                        child: Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF667EEA),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFF667EEA),
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen()));
                        },
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF667EEA),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFF667EEA),
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
      ),
    );
  }
}
