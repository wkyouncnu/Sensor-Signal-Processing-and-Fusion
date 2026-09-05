# 기록 — GitHub 에 남긴다

> 사용자 지시: **"세션 완료되거나 새로운게 업데이트 되면 자동으로 푸쉬해줘...
> 기록들을 다 잇도록"**

---

## 1. 무엇이 올라가는가

| | |
|---|---|
| 저장소 | `git@github.com:wkyouncnu/Sensor-Signal-Processing-and-Fusion.git` — **private** |
| 올라가는 것 | `00_GradCourse_2026/` **하나뿐** |
| 올라가지 않는 것 | 상위 폴더의 `강의자료` · `10_연구_USV_MILS`(MSS 120 MB) · `40_PX4_HILS` · `90_보관` |

> [!important] 범위를 넓히지 않는다
> 상위 폴더에는 **출석부**가 있다. 학생 개인정보이고, 한 번 올라가면 지워도 캐시와
> 인덱스에 남는다. 사용자가 2026-09-05 에 **"00_GradCourse_2026 만"** 을 골랐다.
> 범위를 바꾸려면 다시 물어본다.

`.gitignore` 가 빼는 것은 **되만들 수 있는 것**뿐이다 — `slprj/` · `*.slxc` · `*.asv` ·
임시 HTML. **`.pdf` 는 추적한다.** 그것이 산출물이기 때문이다.

---

## 2. 언제 올라가는가

`.claude/settings.json` 의 **SessionEnd 훅**이 `_tools/git_autopush.sh` 를 부른다.
세션 하나에 커밋 하나다.

```bash
bash _tools/git_autopush.sh              # 손으로도 아무 때나
bash _tools/git_autopush.sh --dry-run    # 무엇이 올라갈지만 본다
```

스크립트가 지키는 것:

- **파일을 지우지 않는다.** `git add -A` 는 스테이징일 뿐이다
- **force push 하지 않는다.** 원격이 앞서 있으면 멈추고 알린다
- **push 가 실패해도 커밋은 남는다.** 기록이 사라지지 않는 것이 먼저고,
  네트워크와 인증은 다음 세션에 다시 시도된다
- 올릴 것이 없으면 조용히 끝난다. 빈 커밋을 만들지 않는다
- 커밋 제목이 **어디가 바뀌었는지**를 말한다 — `Session update: lectures, tools (7 files)`.
  "update" 만 적힌 기록은 기록이 아니다

---

## 3. 인증 — 한 번만 하면 된다

SSH 키를 `~/.ssh/id_ed25519` 에 만들어 두었다. 암호가 없는 키인데, 훅이 사람 없이
push 해야 하므로 그렇게 해야 한다. 공개키를 GitHub 에 등록하면 그 뒤로는 자동이다.

```bash
cat ~/.ssh/id_ed25519.pub
```

GitHub → Settings → SSH and GPG keys → New SSH key 에 붙여넣는다.
저장소가 아직 없으면 GitHub 에서 **private** 으로 먼저 만든다.

확인:

```bash
ssh -T git@github.com          # "Hi wkyouncnu!" 가 나오면 된 것
```

---

## 4. 한 주차를 끝낼 때의 순서

`vault_check.sh` 가 0 건이 된 **뒤에** 올린다. 깨진 상태를 기록으로 남기지 않는다.

```bash
matlab -batch "cd lectures/WXX_simulink; WXX_1_build_...; WXX_0_setup"
bash _tools/md2pdf.sh lectures/WXX_*.md
bash .claude/skills/gnc-lecture-vault/scripts/vault_check.sh   # 0 건
bash _tools/git_autopush.sh                                    # 그리고 올린다
```
