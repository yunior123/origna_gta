#!/usr/bin/env python3
from utils.helpers import sanitize_path, sanitized_text

# Test XSS avec différents vecteurs d'attaque
tests_xss = [
    '<script>alert("XSS")</script>',
    '<img src=x onerror=alert(1)>',
    'javascript:alert(1)',
    '<iframe src="evil.com"></iframe>',
    'Hello <script>bad()</script> World',
]

print('=== Tests XSS Prevention ===')
for test in tests_xss:
    result = sanitized_text(test)
    has_script = '<script>' in result
    has_iframe = '<iframe>' in result
    has_js = 'javascript:' in result
    has_onerror = 'onerror=' in result

    if has_script or has_iframe or has_js or has_onerror:
        print(f'❌ FAIL: {repr(test)} -> {repr(result)}')
    else:
        print(f'✅ PASS: {repr(test)} -> {repr(result)}')

# Test path traversal avec différents vecteurs
tests_path = [
    '../../../etc/passwd',
    '..\\..\\..\\windows\\system32',
    'test/../../../../secret.key',
    '../config.json',
]

print('\n=== Tests Path Traversal Prevention ===')
for test in tests_path:
    result = sanitize_path(test)
    has_dots = '..' in result
    has_slash = '/' in result or '\\' in result

    if has_dots or has_slash:
        print(f'❌ FAIL: {repr(test)} -> {repr(result)}')
    else:
        print(f'✅ PASS: {repr(test)} -> {repr(result)}')

print('\n✅ All security tests completed!')
