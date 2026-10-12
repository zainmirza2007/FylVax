import sys
import os
import glob
import subprocess
from PIL import Image, ImageOps

# If a real ImageMagick installation exists on the machine, delegate to it
real_magick = glob.glob(r"C:\Program Files\ImageMagick*\magick.exe") + \
              glob.glob(r"C:\Program Files (x86)\ImageMagick*\magick.exe")

if real_magick and os.path.exists(real_magick[0]):
    res = subprocess.run([real_magick[0]] + sys.argv[1:])
    sys.exit(res.returncode)

args = sys.argv[1:]
if not args or '-version' in args or '--version' in args:
    print("Version: ImageMagick 7.1.1-41 Q16-HDRI x64 (Pillow-backed shim)")
    print("Copyright: (C) 1999 ImageMagick Studio LLC")
    sys.exit(0)

# Check for -ping / info: (ImageMagick inspection / validation mode)
if '-ping' in args or 'info:' in args:
    target = None
    for a in args:
        if a not in ('-ping', 'info:') and not a.startswith('-') and os.path.exists(a):
            target = a
            break
    if target:
        try:
            with Image.open(target) as im:
                print(f"{target} {im.format} {im.size[0]}x{im.size[1]} 8-bit")
            sys.exit(0)
        except Exception as e:
            sys.stderr.write(f"Image decode error: {e}\n")
            sys.exit(1)
    sys.exit(0)

# Parse ImageMagick conversion / compression options
quality = None
resize_str = None
bg_white = False

src = None
out = None

# In ImageMagick conversion: args[0] is src, args[-1] is out
if len(args) >= 2 and not args[0].startswith('-') and not args[-1].startswith('-'):
    src = args[0]
    out = args[-1]
    opt_args = args[1:-1]
else:
    # Fallback linear scanner
    opt_args = []
    for a in args:
        if not a.startswith('-'):
            if src is None:
                src = a
            else:
                out = a
        else:
            opt_args.append(a)

i = 0
while i < len(opt_args):
    a = opt_args[i]
    if a == '-quality' and i + 1 < len(opt_args):
        try:
            quality = int(opt_args[i + 1])
        except ValueError:
            pass
        i += 2
    elif a == '-resize' and i + 1 < len(opt_args):
        resize_str = opt_args[i + 1]
        i += 2
    elif a == '-background' and i + 1 < len(opt_args):
        if opt_args[i + 1].lower() == 'white':
            bg_white = True
        i += 2
    elif a in ('-alpha', '-auto-orient', '-strip', '-coalesce', '-layers'):
        if a in ('-alpha', '-layers') and i + 1 < len(opt_args):
            i += 2
        else:
            i += 1
    else:
        i += 1

if not src or not out:
    sys.exit(0)

try:
    with Image.open(src) as im:
        # Auto orient from EXIF
        try:
            im = ImageOps.exif_transpose(im)
        except Exception:
            pass

        # Handle resize
        if resize_str:
            parts = resize_str.lower().split('x')
            target_w = int(parts[0]) if parts[0].isdigit() else None
            target_h = int(parts[1]) if len(parts) > 1 and parts[1].isdigit() else None
            if target_w and not target_h:
                ratio = target_w / im.width
                target_h = max(1, int(im.height * ratio))
                im = im.resize((target_w, target_h), Image.Resampling.LANCZOS)
            elif target_w and target_h:
                im.thumbnail((target_w, target_h), Image.Resampling.LANCZOS)

        out_ext = os.path.splitext(out)[1].lower()
        if not out_ext:
            # If no extension was given, infer from src
            out_ext = os.path.splitext(src)[1].lower() or '.jpg'

        if out_ext in ('.jpg', '.jpeg'):
            if bg_white or im.mode in ('RGBA', 'LA') or (im.mode == 'P' and 'transparency' in im.info):
                bg = Image.new('RGB', im.size, (255, 255, 255))
                rgba = im.convert('RGBA')
                bg.paste(rgba, mask=rgba.split()[3])
                im = bg
            elif im.mode != 'RGB':
                im = im.convert('RGB')
            save_opts = {'format': 'JPEG', 'optimize': True}
            if quality:
                save_opts['quality'] = quality
            im.save(out, **save_opts)
        elif out_ext == '.webp':
            save_opts = {'format': 'WEBP'}
            if quality:
                save_opts['quality'] = quality
            im.save(out, **save_opts)
        elif out_ext == '.png':
            im.save(out, format='PNG', optimize=True)
        elif out_ext == '.gif':
            im.save(out, format='GIF', optimize=True)
        else:
            im.save(out)
    sys.exit(0)
except Exception as e:
    # Fallback to ffmpeg if pillow fails
    try:
        cmd = ['ffmpeg', '-y', '-i', src]
        if quality and out.lower().endswith(('.jpg', '.jpeg')):
            qscale = max(2, min(31, int(31 - (quality * 29 / 100))))
            cmd.extend(['-q:v', str(qscale)])
        cmd.append(out)
        res = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
        if res.returncode == 0 and os.path.exists(out):
            sys.exit(0)
    except Exception:
        pass
    sys.stderr.write(f"Image processing error: {e}\n")
    sys.exit(1)
