#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
PORT=${BROAD_TEST_PORT:-3599}
BASE="http://127.0.0.1:$PORT"
LOG=/tmp/fylvex-broad-modules.log
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
  if [ "$code" != "200" ]; then echo "FAIL $tool $(basename "$file") HTTP=$code :: $(grep -o 'class=\"error\">[^<]*' "$html" 2>/dev/null | head -1)"; fail=$((fail+1)); rm -f "$html" "$out"; return; fi
  link=$(grep -o 'href="/download/[^"]*"' "$html" | head -1 | sed 's/^href="//;s/"$//')
  if [ -z "$link" ]; then echo "FAIL $tool $(basename "$file") no download"; fail=$((fail+1)); rm -f "$html" "$out"; return; fi
  dcode=$(curl -sS -o "$out" -w '%{http_code}' "$BASE$link" || true)
  size=$(wc -c < "$out" 2>/dev/null || echo 0)
  if [ "$dcode" = "200" ] && [ "$size" -gt 0 ]; then echo "PASS $tool $(basename "$file")"; pass=$((pass+1)); else echo "FAIL $tool $(basename "$file") download=$dcode size=$size"; fail=$((fail+1)); fi
  rm -f "$html" "$out"
}

for tool in compress-image resize-image reduce-image-size remove-image-metadata; do
  echo "[$tool across all advertised image formats]"
  for f in "$ROOT"/tests/fixtures/matrix/image/*; do
    case "$tool" in
      compress-image) process_test "$tool" "$f" -F quality=82 -F output=auto;;
      resize-image) process_test "$tool" "$f" -F width=640 -F output=auto;;
      reduce-image-size) process_test "$tool" "$f" -F targetKb=300 -F output=webp;;
      remove-image-metadata) process_test "$tool" "$f" -F output=auto;;
    esac
  done
done

echo '[compress-video across all advertised video containers]'
for f in "$ROOT"/tests/fixtures/matrix/video/*; do process_test compress-video "$f"; done

echo '[compress-audio across all advertised audio formats]'
for f in "$ROOT"/tests/fixtures/matrix/audio/*; do process_test compress-audio "$f" -F bitrate=96k; done

echo '[specific Office modules across their full accepted families]'
for f in "$ROOT"/tests/fixtures/matrix/doc/word/*; do process_test word-to-pdf "$f"; done
for f in "$ROOT"/tests/fixtures/matrix/doc/sheet/*; do process_test excel-to-pdf "$f"; done
for f in "$ROOT"/tests/fixtures/matrix/doc/slide/*; do process_test powerpoint-to-pdf "$f"; done

echo "BROAD MODULE SUMMARY pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
