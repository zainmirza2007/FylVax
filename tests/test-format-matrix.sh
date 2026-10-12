#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
PORT=${FORMAT_TEST_PORT:-3499}
BASE="http://127.0.0.1:$PORT"
LOG=/tmp/fylvex-format-matrix.log
PID=""
cleanup(){ if [ -n "${PID:-}" ]; then kill "$PID" 2>/dev/null || true; wait "$PID" 2>/dev/null || true; fi; }
trap cleanup EXIT
cd "$ROOT"
PORT=$PORT SITE_URL=$BASE RATE_LIMIT_MAX=1000 ADSENSE_ENABLED=false CMP_READY=false node server.js >"$LOG" 2>&1 & PID=$!
for _ in $(seq 1 60); do curl -fsS "$BASE/healthz" >/dev/null 2>&1 && break; sleep .25; done
curl -fsS "$BASE/healthz" | grep -q '"ok":true'
pass=0; fail=0
process_test(){
  local tool=$1 file=$2; shift 2
  local html out code link dcode size
  html=$(mktemp); out=$(mktemp)
  code=$(curl -sS -o "$html" -w '%{http_code}' -F "files=@$file" "$@" "$BASE/process/$tool" || true)
  if [ "$code" != "200" ]; then
    echo "FAIL $tool $(basename "$file") HTTP=$code :: $(grep -o 'class=\"error\">[^<]*' "$html" 2>/dev/null | head -1)"
    fail=$((fail+1)); rm -f "$html" "$out"; return
  fi
  link=$(grep -o 'href="/download/[^"]*"' "$html" | head -1 | sed 's/^href="//;s/"$//')
  if [ -z "$link" ]; then echo "FAIL $tool $(basename "$file") no download"; fail=$((fail+1)); rm -f "$html" "$out"; return; fi
  dcode=$(curl -sS -o "$out" -w '%{http_code}' "$BASE$link" || true)
  size=$(wc -c < "$out" 2>/dev/null || echo 0)
  if [ "$dcode" = "200" ] && [ "$size" -gt 0 ]; then
    echo "PASS $tool $(basename "$file")"
    pass=$((pass+1))
  else
    echo "FAIL $tool $(basename "$file") download=$dcode size=$size"
    fail=$((fail+1))
  fi
  rm -f "$html" "$out"
}

echo '[image accepted formats -> WebP]'
for f in "$ROOT"/tests/fixtures/matrix/image/*; do process_test convert-image "$f" -F output=webp; done

echo '[video accepted formats -> MP4]'
for f in "$ROOT"/tests/fixtures/matrix/video/*; do process_test convert-video "$f" -F output=mp4; done

echo '[audio accepted formats -> MP3]'
for f in "$ROOT"/tests/fixtures/matrix/audio/*; do process_test convert-audio "$f" -F output=mp3; done

echo '[office accepted formats -> PDF]'
for f in "$ROOT"/tests/fixtures/matrix/doc/word/* "$ROOT"/tests/fixtures/matrix/doc/sheet/* "$ROOT"/tests/fixtures/matrix/doc/slide/*; do process_test office-to-pdf "$f"; done

echo "FORMAT MATRIX SUMMARY pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
