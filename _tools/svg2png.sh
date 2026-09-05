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
#  정수일 수도, 소수일 수도 있다 — dvisvgm 이 만든 SVG 는 소수를 쓴다.
#  올림해서 창 크기로 삼는다. 잘리는 것보다 한 픽셀 남는 편이 낫다.
W=$(grep -oE 'width="[0-9]+([.][0-9]+)?"' "$SVG" | head -1 |
    grep -oE '[0-9]+([.][0-9]+)?' | awk '{printf "%d", int($1)+1}')
H=$(grep -oE 'height="[0-9]+([.][0-9]+)?"' "$SVG" | head -1 |
    grep -oE '[0-9]+([.][0-9]+)?' | awk '{printf "%d", int($1)+1}')
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
