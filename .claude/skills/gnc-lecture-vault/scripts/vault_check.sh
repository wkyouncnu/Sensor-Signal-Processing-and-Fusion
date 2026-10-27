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

# ── 캐시 — 같은 것을 두 번 만들지 않는다 ──────────────────────────────────
#  2026-10-27 에 재 보니 전체 점검이 7분 30초였고 그중 sys 가 6분 28초였다.
#  일이 아니라 **프로세스를 띄우는 값**이다 — Windows 의 fork 는 비싸고,
#  옛 코드는 항목마다 find·awk·sed·grep·wc 를 새로 띄웠다. 목록·사본·이름을
#  한 번만 만들어 돌려 쓴다 → standing-orders.md §15-64
TMPD="$(mktemp -d)"; trap 'rm -rf "$TMPD"' EXIT

MDS=(); DELIVERED=(); LABDOCS=()
lists() {
  [ "${LISTS_DONE:-0}" = 1 ] && return 0
  mapfile -t MDS       < <(mds)
  mapfile -t DELIVERED < <(delivered)
  mapfile -t LABDOCS   < <(labdocs)
  LISTS_DONE=1
  return 0
}

#  코드블록을 벗긴 사본. 같은 파일을 열여섯 번 다시 벗기지 않는다 — §9 가 금지
#  표현 열여섯 개마다 문서 전부를 다시 벗겨서 4 MB 를 열여섯 번 읽었다.
#  경로는 전역 STRIPPED 에 둔다. $( ) 로 받으면 그것이 또 포크다.
STRIPPED=""
strip_path() {
  STRIPPED="$TMPD/s_${1//[\/ ]/_}"
  [ -s "$STRIPPED" ] || strip_code "$1" > "$STRIPPED"
  return 0
}

#  lectures · _tools 의 **파일 이름** 색인. §15 는 토큰마다 find 를 돌렸다 —
#  506 개 토큰 × 최대 여섯 번, 한 번에 0.3 초니 그것만 3 분이다. 트리를 한 번
#  걷고 이름으로 찾는다. _tools 를 함께 넣었으므로 옛 `_tools -name` 가지도 덮는다.
#  HAVE_MD 는 볼트 전체의 `.md` 이름이다 — §2 의 wikilink 가 링크마다
#  `find . -name "<이름>.md"` 를 돌렸다. 여기도 트리를 한 번만 걷는다.
declare -A HAVE_F HAVE_D HAVE_MD
names() {
  [ "${NAMES_DONE:-0}" = 1 ] && return 0
  local p
  while IFS= read -r p; do HAVE_F["${p##*/}"]=1; done \
    < <(find lectures _tools -type f 2>/dev/null | grep -vE "$VENDOR")
  while IFS= read -r p; do HAVE_D["${p##*/}"]=1; done \
    < <(find lectures -type d 2>/dev/null | grep -vE "$VENDOR")
  while IFS= read -r p; do HAVE_MD["${p##*/}"]=1; done \
    < <(find . -name '*.md' -type f 2>/dev/null)
  NAMES_DONE=1
  return 0
}

