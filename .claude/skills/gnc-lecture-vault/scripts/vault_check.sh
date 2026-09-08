#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# vault_check.sh — GradCourse 볼트 점검
#
#   사용법 (Git Bash, GradCourse 루트에서)
#     bash .claude/skills/gnc-lecture-vault/scripts/vault_check.sh
#     bash .claude/skills/gnc-lecture-vault/scripts/vault_check.sh --style
#     bash .claude/skills/gnc-lecture-vault/scripts/vault_check.sh --links
#     bash .claude/skills/gnc-lecture-vault/scripts/vault_check.sh --figs
#
#   합격선은 전 항목 0 건.
#   CLAUDE.md 와 스킬 문서는 규칙을 설명하려고 금지 표현을 인용하므로 검사에서 뺀다.
# ---------------------------------------------------------------------------
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
cd "$ROOT" || exit 1
[ -d lectures ] || { echo "오류: GradCourse 루트를 찾을 수 없습니다 ($ROOT)"; exit 1; }

MODE="${1:-all}"
FAIL=0
note()  { printf '  %-44s %s\n' "$1" "$2"; }
head2() { printf '\n%s\n' "$1"; }

# 검사 대상 MD — 템플릿·스킬 문서·규칙 원본은 제외
#
# 벤더링한 남의 코드(MSS 등)도 제외한다. 그 안의 README 는 우리가 쓴 글이 아니고,
# 우리 문체 규칙(1·2인칭 금지)이나 PDF 짝 규칙을 적용할 대상이 아니다.
# 실제로 MSS-master 가 lectures/ 안에 놓이자 그 세 README 가 12건의 허위 지적을
# 냈다. 검사기가 남의 파일을 고치라고 말하기 시작하면 검사기를 못 믿게 된다.
VENDOR='/MSS-master/|/MSS/|/node_modules/'

mds() {
  find . -name '*.md' -type f \
    | grep -v '/\.claude/' \
    | grep -v '/_templates/' \
    | grep -v '/slprj/' \
    | grep -vE "$VENDOR" \
    | grep -v '^\./CLAUDE\.md$' \
    | sort
}

# 배포하는 문서 — PDF 쌍과 문체 검사의 대상
#
# 폴더 색인용 README 는 뺀다. 다만 **실습 문제지와 답안지는 학생이 받는 배포물**
# 이므로 이름이 README.md 라도 뺄 수 없다: 사용자 지시 2026-09-08,
# "숙제도 MD 파일만 있는데 PDF로도 변환해서 같은 폴더에 넣어줘".
#   빠지는 것  lectures/README.md,  lectures/WXX_simulink/README.md
#   들어가는 것 lectures/WXX_simulink/problems|solutions/README.md
delivered() {
  mds | grep -E '^\./lectures/' \
      | grep -vE '^\./lectures/README\.md$' \
      | grep -vE '^\./lectures/[^/]+/README\.md$'
}

# 실습이 딸린 문서 — 주차와 부록. 접두사는 파일명의 첫 '_' 앞부분 (W01, A1 ...)
labdocs() {
  { find lectures -maxdepth 1 -name 'W*.md' -type f 2>/dev/null
    find lectures -maxdepth 1 -name 'A*.md' -type f 2>/dev/null; } | sort
}

# 규칙을 인용한 예시가 걸리지 않도록 코드블록·인라인 코드를 지운 사본으로 본다
strip_code() { awk '/^```/{f=!f; next} !f' "$1" | sed 's/`[^`]*`//g'; }

