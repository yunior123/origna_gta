import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/products/product_rating_viewmodel.dart';

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
      title: const Text('Rate Product'),
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
          const Text('How would you rate this product?', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          _buildStarRating(),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _getRatingText(),
              style: TextStyle(color: _selectedRating > 0 ? Colors.amber[700] : Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      actions: [
        Semantics(
          button: true,
          label: 'Cancel rating',
          child: TextButton(onPressed: _isSubmitting ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ),
        Semantics(
          button: true,
          label: 'Submit rating',
          child: ElevatedButton(
          onPressed: (_selectedRating == 0 || _isSubmitting) ? null : _submitRating,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667EEA), foregroundColor: Colors.white),
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Submit'),
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
          label: 'Rate $starNumber out of 5 stars',
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedRating = starNumber);
            },
            child: Padding(
              padding: const EdgeInsets.all(4), // WCAG 2.5.8: 4+40+4=48dp touch target
              child: Icon(starNumber <= _selectedRating ? Icons.star : Icons.star_border, color: Colors.amber[700], size: 40),
            ),
          ),
        );
      }),
    );
  }

  String _getRatingText() {
    switch (_selectedRating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap a star to rate';
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
      messenger.showSnackBar(const SnackBar(content: Text('Thank you for your rating!'), backgroundColor: Colors.green));
      widget.onRatingSubmitted?.call();
    } else {
      final error = ref.read(productRatingViewModelProvider).errorMessage ?? 'Error submitting rating';
      messenger.showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      setState(() => _isSubmitting = false);
    }
  }
}
