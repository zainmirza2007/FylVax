# Supported formats — Fylvex 2.0

This list describes formats intentionally configured and tested in the release package. It does **not** claim that every file format ever created is supported; there are thousands of proprietary and legacy formats, and internal codecs/encryption/corruption can affect otherwise valid files.

## Images

Universal Image Converter / Compressor / Resize / Target Size / Metadata tools accept:

`JPG, JPEG, JFIF, PNG, WEBP, AVIF, HEIC, HEIF, TIF, TIFF, BMP, GIF, ICO, PSD, TGA, PCX, PNM, PPM, PGM`

Universal image conversion exports `WebP`, `JPG`, or `PNG`.

HEIC/HEIF/AVIF inputs are decoded through libheif before ImageMagick processing. For compression with **Auto** output, modern/less practical source formats may be exported to WebP instead of preserving the original container.

## Video

Universal Video Converter, Video Compressor, Resize Video and Extract Audio accept:

`MP4, MOV, M4V, WEBM, MKV, AVI, FLV, WMV, MPG, MPEG, M2V, TS, MTS, M2TS, 3GP, 3G2, OGV, VOB, ASF`

Universal conversion exports `MP4` or `WebM`. Compression and resizing export MP4.

A video without an audio stream cannot produce an extracted-audio result; this is a content limitation, not a container-format failure.

## Audio

Universal Audio Converter and Audio Compressor accept:

`MP3, WAV, M4A, AAC, FLAC, OGG, OPUS, WMA, AIFF, AIF, AC3, CAF`

Universal conversion exports `MP3` or `WAV`. Audio compression exports MP3.

## Office documents

Office to PDF accepts:

- Word/text: `DOC, DOCX, ODT, RTF, TXT`
- Spreadsheets: `XLS, XLSX, ODS, CSV`
- Presentations: `PPT, PPTX, ODP`

Specific Word/Excel/PowerPoint pages accept the matching subset above.

## PDF

PDF tools accept ordinary PDF files for compression, merge, split, page extraction/deletion/rotation, and PDF-to-image conversion. Password-protected, corrupted, or unusual PDFs may require the user to unlock or repair the file first.

## Intentionally not accepted

The release does not accept executables, archives as generic conversion inputs, streaming-platform URLs, or arbitrary unknown binary files. SVG is not accepted by the image upload tools in this release because XML/vector inputs require a separate security model. Streaming/social downloaders are deliberately excluded from this AdSense-first product.
