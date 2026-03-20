import 'package:origna_gta/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/qa/qa_provider.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:origna_gta/models/qa_model.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:origna_gta/widgets/modern_textfield.dart';
import 'package:origna_gta/widgets/premium_paywall_widget.dart';

/// Q&A section for product detail page.
class QASection extends ConsumerStatefulWidget {
  final String productId;
  final String sellerId;

  const QASection({super.key, required this.productId, required this.sellerId});

  @override
  ConsumerState<QASection> createState() => _QASectionState();
}

class _QASectionState extends ConsumerState<QASection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final qaAsync = ref.watch(qaListProvider(widget.productId));
    final currentUserId = ref.watch(userIdProvider);
    final isSeller = currentUserId == widget.sellerId;
    final isPremium =
        ref
            .watch(subscriptionStreamProvider)
            .whenOrNull(data: (s) => s?.isPremium) ??
        false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'qa.title'.tr(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? DesignTokens.white : DesignTokens.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        qaAsync.when(
          data: (qaList) {
            if (qaList.isEmpty) {
              return _emptyState(context, currentUserId, isSeller, isPremium);
            }

            final displayList = _showAll ? qaList : qaList.take(3).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...displayList.map(
                  (qa) => _QACard(
                    qa: qa,
                    productId: widget.productId,
                    sellerId: widget.sellerId,
                    currentUserId: currentUserId,
                  ),
                ),
                if (qaList.length > 3 && !_showAll)
                  TextButton(
                    onPressed: () => setState(() => _showAll = true),
                    style: TextButton.styleFrom(
                        foregroundColor: DesignTokens.primary),
                    child: Text(
                      'qa.see_all'.tr(
                        namedArgs: {'count': qaList.length.toString()},
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (!isSeller && currentUserId != null)
                  ModernButton(
                    label: 'qa.ask_question'.tr(),
                    icon:
                        isPremium ? Icons.help_outline : Icons.lock_rounded,
                    isPrimary: isPremium,
                    isOutlined: !isPremium,
                    onPressed: () => isPremium
                        ? _showAskDialog(context)
                        : _showPremiumPaywall(context),
                  )
                else if (currentUserId == null)
                  Center(
                    child: Text(
                      'qa.sign_in_to_ask'.tr(),
                      style: const TextStyle(
                          color: DesignTokens.textSecondary),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: ModernLoadingIndicator()),
          error: (e, _) => Text(
            'errors.something_went_wrong'.tr(),
            style: const TextStyle(color: DesignTokens.error),
          ),
        ),
      ],
    );
  }

  Widget _emptyState(
    BuildContext context,
    String? currentUserId,
    bool isSeller,
    bool isPremium,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? DesignTokens.darkSurface
            : DesignTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.forum_outlined,
            size: 48,
            color: DesignTokens.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            'qa.no_questions'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: DesignTokens.textSecondary),
          ),
          if (!isSeller && currentUserId != null) ...[
            const SizedBox(height: 16),
            ModernButton(
              label: 'qa.ask_question'.tr(),
              icon: isPremium ? Icons.help_outline : Icons.lock_rounded,
              isPrimary: isPremium,
              isOutlined: !isPremium,
              onPressed: () => isPremium
                  ? _showAskDialog(context)
                  : _showPremiumPaywall(context),
            ),
          ] else if (currentUserId == null) ...[
            const SizedBox(height: 16),
            Text(
              'qa.sign_in_to_ask'.tr(),
              style: const TextStyle(
                color: DesignTokens.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAskDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('qa.ask_question'.tr()),
        content: ModernTextField(
          controller: controller,
          hint: 'qa.question_hint'.tr(),
          isMultiline: true,
          maxLines: 3,
          minLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
                foregroundColor: DesignTokens.textSecondary),
            child: Text('common.cancel'.tr()),
          ),
          ModernButton(
            label: 'qa.ask_question'.tr(),
            fullWidth: false,
            height: 40,
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              await ref
                  .read(qaControllerProvider.notifier)
                  .askQuestion(widget.productId, text);
              if (!mounted) return;
              final state = ref.read(qaControllerProvider);
              if (state.hasError) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(state.error.toString()),
                    backgroundColor: DesignTokens.error,
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                      content: Text('qa.question_submitted'.tr())),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showPremiumPaywall(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: PremiumPaywallWidget(
          featureName: 'subscription.ask_questions'.tr(),
        ),
      ),
    );
  }
}

/// Individual Q&A card with question, answer, and seller reply action.
class _QACard extends ConsumerWidget {
  final QAModel qa;
  final String productId;
  final String sellerId;
  final String? currentUserId;

  const _QACard({
    required this.qa,
    required this.productId,
    required this.sellerId,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSeller = currentUserId == sellerId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = DateFormat.yMMMd();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurface : DesignTokens.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.help_outline,
                size: 20,
                color: DesignTokens.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      qa.question,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'qa.asked_on'.tr(
                        namedArgs: {
                            'date': formatter.format(qa.createdAt)},
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: DesignTokens.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (qa.answer != null && qa.answer!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? DesignTokens.darkSurface
                    : DesignTokens.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      DesignTokens.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: DesignTokens.success,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'qa.answer_label'.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: DesignTokens.success,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(qa.answer!,
                            style: const TextStyle(fontSize: 15)),
                        if (qa.answeredAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${'qa.answered'.tr()} ${formatter.format(qa.answeredAt!)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: DesignTokens.textDisabled,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isSeller) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ModernButton(
                label: 'qa.your_answer'.tr(),
                icon: Icons.reply,
                isPrimary: false,
                isOutlined: true,
                fullWidth: false,
                height: 40,
                onPressed: () => _showAnswerDialog(context, ref),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAnswerDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('qa.your_answer'.tr()),
        content: ModernTextField(
          controller: controller,
          hint: 'qa.answer_hint'.tr(),
          isMultiline: true,
          maxLines: 3,
          minLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
                foregroundColor: DesignTokens.textSecondary),
            child: Text('common.cancel'.tr()),
          ),
          ModernButton(
            label: 'qa.submit_answer'.tr(),
            fullWidth: false,
            height: 40,
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(qaControllerProvider.notifier)
                    .answerQuestion(
                        qaId: qa.id, answer: controller.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('qa.answer_submitted'.tr())),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
