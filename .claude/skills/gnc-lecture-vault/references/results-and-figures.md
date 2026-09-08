# 수식과 그림 — 주차 자료에 무엇이 반드시 들어가는가

이 문서는 사용자가 명시적으로 요구한 규칙이다.

> **모든 Simulink 블록도, 모든 수식, 모든 결과 그래프가 `.md` 와 `.pdf` 양쪽에 들어간다.**

`vault_check.sh` 가 이 규칙을 기계적으로 검사한다. 검사에 걸리면 그 주차는 끝난 것이 아니다.

---

## 1. 수식

### 1-1. MathType 이미지를 만들지 않는다

사용자가 "수식은 MathType 으로" 라고 말할 때 요구하는 것은 **조판 품질**이지 파일 형식이 아니다.
LaTeX 한 소스가 두 곳을 동시에 만족시킨다.

| 어디서 보는가 | 무엇이 렌더하는가 |
|---|---|
| `.md` — Obsidian, GitHub, VS Code | 각 뷰어의 내장 MathJax/KaTeX |
| `.pdf` — `md2pdf.sh` | MathJax 3 `tex-svg-full` 이 **SVG 벡터**로 조판 |

PDF 안의 수식은 래스터 이미지가 아니라 벡터 패스다. 확대해도 깨지지 않는다.
이것이 MathType 수준의 조판이며, 별도의 이미지 파일은 **만들지 않는다**.

### 1-2. 표기 규약

| 용도 | 쓰는 법 |
|---|---|
| 인라인 | `$y_e$`, `$\psi_d$` |
| 블록 | `$$ ... $$` — 앞뒤로 빈 줄 |
| 유도 | `\begin{aligned} ... \end{aligned}` |
| 행렬·벡터 | `bmatrix`; 벡터는 `\boldsymbol{\tau}`, `\boldsymbol{\nu}` |
| 행렬 기호 | `\mathbf{M}`, `\mathbf{B}^{\dagger}` |
| 함수 | `\operatorname{atan2}`, `\operatorname{ssa}` |
| 좌표계 | `\{n\}`, `\{b\}` — 중괄호를 이스케이프 |

### 1-3. 기호를 쓰면 표를 붙인다

수식을 낸 직후에 **기호 표**를 놓는다. 세 열이다.

| Symbol | Quantity | Value / source |
|---|---|---|
| $X_u$ | linear surge damping | $-77.5544$ N per m/s, `otter.m` |

값이 코드에서 오면 **파일명을 적는다**. "약 80" 같은 표현을 쓰지 않는다.

### 1-4. 블록 수식과 코드블록을 섞지 않는다

- 이론을 설명하는 식 → `$$ ... $$`
- Simulink 블록의 파라미터 칸에 **문자 그대로** 들어가는 식 → 코드블록

```
2*k_pos*n_cmd*abs(n_cmd)
```

같은 식을 두 형태로 반복하지 않는다. 한쪽을 고르고 다른 쪽은 참조만 한다.

---

## 2. 그림 — 주차마다 세 종류가 모두 들어간다

| 종류 | 만드는 법 | 저장 위치 | `.md` 참조 |
|---|---|---|---|
| ① 개념도 | 손으로 쓴 SVG | `figures/w01-*.svg` | `![...](../figures/w01-frames.svg)` |
| ② **Simulink 블록도** | `print('-sMODEL','-dpng','-r150', ...)` | `W01_simulink/img/` | `![...](W01_simulink/img/W01_openloop.png)` |
| ③ **시뮬레이션 결과 그래프** | 러너가 `lab_fig` + `exportgraphics(..., 'Resolution', 150)` | `W01_simulink/img/` | `![...](W01_simulink/img/W01_result_states.png)` |

**②와 ③은 선택이 아니다.** 주차마다 블록도 PNG 최소 1장, 결과 그래프 PNG 최소 1장.

### 2-1. 블록도 내보내기

```matlab
load_system('W01_openloop');
print('-sW01_openloop', '-dpng', '-r150', fullfile(here,'img','W01_openloop.png'));
close_system('W01_openloop', 0);
```

> [!warning] 내보낸 PNG 가 수천 픽셀로 늘어나면
> 원인은 둘뿐이다.
> 1. `Simulink.BlockDiagram.arrangeSystem` 또는 `tidy_layout` 이 손으로 놓은 블록을 흩뜨렸다
>    → 좌표를 직접 정한 모델에서는 **둘 다 호출하지 않는다**
> 2. 주석(annotation) 이 한 줄로 길다 — Simulink 주석은 `Position` 폭에서 **자동 줄바꿈하지 않는다**
>    → `strjoin({...}, newline)` 으로 손으로 끊는다
>
> 합격 폭은 **2000 px 이하**다. 그 이상이면 문서에서 읽을 수 없다.

