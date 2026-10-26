# 모델을 코드로 만들기

## 한 파일의 골격

```matlab
function build_w07_models()
    here = fileparts(mfilename('fullpath'));  cd(here);
    if evalin('base','~exist(''wp_north'',''var'')')
        error('먼저 W08_setup 을 실행하십시오.');
    end
    build_offline();
    build_vrx();

    slxList = dir('*.slx');
    for k = 1:numel(slxList)
        [~, mName] = fileparts(slxList(k).name);
        try, tidy_layout(mName); tidy_layout(mName); catch, end
    end
    fprintf('\n완료.\n');
end
```

## 공통 헬퍼 — 그대로 복사해 쓴다

```matlab
function fresh(m)
    if bdIsLoaded(m), close_system(m, 0); end
    if isfile([m '.slx']), delete([m '.slx']); end
    new_system(m); load_system(m);
end

function setFcn(sys, path, code)          % MATLAB Function 블록 본문 채우기
    add_block('simulink/User-Defined Functions/MATLAB Function', [sys '/' path]);
    S = sfroot; B = S.find('Path', [sys '/' path], '-isa','Stateflow.EMChart');
    B.Script = code;
end

function C(m, name, value, x, y)          % Constant
    add_block('simulink/Sources/Constant', [m '/' name], ...
              'Value', value, 'Position', [x y x+95 y+30]);
end

function F(m, tag, sfx, x, y)             % From
function G(m, tag, x, y)                  % Goto
function note(m, tag, txt, x, y)          % 주석
```

- **From/Goto 이름은 `Fr_<tag>_<접미사>` / `Go_<tag>`** 로 통일한다. 이름이 겹치면 `add_line` 이 조용히 엉뚱한 데 붙는다

## Stateflow 를 코드로

```matlab
ch = Stateflow.Chart(machine);
ch.ActionLanguage = 'MATLAB';
ch.ChartUpdate    = 'DISCRETE';
ch.SampleTime     = 'Ts_ctrl';

s = Stateflow.State(ch);  s.LabelString = sprintf('WpFollow\nen: mode = 1;');
t = Stateflow.Transition(ch);  t.Source = s1;  t.Destination = s2;
t.LabelString = '[at_loiter > 0.5]';

d = Stateflow.Data(ch);  d.Name = 'mode';  d.Scope = 'Output';
```

- **기본 전이**는 `Source` 를 비우고 `Destination` 만 준다
- 상태·전이의 좌표(`Position`, `MidPoint`)를 반드시 지정한다. 안 하면 전부 원점에 겹친다

## 자주 걸리는 것

| 증상 | 원인 | 해법 |
|---|---|---|
| `Algebraic loop` 오류 | 모드 신호가 자기 자신으로 되먹임 | 경로에 **Unit Delay 1개** |
| 로이터 중 웨이포인트 인덱스가 전진 | 인덱스 갱신에 모드 조건이 없음 | `if (mode < 1.5) && reached && (k < n-1)` |
| 로이터 중심이 따라 움직임 | 중심을 매 스텝 계산 | 진입 시점 값을 상수로 고정 |
| `To Workspace` 데이터가 `[2×1×N]` | 벡터 신호 | `squeeze(out.log_x.Data)'` |
| MATLAB Function 안에서 그림이 안 그려짐 | 코드 생성 대상 | `coder.extrinsic('plot', ...)` |
| 제목의 한글이 네모로 나옴 | `'FontName','Consolas'` | FontName 을 지정하지 않는다 |
| 실제보다 배가 느리게 감 | 페이싱 ≠ RTF | `PacingRate` 를 **실측 RTF** 와 같게 |

## 실시간 애니메이션을 모델 안에 넣기

- MATLAB Function 블록 + `coder.extrinsic`, 지속 변수(`persistent`)에 figure 핸들 보관
- 선수는 **삼각형**, 선미는 **사각형** — 방향이 한눈에 보인다
- 제어 루프와 분리해 `en` 입력으로 켜고 끈다. 끄면 시뮬레이션이 빨라진다

---

