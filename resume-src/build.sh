#!/bin/bash
# Rebuild the resume PDFs from the HTML sources in this folder.
#   ./build.sh            -> writes ../resume_{en,ja,zh}.pdf (the files linked from index.html)
#   ./build.sh OUT_DIR    -> writes OUT_DIR/resume_{en,ja,zh}.pdf (for previewing)
# Requires Google Chrome (macOS) or Chrome / Microsoft Edge (Windows Git Bash, Linux); set
# CHROME=/path/to/browser to override. Fonts are the macOS system fonts named in resume.css;
# elsewhere the Inter / Noto Sans web fonts linked from the HTML are used (needs network).
set -euo pipefail
cd "$(dirname "$0")"
out="$(mkdir -p "${1:-..}" && cd "${1:-..}" && pwd)"

chrome="${CHROME:-}"
for c in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
         "/c/Program Files/Google/Chrome/Application/chrome.exe" \
         "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" \
         "$(command -v google-chrome chromium 2>/dev/null | head -n 1)"; do
  if [ -z "$chrome" ] && [ -n "$c" ] && [ -x "$c" ]; then chrome="$c"; fi
done
[ -n "$chrome" ] || { echo "Chrome or Edge not found; set CHROME=/path/to/browser" >&2; exit 1; }

# On Windows the browser needs native paths (C:/...), which cygpath provides in Git Bash.
native() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi; }
profile="$(mktemp -d)"   # separate profile, so a running browser window does not take over the job
trap 'rm -rf "$profile"' EXIT

for lang in en ja zh; do
  pdf="$out/resume_$lang.pdf"
  rm -f "$pdf"
  src="$(native "$PWD/resume_$lang.html")"
  url="file://$( [ "${src:0:1}" = / ] || printf / )${src// /%20}"
  "$chrome" --headless --disable-gpu --no-pdf-header-footer --user-data-dir="$(native "$profile")" \
    --virtual-time-budget=20000 --print-to-pdf="$(native "$pdf")" "$url" >/dev/null 2>&1
  # Edge on Windows can return before the PDF is fully written: wait until its size settles.
  prev=-1
  for _ in $(seq 60); do
    size=$( [ -f "$pdf" ] && wc -c < "$pdf" | tr -d ' ' || echo 0 )
    if [ "$size" -gt 0 ] && [ "$size" = "$prev" ]; then break; fi
    prev=$size; sleep 0.5
  done
  pages=$(pdfinfo "$pdf" 2>/dev/null | awk '/^Pages/{print $2}' || true)
  [ -n "$pages" ] || pages=$(python3 -c "import fitz,sys; print(len(fitz.open(sys.argv[1])))" "$(native "$pdf")" 2>/dev/null || python -c "import fitz,sys; print(len(fitz.open(sys.argv[1])))" "$(native "$pdf")" 2>/dev/null || echo "?")
  echo "wrote $pdf ($pages pages)"
done
