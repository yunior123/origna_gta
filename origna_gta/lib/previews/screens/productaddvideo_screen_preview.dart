import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/screens/productaddvideo_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Product Add Video', group: 'Product Screens')
Widget previewProductAddVideo() {
  return previewResponsiveBreakpoints(
    builder: (breakpoint) => const ProviderScope(
      child: Scaffold(body: Center(child: ProductAddVideo())),
    ),
  );
}
