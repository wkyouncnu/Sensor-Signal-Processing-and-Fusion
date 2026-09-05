#!/usr/bin/env bash
#
#  tikz2svg.sh — TikZ 그림 하나를 SVG 로 만든다.
#
#      bash _tools/tikz2svg.sh figures/src/w02-windup.tex figures/w02-windup.svg
#
#  왜 TikZ 인가. 손으로 SVG 좌표를 쓰면 화살촉·선 굵기·간격이 그림마다 미묘하게
#  달라지고, 그것이 "어설퍼 보인다" 의 정체다. TikZ 는 그 셋을 스타일로 한 번만
#  정하고 배치를 상대좌표(right=of, |-, -|)로 쓰므로, 좌표를 고쳐도 그림이
#  무너지지 않는다. 수식은 어차피 TeX 이라 본문과 같은 글꼴로 나온다.
#
#  경로: TeX --(latex)--> DVI --(dvisvgm)--> SVG
#    * pdflatex 가 아니라 **latex** 를 쓴다. dvisvgm 이 DVI 를 받을 때
#      선과 글자를 **벡터 path** 로 뽑아 주기 때문이다.
#    * --no-fonts 로 글리프를 path 로 바꾼다. 그래야 폰트가 없는
#      컴퓨터에서도, Chrome 의 PDF 파이프라인에서도 똑같이 보인다.
#    * --exact-bbox 로 여백을 그림에 맞춘다.
#
#  TinyTeX 은 %APPDATA%\TinyTeX 에 있고 PATH 에 없을 수 있으므로 여기서 붙인다.
set -u
[ $# -lt 1 ] && { sed -n '3,22p' "$0"; exit 1; }

SRC="$1"
OUT="${2:-${SRC%.tex}.svg}"
[ -f "$SRC" ] || { echo "no such file: $SRC" >&2; exit 1; }

for d in "/c/Users/admin/AppData/Roaming/TinyTeX/bin/windows" \
         "/c/texlive/2026/bin/windows" "/c/texlive/2025/bin/windows"; do
  [ -d "$d" ] && PATH="$d:$PATH"
done
export PATH
command -v latex   >/dev/null || { echo "latex not found — TinyTeX 설치 확인" >&2; exit 1; }
command -v dvisvgm >/dev/null || { echo "dvisvgm not found — tlmgr install dvisvgm" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
base="$(basename "${SRC%.tex}")"
#  \input{gnc-style} 같은 형제 파일이 있으므로 소스 폴더의 .tex 를 전부 옮긴다
cp "$(dirname "$SRC")"/*.tex "$TMP/" 2>/dev/null || cp "$SRC" "$TMP/"

( cd "$TMP" && latex -interaction=nonstopmode -halt-on-error "$base.tex" >latex.log 2>&1 )
if [ ! -f "$TMP/$base.dvi" ]; then
  echo "latex failed — 마지막 30 줄:" >&2
  tail -30 "$TMP/latex.log" >&2
  exit 1
fi

( cd "$TMP" && dvisvgm --exact-bbox --no-fonts \
                       --output="$base.svg" "$base.dvi" >dvisvgm.log 2>&1 )
[ -f "$TMP/$base.svg" ] || { echo "dvisvgm failed:" >&2; tail -20 "$TMP/dvisvgm.log" >&2; exit 1; }

mkdir -p "$(dirname "$OUT")"
cp "$TMP/$base.svg" "$OUT"

#  dvisvgm 은 width/height 를 pt 로 쓴다. 이 볼트의 나머지 도구(svg2png.sh)와
#  브라우저는 px 를 기대하므로 96/72 로 바꿔 둔다. viewBox 는 그대로 두어
#  좌표계가 흔들리지 않게 한다.
awk '
  /<svg / && !did {
    if (match($0, /width=.[0-9.]+pt./)) {
      wv = substr($0, RSTART+7, RLENGTH-10) + 0
      sub(/width=.[0-9.]+pt./, sprintf("width=\"%.2f\"", wv*96/72))
    }
    if (match($0, /height=.[0-9.]+pt./)) {
      hv = substr($0, RSTART+8, RLENGTH-11) + 0
      sub(/height=.[0-9.]+pt./, sprintf("height=\"%.2f\"", hv*96/72))
    }
    did = 1
  }
  { print }
' "$OUT" > "$OUT.tmp" && cat "$OUT.tmp" > "$OUT" && rm -f "$OUT.tmp"

#  vault_check 는 SVG 에 흰 배경 사각형을 요구한다 (투명 배경은 PDF 에서 비친다).
#  dvisvgm 은 배경을 넣지 않으므로 여기서 첫 <g> 앞에 하나 깐다.
awk '
  /<svg/ && !done {
    print
    vb = $0
    if (match(vb, /viewBox=.[^"'"'"']*/)) {
      s = substr(vb, RSTART+9, RLENGTH-9)
      split(s, V, / +/)
      printf "<rect x=\"%s\" y=\"%s\" width=\"%s\" height=\"%s\" fill=\"#ffffff\"/>\n", V[1], V[2], V[3], V[4]
    }
    done = 1
    next
  }
  { print }
' "$OUT" > "$OUT.tmp" && cat "$OUT.tmp" > "$OUT" && rm -f "$OUT.tmp"

echo "  wrote $OUT  ($(grep -o 'width=.[0-9.]*pt' "$OUT" | head -1))"
bash "$(dirname "${BASH_SOURCE[0]}")/svg2png.sh" "$OUT"
