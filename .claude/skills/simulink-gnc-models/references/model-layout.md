# 모델 배치 — MSS 규약을 따른다

사용자가 명시적으로 요구한 규칙이다.

> **"명령 값이 왼쪽에 오고 제어기 오고 control allocation 오고
> 그 다음에 동역학 오는 순서대로 깔끔하게 정리하고 subsystem 으로 잘 정리해줘"**

근거는 MSS 툴박스의 데모 모델이다. 새 모델을 만들기 전에 한 번 열어본다.

```
Tools/MSS/SIMULINK/mssSimulinkDemos/demoOtterUSVHeadingControl.slx
```

---

## 1. 여섯 단계, 왼쪽에서 오른쪽으로

MSS 데모의 최상위는 정확히 이 순서다.

```
command  -->  reference  -->  controller  -->  allocation  -->  plant  -->  measurement
psi_ref       Reference       Heading         Control         Otter USV    Demux
X_desired     model           autopilot       allocation      (otter.m)    Scopes
                                                                           XY plot
```

| 단계 | 하는 일 | 이 볼트의 블록 이름 |
|---|---|---|
| command | 무엇을 요구하는가 | `Heading command`, `Speed command` |
| reference | 그것이 실현 가능한가, 얼마나 빨리 | `Reference model` |
| controller | 그러려면 어떤 힘이 필요한가 | `Heading autopilot`, `Surge controller` |
| allocation | 어느 추진기가 그 힘을 내는가 | `Control allocation` |
| plant | 배가 어떻게 반응하는가 | `Otter USV` |
| measurement | 무엇을 기록하는가 | `Measurements` |

**없는 단계는 그냥 빼고 나머지가 당겨진다.** 순서가 계약이지 좌표가 계약이 아니다.
W01 은 제어기도 배분도 없으므로 세 블록만 남는다.

---

## 2. 공용 도구

직접 좌표를 쓰지 않는다. `_tools/` 의 함수를 쓴다.

| 함수 | 하는 일 |
|---|---|
| `gnc_chain(stages)` | 단계 목록을 주면 표준 좌표 struct 를 돌려준다. 없는 단계는 알아서 당긴다 |
| `add_subsys(mdl, name, pos, ins, outs, colour)` | **이름 붙은 포트**를 가진 빈 서브시스템을 만든다 |
| `gnc_colour(stage)` | 단계별 색. 색은 의미이지 장식이 아니다 |
| `add_measurement(mdl, pos, tag, extra)` | 마지막 단계를 통째로 만든다 — 셀렉터·로깅·스코프·live view |
| `add_sum(sys, name, signs, centre)` | MSS 규격의 20×20 둥근 Sum |
| `mss_style(mdl)` | 모든 블록을 MSS 치수로. `save_system` 직전 한 줄 |
| **`port_xy(sys, blk, kind, k)`** | 포트 위치 `[x y]`. 포트 높이는 **읽는다**, 계산하지 않는다 |
| **`row_feed(sys, dst, srcs)`** | 소스를 각자 포트 높이로 옮기고 직선으로 잇는다 |
| **`lane_line(sys, s, sk, d, dk, x)`** | 이름 붙인 수직 통로 하나로 잇는다 |
| **`check_overlaps(mdl, verbose)`** | 겹친 선을 센다. **0 이 합격선** |

```matlab
P = gnc_chain({'command','controller','allocation','plant','measurement'}, ...
              'Height', struct('controller',130), 'Y', 120);

c = add_subsys(m, 'Heading autopilot', P.controller, ...
               {'psi_d','x'}, {'tau_N'}, gnc_colour('controller'));
% ... c 안에 블록을 채운다 ...

add_otter_plant(m, 'Otter USV', P.plant, cfg);
add_measurement(m, P.measurement, 'W03', {'psi_d','tau_N','n1','n2'});
```

