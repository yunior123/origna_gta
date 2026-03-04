import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/favorites_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Favorites / Wishlist — Mobile', group: 'Screens', size: Size(390, 844))
Widget previewFavoritesScreenMobile() => previewMobile(child: previewScope(child: FavoritesScreen()));

@Preview(name: 'Favorites / Wishlist — Tablet', group: 'Screens', size: Size(768, 1024))
Widget previewFavoritesScreenTablet() => previewTablet(child: previewScope(child: FavoritesScreen()));

@Preview(name: 'Favorites / Wishlist — Desktop', group: 'Screens', size: Size(1280, 800))
Widget previewFavoritesScreenDesktop() => previewDesktop(child: previewScope(child: FavoritesScreen()));

@Preview(name: 'Favorites / Wishlist — Web', group: 'Screens', size: Size(1440, 900))
Widget previewFavoritesScreenWeb() => previewWeb(child: previewScope(child: FavoritesScreen()));
