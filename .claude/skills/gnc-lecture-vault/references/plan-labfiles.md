# 계획 · 실습 파일 구조와 선 정리 (`PLAN.md` §8 · §9)

> [!note] 이 파일은 `PLAN.md` 에서 갈라져 나온 것이다
> 계획의 **원본과 색인은 `PLAN.md`** 다. 이 파일이 담는 것은 §8 **실습 파일 구조**
> (주차 폴더가 왜 그 모양인지, 절 하나에 스크립트 하나) 와 §9 **선이 겹치지 않는 모델**
> (`check_overlaps` · `port_xy` · `row_feed` · `lane_line`) 이다.
> 형식의 원본은 `CLAUDE.md` §2 와 `simulink-gnc-models/references/model-layout.md` 이고,
> 여기 있는 것은 **그렇게 만든 기록**이다.

---

## 8. 실습 파일 구조 — 강의 절 하나에 스크립트 하나

사용자 지시로 2026-09-05 에 바꿨다. **W01·W03·W04·W05·A1 다섯 모두 끝났다.**

```
lectures/W03_simulink/
├── W03_0_setup.m                     파라미터. 세션마다 한 번
├── W03_1_build_surge_control.m       ->  W03_surge_control.slx
├── W03_C_identify_plant.m            강의 C 절
├── W03_D_proportional_only.m         강의 D 절
├── W03_E_integral_and_derivative.m   강의 E 절
├── W03_F_windup.m                    강의 F 절
├── W03_G_block_vs_handbuilt.m        강의 G 절
├── W03_H_build_antiwindup.m          ->  W03_H_antiwindup.slx
├── W03_H_antiwindup_run.m            강의 H 절
├── W03_I_build_pseudo_derivative.m   ->  W03_I_pseudo_derivative.slx
├── W03_I_pseudo_derivative_run.m     강의 I 절
├── W03_vars.m   W03_cols.m           공용 — 값과 로그 열 이름
└── img/
```

- 스크립트 하나가 **그림 한 장(또는 그 절의 그림들)** 과 표 하나만 낸다
- 파일명 앞의 숫자·절 문자가 **강의 순서 그대로**다
- 강의 MD 의 절마다 **"To produce every figure in this section"** 블록이 있어
  어떤 `.m` 과 어떤 `.slx` 를 돌리면 그 그림이 나오는지 적혀 있다

W04 과 A1 도 같은 모양이다.

```
lectures/W04_simulink/                 lectures/A1_simulink/
├── W04_0_setup.m                      ├── A1_0_setup.m
├── W04_1_build_heading.m              ├── A1_1_build_actuation.m
├── W04_C_proportional_only.m          ├── A1_C_four_layouts.m
├── W04_D_derivative_action.m          ├── A1_D_attainable_set.m
├── W04_E_the_wrap.m                   ├── A1_E_command_that_turns.m
├── W04_F_big_turns_overshoot_less.m   ├── A1_F_sway_without_force.m
├── W04_vars.m  W04_read.m             ├── A1_vars.m  A1_read.m
└── img/                               └── img/
```

W05 도 같은 모양이다. 절이 여섯이라 절 스크립트가 여섯이다.

```
lectures/W05_simulink/
├── W05_0_setup.m                     학생이 고치는 유일한 파일
├── W05_1_build_guidance.m            ->  W05_guidance.slx  (네 척이 나란히)
├── W05_C_aim_at_the_waypoint.m       C 절 — atan2 는 왜 경로추종이 아닌가
├── W05_D_line_of_sight.m             D 절 — 법칙을 두 조각으로 분해
├── W05_E_lookahead_distance.m        E 절 — Delta 스윕 다섯
├── W05_F_waypoint_switching.m        F 절 — 판정 둘, R 스윕 넷
├── W05_G_current_and_integral.m      G 절 — 조류 아래 네 법칙
├── W05_H_adaptive_and_stability.m    H 절 — kappa·gamma 스윕과 V(t)
├── W05_vars.m  W05_read.m  W05_plot.m
└── img/
```

W01 도 같은 모양이다. 모델이 둘이라 빌더가 둘이다.

```
lectures/W01_simulink/
├── W01_0_setup.m                     파라미터
├── W01_1_build_openloop.m            ->  W01_openloop.slx
├── W01_C_terminal_speed.m            강의 C 절 — 그림 2장
├── W01_D_the_manoeuvre.m             강의 D 절 — 그림 2장
├── W01_E_build_current.m             ->  W01_current.slx
├── W01_E_current_run.m               강의 E 절 — 그림 2장
├── W01_vars.m   W01_read.m           공용
└── img/
```

### 남은 일 — 전부 끝났다

| 항목 | 상태 |
|---|---|
| W03·W04·A1·W01 을 절 단위로 분할 | **완료** (2026-09-05) |
| 그림마다 "읽어서 강의가 되는" 자세한 설명 | **완료** — 결과 그래프 **29장 전부** |
| Simulink 만 눌러도 그 주차 신호가 뜨는 Scope | **완료** — `add_measurement` 이 `<tag> this week` 스코프를 만든다 |

**그래프 설명 29장의 내역** — 의미 · 경향(수치) · 원리 · 알고리즘별 차이 · 상황별 차이,
중요한 곳은 굵게. 규칙은 `results-and-figures.md`.

| 주차 | 결과 그래프 | 설명 |
|---|---|---|
| W01 | 6 | 6 |
| W03 | 10 | 10 |
| W04 | 4 | 4 |
| A1 | 3 | 3 |
| W05 | 6 | 6 |

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
| `W03_surge_control` | 6 | **0** |
| `W03_H_antiwindup` | 4 | **0** |
| `W03_I_pseudo_derivative` | 29 | **0** |
| `W04_heading_control` | 2 | **0** |
| `A1_actuation` | 4 | **0** |
| `W05_guidance` | 572 | **0** |

`add_measurement` 을 다시 썼다. Mux 를 먼저 만들고 포트 높이를 읽은 뒤 셀렉터와 여분
입력을 그 행에 놓으므로, 로깅 열 하나가 **직선 한 토막**이다. 모든 주차가 이 함수를
쓰므로 한 번 고쳐서 전부 좋아졌다.

규칙은 `simulink-gnc-models/references/model-layout.md` 의 **"선이 겹치면 안 된다"** 절.
