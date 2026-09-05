# 계획 — 대학원 USV 유도·항법·제어 (Simulink 전용, MSS Otter)

> [!important] 이 파일이 계획의 원본이다
> 예전에는 계획이 `~/.claude/plans/` 안의 긴 이름의 파일에 있어 찾을 수 없었다.
> **이제 계획은 여기 하나뿐이다.** 새 지침이 오면 이 파일부터 고친다.

- **볼트 위치** `C:\Users\admin\Dropbox\센서신호처리및융합\00_GradCourse_2026\`
- **최종 갱신** 2026-09-04
- **형식 규칙** → [CLAUDE.md](CLAUDE.md) · **작업 순서** → `.claude/skills/gnc-lecture-vault/`

---

## 1. 무엇을 만드는가

| | |
|---|---|
| 분량 | 본과정 **8주** + 선체·구동기 변형 **3주** = 11주 |
| 도구 | **Simulink 하나.** 선체는 Fossen 의 Otter (`otter.m`, 손대지 않는다) |
| 근거 | MSS 툴박스 · Fossen Handbook |
| 산출물 | 주차마다 `.md` + `.pdf` + `WXX_simulink/` (빌더·러너·모델·그림) |
| 언어 | 강의 본문 **영어**, 정식 교재 어조. 계획·주석·스킬 문서는 한국어 |
| 외란 | 조류 + 바람 + 파랑, 파랑필터 포함 (W07) |
| 평가 | 주차 과제 + 기말 프로젝트 |
| 기존 `Lecture/` 17주차 | **이번 산출물이 아니다.** 손대지 않는다 |

---

## 2. 진행 상황

| 주차 | 제목 | 상태 |
|---|---|---|
| **W01** | Vessel Kinematics and the Otter Motion Model | **완료** |
| **W02** | Surge Speed Control | **완료** |
| **W03** | Heading Control | **완료** |
| **A1** | Actuation and the Control Effectiveness Matrix (부록) | **완료** |
| W04 | Control Allocation | 미착수 |
| W05 | Waypoint Following and LOS Guidance | 미착수 |
| W06 | Environmental Loads and Wave Filtering | 미착수 |
| W07 | Dynamic Positioning and Mission Integration | 미착수 |
| W08 | 본과정 마무리 / 통합 | 미착수 |
| W09 | Variant A — Aft Azimuth Thrusters | 미착수 |
| W10 | Variant B — Bow Tunnel Thruster | 미착수 |
| W11 | Variant C — Four Tilting Thrusters, and a Comparison | 미착수 |
| 기말 | Final-Project 명세 | 미착수 |

> [!note] 사용자가 W03 까지 보고 검토하겠다고 했다
> W04 로 넘어가기 전에 W01~W03 검토를 받는다 → 기억 `usv-lecture-review-deferred`.

### W01 · Vessel Kinematics and the Otter Motion Model — 완료

- Part 1 을 12절로 확장: 좌표계(NED/ENU) · 자세 · 회전행렬 · 바디속도 ≠ 위치변화율 ·
  p·q·r 와 $T_\Theta$ · kinematics vs kinetics · 6/4/3 자유도와 M·C·D · 운동방정식 ·
  12 상태(프레임·단위 포함) · 프로펠러에서 힘까지 · surge · sway
- 그림: `w01-frames` · `w01-ned-enu` · `w01-euler` · `w01-velocity` · `w01-pqr` ·
  `w01-otter-layout` · `w01-6dof`
- 실습: **직진 → 좌회전 → 직진 → 우회전 → 직진**. 후진 없음. 선회는 좌우 추진기의
  작은 차이($dn$)로 만든다

### W02 · Surge Speed Control — 완료

- type 0 · 최종값 정리 · PI 영점 · 미분항이 속도루프에서 **질량**으로 들어가는 것
- 와인드업 = 포화 문제. clamping vs back-calculation
- 손으로 만든 PID 와 Simulink PID 블록 **둘 다**, 선택 가능
- 별도 모델 둘: `W02_antiwindup` ($1/(s+1)$) · `W02_pseudo` ($1/(s^2+0.4s)$)
- §I **pseudo-derivative** — 왜 직접 미분하지 않는가, $Ns/(s+N)$, $N$ 고르는 법

### W03 · Heading Control — 완료

- type 1 · `ssa()` · $r$ 에 대한 P–D · 비선형 요 감쇠 · course/crab angle

### A1 · Actuation and the Control Effectiveness Matrix — 완료

- 열 규칙에서 $\mathbf{B}$ 를 유도하고 네 형상에 적용 — 계급 2/3/3/3
- 도달가능 제어집합: $X \in [-133.42,\ 239.36]$ N, $\max\lvert N\rvert = 73.62$ N·m,
  $\max\lvert Y\rvert = 0$ **정확히**
- $n_2 = -n_1\sqrt{k_{pos}/k_{neg}} = -78.6701$ rad/s — 명령의 대칭은 힘의 대칭이 아니다.
  60 s 후 표류 $1.9376$ m 대 $0.0435$ m
- $\mathbf{B}$ 의 빈 행과 $\mathbf{M}^{-1}$ 의 빈 열은 다른 이야기 — $M_{2,6} = 12.25$ kg·m
- 절 단위 스크립트 · 결과 그림 세 장에 상세 설명 완료

---

## 3. 다음에 할 일

1. **W01 을 절 단위 스크립트로 분할** — 마지막 남은 하나 (§8)
2. **그림 설명 붙이기** — W01·W02·W03 의 모든 결과 그림에 "읽으면 강의가 되는" 설명.
   A1 은 끝났다 (§8)
3. 절마다 **Scope** 를 붙여 Simulink 에서 Run 만 눌러도 그 절 그림이 뜨게 한다
4. **W01~W03 검토를 받는다** (사용자 요청)
5. W04 Control Allocation — 가중 최소자승, 제약 배분, `quadprog`
6. W05 LOS 유도 — 적분 LOS 포함
7. 이후 W06~W11

---

## 4. 남은 정리 작업

| 항목 | 상태 |
|---|---|
| 볼트를 `00_GradCourse_2026` 으로 이동, MSS 는 `mss_path.m` 이 찾음 | 완료 |
| 빈 폴더 5개 제거, `lectures/` · `figures/` 로 단순화 | 완료 |
| `예제코드`·`PX4-HILS`·`Termproject` → `30_`·`40_`·`50_` | 완료 |
| zip·출석부 → `90_보관/` | 완료 |
| `Proj_SHI_USV_MILS` → `10_연구_USV_MILS` 이름 변경 | **완료** (훅이 처리, 1361개 그대로) |
| `강의자료` → `20_강의자료` 이름 변경 | **미완 — 아직 잠김.** 훅이 세션마다 재시도한다 |
| Simulink 블록 치수를 MSS 에 맞춤 (`add_sum` · `mss_style`) | 완료 |
| W02 §2-1 · W03 §3-1 유도 추가, Nomoto 1·2차 추가 | 완료 |
| 계수 검증 `verify_constants.m` — 16개 전부 `otter.m` 과 일치 | 완료 |

> [!caution] 남은 두 개는 재부팅 뒤에 스크립트로 한다
> 파일은 하나도 건드리지 않았다(각각 1361개·88개 그대로).
>
> ```powershell
> powershell -ExecutionPolicy Bypass -File _tools\rename_top_folders.ps1
> ```
>
> 그 스크립트가 이름만 바꾸고 **바꾸기 전후 파일 수를 대조**한다. 막히면 그대로 두고 알린다.
>
> **무엇이 잡고 있었나.** 안의 파일은 **하나도 잠겨 있지 않은데 디렉터리만** 잠겼다.
> `Proj_SHI_USV_MILS` 는 Claude Code 세션이 프로젝트 폴더로 잡고 있던 것이 맞았고,
> 세션이 옮겨간 뒤 훅이 곧바로 이름을 바꿨다. 남은 `강의자료` 는 `2025년` 하위가
> 잠겨 있고 Dropbox 로 보인다 — 훅이 세션마다 다시 시도하므로 손댈 것이 없다.
>
> 이름을 바꾼 뒤에도 강의자료는 그대로 돈다 — `_tools/mss_path.m` 이 MSS 를
> **찾아서** 올리기 때문에 고칠 경로가 없다.

> [!caution] 2026-09-04 22:16 삭제된 폴더를 휴지통에서 복구했다
> `Lecture`(592) · `Proj/Proj/강의자료`(2) · `강의자료/2026년/slide-master` ·
> `강의자료/2026년/references` 넷이 휴지통에 들어가 있었다. 전부 되돌렸고 파일 수가
> 원래대로 맞는 것을 확인했다(88, 592, 2). 이 세션의 명령이 한 일은 아니다 —
> `rm`·`Remove-Item` 은 휴지통을 거치지 않고 바로 지우기 때문이다.

---

## 5. 플랜트 구조 — 이 설계의 핵심 결정

`otter.m` 은 `numel(n) == 2` 를 강제하므로 W09~W11 에 그대로 못 쓴다.
네 번 복사하는 것은 **틀린 답**이다. 파라미터화된 플랜트 하나를 쓴다.

```matlab
cfg = otter_config('base' | 'aft_azimuth' | 'bow_thruster' | 'quad_tilt');
add_otter_plant(mdl, 'Otter plant', pos, cfg);
```

- 선체 유체동역학(`M`, `C_A`, `C_RB`, 교차흐름 감쇠, 복원력, $N_h = N_r(1+10|r|)r$)은
  **네 형상에서 한 글자도 다르지 않다.** 그래야 비교가 정직하다
- 바뀌는 것은 `B`, 추진기 개수, 틸팅 여부, 방위각 한계뿐이다

> [!warning] 부호 규약 함정
> 이 프로젝트에는 **정확히 부호가 반대인 `B` 가 둘** 산다 —
> `Lecture/_tools/otter4_B.m` 과 `otter_params.m` 41행. 둘 중 어느 것도 가져오지 않는다.
> **부록 A1 의 열 규칙이 유일한 정의**이며, 모든 `B` 를 `_tools/otter_B.m` 이 거기서 유도한다.
>
> ```
> (x, y) 에 있고 방향이 e 인 추진기의 열 =  [ e_x ; e_y ; x·e_y − y·e_x ]
> ```

---

## 6. 환경

- MATLAB **R2024b** + Simulink (+ Stateflow: W07, Optimization Toolbox: W04·W11)
- MSS 는 `10_연구_USV_MILS/Proj_SHI_USV_MILS/Tools/MSS` — `_tools/mss_path.m` 이 찾는다
- PDF 는 Git Bash + Chrome 만 있으면 된다. **pandoc·LaTeX 없음** (이 PC 에 설치돼 있지 않다)

## 7. 한 주차를 끝내기 전

```bash
matlab -batch "cd lectures/WXX_simulink; build_wXX_models; WXX_run"
bash _tools/md2pdf.sh lectures/WXX_*.md
bash .claude/skills/gnc-lecture-vault/scripts/vault_check.sh
```

세 번째 명령이 **전 항목 0 건**이어야 그 주차가 끝난 것이다.

---

## 8. 실습 파일 구조 — 강의 절 하나에 스크립트 하나

사용자 지시로 2026-09-05 에 바꿨다. **W02 가 본보기이고, W03 과 A1 이 따라왔다. W01 만 남았다.**

```
lectures/W02_simulink/
├── W02_0_setup.m                     파라미터. 세션마다 한 번
├── W02_1_build_surge_control.m       ->  W02_surge_control.slx
├── W02_C_identify_plant.m            강의 C 절
├── W02_D_proportional_only.m         강의 D 절
├── W02_E_integral_and_derivative.m   강의 E 절
├── W02_F_windup.m                    강의 F 절
├── W02_G_block_vs_handbuilt.m        강의 G 절
├── W02_H_build_antiwindup.m          ->  W02_H_antiwindup.slx
├── W02_H_antiwindup_run.m            강의 H 절
├── W02_I_build_pseudo_derivative.m   ->  W02_I_pseudo_derivative.slx
├── W02_I_pseudo_derivative_run.m     강의 I 절
├── W02_vars.m   W02_cols.m           공용 — 값과 로그 열 이름
└── img/
```

- 스크립트 하나가 **그림 한 장(또는 그 절의 그림들)** 과 표 하나만 낸다
- 파일명 앞의 숫자·절 문자가 **강의 순서 그대로**다
- 강의 MD 의 절마다 **"To produce every figure in this section"** 블록이 있어
  어떤 `.m` 과 어떤 `.slx` 를 돌리면 그 그림이 나오는지 적혀 있다

W03 과 A1 도 같은 모양이다.

```
lectures/W03_simulink/                 lectures/A1_simulink/
├── W03_0_setup.m                      ├── A1_0_setup.m
├── W03_1_build_heading.m              ├── A1_1_build_actuation.m
├── W03_C_proportional_only.m          ├── A1_C_four_layouts.m
├── W03_D_derivative_action.m          ├── A1_D_attainable_set.m
├── W03_E_the_wrap.m                   ├── A1_E_command_that_turns.m
├── W03_F_big_turns_overshoot_less.m   ├── A1_F_sway_without_force.m
├── W03_vars.m  W03_read.m             ├── A1_vars.m  A1_read.m
└── img/                               └── img/
```

### 남은 일

| 항목 | 상태 |
|---|---|
| W02 를 절 단위로 분할 | **완료** |
| W03 을 절 단위로 분할 | **완료** |
| A1 을 절 단위로 분할 | **완료** (2026-09-05) |
| W01 도 같은 구조로 | **미완** — 마지막 하나 |
| 그림마다 "읽어서 강의가 되는" 자세한 설명 | **진행 중** — A1 의 결과 그림 세 장에 붙였다. W01·W02·W03 미완 |
| 절마다 Scope 를 붙여 Simulink 만 눌러도 그 절 그림이 뜨게 | **미완** |

---

## 9. 선이 겹치지 않는 모델 — 2026-09-05

사용자 지시 **"모든 시뮬링크 파일 안에 있는 subsystem 도 선들이 겹치지 않는지 정리"** 에
따라 도구를 만들고 전 모델을 통과시켰다.

| 새 도구 | 하는 일 |
|---|---|
| `_tools/check_overlaps.m` | 겹친 선을 센다. 한 신호의 분기는 세지 않는다. **합격선 0** |
| `_tools/port_xy.m` | 포트 위치를 **읽는다**. 포트 간격 공식은 블록마다 다르다 |
| `_tools/row_feed.m` | 소스를 각자 포트 높이로 옮기고 직선으로 잇는다 |
| `_tools/lane_line.m` | 꺾이는 선에 이름 붙인 수직 통로를 준다. 둥근 Sum 의 아래쪽 입력도 처리 |

결과 — 전부 **0 건**.

| 모델 | 고치기 전 | 지금 |
|---|---|---|
| `W01_openloop` · `W01_current` | 0 | 0 |
| `W02_surge_control` | 6 | **0** |
| `W02_H_antiwindup` | 4 | **0** |
| `W02_I_pseudo_derivative` | 29 | **0** |
| `W03_heading_control` | 2 | **0** |
| `A1_actuation` | 4 | **0** |

`add_measurement` 을 다시 썼다. Mux 를 먼저 만들고 포트 높이를 읽은 뒤 셀렉터와 여분
입력을 그 행에 놓으므로, 로깅 열 하나가 **직선 한 토막**이다. 모든 주차가 이 함수를
쓰므로 한 번 고쳐서 전부 좋아졌다.

규칙은 `simulink-gnc-models/references/model-layout.md` 의 **"선이 겹치면 안 된다"** 절.
