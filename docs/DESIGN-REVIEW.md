# Fylvex design review — 12 October 2026

Implemented a quieter shared design across the homepage, tool directory, categories, tool forms, guides, legal pages and result screens. The existing Node server and conversion handlers remain in place; no production dependencies were added.

## Changes

- Neutral backgrounds, restrained purple accent, system typography, lighter borders and fewer decorative blocks.
- Homepage search and common tasks precede file categories. Repeated marketing statistics and badges were removed.
- Tool instructions use plain language. Duplicate guidance was consolidated; unique format support, limitations, FAQs and related links remain available.
- Responsive navigation, visible keyboard focus, a skip link, an explicit search empty state and keyboard access to results.
- Search supports words in different orders. Hidden results now stay hidden. Returning from processing restores the submit button.
- The configured ad slot sits after explanatory tool content, outside the form, with an Advertisement label and reserved space. Existing consent/configuration gates remain intact. No live advertising was enabled.

## Verification

- Syntax checks passed for server.js and public/app.js.
- All 63 sitemap pages returned HTTP 200 with one H1, unique titles, descriptions, expected canonical URLs and parseable JSON-LD where present.
- Private process, result and download error routes retain noindex responses.
- Browser checks covered seven representative pages at 375, 768, 1024 and 1440 pixels: 28 layouts without horizontal overflow. Internal links on those pages resolve to sitemap entries.
- Search matching, empty results, keyboard focus, mobile navigation, file selection, compression settings, FAQ expansion, multipart submission and back navigation passed in Chrome. Submission was intercepted to inspect fields; this does not verify file conversion.
- BeyondSEO HTTP crawls inspected the same four pages before and after: homepage, tool directory, image compression and PDF compression. Both returned four complete captures, no failed pages and zero crawler findings. The other 59 sitemap pages were outside these focused native crawls.
- A separate local server with dummy ad configuration verified one labelled slot after content and no ad code on the homepage, directory or private error pages. No requests to Google advertising services were made. That test server was stopped.

## Limits

This is a local design implementation, not a deployment or AdSense approval. The local runtime reports missing Ghostscript, LibreOffice, file/ZIP utilities and required Python packages. Complete conversion tests need a ready conversion runtime. Live consent behavior, real ad creatives, Core Web Vitals, rankings and indexing were not measured.

Backups, before/after crawls and screenshots are stored outside the website in the chat's private `fylvex-review` folder. The preview runs at http://localhost:3100.

The repeatable browser check is `tests/ui-review.cjs`. Set `PLAYWRIGHT_MODULE` to an existing Playwright installation and optionally `BASE_URL` and `SCREENSHOT_DIR`, then run it with Node. The server should use a matching SITE_URL and have ads disabled. Chrome is required by this check.

## Guidance consulted

- [Google AdSense ad placement policies](https://support.google.com/adsense/answer/1346295?hl=en)
- [Google Search developer guidance](https://developers.google.com/search/docs/fundamentals/get-started-developers)
- [Google guidance on helpful content](https://developers.google.com/search/docs/fundamentals/creating-helpful-content)
- BeyondSEO website-work and crawler instructions; UI/UX Pro Max minimalism guidance; Ponytail implementation guidance.
