import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/payment_screens.dart';

import '../_preview_theme.dart';

@Preview(name: 'Payment Canceled / Failed', group: 'Screens — Checkout Flows')
Widget previewPaymentCanceledScreen() => previewResponsiveBreakpoints(builder: (breakpoint) => const PaymentCanceledScreen());
