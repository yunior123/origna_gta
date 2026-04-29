Corbado passkeys web bundle
===========================

This directory vendors the browser bridge required by the Flutter `passkeys_web`
package so OrignaGTA does not load runtime JavaScript from GitHub Releases.

- Upstream release: https://github.com/corbado/flutter-passkeys/releases/tag/2.4.0
- Upstream asset: https://github.com/corbado/flutter-passkeys/releases/download/2.4.0/bundle.js
- Local file: `corbado-passkeys-2.4.0.bundle.js`
- SHA-256: `dd06b08556f161f0518d701fd0a1bf9b3f5144e2e0d6e1f5c3cac81742c0be49`

When upgrading `passkeys_web`, download the matching upstream bundle, verify the
checksum, update `web/index.html`, and keep the script source relative.
