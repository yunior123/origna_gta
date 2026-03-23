import 'package:origna_gta/utils/constants.dart';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/features/products/product_detail_viewmodel.dart';
import 'package:origna_gta/features/products/review_eligibility_provider.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:origna_gta/widgets/rating_dialog.dart';
import 'package:origna_gta/widgets/rating_histogram.dart';
import 'package:origna_gta/widgets/modern_skeleton_loader.dart';

/// Reviews section with histogram, review cards, write-a-review button,
/// and helpfulness voting.
class ReviewsSection extends ConsumerWidget {
  final String productId;
  final String productName;
  final int ratingCount;
  final double averageRating;
  final AsyncValue<List<Map<String, dynamic>>> ratingsAsync;
  final VoidCallback? onRetry;

  const ReviewsSection({
    super.key,
    required this.productId,
    required this.productName,
    required this.ratingCount,
    required this.averageRating,
    required this.ratingsAsync,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final eligibilityAsync = ref.watch(reviewEligibilityProvider(productId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'product.reviews_title'.tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? DesignTokens.white : DesignTokens.textPrimary,
                ),
              ),
            ),
            _WriteReviewButton(
              productId: productId,
              productName: productName,
              eligibilityAsync: eligibilityAsync,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ratingsAsync.when(
          data: (ratings) {
            if (ratingCount == 0 && ratings.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? DesignTokens.darkSurface
                      : DesignTokens.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DesignTokens.outlineVariant),
                ),
                child: Center(
                  child: Text(
                    'product.no_reviews_yet'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: DesignTokens.textSecondary),
                  ),
                ),
              );
            }

            final counts = List<int>.filled(5, 0);
            for (final r in ratings) {
              final star = (r[Fields.rating] as num?)?.toInt() ?? 0;
              if (star >= 1 && star <= 5) counts[5 - star]++;
            }
            final total = ratingCount > 0 ? ratingCount : ratings.length;
            final canRenderHistogram =
                ratingCount <= ratings.length || ratingCount <= 10;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if ((ratingCount > 0 || ratings.isNotEmpty) &&
                    canRenderHistogram)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: RatingHistogram(counts: counts, total: total),
                  ),
                ...ratings.map(
                  (review) => ReviewCard(review: review, productId: productId),
                ),
                if (ratings.isEmpty && ratingCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      (ratingCount == 1
                              ? 'product.ratings_no_text_one'
                              : 'product.ratings_no_text_other')
                          .tr(namedArgs: {'count': '$ratingCount'}),
                      style: TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: ModernLoadingIndicator()),
          error: (e, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? DesignTokens.darkSurface : DesignTokens.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DesignTokens.outlineVariant),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'product.reviews_load_error'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onRetry,
                  child: Text('common.retry'.tr()),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Individual review card with stars, text, photos, seller reply, and helpfulness voting.
class ReviewCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> review;
  final String productId;

  const ReviewCard({super.key, required this.review, required this.productId});

  @override
  ConsumerState<ReviewCard> createState() => _ReviewCardState();
}

/// Private provider for ReviewCard helpful vote loading state
final _votingHelpfulProvider = StateProvider.autoDispose<bool>((_) => false);