### 2-2. 결과 그래프는 러너가 저장한다

사람이 스크린샷을 찍지 않는다. 모델을 다시 돌리면 그림도 같이 갱신되어야 하기 때문이다.

```matlab
f = W01_plot(R, LBL, 'W01 open loop — ...');
exportgraphics(f, fullfile(here,'img','W01_result_states.png'), 'Resolution', 150);
```

**모델의 `StopFcn` 과 러너가 같은 플로팅 함수를 부른다.** 학생이 Run 을 눌러서 보는 그림과
강의자료에 실린 그림이 한 코드에서 나와야 한다.

```matlab
set_param(m, 'StopFcn', 'W01_plot;');
set_param(m, 'ReturnWorkspaceOutputs', 'off');   % R2024b — 없으면 To Workspace 결과가 out 에 갇힌다
```

### 2-3. 궤적에는 반드시 선박과 heading 을 그린다

> [!important] XY Graph 를 쓰지 않는다
> 궤적선만으로는 **배가 어디로 갔는지**만 알 수 있고 **어디를 향하고 있었는지**는 알 수 없다.
> 해양 이동체는 sway 속도를 가지므로 선수각 `psi` 와 대지침로가 **크랩각만큼 다르다**
> (W01 선회 실험에서 20도 이상). 그러니 궤적을 그리는 모든 그림은 **선체 실루엣과
> 선수 방향선**을 함께 그린다. 이것이 사용자가 명시적으로 요구한 규칙이다.

공용 도구 세 개가 `_tools/` 에 있다. 새로 만들지 말고 이것을 쓴다.

| 파일 | 하는 일 |
|---|---|
| `draw_ship.m` | 한 점에서의 선체 실루엣 + 선수 방향선 |
| `track_ships.m` | 궤적 전체에 실루엣을 배치. 크기를 자동으로 정한다 |
| `ship_marks.m` | **호길이 기준** 등간격 인덱스. 시간 기준으로 하면 느린 구간에 몰린다 |

선체 다각형은 **선미 사각형 + 선수 삼각형**이며, 연구실 교육코드 `shipModel.m`
(J. Hong, KRISO, 2022) 을 따른다. 폭 비는 Otter 실측(2.00 m 에 1.08 m)을 쓴다.

**NED 회전** — 부호를 바꾸면 배가 반대로 돈다. 애니메이션이 거울처럼 보이는 이유는 대개 이것이다.

```
N = N0 + x_b cos(psi) - y_b sin(psi)
E = E0 + x_b sin(psi) + y_b cos(psi)
```

**크기** — 160 m 궤적 위의 2 m Otter 는 1 픽셀도 안 된다. 그래서

```
Lship = max( 0.045 * (축 범위 중 큰 쪽), 실제 전장 )
```

바닥값이 중요하다. 제자리 선회하는 배가 그리는 원은 **배보다 작다**. 축 범위에만 비례시키면
실루엣이 실제 선체보다 작아져서 그 사실이 숨겨진다. 실제 크기로 그린 그림에는
**"at true hull size" 라고 제목에 적는다.**

**여러 바퀴를 돌면 한 바퀴만 그린다.** 3.5 바퀴에 실루엣을 흩뿌리면 겹쳐서 읽을 수 없다.
마지막 한 바퀴를 잘라 6장을 놓으면 60도 간격이 되어 회전이 분명해진다.

```matlab
psi2 = R.y(:,6);                              % [deg], 랩핑되지 않음
kS   = find(psi2 <= psi2(end) - 360, 1, 'last');
seg  = kS:numel(psi2);
```

### 2-4. 살아 있는 궤적 — Animate 블록

MATLAB Function 블록은 원래 그림을 못 그린다. `coder.extrinsic` 으로 선언하면
컴파일하지 않고 MATLAB 함수를 그대로 부른다. 실제 그리기는 `WXX_animate.m` 이 한다.

```matlab
add_block('simulink/Sources/Digital Clock', [m '/clock'], 'SampleTime','h', ...);
add_block('simulink/Sources/Constant',      [m '/live view'], 'Value','animate', ...);
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/Animate'], ...);
set_mlfcn([m '/Animate'], { ...
'function ok = Animate(N, E, psi, t, en)'
'%#codegen'
'coder.extrinsic(''WXX_animate'');'
'ok = 1;'
'if en > 0.5'
'    WXX_animate(N, E, psi, t);'
'end'
'end'});
add_block('simulink/Sinks/Terminator', [m '/anim end'], ...);   % ok 출력을 받는다
```

