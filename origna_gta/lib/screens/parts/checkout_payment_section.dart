// coverage:ignore-file
part of '../checkout_screen.dart';
class _CheckoutButton extends ConsumerWidget {
  final List<CartItemDetailModel> items;
  final UserModel userModel;
  final double subtotal;
  final double total;

  const _CheckoutButton({required this.items, required this.userModel, required this.subtotal, required this.total});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref.watch(checkoutStateProvider.select((state) => state.isProcessing));
    final isCalculating = ref.watch(checkoutStateProvider.select((state) => state.isCalculatingShipping));
    final shippingError = ref.watch(checkoutStateProvider.select((state) => state.shippingError));
    final termsAccepted = ref.watch(checkoutTermsAcceptedProvider);
    final eulaAccepted = ref.watch(checkoutEulaAcceptedProvider);
    final ageVerifAccepted = ref.watch(checkoutAgeVerifAcceptedProvider);
    final hasDigitalItems = items.any((item) => item.isDigital);
    final hasAgeRestrictedItems = items.any((item) => item.isAgeRestricted);
    final isDisabled = isProcessing || isCalculating || shippingError != null || !termsAccepted || (hasDigitalItems && !eulaAccepted) || (hasAgeRestrictedItems && !ageVerifAccepted);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(
        ResponsiveBreakpoints.getSpacing(context, SpacingSize.md),
        12,
        ResponsiveBreakpoints.getSpacing(context, SpacingSize.md),
        ResponsiveBreakpoints.getSpacing(context, SpacingSize.md),
      ),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurface : DesignTokens.surface,
        border: Border(top: BorderSide(color: DesignTokens.primary.withValues(alpha: 0.15))),
        boxShadow: [BoxShadow(color: DesignTokens.black.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, -8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: 'btn-place-order',
            child: ModernButton(
              key: const Key('checkout_place_order_button'),
              label: isProcessing ? 'common.processing'.tr() : 'checkout.place_order'.tr(),
              onPressed: isDisabled ? null : () => _showOrderReview(context, ref),
              isLoading: isProcessing,
              icon: Icons.payment,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outlined, size: 12, color: DesignTokens.success.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Text(
                'checkout.secure_stripe'.tr(),
                style: TextStyle(fontSize: 11, color: DesignTokens.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOrderReview(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.transparent,
      builder: (_) => _OrderReviewSheet(
        items: items,
        subtotal: subtotal,
        onConfirm: () {
          Navigator.of(context).pop();
          _startCheckout(context, ref);
        },
      ),
    );
  }

  Future<void> _redirectToStripe(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (!await safeLaunchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('checkout.stripe_redirect_failed'.tr()),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'common.copy_link'.tr(),
            onPressed: () => Clipboard.setData(ClipboardData(text: url)),
          ),
        ),
      );
    }
  }

  Future<void> _startCheckout(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(checkoutStateProvider.notifier);

    final eulaAccepted = ref.read(checkoutEulaAcceptedProvider);
    final ageVerificationAccepted = ref.read(checkoutAgeVerifAcceptedProvider);
    final result = await notifier.startCheckout(items: items, user: userModel, subtotal: subtotal, eulaAccepted: eulaAccepted, ageVerificationAccepted: ageVerificationAccepted);
    if (!context.mounted) return;

    switch (result) {
      case CheckoutSuccess(:final checkoutUrl):
        // Persist terms acceptance server-side (fire-and-forget — never blocks checkout redirect)
        // Failures are reported to Sentry so compliance gaps are visible (PIPEDA / CASL audit trail).
        ref.read(userRepositoryProvider).recordTermsAcceptance().catchError((Object e, StackTrace st) {
          Sentry.captureException(e, stackTrace: st, hint: Hint.withMap({'context': 'recordTermsAcceptance at checkout'}));
        });
        await _redirectToStripe(checkoutUrl, context);
      case CheckoutError(:final message):
        messenger.showSnackBar(
          SnackBar(
            content: Text('checkout.checkout_error'.tr(namedArgs: {'message': message})),
            backgroundColor: DesignTokens.error,
            duration: const Duration(seconds: 5),
          ),
        );
      case CheckoutAlreadyProcessed(:final existingOrderId):
        messenger.showSnackBar(
          SnackBar(
            content: Text('checkout.order_already_exists'.tr(namedArgs: {'id': existingOrderId})),
            backgroundColor: DesignTokens.primary,
          ),
        );
    }
  }
}

class _CouponSection extends ConsumerStatefulWidget {
  final int subtotalCents;
  // AUDIT FIX (HIGH-C4): Pass seller IDs so seller-scoped coupon validation works
  final List<String> sellerIds;

  const _CouponSection({required this.subtotalCents, this.sellerIds = const []});

