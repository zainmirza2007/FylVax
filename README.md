# Fylvex 2.0 — production-focused file converter & compressor

Fylvex 2.0 is a server-rendered file utility website for PDF, image, video, audio, and office-document processing. This release combines the broad-format reliability work from v1.1 with a complete tool-first UI/UX redesign inspired by the usability patterns of mature converter products, while keeping the design and code original.

## What is included

- **38 working public tool routes** across PDF, image, video, audio, and documents.
- Minimal tool-first desktop/mobile UI: task → upload → settings → process → download.
- Drag & drop, normal file selection, and clipboard image paste where browser permissions support it.
- Progressive settings: everyday users get recommended presets; advanced options stay secondary.
- Homepage tool search without generating thin/indexable search-result pages.
- Task/category hubs plus exact-intent tool pages for SEO.
- Public tool content below the utility: real use cases, limitations, workflow, privacy, FAQs, and related tools.
- AdSense code is **off by default**, kept away from upload/process/download controls, and gated behind explicit configuration/CMP readiness.
- Private processing/result/download states are ad-free and excluded from indexing.
- Runtime diagnostics for FFmpeg, Ghostscript, Poppler, LibreOffice, libheif, Python libraries, ZIP/file utilities, and ImageMagick 6/7.

## Reliability testing

The final release has three separate conversion suites:

```bash
npm test
npm run test:formats
npm run test:broad
```

Run these suites in the intended deployment environment to obtain current results. Historical audit outputs and test logs have been removed from the project; they do not certify the current runtime.

`test:broad` specifically pushes every advertised broad-family input through Image Compressor, Resize Image, Reduce Image Size, Remove Metadata, Video Compressor, Audio Compressor, and the three Office-specific conversion families.

See `SUPPORTED-FORMATS.md`, `docs/DESIGN-REVIEW.md`, and `docs/SEO-AUDIT-NOTES.md` for format coverage and the latest local verification limits.

## Recommended local run

### Docker — recommended

```bash
cp .env.example .env
docker compose up --build
```

Then open:

```text
http://localhost:3000
```

Verify the conversion stack:

```bash
curl http://localhost:3000/healthz
```

It should return `"ok":true`.

### Native runtime

Node.js by itself is not enough. Run:

```bash
npm run doctor
```

The required runtime includes:

- Node.js 20+
- FFmpeg + ffprobe
- ImageMagick 6 or 7 (`convert` or `magick`)
- Ghostscript
- Poppler (`pdftoppm`, `pdfseparate`, `pdfunite`)
- LibreOffice headless
- Python 3 + Pillow + PyMuPDF
- `heif-convert`
- `file` and `zip`

On Debian/Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y ffmpeg imagemagick ghostscript poppler-utils libreoffice python3 python3-pip file zip libheif-examples
python3 -m pip install Pillow PyMuPDF --break-system-packages
npm run doctor
npm start
```

## AdSense-first architecture

- AdSense is disabled by default.
- A real AdSense publisher ID can be configured for ownership verification while ad units stay disabled.
- Ad rendering requires all required environment values plus `ADSENSE_ENABLED=true` and `CMP_READY=true`.
- `CMP_READY=true` must only be set after the required Google-certified consent solution is actually configured for relevant regions.
- Ads are placed only after the complete interactive tool/trust block, never beside the upload/process/download controls.
- `/process/`, `/result/`, and `/download/` states remain private, `noindex`, and ad-free.
- Streaming/social-platform downloader features are intentionally excluded.

No codebase can guarantee Google AdSense approval; Google reviews the live site/account and policies can change.

## SEO architecture

The primary SEO targets are exact-task public URLs such as:

```text
/image/compress-image
/image/heic-to-jpg
/pdf/compress-pdf
/pdf/merge-pdf
/video/compress-video
```

Task hubs such as `/compress/` and `/convert/` support discovery and internal linking without replacing the exact-intent pages.

Included technical SEO:

- server-rendered HTML
- unique title/meta description/H1 per tool
- canonical tags
- XML sitemap
- robots.txt
- breadcrumbs + Breadcrumb structured data
- SoftwareApplication structured data on tool pages
- internal linking between category, task, tool, guide, and trust pages
- processing/download states excluded from the sitemap and indexed content

## Before production launch

Set real values in `.env`:

```env
SITE_URL=https://yourdomain.com
SITE_NAME=Your Brand
CONTACT_EMAIL=you@yourdomain.com
MAX_UPLOAD_MB=200
FILE_RETENTION_MINUTES=60
MAX_CONCURRENT_JOBS=4
RATE_LIMIT_MAX=20
```

Do not submit placeholder brand/contact/domain values to Search Console or AdSense.

Run a final live-domain pass for HTTPS, mobile browsers, upload limits, PageSpeed/Core Web Vitals, consent/CMP behavior, and your hosting provider's CPU/RAM/timeouts.

See `DEPLOYMENT.md`, `ADSENSE-SEO-CHECKLIST.md`, `SUPPORTED-FORMATS.md`, `docs/UI-DESIGN.md`, and `docs/SEO-AUDIT-NOTES.md`.
