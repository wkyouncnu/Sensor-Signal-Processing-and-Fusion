# 모델을 코드로 만들기

## 한 파일의 골격

```matlab
function build_w07_models()
    here = fileparts(mfilename('fullpath'));  cd(here);
    if evalin('base','~exist(''wp_north'',''var'')')
        error('먼저 W07_setup 을 실행하십시오.');
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
