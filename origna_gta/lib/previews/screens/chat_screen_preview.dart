import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/chat_screen.dart';

import '../_preview_theme.dart';

Widget _chatContent() => previewScope(
  child: ChatScreen(productId: 'preview-id', productTitle: 'Preview Product'),
);

@Preview(name: 'Direct Messaging — Mobile', group: 'Screens', size: Size(390, 844))
Widget previewChatScreenMobile() => previewMobile(child: _chatContent());

@Preview(name: 'Direct Messaging — Tablet', group: 'Screens', size: Size(768, 1024))
Widget previewChatScreenTablet() => previewTablet(child: _chatContent());

@Preview(name: 'Direct Messaging — Desktop', group: 'Screens', size: Size(1280, 800))
Widget previewChatScreenDesktop() => previewDesktop(child: _chatContent());

@Preview(name: 'Direct Messaging — Web', group: 'Screens', size: Size(1440, 900))
Widget previewChatScreenWeb() => previewWeb(child: _chatContent());
