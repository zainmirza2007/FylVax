#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
PORT=${TEST_PORT:-3199}
BASE="http://127.0.0.1:$PORT"
LOG=/tmp/fylvex-test-server.log
PID=""
cleanup(){ if [ -n "${PID:-}" ]; then kill "$PID" 2>/dev/null || true; wait "$PID" 2>/dev/null || true; fi; }
trap cleanup EXIT

cd "$ROOT"
PORT=$PORT SITE_URL=$BASE RATE_LIMIT_MAX=100 ADSENSE_ENABLED=false CMP_READY=false node server.js >"$LOG" 2>&1 &
PID=$!
for _ in $(seq 1 40); do
  if curl -fsS "$BASE/healthz" >/dev/null 2>&1; then break; fi
  sleep .25
done
curl -fsS "$BASE/healthz" | grep -q '"ok":true'

echo "[1/6] Public routes"
for route in / /tools/ /compress/ /convert/ /pdf/ /image/ /video/ /audio/ /document/ /guides/ /about/ /contact/ /privacy/ /cookie-policy/ /terms/ /copyright/ /acceptable-use/ /security/ /formats/ /robots.txt /sitemap.xml /ads.txt; do
  curl -fsS "$BASE$route" >/dev/null
  echo "PASS $route"
done

echo "[2/6] SEO structure"
python3 - "$BASE" <<'PY'
import re, sys, urllib.request, urllib.parse, xml.etree.ElementTree as ET
base=sys.argv[1]
def get(path):
    with urllib.request.urlopen(base+path, timeout=10) as r:
        return r.read().decode('utf-8','replace'), dict(r.headers)
xml,_=get('/sitemap.xml')
root=ET.fromstring(xml)
urls=[e.text for e in root.findall('{http://www.sitemaps.org/schemas/sitemap/0.9}url/{http://www.sitemaps.org/schemas/sitemap/0.9}loc')]
assert len(urls)==63, f'expected 63 sitemap URLs, got {len(urls)}'
assert len(urls)==len(set(urls)), 'duplicate sitemap URLs'
tool_urls=[u for u in urls if re.search(r'/(pdf|image|video|audio|document)/[^/]+$',u)]
assert len(tool_urls)==38, f'expected 38 tool URLs, got {len(tool_urls)}'
titles=[]; descs=[]; canon=[]; h1s=[]; guidance=[]
for u in tool_urls:
    path=u[len(base):] if u.startswith(base) else urllib.parse.urlparse(u).path
    html,_=get(path)
    title=re.search(r'<title>(.*?)</title>',html,re.S)
    desc=re.search(r'<meta name="description" content="([^"]*)"',html)
    ca=re.search(r'<link rel="canonical" href="([^"]+)"',html)
    h1=re.findall(r'<h1>(.*?)</h1>',html,re.S)
    assert title and desc and ca and len(h1)==1, f'metadata/H1 problem: {path}'
    assert 'When to use it' in html and 'Simple workflow' in html and 'Privacy by design' in html, f'missing useful tool content: {path}'
    titles.append(title.group(1)); descs.append(desc.group(1)); canon.append(ca.group(1)); h1s.append(h1[0])
    m=re.search(r'Made for the task, not just the keyword</h2><p>(.*?)</p>',html,re.S)
    guidance.append(m.group(1) if m else '')
assert len(titles)==len(set(titles)), 'tool titles not unique'
assert len(descs)==len(set(descs)), 'tool descriptions not unique'
assert len(canon)==len(set(canon)), 'canonicals not unique'
assert len(guidance)==len(set(guidance)), 'tool guidance not unique'
robots,_=get('/robots.txt')
for p in ['/process/','/result/','/download/']:
    assert f'Disallow: {p}' in robots
print(f'PASS sitemap={len(urls)} tool_pages={len(tool_urls)} unique_metadata=yes unique_guidance=yes')
PY

