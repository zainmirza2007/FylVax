import sys
import mimetypes
import os

args = sys.argv[1:]
target = None
for a in args:
    if not a.startswith('-') and os.path.exists(a):
        target = a
        break

if target:
    # Use mimetypes or magic detection
    ext = os.path.splitext(target)[1].lower()
    custom_map = {
        '.heic': 'image/heic',
        '.heif': 'image/heif',
        '.avif': 'image/avif',
        '.webp': 'image/webp',
        '.pdf': 'application/pdf',
        '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        '.pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        '.ts': 'video/mp2t',
        '.mts': 'video/mp2t',
        '.m2ts': 'video/mp2t',
    }

    if ext in custom_map:
        print(custom_map[ext])
    else:
        mime, _ = mimetypes.guess_type(target)
        print(mime or 'application/octet-stream')
else:
    print('application/octet-stream')