# ── 1. MD ↔ PDF 쌍 ────────────────────────────────────────────────────────
check_pdf() {
  head2 "1. MD - PDF 쌍"
  local miss=0 stale=0 f pdf
  lists
  for f in "${DELIVERED[@]}"; do
    pdf="${f%.md}.pdf"
    if [ ! -f "$pdf" ]; then
      echo "     [PDF 없음] $f"; miss=$((miss+1))
    elif [ "$f" -nt "$pdf" ]; then
      echo "     [PDF 가 오래됨] $f"; stale=$((stale+1))
    fi
  done
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
  lists; names
  for f in "${MDS[@]}"; do
    strip_path "$f"
    while IFS= read -r raw; do
      name="${raw%%|*}"; name="${name%%#*}"
      [ -z "$name" ] && continue
      if [ -z "${HAVE_MD["$name.md"]:-}" ]; then
        echo "     [깨짐] $f  ->  [[$name]]"; bad=$((bad+1))
      fi
    done < <(sed 's/!\[\[/@@IMG@@/g' "$STRIPPED" | grep -o '\[\[[^]]*\]\]' \
             | sed 's/^\[\[//; s/\]\]$//' | sort -u)
  done
  note "깨진 wikilink" "$bad"
  FAIL=$((FAIL+bad))

  head2 "3. 그림 참조가 실재하는가"
  local img=0 d p
  for f in "${MDS[@]}"; do
    d="${f%/*}"
    while IFS= read -r p; do
      case "$p" in http*|data:*) continue ;; esac
      [ -f "$d/$p" ] || { echo "     [없음] $f  ->  $p"; img=$((img+1)); }
    done < <(grep -o '](\([^)]*\.\(svg\|png\|jpg\|jpeg\|gif\)\))' "$f" \
             | sed 's/^](//; s/)$//' | sort -u)
  done
  note "없는 그림" "$img"
  FAIL=$((FAIL+img))

  head2 "4. Obsidian 전용 임베드"
  local emb=0
  for f in "${MDS[@]}"; do
    strip_path "$f"
    if grep -q '!\[\[' "$STRIPPED"; then echo "     $f"; emb=$((emb+1)); fi
  done
  note "Obsidian 임베드를 쓴 문서" "$emb"
  FAIL=$((FAIL+emb))
  return 0
}

# ── 3. 그림과 수식 — references/results-and-figures.md 의 규칙 ────────────
check_figs() {
  head2 "5. 주차·부록마다 블록도 1장, 결과 그래프 1장"
  local nodiag=0 nores=0 f dir tag nd nr
  lists
  for f in "${LABDOCS[@]}"; do
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
  done
  note "블록도 PNG 가 없는 주차" "$nodiag"
  note "결과 그래프 PNG 가 없는 주차" "$nores"
  FAIL=$((FAIL+nodiag+nores))

  head2 "6. PNG 가 빌더보다 새것인가"
  #  .slx 와 비교하지 않는다. Simulink 는 모델을 **열기만 해도** .slx 를 다시 써서
  #  mtime 이 올라가고, 한 폴더에 모델이 셋이면 H 절 모델을 연 것 때문에 D 절 그림이
  #  낡았다고 나온다. 실제 의존성은 사람이 고치는 **빌더 스크립트**다.
  #  강의자료가 싣는 그림 이름을 **한 번에** 모은다. PNG 마다 grep -qr 을 돌리면
  #  248 번 × lectures/*.md 4 MB 를 다시 읽는다 — 그것이 이 절의 57 초였다.
  local stale=0 bld png b
  declare -A SHOWN
  while IFS= read -r b; do SHOWN["$b"]=1; done \
    < <(grep -ohE '[A-Za-z0-9_.+-]+\.png' lectures/*.md 2>/dev/null | sort -u)
  while IFS= read -r bld; do
    d="$(dirname "$bld")"
    [ -d "$d/img" ] || continue
    for png in "$d"/img/*.png; do
      [ -f "$png" ] || continue
      #  강의자료가 더 이상 싣지 않는 그림은 건너뛴다. §9-8 로 철회한 그림은
      #  생성기가 돌지 않으므로 **영원히** 낡은 상태이고, 그것을 계속 지적하면
      #  검사기가 늑대 소년이 된다. 파일은 남기고(사용자 절대 지침) 판정에서만 뺀다.
      [ -n "${SHOWN["${png##*/}"]:-}" ] || continue
      if [ "$bld" -nt "$png" ]; then
        echo "     [낡음] $png  <  $(basename "$bld")"; stale=$((stale+1))
      fi
    done
  done < <(find lectures \( -name 'build_*.m' -o -name '*_build_*.m' \) -type f 2>/dev/null | grep -vE "$VENDOR" | sort)
  note "빌더보다 오래된 PNG" "$stale"
  [ $stale -gt 0 ] && echo "     -> 그 주차의 절 스크립트를 다시 돌린다 (WXX_C_… 부터)"
  FAIL=$((FAIL+stale))

  head2 "7. 블록도 PNG 폭"
  #  폭은 PNG 헤더(IHDR 의 첫 4바이트)에 있다. 그림마다 od 나 identify 를 띄우면
  #  150 포크이고 그것이 12 초였다 — 한 번에 전부 읽는다 → §15-64
  local wide=0 w
  local -a PNGS=()
  mapfile -t PNGS < <(find lectures -path '*/img/*.png' ! -name '*_result*' -type f 2>/dev/null \
                      | grep -vE "$VENDOR")
  if [ "${#PNGS[@]}" -gt 0 ]; then
    while read -r w png; do
      [ "$w" -gt 2000 ] && { echo "     [너무 넓음] $png  ${w}px"; wide=$((wide+1)); }
    done < <(perl -e 'for my $f (@ARGV) { open(my $h, "<", $f) or next; binmode $h;
                        read($h, my $b, 24); next if length($b) < 24;
                        print unpack("N", substr($b, 16, 4)), " $f\n"; }' "${PNGS[@]}")
  fi
  note "폭 2000px 초과 블록도" "$wide"
  FAIL=$((FAIL+wide))

  head2 "8. 블록 수식 \$\$ 의 짝"
  local odd=0 n
  for f in "${MDS[@]}"; do
    n=$(awk '/^```/{c=!c; next} !c' "$f" | grep -o '\$\$' | wc -l)
    if [ $((n % 2)) -ne 0 ]; then echo "     [짝이 안 맞음] $f  (\$\$ x $n)"; odd=$((odd+1)); fi
  done
  note "짝이 맞지 않는 \$\$" "$odd"
  FAIL=$((FAIL+odd))
  return 0
}

