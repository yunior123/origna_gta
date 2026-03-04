import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/favorites_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Favorites / Wishlist', group: 'Screens')
Widget previewFavoritesScreen() => previewResponsiveBreakpoints(builder: (breakpoint) => previewScope(child: FavoritesScreen()));
