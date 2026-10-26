#!/usr/bin/env bash
#  vault_shift_files.sh <first> [--apply]
#
#  주차 번호가 <first> 이상인 강의 파일·실습 폴더·검증 스크립트의 **이름**을
#  한 칸 뒤로 민다 (n -> n+1). 파일 **안의** 참조는 고치지 않는다 —
#  그것은 `vault_shift_from.m` 이 한다.
#
#    bash _tools/vault_shift_files.sh 6            무엇이 옮겨지는지만 보인다
#    bash _tools/vault_shift_files.sh 6 --apply    실제로 git mv 한다
#
#  왜 git mv 인가
#    지우고 새로 만들면 이력이 끊기고, 이 볼트는 파일을 지우지 않는다.
#    git mv 는 한 커밋 안에서 이름만 바꾼 것으로 남는다.
#
#  왜 내림차순인가
#    W06 -> W07 을 먼저 하면 기존 W07 과 부딪친다. 큰 번호부터 민다.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
first="${1:?usage: vault_shift_files.sh <first-week> [--apply]}"
apply="${2:-}"

mv_one() {                                   # $1 = 지금 이름, $2 = 새 이름
    if [ "$apply" = "--apply" ]; then git mv "$1" "$2"; else echo "  $1  ->  $2"; fi
}

for n in $(seq 11 -1 "$first"); do
    o=$(printf 'W%02d' "$n");      w=$(printf 'W%02d' $((n+1)))
    ol=$(printf 'w%02d' "$n");     wl=$(printf 'w%02d' $((n+1)))

    #  1) 주차 문서(.md/.pdf) 와 실습 폴더
    for p in lectures/${o}_*; do
        [ -e "$p" ] || continue
        mv_one "$p" "lectures/${w}_${p#lectures/${o}_}"
    done

    #  2) 옮긴 폴더 안의 파일 이름. --apply 가 아니면 폴더가 아직 옛 이름이다
    d="lectures/${w}_simulink"; [ "$apply" = "--apply" ] || d="lectures/${o}_simulink"
    if [ -d "$d" ]; then
        git ls-files "$d" | while read -r f; do
            b=$(basename "$f"); dir=$(dirname "$f")
            case "$b" in
                ${o}_*)  mv_one "$f" "$dir/${w}_${b#${o}_}"  ;;
                ${ol}_*) mv_one "$f" "$dir/${wl}_${b#${ol}_}" ;;
            esac
        done
    fi

    #  3) 그 주차의 검증 스크립트
    for p in _tools/verify_${ol}_*.m; do
        [ -e "$p" ] || continue
        mv_one "$p" "_tools/verify_${wl}_${p#_tools/verify_${ol}_}"
    done

    #  4) 개념도 SVG 와 그 TikZ 원본
    for p in figures/${ol}-* figures/src/${ol}-*; do
        [ -e "$p" ] || continue
        case "$p" in
            figures/src/*) mv_one "$p" "figures/src/${wl}-${p#figures/src/${ol}-}" ;;
            *)             mv_one "$p" "figures/${wl}-${p#figures/${ol}-}" ;;
        esac
    done
done
