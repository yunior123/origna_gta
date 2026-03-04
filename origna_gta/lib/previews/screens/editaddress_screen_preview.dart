import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/screens/editaddress_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Manage Address Details', group: 'Screens')
Widget previewAddEditAddressScreen() => previewResponsiveBreakpoints(builder: (breakpoint) => previewScope(child: AddEditAddressScreen()));
