#!/bin/bash
# Rebuild the resume PDFs from the HTML sources in this folder.
#   ./build.sh            -> writes ../resume_{en,ja,zh}.pdf (the files linked from index.html)
#   ./build.sh OUT_DIR    -> writes OUT_DIR/resume_{en,ja,zh}.pdf (for previewing)
# Requires Google Chrome; fonts are the macOS system fonts named in resume.css.
set -euo pipefail
cd "$(dirname "$0")"
out="${1:-..}"
chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
for lang in en ja zh; do
  "$chrome" --headless --disable-gpu --no-pdf-header-footer \
    --print-to-pdf="$out/resume_$lang.pdf" "file://$PWD/resume_$lang.html" 2>/dev/null
  echo "wrote $out/resume_$lang.pdf ($(pdfinfo "$out/resume_$lang.pdf" 2>/dev/null | awk '/^Pages/{print $2}') pages)"
done
