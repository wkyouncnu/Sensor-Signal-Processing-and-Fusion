# 대학원 USV 유도·항법·제어

Fossen 의 **Otter** 를 Simulink 하나로 다루는 대학원 강의. 근거는 MSS 와 Fossen Handbook.

## 수업 전에 — 강의자료 받기와 최신으로 맞추기 (Windows)

강의자료·모델·스크립트는 이 저장소 하나에 있고 학기 중에 계속 갱신된다.
**처음 한 번 clone, 그 뒤로는 수업 전마다 pull.** pull 은 바뀐 파일만 내려받는다.

| 언제 | 어디서 | 명령 |
|---|---|---|
| 처음 한 번 | PowerShell — Git for Windows 설치 | `winget install --id Git.Git -e` |
| 처음 한 번 | 강의 폴더를 둘 곳 (예: `문서`) | `git clone https://github.com/wkyouncnu/Sensor-Signal-Processing-and-Fusion.git` |
| 수업 전마다 | clone 된 폴더 `Sensor-Signal-Processing-and-Fusion` 안 | `git pull` |

- `git pull` 은 바뀐 것이 없으면 `Already up to date.` 를, 있으면 갱신한 파일 목록을 찍는다.
- 비공개 저장소다. Git 이 로그인을 물으면 강사가 접근 권한을 준 GitHub 계정으로 로그인한다.
- clone 된 파일을 직접 고치지 않는다. 실험할 주차 폴더(`lectures/WXX_simulink`)를 다른 곳에 복사해서
  쓰면 pull 이 충돌하지 않는다. 이미 고쳤다면 `git stash` → `git pull` → `git stash pop`.
- MSS 툴박스는 저장소에 없다. Otter 를 쓰는 주차는 clone 된 폴더 안 `Tools\MSS` 에 두어야 한다
  (W02 는 필요 없다).

같은 내용이 모든 강의자료 첫 장에 영어로 들어 있다.

## 어디에 무엇이 있는가

| 찾는 것 | 어디 |
|---|---|
| **계획 — 무엇을 언제 만드는가** | [PLAN.md](PLAN.md) |
| 형식 규칙 — 무엇이 옳은 모양인가 | [CLAUDE.md](CLAUDE.md) |
| 작업 순서 — 어떤 순서로 실행하는가 | `.claude/skills/gnc-lecture-vault/SKILL.md` |
| 사용자가 못박은 상시 지침 | `.claude/skills/gnc-lecture-vault/references/standing-orders.md` |
| 강의자료 (`.md` + `.pdf`) 와 실습 | `lectures/` |
| 개념도 SVG | `figures/` |
| 공용 스크립트 | `_tools/` |

폴더는 **넷뿐**이다 — `lectures` · `figures` · `_templates` · `_tools`.
빈 폴더를 미리 만들지 않는다.

## 강의자료

| 주차 | 제목 | 실습 모델 |
|---|---|---|
| W01 | [Vessel Kinematics and the Otter Motion Model](lectures/W01_Vessel_Kinematics_and_the_Otter_Model.md) | `W01_openloop` |
| W02 | [PID Control Fundamentals](lectures/W02_PID_Control_Fundamentals.md) | `W02_pid` (MSS 불필요) |
| W03 | [Surge Speed Control](lectures/W03_Surge_Speed_Control.md) | `W03_surge_control` · `W03_H_antiwindup` · `W03_I_pseudo_derivative` |
| W04 | [Heading Control](lectures/W04_Heading_Control.md) | `W04_heading_control` |
| W05 | [Waypoint Following and LOS Guidance](lectures/W05_Waypoint_Following_and_LOS_Guidance.md) | `W05_guidance` |
| A1 | [Actuation and the Control Effectiveness Matrix](lectures/A1_Actuation_and_the_Control_Effectiveness_Matrix.md) (부록) | `A1_actuation` |

W06 이후는 [PLAN.md](PLAN.md) §2 참조. **W05 는 유도, W06 는 Control Allocation** 이다 —
사용자 결정으로 둘의 순서를 바꿨다. 2026-09-21 에 PID 입문을 새 W02 로 넣으면서
그 뒤 주차가 모두 한 칸씩 밀렸다 (옛 W02 속도 → W03, 옛 W03 선수각 → W04, 옛 W04 유도 → W05).

## 실행

```matlab
cd lectures/W02_simulink
W02_0_setup                 % 학생이 고치는 유일한 파일
W02_1_build_pid             % 모델을 코드로 만든다
W02_C_proportional_only     % 절 하나에 스크립트 하나 — 표를 찍고 img/ 에 그림을 저장한다
```

- `WXX_1_build_…` 는 모델을 **코드로** 다시 만든다. 실습 중 모델을 부숴도 이 한 줄로 복구된다.
- MSS 는 이 폴더 안에 없다. `_tools/mss_path.m` 이 옆 프로젝트에서 **찾아서** 경로에 얹는다.

## PDF 다시 뽑기

```bash
bash _tools/md2pdf.sh lectures/W01_*.md
bash .claude/skills/gnc-lecture-vault/scripts/vault_check.sh
```

두 번째 명령이 **전 항목 0 건**이어야 한다.

> [!warning] PDF 뷰어를 열어 둔 채로는 다시 뽑을 수 없다
> Adobe Acrobat 이 파일을 잠그면 `md2pdf.sh` 가 "다른 프로그램이 이 PDF 를 열고 있음" 으로
> 멈춘다. 뷰어를 닫고 다시 실행한다.