체인 전체가 x = 950 에서 끝나므로 내보낸 PNG 가 **2000 px** 안에 들어온다.

---

## 3. 서브시스템으로 나누는 이유

- **최상위는 신호 흐름만 보여준다.** 블록 여섯 개, 그 사이의 선, 그리고 피드백 선 한둘
- 제어기가 무엇을 하는지 알고 싶은 사람은 **제어기를 연다**
- 게인·합·적분기를 한 캔버스에 다 늘어놓으면 문서에 넣을 수 없고,
  블록 하나를 옮길 때마다 배치가 무너진다

> [!important] 포트 이름이 곧 인터페이스다
> `In1`, `Out1` 을 그대로 두지 않는다. 포트 이름은 최상위 다이어그램에서 선 옆에
> 그대로 보이므로, `psi_d` 와 `tau_N` 이 주석 한 줄 없이 모델을 설명한다.

---

## 4. 뒤로 가는 선은 최소한으로

앞으로 가는 선은 체인이 정해준다. **뒤로 가는 선은 하나하나 정당화한다.**

| 신호 | 어디서 어디로 | 왜 |
|---|---|---|
| `x` | plant → controller | 측정값. 12 상태를 통째로 보내고 **제어기 안에서 셀렉터로 고른다** |
| `X_sat` | allocation → controller | 구동기가 **실제로 낸** 힘. 안티와인드업이 이것 없이는 불가능하다 |

12 상태를 통째로 보내는 이유: 최상위에 Demux 와 셀렉터를 늘어놓으면 체인이 다시
난잡해진다. 제어기가 무엇을 쓰는지는 제어기를 열면 첫 블록이 말해 준다.

---

## 5. 로깅 계약

`add_measurement` 가 모든 주차에서 **같은 앞 여섯 열**을 남긴다.

```
1 u    2 v    3 r[rad/s]    4 N    5 E    6 psi[deg]    7.. 그 주차의 추가 신호
```

- 베이스 워크스페이스의 변수 이름은 주차 태그 (`W01`, `W02`, `W03`)
- 주차가 다른 열 순서로 일하고 싶으면 **읽는 곳 한 군데에서** 재배열한다
  (`W02_run.m` 의 `o.y = y(:, [7 1 8 9 10 11]);`). 지수를 여기저기 고치지 않는다

---

## 6. 점검

- [ ] 최상위 블록이 여섯 개 이하인가
- [ ] 왼쪽에서 오른쪽으로 command → … → measurement 순인가
- [ ] 모든 포트에 이름이 있는가
- [ ] 뒤로 가는 선이 두 개 이하이고, 각각 이유가 있는가
- [ ] 내보낸 블록도 PNG 폭이 2000 px 이하인가
- [ ] 색이 `gnc_colour` 를 따르는가
- [ ] 주석(annotation) 을 손으로 줄바꿈했는가 — Simulink 는 자동 줄바꿈하지 않는다
- [ ] **`check_overlaps(mdl)` 이 0 인가** — 최상위와 모든 서브시스템
- [ ] 서브시스템을 PNG 로 뽑아 **눈으로** 봤는가 — 이름 겹침 · 블록을 관통하는 선 · 사선

---

## 블록 치수 — MSS 를 그대로 따른다

사용자 지시: **"error 계산할때 +- 하는 부분의 동그라미도 너무 커... mss 보면서 잘 정리해줘...
작고 가독성 좋게"**, **"다른 것들도 mss toolbox 의 시뮬링크 파일의 가독성을 보고
비슷한 크기와 방법대로 수정해줘"**

치수를 지어내지 않았다. `mssSimulinkDemos` 의 모든 데모를 훑어 블록 종류별 중앙값을
낸 것이고, 그 표가 `_tools/mss_style.m` 안에 있다. (Sum 211개, Gain 242개, Inport 354개 …)