- 축 한계·on/off·갱신주기는 **전부 `WXX_setup.m` 의 변수**로 둔다
  (`track_Nmin` … `track_Emax`, `animate`, `animate_every`). 창을 넓히는 것이
  모델 수정이 아니라 설정 수정이 되게 한다
- 애니메이터 안에서는 **핸들을 재사용한다.** 매 스텝 `patch` 를 새로 만들면
  그래픽 객체가 쌓여 그림이 기어간다
- 새 실행 감지는 `t < tPrev` 하나로 한다
- **러너는 `animate = 0` 으로 돌린다.** 배치 실행이 그림을 그릴 이유가 없다
- Animate 블록은 오른쪽 끝 자기 열에 놓는다. 로깅 Mux 위로 선이 지나가면
  블록도가 읽히지 않고 내보낸 PNG 폭이 2000 px 를 넘는다

### 2-4. 그림마다 "reading the figure" 표

모든 그림 바로 뒤에 표를 놓는다.

| Element | Meaning |
|---|---|
| blue trace | `n = [60, 60]`, ahead |
| square marker | start point |

그림 옆의 수치는 그 그림을 만든 **러너 출력 표와 같은 값**이어야 한다. 다르면 둘 중 하나가 낡았다.

---

### 2-5. 결과 그림의 결함 네 가지 — W04 에서 전부 한 번씩 냈다

그림을 렌더해서 눈으로 보는 이유가 이것이다. 넷 다 **코드는 정상 종료했고 표는 옳았다.**
그림만 틀렸다. `vault_check.sh` 도 잡지 못한다 — 그림의 **내용**은 기계가 못 본다.

#### ① 앞 절과 같은 그림

W04 C 절과 D 절이 둘 다 `W04_plot` 을 불러 **제목만 다른 같은 그림**을 냈다.
결과 그림 여섯 장 중 둘이 같은 그림이면 그 절 하나는 그림이 없는 것과 같다.

> 절마다 **그 절이 말하는 것**을 그린다. C 절은 "atan2 는 경로를 따라가지 못한다" 이므로
> 궤적과 $y_e$ 가 맞고, D 절은 "법칙은 두 조각이다" 이므로 $\pi_p$ · $\arctan$ · 그 합을
> 분해해 그리는 것이 맞다. 공용 플로터는 **기본값**이지 의무가 아니다.

#### ② 판정선이 그 절의 판정이 아니다

W04 F 절은 **along-track 판정** ($d - x_e < R$) 을 스윕하면서 웨이포인트 둘레에
**수락반경 원**을 그렸다. 바로 앞 페이지(§4-6)가 "이 둘은 다르다" 를 그림 한 장으로
설명한 참이었다. 그림이 본문을 반박한 것이다.

> 그림에 그린 임계선은 **코드가 실제로 평가한 부등식**이어야 한다.
> 직선 구간에서 $d - x_e < R$ 의 경계는 **원이 아니라 직선**이다.

#### ③ NaN 이 문장과 그림으로 새어 나간다

측정에 실패한 값을 `sw(4,1)` 처럼 **고정 인덱스**로 문장에 꽂아 두면,
그 실험이 실패하는 날 `"the vessel takes NaN m to get within 0.4 m"` 가 인쇄된다.
그림에서는 더 나쁘다 — NaN 은 선에 **말없는 구멍**을 남긴다.

> 문장은 표에서 **데이터로 만든다** (`find(ok,1,'last')`), 고정 인덱스로 쓰지 않는다.
> 빠진 점은 축 높이의 92 % 같은 **값으로 읽히는 자리**에 마커를 두지 말고,
> "구간 길이 60 m" 선을 긋고 그 **위**에 놓는다. 그러면 마커의 높이가 뜻을 갖는다.

#### ④ 한 양에 두 구간

`settled |y_e|` 를 `W04_plot` 은 마지막 1/4, D 절 스크립트는 마지막 1/5 로 쟀다.
같은 양인데 그림에는 $0.02$, 표에는 $0.0141$ 이 찍혔다.

> **한 양에는 한 구간.** 평균·RMS 의 구간은 공용 플로터가 정하고, 절 스크립트가 따른다.
> 구간은 그림과 본문 양쪽에 **적는다**.

축 이야기 하나 더. `axis equal` 은 궤적에는 옳지만 **한 축만 긴 그림에서는 그림을 죽인다.**
W04 E 절은 60 m 구간에서 9 m 안의 수렴을 보는 그림이라, `axis equal` 이 다섯 궤적을
경로선 위로 겹쳐 아무것도 안 보이게 만들었다. 축 비율을 깨는 편이 맞을 때는 깨되,
**제목이나 축 이름에 "not to the same scale" 이라고 적는다.**