## 모델 안에서 그리는 "대시보드" — W01 에서 만든 것

> 사용자 지시 2026-09-08: **"가장 왼쪽에 North-East 선박 궤적과 (선박의 heading 이
> 표시될 수 있도록 선박 모양도), 그리고 u, v, r, x, y, psi (wrap to pi to pi 해주고)
> 단위도 적고 ... 시뮬링크 안에 matlab 함수를 통해서 그렸으면 좋겠어"**

궤적 하나만 그리는 `live_track` 으로는 "지금 배가 무엇을 하고 있는가" 의 절반밖에
안 보인다. `_tools/live_dash.m` 이 **한 창에 궤적 + 상태 여섯**을 그린다.

```matlab
add_measurement(m, P.measurement, 'W01', {'n'}, ...
                struct('dash', true, 'weekName', 'input  n  (rad per s)'));
```

- `.dash = true` 면 Animate 블록이 `(u,v,r,N,E,psi,t,en)` 여덟 입력을 받는다.
  주차별 `WXX_animate.m` 래퍼도 같은 날 함께 넓혀야 하므로 **기본값이 아니라 플래그**다.
- 각도 변환은 래퍼가 아니라 `live_dash` **한 곳**에서 한다. psi 는 rad 로 받아
  `mod(psi_deg+180,360)-180` 으로 감고, r 은 rad/s 로 받아 deg/s 로 바꾼다.
- 스코프는 **입력 하나, 속도 하나**로 둘이면 충분하다. 위치·자세는 대시보드에 있으므로
  세 번째 스코프는 같은 것을 두 번 보여줄 뿐이다.

### 이때 밟은 지뢰 셋

| 증상 | 원인 | 고침 |
|---|---|---|
| `이름이 '…/input  n  [rad/s]'인 새 블록은 추가할 수 없음` | **Simulink 블록 이름에 `/` 를 못 쓴다.** 경로 구분자다 | 단위를 풀어 쓴다 — `(rad per s)` |
| To Workspace 결과가 `[8 1 nT]` 3차원으로 나온다 | MATLAB Function 의 `n = [nL; nR]` 는 2×1 **행렬** 신호다. Mux 입력 하나가 행렬이면 **출력 전체가 행렬**이 되고 로그가 `[nT x 8]` 이 아니게 된다 | 그 신호에 **Reshape(`1-D array`)** 를 하나 물린다. 로깅 계약이 2차원인 이유가 이것이다 |
| `유효하지 않은 표현식입니다` | `...` 줄바꿈 **다음 줄에 주석**을 넣었다 | 주석은 호출문 **위**로 뺀다 |

### 로깅 계약을 늘릴 때

`[u v r N E psi | …]` 뒤에 붙이는 순서가 곧 열 번호다. 같은 주차의 모델 둘이
서로 다른 순서로 붙이면 `WXX_read.m` 이 어느 모델이 만든 로그인지 알아야 하게 된다.
**W01 은 두 모델 모두 7·8 열을 `n` 으로 맞췄다** — 그래서 리더가 모델을 몰라도 된다.

---

## 캔버스에 수식을 조판한다 (2026-10-27)

사용자 지시: "시뮬링크에 MATHTYPE이나 LATEX로 수식도 넣어줘 해당 부분 강의 자료에
있는 내용을 참조해서". 학생이 모델을 열면 그 절의 식이 **블록 옆에** 있어야 한다.

### 되는 것과 안 되는 것 — 실험으로 확인했다

`set(a,'Interpreter')` 가 돌려주는 값은 넷뿐이다: `'off'` · `'tex'` · `'rich'` · `'mathml'`.

| 쓰려던 것 | 결과 |
|---|---|
| `$$ ... $$` 로 감싼 LaTeX | **글자 그대로 찍힌다.** `TeXMode='on'` 을 켜도 같다 |
| `Interpreter = 'mathml'` | 본문을 `<math>…</math>` 로 감싼 글자가 그대로 보인다 (진짜 MathML 이 필요하다) |
| `\begin{bmatrix}` | **지원하지 않는다** |
| **`Interpreter = 'tex'` + 달러 기호 없는 MATLAB TeX 마크업** | **이것이 된다** |

