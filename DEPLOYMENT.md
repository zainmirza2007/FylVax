# Deployment guide — Fylvex 2.0

## Recommended deployment model

Use the included Docker image on a container host or VPS. The conversion service depends on native binaries, so deploying only the Node.js file will create a site that loads visually but cannot reliably process files.

```bash
cp .env.example .env
# set SITE_URL, SITE_NAME, CONTACT_EMAIL and production limits
docker compose up --build
```

Verify:

```bash
curl https://yourdomain.com/healthz
```

A healthy instance returns `"ok":true`. Missing mandatory conversion engines cause HTTP 503 rather than silently breaking uploads.

## Pre-launch tests

Run inside the same image/environment you intend to deploy:

```bash
npm run doctor
npm test
npm run test:formats
npm run test:broad
```

Do not deploy if any suite fails.

## Reverse proxy / hosting

- HTTPS only in production.
- Request body limit must exceed `MAX_UPLOAD_MB` plus multipart overhead.
- Video and Office conversion need longer upstream timeouts than normal web requests.
- Do not cache `/process/`, `/result/`, `/download/`, or `/healthz`.
- Add host/WAF rate limiting in addition to the app-level rate limit.
- Allocate enough temporary disk for concurrent uploads plus converted outputs.

## Conversion runtime

`npm run doctor` verifies the native stack used by the server.

ImageMagick 6 and 7 are both supported; the server prefers `magick` and falls back to `convert`.

## Malware scanning

Scanning is off by default because an installed `clamscan` binary without an initialized signature database can otherwise break every upload.

Before enabling:

1. Install ClamAV.
2. Update and verify signatures.
3. Test `clamscan` manually.
4. Set `ENABLE_MALWARE_SCAN=true` or `REQUIRE_MALWARE_SCAN=true`.

When enabled, scanner failures fail closed.

## Storage and scaling

The single-node release uses private temporary per-job directories and automatic cleanup. At scale, move to:

1. public SEO/web server
2. job queue
3. isolated conversion workers
4. private object storage with lifecycle deletion and signed URLs
5. CDN/WAF for public pages

Keep public SEO URLs unchanged when moving the processing engine behind workers.

## AdSense / privacy launch sequence

1. Deploy with `ADSENSE_ENABLED=false`.
2. Replace all placeholder contact/domain/brand values.
3. Verify the privacy, cookie, terms, security, acceptable-use, and copyright pages match the real deployment.
4. Configure the required Google-certified CMP for the regions where Google requires it.
5. Connect/verify the site with AdSense using the publisher ID if desired while ads remain disabled.
6. Only after approval and consent setup, configure the ad slot and deliberately enable advertising.
7. Re-check that upload, result, download, legal, and private states remain ad-free.

## Search launch

- Set the final HTTPS `SITE_URL` before indexing.
- Verify canonicals on representative pages.
- Add the domain to Google Search Console.
- Submit `/sitemap.xml`.
- Inspect key pages such as image compression, PDF compression, video compression, HEIC→JPG, and PDF merge.
- Confirm `/process/`, `/result/`, and `/download/` do not appear as indexable pages.
- Run real-device/mobile checks and PageSpeed/Core Web Vitals on the deployed domain.

## Final UI checks

The responsive markup/CSS is included and automated functional tests pass. Perform a live browser pass after deployment because real hosting, reverse-proxy behavior, fonts, network latency, ad/CMP scripts, and production headers can affect layout and Core Web Vitals.