---

## 3. PDF 로 넘어갔는지 확인하는 법

`md2pdf.sh` 는 임시 HTML 을 `.md` 와 **같은 폴더**에 만든다. 그래서 `W01_simulink/img/...`
같은 상대경로가 그대로 살아 있고, PNG 가 PDF 에 그대로 박힌다. 경로를 절대경로로 바꾸지 않는다.

변환 후 다음을 확인한다.

```bash
# 1. PNG 가 실제로 박혔는가 — /Width 값이 원본 PNG 의 폭과 같아야 한다
LC_ALL=C grep -a -o '/Subtype */Image' W01_*.pdf | wc -l
LC_ALL=C grep -a -o '/Width [0-9]*'    W01_*.pdf | sort | uniq -c

# 2. 수식이 조판됐는가 — 렌더된 본문에 $ 가 하나도 남아 있으면 안 된다
#    (headless --dump-dom 으로 <div id="out"> 안만 본다)
```

| 확인 | 합격선 |
|---|---|
| `/Subtype /Image` 개수 | `.md` 의 `![](...png)` 개수와 **일치** |
| `/Width` 값 | 원본 PNG 폭과 일치 |
| 렌더된 본문의 `$` | **0 개** |
| 쪽수 | **제한 없음** |

> [!note] 얇아 보이면
> 이론을 늘리기 전에 **측정 표와 그림**을 먼저 늘린다. 대학원 자료에서 부족한 것은
> 대개 설명이 아니라 근거다. 반대로 두꺼워졌다고 잘라내지는 않는다.

---

## 4. 사후 검사

```bash
bash .claude/skills/gnc-lecture-vault/scripts/vault_check.sh
```

이 문서와 관련된 항목:

| 항목 | 합격선 |
|---|---|
| `.md` 가 참조하는 `img/*.png` 가 실제로 존재 | 0 건 누락 |
| `img/*.png` 가 그 주차 `.slx` 보다 새것 | 0 건 |
| 주차마다 블록도 PNG ≥ 1 | 위반 0 |
| 주차마다 결과 그래프 PNG ≥ 1 | 위반 0 |
| 블록 수식 `$$` 의 짝 | 0 건 불일치 |
| 블록도 PNG 폭 ≤ 2000 px | 위반 0 |

---

## 궤적 그래프에 환경도 그린다 — 화살표로, 성기게

사용자 지시: **"조류의 방향이 달라지면 궤적 그래프에서 화살표로 조류의 방향도
너무 dense 하지 않게 표시해줘. 그래야 알지, 어느 각도인지"**

휘어진 궤적만으로는 **물이 어느 쪽으로 갔는지** 알 수 없다. 조류·바람이 들어간 궤적
그래프에는 그 방향을 화살표로 함께 그린다.

| 규칙 | |
|---|---|
| 개수 | **한 run 당 3개.** 그 이상은 선체 실루엣과 경쟁한다 — 선체도 읽혀야 한다 |
| 위치 | 궤적 **옆**에 비켜서. 궤적 위에 놓으면 선체와 겹친다 |
| 색 | 그 run 의 색과 같게. 어느 궤적의 조류인지 색으로 짝지어진다 |
| 길이 | 세기에 비례. 0 이면 **그리지 않는다** (정수 조건은 화살표가 없어야 맞다) |

> [!caution] NED 를 그림 축으로 옮길 때 성분을 뒤집지 않는다
> 궤적 그래프는 **가로가 East, 세로가 North** 인데 $\beta_c$ 는 **북에서 시계방향**이다.
> ```
> east  성분 = V_c sin(beta_c)
> north 성분 = V_c cos(beta_c)
> ```
> 둘을 바꾸면 모든 화살표가 대각선에 대해 뒤집히는데 **그럴듯해 보인다.**
> 코드에 이 두 줄을 주석으로 적어 둔다 — `W01_cur_plot.m` 의 `current_arrows` 참고.

같은 이유로 polar 그래프도 손봐야 한다. MATLAB 은 0°를 오른쪽에 놓고 반시계로 세지만
NED 는 북에서 시계방향이다. 나침반으로 읽히게 하려면 반드시:

```matlab
ax = gca;  ax.ThetaZeroLocation = 'top';  ax.ThetaDir = 'clockwise';
```

---

## 그림 아래에는 **읽어서 강의가 되는** 설명을 단다

