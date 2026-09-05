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
mds() {
  find . -name '*.md' -type f \
    | grep -v '/\.claude/' \
    | grep -v '/_templates/' \
    | grep -v '/slprj/' \
    | grep -v '^\./CLAUDE\.md$' \
    | sort
}

# 배포하는 문서만 (README 제외) — PDF 쌍과 문체 검사의 대상
delivered() {
  mds | grep -E '^\./lectures/' | grep -v '/README\.md$'
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
  done < <(find lectures \( -name 'build_*.m' -o -name '*_build_*.m' \) -type f 2>/dev/null | sort)
  note "빌더보다 오래된 PNG" "$stale"
  [ $stale -gt 0 ] && echo "     -> 그 주차의 절 스크립트를 다시 돌린다 (WXX_C_… 부터)"
  FAIL=$((FAIL+stale))

  head2 "7. 블록도 PNG 폭"
  local wide=0 w
  if command -v identify >/dev/null 2>&1; then
    while IFS= read -r png; do
      w=$(identify -format '%w' "$png" 2>/dev/null || echo 0)
      [ "$w" -gt 2000 ] && { echo "     [너무 넓음] $png  ${w}px"; wide=$((wide+1)); }
    done < <(find lectures -path '*/img/*.png' ! -name '*_result*' -type f 2>/dev/null)
  else
    # ImageMagick 이 없으면 PNG 헤더에서 직접 읽는다 (IHDR 의 첫 4바이트)
    while IFS= read -r png; do
      w=$(od -An -tu4 -j16 -N4 --endian=big "$png" 2>/dev/null | tr -d ' ')
      [ -z "$w" ] && continue
      [ "$w" -gt 2000 ] && { echo "     [너무 넓음] $png  ${w}px"; wide=$((wide+1)); }
    done < <(find lectures -path '*/img/*.png' ! -name '*_result*' -type f 2>/dev/null)
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

# ── 실행 ──────────────────────────────────────────────────────────────────
echo "볼트: $ROOT"
case "$MODE" in
  --style) check_style ;;
  --links) check_links ;;
  --figs)  check_figs ;;
  *)       check_pdf; check_links; check_figs; check_style; check_svg ;;
esac

echo
if [ "$FAIL" -eq 0 ]; then
  echo "  통과 — 지적 사항 0 건"
else
  echo "  지적 사항 $FAIL 건"
fi
exit 0
