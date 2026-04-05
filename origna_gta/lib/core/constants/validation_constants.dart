/// F-74: Centralised validation constants — single source of truth.
/// All email validation across the app MUST use [ValidationConstants.emailRegex].
abstract final class ValidationConstants {
  /// RFC 5322 simplified email regex — same pattern used in auth_repository and login_viewmodel.
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// F-84: Strong password policy — single source of truth.
  /// Requires: 8+ chars, 1 upper, 1 lower, 1 digit, 1 special.
  /// Special char set matches backend: ob-auth/src/password.rs
  static final RegExp passwordRegex = RegExp(
    r'''^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=\[\]{}|;':",./<>?~`])[A-Za-z\d!@#$%^&*()_+\-=\[\]{}|;':",./<>?~`]{8,}$''',
  );

  static const int minPasswordLength = 8;
  static const int maxEmailLength = 254;
  static const int minEmailLength = 6;
  static const int minNameLength = 2;
  static const int maxNameLength = 60;

  /// Common weak passwords to reject (expanded list for production security)
  static const List<String> commonPasswords = [
    // Top most common passwords globally
    'password', '12345678', '123456789', '1234567890', 'qwerty', 'qwerty123',
    'abc123', 'abc123456', 'password1', 'password123', 'iloveyou', 'monkey',
    'dragon', 'master', 'letmein', 'login', 'admin', 'welcome', 'shadow',
    'sunshine', 'trustno1', 'football', 'baseball', 'soccer', 'hockey',
    'batman', 'superman', 'spider', 'michael', 'jennifer', 'hunter',
    'harley', 'ranger', 'buster', 'thomas', 'robert', 'george',
    // Keyboard patterns
    'asdfgh', 'asdfghjkl', 'zxcvbn', 'zxcvbnm', 'qazwsx', 'qweasd',
    // Common with special chars
    'password!', 'password@', 'password#', '123456!', 'qwerty!',
    // E-commerce related (should not be used)
    'shop1234', 'store123', 'buybuy123', 'market1',
    // Seasonal/temporal
    'summer2024', 'winter2024', 'spring2024', 'fall2024',
    'summer2025', 'winter2025', 'spring2025', 'fall2025',
    'summer2026', 'winter2026', 'spring2026', 'fall2026',
  ];
}
