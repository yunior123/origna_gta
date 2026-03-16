#!/usr/bin/env bash
# Generate test video fixtures for product-video-e2e.spec.ts
# Requires ffmpeg to be installed: brew install ffmpeg
#
# Outputs:
#   e2e/fixtures/videos/oversized.mp4   — silent video > 100 MB (size limit)
#   e2e/fixtures/videos/too-long.mp4    — silent video > 60 s (duration limit)
#
# Run from the repo root or from the e2e/ directory.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURES_DIR="$(cd "${SCRIPT_DIR}/../fixtures/videos" && pwd)"

if ! command -v ffmpeg &>/dev/null; then
  echo "ERROR: ffmpeg not found. Install with: brew install ffmpeg" >&2
  exit 1
fi

echo "Generating test video fixtures in: ${FIXTURES_DIR}"

# ── oversized.mp4 ────────────────────────────────────────────────────────────
# A 10-minute silent black video at 1280x720 @ 1 Mbps — results in ~750 MB,
# well above the 100 MB upload limit used by the Flutter product video validator.
OVERSIZED="${FIXTURES_DIR}/oversized.mp4"
if [[ -f "${OVERSIZED}" ]]; then
  echo "oversized.mp4 already exists — skipping (delete to regenerate)"
else
  echo "Generating oversized.mp4 (this may take ~30s)..."
  ffmpeg -y -f lavfi -i color=c=black:size=1280x720:rate=24 \
    -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 \
    -t 600 \
    -c:v libx264 -b:v 1500k -preset ultrafast \
    -c:a aac -b:a 128k \
    "${OVERSIZED}" -loglevel error
  echo "  -> $(du -sh "${OVERSIZED}" | cut -f1) oversized.mp4"
fi

# ── too-long.mp4 ─────────────────────────────────────────────────────────────
# A 90-second silent black video — exceeds the 60-second duration limit.
TOO_LONG="${FIXTURES_DIR}/too-long.mp4"
if [[ -f "${TOO_LONG}" ]]; then
  echo "too-long.mp4 already exists — skipping (delete to regenerate)"
else
  echo "Generating too-long.mp4 (this may take ~5s)..."
  ffmpeg -y -f lavfi -i color=c=black:size=640x480:rate=24 \
    -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 \
    -t 90 \
    -c:v libx264 -b:v 500k -preset ultrafast \
    -c:a aac -b:a 64k \
    "${TOO_LONG}" -loglevel error
  echo "  -> $(du -sh "${TOO_LONG}" | cut -f1) too-long.mp4"
fi

echo "Done. Run the E2E tests with:"
echo "  cd e2e && npx playwright test playwright_ui/product-video-e2e.spec.ts --config=playwright.config.dev.ts"
