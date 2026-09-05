#!/usr/bin/env bash
#
#  git_autopush.sh — 세션이 끝날 때 볼트를 GitHub 에 올린다.
#
#      bash _tools/git_autopush.sh            변경분을 커밋하고 push
#      bash _tools/git_autopush.sh --dry-run  무엇을 올릴지만 보여준다
#
#  SessionEnd 훅이 부른다 (.claude/settings.json). 손으로 아무 때나 불러도 된다.
#
#  원칙
#    - 절대 파일을 지우지 않는다. `git add -A` 는 스테이징일 뿐이다
#    - 절대 force push 하지 않는다. 원격이 앞서 있으면 멈추고 알린다
#    - push 가 실패해도 **커밋은 남는다.** 작업 기록이 사라지지 않는 것이 우선이고,
#      네트워크나 인증은 나중에 고치면 된다
#    - 올릴 것이 없으면 조용히 끝난다. 빈 커밋을 만들지 않는다

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 0

[ -d .git ] || { echo "  [autopush] git 저장소가 아니다: $ROOT"; exit 0; }

DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

#  ---- 무엇이 바뀌었나 -----------------------------------------------------
git add -A

if git diff --cached --quiet; then
    echo "  [autopush] 변경 없음"
    exit 0
fi

N=$(git diff --cached --name-only | wc -l | tr -d ' ')

#  커밋 제목은 어디가 바뀌었는지로 만든다. "update" 만 적힌 기록은 기록이 아니다.
AREAS=""
add_area() { git diff --cached --name-only | grep -q "^$1" && AREAS="${AREAS}${AREAS:+, }$2"; }
add_area "lectures/"  "lectures"
add_area "_tools/"    "tools"
add_area "figures/"   "figures"
add_area ".claude/"   "skills"
add_area "PLAN.md"    "plan"
add_area "CLAUDE.md"  "contract"
[ -z "$AREAS" ] && AREAS="vault"

SUBJECT="Session update: $AREAS ($N files)"

if [ "$DRY" = "1" ]; then
    echo "  [autopush] --dry-run"
    echo "  제목: $SUBJECT"
    git diff --cached --stat | tail -20
    git reset -q
    exit 0
fi

#  ---- 커밋 ----------------------------------------------------------------
git commit -q -F - <<EOF
$SUBJECT

$(git diff --cached --stat | tail -25)

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
echo "  [autopush] 커밋 $(git rev-parse --short HEAD)  —  $SUBJECT"

#  ---- push ----------------------------------------------------------------
git remote get-url origin >/dev/null 2>&1 || {
    echo "  [autopush] origin 이 없다. 커밋만 남겼다."
    exit 0
}

BR=$(git rev-parse --abbrev-ref HEAD)
if git push -q origin "$BR" 2>/tmp/autopush.err; then
    echo "  [autopush] push 완료  ->  $(git remote get-url origin)  ($BR)"
else
    echo "  [autopush] push 실패 — 커밋은 남아 있다. 다음에 다시 올라간다."
    sed 's/^/      /' /tmp/autopush.err | head -6
    echo "      인증이 문제라면 ~/.ssh/id_ed25519.pub 를 GitHub 에 등록한다."
fi
