import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/screens/productaddimages_screen.dart';
import 'package:origna_gta/screens/productaddvideo_screen.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

import 'package:origna_gta/features/products/edit_product_state.dart';
import 'package:origna_gta/features/products/edit_product_viewmodel.dart';

part 'parts/editproduct_form_widgets.dart';
part 'parts/editproduct_basic_info_section.dart';
part 'parts/editproduct_shipping_section.dart';
part 'parts/editproduct_location_section.dart';
part 'parts/editproduct_media_section.dart';
part 'parts/editproduct_delivery_section.dart';
part 'parts/editproduct_submit_section.dart';
part 'parts/editproduct_shared_widgets.dart';

/// Whether the low-stock alert toggle is on in the edit-product form.
final _editProductLowStockAlertProvider = StateProvider.autoDispose<bool>(
  (_) => false,
);

/// Edit product screen — composes parts from parts/ sub-files:
/// - parts/editproduct_form_widgets.dart (_EditDigitalTypeChip)
/// - parts/editproduct_basic_info_section.dart (buildBasicInfoSection)
/// - parts/editproduct_shipping_section.dart (buildShippingSection)
/// - parts/editproduct_location_section.dart (buildLocationSection)
/// - parts/editproduct_media_section.dart (buildMediaSection)
/// - parts/editproduct_delivery_section.dart (delivery options + digital section)
/// - parts/editproduct_submit_section.dart (handleSave, onUpdateSuccess)
/// - parts/editproduct_shared_widgets.dart (section title, info hint, URL field, etc.)
class EditProductScreen extends ConsumerStatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _compareAtPriceController;
  late final TextEditingController _categoryController;
  late final TextEditingController _streetController;
  late final TextEditingController _apartmentController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _stockController;
  late final TextEditingController _weightController;
  late final TextEditingController _lengthController;
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late final TextEditingController _shipDaysController;
  late final TextEditingController _minOrderController;
  late final TextEditingController _taxCodeController;

  // Inventory config
  late final TextEditingController _lowStockThresholdController;

  // Bill 96: French translation controllers
  late final TextEditingController _nameFController;
  late final TextEditingController _descriptionFController;

  // Digital product controllers
  late final TextEditingController _macosUrlController;
  late final TextEditingController _windowsUrlController;
  late final TextEditingController _linuxUrlController;
  late final TextEditingController _bookUrlController;
  late final TextEditingController _deviceLimitController;

  // Delivery controllers
  late final TextEditingController _standardDaysController;
  late final TextEditingController _standardPriceController;
  late final TextEditingController _expressDaysController;
  late final TextEditingController _expressPriceController;
  late final TextEditingController _sameDayPriceController;
  ProviderSubscription<EditProductState>? _editProductSubscription;

  static const Map<String, String> _provinceNames = ProvinceCodeValues.names;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProductViewModelProvider(widget.product));
    final viewModel = ref.read(
      editProductViewModelProvider(widget.product).notifier,
    );

    return Scaffold(
      appBar: AppBarFactory.simple(title: 'product.edit_product'.tr()),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildBasicInfoSection(state, viewModel),
                  if (!state.isDigital) buildShippingSection(state, viewModel),
                  buildLocationSection(state, viewModel),
                  buildMediaSection(state, viewModel),
                  Semantics(
                    button: true,
                    label: 'btn-save-product',
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        key: const Key('product_edit_save_button'),
                        onPressed: state.isLoading
                            ? null
                            : () => handleSave(viewModel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.primary,
                          foregroundColor: DesignTokens.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: state.isLoading
                            ? const ModernLoadingIndicator(
                                color: DesignTokens.white,
                                centered: false,
                              )
                            : Text(
                                'product.save_changes'.tr(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _editProductSubscription?.close();
    _nameController.dispose();
    _nameFController.dispose();
    _descriptionController.dispose();
    _descriptionFController.dispose();
    _priceController.dispose();
    _compareAtPriceController.dispose();
    _categoryController.dispose();
    _streetController.dispose();
    _apartmentController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _stockController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _shipDaysController.dispose();
    _minOrderController.dispose();
    _taxCodeController.dispose();
    _lowStockThresholdController.dispose();
    _macosUrlController.dispose();
    _windowsUrlController.dispose();
    _linuxUrlController.dispose();
    _bookUrlController.dispose();
    _deviceLimitController.dispose();
    _standardDaysController.dispose();
    _standardPriceController.dispose();
    _expressDaysController.dispose();
    _expressPriceController.dispose();
    _sameDayPriceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _editProductSubscription = ref.listenManual(
      editProductViewModelProvider(widget.product),
      (_, next) {
        if (!mounted) return;
        if (next.isSuccess) {
          onUpdateSuccess();
        } else if (next.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: DesignTokens.error,
            ),
          );
        }
      },
    );
    final p = widget.product;
    _nameController = TextEditingController(text: p.name);
    _nameFController = TextEditingController(text: p.nameF ?? '');
    _descriptionController = TextEditingController(text: p.description);
    _descriptionFController = TextEditingController(text: p.descriptionF ?? '');
    _priceController = TextEditingController(text: p.price.toString());
    _compareAtPriceController = TextEditingController(
      text: p.compareAtPrice?.toString() ?? '',
    );
    _categoryController = TextEditingController(text: p.categoryId.toString());
    _streetController = TextEditingController(
      text: p.sellerAddress?.street ?? '',
    );
    _apartmentController = TextEditingController(
      text: p.sellerAddress?.apartment ?? '',
    );
    _cityController = TextEditingController(
      text: p.sellerAddress?.city ?? p.shipFromCity ?? '',
    );
    _postalCodeController = TextEditingController(
      text: p.sellerAddress?.postalCode ?? '',
    );
    _stockController = TextEditingController(text: p.stockQuantity.toString());
    _weightController = TextEditingController(
      text: p.weightKg?.toString() ?? '',
    );
    _lengthController = TextEditingController(
      text: p.lengthCm?.toString() ?? '',
    );
    _widthController = TextEditingController(text: p.widthCm?.toString() ?? '');
    _heightController = TextEditingController(
      text: p.heightCm?.toString() ?? '',
    );
    _shipDaysController = TextEditingController(
      text: p.estimatedShipDays.toString(),
    );
    _minOrderController = TextEditingController(
      text: p.minimumOrderQuantity.toString(),
    );
    _taxCodeController = TextEditingController(text: p.taxCode ?? '');
    final existingThreshold = p.inventory?.lowStockThreshold ?? 0;
    ref.read(_editProductLowStockAlertProvider.notifier).state =
        existingThreshold > 0;
    _lowStockThresholdController = TextEditingController(
      text: existingThreshold > 0 ? existingThreshold.toString() : '5',
    );
    _macosUrlController = TextEditingController(
      text: p.digitalBuilds?[DigitalPlatformValues.macos] ?? '',
    );
    _windowsUrlController = TextEditingController(
      text: p.digitalBuilds?[DigitalPlatformValues.windows] ?? '',
    );
    _linuxUrlController = TextEditingController(
      text: p.digitalBuilds?[DigitalPlatformValues.linux] ?? '',
    );
    _bookUrlController = TextEditingController(); // empty — server-side only
    _deviceLimitController = TextEditingController(
      text: p.deviceLimit?.toString() ?? '',
    );

    // Initialize delivery options
    final standardOpt = _findOption(
      p.deliveryOptions,
      'standard',
      SellerDeliveryOption(
        type: 'standard',
        description: 'product.standard_delivery'.tr(),
        costCents: 0,
        estimatedDays: 5,
      ),
    );
    final expressOpt = _findOption(
      p.deliveryOptions,
      'express',
      SellerDeliveryOption(
        type: 'express',
        description: 'product.express_delivery'.tr(),
        costCents: 999,
        estimatedDays: 2,
      ),
    );
    final sameDayOpt = _findOption(
      p.deliveryOptions,
      'same_day',
      SellerDeliveryOption(
        type: 'same_day',
        description: 'product.same_day_delivery'.tr(),
        costCents: 1499,
        estimatedDays: 0,
      ),
    );

    _standardDaysController = TextEditingController(
      text: standardOpt.estimatedDays.toString(),
    );
    _standardPriceController = TextEditingController(
      text: (standardOpt.costCents / 100.0).toStringAsFixed(2),
    );
    _expressDaysController = TextEditingController(
      text: expressOpt.estimatedDays.toString(),
    );
    _expressPriceController = TextEditingController(
      text: (expressOpt.costCents / 100.0).toStringAsFixed(2),
    );
    _sameDayPriceController = TextEditingController(
      text: (sameDayOpt.costCents / 100.0).toStringAsFixed(2),
    );
  }

  SellerDeliveryOption _findOption(
    List<SellerDeliveryOption> options,
    String type,
    SellerDeliveryOption fallback,
  ) {
    return options.firstWhere((o) => o.type == type, orElse: () => fallback);
  }
}
