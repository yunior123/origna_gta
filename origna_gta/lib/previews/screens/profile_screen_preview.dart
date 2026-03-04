import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/screens/profile_screen.dart';
import 'package:origna_gta/utils/constants.dart';

@Preview(name: 'ProfileScreen — Dark', group: 'ProfileScreen')
Widget previewProfileScreenDark() => ProviderScope(
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: Material(
      child: ProfileScreenLayout(
        userProfileAsync: AsyncValue.data(
          UserModel(uid: 'mock-uid', email: 'user@example.com', name: 'John Doe', roles: [UserRoles.buyer], createdAt: DateTime.now()),
        ),
        currentUser: null,
        isExportLoading: false,
        themeMode: ThemeMode.dark,
        isPremium: true,
        onSignIn: () {},
        onSignOut: () {},
        onDeleteAccountRequested: () {},
        onExportData: () {},
        onThemeChange: (_) {},
        onLanguageChange: (_) {},
      ),
    ),
  ),
);

@Preview(name: 'ProfileScreen — Light', group: 'ProfileScreen')
Widget previewProfileScreenLight() => ProviderScope(
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.light(),
    home: Material(
      child: ProfileScreenLayout(
        userProfileAsync: AsyncValue.data(
          UserModel(uid: 'mock-uid', email: 'user@example.com', name: 'Jane Doe', roles: [UserRoles.seller], createdAt: DateTime.now()),
        ),
        currentUser: null,
        isExportLoading: false,
        themeMode: ThemeMode.light,
        isPremium: false,
        onSignIn: () {},
        onSignOut: () {},
        onDeleteAccountRequested: () {},
        onExportData: () {},
        onThemeChange: (_) {},
        onLanguageChange: (_) {},
      ),
    ),
  ),
);