| 블록 | MSS | Simulink 기본 |
|---|---|---|
| **Sum** | **20×20, `IconShape='round'`** | 25×40 사각형 |
| Gain | 50×36 | 40×40 |
| Constant | 55×30 | 60×40 |
| Integrator | 30×30 | 40×40 |
| Transfer Fcn | 60×36 | 원하는 대로 커짐 |
| Saturate · Scope · Step · Switch | 30×30 | |
| Inport · Outport | 30×14 | 30×30 |
| Clock · Terminator | 20×20 | |

### 쓰는 법 — 두 줄

```matlab
add_sum(c, 'error', '+-', [280 90]);   % 중심 좌표로 놓는다. 신호선과 중심을 맞춘다
...
mss_style(m);                          % save_system 직전에 한 번. 나머지를 전부 맞춘다
```

- `add_sum` 은 부호에 `|` 스페이서를 자동으로 넣는다 (`'+-'` → `'|+-'`).
  이것이 없으면 두 부호가 왼쪽 모서리에 몰려 작은 원에서 읽히지 않는다. MSS 가 그렇게 쓴다
- `mss_style` 은 **중심을 유지한 채** 크기만 바꾼다. 신호선에 맞춰 둔 블록이 어긋나지 않는다
- `mss_style` 은 SubSystem 을 건드리지 않는다. 체인 여섯 단계의 크기는 `gnc_chain` 이 정한다

### 서브시스템 안쪽도 검사한다

최상위만 깨끗해서는 안 된다. 서브시스템을 각각 뽑아서 눈으로 본다.

```matlab
subs = find_system(mdl,'SearchDepth',1,'BlockType','SubSystem');
for i = 1:numel(subs)
    print(['-s' subs{i}], '-dpng', '-r110', fullfile(d, [get_param(subs{i},'Name') '.png']));
end
```

> [!warning] `Simulink.BlockDiagram.arrangeSystem` 을 쓰지 않는다 — 서브시스템 안쪽에도
> 시험해 봤고 버렸다. 더 조밀하게 싸주기는 하는데 **블록 순서를 바꾼다.**
> W02 `Surge controller` 에 걸었더니 출력 포트 `X_cmd` 를 **왼쪽 맨 위**, 입력 포트보다
> 앞에 놓았다. 조밀함이 목적이 아니라 **왼쪽에서 오른쪽으로 읽히는 것**이 목적이다.
> 안쪽도 최상위와 같은 방식으로 **손으로 열을 잡아** 배치한다.

---

## 선이 겹치면 안 된다 — 규칙 셋과 도구 넷

> [!important] 합격선은 `check_overlaps(mdl)` 이 **0** 이다
> 겹친 두 선은 인쇄하면 한 선이다. 읽는 사람은 **어느 출발점이 어느 도착점에 닿는지**
> 알 수 없고, 그림이 실제로 없는 연결을 주장한다. 최상위와 **모든 서브시스템**에 대해
> 0 이어야 그 모델이 끝난 것이다.
>
> ```matlab
> check_overlaps('W02_surge_control', true)   % true 면 건건이 출력
> ```
>
> **한 신호의 분기는 지적하지 않는다.** 팬아웃은 일부러 한 줄기를 공유하며 그것이 옳다.
> 도구가 출발 포트가 같은 구간을 건너뛴다.

### 규칙 1 — 포트 높이에 소스를 맞춘다 (`row_feed`)

입력이 많은 블록(파라미터를 신호로 받는 MATLAB Function 이 대표적)이 가장 잘 망가진다.
Constant 를 왼쪽에 쌓아 두면 선 일곱 개가 제각기 꺾이고, autorouting 이 그중 몇 개를
**같은 수직 통로**에 합친다. 소스를 **자기 포트의 높이**로 옮기면 전부 직선 한 토막이 되고,
직선은 겹칠 수가 없다.

```matlab
row_feed(a, 'allocation', [{'tau_N','X_ff'} KK]);   % 빈 칸 '' 은 그 포트를 건너뛴다
```