  @override
  ConsumerState<_CouponSection> createState() => _CouponSectionState();
}

class _CouponSectionState extends ConsumerState<_CouponSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final couponCode = ref.watch(checkoutStateProvider.select((s) => s.couponCode));
    final isLoading = ref.watch(checkoutStateProvider.select((s) => s.isCouponLoading));
    final isProcessing = ref.watch(checkoutStateProvider.select((s) => s.isProcessing));
    final couponError = ref.watch(checkoutStateProvider.select((s) => s.couponError));
    final notifier = ref.read(checkoutStateProvider.notifier);
    final applied = couponCode != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('checkout.coupon_title'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('checkout_coupon_field'),
                controller: _controller,
                enabled: !applied && !isLoading && !isProcessing,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'checkout.coupon_hint'.tr(),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? DesignTokens.darkCard : DesignTokens.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: DesignTokens.outline.withValues(alpha: 0.3))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: DesignTokens.outline.withValues(alpha: 0.3))),
                  errorText: couponError,
                  prefixIcon: const Icon(Icons.local_offer_outlined, size: 20),
                  suffixIcon: applied
                      ? Icon(Icons.check_circle, color: DesignTokens.success, size: 20)
                      : null,
                ),
                onSubmitted: (_) => _apply(notifier),
              ),
            ),
            const SizedBox(width: 10),
            applied
                ? TextButton(
                    onPressed: () {
                      _controller.clear();
                      notifier.removeCoupon();
                    },
                    child: Text('common.remove'.tr(), style: TextStyle(color: DesignTokens.error)),
                  )
                : SizedBox(
                    width: 100,
                    child: ModernButton(
                      key: const Key('checkout_apply_coupon_button'),
                      label: 'common.apply'.tr(),
                      height: 48,
                      isLoading: isLoading,
                      onPressed: (isLoading || isProcessing) ? null : () => _apply(notifier),
                    ),
                  ),
          ],
        ),
      ],
    );
  }

  void _apply(CheckoutNotifier notifier) {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    // AUDIT FIX (HIGH-C4): Pass sellerIds for server-side seller-scoped validation
    notifier.applyCoupon(code, widget.subtotalCents, sellerIds: widget.sellerIds);
  }
}

class _PaymentProviderSection extends StatelessWidget {
  final String selectedProvider;
  final ValueChanged<String> onChanged;

  const _PaymentProviderSection({required this.selectedProvider, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Stripe is the only integrated payment provider
    return Column(
      key: const Key('checkout_payment_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('checkout.payment_method_title'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [ChoiceChip(label: Text('payment.stripe'.tr()), selected: true, onSelected: (_) {})],
        ),
        const SizedBox(height: 8),
        Text('checkout.stripe_secure_notice'.tr(), style: TextStyle(color: DesignTokens.textSecondary, fontSize: 12)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: ['VISA', 'MC', 'AMEX', 'Apple Pay', 'Google Pay'].map((label) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: DesignTokens.outline),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DesignTokens.textSecondary)),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _BuyerProtectionBanner extends StatelessWidget {
  const _BuyerProtectionBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('checkout_buyer_protection_banner'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DesignTokens.success.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: DesignTokens.success, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'checkout.buyer_protection_title'.tr(),
                  style: TextStyle(color: DesignTokens.success, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'checkout.buyer_protection_message'.tr(),
                  style: TextStyle(color: DesignTokens.success.withValues(alpha: 0.85), fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 6),
                Semantics(
                  link: true,
                  label: 'link-buyer-protection',
                  child: GestureDetector(
                    onTap: () => safeLaunchUrl(Uri.parse(ExternalUrls.buyerProtectionUrl), mode: LaunchMode.externalApplication),
                    child: Text(
                      'checkout.buyer_protection_link'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: DesignTokens.success,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: DesignTokens.success,
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
}

class _SecurityInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('checkout_secure_badge'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DesignTokens.info.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, color: DesignTokens.info, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'checkout.secure_payment'.tr(),
                  style: TextStyle(color: DesignTokens.info, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text('checkout.stripe_secure'.tr(), style: TextStyle(color: DesignTokens.info.withValues(alpha: 0.8), fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FREE SHIPPING THRESHOLD BANNER
// ============================================================================

/// Shows "Spend $X.XX more for free shipping!" when subtotal is below the threshold.
/// Disappears when shipping is already free or the threshold is reached.
class _FreeShippingBanner extends ConsumerWidget {
  final double subtotal;

  const _FreeShippingBanner({required this.subtotal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shippingCost = ref.watch(checkoutStateProvider.select((s) => s.shippingCost));
    final isCalculating = ref.watch(checkoutStateProvider.select((s) => s.isCalculatingShipping));

    if (isCalculating || shippingCost == 0) return const SizedBox.shrink();

    const thresholdCents = BusinessRules.freeShippingThresholdCents;
    final subtotalCents = (subtotal * 100).round();
    final remainingCents = thresholdCents - subtotalCents;
    if (remainingCents <= 0) return const SizedBox.shrink();

    final remaining = remainingCents / 100.0;
    final progress = (subtotalCents / thresholdCents).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [DesignTokens.tertiary.withValues(alpha: 0.12), DesignTokens.success.withValues(alpha: 0.10)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.tertiary.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_outlined, size: 17, color: DesignTokens.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'checkout.free_shipping_banner'.tr(namedArgs: {'amount': '\$${remaining.toStringAsFixed(2)}'}),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DesignTokens.tertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: DesignTokens.outlineVariant,
              valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.tertiary),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

