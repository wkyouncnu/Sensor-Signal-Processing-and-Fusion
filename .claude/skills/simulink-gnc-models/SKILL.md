---
name: simulink-gnc-models
description: 선박·USV의 GNC(유도·항법·제어) Simulink 모델을 MATLAB 코드로 생성하고, 블록 배치와 신호선을 읽기 좋게 정리한다. 사용자가 "시뮬링크 모델 만들어줘", "Simulink 모델 생성", "블록 배치 정리", "선 정리", "선이 복잡해", "겹치지 않게", "블록 색", "LOS 유도", "웨이포인트 추종", "로이터링", "Stateflow 미션", "VRX", "WAM-V", "추력 배분", "운동모델", "build_wXX_models", "대시보드", "슬라이더", "버튼", "실시간", "조종기", "RC", "조이스틱", "Joystick Input", "USB" 를 언급하거나, 강의용 Simulink 자료를 만들거나 고칠 때 사용하라. MATLAB MCP 로 실제 실행해 검증하는 절차까지 포함한다.
---

# Simulink GNC 모델 — 코드로 만들고, 코드로 정리한다

> [!important] 배치가 먼저다
> 모델을 쓰기 전에 **`references/model-layout.md`** 를 읽는다. 최상위는 MSS 데모와 같은
> 순서 — **command → reference → controller → allocation → plant → measurement** — 이고,
> 각 단계는 **서브시스템**이다. 좌표를 손으로 쓰지 않고 `_tools/gnc_chain` 을 쓴다.

Simulink 모델을 **손으로 그리지 않는다.** `build_wXX_models.m` 하나가 모델 전체를 만든다.
이유는 세 가지다.

- 모델이 깨져도 한 줄로 복구된다 — 학생이 마음껏 만져볼 수 있다
- 배치·색·배선 규칙을 전 모델에 **똑같이** 적용할 수 있다
- 무엇이 바뀌었는지 `.slx` 가 아니라 `.m` 의 diff 로 보인다

---

## 0. 작업 순서

1. **생성** — `build_wXX_models.m` 작성 → MATLAB MCP 로 실행
2. **정리** — 스크립트 끝에서 `tidy_layout(모델)` 을 **두 번** 호출
3. **검증** — 컴파일 · 미연결 포트 0 · 실제 시뮬레이션 실행
4. **그림** — `print('-s모델','-dpng','-r100', ...)` 로 PNG 추출
5. **문서** — MD 에 그림과 **실측 수치**를 싣고 PDF 재생성

> [!important] 수치는 반드시 실행해서 얻는다
> 문서에 싣는 오차·시간·반경은 전부 `sim()` 결과다. 추정치를 쓰지 않는다.

---

## 1. 배치 정리 — `tidy_layout`

`scripts/tidy_layout.m` 을 모델 폴더에 복사하고 부른다.

```matlab
tidy_layout('W07_0_offline')     % 한 번 더 부르면 결과가 더 좋아진다
```

`scripts/tidy_all.m` 은 폴더 전체를 돌며 **겹침 쌍 수 · 꺾인 선 수**를 표로 보고한다.
목표는 **겹침 0**. 꺾인 선은 되먹임 때문에 완전히 없앨 수 없다 (실측 15% 내외).

무엇을 하는지, 무엇이 깨지는지는 **`references/layout.md`** 에 있다.
고치기 전에 반드시 읽을 것 — 이미 밟은 지뢰가 열 개 넘는다.

### 색 규칙 (바꾸지 말 것)

| 색 | 역할 |
|---|---|
| 파랑 `[0.80 0.89 0.98]` | 유도 Guidance |
| 보라 `[0.90 0.83 0.96]` | 미션 판단 (FSM, 모드 전환) |
| 주황 `[1.00 0.88 0.72]` | 제어 Control |
| 노랑 `[1.00 0.95 0.70]` | 추진기 |
| 초록 `[0.81 0.93 0.81]` | 운동모델 Plant |
| 분홍 `[0.98 0.85 0.85]` | 외란 (바람·파랑) |
| 연보라 `[0.87 0.87 0.96]` | ROS 통신 · 신호처리 |
| 회색 `[0.93 0.93 0.93]` | 로깅·표시 |
| 흰색 | 설정값 Constant |

---

## 2. 모델을 만들 때

**`references/build-models.md`** 에 관용구가 전부 있다 — `fresh`/`setFcn`/`C`/`F`/`G`/`note`
헬퍼, Stateflow 프로그래밍 API, 대수 루프 끊는 법, 실시간 페이싱.

절대 규칙 세 가지만 여기 적는다.

1. **GNC 순서를 왼쪽에서 오른쪽으로** — 유도 → 제어 → 추진기 → 운동모델 → 로깅
2. **되먹임은 Goto/From 태그** — 화면을 가로지르는 선을 만들지 않는다
3. **오프라인 모델의 계수는 시뮬레이터와 같아야 한다** — 안 그러면 게인이 옮겨가지 않는다

---

## 3. 제어기를 쓸 때 — MSS 규약

`references/gnc-conventions.md` 참조. 자주 틀리는 세 가지:

| 흔한 실수 | 옳은 것 |
|---|---|
| 속도 되먹임에 `U = sqrt(u²+v²)` 사용 | **`u` (surge) 만** 되먹임 |
| 헤딩 D항에서 오차를 미분 | **요각속도 `r` 을 직접** 되먹임 (P–D) |
| 유도가 침로각 `χ` 를 출력 | 유도는 **`ψ_ref`** 를 출력 |

---

## 4. 검증

**`references/verify.md`** — 컴파일 확인, 미연결 포트 검사, VRX 기동·정리 명령,
RTF 와 `PacingRate` 를 맞추는 이유.

정리 명령은 반드시 `vrx_ros` 를 포함한다.

```bash
pkill -f "vrx_gz|vrx_ros|ros_gz_bridge|gz sim|ruby|parameter_bridge"
```

---

## 5. 참고 문서

| 파일 | 읽을 때 |
|---|---|
| `references/model-layout.md` | **새 모델을 만들 때 가장 먼저. 여섯 단계 체인과 서브시스템 규칙** |
| `references/layout.md` | 배치가 마음에 안 들 때. `tidy_layout` 을 고치기 전에 |
| `references/build-models.md` | 새 모델을 만들 때마다 |
| `references/gnc-conventions.md` | 제어기·유도법칙을 쓸 때 |
| `references/verify.md` | 수치를 문서에 싣기 전에 |
| `references/interactive-models.md` | **사람이 조작하는 모델** — 버튼·슬라이더·조종기 스틱, 실시간 화면, 실물 USB 조종기(Joystick Input), 장치 없이 검증하는 법 |
