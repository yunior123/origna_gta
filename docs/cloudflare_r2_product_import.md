# Cloudflare R2 Product Import Runbook

This runbook keeps product-image storage on Cloudflare R2 only. Amazon S3 direct usage is intentionally excluded.

## What was prepared locally

- `scripts/data/solar_product_manifest.json`
  - Production-ready solar product metadata.
  - Uses the improved local images from `extracted_images/`.
- `scripts/data/aliexpress_test_products.json`
  - Three realistic AliExpress-style test products for future catalog seeding.
- `scripts/upload_product_assets.ts`
  - Signs into OrignaBase, requests presigned R2 upload URLs, uploads the local images, and writes the resulting public URLs.
- `scripts/add_hybrid_solar_system.ts`
  - Reads the solar manifest and uploaded R2 URLs instead of using a hardcoded sample image.

## Cloudflare R2 best practices used here

- Use short-lived presigned `PUT` URLs for uploads rather than exposing bucket credentials.
- Enforce `Content-Type` during signing and upload so mismatched uploads fail closed.
- Configure bucket CORS if uploads happen from a browser.
- Keep original object paths separate from any transformed-image paths to avoid loops.
- Treat presigned URLs as bearer tokens and keep their TTL short.

Official references:

- `https://developers.cloudflare.com/r2/api/s3/presigned-urls/`
- `https://developers.cloudflare.com/r2/buckets/cors/`
- `https://developers.cloudflare.com/images/transform-images/transform-via-workers/`
- `https://developers.cloudflare.com/images/transform-images/transform-via-url/`

## Live upload flow

1. Export auth:

```bash
export ADMIN_EMAIL='...'
export ADMIN_PASSWORD='...'
export ORIGNABASE_URL='https://api.orignagta.ca'
```

2. Upload the improved solar images to R2 through OrignaBase presigns:

```bash
bun scripts/upload_product_assets.ts
```

That writes `scripts/data/solar_product_uploaded_urls.json`.

3. Insert the production product with the uploaded image URLs:

```bash
IMAGE_URLS_JSON_PATH='scripts/data/solar_product_uploaded_urls.json' \
PRODUCT_MANIFEST_PATH='scripts/data/solar_product_manifest.json' \
bun scripts/add_hybrid_solar_system.ts
```

## Notes

- The current terminal session does not expose the required admin credentials, so the live upload and live product insert were not executed here.
- The terminal also does not currently have macOS access to re-read `~/Downloads`, so this runbook relies on the already extracted local image assets committed in the repo workspace.
