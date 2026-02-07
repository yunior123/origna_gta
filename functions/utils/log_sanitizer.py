"""
Log Sanitization Utility
Sanitizes sensitive data from logs to prevent credential leaks
"""

from typing import Any


def sanitize_log_data(
    data: Any,
    sensitive_keys: list[str] = None,
    mask: str = "***"
) -> Any:
    """
    Sanitize sensitive data from logs

    Args:
        data: Data to sanitize (dict, list, or primitive)
        sensitive_keys: List of key names to mask (case-insensitive)
        mask: Replacement string for sensitive values

    Returns:
        Sanitized copy of the data
    """
    if sensitive_keys is None:
        sensitive_keys = [
            'password', 'token', 'secret', 'key', 'apiKey', 'api_key',
            'clientSecret', 'client_secret', 'webhook_secret', 'stripe_key',
            'authorization', 'auth', 'bearer', 'credentials', 'private_key'
        ]

    # Normalize sensitive keys to lowercase for comparison
    sensitive_keys_lower = [k.lower() for k in sensitive_keys]

    if isinstance(data, dict):
        return {
            k: mask if any(s in k.lower() for s in sensitive_keys_lower) else sanitize_log_data(v, sensitive_keys, mask)
            for k, v in data.items()
        }
    elif isinstance(data, list):
        return [sanitize_log_data(item, sensitive_keys, mask) for item in data]
    else:
        return data


def sanitize_error_log(error: Exception, context: dict = None) -> dict[str, Any]:
    """
    Sanitize error information for safe logging

    Args:
        error: Exception object
        context: Additional context dictionary

    Returns:
        Dictionary with sanitized error info
    """
    error_info = {
        'type': type(error).__name__,
        'message': str(error),
    }

    if context:
        error_info['context'] = sanitize_log_data(context)

    return error_info
