#!/usr/bin/env bash
# pending_folder_rename.sh — 세션이 시작될 때 남은 폴더 이름 변경을 **직접 처리한다.**
#
# 배경
#
#   2026-09-04 최상위 폴더를 정리하다가 두 개가 잠겨서 못 바꿨다. 안의 파일에는 열린
#   핸들이 하나도 없는데 디렉터리에만 걸려 있었고(Claude 세션의 프로젝트 폴더 감시 +
#   Dropbox 동기화), 재부팅해야 풀린다.
#
#   사용자 지시: "나중에 재부팅 하고 여기서 바로 재부팅한것 파악해서 스스로 폴더 변경해줘.
#   잊어버리지 말고. 훅으로 저장해서."
#
#   그래서 이 훅은 알림만 하지 않는다. **직접 바꾼다.**
#
# 안전
#
#   이름만 바꾼다. 지우지도 옮기지도 덮어쓰지도 않는다. rename_top_folders.ps1 이
#   바꾸기 전후 파일 수를 대조하고, 다르면 붉게 경고한다. 목적지가 이미 있으면 건너뛴다.
#   아직 잠겨 있으면 그대로 두고 다음 세션에 다시 시도한다.
#
# 둘 다 끝나면 조용해진다.

root="/c/Users/admin/Dropbox/센서신호처리및융합"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pending=0
[ -d "$root/Proj_SHI_USV_MILS" ] && pending=1
[ -d "$root/강의자료" ]           && pending=1
[ "$pending" -eq 0 ] && exit 0

# 마지막 부팅 시각 — 재부팅했는지 사용자에게도 보이게 한다
boot="$(powershell.exe -NoProfile -Command \
        "(Get-CimInstance Win32_OperatingSystem).LastBootUpTime.ToString('yyyy-MM-dd HH:mm')" \
        2>/dev/null | tr -d '\r')"

echo "밀려 있던 최상위 폴더 이름 변경을 지금 시도합니다.  (마지막 부팅: ${boot:-알 수 없음})"
echo

# -File 로 부르면 콘솔 코드페이지 때문에 한글 폴더명이 깨져 보인다. -Command 로 부르며
# 출력 인코딩을 UTF-8 로 올려야 이름이 제대로 찍힌다.
ps1_win="$(cygpath -w "$here/rename_top_folders.ps1")"
out="$(powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
       "[Console]::OutputEncoding=[Text.Encoding]::UTF8; & '${ps1_win}'" 2>&1 | tr -d '\r')"
echo "$out"
echo

if [ -d "$root/Proj_SHI_USV_MILS" ] || [ -d "$root/강의자료" ]; then
    echo "아직 잠겨 있습니다. 파일은 건드리지 않았습니다. 다음 세션에서 다시 시도합니다."
    echo "재부팅해도 안 풀리면 Dropbox 동기화를 잠시 멈추고 위 스크립트를 직접 실행하세요."
else
    echo "끝났습니다. 이 훅은 더 이상 아무것도 하지 않습니다 —"
    echo ".claude/settings.json 의 SessionStart 훅과 이 스크립트는 지워도 됩니다."
fi
