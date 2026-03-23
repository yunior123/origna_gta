import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/config/supplier_config.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/screens/productaddimages_screen.dart';
import 'package:origna_gta/screens/productaddvideo_screen.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

import 'package:origna_gta/features/products/add_product_state.dart';
import 'package:origna_gta/features/products/add_product_viewmodel.dart';
import 'package:origna_gta/features/seller/warehouses_viewmodel.dart';

part 'parts/product_form_helper_widgets.dart';
part 'parts/addproduct_form_widgets.dart';
part 'parts/addproduct_basic_info_section.dart';
part 'parts/addproduct_delivery_section.dart';
part 'parts/addproduct_package_location_section.dart';
part 'parts/addproduct_supplier_section.dart';
part 'parts/addproduct_submit_section.dart';
part 'parts/addproduct_form_content_section.dart';
part 'parts/addproduct_delivery_children_section.dart';
part 'parts/addproduct_supplier_children_section.dart';
part 'parts/addproduct_chrome_section.dart';

/// Documentation for AddProductScreen
class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _compareAtPriceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _streetController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  final _minOrderController = TextEditingController(text: '1');
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _taxCodeController = TextEditingController();

  // Bill 96: French translation controllers
  final _nameFController = TextEditingController();
  final _descriptionFController = TextEditingController();

  // Supplier Info Controllers
  final _costController = TextEditingController();
  final _supplierSkuController = TextEditingController();
  final _sellerSkuController = TextEditingController();
  final _supplierUrlController = TextEditingController();
  final _supplierShippingDaysController = TextEditingController(text: '7-15');
  final _supplierNotesController = TextEditingController();
  final _customSupplierNameController = TextEditingController();

  // Inventory Config
  final _lowStockThresholdController = TextEditingController(text: '5');

  final _standardDaysController = TextEditingController(text: '5');
  final _standardPriceController = TextEditingController(text: '0.00');
  final _expressDaysController = TextEditingController(text: '2');
  final _expressPriceController = TextEditingController(text: '9.99');
  final _sameDayPriceController = TextEditingController(text: '14.99');

  // Quantity-based shipping discount controllers
  final _shippingDiscount3Controller = TextEditingController();
  final _shippingDiscount5Controller = TextEditingController();
  final _additionalItemCostController = TextEditingController(text: '0.00');
  final _maxItemsPerShipmentController = TextEditingController(text: '0');

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  ProviderSubscription<AddProductState>? _addProductSubscription;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addProductViewModelProvider);
    final viewModel = ref.read(addProductViewModelProvider.notifier);

    final maxWidth = ResponsiveBreakpoints.getValue<double>(
      context: context,
      mobile: double.infinity,
      mobilePlus: 540,
      tablet: 640,
      desktop: 720,
    );

    return Scaffold(
      backgroundColor: DesignTokens.surface,
      body: Stack(
        children: [
          // Gradient header background
          _buildGradientHeader(),
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(state),
                // Scrollable form
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Form(
                            key: _formKey,
                            autovalidateMode: state.hasAttemptedSubmit
                                ? AutovalidateMode.onUserInteraction
                                : AutovalidateMode.disabled,
                            child: _buildFormContent(state, viewModel),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _addProductSubscription?.close();
    _fadeController.dispose();
    _nameController.dispose();
    _nameFController.dispose();
    _descriptionController.dispose();
    _descriptionFController.dispose();
    _priceController.dispose();
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
    _compareAtPriceController.dispose();
    _taxCodeController.dispose();
    _minOrderController.dispose();
    _standardDaysController.dispose();
    _standardPriceController.dispose();
    _expressDaysController.dispose();
    _expressPriceController.dispose();
    _sameDayPriceController.dispose();
    _costController.dispose();
    _supplierSkuController.dispose();
    _sellerSkuController.dispose();
    _supplierUrlController.dispose();
    _supplierShippingDaysController.dispose();
    _supplierNotesController.dispose();
    _customSupplierNameController.dispose();
    _lowStockThresholdController.dispose();
    _shippingDiscount3Controller.dispose();
    _shippingDiscount5Controller.dispose();
    _additionalItemCostController.dispose();
    _maxItemsPerShipmentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _addProductSubscription = ref.listenManual(addProductViewModelProvider, (
      previous,
      next,
    ) {
      if (!mounted || previous?.isSuccess == true) return;
      if (next.isSuccess) {
        _onSuccess();
      } else if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: const Key('addproduct_error_snackbar'),
            content: Text(next.errorMessage!),
            backgroundColor: DesignTokens.error,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _shippingDiscount3Controller.addListener(_validateDiscountTiers);
    _shippingDiscount5Controller.addListener(_validateDiscountTiers);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // PROD-C1: reset text controllers when re-entering the screen after a previous success.
      final currentState = ref.read(addProductViewModelProvider);
      if (currentState.isSuccess) {
        _resetControllers();
      }
      ref.read(addProductViewModelProvider.notifier).resetIfSuccess();
    });
  }
}