# ── 1. MD ↔ PDF 쌍 ────────────────────────────────────────────────────────
check_pdf() {
  head2 "1. MD - PDF 쌍"
  local miss=0 stale=0 f pdf
  while IFS= read -r f; do
    pdf="${f%.md}.pdf"
    if [ ! -f "$pdf" ]; then
      echo "     [PDF 없음] $f"; miss=$((miss+1))
    elif [ "$f" -nt "$pdf" ]; then
      echo "     [PDF 가 오래됨] $f"; stale=$((stale+1))
    fi
  done < <(delivered)
  note "PDF 누락" "$miss"
  note "PDF 가 MD 보다 오래됨" "$stale"
  [ $stale -gt 0 ] && echo "     -> bash _tools/md2pdf.sh <파일.md>"
  FAIL=$((FAIL+miss+stale))
  return 0
}

# ── 2. 링크와 그림 참조 ───────────────────────────────────────────────────
check_links() {
  head2 "2. wikilink"
  local bad=0 f raw name
  while IFS= read -r f; do
    while IFS= read -r raw; do
      name="${raw%%|*}"; name="${name%%#*}"
      [ -z "$name" ] && continue
      if ! find . -name "$name.md" -type f 2>/dev/null | grep -q .; then
        echo "     [깨짐] $f  ->  [[$name]]"; bad=$((bad+1))
      fi
    done < <(strip_code "$f" | sed 's/!\[\[/@@IMG@@/g' | grep -o '\[\[[^]]*\]\]' \
             | sed 's/^\[\[//; s/\]\]$//' | sort -u)
  done < <(mds)
  note "깨진 wikilink" "$bad"
  FAIL=$((FAIL+bad))

  head2 "3. 그림 참조가 실재하는가"
  local img=0 d p
  while IFS= read -r f; do
    d="$(dirname "$f")"
    while IFS= read -r p; do
      case "$p" in http*|data:*) continue ;; esac
      [ -f "$d/$p" ] || { echo "     [없음] $f  ->  $p"; img=$((img+1)); }
    done < <(grep -o '](\([^)]*\.\(svg\|png\|jpg\|jpeg\|gif\)\))' "$f" \
             | sed 's/^](//; s/)$//' | sort -u)
  done < <(mds)
  note "없는 그림" "$img"
  FAIL=$((FAIL+img))

  head2 "4. Obsidian 전용 임베드"
  local emb=0
  while IFS= read -r f; do
    if strip_code "$f" | grep -q '!\[\['; then echo "     $f"; emb=$((emb+1)); fi
  done < <(mds)
  note "Obsidian 임베드를 쓴 문서" "$emb"
  FAIL=$((FAIL+emb))
  return 0
}

