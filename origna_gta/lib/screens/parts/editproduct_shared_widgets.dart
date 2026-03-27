part of '../editproduct_screen.dart';

// ============================================================================
// SHARED WIDGETS — Section title, info hint, URL field, info sheet, validation,
//                  approval banner, address suggestions, image grid
// ============================================================================

extension _EditProductSharedWidgets on _EditProductScreenState {
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: DesignTokens.primary,
        ),
      ),
    );
  }

  Widget _buildTappableInfoHint(String shortText, String title, String body) {
    return Semantics(
      button: true,
      label: 'btn-info-hint',
      child: GestureDetector(
        onTap: () => _showInfoSheet(title, body),
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: DesignTokens.info.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  shortText,
                  style: TextStyle(
                    fontSize: 11,
                    color: DesignTokens.textSecondary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: DesignTokens.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editUrlField({
    Key? key,
    required String label,
    required TextEditingController controller,
    required void Function(String) onChanged,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        label: 'input-edit-product-url',
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          keyboardType: TextInputType.url,
          onChanged: onChanged,
        ),
      ),
    );
  }

  String? _validatePostalCode(String? v) {
    if (v == null || v.isEmpty) return 'common.required'.tr();
    final reg = RegExp(r'^[A-Z]\d[A-Z] \d[A-Z]\d$');
    if (!reg.hasMatch(v.toUpperCase().trim())) {
      return 'product.invalid_postal'.tr();
    }
    return null;
  }

  Widget _buildApprovalStatusBanner() {
    final status = widget.product.lifecycleStatus;
    final reason = widget.product.approvalRejectionReason;
    if (status == ProductLifecycleStatusValues.active ||
        status == ProductLifecycleStatusValues.approved) {
      return const SizedBox.shrink();
    }

    Color bgColor;
    Color textColor;
    IconData icon;
    String title;
    String subtitle = '';

    if (status == ProductLifecycleStatusValues.rejected) {
      bgColor = DesignTokens.error.withValues(alpha: 0.10);
      textColor = DesignTokens.error;
      icon = Icons.cancel_rounded;
      title = 'product.approval_rejected_title'.tr();
      subtitle = reason ?? 'product.approval_rejected_generic'.tr();
    } else {
      bgColor = DesignTokens.warning.withValues(alpha: 0.12);
      textColor = DesignTokens.warningText;
      icon = Icons.hourglass_top_rounded;
      title = 'product.under_review_title'.tr();
      subtitle = 'product.under_review_edit_note'.tr();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    fontSize: 13,
                  ),
                ),
                ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: textColor, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSuggestions(
    EditProductState state,
    EditProductViewModel viewModel,
  ) {
    return Card(
      child: Column(
        children: state.addressSuggestions.map((s) {
          final props = s['properties'] ?? {};
          return ListTile(
            title: Text((props['formatted'] as String?) ?? ''),
            onTap: () {
              viewModel.selectAddress(s);
              _streetController.text =
                  (props['street'] as String?) ??
                  (props['formatted'] as String?) ??
                  '';
              _cityController.text = (props['city'] as String?) ?? '';
              _postalCodeController.text = (props['postcode'] as String?) ?? '';
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildImageGrid(
    EditProductState state,
    EditProductViewModel viewModel,
  ) {
    if (state.existingImageUrls.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.existingImageUrls.length,
        itemBuilder: (context, index) => Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(
                    state.existingImageUrls[index],
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 8,
              child: IconButton(
                icon: const Icon(
                  Icons.remove_circle,
                  color: DesignTokens.error,
                ),
                tooltip: 'product.remove_image'.tr(),
                onPressed: () => viewModel.removeExistingImage(index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoSheet(String title, String body) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DesignTokens.textOnPrimary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DesignTokens.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lightbulb_rounded,
                    color: DesignTokens.info,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.darkSurface,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'btn-close-info-sheet',
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: DesignTokens.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              body,
              style: TextStyle(
                fontSize: 14,
                color: DesignTokens.darkSurface.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Semantics(
                button: true,
                label: 'btn-edit-product-got-it',
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.primary,
                    foregroundColor: DesignTokens.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'common.got_it'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
