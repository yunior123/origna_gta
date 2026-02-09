"""
Cryptographic Utilities for OrignaGTA
=====================================

Provides AES-256-GCM encryption/decryption for sensitive data stored in Firestore,
specifically MFA TOTP secrets.

AUDIT FIX: MFA secrets were stored in plaintext in Firestore. This module encrypts
them at rest using a key from Google Secret Manager (or .env in emulator mode).
"""

import base64
import os

from cryptography.hazmat.primitives.ciphers.aead import AESGCM


def _get_encryption_key() -> bytes:
    """
    Load the 256-bit AES encryption key.

    In emulator mode: reads MFA_ENCRYPTION_KEY from environment.
    In production: reads from Google Secret Manager via config.

    The key must be a 32-byte value, base64-encoded in the secret store.
    If no key is configured, raises RuntimeError to prevent plaintext storage.
    """
    # Check environment variable directly to handle test environments correctly
    # where IS_EMULATOR may be patched or the env var is set after module load
    _is_emulator = os.environ.get('FUNCTIONS_EMULATOR', 'false').lower() == 'true'

    if _is_emulator:
        key_b64 = os.environ.get('MFA_ENCRYPTION_KEY', '')
        if not key_b64:
            # In emulator, generate a deterministic dev key for testing
            # NEVER use this in production
            import hashlib
            dev_key = hashlib.sha256(b'origna-dev-mfa-key-emulator-only').digest()
            return dev_key
    else:
        from firebase_functions import params
        try:
            key_b64 = params.SecretParam('MFA_ENCRYPTION_KEY').value
        except Exception as e:
            raise RuntimeError(f'MFA_ENCRYPTION_KEY not configured in Secret Manager: {e}') from e

    if not key_b64:
        raise RuntimeError('MFA_ENCRYPTION_KEY is empty. Cannot encrypt MFA secrets.')

    try:
        key_bytes = base64.b64decode(key_b64)
    except Exception as e:
        raise RuntimeError(f'MFA_ENCRYPTION_KEY is not valid base64: {e}') from e

    if len(key_bytes) != 32:
        raise RuntimeError(f'MFA_ENCRYPTION_KEY must be 32 bytes (256-bit), got {len(key_bytes)} bytes.')

    return key_bytes


def encrypt_mfa_secret(plaintext_secret: str) -> str:
    """
    Encrypt an MFA TOTP secret using AES-256-GCM.

    Args:
        plaintext_secret: The Base32-encoded TOTP secret to encrypt.

    Returns:
        A string in format "nonce_b64:ciphertext_b64" safe for Firestore storage.

    The nonce (12 bytes) is randomly generated per encryption to ensure
    the same secret never produces the same ciphertext.
    """
    key = _get_encryption_key()
    aesgcm = AESGCM(key)
    nonce = os.urandom(12)  # 96-bit nonce for AES-GCM

    plaintext_bytes = plaintext_secret.encode('utf-8')
    ciphertext = aesgcm.encrypt(nonce, plaintext_bytes, None)

    # Encode both nonce and ciphertext as base64, separated by ':'
    nonce_b64 = base64.b64encode(nonce).decode('ascii')
    ct_b64 = base64.b64encode(ciphertext).decode('ascii')

    return f'{nonce_b64}:{ct_b64}'


def decrypt_mfa_secret(encrypted_secret: str) -> str:
    """
    Decrypt an AES-256-GCM encrypted MFA TOTP secret.

    Args:
        encrypted_secret: String in format "nonce_b64:ciphertext_b64".

    Returns:
        The original Base32-encoded TOTP secret.

    Raises:
        ValueError: If the encrypted string format is invalid.
        RuntimeError: If decryption fails (wrong key or tampered data).
    """
    if ':' not in encrypted_secret:
        # Legacy plaintext secret — return as-is for backward compatibility
        # This allows gradual migration of existing secrets
        return encrypted_secret

    parts = encrypted_secret.split(':', 1)
    if len(parts) != 2:
        raise ValueError('Invalid encrypted MFA secret format')

    nonce_b64, ct_b64 = parts

    try:
        nonce = base64.b64decode(nonce_b64)
        ciphertext = base64.b64decode(ct_b64)
    except Exception:
        # Could be a legacy plaintext secret containing ':'
        # Return as-is for backward compatibility
        return encrypted_secret

    if len(nonce) != 12:
        # Not a valid encrypted format — treat as legacy plaintext
        return encrypted_secret

    key = _get_encryption_key()
    aesgcm = AESGCM(key)

    try:
        plaintext_bytes = aesgcm.decrypt(nonce, ciphertext, None)
        return plaintext_bytes.decode('utf-8')
    except Exception as e:
        raise RuntimeError(f'Failed to decrypt MFA secret (wrong key or tampered data): {e}') from e


def is_encrypted(value: str) -> bool:
    """
    Check if a string appears to be an encrypted MFA secret.

    Returns True if the string matches the "nonce_b64:ciphertext_b64" format.
    """
    if ':' not in value:
        return False
    parts = value.split(':', 1)
    if len(parts) != 2:
        return False
    try:
        nonce = base64.b64decode(parts[0])
        return len(nonce) == 12
    except Exception:
        return False
