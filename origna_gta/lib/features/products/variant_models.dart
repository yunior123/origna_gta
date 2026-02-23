import 'package:flutter/foundation.dart';

/// A single product variant option (e.g. Size with values [S, M, L]).
@immutable
class VariantOption {
  final String name;
  final List<String> values;

  const VariantOption({required this.name, required this.values});

  factory VariantOption.fromMap(Map<String, dynamic> map) {
    return VariantOption(
      name: map['name'] as String,
      values: (map['values'] as List).cast<String>(),
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'values': values};

  VariantOption copyWith({String? name, List<String>? values}) {
    return VariantOption(name: name ?? this.name, values: values ?? this.values);
  }

  @override
  bool operator ==(Object other) => other is VariantOption && other.name == name && listEquals(other.values, values);

  @override
  int get hashCode => Object.hash(name, Object.hashAll(values));
}

/// A single product variant combination (e.g. Size=M + Color=Red).
@immutable
class ProductVariantEntry {
  static const _sentinel = Object();

  final Map<String, String> optionValues;
  final double? price;
  final int stockQuantity;
  final String? sku;
  final bool isActive;

  const ProductVariantEntry({
    required this.optionValues,
    this.price,
    this.stockQuantity = 0,
    this.sku,
    this.isActive = true,
  });

  factory ProductVariantEntry.fromMap(Map<String, dynamic> map) {
    return ProductVariantEntry(
      optionValues: (map['optionValues'] as Map).cast<String, String>(),
      price: (map['price'] as num?)?.toDouble(),
      stockQuantity: (map['stockQuantity'] as int?) ?? 0,
      sku: map['sku'] as String?,
      isActive: (map['isActive'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'optionValues': optionValues,
        'price': price,
        'stockQuantity': stockQuantity,
        'sku': sku,
        'isActive': isActive,
      };

  ProductVariantEntry copyWith({
    Map<String, String>? optionValues,
    Object? price = _sentinel,
    int? stockQuantity,
    Object? sku = _sentinel,
    bool? isActive,
  }) {
    return ProductVariantEntry(
      optionValues: optionValues ?? this.optionValues,
      price: identical(price, _sentinel) ? this.price : price as double?,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      sku: identical(sku, _sentinel) ? this.sku : sku as String?,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProductVariantEntry &&
      mapEquals(other.optionValues, optionValues) &&
      other.price == price &&
      other.stockQuantity == stockQuantity &&
      other.sku == sku &&
      other.isActive == isActive;

  @override
  int get hashCode => Object.hash(Object.hashAll(optionValues.entries.map((e) => '${e.key}=${e.value}')), price, stockQuantity, sku, isActive);
}
