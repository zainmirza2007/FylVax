#!/usr/bin/env python3
import sys, os, fitz
from PIL import Image
Image.init()

cmd = sys.argv[1]

if cmd == 'images_to_pdf':
    out = sys.argv[2]
    inputs = sys.argv[3:]
    imgs=[]
    for p in inputs:
        im=Image.open(p)
        if im.mode in ('RGBA', 'LA') or (im.mode == 'P' and 'transparency' in im.info):
            bg = Image.new('RGB', im.size, (255, 255, 255))
            rgba = im.convert('RGBA')
            bg.paste(rgba, mask=rgba.split()[3])
            imgs.append(bg)
        else:
            imgs.append(im.convert('RGB'))
    if not imgs: raise SystemExit('No images')
    imgs[0].save(out, save_all=True, append_images=imgs[1:])

elif cmd == 'rotate':
    src, out, deg = sys.argv[2], sys.argv[3], int(sys.argv[4])
    doc=fitz.open(src)
    for page in doc:
        page.set_rotation((page.rotation + deg) % 360)
    doc.save(out)

elif cmd in ('extract','delete'):
    src, out, spec = sys.argv[2], sys.argv[3], sys.argv[4]
    doc=fitz.open(src)
    wanted=set()
    for token in spec.split(','):
        token=token.strip()
        if not token: continue
        if '-' in token:
            a,b=token.split('-',1)
            for x in range(int(a), int(b)+1): wanted.add(x-1)
        else: wanted.add(int(token)-1)
    wanted={i for i in wanted if 0 <= i < len(doc)}
    if cmd=='delete':
        keep=[i for i in range(len(doc)) if i not in wanted]
    else:
        keep=sorted(wanted)
    if not keep: raise SystemExit('No pages remain')
    outdoc=fitz.open()
    for i in keep:
        outdoc.insert_pdf(doc, from_page=i, to_page=i)
    outdoc.save(out)

else:
    raise SystemExit('Unknown command')
