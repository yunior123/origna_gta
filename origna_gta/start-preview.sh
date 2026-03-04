#!/usr/bin/env bash
set -e

# Start the widget previewer and immediately patch the scaffold HTML
flutter widget-preview start &
FLUTTER_PID=$!

# Wait for scaffold to be generated (poll for the HTML file)
SCAFFOLD_HTML=""
for i in $(seq 1 30); do
  SCAFFOLD_HTML=$(find /tmp/flutter_tools.* -name "index.html" \
    -path "*/widget_preview_scaffold*/web/*" 2>/dev/null | head -1)
  if [ -n "$SCAFFOLD_HTML" ]; then break; fi
  sleep 1
done

if [ -n "$SCAFFOLD_HTML" ]; then
  python3 - "$SCAFFOLD_HTML" << 'PYEOF'
import sys
path = sys.argv[1]
stub = '''  <!-- PasskeyAuthenticator full stub — all 7 interop.dart methods.
       Prevents passkeys_web plugin from crashing in preview/test mode. -->
  <script>
    if (typeof window.PasskeyAuthenticator === 'undefined') {
      window.PasskeyAuthenticator = {
        init: function() {},
        register: function() { return Promise.reject('passkeys not loaded'); },
        login: function() { return Promise.reject('passkeys not loaded'); },
        cancelCurrentAuthenticatorOperation: function() {},
        isUserVerifyingPlatformAuthenticatorAvailable: function() { return Promise.resolve(false); },
        isConditionalMediationAvailable: function() { return Promise.resolve(false); },
        hasPasskeySupport: function() { return false; }
      };
    }
  </script>
  '''
with open(path) as f:
    content = f.read()
if 'PasskeyAuthenticator' not in content:
    content = content.replace(
        '  <script src="flutter_bootstrap.js" async></script>',
        stub + '  <script src="flutter_bootstrap.js" async></script>'
    )
    with open(path, 'w') as f:
        f.write(content)
    print(f'✓ Patched {path}')
else:
    print('Already patched')
PYEOF
fi

wait $FLUTTER_PID
