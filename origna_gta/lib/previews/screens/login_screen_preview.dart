import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/screens/login_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Login', group: 'Auth Screens')
Widget previewLoginScreen() {
  return previewResponsiveBreakpoints(
    builder: (breakpoint) => ProviderScope(
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
    ),
  );
}

@Preview(name: 'Register', group: 'Auth Screens')
Widget previewRegisterScreen() {
  return previewResponsiveBreakpoints(
    builder: (breakpoint) => ProviderScope(
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
    ),
  );
}
