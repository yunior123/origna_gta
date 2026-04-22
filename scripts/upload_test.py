#!/usr/bin/env python3

"""Upload a local file to Cloudflare R2 through a presigned PUT URL.

This helper intentionally avoids Amazon S3 client usage. Generate the presigned
Cloudflare R2 upload URL elsewhere, then pass it in directly.

Example:
  python3 scripts/upload_test.py extracted_images/solar_quote_img_improved_1.jpeg \
    "https://<account>.r2.cloudflarestorage.com/<bucket>/<key>?X-Amz-..."
"""

import os
import sys

import requests
import urllib3

urllib3.disable_warnings()


def main() -> int:
    if len(sys.argv) != 3:
        print(
            "Usage: python3 scripts/upload_test.py <local_file> <presigned_put_url>",
            file=sys.stderr,
        )
        return 1

    file_path = sys.argv[1]
    presigned_put_url = sys.argv[2]

    if not os.path.exists(file_path):
        print(f"File not found: {file_path}", file=sys.stderr)
        return 1

    content_type = "image/jpeg"
    lowered = file_path.lower()
    if lowered.endswith(".png"):
        content_type = "image/png"
    elif lowered.endswith(".webp"):
        content_type = "image/webp"

    print(f"Uploading {file_path} to Cloudflare R2 via presigned URL...")
    with open(file_path, "rb") as handle:
        response = requests.put(
            presigned_put_url,
            data=handle,
            headers={"Content-Type": content_type},
            timeout=120,
        )

    if response.status_code not in (200, 201):
        print(
            f"Upload failed with status {response.status_code}: {response.text}",
            file=sys.stderr,
        )
        return 1

    print("Upload successful!")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