# ── 4. 문체 — 강의자료는 영어 정식 어조 ──────────────────────────────────
check_style() {
  head2 "9. 금지 표현 (배포 문서)"
  # \b 로 단어 경계를 잡아 in-you-endo 류의 오탐을 막는다
  #  yourself · yourselves · ours · ourselves 는 2026-09-14 에 추가했다.
  #  W01 에 "Drive it yourself" 와 "How to convince yourself" 가 있었는데 \byou\b 는
  #  yourself 의 일부를 단어로 보지 않으므로 이 검사를 그대로 통과했다.
  local words=('\byou\b' '\byour\b' "\byou're\b" '\byours\b' '\byourself\b' '\byourselves\b' \
               '\bwe\b' '\bour\b' '\bours\b' '\bourselves\b' "\bwe'll\b" "\bwe're\b" \
               '\btoday\b' '\blet us\b' "\blet's\b" '\bnowadays\b')
  local w n total=0 f hits
  lists
  #  표현 하나마다 **문서 전부를 한 grep 에** 넣는다. 문서마다 따로 띄우면
  #  16 × 35 = 560 포크이고 그것이 51 초였다. grep 은 인자 순서대로 읽으므로
  #  출력 순서는 DELIVERED 순서 그대로다 → standing-orders.md §15-64
  local -a SP=()
  declare -A S2F
  for f in "${DELIVERED[@]}"; do
    strip_path "$f"; SP+=("$STRIPPED"); S2F["$STRIPPED"]="$f"
  done
  local sfile
  for w in "${words[@]}"; do
    n=0
    while read -r hits sfile; do
      [ -z "$hits" ] && continue
      f="${S2F["$sfile"]}"
      n=$((n+hits)); echo "     $f  ($hits x ${w//\\b/})"
    done < <(grep -oiEH -- "$w" "${SP[@]}" 2>/dev/null | cut -d: -f1 | uniq -c)
    [ "$n" -gt 0 ] && printf '  %-44s %s\n' "${w//\\b/}" "$n"
    total=$((total+n))
  done
  note "1·2인칭 · 시점 표현 합계" "$total"
  FAIL=$((FAIL+total))

  head2 "10. 이모지 · 장식 기호"
  local emo=0
  while read -r hits sfile; do
    [ -z "$hits" ] && continue
    echo "     ${S2F["$sfile"]}  ($hits)"; emo=$((emo+hits))
  done < <(grep -oHP '[\x{1F300}-\x{1FAFF}\x{2600}-\x{27BF}\x{2B00}-\x{2BFF}]' \
           "${SP[@]}" 2>/dev/null | cut -d: -f1 | uniq -c)
  note "이모지 · 장식 기호" "$emo"
  FAIL=$((FAIL+emo))

  head2 "11. 콜아웃 종류"
  local badc=0
  while read -r hits sfile; do
    [ -z "$hits" ] && continue
    echo "     $sfile  ($hits)"; badc=$((badc+hits))
  done < <(grep -oH '> \[![a-z]*\]' "${MDS[@]}" 2>/dev/null \
           | grep -vE '\[!(note|tip|important|warning|caution|info)\]$' \
           | cut -d: -f1 | uniq -c)
  note "미지원 콜아웃" "$badc"
  FAIL=$((FAIL+badc))

  head2 "11a. 첫 장 — 참고자료 콜아웃과 git clone/pull 안내"
  #  사용자 지시 2026-09-21: "매번 수업 전에 수정된 부분만 다운로드 하는 방법을 첫장에
  #  정리해서 항상 넣어줄래". 주차·부록마다 두 콜아웃이 있고, 순서가 참고자료 → git 이다.
  #  → standing-orders.md §1 · §1-1
  #  한글본(_KO.md)은 같은 콜아웃을 한국어 제목으로 단다 (§15-41). 둘 다 인정한다.
  #  The Korean edition carries the same two callouts under Korean titles.
  #  네 가지를 문서마다 따로 grep 하면 문서 하나에 네댓 번 포크다. awk 한 번으로
  #  네 값을 함께 내고, 판정은 쉘이 LABDOCS 순서대로 한다 → §15-64
  local miss=0 a b c p line
  declare -A HEAD4
  while read -r line a b c p; do
    HEAD4["$line"]="$a $b $c $p"
  done < <(awk '
    FNR == 1 { n++; name[n] = FILENAME }
    A[FILENAME] == 0 && /Reference material — read this first|참고자료 — 먼저 읽을 것/ { A[FILENAME] = FNR }
    B[FILENAME] == 0 && /Getting the course files, and keeping them current \(Windows\)|수업 파일 받기와 최신으로 유지하기 \(Windows\)/ { B[FILENAME] = FNR }
    index($0, "git clone https://github.com/wkyouncnu/Sensor-Signal-Processing-and-Fusion.git") { C[FILENAME] = 1 }
    index($0, "`git pull`")                                                                    { P[FILENAME] = 1 }
    END { for (i = 1; i <= n; i++) { f = name[i]
            printf "%s %d %d %d %d\n", f, A[f], B[f], C[f], P[f] } }' "${LABDOCS[@]}")
  for f in "${LABDOCS[@]}"; do
    read -r a b c p <<< "${HEAD4["$f"]:-0 0 0 0}"
    if [ "$a" = 0 ] || [ "$b" = 0 ] || [ "$a" -gt "$b" ] || [ "$c" = 0 ] || [ "$p" = 0 ]; then
      echo "     $f"; miss=$((miss+1))
    fi
  done
  note "첫 장 콜아웃 누락 · 순서 어긋남" "$miss"
  FAIL=$((FAIL+miss))
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
  lists; names
  for f in "${LABDOCS[@]}"; do
    tag="$(basename "$f" | cut -d_ -f1)"           # W01, A1 ...
    # 백틱 안만 보면 ```matlab 블록 안의 이름을 통째로 놓친다 — 실제로 W01 에서
    # 두 개밖에 못 잡았다. 파일 전체에서 그 주차의 접두사를 가진 토큰을 모은다.
    # .m 스크립트든 .slx 모델이든 폴더든, 무엇으로든 실재하면 통과다.
    while IFS= read -r name; do
      [ -z "$name" ] && continue
      case "$name" in *_) continue ;; esac      # 산문에서 잘린 조각 (W03_C_ 등)
      #  .m 이든 .slx 든 img/ 의 .png 든 폴더든, 무엇으로든 실재하면 통과다.
      #  WXX_P1 처럼 학생이 WXX_P1_start 로 만들어 내는 모델도 통과시킨다 —
      #  저장소에 없는 것이 정상이기 때문이다.
      #  names() 가 만든 이름 색인으로 본다. 옛 코드는 토큰마다 find 를 최대
      #  여섯 번 돌려 트리를 다시 걸었다 — `_tools` 도 색인에 들어 있으므로
      #  마지막 가지까지 그대로 덮는다.
      if   [ -n "${HAVE_F["${name}.m"]:-}" ]       ; then :
      elif [ -n "${HAVE_F["${name}.slx"]:-}" ]     ; then :
      elif [ -n "${HAVE_F["${name}.png"]:-}" ]     ; then :
      elif [ -n "${HAVE_F["${name}_start.m"]:-}" ] ; then :
      elif [ -n "${HAVE_D["${name}"]:-}" ]         ; then :
      else
        echo "     [없는 스크립트] $(basename "$f")  ->  $name"
        miss=$((miss+1))
      fi
    done < <(sed -E 's/[A-Za-z0-9_]+\.md//g' "$f" \
             | grep -oE "\b${tag}_[A-Za-z0-9_]+\b" \
             | sed 's/\.$//' | sort -u)
  done
  note "문서가 부르는데 없는 스크립트" "$miss"
  FAIL=$((FAIL+miss))
  return 0
}

