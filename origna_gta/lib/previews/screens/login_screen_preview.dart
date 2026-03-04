import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/login_screen.dart';

import '../_preview_theme.dart';

Widget _loginContent() => previewScope(
  child: LoginScreenLayout(
    isLogin: true,
    isLoading: false,
    obscurePassword: true,
    acceptedTerms: true,
    marketingOptIn: false,
    nameController: TextEditingController(),
    emailController: TextEditingController(text: 'preview@example.com'),
    passwordController: TextEditingController(text: 'password123'),
    formKey: GlobalKey<FormState>(),
    onAuthToggle: () {},
    onAuthSubmit: () {},
    onGoogleSignIn: () {},
    onAppleSignIn: () {},
    onForgotPassword: () {},
    onToggleObscurePassword: () {},
    onTermsChanged: (v) {},
    onMarketingOptInChanged: (v) {},
  ),
);

Widget _registerContent() => previewScope(
  child: LoginScreenLayout(
    isLogin: false,
    isLoading: false,
    obscurePassword: true,
    acceptedTerms: true,
    marketingOptIn: false,
    nameController: TextEditingController(),
    emailController: TextEditingController(text: 'preview@example.com'),
    passwordController: TextEditingController(text: 'password123'),
    formKey: GlobalKey<FormState>(),
    onAuthToggle: () {},
    onAuthSubmit: () {},
    onGoogleSignIn: () {},
    onAppleSignIn: () {},
    onForgotPassword: () {},
    onToggleObscurePassword: () {},
    onTermsChanged: (v) {},
    onMarketingOptInChanged: (v) {},
  ),
);

@Preview(name: 'Login — Mobile', group: 'Auth Screens', size: Size(390, 844))
Widget previewLoginScreenMobile() => previewMobile(child: _loginContent());

@Preview(name: 'Login — Tablet', group: 'Auth Screens', size: Size(768, 1024))
Widget previewLoginScreenTablet() => previewTablet(child: _loginContent());

@Preview(name: 'Login — Desktop', group: 'Auth Screens', size: Size(1280, 800))
Widget previewLoginScreenDesktop() => previewDesktop(child: _loginContent());

@Preview(name: 'Login — Web', group: 'Auth Screens', size: Size(1440, 900))
Widget previewLoginScreenWeb() => previewWeb(child: _loginContent());

@Preview(name: 'Register — Mobile', group: 'Auth Screens', size: Size(390, 844))
Widget previewRegisterScreenMobile() => previewMobile(child: _registerContent());

@Preview(name: 'Register — Tablet', group: 'Auth Screens', size: Size(768, 1024))
Widget previewRegisterScreenTablet() => previewTablet(child: _registerContent());

@Preview(name: 'Register — Desktop', group: 'Auth Screens', size: Size(1280, 800))
Widget previewRegisterScreenDesktop() => previewDesktop(child: _registerContent());

@Preview(name: 'Register — Web', group: 'Auth Screens', size: Size(1440, 900))
Widget previewRegisterScreenWeb() => previewWeb(child: _registerContent());
