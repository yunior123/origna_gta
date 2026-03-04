import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/screens/chat_conversations_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Chat Conversations', group: 'Screens')
Widget previewChatConversationsScreen() => previewResponsiveBreakpoints(builder: (breakpoint) => const ProviderScope(child: ChatConversationsScreen()));
