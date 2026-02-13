import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/products/product_rating_viewmodel.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

/// Shows the rating dialog
Future<void> showRatingDialog({
  required BuildContext context,
  required String orderId,
  required String productId,
  required String productName,
  VoidCallback? onRatingSubmitted,
}) {
  return showDialog(
    context: context,
    builder: (context) => RatingDialog(orderId: orderId, productId: productId, productName: productName, onRatingSubmitted: onRatingSubmitted),
  );
}

class RatingDialog extends ConsumerStatefulWidget {
  final String orderId;
  final String productId;
  final String productName;
  final VoidCallback? onRatingSubmitted;

  const RatingDialog({super.key, required this.orderId, required this.productId, required this.productName, this.onRatingSubmitted});

  @override
  ConsumerState<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends ConsumerState<RatingDialog> {
  int _selectedRating = 0;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('rating.title'.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.productName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Text('rating.prompt'.tr(), style: const TextStyle(color: DesignTokens.textSecondary)),
          const SizedBox(height: 16),
          _buildStarRating(),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _getRatingText(),
              style: TextStyle(color: _selectedRating > 0 ? DesignTokens.warning : DesignTokens.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      actions: [
        Semantics(
          button: true,
          label: 'rating.cancel_label'.tr(),
          child: TextButton(onPressed: _isSubmitting ? null : () => Navigator.pop(context), child: Text('common.cancel'.tr())),
        ),
        Semantics(
          button: true,
          label: 'rating.submit_label'.tr(),
          child: ElevatedButton(
          onPressed: (_selectedRating == 0 || _isSubmitting) ? null : _submitRating,
          style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.primary, foregroundColor: Colors.white),
          child: _isSubmitting
              ? const ModernLoadingIndicator.small(color: Colors.white)
              : Text('common.submit'.tr()),
        ),
        ),
      ],
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        return Semantics(
          button: true,
          label: 'rating.star_label'.tr(namedArgs: {'count': starNumber.toString()}),
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedRating = starNumber);
            },
            child: Padding(
              padding: const EdgeInsets.all(4), // WCAG 2.5.8: 4+40+4=48dp touch target
              child: Icon(starNumber <= _selectedRating ? Icons.star : Icons.star_border, color: DesignTokens.warning, size: 40),
            ),
          ),
        );
      }),
    );
  }

  String _getRatingText() {
    switch (_selectedRating) {
      case 1:
        return 'rating.poor'.tr();
      case 2:
        return 'rating.fair'.tr();
      case 3:
        return 'rating.good'.tr();
      case 4:
        return 'rating.very_good'.tr();
      case 5:
        return 'rating.excellent'.tr();
      default:
        return 'rating.tap_to_rate'.tr();
    }
  }

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final viewModel = ref.read(productRatingViewModelProvider.notifier);
    final success = await viewModel.submitRating(widget.orderId, widget.productId, _selectedRating);

    if (!mounted) return;

    if (success) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text('rating.thank_you'.tr()), backgroundColor: DesignTokens.success));
      widget.onRatingSubmitted?.call();
    } else {
      final error = ref.read(productRatingViewModelProvider).errorMessage ?? 'rating.error_submitting'.tr();
      messenger.showSnackBar(SnackBar(content: Text(error), backgroundColor: DesignTokens.error));
      setState(() => _isSubmitting = false);
    }
  }
}
