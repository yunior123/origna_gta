import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/screens/chat_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Direct Messaging', group: 'Screens')
Widget previewChatScreen() => previewResponsiveBreakpoints(
  builder: (breakpoint) => const ProviderScope(
    child: ChatScreen(productId: 'preview-id', productTitle: 'Preview Product'),
  ),
);
