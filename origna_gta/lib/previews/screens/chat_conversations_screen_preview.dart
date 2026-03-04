import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/chat_conversations_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Chat Conversations — Mobile', group: 'Screens', size: Size(390, 844))
Widget previewChatConversationsScreenMobile() => previewMobile(child: previewScope(child: ChatConversationsScreen()));

@Preview(name: 'Chat Conversations — Tablet', group: 'Screens', size: Size(768, 1024))
Widget previewChatConversationsScreenTablet() => previewTablet(child: previewScope(child: ChatConversationsScreen()));

@Preview(name: 'Chat Conversations — Desktop', group: 'Screens', size: Size(1280, 800))
Widget previewChatConversationsScreenDesktop() => previewDesktop(child: previewScope(child: ChatConversationsScreen()));

@Preview(name: 'Chat Conversations — Web', group: 'Screens', size: Size(1440, 900))
Widget previewChatConversationsScreenWeb() => previewWeb(child: previewScope(child: ChatConversationsScreen()));
