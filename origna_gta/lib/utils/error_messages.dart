import 'package:origna_gta/core/errors/error_codes.dart';

/// Formats an error code + description for display in the UI.
///
/// Format: `Error [CODE]: <description>`
/// Example: `Error [ORIGNA-PAY-001]: Card declined`
///
/// Usage:
/// ```dart
/// final msg = ErrorMessages.format(ErrorCodes.payCardDeclined);
/// // → "Error [ORIGNA-PAY-001]: Card declined"
/// ```
abstract final class ErrorMessages {
  /// Returns a display string for SnackBars and error dialogs.
  /// Falls back to a generic message if the code is unrecognized.
  static String format(String code) {
    final description = ErrorCodes.describe(code);
    return 'Error [$code]: $description';
  }

  /// Formats a generic unknown error with the SYS-999 code.
  static String unknown() => format(ErrorCodes.sysUnknown);
}
