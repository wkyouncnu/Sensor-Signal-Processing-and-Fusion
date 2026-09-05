#!/usr/bin/env bash
#
#  tex2svg.sh — TeX 한 줄을 그림에 붙일 수 있는 SVG 조각으로 바꾼다.
#
#      bash _tools/tex2svg.sh 'y_e = \Delta\tan\beta_c'
#      bash _tools/tex2svg.sh -s 16 -x 40 -y 120 'K_p = 1/\Delta'
#      bash _tools/tex2svg.sh -f list.tex -s 15 -o build/
#
#  왜 필요한가. 개념도 안의 수식을 `e_x`·`X_cmd` 처럼 평문으로 쓰면 본문의
#  MathJax 조판과 글꼴도 모양도 달라 보인다. 유니코드 아래첨자로 흉내내면
#  아예 없는 글자를 만나 틀린다 → standing-orders.md §5-2.
#  그래서 PDF 파이프라인이 쓰는 것과 **같은 MathJax 번들**로 조판해서
#  그 결과 path 를 그대로 SVG 에 심는다. 본문 수식과 글자 하나까지 같아진다.
#
#  옵션
#    -s N   글자 크기 [px], 기본 16
#    -x N   붙일 자리의 x, 기본 0
#    -y N   붙일 자리의 y — **기준선(baseline)** 이다, 기본 0
#    -a A   가로 정렬 start|middle|end, 기본 start
#    -f F   TeX 을 한 줄에 하나씩 담은 파일 (여러 개를 한 번에)
#    -o D   -f 와 함께. 결과를 D/0.svg, D/1.svg … 로 쓴다
#    -p F   배치목록 파일.  x | y | size | align | TeX  한 줄에 하나.
#           수식마다 자리와 크기가 다른 그림 한 장을 한 번에 만든다
#    -d     display 스타일. 기본은 inline
#
#  출력은 <g transform="translate(x,y) scale(s)"> … </g> 하나와,
#  폭·높이·어센트를 px 로 적은 주석 한 줄. 배치 계산에 그 주석을 쓴다.
#
#  TeX 문자열은 **base64 로** 페이지에 넘긴다. 역슬래시를 셸·awk·JSON 세 번
#  통과시키면 어디선가 반드시 반토막이 나기 때문이다. 실제로 한 번 그랬다.
set -u

SIZE=16; PX=0; PY=0; ALIGN=start; LIST=""; OUTDIR=""; DISP=false; PLACE=""; PLACEMODE=0
while getopts "s:x:y:a:f:o:p:d" opt; do
  case "$opt" in
    s) SIZE="$OPTARG" ;;  x) PX="$OPTARG" ;;  y) PY="$OPTARG" ;;
    a) ALIGN="$OPTARG" ;; f) LIST="$OPTARG" ;; o) OUTDIR="$OPTARG" ;;
    p) PLACE="$OPTARG" ;;
    d) DISP=true ;;
    *) sed -n '3,27p' "$0"; exit 1 ;;
  esac
done
shift $((OPTIND-1))

TOOLS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MJ="$TOOLS/mathjax-tex-svg.js"
[ -f "$MJ" ] || { echo "no mathjax bundle: $MJ" >&2; exit 1; }

CHROME=""
for c in "/c/Program Files/Google/Chrome/Application/chrome.exe" \
         "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe" \
         "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"; do
  [ -f "$c" ] && { CHROME="$c"; break; }
done
[ -z "$CHROME" ] && { echo "Chrome or Edge not found" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

#  -p 배치목록 모드. 한 줄에 하나:
#
#      x | y | size | align | TeX
#
#  이 모드가 있는 이유는 하나다. TeX 을 셸 인자로 넘기면 따옴표와 역슬래시가
#  bash·perl·awk 를 지나며 반드시 어딘가에서 반토막 난다 (`\hat\beta` 가
#  `hateta` 가 된 적이 있다). 목록을 **파일로** 두면 셸을 통과하지 않는다.
if [ -n "${PLACE:-}" ]; then
  [ -f "$PLACE" ] || { echo "no such file: $PLACE" >&2; exit 1; }
  awk -F'[ \t]*\\|[ \t]*' 'NF>=6 && $1 !~ /^[ \t]*#/ {
        t=$6; for(i=7;i<=NF;i++) t = t "|" $i; print t }' "$PLACE" > "$TMP/place.tex"
  awk -F'[ \t]*\\|[ \t]*' 'NF>=6 && $1 !~ /^[ \t]*#/ {
        print $1, $2, $3, $4, $5 }' "$PLACE" > "$TMP/place.meta"
  SRC="$TMP/place.tex"
  PLACEMODE=1
