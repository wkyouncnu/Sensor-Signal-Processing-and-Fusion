#!/usr/bin/env bash
#
#  hook_matlab_rules.sh — PostToolUse 훅. lectures/ 의 .m 을 쓰거나 고친 직후에 본다.
#
#  .claude/settings.json 이 Write · Edit 뒤에 부른다. 도구 호출 정보(JSON)가 stdin 으로
#  온다. 규칙을 어기면 exit 2 — Claude Code 가 stderr 를 Claude 에게 되돌려 주어,
#  그 자리에서 고치게 한다. 어기지 않으면 조용히 exit 0.
#
#  규칙 (vault_check.sh §17 과 같다. 훅은 쓰는 순간, §17 은 끝내기 전에 잡는다)
#    러너 · 확인 스크립트에 맨 clear 금지. WXX_0_setup.m 만 예외.
#    2026-09-11: W01_H_usb_check.m 의 맨 clear 가 기본 작업공간을 비워
#    W01_openloop · W01_current 빌더가 멈췄다. MCP 로 돌리는 스크립트는 기본
#    작업공간에서 돈다. 제 변수만 이름으로 지운다 — clear m cfg y …
#
#  jq 가 없는 PC(Git Bash)에서도 돌도록 grep · sed 로 file_path 만 뽑는다.
#  경로를 못 읽으면 아무것도 막지 않는다 (§17 이 뒤에서 잡는다).
set -u
in="$(cat)"
f="$(printf '%s' "$in" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
      | sed -E 's/^"file_path"[[:space:]]*:[[:space:]]*"(.*)"$/\1/; s/\\\\/\\/g')"
[ -z "$f" ] && exit 0
command -v cygpath >/dev/null 2>&1 && f="$(cygpath -u "$f")"

case "$f" in *.m) ;; *) exit 0 ;; esac
case "$f" in */lectures/*) ;; *) exit 0 ;; esac
case "$(basename "$f")" in *_0_setup.m) exit 0 ;; esac
[ -f "$f" ] || exit 0

hits="$(grep -nE '^\s*(clear|clearvars)\s*(;|%|$)|^\s*clear\s+all\b' "$f" | cut -d: -f1 | paste -sd, -)"
if [ -n "$hits" ]; then
  {
    echo "규칙 위반 (hook_matlab_rules.sh): $(basename "$f") 줄 $hits 에 맨 clear 가 있다."
    echo "러너 · 확인 스크립트는 기본 작업공간에서 돌므로, 맨 clear 는 다른 모델이 읽는"
    echo "변수까지 지운다 (2026-09-11 W01_openloop · W01_current 가 멈춘 원인)."
    echo "제 변수만 이름으로 지운다:  clear m cfg y ...   (WXX_0_setup.m 만 예외)"
  } >&2
  exit 2
fi
exit 0
