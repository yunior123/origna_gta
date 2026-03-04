import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/previews/_preview_theme.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';

@Preview(name: 'Custom AppBar — Cart Scenarios', group: 'CustomAppBar')
Widget previewAppBarCart() => previewGrid(
  children: [
    ProviderScope(
      overrides: [cartItemCountProvider.overrideWith((ref) => 0)],
      child: AppBarFactory.withCart(title: 'Empty Cart'),
    ),
    ProviderScope(
      overrides: [cartItemCountProvider.overrideWith((ref) => 105)],
      child: AppBarFactory.withCart(title: 'Full Cart'),
    ),
  ],
);

@Preview(name: 'Custom AppBar — Variants', group: 'CustomAppBar')
Widget previewAppBarVariants() => ProviderScope(
  overrides: [
    cartItemCountProvider.overrideWith((ref) => 3),
    currentUserProvider.overrideWith((ref) => null), // Not logged in
  ],
  child: previewGrid(
    children: [
      AppBarFactory.main(title: 'OrignaGTA', showCartBadge: true),
      AppBarFactory.simple(title: 'Settings', subtitle: 'Manage your account'),
      AppBarFactory.custom(
        title: 'Search Results',
        leading: const Icon(Icons.search, color: Colors.white),
        actions: [IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}, tooltip: 'Filter')],
      ),
    ],
  ),
);
