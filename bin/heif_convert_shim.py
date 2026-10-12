import sys
import subprocess
import os

args = sys.argv[1:]
quality = "90"
clean_args = []
i = 0
while i < len(args):
    if args[i] == '-q' and i + 1 < len(args):
        quality = args[i + 1]
        i += 2
    elif args[i].startswith('-'):
        i += 1
    else:
        clean_args.append(args[i])
        i += 1

if len(clean_args) >= 2:
    inp, out = clean_args[0], clean_args[1]
    cmd = ['ffmpeg', '-y', '-i', inp]
    if out.lower().endswith('.jpg') or out.lower().endswith('.jpeg'):
        cmd.extend(['-q:v', '2'])
    cmd.append(out)
    res = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    sys.exit(res.returncode)
else:
    print("heif-convert (compatible shim)")
    sys.exit(0)