- 소스는 **출력 포트가 하나**여야 한다 (Constant · Inport · Gain · Selector)
- 세로로만 옮긴다. x 는 빌더가 정한 자리에 남는다
- **그 블록만을 위해 존재하는 블록에만 쓴다.** W02 에서 `PID block` 을 스위치 행에
  맞추게 했더니 비교 대상인 손으로 만든 경로 **위로 끌려 올라갔다**. 선택 상수는 옮겨도
  되고, 경로 전체를 이루는 블록은 옮기면 안 된다

### 규칙 2 — 꺾이는 선에는 이름 붙인 통로를 준다 (`lane_line`)

```matlab
lane_line(sub, 'N', 1, 'Animate', 1, 360);   % 360 이 이 신호의 수직 통로
```

- 통로 x 가 같은 선 둘은 **소스에서 눈으로 잡히는 버그**다. autorouting 은 그것을 숨긴다
- 두 포트가 이미 같은 행이면 통로를 무시하고 직선을 긋는다. 호출은 그대로 두면 된다
- **둥근 Sum 의 두 번째 입력은 원의 아래쪽에 있다.** 옆에서 들어가면 안 되고 밑에서
  올라와야 한다. `lane_line` 이 포트 x 가 블록 x 범위 **안**인 것을 보고 알아서 세로로 붙인다

### 규칙 3 — 한 행에 한 뜻. 두 경로는 두 높이

W02 `Controller bank` 는 행마다 비례 경로와 미분 경로가 같이 있다. 둘을 같은 높이에 두면
미분 블록들이 비례 신호선 **위에** 그려진다. 미분 경로를 70 px 아래로 내리고 Sum 의
아래쪽 입력으로 되올렸다.

### 규칙 4 — 포트 높이는 **읽는다**. 계산하지 않는다

```matlab
q = port_xy(sub, 'log', 'Inport', 3);   % [x y]
```

Simulink 의 포트 간격은 블록 종류마다 다르고, 맞을 것 같은 공식이 몇 픽셀씩 틀린다.
그러면 그림이 **얕은 사선**으로 가득 찬다. 측정해서 알아낸 것:

| 블록 | 첫 포트 | 간격 |
|---|---|---|
| MATLAB Function · Switch 등 SubSystem | 위에서 20 px | `(H-40)/(n-1)` |
| **Mux** | 위에서 `H/(2n)` | `H/n` |
| **Demux** | 위에서 `H/(2n)` | `H/n` |

블록을 만들기 **전에** 크기를 정할 때만 이 표를 쓰고, 다른 블록을 놓을 때는 `port_xy` 로
**읽는다.** 실제 순서는 이렇다.

1. 행을 정의하는 Mux · Demux · 큰 함수 블록을 **먼저** 만든다
2. `port_xy` 로 행 높이를 읽는다
3. 나머지 블록을 그 행에 놓고 잇는다

`add_measurement` 과 W02 `Controller bank` · `Plant bank` 가 이 순서로 되어 있다.

### 간격은 52 px 이상

블록은 30 px 높이에 이름이 그 아래 붙는다. 행 간격이 46 px 이면 이름이 아래 블록의
테두리에 닿는다. **52 px** 이 최소값이고, `row_feed` 가 그보다 좁으면 경고하면서
필요한 블록 높이 `52(n-1)+40` 을 알려 준다.

---

## 파일 이름과 실행 단위 — 강의 순서 그대로

사용자 지시: **"하나의 m 파일에서 시뮬링크 전체를 다 돌리니 내용을 하나하나 확인하기가
힘들어... 하나만 실행하면 다 보이도록 하지 말고 하나하나 분할해서 돌려볼 수 있도록...
예를 들어 antiwind-up 따로... m 파일과 시뮬링크 파일 이름이 매칭도 쉽지 않아...
강의 PDF 와 MD 파일 순서대로 돌려 볼 수 있도록 파일이름에도 순서가 느껴지도록"**

