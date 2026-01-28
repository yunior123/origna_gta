import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RatingDialog extends StatefulWidget {
  final String orderId;
  final String productId;
  final String productName;
  final VoidCallback? onRatingSubmitted;

  const RatingDialog({
    super.key,
    required this.orderId,
    required this.productId,
    required this.productName,
    this.onRatingSubmitted,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
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
          const Text(
            'How would you rate this product?',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _buildStarRating(),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _getRatingText(),
              style: TextStyle(
                color: _selectedRating > 0 ? Colors.amber[700] : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_selectedRating == 0 || _isSubmitting) ? null : _submitRating,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedRating = starNumber);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              starNumber <= _selectedRating ? Icons.star : Icons.star_border,
              color: Colors.amber[700],
              size: 40,
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

    try {
      final db = FirebaseFirestore.instance;

      await db.runTransaction((transaction) async {
        // Get current product data
        final productRef = db.collection('products').doc(widget.productId);
        final productDoc = await transaction.get(productRef);

        if (!productDoc.exists) {
          throw Exception('Product not found');
        }

        final productData = productDoc.data()!;
        final currentRating = (productData['rating'] ?? 0.0).toDouble();
        final currentCount = (productData['ratingCount'] ?? 0) as int;

        // Calculate new average rating
        // Formula: newRating = ((oldRating * oldCount) + newRating) / (oldCount + 1)
        final newCount = currentCount + 1;
        final newRating = ((currentRating * currentCount) + _selectedRating) / newCount;

        // Update product with new rating
        transaction.update(productRef, {
          'rating': newRating,
          'ratingCount': newCount,
        });

        // Store rating in order document to prevent double-rating
        final orderRef = db.collection('orders').doc(widget.orderId);
        transaction.update(orderRef, {
          'ratings.${widget.productId}': {
            'rating': _selectedRating,
            'ratedAt': FieldValue.serverTimestamp(),
          },
        });
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your rating!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onRatingSubmitted?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }
}

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
    builder: (context) => RatingDialog(
      orderId: orderId,
      productId: productId,
      productName: productName,
      onRatingSubmitted: onRatingSubmitted,
    ),
  );
}
