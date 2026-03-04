import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/payment_screens.dart';

import '../_preview_theme.dart';

@Preview(name: 'Payment Canceled — Mobile', group: 'Screens — Checkout Flows', size: Size(390, 844))
Widget previewPaymentCanceledScreenMobile() => previewMobile(child: const PaymentCanceledScreen());

@Preview(name: 'Payment Canceled — Tablet', group: 'Screens — Checkout Flows', size: Size(768, 1024))
Widget previewPaymentCanceledScreenTablet() => previewTablet(child: const PaymentCanceledScreen());

@Preview(name: 'Payment Canceled — Desktop', group: 'Screens — Checkout Flows', size: Size(1280, 800))
Widget previewPaymentCanceledScreenDesktop() => previewDesktop(child: const PaymentCanceledScreen());

@Preview(name: 'Payment Canceled — Web', group: 'Screens — Checkout Flows', size: Size(1440, 900))
Widget previewPaymentCanceledScreenWeb() => previewWeb(child: const PaymentCanceledScreen());
