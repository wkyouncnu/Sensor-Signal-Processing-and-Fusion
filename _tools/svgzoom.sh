#!/usr/bin/env bash
#
#  svgzoom.sh — 그림의 한 조각을 확대해서 본다.
#
#      bash _tools/svgzoom.sh figures/w01-pqr.svg 3 out.png [x y w h]
#
#  svg2png.sh 는 1:1 로 뽑는다. 작은 라벨이 겹쳤는지 눈으로 가리기에는
#  그것으로 모자랄 때가 있어서, 배율과 잘라낼 영역을 받는 판을 따로 둔다.
#  영역은 원본 SVG 픽셀 좌표다. 주면 그 부분만, 안 주면 전체를 확대한다.
set -u
SVG="$1"; Z="${2:-2}"; OUT="${3:-${SVG%.svg}-zoom.png}"
X="${4:-0}"; Y="${5:-0}"

W=$(grep -oE 'width="[0-9]+([.][0-9]+)?"' "$SVG" | head -1 | grep -oE '[0-9]+([.][0-9]+)?')
H=$(grep -oE 'height="[0-9]+([.][0-9]+)?"' "$SVG" | head -1 | grep -oE '[0-9]+([.][0-9]+)?')
CW="${6:-$W}"; CH="${7:-$H}"

CHROME=""
for c in "/c/Program Files/Google/Chrome/Application/chrome.exe" \
         "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe" \
         "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"; do
  [ -f "$c" ] && { CHROME="$c"; break; }
done
[ -z "$CHROME" ] && { echo "Chrome or Edge not found"; exit 1; }

#  임시 HTML 은 출력 파일 옆에 둔다. /tmp 는 Git Bash 와 Chrome 이 서로 다른
#  곳으로 해석해서 Chrome 이 파일을 못 찾는 일이 있었다.
TMP="$(dirname "$(realpath -m "$OUT")")/svgzoom_$$.html"
WIN_SVG=$(cygpath -w "$(realpath "$SVG")" 2>/dev/null || echo "$SVG")
cat > "$TMP" <<HTML
<html><body style="margin:0;background:#fff">
<div style="position:relative;overflow:hidden;
            width:$(awk "BEGIN{printf \"%d\", $CW*$Z}")px;
            height:$(awk "BEGIN{printf \"%d\", $CH*$Z}")px">
<img src="file:///${WIN_SVG//\\//}"
     style="position:absolute;
            left:$(awk "BEGIN{printf \"%d\", -$X*$Z}")px;
            top:$(awk "BEGIN{printf \"%d\", -$Y*$Z}")px;
            width:$(awk "BEGIN{printf \"%d\", $W*$Z}")px">
</div></body></html>
HTML

WIN_TMP=$(cygpath -w "$TMP" 2>/dev/null || echo "$TMP")
WIN_OUT=$(cygpath -w "$(realpath -m "$OUT")" 2>/dev/null || echo "$OUT")
rm -f "$OUT"
"$CHROME" --headless --disable-gpu --no-sandbox --hide-scrollbars \
          --default-background-color=FFFFFFFF \
          --window-size="$(awk "BEGIN{printf \"%d\", $CW*$Z}"),$(awk "BEGIN{printf \"%d\", $CH*$Z}")" \
          --user-data-dir="${WIN_OUT%\\*}\\svgzoom_profile" \
          --screenshot="$WIN_OUT" "file:///${WIN_TMP//\\//}" >/dev/null 2>&1 
rm -f "$TMP"
[ -f "$OUT" ] && echo "  $OUT   zoom ${Z}x  of ${CW}x${CH} at (${X},${Y})" || { echo "  FAILED"; exit 1; }
