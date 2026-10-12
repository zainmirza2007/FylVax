#!/usr/bin/env bash
set -u
BASE=${BASE:-http://127.0.0.1:3010}
FIX=${FIX:-/mnt/data/fylvex-ready/tests/fixtures}
OUT=/tmp/fylvex-test-results
rm -rf "$OUT" && mkdir -p "$OUT"
pass=0; fail=0
run_test(){
  name=$1; shift
  html="$OUT/$name.html"
  code=$(curl -sS -o "$html" -w '%{http_code}' "$@" "$BASE/process/$name" || echo 000)
  if [ "$code" != "200" ]; then echo "FAIL $name HTTP=$code :: $(grep -o 'class="error">[^<]*' "$html" 2>/dev/null | head -1)"; fail=$((fail+1)); return; fi
  link=$(grep -o 'href="/download/[^"]*"' "$html" | head -1 | sed 's/^href="//;s/"$//')
  if [ -z "$link" ]; then echo "FAIL $name no download link"; fail=$((fail+1)); return; fi
  dcode=$(curl -sS -o "$OUT/$name.out" -w '%{http_code}' "$BASE$link" || echo 000)
  size=$(wc -c < "$OUT/$name.out" 2>/dev/null || echo 0)
  if [ "$dcode" = "200" ] && [ "$size" -gt 0 ]; then echo "PASS $name ($size bytes)"; pass=$((pass+1)); else echo "FAIL $name download=$dcode size=$size"; fail=$((fail+1)); fi
}
F=(-F)
run_test compress-pdf -F files=@$FIX/test1.pdf -F level=balanced
run_test merge-pdf -F files=@$FIX/test1.pdf -F files=@$FIX/test2.pdf
run_test split-pdf -F files=@$FIX/test1.pdf
run_test pdf-to-jpg -F files=@$FIX/test1.pdf
run_test pdf-to-png -F files=@$FIX/test1.pdf
run_test jpg-to-pdf -F files=@$FIX/test.jpg
run_test png-to-pdf -F files=@$FIX/test.png
run_test rotate-pdf -F files=@$FIX/test1.pdf -F degrees=90
run_test extract-pdf-pages -F files=@$FIX/test1.pdf -F pages=1-2
run_test delete-pdf-pages -F files=@$FIX/test1.pdf -F pages=2
run_test convert-image -F files=@$FIX/test.avif -F output=webp
run_test compress-image -F files=@$FIX/test.jpg -F quality=75 -F output=auto
run_test resize-image -F files=@$FIX/test.jpg -F width=320
run_test reduce-image-size -F files=@$FIX/test.webp -F targetKb=3
run_test jpg-to-png -F files=@$FIX/test.jpg
run_test png-to-jpg -F files=@$FIX/test.png
run_test webp-to-png -F files=@$FIX/test.webp
run_test png-to-webp -F files=@$FIX/test.png
run_test jpg-to-webp -F files=@$FIX/test.jpg
run_test heic-to-jpg -F files=@$FIX/test.heic
run_test remove-image-metadata -F files=@$FIX/test.jpg
run_test convert-video -F files=@$FIX/test.mov -F output=webm
run_test compress-video -F files=@$FIX/test.mp4 -F targetMb=1
run_test mov-to-mp4 -F files=@$FIX/test.mov
run_test webm-to-mp4 -F files=@$FIX/test.webm
run_test mp4-to-webm -F files=@$FIX/test.mp4
run_test mp4-to-gif -F files=@$FIX/test.mp4
run_test extract-audio -F files=@$FIX/test.mp4
run_test resize-video -F files=@$FIX/test.mp4 -F width=160
run_test convert-audio -F files=@$FIX/test.m4a -F output=mp3
run_test mp3-to-wav -F files=@$FIX/test.mp3
run_test wav-to-mp3 -F files=@$FIX/test.wav
run_test m4a-to-mp3 -F files=@$FIX/test.m4a
run_test compress-audio -F files=@$FIX/test.wav -F bitrate=64k
run_test office-to-pdf -F files=@$FIX/test.docx
run_test word-to-pdf -F files=@$FIX/test.docx
run_test excel-to-pdf -F files=@$FIX/test.xlsx
run_test powerpoint-to-pdf -F files=@$FIX/test.pptx

echo "SUMMARY pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
