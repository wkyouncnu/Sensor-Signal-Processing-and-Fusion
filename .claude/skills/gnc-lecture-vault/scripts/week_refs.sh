#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# week_refs.sh — 주차 번호를 바꿨을 때 낡은 상호참조를 찾는다.
#
#   2026-09-05 에 W05(유도)와 W06(배분)의 순서를 바꿨더니 다섯 자료에서
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
#
#  이 표는 **PLAN.md §2 의 주차표를 손으로 베낀 것**이다. 주차를 밀면 여기도
#  밀어야 한다 — 2026-10-27 에 W06(선수추진기)을 넣고 뒤를 한 칸씩 밀었더니
#  이 표가 옛 번호를 들고 있어서 W07·W08·W09 의 제 번호를 틀렸다고 7 건 찍었다.
#  **표가 낡으면 옳은 문서가 틀렸다고 나온다** — 그쪽이 더 위험하다.
PHRASES='bow thruster|6
berthing|6
control allocation|7
line-of-sight|5
line of sight|5
LOS guidance|5
waypoint following|5
waypoint switching|5
cross-track error|5
wave filtering|8
dynamic positioning|9
PID fundamentals|2
surge speed control|3
heading control|4'

bad=0
while IFS='|' read -r phrase wk; do
  [ -n "$phrase" ] || continue
  #  그 구절 **바로 옆**(25 자 안)에 자기 주차가 아닌 "Week N" 이 붙은 줄.
  #
  #  줄 전체를 보면 안 된다. 긴 산문 한 줄에는 그 주차의 낱말과 다른 주차의
  #  정당한 앞뒤 참조가 함께 들어 있다 — "cross-track error … — Week 4 §4-4" 는
  #  옳은 문장이다. 2026-10-27 에 줄 전체를 보던 판정이 그런 줄 여섯 개를
  #  집어냈고, `cut -c1-200` 이 표식을 잘라 내는 바람에 vault_check 의 집계에만
  #  안 잡혀서 **우연히** 0 건으로 보였다. 그래서 둘을 함께 고쳤다 —
  #  판정은 붙어 있는 것만 보고, 표식은 자른 뒤에 붙인다.
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    echo "  $hit"
    bad=$((bad+1))
  done < <(grep -rniE "$phrase" lectures/*.md 2>/dev/null \
           | grep -oE "^[^:]+:[0-9]+:.*" \
           | grep -iE "(Week [0-9]+.{0,25}$phrase|$phrase.{0,25}Week [0-9]+)" \
           | grep -vE "Week $wk\b" \
           | cut -c1-160 \
           | sed "s/$/   <- '$phrase' 는 ${wk}주차/")
done <<< "$PHRASES"

echo
if [ "$bad" -eq 0 ]; then
  echo "  주차 상호참조 통과 — 0 건"
else
  echo "  주차 상호참조 $bad 건 — PLAN.md §2 의 주차표와 대조할 것"
fi
exit 0
