import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/features/orders/return_request_viewmodel.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart' hide Address;
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

// ─── Riverpod state for ReturnRequestScreen ─────────────────────────────────
final _returnSelectedItemsProvider = StateProvider.autoDispose<Set<String>>(
  (ref) => {},
);
final _returnSelectedReasonProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

/// Return reason options for the buyer.
const _returnReasons = [
  ('defective', 'returns.reason_defective'),
  ('wrong_item', 'returns.reason_wrong_item'),
  ('changed_mind', 'returns.reason_changed_mind'),
  ('not_as_described', 'returns.reason_not_as_described'),
  ('damaged_in_shipping', 'returns.reason_damaged'),
  ('other', 'returns.reason_other'),
];

/// Screen for buyers to request a return on delivered order items.
class ReturnRequestScreen extends ConsumerStatefulWidget {
  final String orderId;
  const ReturnRequestScreen({super.key, required this.orderId});

  @override
  ConsumerState<ReturnRequestScreen> createState() =>
      _ReturnRequestScreenState();
}

class _ReturnRequestScreenState extends ConsumerState<ReturnRequestScreen> {
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orderAsync = ref.watch(orderByIdProvider(widget.orderId));
    final vmState = ref.watch(returnRequestViewModelProvider);

    // Listen for error feedback from the ViewModel
    ref.listen<ReturnRequestState>(returnRequestViewModelProvider, (
      prev,
      next,
    ) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: DesignTokens.error,
          ),
        );
        ref.read(returnRequestViewModelProvider.notifier).clearStatus();
      }
    });

    return Container(
      decoration: BoxDecoration(
        gradient: DesignTokens.backgroundGradient(isDark: isDark),
      ),
      child: Scaffold(
        appBar: AppBarFactory.simple(title: 'returns.request_return'.tr()),
        backgroundColor: DesignTokens.transparent,
        body: vmState.isSuccess
            ? _buildConfirmation(isDark)
            : orderAsync.when(
                loading: () => const Center(child: ModernLoadingIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    AppError.getMessage(error),
                    style: TextStyle(color: DesignTokens.error),
                  ),
                ),
                data: (order) {
                  if (order == null) {
                    return Center(
                      child: Text(
                        'orders.not_found'.tr(),
                        style: TextStyle(color: DesignTokens.textSecondary),
                      ),
                    );
                  }
                  return _buildForm(order, isDark);
                },
              ),
      ),
    );
  }

  Widget _buildForm(Order order, bool isDark) {
    final selectedItems = ref.watch(_returnSelectedItemsProvider);
    final selectedReason = ref.watch(_returnSelectedReasonProvider);
    final isSubmitting = ref.watch(
      returnRequestViewModelProvider.select((s) => s.isLoading),
    );
    // Only delivered items are eligible for return
    final eligibleItems = order.items.where((item) {
      return item.status == DeliveryStatusValues.delivered;
    }).toList();

    if (eligibleItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: DesignTokens.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'returns.no_eligible_items'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DesignTokens.textSecondary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ResponsiveBreakpoints.contentMaxWidth,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Return window notice
              _buildReturnWindowNotice(order, isDark),
              const SizedBox(height: 20),

              // Item selection
              Text(
                'returns.select_items'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? DesignTokens.white : DesignTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...eligibleItems.map((item) => _buildItemTile(item, isDark)),
              const SizedBox(height: 24),

              // Reason dropdown
              Text(
                'returns.select_reason'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? DesignTokens.white : DesignTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'input-return-reason',
                child: DropdownButtonFormField<String>(
                  initialValue: ref.read(_returnSelectedReasonProvider),
                  decoration: InputDecoration(
                    hintText: 'returns.reason_hint'.tr(),
                    filled: true,
                    fillColor: isDark
                        ? DesignTokens.darkSurfaceVariant
                        : DesignTokens.surface,
                  ),
                  items: _returnReasons.map((r) {
                    return DropdownMenuItem(
                      value: r.$1,
                      child: Text(r.$2.tr()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (!mounted) return;
                    ref.read(_returnSelectedReasonProvider.notifier).state =
                        value;
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Optional description
              Text(
                'returns.description_label'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? DesignTokens.white : DesignTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'input-return-description',
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'returns.description_hint'.tr(),
                    filled: true,
                    fillColor: isDark
                        ? DesignTokens.darkSurfaceVariant
                        : DesignTokens.surface,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  button: true,
                  label: 'btn-submit-return',
                  child: ModernButton(
                    onPressed:
                        _canSubmit(selectedItems, selectedReason, isSubmitting)
                        ? _submitReturn
                        : null,
                    label: 'returns.submit'.tr(),
                    icon: Icons.assignment_return,
                    isLoading: isSubmitting,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReturnWindowNotice(Order order, bool isDark) {
    // Find the latest deliveredAt among items
    DateTime? latestDelivery;
    for (final item in order.items) {
      if (item.deliveredAt != null) {
        if (latestDelivery == null ||
            item.deliveredAt!.isAfter(latestDelivery)) {
          latestDelivery = item.deliveredAt;
        }
      }
    }

    final deadline = latestDelivery?.add(
      const Duration(days: BusinessRules.returnWindowDays),
    );
    final daysLeft = deadline != null
        ? deadline.difference(DateTime.now()).inDays
        : 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.info.withValues(alpha: 0.12),
            DesignTokens.info.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: DesignTokens.info.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 20, color: DesignTokens.info),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'returns.window_notice'.tr(
                namedArgs: {'days': daysLeft.toString()},
              ),
              style: TextStyle(
                fontSize: 13,
                color: DesignTokens.info,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(OrderItem item, bool isDark) {
    final itemKey = item.cartItemId ?? item.productId;
    final selectedItems = ref.watch(_returnSelectedItemsProvider);
    final isSelected = selectedItems.contains(itemKey);
    final imageUrl = item.imageUrls.isNotEmpty ? item.imageUrls.first : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        label: 'return-item-${item.productId}',
        child: Material(
          color: DesignTokens.transparent,
          child: InkWell(
            onTap: () {
              if (!mounted) return;
              final current = ref.read(_returnSelectedItemsProvider);
              if (isSelected) {
                ref.read(_returnSelectedItemsProvider.notifier).state = {
                  ...current,
                }..remove(itemKey);
              } else {
                ref.read(_returnSelectedItemsProvider.notifier).state = {
                  ...current,
                  itemKey,
                };
              }
            },
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? DesignTokens.darkCard : DesignTokens.white,
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                border: Border.all(
                  color: isSelected
                      ? DesignTokens.primary
                      : (isDark
                            ? DesignTokens.white.withValues(alpha: 0.08)
                            : DesignTokens.outlineVariant),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Checkbox
                  Checkbox(
                    value: isSelected,
                    onChanged: (val) {
                      if (!mounted) return;
                      final current = ref.read(_returnSelectedItemsProvider);
                      if (val == true) {
                        ref.read(_returnSelectedItemsProvider.notifier).state =
                            {...current, itemKey};
                      } else {
                        ref
                            .read(_returnSelectedItemsProvider.notifier)
                            .state = {...current}
                          ..remove(itemKey);
                      }
                    },
                    activeColor: DesignTokens.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Image
                  if (imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          width: 48,
                          height: 48,
                          color: DesignTokens.textSecondary.withValues(
                            alpha: 0.1,
                          ),
                          child: Icon(
                            Icons.image,
                            size: 20,
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: DesignTokens.textSecondary.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.image,
                        size: 20,
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  const SizedBox(width: 12),
                  // Name and price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? DesignTokens.white
                                : DesignTokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Qty: ${item.quantity}  ·  \$${item.subtotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _canSubmit(Set<String> items, String? reason, bool submitting) =>
      items.isNotEmpty && reason != null && !submitting;

  Future<void> _submitReturn() async {
    final selectedItems = ref.read(_returnSelectedItemsProvider);
    final selectedReason = ref.read(_returnSelectedReasonProvider);
    final isSubmitting = ref.read(returnRequestViewModelProvider).isLoading;
    if (!_canSubmit(selectedItems, selectedReason, isSubmitting)) return;

    await ref
        .read(returnRequestViewModelProvider.notifier)
        .submitReturn(
          orderId: widget.orderId,
          cartItemIds: selectedItems.toList(),
          reason: selectedReason!,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
  }

  Widget _buildConfirmation(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    DesignTokens.success.withValues(alpha: 0.2),
                    DesignTokens.success.withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 48,
                color: DesignTokens.success,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'returns.submitted_title'.tr(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? DesignTokens.white : DesignTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'returns.submitted_message'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: DesignTokens.textSecondary),
            ),
            const SizedBox(height: 32),
            Semantics(
              button: true,
              label: 'btn-back-to-order',
              child: ModernButton(
                onPressed: () => appPop(context),
                label: 'returns.back_to_order'.tr(),
                icon: Icons.arrow_back,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@Preview(
  name: 'Return Request — Mobile',
  group: 'ReturnRequest',
  size: Size(390, 844),
)
Widget previewReturnRequestMobile() =>
    previewMobile(child: _returnRequestContent());

@Preview(
  name: 'Return Request — Tablet',
  group: 'ReturnRequest',
  size: Size(768, 1024),
)
Widget previewReturnRequestTablet() =>
    previewTablet(child: _returnRequestContent());

@Preview(
  name: 'Return Request — Desktop',
  group: 'ReturnRequest',
  size: Size(1280, 800),
)
Widget previewReturnRequestDesktop() =>
    previewDesktop(child: _returnRequestContent());

@Preview(
  name: 'Return Request — Light',
  group: 'ReturnRequest',
  size: Size(390, 844),
  brightness: Brightness.light,
)
Widget previewReturnRequestLight() =>
    previewMobile(child: _returnRequestContent(), theme: previewLightTheme);

const _previewOrderId = 'preview-order-id';
const _previewReturnRequestImageBase = 'https://fastly.picsum.photos/id';

String _previewReturnRequestImage(
  int id, {
  int width = 900,
  int height = 900,
}) => '$_previewReturnRequestImageBase/$id/$width/$height.jpg';

Widget _returnRequestContent() => previewScopeLoggedIn(
  extraOverrides: [
    orderByIdProvider(_previewOrderId).overrideWith(
      (ref) => Future.value(
        Order(
          orderId: _previewOrderId,
          userId: 'preview-uid',
          items: [
            OrderItem(
              productId: 'prod-1',
              cartItemId: 'cart-1',
              name: 'Premium Headphones',
              description: 'Noise-canceling wireless headphones',
              priceCents: 29999,
              quantity: 1,
              imageUrls: [_previewReturnRequestImage(367)],
              sellerId: 'seller-1',
              sellerName: 'AudioTech Canada',
              status: DeliveryStatusValues.delivered,
              deliveredAt: DateTime(2026, 3, 20),
            ),
            OrderItem(
              productId: 'prod-2',
              cartItemId: 'cart-2',
              name: 'USB-C Charging Cable',
              description: 'Braided 2m cable',
              priceCents: 1499,
              quantity: 2,
              imageUrls: [_previewReturnRequestImage(29)],
              sellerId: 'seller-1',
              sellerName: 'AudioTech Canada',
              status: DeliveryStatusValues.delivered,
              deliveredAt: DateTime(2026, 3, 20),
            ),
          ],
          totalAmountCents: 32997,
          subtotalCents: 32997,
          taxes: const Taxes(
            gstCents: 0,
            pstCents: 0,
            qstCents: 0,
            hstCents: 0,
          ),
          orderStatus: OrderStatus.delivered,
          paymentStatus: PaymentStatus.paid,
          createdAt: DateTime(2026, 3, 15),
          shippingAddress: Address(
            street: '123 Queen St W',
            city: 'Toronto',
            state: 'ON',
            postalCode: 'M5H 2M9',
            country: 'CA',
          ),
        ),
      ),
    ),
    returnRequestViewModelProvider.overrideWith(
      (ref) => _PreviewReturnRequestViewModel(ref),
    ),
  ],
  child: const ReturnRequestScreen(orderId: _previewOrderId),
);

class _PreviewReturnRequestViewModel extends ReturnRequestViewModel {
  _PreviewReturnRequestViewModel(super.ref) : super.preview();
}
