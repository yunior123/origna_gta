/// F-74: Centralised validation constants — single source of truth.
/// All email validation across the app MUST use [ValidationConstants.emailRegex].
abstract final class ValidationConstants {
  /// RFC 5322 simplified email regex — same pattern used in auth_repository and login_viewmodel.
  static final RegExp emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
}