elif [ -n "$LIST" ]; then
  [ -f "$LIST" ] || { echo "no such file: $LIST" >&2; exit 1; }
  SRC="$LIST"
else
  [ $# -ge 1 ] || { sed -n '3,27p' "$0"; exit 1; }
  printf '%s\n' "$1" > "$TMP/in.tex"
  SRC="$TMP/in.tex"
fi

B64="$(base64 -w0 < "$SRC")"

#  fontCache 를 끄지 않으면 글리프가 공용 <defs> 로 빠지고 <use> 로만 참조되어,
#  조각을 떼어내면 글자가 사라진다. 반드시 'none'.
{
  echo '<!doctype html><meta charset="utf-8"><body><div id="out"></div>'
  echo '<script>window.MathJax={startup:{typeset:false},svg:{fontCache:"none"}};</script>'
  echo '<script>'
  cat "$MJ"
  echo '</script>'
  echo '<script>'
  echo "var B64=\"$B64\"; var DISP=$DISP;"
  echo 'var TXT = decodeURIComponent(escape(atob(B64)));'
  echo 'var L = TXT.split("\n").filter(function(s){return s.length>0;});'
  echo 'MathJax.startup.promise.then(function(){'
  echo '  var out=document.getElementById("out");'
  echo '  L.forEach(function(tex,i){'
  echo '    var svg=MathJax.tex2svg(tex,{display:DISP}).querySelector("svg");'
  echo '    var d=document.createElement("div");'
  echo '    d.className="M"; d.setAttribute("data-i",i);'
  echo '    d.setAttribute("data-vb", svg.getAttribute("viewBox"));'
  echo '    d.textContent = svg.innerHTML;'
  echo '    out.appendChild(d);'
  echo '  });'
  echo '  document.title="DONE";'
  echo '});'
  echo '</script></body>'
} > "$TMP/p.html"

"$CHROME" --headless --disable-gpu --no-sandbox --virtual-time-budget=20000 \
          --dump-dom "file:///$(cygpath -m "$TMP/p.html")" 2>/dev/null > "$TMP/dom.html"

grep -q 'class="M"' "$TMP/dom.html" || { echo "MathJax produced nothing" >&2; exit 1; }

[ -n "$OUTDIR" ] && mkdir -p "$OUTDIR"

#  <div class="M" data-i=N data-vb="a b c d">본문</div> 을 하나씩 꺼내 <g> 로 감싼다.
#  MathJax 의 viewBox 단위는 1 em = 1000 이므로 배율은 size/1000 이다.
awk -v size="$SIZE" -v px="$PX" -v py="$PY" -v align="$ALIGN" -v outdir="$OUTDIR" \
    -v pmode="$PLACEMODE" -v pmeta="$TMP/place.meta" '
  BEGIN {
    if (pmode) { np = 0; while ((getline ln < pmeta) > 0) { np++; split(ln, F, " ")
                   MX[np]=F[1]; MY[np]=F[2]; MS[np]=F[3]; MA[np]=F[4]; MC[np]=F[5] } }
  }
  { line = line $0 "\n" }
  END {
    m = split(line, part, "<div class=\"M\"")
    for (k = 2; k <= m; k++) {
      j = k-1
      s = part[k]
      vb = s; sub(/^.*data-vb="/, "", vb); sub(/".*/, "", vb)
      split(vb, V, / +/)
      body = s; sub(/^[^>]*>/, "", body); sub(/<\/div>.*/, "", body)
      gsub(/&lt;/,  "<", body)
      gsub(/&gt;/,  ">", body)
      gsub(/&quot;/, "\"", body)
      gsub(/&amp;/, "\\&", body)
      if (pmode) { ux=MX[j]+0; uy=MY[j]+0; us=MS[j]+0; ua=MA[j]; uc=MC[j] }
      else       { ux=px+0;    uy=py+0;    us=size+0;  ua=align;  uc="-"   }
      sc = us/1000.0
      w  = V[3]*sc; h = V[4]*sc; asc = -V[2]*sc
      dx = (ua == "middle") ? -w/2 : (ua == "end" ? -w : 0)
      tx = ux + dx - V[1]*sc
      f = (outdir == "") ? "/dev/stdout" : sprintf("%s/%d.svg", outdir, k-2)
      pre  = (uc == "-" || uc == "") ? "" : sprintf("<g fill=\"%s\">", uc)
      post = (pre == "") ? "" : "</g>"
      printf "%s<g transform=\"translate(%.3f,%.3f) scale(%.6f)\">%s</g>%s\n", pre, tx, uy, sc, body, post > f
      if (!pmode)
        printf "<!-- tex2svg w=%.2f h=%.2f ascent=%.2f descent=%.2f -->\n", w, h, asc, h-asc > f
    }
  }
' "$TMP/dom.html"