사용자 지시: **"그래프가 나오면 내가 그것을 그대로 읽으면 될 정도로 의미와 경향,
그리고 원리에 대한 설명, 각 알고리즘 별 차이, 상황별 차이 등을 각 그래프 별로 아래에
설명해줘. 중간에 중요한 부분은 bold로 강조해주고. 그래프는 많은데 내가 설명을 못할 것 같아"**

"reading the figure" 표만으로는 부족하다. 그 표는 **무엇이 그려져 있는가**를 말하고,
여기서 요구하는 것은 **그것이 무슨 뜻인가**이다. 그림마다 표 **다음에** 다음을 붙인다.

> [!important] 제목은 `**What the figure says**` 로 고정한다
> 결과 그래프마다 이 제목의 불릿 목록이 하나씩 있어야 한다. 고정된 문자열이라
> 세어서 확인할 수 있다.
>
> ```bash
> for f in lectures/W*.md lectures/A*.md; do
>     echo "$f  그림 $(grep -c '^!\[' "$f")  설명 $(grep -c '^\*\*What the figure says\*\*' "$f")"
> done
> ```
>
> 개념도(SVG)와 블록도에는 붙이지 않는다 — 그 둘은 "reading the figure" 표로 끝난다.
> **결과 그래프에는 예외 없이 붙인다.** 2026-09-05 현재 W01 6 · W02 10 · W03 4 · A1 3,
> 전부 완료.

> [!caution] 2026-09-08 개정 — **범주 이름을 본문에 쓰지 않는다**
> 사용자 원문: **"모든 그래프를 의미, 경향, 원리 등으로 설명하기 보다는... 너가
> 생각했을 때 제일 이해하기 쉬운 방식대로 설명해줘... 그대로 읽으면 되게..
> 너무 설명이 긴데..알맹이가 없어"**
>
> 아래의 다섯 가지는 **글쓴이가 빠뜨렸는지 확인하는 점검표**였는데, 그것이 그대로
> **독자가 읽는 굵은 소제목**이 되어 버렸다. `**Meaning.**` `**Trend, in numbers.**`
> `**Principle.**` 로 시작하는 불릿 다섯 개는 강의에서 소리 내어 읽을 수 없다 —
> "의미. 네 개의 명령, 하나의 플랜트" 라고 읽는 사람은 없다.
>
> **점검표는 머릿속에 두고, 지면에는 이어지는 산문을 쓴다.**

### 어떻게 쓰는가

그림 앞에서 **사람이 실제로 설명하는 순서**로 쓴다. 대개 이렇게 흘러간다.

1. **무엇이 잘 되었는지** 먼저 — 독자가 그림을 볼 때 가장 먼저 눈에 들어오는 것
2. **그런데 이상한 것 하나** — 이 그림이 존재하는 이유. 숫자 둘을 나란히 놓는다
3. **틀린 설명을 먼저 지운다** — "이것 때문일까? 아니다, 그렇다면 두 곡선이 갈라졌을 것이다"
4. **진짜 원인** — 앞 절의 수식으로 되돌린다
5. **그래서 어떻게 하나** — 한 문장. 필요하면 `[!tip]` 으로

문단은 짧게, 한 문단에 한 생각. **불릿보다 산문이 낫다** — 불릿은 목록을 읽게 하고,
산문은 이야기를 읽게 한다. 그림 설명은 이야기다.

### 그래도 반드시 들어가야 하는 것 (점검표 — 제목으로 쓰지 않는다)

| | 확인 |
|---|---|
| 결론 | 이 그림이 말하는 것 하나를 한 문장으로 말할 수 있는가 |
| 숫자 | "커진다" 가 아니라 "$8.15$ 에서 $21.3\%$ 로" 인가 |
| 원리 | 왜 그렇게 되는지가 앞 절의 수식으로 이어지는가 |
| 곡선 | 범례에 있는데 본문에 한 번도 안 나온 곡선이 있는가 |
| 함정 | 잘못 읽기 쉬운 자리를 짚었는가 |

- **강조는 굵게, 한 문단에 두 개까지** (`CLAUDE.md` §1). 읽을 때 목소리가 올라갈 자리다
- 패널이 여럿이면 **패널 순서대로**. 독자의 눈이 움직이는 순서와 같아야 한다
- **소리 내어 읽어 본다.** 읽다가 걸리면 그 문장이 틀린 것이다

### 실제 예 — W02 §E (2026-09-08)

고치기 전은 `**Meaning.**` `**Trend, in numbers.**` `**Principle.**` … 다섯 불릿,
각 불릿이 세 줄. 고친 뒤는 짧은 문단 다섯:

