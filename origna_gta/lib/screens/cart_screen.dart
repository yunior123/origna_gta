import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/screens/cartitem_screen.dart';
import 'package:origna_gta/screens/checkout_screen.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';

/// Cart screen using optimized Riverpod patterns
/// - Main screen only watches cart item IDs (lightweight)
/// - Each cart item widget watches its own data via family provider
/// - Summary widget only watches what it needs
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        appBar: AppBarFactory.simple(title: 'Shopping Cart'),
        body: const AnimatedEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Sign in to view cart',
          subtitle: 'Your cart items will be saved to your account.',
        ),
      );
    }

    // Use select to only rebuild when product IDs change (not quantities)
    final productIdsAsync = ref.watch(
      cartItemsProvider.select(
        (async) =>
            async.whenData((items) => items.map((i) => i.productId).toList()),
      ),
    );

    return Scaffold(
      appBar: AppBarFactory.simple(title: 'Shopping Cart'),
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: DesignTokens.backgroundGradient(isDark: isDark),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: productIdsAsync.when(
              loading: () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            DesignTokens.primary.withValues(alpha: 0.15),
                            DesignTokens.secondary.withValues(alpha: 0.15),
                          ],
                        ),
                      ),
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) =>
                              DesignTokens.primaryGradient.createShader(bounds),
                          child: const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading cart...',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              error: (error, stack) => AnimatedEmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Unable to load cart',
                subtitle: '$error',
              ),
              data: (productIds) {
                if (productIds.isEmpty) {
                  return AnimatedEmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Your cart is empty',
                    subtitle: 'Looks like you haven\'t added any items yet.',
                    action: SizedBox(
                      width: 200,
                      child: ModernButton(
                        label: 'Start Shopping',
                        icon: Icons.arrow_back,
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.of(
                              context,
                            ).pushNamedAndRemoveUntil('/', (route) => false);
                          }
                        },
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: productIds.length,
                        itemBuilder: (context, index) {
                          final productId = productIds[index];
                          return FadeSlideIn(
                            delay: Duration(milliseconds: 50 * index),
                            child: _CartItemWidget(
                              key: ValueKey(productId),
                              productId: productId,
                            ),
                          );
                        },
                      ),
                    ),
                    FadeSlideIn(
                      delay: Duration(milliseconds: 50 * productIds.length),
                      beginOffset: const Offset(0, 0.2),
                      child: const _CartSummary(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual cart item widget - only rebuilds when THIS item's data changes
class _CartItemWidget extends ConsumerWidget {
  final String productId;

  const _CartItemWidget({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch only this specific item's details via family provider
    final itemAsync = ref.watch(cartItemDetailProvider(productId));

    return itemAsync.when(
      loading: () => Container(
        margin: const EdgeInsets.only(bottom: DesignTokens.spacing12),
        padding: const EdgeInsets.all(DesignTokens.spacing12),
        height: 104,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? DesignTokens.darkCard
              : Colors.white,
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
              ),
            ),
            const SizedBox(width: DesignTokens.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
      data: (item) {
        if (item == null) return const SizedBox.shrink();
        return CartItemScreen(
          productId: productId,
          item: item.toMap(),
          onRemove: () =>
              ref.read(cartControllerProvider).removeFromCart(productId),
        );
      },
    );
  }
}

/// Cart summary - only watches what it needs for display
class _CartSummary extends ConsumerWidget {
  const _CartSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch only if cart is empty (for visibility logic)
    final isEmpty = ref.watch(
      cartWithDetailsProvider.select(
        (async) => async.whenData((items) => items.isEmpty),
      ),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isEmpty.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (isEmpty) {
        if (isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacing16,
            vertical: DesignTokens.spacing20,
          ),
          decoration: BoxDecoration(
            color: isDark ? DesignTokens.darkCard : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : DesignTokens.outline.withValues(alpha: 0.3),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.primary.withValues(
                  alpha: isDark ? 0.1 : 0.06,
                ),
                blurRadius: 20,
                offset: const Offset(0, -8),
              ),
            ],
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(DesignTokens.radius24),
            ),
          ),
          child: Column(
            children: [
              const _CartTotalDisplay(),
              const SizedBox(height: DesignTokens.spacing20),
              const _CheckoutButton(),
            ],
          ),
        );
      },
    );
  }
}

