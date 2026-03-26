//! Input validation helpers for handler endpoints.

use ob_core::Error;
use std::sync::OnceLock;

static PHONE_RE: OnceLock<regex_lite::Regex> = OnceLock::new();
static EMAIL_RE: OnceLock<regex_lite::Regex> = OnceLock::new();
static EMAIL_REDACT_RE: OnceLock<regex_lite::Regex> = OnceLock::new();

/// Validate that a string is non-empty and within max length.
pub fn validate_string(field: &str, value: &str, max_len: usize) -> ob_core::Result<()> {
    if value.is_empty() {
        return Err(Error::Validation(format!("{field} cannot be empty")));
    }
    if value.len() > max_len {
        return Err(Error::Validation(format!(
            "{field} exceeds max length of {max_len}"
        )));
    }
    Ok(())
}

/// Validate that an amount in cents is positive and within bounds.
pub fn validate_amount_cents(field: &str, cents: i64) -> ob_core::Result<()> {
    if cents < 0 {
        return Err(Error::Validation(format!("{field} cannot be negative")));
    }
    if cents > 10_000_000 {
        // $100,000 CAD max (aligned with checkout limit)
        return Err(Error::Validation(format!("{field} exceeds maximum")));
    }
    Ok(())
}

/// Validate a nutrition amount value: non-negative and within bounds.
/// Used for individual nutrient field validation in product endpoints.
pub fn validate_nutrition_amount(field: &str, value: i64) -> ob_core::Result<()> {
    if value < 0 {
        return Err(Error::Validation(format!("{field} cannot be negative")));
    }
    if value > 999_999 {
        return Err(Error::Validation(format!(
            "{field} exceeds maximum (999999)"
        )));
    }
    Ok(())
}

/// Validate an email address using RFC 5322 simplified regex.
pub fn validate_email(email: &str) -> ob_core::Result<()> {
    if email.len() > 254 {
        return Err(Error::Validation("Email too long".into()));
    }
    let email_regex = EMAIL_RE.get_or_init(|| {
        regex_lite::Regex::new(r"^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$")
            .expect("static email regex should compile")
    });
    if !email_regex.is_match(email) {
        return Err(Error::Validation("Invalid email address".into()));
    }
    Ok(())
}

/// Validate a UUID string.
pub fn validate_uid(field: &str, value: &str) -> ob_core::Result<()> {
    if value.is_empty() {
        return Err(Error::Validation(format!("{field} cannot be empty")));
    }
    if value.len() > 128 {
        return Err(Error::Validation(format!("{field} is too long")));
    }
    Ok(())
}

/// Sanitize HTML to prevent XSS (strips all tags).
pub fn sanitize_html(input: &str) -> String {
    let mut result = String::with_capacity(input.len());
    let mut in_tag = false;
    for ch in input.chars() {
        match ch {
            '<' => in_tag = true,
            '>' => in_tag = false,
            _ if !in_tag => result.push(ch),
            _ => {}
        }
    }
    result
}

/// Redact contact information (phone numbers, emails) from chat messages.
pub fn redact_contact_info(text: &str) -> String {
    let mut result = text.to_string();
    // Redact phone numbers (10+ digits with optional separators)
    let phone_pattern = PHONE_RE
        .get_or_init(|| regex_lite::Regex::new(r"\+?\d[\d\s\-().]{8,}\d").expect("valid regex"));
    result = phone_pattern.replace_all(&result, "[REDACTED]").to_string();
    // Redact emails (unanchored pattern for finding emails within text)
    let email_pattern = EMAIL_REDACT_RE.get_or_init(|| {
        regex_lite::Regex::new(r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}")
            .expect("valid regex")
    });
    result = email_pattern.replace_all(&result, "[REDACTED]").to_string();
    result
}

/// Validate phone number in E.164 format.
/// Format: +[1-9]{1-15 digits}
/// Example: +14165551234
pub fn validate_phone_e164(phone: &str) -> ob_core::Result<()> {
    let phone_trimmed = phone.trim();

    // E.164 format: +[1-9]{1,15}
    let e164_regex = regex_lite::Regex::new(r"^\+[1-9]\d{1,14}$")
        .map_err(|_| ob_core::Error::Internal("Regex compile error".into()))?;

    if !e164_regex.is_match(phone_trimmed) {
        return Err(ob_core::Error::Validation(
            "Phone must be in E.164 format (e.g., +14165551234)".into(),
        ));
    }

    Ok(())
}