### 규칙 — 강의 절 하나에 스크립트 하나

한 러너가 그림을 여섯 장 쏟아내면 강의 중에 짚어 갈 수가 없다. **강의 Part 2 의 절
하나가 스크립트 하나**이고, 그 스크립트는 **그림 한 장과 표 하나**만 낸다.

```
WXX_simulink/
├── WXX_0_setup.m                파라미터. 맨 처음 한 번
├── WXX_1_build_<모델>.m          모델을 만든다.  -> WXX_<모델>.slx
├── WXX_C_<절 이름>.m             강의 C 절            그림 1장
├── WXX_D_<절 이름>.m             강의 D 절            그림 1장
├── WXX_H_<절 이름>.m             강의 H 절            + WXX_H_<모델>.slx
└── WXX_<모델>.slx
```

| 규칙 | 이유 |
|---|---|
| 접두 `0_`·`1_` 다음에 **강의 절 문자** | 숫자가 문자보다 먼저 정렬되므로 setup·build 가 맨 위에 온다 |
| 파일명에 **절 문자와 내용**이 함께 | `W02_H_antiwindup.m` 이면 강의 H 절이라는 것과 무엇인지가 한눈에 |
| 모델과 스크립트가 **같은 접두사** | `W02_H_antiwindup.m` ↔ `W02_H_antiwindup.slx`. 짝을 찾을 필요가 없다 |
| **`function` 이 아니라 스크립트** | 위에서 아래로 읽힌다. 변수가 워크스페이스에 남아 학생이 이어서 만져볼 수 있다 |
| 공용 코드만 `_tools/` 의 함수로 | `run_sim` 처럼 여러 주차가 쓰는 것만 |

### 시뮬링크만 눌러도 그림이 나와야 한다

학생이 `.slx` 를 열고 Run 만 눌러도 그 절의 그림이 떠야 한다.

- `set_param(m,'StopFcn','<그 절의 plot 스크립트>;')`
- 그리고 **Scope 를 그 절에 맞는 신호에 붙여** `'Open','on'` 으로 열어 둔다.
  Scope 는 실행 중에 보이고, StopFcn 그림은 끝나고 남는다. 둘 다 필요하다

> [!caution] 스크립트와 모델에 **같은 이름**을 주지 않는다 — 조용히 아무것도 안 한다
> `W02_H_antiwindup.m` 과 `W02_H_antiwindup.slx` 를 나란히 두었더니, 명령창에
> `W02_H_antiwindup` 을 치면 MATLAB 이 **모델을 여는 쪽**을 골랐다. 스크립트는
> 실행되지 않는데 **에러도 안 난다.** "OK" 가 찍히고 그림만 갱신되지 않았다.
>
> 게다가 그 뒤에 숨어 있던 진짜 문법 오류(함수를 스크립트로 바꾸며 남은 `end`)까지
> 가려져서, 이름을 바꾸고 나서야 드러났다.
>
> **규칙: 모델은 `<주차>_<절>_<이름>.slx`, 그 절의 스크립트는 `..._run.m`.**
>
> ```
> W02_H_antiwindup.slx        모델
> W02_H_antiwindup_run.m      그 절을 돌리는 스크립트
> ```
>
> 자기 모델이 없는 절(공용 모델을 쓰는 C~G)은 이름이 겹칠 일이 없으므로 `_run` 이 필요 없다.

> [!caution] 함수를 스크립트로 바꿀 때 **닫는 `end` 를 지운다**
> `function out = foo(...)` 를 지우면 그 함수를 닫던 `end` 가 고아가 되어
> `예약된 키워드 "end"의 사용이 적절치 않습니다` 가 난다. 파일 끝의 지역 함수들은
> 스크립트에서도 그대로 쓸 수 있으므로 **그 `end` 하나만** 지운다.