> The integral term works. … The surprise is the overshoot. … The left panel rules
> out the obvious suspect. If the vessel were more complicated than the design
> assumed, the blue and orange curves would separate. They do not. … The right panel
> shows where the prediction went wrong. Both curves there have **identical poles**. …
> The damping ratio was designed correctly. The prediction made from it was not.

길이는 비슷한데 **읽힌다.** 차이는 하나다 — 범주 이름을 지우고 그 자리에
**왜 그 문단이 거기 있는지**를 넣었다.

---

## 그림마다 "무엇을 실행하면 이게 나오는가"를 적는다

사용자 지시: **"강의 자료에 이 그림에 대한 부분 (예를 들어 특정 세션에 대해서)
어떤 m 파일과 시뮬링크 파일을 실행하면 나오는지도 강의 자료에 추가해줘"**

강의 중에 "이 그림 다시 띄워 주세요" 라는 말이 나오면 **바로 찾을 수 있어야** 한다.
Part 2 의 절마다, 그림 **바로 앞에** 실행 블록을 둔다.

```markdown
> [!tip] To produce this figure
> | | |
> |---|---|
> | script | `W02_E_integral_and_derivative.m` |
> | model | `W02_surge_control.slx` |
> | figure | `img/W02_result_PI.png` |
>
> ```matlab
> W02_0_setup                        % once per session
> W02_E_integral_and_derivative      % this section only
> ```
```

- **스크립트 · 모델 · 그림 파일** 셋을 모두 적는다. 하나라도 빠지면 찾는 데 시간이 든다
- 모델만 열어서 Run 을 눌러도 되면 그것도 적는다 — 학생이 블록을 만져 보는 경로다
- 파일명이 강의 절 문자를 달고 있으므로(`W02_E_…`) 절과 파일이 눈으로 짝지어진다
  → `simulink-gnc-models/references/model-layout.md`

---

## 2-6. 그림 안의 수식은 조판한다 — `tex2svg.sh`

`e_x` · `X_cmd` 처럼 평문으로 쓰면 본문 수식과 글꼴이 달라 그림만 떠 보인다.
유니코드 아래첨자로 흉내내면 없는 글자를 만나 **틀린다** (→ `standing-orders.md` §5-2).

**PDF 파이프라인이 쓰는 것과 같은 MathJax 번들로 조판해서 path 를 그대로 심는다.**

```bash
bash _tools/tex2svg.sh -s 18 -x 40 -y 120 'y_e = \Delta\tan\beta_c'
bash _tools/tex2svg.sh -p _tools/labels/w02-windup.txt      # 배치목록 통째로
```

배치목록은 한 줄에 하나, `x | y | 크기 | 정렬 | 색 | TeX` 이다.
**TeX 을 셸 인자로 넘기지 않는 것이 요점**이다 — `\hat\beta` 가 `hateta` 로,
`\top` 이 탭으로 바뀐 적이 각각 한 번씩 있다. 목록을 파일로 두면 셸을 통과하지 않는다.

## 2-7. 블록선도가 "어설퍼" 보이는 이유는 내용이 아니라 형식이다

사용자 지적: **"antiwindup 다이어그램이나 다른 다이어그램도 약간 어설픈데
논문처럼 그릴 수 없나"**. 이 PC 에는 TikZ·Graphviz·LaTeX 이 **없다**(확인함).
설치는 사용자에게 물을 일이고, 그 전에 형식만 고쳐도 대부분 해결된다.

저널 그림과 나란히 놓고 보면 차이가 넷으로 좁혀진다.

| 어설픈 그림 | 저널 그림 |
|---|---|
| 선 굵기가 요소마다 다르다 | **신호선 하나, 블록 테두리 하나** — 둘뿐 |
| 화살촉이 크고 둥글다 | 작고 뾰족한 삼각형 **하나로 통일** |
| 상자가 알록달록하고 모서리가 둥글다 | **흰 바탕, 직각, 검은 테두리** |
| 색을 장식으로 쓴다 | 색은 **강조 하나**에만. 나머지는 흑백 |
| 설명을 그림 안에 넣는다 | 그림 안은 최소, 설명은 **아래 캡션** |

`_tools/bdiag.sh` 가 이 규약을 도형으로 굳혀 놓았다 — `bd_blk`·`bd_sum`·`bd_sig`·
`bd_wire`·`bd_dot`·`bd_sigA`(강조). 새 블록선도는 이것으로 그린다.

실례: `figures/w02-windup.svg` 를 `_tools/w02_windup_fig.sh` 로 다시 그렸다.
내용은 그대로인데 형식만 바꿔도 논문 그림에 가까워진다.

## 2-8. 새 블록선도·도표는 TikZ 로 그린다

