import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/screens/profile_screen.dart';
import 'package:origna_gta/utils/constants.dart';
import '../_preview_theme.dart';

Widget _profileDarkContent() => previewScope(
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
);

Widget _profileLightContent() => previewScope(
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
);

@Preview(name: 'Profile Dark — Mobile', group: 'ProfileScreen', size: Size(390, 844))
Widget previewProfileScreenDarkMobile() => previewMobile(theme: previewDarkTheme, child: _profileDarkContent());

@Preview(name: 'Profile Dark — Tablet', group: 'ProfileScreen', size: Size(768, 1024))
Widget previewProfileScreenDarkTablet() => previewTablet(theme: previewDarkTheme, child: _profileDarkContent());

@Preview(name: 'Profile Dark — Desktop', group: 'ProfileScreen', size: Size(1280, 800))
Widget previewProfileScreenDarkDesktop() => previewDesktop(theme: previewDarkTheme, child: _profileDarkContent());

@Preview(name: 'Profile Dark — Web', group: 'ProfileScreen', size: Size(1440, 900))
Widget previewProfileScreenDarkWeb() => previewWeb(theme: previewDarkTheme, child: _profileDarkContent());

@Preview(name: 'Profile Light — Mobile', group: 'ProfileScreen', size: Size(390, 844))
Widget previewProfileScreenLightMobile() => previewMobile(theme: previewLightTheme, child: _profileLightContent());

@Preview(name: 'Profile Light — Tablet', group: 'ProfileScreen', size: Size(768, 1024))
Widget previewProfileScreenLightTablet() => previewTablet(theme: previewLightTheme, child: _profileLightContent());

@Preview(name: 'Profile Light — Desktop', group: 'ProfileScreen', size: Size(1280, 800))
Widget previewProfileScreenLightDesktop() => previewDesktop(theme: previewLightTheme, child: _profileLightContent());

@Preview(name: 'Profile Light — Web', group: 'ProfileScreen', size: Size(1440, 900))
Widget previewProfileScreenLightWeb() => previewWeb(theme: previewLightTheme, child: _profileLightContent());
