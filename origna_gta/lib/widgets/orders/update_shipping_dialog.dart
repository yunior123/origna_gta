import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/schema/schema_constants.dart'
    show CarrierValues;
import 'package:origna_gta/features/orders/seller_orders_viewmodel.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/orders/mark_shipped_dialog.dart'
    show carrierLabel;

/// Shows the "Confirm Shipping & Capture" dialog where the seller enters
/// actual shipping cost, carrier, tracking number, and optional carrier note.
///
/// Used when the order payment is authorized but not yet captured.
void showUpdateShippingDialog(
  BuildContext context,
  WidgetRef ref, {
  required String orderId,
  required double estimatedShipping,
  required AutoDisposeStateProvider<String?> carrierProvider,
}) {
  final shippingController = TextEditingController(
    text: estimatedShipping.toStringAsFixed(2),
  );
  final trackingController = TextEditingController();
  final carrierNoteController = TextEditingController();
  // Initialize the provider before showing dialog
  ref.read(carrierProvider.notifier).state = null;

  showDialog(
    context: context,
    builder: (context) => Consumer(
      builder: (context, dialogRef, _) {
        final carrierValue = dialogRef.watch(carrierProvider);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DesignTokens.primary.withValues(alpha: 0.15),
                      DesignTokens.secondary.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: Icon(
                  Icons.payment_rounded,
                  size: 18,
                  color: DesignTokens.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'seller.confirm_shipping'.tr(),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                textField: true,
                label: 'input-actual-cost',
                child: TextField(
                  controller: shippingController,
                  decoration: InputDecoration(
                    labelText: 'seller.actual_cost'.tr(),
                    prefixIcon: Icon(
                      Icons.attach_money_rounded,
                      color: DesignTokens.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radius12,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radius12,
                      ),
                      borderSide: BorderSide(
                        color: DesignTokens.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 14),
              // Carrier dropdown
              DropdownButtonFormField<String>(
                menuMaxHeight: ResponsiveBreakpoints.dropdownMaxHeight(context),
                initialValue: carrierValue,
                decoration: InputDecoration(
                  labelText: 'seller.carrier_label'.tr(),
                  prefixIcon: Icon(
                    Icons.local_shipping_outlined,
                    color: DesignTokens.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    borderSide: BorderSide(
                      color: DesignTokens.primary,
                      width: 2,
                    ),
                  ),
                ),
                items: CarrierValues.all
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(carrierLabel(c)),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    dialogRef.read(carrierProvider.notifier).state = value,
              ),
              // Carrier note (only when 'other' is selected)
              if (carrierValue == CarrierValues.other) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: carrierNoteController,
                  decoration: InputDecoration(
                    labelText: 'seller.carrier_note_label'.tr(),
                    prefixIcon: Icon(
                      Icons.edit_outlined,
                      color: DesignTokens.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radius12,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radius12,
                      ),
                      borderSide: BorderSide(
                        color: DesignTokens.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Semantics(
                textField: true,
                label: 'input-tracking-number-update',
                child: TextField(
                  controller: trackingController,
                  decoration: InputDecoration(
                    labelText: 'seller.tracking_number'.tr(),
                    prefixIcon: Icon(
                      Icons.qr_code_rounded,
                      color: DesignTokens.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radius12,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radius12,
                      ),
                      borderSide: BorderSide(
                        color: DesignTokens.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'common.cancel'.tr(),
                style: TextStyle(color: DesignTokens.textSecondary),
              ),
            ),
            SizedBox(
              width: 120,
              child: ModernButton(
                label: 'common.confirm'.tr(),
                onPressed: () {
                  final costDollars = double.tryParse(shippingController.text);
                  final tracking = trackingController.text.trim();
                  if (costDollars != null && tracking.isNotEmpty) {
                    final costCents = (costDollars * 100).round();
                    final note = carrierValue == CarrierValues.other
                        ? carrierNoteController.text.trim()
                        : null;
                    Navigator.pop(context);
                    ref
                        .read(sellerOrdersViewModelProvider.notifier)
                        .updateShippingAndCapture(
                          orderId,
                          costCents,
                          tracking,
                          carrier: carrierValue,
                          carrierNote: note,
                        );
                  }
                },
                height: 42,
              ),
            ),
          ],
        );
      },
    ),
  );
}
