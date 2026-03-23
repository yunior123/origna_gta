# Dart Standards — origna_gta

## Freezed Model

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required String description,
    required int priceCents,          // Always int cents
    required String sellerId,
    required String categoryId,
    required String lifecycleStatus,  // draft|active|inactive|deleted
    required int stockQuantity,
    required int dateCreated,         // Unix timestamp
    @Default(false) bool isDigital,
    @Default(false) bool isPerishable,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
```

## ViewModel (AsyncNotifier)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/services/product_service.dart';

final productListProvider =
    AsyncNotifierProvider<ProductListViewModel, List<Product>>(
  ProductListViewModel.new,
);

class ProductListViewModel extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    return _fetchProducts();
  }

  Future<List<Product>> _fetchProducts({int offset = 0}) async {
    final service = ref.read(productServiceProvider);
    return service.getProducts(limit: 20, offset: offset);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchProducts());
  }
}
```

## Screen (Widget)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/utils/design_tokens.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);

    return Scaffold(
      backgroundColor: DesignTokens.darkBackground,
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            error.toString(),
            style: TextStyle(color: DesignTokens.error),
          ),
        ),
        data: (products) => ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Semantics(
              label: 'product-card-${product.id}',
              child: ProductCard(product: product),
            );
          },
        ),
      ),
    );
  }
}
```

## Service (Stateless)

```dart
import 'package:origna_gta/core/schema/schema_constants.dart';

final productServiceProvider = Provider<ProductService>((ref) {
  final sdk = ref.read(orignaBaseSdkProvider);
  return ProductService(sdk: sdk);
});

class ProductService {
  final OrignaBaseSDK sdk;

  const ProductService({required this.sdk});

  Future<List<Product>> getProducts({
    required int limit,
    required int offset,
  }) async {
    final result = await sdk.collection('products').get(
      where: {SchemaConstants.lifecycleStatus: 'active'},
      orderBy: SchemaConstants.dateCreated,
      limit: limit,
      offset: offset,
    );
    return result.fold(
      (error) => throw AppError(error.message),
      (docs) => docs.map((d) => Product.fromJson(d.data)).toList(),
    );
  }
}
```

## Money Display

```dart
/// Format cents to CAD display string
String formatCents(int cents) {
  return '\$${(cents / 100).toStringAsFixed(2)}';
}

// Usage
Text(
  formatCents(product.priceCents), // $75.00
  style: TextStyle(color: DesignTokens.textPrimary),
),
```

## Error Handling

```dart
try {
  await viewModel.placeOrder();
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order placed')),
    );
  }
} on AppError catch (e) {
  AppLogger.error('Order failed', error: e);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.userMessage)),
    );
  }
}
```

## Select for Performance

```dart
// GOOD — only rebuilds when name changes
final name = ref.watch(userProvider.select((u) => u.name));

// BAD — rebuilds on any user field change
final user = ref.watch(userProvider);
Text(user.name);
```

## Import Style

```dart
// CORRECT — package imports
import 'package:origna_gta/viewmodels/cart_viewmodel.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

// FORBIDDEN — relative imports
import '../viewmodels/cart_viewmodel.dart';
import '../../utils/design_tokens.dart';
```
