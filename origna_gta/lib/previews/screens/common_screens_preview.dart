import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/common_screens.dart';

import '../_preview_theme.dart';

@Preview(name: 'Email Verification — Mobile', group: 'Screens — Auth Flows', size: Size(390, 844))
Widget previewEmailVerificationRequiredScreenMobile() =>
    previewMobile(child: previewScope(child: EmailVerificationRequiredScreen()));

@Preview(name: 'Email Verification — Tablet', group: 'Screens — Auth Flows', size: Size(768, 1024))
Widget previewEmailVerificationRequiredScreenTablet() =>
    previewTablet(child: previewScope(child: EmailVerificationRequiredScreen()));

@Preview(name: 'Email Verification — Desktop', group: 'Screens — Auth Flows', size: Size(1280, 800))
Widget previewEmailVerificationRequiredScreenDesktop() =>
    previewDesktop(child: previewScope(child: EmailVerificationRequiredScreen()));

@Preview(name: 'Email Verification — Web', group: 'Screens — Auth Flows', size: Size(1440, 900))
Widget previewEmailVerificationRequiredScreenWeb() =>
    previewWeb(child: previewScope(child: EmailVerificationRequiredScreen()));