# ── 3. 그림과 수식 — references/results-and-figures.md 의 규칙 ────────────
check_figs() {
  head2 "5. 주차·부록마다 블록도 1장, 결과 그래프 1장"
  local nodiag=0 nores=0 f dir tag nd nr
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    tag="$(basename "$f" | cut -d_ -f1)"          # W01, A1 ...
    dir="$(dirname "$f")/${tag}_simulink"
    if [ ! -d "$dir" ]; then
      echo "     [실습 폴더 없음] $dir"; nodiag=$((nodiag+1)); nores=$((nores+1)); continue
    fi
    # 블록도 = .slx 와 같은 이름의 PNG. 결과 그래프 = _result 를 포함하는 PNG
    nd=0; nr=0
    while IFS= read -r p; do
      case "$(basename "$p")" in
        *_result*.png) nr=$((nr+1)) ;;
        *.png)         nd=$((nd+1)) ;;
      esac
    done < <(grep -o "](${tag}_simulink/img/[^)]*\.png)" "$f" 2>/dev/null \
             | sed 's/^](//; s/)$//' | sort -u)
    [ "$nd" -ge 1 ] || { echo "     [블록도 없음] $f"; nodiag=$((nodiag+1)); }
    [ "$nr" -ge 1 ] || { echo "     [결과 그래프 없음] $f"; nores=$((nores+1)); }
  done < <(labdocs)
  note "블록도 PNG 가 없는 주차" "$nodiag"
  note "결과 그래프 PNG 가 없는 주차" "$nores"
  FAIL=$((FAIL+nodiag+nores))

  head2 "6. PNG 가 빌더보다 새것인가"
  #  .slx 와 비교하지 않는다. Simulink 는 모델을 **열기만 해도** .slx 를 다시 써서
  #  mtime 이 올라가고, 한 폴더에 모델이 셋이면 H 절 모델을 연 것 때문에 D 절 그림이
  #  낡았다고 나온다. 실제 의존성은 사람이 고치는 **빌더 스크립트**다.
  local stale=0 bld png
  while IFS= read -r bld; do
    d="$(dirname "$bld")"
    [ -d "$d/img" ] || continue
    for png in "$d"/img/*.png; do
      [ -f "$png" ] || continue
      if [ "$bld" -nt "$png" ]; then
        echo "     [낡음] $png  <  $(basename "$bld")"; stale=$((stale+1))
      fi
    done
  done < <(find lectures \( -name 'build_*.m' -o -name '*_build_*.m' \) -type f 2>/dev/null | grep -vE "$VENDOR" | sort)
  note "빌더보다 오래된 PNG" "$stale"
  [ $stale -gt 0 ] && echo "     -> 그 주차의 절 스크립트를 다시 돌린다 (WXX_C_… 부터)"
  FAIL=$((FAIL+stale))

  head2 "7. 블록도 PNG 폭"
  local wide=0 w
  if command -v identify >/dev/null 2>&1; then
    while IFS= read -r png; do
      w=$(identify -format '%w' "$png" 2>/dev/null || echo 0)
      [ "$w" -gt 2000 ] && { echo "     [너무 넓음] $png  ${w}px"; wide=$((wide+1)); }
    done < <(find lectures -path '*/img/*.png' ! -name '*_result*' -type f 2>/dev/null | grep -vE "$VENDOR")
  else
    # ImageMagick 이 없으면 PNG 헤더에서 직접 읽는다 (IHDR 의 첫 4바이트)
    while IFS= read -r png; do
      w=$(od -An -tu4 -j16 -N4 --endian=big "$png" 2>/dev/null | tr -d ' ')
      [ -z "$w" ] && continue
      [ "$w" -gt 2000 ] && { echo "     [너무 넓음] $png  ${w}px"; wide=$((wide+1)); }
    done < <(find lectures -path '*/img/*.png' ! -name '*_result*' -type f 2>/dev/null | grep -vE "$VENDOR")
  fi
  note "폭 2000px 초과 블록도" "$wide"
  FAIL=$((FAIL+wide))

  head2 "8. 블록 수식 \$\$ 의 짝"
  local odd=0 n
  while IFS= read -r f; do
    n=$(awk '/^```/{c=!c; next} !c' "$f" | grep -o '\$\$' | wc -l)
    if [ $((n % 2)) -ne 0 ]; then echo "     [짝이 안 맞음] $f  (\$\$ x $n)"; odd=$((odd+1)); fi
  done < <(mds)
  note "짝이 맞지 않는 \$\$" "$odd"
  FAIL=$((FAIL+odd))
  return 0
}

# ── 4. 문체 — 강의자료는 영어 정식 어조 ──────────────────────────────────
check_style() {
  head2 "9. 금지 표현 (배포 문서)"
  # \b 로 단어 경계를 잡아 in-you-endo 류의 오탐을 막는다
  local words=('\byou\b' '\byour\b' "\byou're\b" '\bwe\b' '\bour\b' "\bwe'll\b" \
               '\btoday\b' '\blet us\b' "\blet's\b" '\bnowadays\b')
  local w n total=0 f hits
  for w in "${words[@]}"; do
    n=0
    while IFS= read -r f; do
      hits=$(strip_code "$f" | grep -oiE -- "$w" | wc -l)
      if [ "$hits" -gt 0 ]; then n=$((n+hits)); echo "     $f  ($hits x ${w//\\b/})"; fi
    done < <(delivered)
    [ "$n" -gt 0 ] && printf '  %-44s %s\n' "${w//\\b/}" "$n"
    total=$((total+n))
  done
  note "1·2인칭 · 시점 표현 합계" "$total"
  FAIL=$((FAIL+total))

  head2 "10. 이모지 · 장식 기호"
  local emo=0
  while IFS= read -r f; do
    hits=$(strip_code "$f" | grep -oP '[\x{1F300}-\x{1FAFF}\x{2600}-\x{27BF}\x{2B00}-\x{2BFF}]' 2>/dev/null | wc -l)
    [ -z "$hits" ] && hits=0
    if [ "$hits" -gt 0 ]; then echo "     $f  ($hits)"; emo=$((emo+hits)); fi
  done < <(delivered)
  note "이모지 · 장식 기호" "$emo"
  FAIL=$((FAIL+emo))

  head2 "11. 콜아웃 종류"
  local badc=0
  while IFS= read -r f; do
    hits=$(grep -oh '> \[![a-z]*\]' "$f" 2>/dev/null \
           | grep -vcE '\[!(note|tip|important|warning|caution|info)\]')
    if [ "$hits" -gt 0 ]; then echo "     $f  ($hits)"; badc=$((badc+hits)); fi
  done < <(mds)
  note "미지원 콜아웃" "$badc"
  FAIL=$((FAIL+badc))
  return 0
}

# ── 5. SVG · 잔여물 ───────────────────────────────────────────────────────
check_svg() {
  head2 "12. SVG 흰 배경"
  local bad=0 s
  for s in figures/*.svg; do
    [ -f "$s" ] || continue
    grep -qiE 'fill="#(ffffff|fff)"' "$s" || { echo "     [배경 없음] $s"; bad=$((bad+1)); }
  done
  note "흰 배경 사각형이 없는 SVG" "$bad"
  FAIL=$((FAIL+bad))

  head2 "13. 남은 잔여물"
  local n
  n=$( { find . -name '*.bak'; find . -name '*.orig'; find . -name '.md2pdf_*.html'; \
         find . -name '_check.html'; } 2>/dev/null | wc -l )
  note "*.bak / *.orig / 임시 HTML" "$n"
  FAIL=$((FAIL+n))
  return 0
}

# 14. 주차 상호참조 — 주차 번호를 바꾸면 다른 자료가 조용히 낡는다
check_weeks() {
  head2 "14. 주차 상호참조 (PLAN.md §2 의 주차표)"
  local out n
  out="$(bash "$(dirname "${BASH_SOURCE[0]}")/week_refs.sh" 2>/dev/null)"
  n=$(printf "%s" "$out" | grep -c "<- " || true)
  printf "%s
" "$out" | grep "<- " | sed "s/^/  /"
  note "PLAN 의 주차와 어긋나는 참조" "$n"
  FAIL=$((FAIL+n))
  return 0
}

# ── 15. 강의자료가 부르는 스크립트가 실재하는가 ──────────────────────────
#
# 사용자 지시 2026-09-08: "강의 자료 pdf와 해당 예제 코드가 잘 매칭이 되는지 보고".
# 문서가 `W01_C_terminal_speed` 라고 적었는데 그런 파일이 없으면, 학생은 첫 줄에서
# 막히고 그 다음부터 문서를 믿지 않는다. 말로 두지 않고 기계로 거른다
# → standing-orders.md §9-6
check_code() {
  head2 "15. 강의자료가 부르는 스크립트가 실재하는가"
  local miss=0 f tag name
  while IFS= read -r f; do
    tag="$(basename "$f" | cut -d_ -f1)"           # W01, A1 ...
    # 백틱 안만 보면 ```matlab 블록 안의 이름을 통째로 놓친다 — 실제로 W01 에서
    # 두 개밖에 못 잡았다. 파일 전체에서 그 주차의 접두사를 가진 토큰을 모은다.
    # .m 스크립트든 .slx 모델이든 폴더든, 무엇으로든 실재하면 통과다.
    while IFS= read -r name; do
      [ -z "$name" ] && continue
      case "$name" in *_) continue ;; esac      # 산문에서 잘린 조각 (W02_C_ 등)
      #  .m 이든 .slx 든 img/ 의 .png 든 폴더든, 무엇으로든 실재하면 통과다.
      #  WXX_P1 처럼 학생이 WXX_P1_start 로 만들어 내는 모델도 통과시킨다 —
      #  저장소에 없는 것이 정상이기 때문이다.
      if   find lectures -name "${name}.m"       -type f 2>/dev/null | grep -vE "$VENDOR" | grep -q . ; then :
      elif find lectures -name "${name}.slx"     -type f 2>/dev/null | grep -vE "$VENDOR" | grep -q . ; then :
      elif find lectures -name "${name}.png"     -type f 2>/dev/null | grep -vE "$VENDOR" | grep -q . ; then :
      elif find lectures -name "${name}_start.m" -type f 2>/dev/null | grep -vE "$VENDOR" | grep -q . ; then :
      elif find lectures -name "${name}"         -type d 2>/dev/null | grep -vE "$VENDOR" | grep -q . ; then :
      elif find _tools   -name "${name}.m"       -type f 2>/dev/null | grep -q . ; then :
      else
        echo "     [없는 스크립트] $(basename "$f")  ->  $name"
        miss=$((miss+1))
      fi
    done < <(grep -oE "\b${tag}_[A-Za-z0-9_]+\b" "$f" \
             | sed 's/\.$//' | sort -u)
  done < <(labdocs)
  note "문서가 부르는데 없는 스크립트" "$miss"
  FAIL=$((FAIL+miss))
  return 0
}

check_legend() {
  head2 "16. 그림마다 범례 표가 붙어 있는가"
  # CLAUDE.md §4 규칙 5: 「그림마다 뒤에 reading the figure 표를 붙인다」.
  #
  # 왜 기계로 세는가. 2026-09-08 에 눈으로 훑어서는 못 찾다가, 그림 수와 표 수를
  # 세어 보고서야 W04 의 **결과 그래프 여섯 장 전부**에 범례 표가 없다는 것을
  # 찾았다. 학생은 키 없는 그림을 여섯 장 보고 있었다. 사람이 놓치는 종류의
  # 누락이므로 검사기로 내린다 → standing-orders.md §0-0
  #
  # 판정: 그림 줄 뒤 12줄 안에 표 머리말이 있으면 통과. 머리말은 두 가지를
  # 인정한다 — "**Reading the figure**" 와, 개념도가 쓰는 "| In the figure |".
  local miss=0 f
  while IFS= read -r f; do
    while IFS= read -r ln; do
      local n img
      n="${ln%%:*}"; img="${ln#*:}"
      if ! sed -n "$((n+1)),$((n+12))p" "$f" \
           | grep -qE '^\*\*Reading the figure\*\*|^\| *In the figure *\|'; then
        printf '     [범례 표 없음] %s:%s  %s\n' "${f#./}" "$n" \
               "$(printf '%s' "$img" | sed -E 's/.*\]\(([^)]*)\).*/\1/')"
        miss=$((miss+1))
      fi
    done < <(grep -n '^!\[' "$f")
  done < <(labdocs)
  note "범례 표가 없는 그림" "$miss"
  FAIL=$((FAIL+miss))
  return 0
}

# ── 실행 ──────────────────────────────────────────────────────────────────
echo "볼트: $ROOT"
case "$MODE" in
  --style) check_style ;;
  --links) check_links ;;
  --figs)  check_figs ;;
  --code)  check_code ;;
  *)       check_pdf; check_links; check_figs; check_style; check_svg; check_weeks; check_code
           check_legend ;;
esac

echo
if [ "$FAIL" -eq 0 ]; then
  echo "  통과 — 지적 사항 0 건"
else
  echo "  지적 사항 $FAIL 건"
fi
exit 0
