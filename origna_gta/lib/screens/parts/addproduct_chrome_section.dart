part of '../addproduct_screen.dart';

// ============================================================================
// CHROME — Gradient header, top bar, success handler, validators
// ============================================================================

extension _AddProductChromeSection on _AddProductScreenState {
  Widget _buildGradientHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 200,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              DesignTokens.gradientStart,
              DesignTokens.gradientMiddle,
              DesignTokens.gradientEnd,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignTokens.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: -40,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignTokens.white.withValues(alpha: 0.04),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(AddProductState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            key: const Key('addproduct_back_button'),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'product.go_back'.tr(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignTokens.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: DesignTokens.textOnPrimary,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Text(
              key: const Key('addproduct_screen_title'),
              'product.new_product'.tr(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: DesignTokens.textOnPrimary,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: DesignTokens.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                final isActive = i <= state.activeStep;
                return Container(
                  width: isActive ? 18 : 8,
                  height: 8,
                  margin: EdgeInsets.only(left: i > 0 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: isActive
                        ? DesignTokens.textOnPrimary
                        : DesignTokens.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _onSuccess() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('addproduct_success_snackbar'),
        content: Row(
          children: [
            Icon(
              Icons.hourglass_top_rounded,
              color: DesignTokens.textOnPrimary,
              size: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'product.under_review_title'.tr(),
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'product.under_review_subtitle'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      color: DesignTokens.textOnPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor:
            DesignTokens.warning, // FIX [LOW] Was hardcoded Color(0xFFF59E0B)
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
      ),
    );
    Navigator.pop(context);
  }

  /// PROD-C1: Clears all text controllers so the form is blank when re-entering after a successful submit.
  void _resetControllers() {
    _nameController.clear();
    _nameFController.clear();
    _descriptionController.clear();
    _descriptionFController.clear();
    _priceController.clear();
    _compareAtPriceController.clear();
    _categoryController.clear();
    _streetController.clear();
    _apartmentController.clear();
    _cityController.clear();
    _postalCodeController.clear();
    _stockController.text = '1';
    _minOrderController.text = '1';
    _weightController.clear();
    _lengthController.clear();
    _widthController.clear();
    _heightController.clear();
    _taxCodeController.clear();
    _costController.clear();
    _supplierSkuController.clear();
    _sellerSkuController.clear();
    _supplierUrlController.clear();
    _supplierShippingDaysController.text = '7-15';
    _supplierNotesController.clear();
    _customSupplierNameController.clear();
    _lowStockThresholdController.text = '5';
    _standardDaysController.text = '5';
    _standardPriceController.text = '0.00';
    _expressDaysController.text = '2';
    _expressPriceController.text = '9.99';
    _sameDayPriceController.text = '14.99';
    _shippingDiscount3Controller.clear();
    _shippingDiscount5Controller.clear();
    _additionalItemCostController.text = '0.00';
    _maxItemsPerShipmentController.text = '0';
    _ingredientsEnController.clear();
    _ingredientsFrController.clear();
    _storageEnController.clear();
    _storageFrController.clear();
    _bestBeforeDaysController.clear();
    _servingSizeAmountController.clear();
    _servingsPerContainerController.clear();
    _caloriesController.clear();
    _totalFatController.clear();
    _saturatedFatController.clear();
    _transFatController.clear();
    _cholesterolController.clear();
    _sodiumController.clear();
    _totalCarbController.clear();
    _fibreController.clear();
    _sugarsController.clear();
    _proteinController.clear();
    _vitaminAController.clear();
    _vitaminCController.clear();
    _calciumController.clear();
    _ironController.clear();
  }

  String? _validateCity(String? v) {
    if (v == null || v.trim().isEmpty) return 'common.required'.tr();
    if (v.trim().length < 2) return 'product.city_too_short'.tr();
    if (v.trim().length > 50) return 'product.city_too_long'.tr();
    return null;
  }

  void _validateDiscountTiers() {
    final d3 = double.tryParse(_shippingDiscount3Controller.text);
    final d5 = double.tryParse(_shippingDiscount5Controller.text);
    final hasError = d3 != null && d5 != null && d5 < d3;
    final state = ref.read(addProductViewModelProvider);
    if (hasError != state.discountTierError) {
      ref
          .read(addProductViewModelProvider.notifier)
          .setDiscountTierError(hasError);
    }
  }

  String? _validatePostalCode(String? v) {
    if (v == null || v.isEmpty) return 'common.required'.tr();
    final normalized = v.toUpperCase().replaceAll(' ', '').trim();
    final reg = RegExp(r'^[A-Z]\d[A-Z]\d[A-Z]\d$');
    if (!reg.hasMatch(normalized)) return 'product.invalid_postal'.tr();
    return null;
  }

  String? _validateStreet(String? v) {
    if (v == null || v.trim().isEmpty) return 'common.required'.tr();
    if (v.trim().length < 3) return 'product.street_too_short'.tr();
    if (v.trim().length > 100) return 'product.street_too_long'.tr();
    return null;
  }
}
