# AdSense + SEO release checklist

## AdSense / publisher safety

- [ ] Keep AdSense disabled until the live site contains only finished, useful pages.
- [ ] Do not add YouTube, TikTok, Instagram or other streaming-platform downloaders to this AdSense-first property.
- [ ] Public tool pages provide a real working tool plus original explanatory content.
- [ ] No ads on processing, user preview, result or download states.
- [ ] Ad units remain visibly separate from upload, convert, play, navigation and download controls.
- [ ] Never style an ad to resemble a download button or native tool control.
- [ ] Review all pages for prohibited/restricted content and misleading claims.
- [ ] Use a Google-certified CMP for EEA/UK/Switzerland before enabling ads there.
- [ ] Privacy Policy accurately reflects the actual deployed data flow and third-party services.
- [ ] Do not send uploaded filenames, file contents, signed URLs or user-entered sensitive data to ad/analytics systems.
- [ ] Configure ads.txt after receiving the real publisher ID.
- [ ] Do not buy bot traffic, click traffic, traffic-exchange traffic or encourage ad clicks.
- [ ] Keep ads subordinate to publisher content; do not overload pages with ads.

## SEO / search quality

- [ ] Permanent domain and HTTPS configured before serious indexing work.
- [ ] `SITE_URL` uses the final canonical HTTPS domain.
- [ ] Search Console property verified.
- [ ] Submit `/sitemap.xml`.
- [ ] Confirm `/robots.txt` allows public tools and blocks private job routes.
- [ ] Confirm every indexable tool page has a unique title, description, H1 and useful content.
- [ ] Avoid near-identical pages such as `/compress-to-1mb`, `/compress-to-2mb`, etc. unless each page has genuinely distinct user value.
- [ ] Keep private job/download URLs out of internal links that crawlers could discover broadly.
- [ ] Validate structured data; do not add fake reviews/ratings.
- [ ] Test Core Web Vitals/mobile usability on the production domain.
- [ ] Add original guides only where they answer real user questions.
- [ ] Expand tools using actual Search Console impressions and competitor evidence, not bulk page generation.

## Security / privacy

- [ ] Put conversion workers in isolated containers in production.
- [ ] Apply CPU, memory, process and execution time limits.
- [ ] Enable edge rate limiting and upload request limits.
- [ ] Require ClamAV or equivalent if your threat model demands server-side malware scanning.
- [ ] Use private object storage with signed URLs when moving beyond local-disk deployment.
- [ ] Configure provider-level lifecycle deletion in addition to application cleanup.
- [ ] Verify temporary files cannot be listed publicly.
- [ ] Test filenames with spaces/unicode and reject unsupported content by detected MIME.
- [ ] Keep logs free of original filenames and file content.

## Final human review

- [ ] No placeholder text, broken links, empty categories or "coming soon" pages.
- [ ] About, Contact, Privacy, Cookie, Terms, Copyright, Acceptable Use and Security pages contain the real brand/company/contact information.
- [ ] Mobile upload, settings and download flows work with touch targets and no horizontal scrolling.
- [ ] Every advertised tool is tested with representative files on the production runtime.