2026-09-05, 사용자 승인으로 **TinyTeX 을 설치했다**(`%APPDATA%\TinyTeX`,
TeX Live 2026 + `pgf` + `standalone` + `dvisvgm`). 그림 전용이며,
**문서 PDF 파이프라인은 그대로 Chrome + MathJax 다.**

```bash
bash _tools/tikz2svg.sh figures/src/w02-windup.tex figures/w02-windup.svg
```

- 원본은 `figures/src/*.tex`, 스타일은 `figures/src/gnc-style.tex` 하나를 공유한다.
  선 굵기·화살촉·상자 모양을 그림마다 다시 정하지 않는 것이 요점이다
- 경로는 **`latex` → DVI → `dvisvgm --no-fonts`**. `pdflatex` 가 아니다 —
  DVI 를 거쳐야 선과 글자가 전부 벡터 path 로 나온다
- `tikz2svg.sh` 이 pt → px 로 바꾸고 흰 배경을 깔아 준다. `vault_check` §12 가
  흰 배경을 요구하기 때문이다

### TikZ 로 옮기면서 밟은 지뢰 넷

| 증상 | 원인 | 고침 |
|---|---|---|
| `\def\Y0{...}` 이 조용히 틀린다 | **TeX 제어어에 숫자를 못 쓴다.** `\Y` 에 인자 `0` 을 붙인 꼴이 된다 | 매크로 이름은 글자만 — `\Yzero` |
| `Dimension too large` | pgfmath 는 고정소수라 $10^6$ 에서 넘친다 | 로그 공간에서 계산한다. $\log(10^a+10^b) = \max(a,b) + \log(1+10^{-\lvert a-b\rvert})$ |
| `Missing number` | `\PY{...}` 가 이미 `{}` 를 붙이는데 인자에도 `{}` 가 있어 이중이 됐다 | 헬퍼 매크로는 바깥 중괄호를 붙이지 않는다 |
| `(\XW-1, y)` 가 안 먹는다 | TikZ 좌표에서 산술은 `{}` 안에서만 된다 | `({\XW-1}, y)` |

> [!caution] `.tex` 원본에 `perl -pi -e` 를 쓰지 않는다
> `.md` 의 LaTeX 과 같은 이유다(→ `standing-orders.md` §5-1). 이번에도 `\XW` 가
> `XW` 로, `\hat\beta` 가 `hateta` 로, `\top` 이 탭으로 바뀌었다. **Edit 도구로 고친다.**

## 2-9. 스무 장을 다 옮기고 나서

2026-09-05, `figures/*.svg` **20장 전부**가 `figures/src/*.tex` 를 원본으로 갖게 되었다.
손으로 쓴 SVG 는 이제 이 볼트에 없다. 옮기면서 나온 것들을 남긴다.

### 옮기는 김에 잡은 진짜 오류

- **`w01-pqr.svg` 의 roll 과 yaw 호가 반대로 그려져 있었다.** 그림이 예쁘게 나와도
  틀린 것은 틀린 것이다. 화살표 방향은 "그럴듯한 쪽"이 아니라 **계산해서** 정한다.
  화면 기저를 오른쪽 $R$, 위 $U$, 화면 밖 $O$ ($R\times U = O$) 로 두고 축을 푼다:

  | 칸 | 관측 방향 | 축 | 오른손 법칙이 화면에서 뜻하는 것 |
  |---|---|---|---|
  | $p$ | 선미에서 앞을 봄 | $x_b = -O$ (화면 안쪽) | $y_b \to z_b$ 곧 $R \to -U$ — **시계방향** |
  | $q$ | 우현에서 봄 | $y_b = +O$ (화면 밖) | **반시계방향**, 선수(오른쪽)가 올라간다 |
  | $r$ | 위에서 봄 | $z_b = -O$ (화면 안쪽) | **시계방향**, 선수가 우현으로 |

  TikZ 에서는 `arc(a:b:...)` 의 **`b < a` 이면 시계방향**이다. 이것을 `.tex` 머리말에
  적어 두면 다음 사람이 다시 확인할 수 있다.
- **`w01-otter-layout.svg` 의 모멘트 팔 두 개가 둘 다 `+0.395` 로 나왔다.**
  `\foreach \s/\sgn in {-1/{-}, 1/{+}}` 의 두 번째 인자가 먹지 않았다.
  **부호가 갈리는 라벨은 `\foreach` 로 돌리지 말고 두 줄로 쓴다.**
  값 자체는 `otter_B('base')` 를 돌려 `max|diff| = 0`으로 대조했다.

### 새로 밟은 지뢰 셋