class _ReviewCardState extends ConsumerState<ReviewCard> {
  DateTime? _parseCreatedAt(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) {
      final millis = value > 1000000000000 ? value : value * 1000;
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    if (value is num) {
      final millis = value > 1000000000000
          ? value.toInt()
          : (value * 1000).toInt();
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPremium =
        ref
            .watch(subscriptionStreamProvider)
            .whenOrNull(data: (s) => s?.isPremium) ??
        false;
    final review = widget.review;
    final ratingId = review[Fields.ratingId] as String? ?? '';
    final comment = review[Fields.review] as String? ?? '';
    final starValue = (review[Fields.rating] as num?)?.toInt() ?? 0;
    final helpfulCount = (review[Fields.helpfulCount] as num?)?.toInt() ?? 0;
    final sellerReply = review[Fields.sellerReply] as String?;
    final userId = review[Fields.userId] as String? ?? '';
    final reviewer = userId.length > 8 ? userId.substring(0, 8) : userId;
    final reviewerLabel = reviewer.isNotEmpty
        ? 'User ${reviewer.toUpperCase()}'
        : 'Anonymous';
    final createdAt = _parseCreatedAt(review[Fields.createdAt]);
    final isVerified = review[Fields.verifiedPurchase] as bool? ?? false;
    final photoUrls =
        (review[Fields.reviewImageUrls] as List?)
            ?.whereType<String>()
            .toList() ??
        <String>[];

    if (comment.isEmpty && sellerReply == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurface : DesignTokens.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: DesignTokens.primary.withValues(alpha: 0.15),
                child: Text(
                  reviewerLabel.isNotEmpty
                      ? reviewerLabel[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: DesignTokens.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewerLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (createdAt != null)
                      Text(
                        DateFormat.yMMMd().format(createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: DesignTokens.textDisabled,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < starValue
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 14,
                    color: DesignTokens.warning,
                  ),
                ),
              ),
            ],
          ),

          // Verified purchase
          if (isVerified) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 14,
                  color: DesignTokens.success,
                ),
                const SizedBox(width: 4),
                Text(
                  'product.verified_purchase'.tr(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.success,
                  ),
                ),
              ],
            ),
          ],

          // Photo row
          if (photoUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            Stack(
              children: [
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photoUrls.length,
                    separatorBuilder: (context, i) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) => GestureDetector(
                      onTap: isPremium
                          ? () =>
                                _showReviewPhotoDialog(context, photoUrls, idx)
                          : null,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: photoUrls[idx],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) =>
                              ModernSkeletonLoader.imagePlaceholder(
                                width: 80,
                                height: 80,
                              ),
                          errorWidget: (ctx, url, err) => Container(
                            width: 80,
                            height: 80,
                            color: DesignTokens.outlineVariant,
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isPremium)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Container(
                          color: DesignTokens.black.withValues(alpha: 0.45),
                          child: Center(
                            child: GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.subscription,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.lock_rounded,
                                    color: DesignTokens.white,
                                    size: 20,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'subscription.premium_label'.tr(),
                                    style: const TextStyle(
                                      color: DesignTokens.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],

          // Review text
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(comment, style: const TextStyle(fontSize: 14, height: 1.5)),
          ],

          // Seller reply
          if (sellerReply != null && sellerReply.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? DesignTokens.black.withValues(alpha: 0.3)
                    : DesignTokens.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: DesignTokens.digital.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'product.seller_response'.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: DesignTokens.digital,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sellerReply,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],

          // Helpfulness voting
          if (ratingId.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'product.helpful_question'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: DesignTokens.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                ref.watch(_votingHelpfulProvider)
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ModernLoadingIndicator(
                          size: 14,
                          strokeWidth: 2,
                          color: DesignTokens.primary,
                          centered: false,
                        ),
                      )
                    : TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          foregroundColor: DesignTokens.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _voteHelpful(ratingId, true),
                        child: Text(
                          'product.helpful_yes_count'.tr(
                            namedArgs: {'count': '$helpfulCount'},
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showReviewPhotoDialog(
    BuildContext context,
    List<String> urls,
    int initialIndex,
  ) {
    showDialog(
      context: context,
      barrierColor: DesignTokens.textPrimary,
      builder: (_) => Dialog(
        backgroundColor: DesignTokens.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: urls.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (_, i) => InteractiveViewer(
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: urls[i],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                    placeholder: (ctx, url) =>
                        ModernSkeletonLoader.imagePlaceholder(),
                    errorWidget: (ctx, url, err) => const Icon(
                      Icons.image_not_supported,
                      size: 100,
                      color: DesignTokens.white,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: DesignTokens.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  tooltip: 'common.close'.tr(),
                  icon: const Icon(
                    Icons.close,
                    color: DesignTokens.white,
                    size: 28,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _voteHelpful(String ratingId, bool helpful) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) showLoginPrompt(context);
      return;
    }
    ref.read(_votingHelpfulProvider.notifier).state = true;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(productDetailViewModelProvider.notifier)
          .voteHelpful(ratingId, widget.productId, helpful);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('product.helpful_vote_thanks'.tr()),
            backgroundColor: DesignTokens.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('product.helpful_vote_error'.tr()),
            backgroundColor: DesignTokens.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) ref.read(_votingHelpfulProvider.notifier).state = false;
    }
  }
}

/// "Write a Review" button — visible only for buyers who purchased the product
/// and haven't already reviewed it.
class _WriteReviewButton extends ConsumerWidget {
  final String productId;
  final String productName;
  final AsyncValue<ReviewEligibility> eligibilityAsync;

  const _WriteReviewButton({
    required this.productId,
    required this.productName,
    required this.eligibilityAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return eligibilityAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (eligibility) {
        if (eligibility.alreadyReviewed) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: DesignTokens.success,
              ),
              const SizedBox(width: 4),
              Text(
                'product.already_reviewed'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  color: DesignTokens.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        }

        if (!eligibility.canReview) return const SizedBox.shrink();

        return Semantics(
          button: true,
          label: 'btn-write-review',
          child: TextButton.icon(
            onPressed: () => showRatingDialog(
              context: context,
              orderId: eligibility.eligibleOrderId!,
              productId: productId,
              productName: productName,
              onRatingSubmitted: () {
                ref.invalidate(reviewEligibilityProvider(productId));
              },
            ),
            icon: const Icon(Icons.rate_review_outlined, size: 18),
            label: Text('product.write_a_review'.tr()),
            style: TextButton.styleFrom(
              foregroundColor: DesignTokens.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}
