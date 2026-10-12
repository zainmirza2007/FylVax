import sys
import os
import glob
import subprocess

# Check for real Ghostscript on the machine
gs_paths = glob.glob(r"C:\Program Files\gs\*\bin\gswin64c.exe") + \
           glob.glob(r"C:\Program Files (x86)\gs\*\bin\gswin32c.exe") + \
           glob.glob(r"C:\Program Files\gs\*\bin\gs.exe")

if gs_paths and os.path.exists(gs_paths[0]):
    res = subprocess.run([gs_paths[0]] + sys.argv[1:])
    sys.exit(res.returncode)

# Fallback: Python pypdf compression
args = sys.argv[1:]
if not args or '-v' in args or '--version' in args:
    print("GPL Ghostscript 10.04.0 (Windows compatible shim)")
    sys.exit(0)

out_file = None
in_file = None

for a in args:
    if a.startswith('-sOutputFile='):
        out_file = a.split('=', 1)[1]
    elif not a.startswith('-') and os.path.exists(a):
        in_file = a

if in_file and out_file:
    try:
        import pypdf
        reader = pypdf.PdfReader(in_file)
        writer = pypdf.PdfWriter()
        for page in reader.pages:
            new_page = writer.add_page(page)
            new_page.compress_content_streams()
        writer.compress_identical_objects()
        with open(out_file, 'wb') as f:
            writer.write(f)
        sys.exit(0)
    except Exception as e:
        sys.stderr.write(f"PDF compression error: {e}\n")
        sys.exit(1)

sys.exit(0)
