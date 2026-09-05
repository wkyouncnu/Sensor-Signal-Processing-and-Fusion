#!/usr/bin/env bash
#
#  svg2png.sh — render a figure the way a reader will actually see it.
#
#      bash _tools/svg2png.sh figures/w04-los-geometry.svg  [out.png]
#
#  The standing order is to RENDER a figure and look at it before publishing,
#  and again after fixing it. A preview pane that scales the drawing to fit
#  its own width is not that check: labels that overlap at one zoom can look
#  clear at another, and the coordinates in the file are the only truth.
#
#  This uses the same headless Chrome the PDF pipeline uses, at 1:1, so what
#  comes out is what the PDF will contain.

set -u
[ $# -lt 1 ] && { echo "usage: svg2png.sh <file.svg> [out.png]"; exit 1; }

SVG="$1"
OUT="${2:-${SVG%.svg}.png}"
[ -f "$SVG" ] || { echo "no such file: $SVG"; exit 1; }

CHROME=""
for c in "/c/Program Files/Google/Chrome/Application/chrome.exe" \
         "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe" \
         "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"; do
  [ -f "$c" ] && { CHROME="$c"; break; }
done
[ -z "$CHROME" ] && { echo "Chrome or Edge not found"; exit 1; }

#  The size comes from the SVG itself, so the PNG is 1:1 with the drawing.
W=$(grep -o 'width="[0-9]*"' "$SVG" | head -1 | tr -dc '0-9')
H=$(grep -o 'height="[0-9]*"' "$SVG" | head -1 | tr -dc '0-9')
: "${W:=900}"; : "${H:=470}"

WIN_SVG=$(cygpath -w "$(realpath "$SVG")" 2>/dev/null || echo "$SVG")
WIN_OUT=$(cygpath -w "$(realpath -m "$OUT")" 2>/dev/null || echo "$OUT")

rm -f "$OUT"
"$CHROME" --headless --disable-gpu --no-sandbox --hide-scrollbars \
          --default-background-color=FFFFFFFF \
          --window-size="$W,$H" \
          --screenshot="$WIN_OUT" "file:///${WIN_SVG//\\//}" >/dev/null 2>&1

if [ -f "$OUT" ]; then
    echo "  $OUT   ${W}x${H}"
else
    echo "  FAILED to render $SVG"
    exit 1
fi
