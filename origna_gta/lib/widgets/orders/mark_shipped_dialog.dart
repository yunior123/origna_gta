import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/schema/schema_constants.dart'
    show CarrierValues, DeliveryStatusValues;
import 'package:origna_gta/features/orders/seller_orders_viewmodel.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/widgets/modern_button.dart';

/// Shows the "Mark as Shipped" dialog where the seller enters
/// carrier, tracking number, and optional carrier note.
///
/// Also used for editing tracking info on already-shipped items
/// via [prefillTracking], [prefillCarrier], [prefillCarrierNote].
void showMarkShippedDialog(
  BuildContext context,
  WidgetRef ref, {
  required String orderId,
  required String productId,
  required AutoDisposeStateProvider<String?> carrierProvider,
  String? prefillTracking,
  String? prefillCarrier,
  String? prefillCarrierNote,
}) {
  final trackingController = TextEditingController(text: prefillTracking ?? '');
  final carrierNoteController = TextEditingController(
    text: prefillCarrierNote ?? '',
  );
  // Initialize the provider with prefill value before showing dialog
  ref.read(carrierProvider.notifier).state = prefillCarrier;

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
                  Icons.local_shipping_rounded,
                  size: 18,
                  color: DesignTokens.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'seller.mark_shipped'.tr(),
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
              // Tracking number
              Semantics(
                textField: true,
                label: 'input-tracking-number',
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
                  final tracking = trackingController.text.trim();
                  if (tracking.isNotEmpty) {
                    final note = carrierValue == CarrierValues.other
                        ? carrierNoteController.text.trim()
                        : null;
                    Navigator.pop(context);
                    ref
                        .read(sellerOrdersViewModelProvider.notifier)
                        .updateItemStatus(
                          orderId,
                          productId,
                          DeliveryStatusValues.shipped,
                          trackingNumber: tracking,
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

/// Human-readable label for a [CarrierValues] constant.
String carrierLabel(String carrier) {
  switch (carrier) {
    case CarrierValues.ups:
      return 'UPS';
    case CarrierValues.fedex:
      return 'FedEx';
    case CarrierValues.canadaPost:
      return 'Canada Post';
    case CarrierValues.purolator:
      return 'Purolator';
    case CarrierValues.dhl:
      return 'DHL';
    case CarrierValues.usps:
      return 'USPS';
    case CarrierValues.maritime:
      return 'Maritime (International)';
    case CarrierValues.other:
      return 'seller.carrier_other'.tr();
    default:
      return carrier;
  }
}