| 증상 | 원인 | 고침 |
|---|---|---|
| `\node[ablk]` 상자가 통째로 보라색으로 칠해진다 | 스타일 끝에 색 이름만 두면 TikZ 가 `color=` 로 읽는다. `color` 는 `draw` 와 **`fill` 을 함께** 바꾸므로 앞의 `fill=white` 를 덮는다 | 글자색은 **`text=accent`** 로 쓴다 |
| tabular 의 마지막 칸 마지막 줄이 다음 문단 위로 올라탄다 | `\parbox[t]` 는 깊이가 제대로 안 잡힌다 | 높이를 못 박는다 — `\parbox[t][15mm][t]{44mm}{...}` |
| 3차원 그림에서 회전호가 축 화살촉을 삼킨다 | 축마다 **사영된 길이가 다르다.** `w01-euler` 의 $y_1$ 은 화면에서 $x_1$ 의 절반이다 | 호를 축 끝에서 얼마나 밀지를 3차원 거리가 아니라 **화면 거리**로 계산한다 → `_tools/w01_euler_R.m` |

> [!caution] Bash 도구의 heredoc 은 `.sh` 안의 역슬래시도 먹는다
> `.md` · `.tex` 만의 문제가 아니었다. `cat > x.sh <<'EOF'` 로 쓴
> `${WIN_SVG//\\//}` 가 파일에는 `${WIN_SVG//\//}` 로 들어가서 Chrome 이
> 파일을 못 찾았다. **역슬래시가 들어가는 줄은 Write · Edit 도구로 쓴다.**

### 확대해서 보는 도구

1:1 렌더만으로는 작은 라벨이 겹쳤는지 안 보인다. 잘라서 확대하는 판을 따로 두었다.

```bash
bash _tools/svgzoom.sh figures/w01-pqr.svg 3 out.png  0 55 250 210
#                      파일               배율 나갈곳  x  y   w   h   (원본 픽셀)
```

- Chrome 이 `Missing headless user data directory` 로 죽으면 `--user-data-dir` 을 준다.
- 임시 HTML 은 **출력 파일 옆**에 만든다. `/tmp` 는 Git Bash 와 Chrome 이 서로 다른
  곳으로 해석해서 Chrome 이 못 찾는 일이 있었다.

### 그림은 **PDF 에 실릴 크기로** 다시 본다

1:1 렌더에서 멀쩡하던 글자가 PDF 에서는 작아진다. `pdf-template.html` 이
`@page { size: A4; margin: 13mm 12mm }` 에 `img { max-width: 100% }` 이므로
본문 폭은 **186 mm = 703 px** 이고, 그보다 넓은 SVG 는 **줄어든 채로 인쇄된다.**

```bash
W=$(grep -oE 'width="[0-9.]+"' figures/w01-euler.svg | head -1 | grep -oE '[0-9.]+')
Z=$(awk -v w=$W 'BEGIN{printf "%.3f", 703/w}')      # PDF 에서의 실제 배율
bash _tools/svgzoom.sh figures/w01-euler.svg $Z out.png
```

- 이 볼트에서 줄어드는 그림: `w04-los-geometry`(78 %) · `w01-otter-layout`(83 %) ·
  `w01-euler`(84 %) · `w04-three-laws`(90 %) 등 여덟 장.
- **그래서 그림 안의 최소 글자는 `\scriptsize` 다. `\tiny` 를 쓰지 않는다.**
  `w01-euler` 의 축 이름표가 `\tiny` (5 pt) 였고, 84 % 로 줄면 **4.2 pt** 라
  인쇄본에서 읽히지 않았다. `\scriptsize` 로 올려 5.8 pt 가 되었다.
- 폭 703 px 안에 들어오면 1:1 로 인쇄되니, 새 그림은 되도록 그 안에서 잡는다.

### 3차원 그림의 기하는 MATLAB 이 계산하고 TikZ 가 사영한다

`w01-euler` 가 지금의 본보기다.

```matlab
w01_euler_R      % figures/src/w01-euler-R.tex 를 쓴다 (\def 로 된 좌표 40개)
```

- 회전행렬을 곱하는 것은 MATLAB, **사영은 TikZ 의 `x/y/z` 기저**가 한다.
  좌표를 3차원으로 주면 타원 중심이 축선 위에 오는 것이 저절로 보장된다.
- 생성기가 **직교성 · $\det = +1$ · MSS `Rzyx.m` 대조**를 찍는다.
  이번 결과 `max|dR| = 0.000e+00` — 유도한 순서가 정본과 같다는 증거다.
- 생성한 `.tex` 는 **손으로 고치지 않는다.** 머리말에 그렇게 적어 둔다.
