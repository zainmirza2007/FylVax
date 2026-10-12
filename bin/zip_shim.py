import sys
import os
import zipfile

args = sys.argv[1:]
junk_paths = False
clean_args = []
for a in args:
    if a == '-j':
        junk_paths = True
    elif a == '-q':
        continue
    elif a.startswith('-'):
        continue
    else:
        clean_args.append(a)

if len(clean_args) >= 2:
    out_zip = clean_args[0]
    in_files = clean_args[1:]
    with zipfile.ZipFile(out_zip, 'w', compression=zipfile.ZIP_DEFLATED) as z:
        for f in in_files:
            actual_path = f
            if not os.path.exists(actual_path):
                alt = os.path.join(os.getcwd(), f)
                if os.path.exists(alt):
                    actual_path = alt
            if os.path.exists(actual_path):
                arcname = os.path.basename(actual_path) if junk_paths else actual_path
                z.write(actual_path, arcname)
elif len(clean_args) == 0:
    print("zip 3.0 (compatible shim)")
    sys.exit(0)