렌더를 눈으로 확인한 마크업: `\tau \nu \psi \pi`, `^{-1}`, `^T`, `_{p,pos}`,
`_{B,max}`, `\leftarrow`, `\rightarrow`, `\surd`, `\times`, `\leq`, `\neq`.
여러 줄은 `strjoin(L, newline)` 으로 만들고 **줄마다 따로** 해석된다.

```matlab
b = Simulink.Annotation([m '/equations']);
b.Text = strjoin(E, newline);
b.Interpreter = 'tex';
b.FontName = 'Consolas';
b.FontSize = 13;
b.HorizontalAlignment = 'left';
b.Position = [40 1700 1300 1700 + 30 + 22*numel(E)];   % 글자 높이 약 22 px
b.BackgroundColor = 'lightBlue';
```

### 행렬은 `|` 로 손으로 그린다 — 그리고 **앞머리가 같아야** 선다

고정폭 글꼴을 줘도 열이 서지 않는다. TeX 해석기가 아래첨자·그리스 글자
(`y_p`, `l_f`, `T_L`, `F_B`, `\psi`) 를 **고정폭 칸보다 좁게** 짠다.

> [!important] 같은 좁아짐이 **이름표**에도 걸린다
> `   p_{app} = ` 나 `     R(\psi) = ` 는 같은 길이의 공백보다 좁게 짜인다.
> 그래서 **이름표를 행렬 첫 줄에 붙이면** 다음 줄이 다른 x 에서 시작해 행렬이 어긋난다.
> 이름표는 **제 줄에 따로** 두고, 행렬의 모든 줄은 **공백만으로** 들여쓴다.

| 틀린 것 | 옳은 것 |
|---|---|
| `'   p_{app} = \| N_b     \|'` + `'             \| E_b + s \|'` | `'   approach  p_{app}'` 다음에 `'     \| N_b     \|'` · `'     \| E_b + s \|'` |
| 행렬 속을 `\| y_p  -y_p  l_f \|` 로 | 숫자로 — `\| 0.395 -0.395 1.5 \|`, 기호 뜻은 **아래 산문**에 |
| 행렬 둘째 줄 끝에 `= R(\psi)^T p_e` 를 붙임 | 그 식을 **행렬 위 도입 줄**로 올린다 |

행렬 한 칸의 **글자 수**도 줄마다 같아야 한다 (`\psi` 는 한 글자로 센다).

### 밑줄 있는 평범한 낱말은 먹힌다

`bow_on` 이 "bow" + 아래첨자 `o` + "n" 으로 찍혔다. **`bow\_on` 으로 escape 한다.**

### 산문 메모와 수식 메모는 **주석 블록 둘**이다

`'tex'` 주석은 평범한 글 덩어리를 함께 들 수 없다. `note(m,o)` 가 산문 상자를 만들고
그 끝에서 `equations(m,o)` 가 수식 상자를 따로 만든다.

### 저장된 모델에서 다시 꺼낼 때

```matlab
h = find_system(mdl,'FindAll','on','SearchDepth',1,'Type','annotation');
for k = 1:numel(h)
    if strcmp(get(h(k),'Interpreter'),'tex'), txt = get(h(k),'Text'); end
end
```

`'Name','equations'` 로는 **걸리지 않는다.** `Interpreter` 로 고른다.
그리고 `strsplit` 은 기본값이 **연속 구분자를 합치므로** 빈 줄이 든 글의 줄 수를
`numel(strsplit(txt,newline))` 으로 세면 모자라게 나온다 — 빌더에서는 `numel(E)` 를 쓴다.

### 끝내는 법

속성 대입이 성공한 것은 **확인이 아니다.** 임시 모델에 그 글을 붙여
`print(['-s' sh],'-dpng','-r90', ...)` 로 PNG 를 뽑고 **눈으로 본다.**
고친 뒤에도 다시 뽑아 본다 (CLAUDE.md §4-6).