/// Validate Canadian postal code format.
/// Format: A1A 1A1 (letter-digit-letter space digit-letter-digit)
pub fn validate_postal_code_ca(postal_code: &str) -> ob_core::Result<String> {
    let normalized = postal_code.to_uppercase().replace(" ", "");

    // Canadian postal code: A1A1A1
    let postal_regex = regex_lite::Regex::new(r"^[A-Z]\d[A-Z]\d[A-Z]\d$")
        .map_err(|_| ob_core::Error::Internal("Regex compile error".into()))?;

    if !postal_regex.is_match(&normalized) {
        return Err(ob_core::Error::Validation(
            "Invalid Canadian postal code. Format: A1A 1A1 (e.g., M5V 3A8)".into(),
        ));
    }

    // Return formatted: A1A 1A1
    Ok(format!("{} {}", &normalized[0..3], &normalized[3..6]))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_validate_string_ok() {
        assert!(validate_string("name", "hello", 100).is_ok());
    }

    #[test]
    fn test_validate_string_empty() {
        assert!(validate_string("name", "", 100).is_err());
    }

    #[test]
    fn test_validate_string_too_long() {
        let long = "a".repeat(200);
        assert!(validate_string("name", &long, 100).is_err());
    }

    #[test]
    fn test_validate_nutrition_amount_ok() {
        assert!(validate_nutrition_amount("sodiumMg", 0).is_ok());
        assert!(validate_nutrition_amount("sodiumMg", 500).is_ok());
        assert!(validate_nutrition_amount("sodiumMg", 999_999).is_ok());
    }

    #[test]
    fn test_validate_nutrition_amount_negative() {
        let err = validate_nutrition_amount("sodiumMg", -1);
        assert!(err.is_err());
        assert!(err.unwrap_err().to_string().contains("cannot be negative"));
    }

    #[test]
    fn test_validate_nutrition_amount_exceeds_max() {
        let err = validate_nutrition_amount("sodiumMg", 1_000_000);
        assert!(err.is_err());
        assert!(err.unwrap_err().to_string().contains("exceeds maximum"));
    }

    #[test]
    fn test_validate_amount_cents() {
        assert!(validate_amount_cents("price", 1000).is_ok());
        assert!(validate_amount_cents("price", -1).is_err());
        assert!(validate_amount_cents("price", 200_000_000).is_err());
    }

    #[test]
    fn test_sanitize_html() {
        assert_eq!(
            sanitize_html("<script>alert('xss')</script>hello"),
            "alert('xss')hello"
        );
        assert_eq!(sanitize_html("no tags here"), "no tags here");
    }

    #[test]
    fn test_redact_contact_info() {
        let text = "Call me at 416-555-1234 or email john@example.com";
        let redacted = redact_contact_info(text);
        assert!(!redacted.contains("416-555-1234"));
        assert!(!redacted.contains("john@example.com"));
        assert!(redacted.contains("[REDACTED]"));
    }

    #[test]
    fn test_validate_email_ok() {
        assert!(validate_email("test@example.com").is_ok());
    }

    #[test]
    fn test_validate_email_invalid_no_at() {
        assert!(validate_email("testexample.com").is_err());
    }

    #[test]
    fn test_validate_email_invalid_no_dot() {
        assert!(validate_email("test@examplecom").is_err());
    }

    #[test]
    fn test_validate_email_too_long() {
        let long_email = format!("{}@example.com", "a".repeat(250));
        assert!(validate_email(&long_email).is_err());
    }

    #[test]
    fn test_validate_uid_ok() {
        assert!(validate_uid("user_id", "user_12345").is_ok());
    }

    #[test]
    fn test_validate_uid_empty() {
        assert!(validate_uid("user_id", "").is_err());
    }

    #[test]
    fn test_validate_uid_too_long() {
        let long_uid = "u".repeat(150);
        assert!(validate_uid("user_id", &long_uid).is_err());
    }

    #[test]
    fn test_validate_phone_e164_ok() {
        assert!(validate_phone_e164("+14165551234").is_ok());
        assert!(validate_phone_e164("+12025551234").is_ok());
    }

    #[test]
    fn test_validate_phone_e164_invalid_format() {
        assert!(validate_phone_e164("416-555-1234").is_err()); // No +
        assert!(validate_phone_e164("+0165551234").is_err()); // Starts with 0
        assert!(validate_phone_e164("14165551234").is_err()); // No +
    }

    #[test]
    fn test_validate_postal_code_ca_ok() {
        assert!(validate_postal_code_ca("M5V 3A8").is_ok());
        assert!(validate_postal_code_ca("m5v 3a8").is_ok()); // Lowercase
        assert!(validate_postal_code_ca("m5v3a8").is_ok()); // No space
    }

    #[test]
    fn test_validate_postal_code_ca_formatted_output() {
        let result = validate_postal_code_ca("m5v3a8");
        assert_eq!(result.unwrap(), "M5V 3A8");
    }

    #[test]
    fn test_validate_postal_code_ca_invalid() {
        assert!(validate_postal_code_ca("M5V 3A").is_err()); // Too short
        assert!(validate_postal_code_ca("123 456").is_err()); // All numbers
        assert!(validate_postal_code_ca("MMMMMM").is_err()); // All letters
    }

    #[test]
    fn test_redact_once_lock_regex_reuse() {
        // Verify OnceLock regexes are compiled once and reused
        let r1 = redact_contact_info("Call 416-555-1234");
        let r2 = redact_contact_info("Email john@test.com");
        let r3 = redact_contact_info("Both: 647-555-9999 and jane@org.ca");
        assert!(r1.contains("[REDACTED]"));
        assert!(r2.contains("[REDACTED]"));
        assert!(!r3.contains("647-555-9999"));
        assert!(!r3.contains("jane@org.ca"));
    }

    #[test]
    fn test_redact_preserves_safe_text() {
        let safe = "No contact info here!";
        assert_eq!(redact_contact_info(safe), safe);
    }
}
