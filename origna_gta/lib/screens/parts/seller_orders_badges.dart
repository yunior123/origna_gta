part of '../seller_orders_screen.dart';

// U-03: Badge widget showing unanswered Q&A count for the seller
class _UnansweredQaBadge extends ConsumerWidget {
  final String sellerId;
  const _UnansweredQaBadge({required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count =
        ref.watch(
          sellerUnansweredQaProvider(sellerId).select((a) => a.valueOrNull),
        ) ??
        0;

    return Tooltip(
      message: count > 0
          ? 'seller.unanswered_questions_plural'.tr(args: [count.toString()])
          : 'seller.no_pending_questions'.tr(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Semantics(
            button: true,
            label: 'btn-unanswered-questions',
            child: IconButton(
              icon: const Icon(Icons.forum_outlined),
              tooltip: count > 0
                  ? 'seller.unanswered_questions_plural'.tr(
                      args: [count.toString()],
                    )
                  : 'seller.no_pending_questions'.tr(),
              onPressed: () =>
                  appPushNamed(context, AppRoutes.sellerProducts),
            ),
          ),
          if (count > 0)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: DesignTokens.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: DesignTokens.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: DesignTokens.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