check_legend() {
  head2 "16. 그림마다 범례 표가 붙어 있는가"
  # CLAUDE.md §4 규칙 5: 「그림마다 뒤에 reading the figure 표를 붙인다」.
  #
  # 왜 기계로 세는가. 2026-09-08 에 눈으로 훑어서는 못 찾다가, 그림 수와 표 수를
  # 세어 보고서야 W05 의 **결과 그래프 여섯 장 전부**에 범례 표가 없다는 것을
  # 찾았다. 학생은 키 없는 그림을 여섯 장 보고 있었다. 사람이 놓치는 종류의
  # 누락이므로 검사기로 내린다 → standing-orders.md §0-0
  #
  # 판정: 그림 줄 뒤 12줄 안에 표 머리말이 있으면 통과. 머리말은 세 가지를
  # 인정한다 — "**Reading the figure**", 2026-09-25 부터 쓰는
  # "**Reading the figure against the derivation.**" 처럼 뒷말이 붙은 것,
  # 그리고 개념도가 쓰는 "| In the figure |" (→ standing-orders.md §15-14).
  # "In the diagram" 도 인정한다 — 블록도에 붙는 표의 제목으로는 그 쪽이 옳다
  # (2026-09-29, W05 §5-7 이 제어기 서브시스템 셋을 실으면서).
  # "On the slide(s)" · "슬라이드에서" 도 인정한다 — 사용자의 옛 강의자료나
  # 교재에서 가져온 슬라이드를 실을 때 그 쪽이 옳은 제목이다
  # (2026-10-17, W05 §5-5 가 2025년 PPT 열한 장을 실으면서).
  #
  # 파일을 한 번만 읽는다. 옛 코드는 그림마다 sed 와 grep 을 띄워서 250 장에
  # 500 번을 포크했다 (2026-10-27) → standing-orders.md §15-64
  local miss=0 f n i j ok img
  local -a L
  local RE='^\*\*Reading the figure|^\| *In the (figure|diagram|live view) *\||^\| *On the slides? *\||^\*\*그림을 .*읽기|^\| *(실시간 )?(그림에서|다이어그램에서|화면에서|슬라이드에서) *\|'
  lists
  for f in "${LABDOCS[@]}"; do
    mapfile -t L < "$f"
    for ((i=0; i<${#L[@]}; i++)); do
      case "${L[i]}" in '!['*) ;; *) continue ;; esac
      n=$((i+1)); ok=0
      for ((j=i+1; j<i+13 && j<${#L[@]}; j++)); do
        if [[ ${L[j]} =~ $RE ]]; then ok=1; break; fi
      done
      if [ "$ok" -eq 0 ]; then
        img="${L[i]##*](}"; img="${img%%)*}"
        printf '     [범례 표 없음] %s:%s  %s\n' "${f#./}" "$n" "$img"
        miss=$((miss+1))
      fi
    done
  done
  note "범례 표가 없는 그림" "$miss"
  FAIL=$((FAIL+miss))
  return 0
}

check_clear() {
  head2 "17. 러너 · 확인 스크립트의 맨 clear"
  # 2026-09-11: W01_H_usb_check.m 맨 앞의 clear 가 기본 작업공간을 비워서,
  # 기본 작업공간 변수를 읽는 W01_openloop · W01_current 빌더가 다음 실행에서
  # "SampleTime 설정이 유효하지 않다" 로 멈췄다. MCP 로 돌리는 스크립트는
  # 기본 작업공간에서 돈다. 제 변수만 이름으로 지운다 — clear m cfg y …
  #
  # 예외: WXX_0_setup.m. 작업공간을 처음부터 채우는 것이 그 파일의 일이다.
  # 같은 규칙을 PostToolUse 훅 _tools/hook_matlab_rules.sh 가 쓰는 순간에 잡는다.
  local n=0 hit
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    echo "     [맨 clear] $hit"
    n=$((n+1))
  done < <(find lectures -name '*.m' -type f 2>/dev/null | grep -vE "$VENDOR" \
             | grep -v '_0_setup\.m$' \
             | xargs -r grep -nE '^\s*(clear|clearvars)\s*(;|%|$)|^\s*clear\s+all\b' 2>/dev/null)
  note "맨 clear 가 있는 스크립트" "$n"
  FAIL=$((FAIL+n))
  return 0
}

check_one_model() {
  head2 "18. 실험 하나에 모델 하나, 스크립트는 얇게"
  # standing-orders.md §15-15 (2026-09-25, 사용자 지시):
  #   "각 실습은 개별 시뮬링크 파일로 실행하도록", "m 파일은 그림 그려서 plot 하는 정도만".
  #
  # 둘을 기계로 본다.
  #   (a) 절 스크립트의 실행 줄(주석·빈 줄 제외)이 45 줄을 넘지 않는가.
  #       넘으면 그 파일은 실험을 둘 이상 하고 있다 — 실제로 W02_C 와 W02_G 가 그랬다.
  #   (b) 한 주차 문서 안에서 "**The model.** `X`" 의 X 가 두 실험에 겹치지 않는가.
  #
  # 예외 셋.
  #   - `_build_` 이 든 파일은 모델을 짓는 빌더다. 절 스크립트가 아니다.
  #   - W01 은 지금 사용자가 편집 중이다 (모델 넷과 setup). 손대지 않기로 했으므로
  #     두께도 재지 않는다. 사용자가 커밋한 뒤에 다시 본다.
  #   - W01_openloop 은 실험 1-11·1-12 가 함께 쓴다 — 한 번의 개루프 주행에 두 질문.
  #   - W05_F_ILOS 는 실험 5-5b·5-5c 가 함께 쓴다. 두 번째는 **플래그만** 바꾼다
  #     (law = 3 대 4, §15-24 "한 블록에 다 넣고 플래그가 고른다"). 모델을 하나 더
  #     만들면 같은 그림이 둘이 되고, 둘이 어긋날 수 있다 — 그것이 이 규칙이 막으려는
  #     것보다 나쁘다 (2026-10-13).
  #
  # 두께 예외는 지금 없다. W06_G_berthing 이 하나 있었으나 — 절 둘을 먹이느라
  # 실행 줄이 55 였다 — 6 주차가 사다리 한 단에 모델 하나·스크립트 하나로 쪼개지면서
  # 사라졌다 (2026-10-27). §6-5 와 §6-6 은 이제 `W06_5_dock_run` 하나를 읽고,
  # 자세 비교는 `W06_7_front_run` 이 찍는 같은 블록과 맞세워서 한다.
  local n=0 f code dup
  while IFS= read -r f; do
    code=$(grep -vE '^\s*%|^\s*$' "$f" | wc -l | tr -d ' ')
    if [ "$code" -gt 45 ]; then
      echo "     [스크립트가 두껍다] ${f#./}  실행 줄 $code (45 이하)"
      n=$((n+1))
    fi
  done < <(find lectures -maxdepth 2 -name 'W[0-9][0-9]_[B-Z]_*.m' -type f 2>/dev/null \
             | grep -vE "$VENDOR" | grep -v '_build_' | grep -v '/W01_simulink/' | sort)

  while IFS= read -r f; do
    while IFS= read -r dup; do
      [ -z "$dup" ] && continue
      [ "$dup" = "W01_openloop" ] && continue          # 위의 예외
      [ "$dup" = "W05_F_ILOS" ]   && continue          # 플래그만 다른 두 실험 (§15-24)
      echo "     [모델을 두 실험이 함께 쓴다] ${f#./}  $dup"
      n=$((n+1))
    done < <(grep -oE '^\*\*The model\.\*\* `[A-Za-z0-9_]+`' "$f" 2>/dev/null \
               | grep -oE '`[A-Za-z0-9_]+`' | tr -d '`' | sort | uniq -d)
  done < <(find lectures -maxdepth 1 -name 'W[0-9][0-9]_*.md' -type f 2>/dev/null | sort)
  note "실험당 모델·스크립트 위반" "$n"
  FAIL=$((FAIL+n))
  return 0
}

check_always_read() {
  head2 "19. 세션마다 통째로 읽히는 것의 크기"
  # standing-orders.md §15-60 (2026-10-27, 사용자 지시 "compact 할 일이 없도록"):
  #   모든 세션이 첫 글자부터 읽는 것은 `CLAUDE.md` 와 메모리뿐이다. 거기에 목록이
  #   쌓이면 작업 공간이 그만큼 줄고 compact 이 자주 돈다. 목록은 `ls` 가 말하고
  #   스킬 참조가 왜 있는지를 말한다 — 이 둘은 **규칙만** 담는다.
  #   `PLAN.md` 는 세션마다 자동으로 읽히지는 않지만 강의 작업의 첫 동작이 그것을
  #   읽는 것이므로 같이 센다. 2026-10-27 에 70 KB 를 색인 + `plan-*.md` 다섯으로
  #   쪼갰다 — 기록이 다시 쌓이면 여기서 걸린다.
  local n=0 c=0 m=0 p=0 lim_c=30000 lim_m=4000 lim_p=20000
  c=$(wc -c < CLAUDE.md 2>/dev/null || echo 0)
  p=$(wc -c < PLAN.md 2>/dev/null || echo 0)
  local mdir="$HOME/.claude/projects/C--Users-admin-Dropbox-----------00-GradCourse-2026/memory"
  [ -d "$mdir" ] && m=$(cat "$mdir"/*.md 2>/dev/null | wc -c) || m=0
  if [ "$c" -gt "$lim_c" ]; then
    echo "     [큼] CLAUDE.md  ${c} 바이트  > ${lim_c}"
    echo "        -> 목록·사례를 references/ 로 내린다 (tools.md 처럼). 규칙만 남긴다"
    n=$((n+1))
  fi
  if [ "$m" -gt "$lim_m" ]; then
    echo "     [큼] 메모리 합계  ${m} 바이트  > ${lim_m}"
    echo "        -> CLAUDE.md·standing-orders 가 이미 적은 것은 메모리에 두지 않는다"
    n=$((n+1))
  fi
  if [ "$p" -gt "$lim_p" ]; then
    echo "     [큼] PLAN.md  ${p} 바이트  > ${lim_p}"
    echo "        -> 기록은 references/plan-log-*.md 끝에 붙인다. PLAN.md 는 색인이다"
    n=$((n+1))
  fi
  note "CLAUDE.md ${c}B · PLAN.md ${p}B · 메모리 ${m}B — 넘은 것" "$n"
  FAIL=$((FAIL+n))
  return 0
}
# ── 20. 표 칸 안의 맨 `|` ──────────────────────────────────────────────────
check_table_pipes() {
  head2 "20. 표 칸의 인라인 코드 안에 맨 | 가 있는가"
  # standing-orders.md §15-63 (2026-10-27):
  #   표 한 줄은 **인라인 파싱보다 먼저** 맨 `|` 로 칸이 쪼개진다. 그래서 코드
  #   스팬 안의 `|` 도 칸을 가르고, 남은 백틱이 옆 칸까지 <code> 로 삼켜서 그
  #   안의 $…$ 는 MathJax 가 건너뛴다 — W06 의 $0.353$ 이 그렇게 사라졌다.
  #   표 줄에서는 코드 스팬 안이라도 `\|` 가 바른 탈출이다(쪼갤 때는 아직 코드
  #   스팬이 아니기 때문). 다만 **산문**의 코드 스팬에서는 탈출이 처리되지 않아
  #   `\|` 가 글자 그대로 찍히므로, 표 줄만 고친다.
  #   판정: 맨 `|` 로 칸을 나눈 뒤 칸마다 백틱을 세어 **홀수**면 깨진 것이다.
  local n=0
  lists
  for f in "${MDS[@]}"; do
    local hit
    hit=$(awk '
      /^[ \t]*>?[ \t]*```/ { fence = 1 - fence; next }
      fence { next }
      /^[ \t]*>?[ \t]*\|/ {
        nb = 0; bad = 0
        m = split($0, ch, "")
        for (i = 1; i <= m; i++) {
          c = ch[i]
          if (c == "\\" && i < m && ch[i+1] == "|") { i++; continue }
          if (c == "`") { nb++; continue }
          if (c == "|") { if (nb % 2) bad = 1; nb = 0 }
        }
        if (nb % 2) bad = 1
        if (bad) printf "%s:%d: %s\n", FILENAME, FNR, substr($0, 1, 90)
      }' "$f")
    if [ -n "$hit" ]; then
      echo "$hit" | sed 's/^/     [쪼개짐] /'
      n=$((n + $(printf '%s\n' "$hit" | wc -l)))
    fi
  done
  note "코드 스팬이 칸을 가른 표 줄" "$n"
  [ "$n" -gt 0 ] && echo "        -> 그 줄의 | 를 \| 로 (Edit 도구로. 표 줄만, 펜스·산문은 그대로)"
  FAIL=$((FAIL+n))
  return 0
}


# ── 실행 ──────────────────────────────────────────────────────────────────
echo "볼트: $ROOT"
case "$MODE" in
  --style) check_style ;;
  --links) check_links ;;
  --figs)  check_figs ;;
  --code)  check_code ;;
  --clear) check_clear ;;
  --onemodel) check_one_model ;;
  --size)  check_always_read ;;
  --pipes) check_table_pipes ;;
  *)       check_pdf; check_links; check_figs; check_style; check_svg; check_weeks; check_code
           check_legend; check_clear; check_one_model; check_always_read; check_table_pipes ;;
esac

echo
if [ "$FAIL" -eq 0 ]; then
  echo "  통과 — 지적 사항 0 건"
else
  echo "  지적 사항 $FAIL 건"
fi
exit 0
