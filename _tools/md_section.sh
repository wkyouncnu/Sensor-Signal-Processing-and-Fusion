#!/usr/bin/env bash
#  md_section.sh — 큰 .md 에서 **한 절만** 꺼낸다
#
#  강의 `.md` 는 145~185 KB 다. 한 절을 보려고 통째로 읽으면 한 번에
#  60,000 토큰이 들어가고, 그것만으로 작업 여유가 사라진다. 2026-10-27 에
#  재 보니 고정 비용이 이미 창의 48 % 였다 → standing-orders.md §15-65
#
#  쓰는 법
#    bash _tools/md_section.sh <file.md> <절>     그 절만 (하위 절 포함)
#    bash _tools/md_section.sh -l <file.md>       절 목록 — 줄번호·바이트
#    bash _tools/md_section.sh -n <file.md> <절>  줄 범위만 (A,B 꼴)
#
#  <절> 은 제목의 **앞머리**로 찾는다. 번호만 주면 된다.
#    bash _tools/md_section.sh lectures/W06_*.md 6-7
#    bash _tools/md_section.sh lectures/W06_*.md "Part 2"
#  찾은 제목과 같거나 **더 높은 수준**의 다음 제목에서 멈춘다.
#  코드펜스(```) 안의 `#` 는 제목으로 세지 않는다.
set -u

usage() { sed -n '2,20p' "$0" | sed 's/^#  \{0,1\}//'; exit 2; }

MODE=print
case "${1:-}" in
  -l) MODE=list; shift ;;
  -n) MODE=range; shift ;;
  -h|--help|'') usage ;;
esac

F="${1:-}"; KEY="${2:-}"
[ -f "$F" ] || { echo "md_section: 그런 파일이 없다 — $F" >&2; exit 1; }
[ "$MODE" = list ] || [ -n "$KEY" ] || usage

#  제목을 한 번에 모은다 — 수준 · 줄번호 · 제목
HEADS="$(awk '
  /^```/        { fence = !fence; next }
  fence         { next }
  /^#+[ \t]/    { n = index($0, " "); lvl = 0
                  for (i = 1; i <= length($0); i++) {
                    if (substr($0, i, 1) == "#") lvl++; else break }
                  t = substr($0, lvl + 1); sub(/^[ \t]+/, "", t)
                  printf "%d\t%d\t%s\n", lvl, FNR, t }
' "$F")"

if [ "$MODE" = list ]; then
  printf '%s\n' "$HEADS" | awk -F'\t' -v tot="$(wc -l < "$F")" '
    { lvl[NR] = $1; ln[NR] = $2; ti[NR] = $3; n = NR }
    END { for (i = 1; i <= n; i++) {
            end = (i < n ? ln[i+1] - 1 : tot)
            indent = ""
            for (j = 2; j <= lvl[i]; j++) indent = indent "  "
            printf "%6d–%-6d %4d 줄  %s%s\n", ln[i], end, end - ln[i] + 1, indent, ti[i] } }'
  exit 0
fi

#  KEY 로 시작하는 제목 중 **첫 번째**. 없으면 어디든 들어 있는 것으로 한 번 더.
HIT="$(printf '%s\n' "$HEADS" | awk -F'\t' -v k="$KEY" '
  index($3, k) == 1 { print; exit }')"
[ -n "$HIT" ] || HIT="$(printf '%s\n' "$HEADS" | awk -F'\t' -v k="$KEY" '
  index($3, k) { print; exit }')"

if [ -z "$HIT" ]; then
  echo "md_section: '$KEY' 로 시작하는 절이 없다. 목록은 -l 로 본다." >&2
  exit 1
fi

LVL="${HIT%%	*}"; REST="${HIT#*	}"; A="${REST%%	*}"; TITLE="${REST#*	}"

#  같거나 더 높은 수준의 다음 제목 전까지
B="$(printf '%s\n' "$HEADS" | awk -F'\t' -v lvl="$LVL" -v a="$A" '
  $2 > a && $1 <= lvl { print $2 - 1; exit }')"
[ -n "$B" ] || B="$(wc -l < "$F")"

if [ "$MODE" = range ]; then echo "$A,$B"; exit 0; fi

printf '%s\n' "sed -n '$A,${B}p' $F   # ${TITLE}  ($((B - A + 1)) 줄)" >&2
sed -n "$A,${B}p" "$F"