echo "[3/6] Privacy/indexing and default ad safety"
HEADERS=$(mktemp); BODY=$(mktemp)
curl -sS -D "$HEADERS" -o "$BODY" "$BASE/download/not-a-real-job"
grep -qi '^x-robots-tag:.*noindex' "$HEADERS"
if curl -fsS "$BASE/pdf/compress-pdf" | grep -q 'adsbygoogle'; then echo 'FAIL ads rendered by default'; exit 1; fi
curl -fsS "$BASE/pdf/compress-pdf" | grep -q '<meta name="robots" content="index,follow'
curl -fsS "$BASE/privacy/" | grep -q 'Privacy Policy'
echo "PASS private noindex + ads off by default"
rm -f "$HEADERS" "$BODY"

echo "[4/6] Conversion suite"
BASE="$BASE" FIX="$ROOT/tests/fixtures" bash "$ROOT/tests/run-conversions.sh"

echo "[5/6] AdSense configuration gate"
cleanup; PID=""
PORT2=$((PORT+1)); BASE2="http://127.0.0.1:$PORT2"; LOG2=/tmp/fylvex-ad-gate.log
PORT=$PORT2 SITE_URL=$BASE2 RATE_LIMIT_MAX=100 ADSENSE_ENABLED=true CMP_READY=false ADSENSE_PUBLISHER_ID=ca-pub-1234567890123456 ADSENSE_SLOT_CONTENT=1234567890 node server.js >"$LOG2" 2>&1 & PID=$!
for _ in $(seq 1 40); do curl -fsS "$BASE2/healthz" >/dev/null 2>&1 && break; sleep .25; done
if curl -fsS "$BASE2/pdf/compress-pdf" | grep -q 'adsbygoogle'; then echo 'FAIL ads rendered without CMP readiness'; exit 1; fi
curl -fsS "$BASE2/pdf/compress-pdf" | grep -q 'meta name="google-adsense-account" content="ca-pub-1234567890123456"'
echo 'PASS publisher verification meta present while ads remain blocked when CMP_READY=false'
cleanup; PID=""
PORT3=$((PORT+2)); BASE3="http://127.0.0.1:$PORT3"; LOG3=/tmp/fylvex-ad-enabled.log
PORT=$PORT3 SITE_URL=$BASE3 RATE_LIMIT_MAX=100 ADSENSE_ENABLED=true CMP_READY=true ADSENSE_PUBLISHER_ID=ca-pub-1234567890123456 ADSENSE_SLOT_CONTENT=1234567890 node server.js >"$LOG3" 2>&1 & PID=$!
for _ in $(seq 1 40); do curl -fsS "$BASE3/healthz" >/dev/null 2>&1 && break; sleep .25; done
curl -fsS "$BASE3/pdf/compress-pdf" | grep -q 'adsbygoogle'
if curl -fsS "$BASE3/privacy/" | grep -q 'adsbygoogle'; then echo 'FAIL ad found on privacy page'; exit 1; fi
RESULT=$(curl -fsS -F "files=@$ROOT/tests/fixtures/test.jpg" "$BASE3/process/jpg-to-png")
echo "$RESULT" | grep -q 'meta name="robots" content="noindex,nofollow,noarchive"'
if echo "$RESULT" | grep -q 'adsbygoogle'; then echo 'FAIL ad found in private processing result'; exit 1; fi
curl -fsS "$BASE3/ads.txt" | grep -q 'google.com, pub-1234567890123456, DIRECT, f08c47fec0942fa0'
echo 'PASS ads require full config; legal/private states remain ad-free'

echo "[6/6] Syntax and accessibility hooks"
node --check server.js
python3 -m py_compile scripts/pdf_tools.py
curl -fsS "$BASE3/pdf/compress-pdf" | grep -q 'aria-live="polite"'
curl -fsS "$BASE3/" | grep -q 'aria-expanded="false"'
grep -q '@media' public/styles.css
echo 'PASS syntax + responsive/accessibility hooks'

echo 'ALL TESTS PASSED'
