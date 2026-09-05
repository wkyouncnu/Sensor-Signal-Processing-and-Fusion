#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# md2pdf.sh — 강의자료 MD 를 A4 PDF 로 변환
#
#   사용법 (Git Bash):
#     bash _tools/md2pdf.sh 10-주차별-강의자료/W01_*.md
#     bash _tools/md2pdf.sh 10-주차별-강의자료/*.md        # 폴더 전체
#
#   동작:
#     MD  ->  임시 HTML(원본과 같은 폴더, 그림 상대경로 유지)
#         ->  Chrome 헤드리스 --print-to-pdf
#         ->  원본과 같은 이름의 .pdf 생성, 임시 HTML 삭제
#
#   필요한 것: Chrome (설치되어 있음), _tools/marked.min.js, _tools/pdf-template.html
#   인터넷 불필요.
# ---------------------------------------------------------------------------
set -u

TOOLS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TPL="$TOOLS/pdf-template.html"
MARKED="$TOOLS/marked.min.js"
MATHJAX="$TOOLS/mathjax-tex-svg.js"

CHROME=""
for c in "/c/Program Files/Google/Chrome/Application/chrome.exe" \
         "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe" \
         "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"; do
  [ -f "$c" ] && { CHROME="$c"; break; }
done

[ -z "$CHROME" ] && { echo "오류: Chrome 또는 Edge 를 찾을 수 없습니다"; exit 1; }
[ -f "$TPL" ]    || { echo "오류: $TPL 없음"; exit 1; }
[ -f "$MARKED" ]  || { echo "오류: $MARKED 없음"; exit 1; }
[ -f "$MATHJAX" ] || { echo "오류: $MATHJAX 없음"; exit 1; }
[ $# -eq 0 ]      && { echo "사용법: bash _tools/md2pdf.sh <파일.md> [...]"; exit 1; }

# 템플릿을 마커 기준으로 4등분
n_md=$(grep -n '<!--MDCONTENT-->'  "$TPL" | head -1 | cut -d: -f1)
n_mj=$(grep -n '<!--MATHJAXJS-->'  "$TPL" | head -1 | cut -d: -f1)
n_js=$(grep -n '<!--MARKEDJS-->'   "$TPL" | head -1 | cut -d: -f1)
[ -z "$n_md" ] || [ -z "$n_mj" ] || [ -z "$n_js" ] && { echo "오류: 템플릿에 마커가 없습니다"; exit 1; }

ok=0; fail=0

for md in "$@"; do
  [ -f "$md" ] || { echo "  [건너뜀] $md — 파일 없음"; fail=$((fail+1)); continue; }

  dir="$(cd "$(dirname "$md")" && pwd)"
  base="$(basename "$md" .md)"
  tmp="$dir/.md2pdf_$$.html"
  pdf="$dir/$base.pdf"

  {
    sed -n "1,$((n_md-1))p" "$TPL"
    # </script 만 이스케이프 (임베드 종료 방지)
    sed 's|</script|<\\/script|g' "$md"
    sed -n "$((n_md+1)),$((n_mj-1))p" "$TPL"
    cat "$MATHJAX"
    sed -n "$((n_mj+1)),$((n_js-1))p" "$TPL"
    cat "$MARKED"
    sed -n "$((n_js+1)),\$p" "$TPL"
  } > "$tmp"

  # Chrome 은 Windows 실행 파일이므로 POSIX 경로를 이해하지 못한다.
  # 출력은 Windows 경로(\), 입력 URL 은 혼합 경로(C:/...)로 변환해서 넘긴다.
  win_pdf="$(cygpath -w "$pdf")"
  url_tmp="file:///$(cygpath -m "$tmp")"

  # 기존 PDF 의 수정 시각을 기억해 둔다.
  # 이것이 없으면 Chrome 이 실패해도 "옛 파일이 존재한다"는 이유로 성공으로 오판한다.
  before=0
  [ -f "$pdf" ] && before=$(stat -c%Y "$pdf")

  err=""
  for attempt in 1 2 3; do
    err="$("$CHROME" --headless --disable-gpu --no-sandbox --hide-scrollbars \
                     --no-pdf-header-footer --run-all-compositor-stages-before-draw \
                     --virtual-time-budget=15000 \
                     --print-to-pdf="$win_pdf" "$url_tmp" 2>&1 | grep -i "Failed to write" | tail -1)"
    after=0
    [ -f "$pdf" ] && after=$(stat -c%Y "$pdf")
    # 실제로 새로 쓰였는지 확인
    if [ -s "$pdf" ] && [ "$after" -gt "$before" ]; then
      err=""
      break
    fi
    # 파일 잠김(Dropbox 동기화·뷰어 열림 등)이면 잠깐 기다렸다 재시도
    [ $attempt -lt 3 ] && sleep 3
  done

  if [ -s "$pdf" ] && [ "$after" -gt "$before" ]; then
    printf "  [OK] %-52s %s KB\n" "$base.pdf" "$(( $(stat -c%s "$pdf") / 1024 ))"
    ok=$((ok+1))
  else
    echo "  [실패] $base.pdf — 갱신되지 않음"
    if [ -n "$err" ]; then
      case "$err" in
        *0x20*|*사용\ 중*|*being\ used*)
          echo "         원인: 다른 프로그램이 이 PDF 를 열고 있음"
          echo "         조치: PDF 뷰어를 닫고, Dropbox 동기화가 끝난 뒤 다시 실행" ;;
        *)
          echo "         $err" ;;
      esac
    fi
    fail=$((fail+1))
  fi
  rm -f "$tmp"
done

echo
echo "  완료: 성공 $ok / 실패 $fail"