/// Cart total display with info icons and delivery instructions
class _CartTotalDisplay extends ConsumerWidget {
  const _CartTotalDisplay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deliveryInstructions = ref.watch(deliveryInstructionsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.primary.withValues(alpha: 0.08),
            DesignTokens.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(
          color: DesignTokens.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtotal row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[900],
                ),
              ),
              // Only this Consumer rebuilds when the subtotal value changes
              Consumer(
                builder: (context, ref, _) {
                  final subtotalAsync = ref.watch(
                    cartWithDetailsProvider.select(
                      (async) => async.whenData(
                        (items) => items.fold(
                          0.0,
                          (total, item) => total + (item.price * item.quantity),
                        ),
                      ),
                    ),
                  );
                  return subtotalAsync.when(
                    loading: () => const SizedBox(width: 100, height: 28),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (subtotal) => ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [DesignTokens.primary, DesignTokens.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        NumberFormat.currency(
                          locale: "en_CA",
                          symbol: "CAD \$",
                        ).format(subtotal),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Service fees row with info icon
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: DesignTokens.info.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Frais de service',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ),
              Text(
                '${(BusinessRules.platformFeePercent * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 4),
              Tooltip(
                message:
                    'Frais de plateforme de ${(BusinessRules.platformFeePercent * 100).toStringAsFixed(1)}% pour maintenir le service sécurisé et fiable.',
                child: InkWell(
                  onTap: () => _showInfoSheet(
                    context,
                    'Frais de Service',
                    'Une commission de ${(BusinessRules.platformFeePercent * 100).toStringAsFixed(1)}% est appliquée sur chaque transaction pour couvrir:\n\n'
                        '• Paiements sécurisés via Stripe\n'
                        '• Protection acheteur et vendeur\n'
                        '• Infrastructure technique\n'
                        '• Support client\n\n'
                        'Ce montant est déduit automatiquement du paiement au vendeur.',
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: DesignTokens.info.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Tax estimate row with info icon
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 16,
                color: Colors.orange.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Estimation taxes et frais',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ),
              Tooltip(
                message:
                    'Les taxes (GST/HST/PST) seront calculées lors du paiement selon votre province.',
                child: InkWell(
                  onTap: () => _showInfoSheet(
                    context,
                    'Estimation des Taxes',
                    'Les taxes sont calculées automatiquement lors du paiement en fonction de:\n\n'
                        '• Votre province de livraison\n'
                        '• Le type de produits (certaines catégories sont exonérées)\n\n'
                        'Taxes applicables:\n'
                        '• GST (5%) : Toutes les provinces\n'
                        '• PST (6-7%) : BC, MB, SK\n'
                        '• QST (9.975%) : QC\n'
                        '• HST (13-15%) : ON (13%), NS (14%), NB, NL, PE (15%)\n\n'
                        'Les produits pour enfants et certaines denrées alimentaires peuvent être exonérés de PST selon la province.',
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: DesignTokens.info.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Delivery instructions row with pencil icon
          InkWell(
            onTap: () => _showDeliveryInstructionsDialog(
              context,
              ref,
              deliveryInstructions,
            ),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: deliveryInstructions.isNotEmpty
                      ? DesignTokens.primary.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_note_outlined,
                    size: 20,
                    color: deliveryInstructions.isNotEmpty
                        ? DesignTokens.primary
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instructions de livraison',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                        ),
                        if (deliveryInstructions.isNotEmpty)
                          Text(
                            deliveryInstructions,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          )
                        else
                          Text(
                            'Ajouter des instructions (optionnel)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoSheet(BuildContext context, String title, String content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: DesignTokens.info,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Compris', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeliveryInstructionsDialog(
    BuildContext context,
    WidgetRef ref,
    String currentInstructions,
  ) {
    final controller = TextEditingController(text: currentInstructions);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? DesignTokens.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit_note_outlined, color: DesignTokens.primary),
            const SizedBox(width: 12),
            const Text('Instructions de livraison'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajoutez des instructions spéciales pour la livraison (optionnel) :',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText:
                    "Ex: Laissez le colis sur le porche\nSonner à l'interphone, appartement 12\nLivraison après 14h uniquement",
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: DesignTokens.primary),
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey[50],
              ),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(deliveryInstructionsProvider.notifier).state = controller
                  .text
                  .trim();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

/// Checkout button - static widget, reads cart data lazily on press
class _CheckoutButton extends ConsumerWidget {
  const _CheckoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ModernButton(
      label: 'Proceed to Checkout',
      onPressed: () {
        final cartDetails = ref.read(cartWithDetailsProvider);
        cartDetails.whenData((itemsWithDetails) {
          if (itemsWithDetails.isEmpty) return;
          final subtotal = itemsWithDetails.fold(
            0.0,
            (total, item) => total + (item.price * item.quantity),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CheckoutScreen(items: itemsWithDetails, total: subtotal),
            ),
          );
        });
      },
      fullWidth: true,
      icon: Icons.payment,
    );
  }
}

/// Extension to add copyWith method to CartItemDetailModel
extension CartItemDetailModelExtension on CartItemDetailModel {
  CartItemDetailModel copyWith({
    String? productId,
    String? name,
    String? description,
    double? price,
    List<String>? imageUrls,
    int? quantity,
    dynamic createdAt,
    Address? sellerAddress,
    String? sellerId,
    String? deliveryStatus,
    bool? isDigital,
  }) {
    return CartItemDetailModel(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrls: imageUrls ?? this.imageUrls,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      sellerAddress: sellerAddress ?? this.sellerAddress,
      sellerId: sellerId ?? this.sellerId,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      isDigital: isDigital ?? this.isDigital,
    );
  }
}
