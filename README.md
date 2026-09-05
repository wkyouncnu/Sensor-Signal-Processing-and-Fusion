# 대학원 USV 유도·항법·제어

Fossen 의 **Otter** 를 Simulink 하나로 다루는 대학원 강의. 근거는 MSS 와 Fossen Handbook.

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
| W02 | [Surge Speed Control](lectures/W02_Surge_Speed_Control.md) | `W02_surge` · `W02_antiwindup` · `W02_pseudo` |
| W03 | [Heading Control](lectures/W03_Heading_Control.md) | `W03_heading` |
| W04 | [Waypoint Following and LOS Guidance](lectures/W04_Waypoint_Following_and_LOS_Guidance.md) | `W04_guidance` |
| A1 | [Actuation and the Control Effectiveness Matrix](lectures/A1_Actuation_and_the_Control_Effectiveness_Matrix.md) (부록) | `A1_actuation` |

W05 이후는 [PLAN.md](PLAN.md) §2 참조. **W04 는 유도, W05 는 Control Allocation** 이다 —
사용자 결정으로 둘의 순서를 바꿨다.

## 실행

```matlab
cd lectures/W01_simulink
W01_setup        % 학생이 고치는 유일한 파일
W01_run          % 수치 표를 찍고 img/ 에 그림을 저장한다
```

- `build_wXX_models` 는 모델을 **코드로** 다시 만든다. 실습 중 모델을 부숴도 이 한 줄로 복구된다.
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
