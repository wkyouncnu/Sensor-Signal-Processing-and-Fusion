#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# week_refs.sh — 주차 번호를 바꿨을 때 낡은 상호참조를 찾는다.
#
#   2026-09-05 에 W04(유도)와 W05(배분)의 순서를 바꿨더니 다섯 자료에서
#   14 군데가 조용히 어긋났고, 전부 사람이 읽어서 찾아야 했다.
#
#   낱말 하나로 대조하면 오탐이 너무 많다("following" 은 아무 데나 나온다).
#   그래서 **주차를 유일하게 지목하는 여러 낱말짜리 구절**만 본다.
#   구절이 나온 줄에 다른 주차 번호가 붙어 있으면 찍는다.
#
#   사용법:  bash .claude/skills/gnc-lecture-vault/scripts/week_refs.sh
#   합격선: 0 건. 새 주차를 만들면 아래 표에 한 줄 더한다.
# ---------------------------------------------------------------------------
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
cd "$ROOT" || exit 1

#  구절|그 구절이 가리키는 주차 번호
PHRASES='control allocation|5
line-of-sight|4
line of sight|4
LOS guidance|4
waypoint following|4
waypoint switching|4
cross-track error|4
wave filtering|6
dynamic positioning|7'

bad=0
while IFS='|' read -r phrase wk; do
  [ -n "$phrase" ] || continue
  #  그 구절이 있는 줄 가운데, 자기 주차가 아닌 "Week N" 을 함께 담은 줄
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    echo "  $hit"
    bad=$((bad+1))
  done < <(grep -rniE "$phrase" lectures/*.md 2>/dev/null \
           | grep -oE "^[^:]+:[0-9]+:.*" \
           | grep -E "Week [0-9]+" \
           | grep -vE "Week $wk\b" \
           | sed "s/$/   <- '$phrase' 는 ${wk}주차/" \
           | cut -c1-200)
done <<< "$PHRASES"

echo
if [ "$bad" -eq 0 ]; then
  echo "  주차 상호참조 통과 — 0 건"
else
  echo "  주차 상호참조 $bad 건 — PLAN.md §2 의 주차표와 대조할 것"
fi
exit 0
