# 사람이 조작하는 모델 — 버튼 · 슬라이더 · 조종기 · USB 장치

W01 §F (`W01_interactive.slx`), §G (`W01_rc.slx`), §H (`W01_rc_usb.slx`) 를 만들며 확인한
것이다. 모두 R2024b 에서 **실제로 돌려서** 확인했다. 새 주차에 같은 것을 만들 때 그대로 따른다.
발견 경위와 사용자 원문은 `gnc-lecture-vault/references/standing-orders.md` §8-4 에 있다.

---

## 1. 스크립트 없이 도는 모델

| 할 일 | 방법 |
|---|---|
| 변수 | **모델 작업공간**에 넣는다: `assignin(get_param(m,'ModelWorkspace'), name, value)`. 모델과 함께 저장된다 |
| 경로 | `PostLoadFcn` 이 `get_param(bdroot,'FileName')` 에서 폴더를 얻어 `_tools` 를 얹고 `mss_path()` |
| 실시간 | `EnablePacing on`, `PacingRate 1`, `StopTime inf` |
| 실행 중 변경 | **`BlockReduction off`**. 켜 두면 Terminator 로만 가는 Constant 가 최적화로 사라져 `set_param` 이 "시뮬레이션 중에는 변경할 수 없다" 로 거부된다 |
| MATLAB Function 의 상수 | 입력 포트 대신 **Parameter** 로 둔다 — `find(sfroot,'-isa','Stateflow.EMChart','Path',blk)` 에서 `Stateflow.Data` 를 찾아 `Scope='Parameter'`. 값은 모델 작업공간의 같은 이름에서 온다. 선이 늘지 않는다 |

## 2. 캔버스 위의 조작 장치

| 장치 | 블록 | 주의 |
|---|---|---|
| 묶기 | `_tools/hmi_bind.m` — `Simulink.HMI.ParamSourceInfo` 에 `BlockPath` · `ParamName` | 저장 후 유지. **`set_param` 으로 Constant 를 바꾸면 묶인 슬라이더도 따라 움직인다** — 정지 중에도 실행 중에도 |
| 라디오 버튼 | `simulink_hmi_blocks/Radio Button`. `States = struct('Value',…,'Label',…)`, 캡션은 `ButtonGroupName` | 경로는 `simulink/Dashboard/…` 가 아니다 — 그것은 라이브러리를 여는 껍데기다 |
| 가로 슬라이더 | `simulink_hmi_blocks/Slider`. `Limits = [최소 눈금 최대]`, 눈금 −1 은 자동 | — |
| 조종기 스틱 | `simulink_hmi_customizable_blocks/Vertical Slider` · `Horizontal Slider`. 어두운 베젤에 빨간 손잡이 | **범위를 코드로 바꿀 수 없다** (`ScaleMin`·`Limits` 는 받고 저장 뒤 비어 있다). 0–100 그대로 두고 모델 안에서 정규화한다 — 수신기 펄스 1000–2000 µs 와 같은 구조 |
| 버튼 | `_tools/image_button.m` — 둥근 버튼 PNG 를 **그림 주석**에 넣고 `ClickFcn` | Dashboard Callback Button 은 코드로 준 `ClickFcn`·글자가 저장 뒤 사라진다. 글자 주석은 `ClickFcn` 이 있으면 배경색이 저장되지 않는다 |
| 장치 몸체 | 그림 주석을 **먼저** 놓고 Dashboard 블록을 그 위에 얹는다 (주석은 블록 뒤에 그려진다). 글자는 그림 안에 그린다 | 영역(area) 주석의 배경색도 저장 뒤 흰색으로 돌아간다 |

- `mss_style(m)` 은 모든 블록 크기를 바꾸므로 Dashboard 블록은 **그 뒤에** 넣는다.
- 캔버스 폭이 넓어지면 블록도 PNG 가 2000 px 를 넘는다 (vault_check §7). 안내문은 옆이 아니라 **아래**에 둔다.

## 3. 실시간 화면

| 할 일 | 방법 |
|---|---|
| 조작한 값 | **반드시 그린다.** 화면에 없으면 사용자는 "슬라이더가 안 먹는다" 고 본다 (실제로 그랬다) |
| 상태 외의 신호 | 최상위의 탭 블록(MATLAB Function, `coder.extrinsic('setappdata')`)이 매 스텝 맡기고, `<tag>_animate` 가 `getappdata` 로 꺼낸다 |
| t = 0 의 옛 값 | `StartFcn` 이 `rmappdata` 로 지운다. 없으면 NaN — 그 점은 그려지지 않는다 |
| 두 모델이 한 화면 | `StartFcn` 이 `setappdata(0,'<tag>_model',bdroot)`. 화면이 그 모델 작업공간에서 한계값을 읽는다 |
| 창 두 개 | START 가 모델을 화면 왼쪽 절반, 화면 함수가 그래프를 오른쪽 절반에 둔다. 겹치면 버튼을 누를 때마다 그래프가 가려진다 |
| 처음부터 다시 | START 가 stop → 완전히 멈출 때까지 대기 → start. 궤적과 그래프가 초기화된다 |

## 4. 실물 USB 장치 (조종기 · 게임패드)

| 할 일 | 방법 |
|---|---|
| 블록 | Simulink 3D Animation `vrlib/Joystick Input` (`joyid`). 출력: 축 벡터, 버튼. Aerospace Blockset 의 pilot 라이브러리는 **조종사 동특성 모델**뿐이고 장치 블록이 아니다 |
| 장치 확인 | `j = vrjoystick(id); caps(j); read(j)` — 없으면 "Joystick is not connected" |
| 모델 생성 | 장치 없이 된다. 컴파일(실행)만 장치를 요구한다 |
| 축의 의미 | 조종기는 USB 로 **채널**(AETR 등)을 보낸다. 모드는 조종기 안에서 적용되므로 모델에 모드 스위치를 두지 않는다 |
| 축 번호 · 방향 | 가정하지 않는다. **"움직여 보라" 고 한 뒤 무엇이 움직였는지 본다** (`W01rc_usb_axis`: 가장 크게 변한 축과 부호, 전체 폭의 1/4 미만이면 거부) |
| START | 먼저 `vrjoystick` 으로 열어 본다. 없으면 창으로 알리고 시작하지 않는다. 스로틀이 중립이 아니면 시작하지 않는다 (throttle check) |

### 장치 없이 검증하는 법

장치에서 모델로 들어오는 것은 장치 블록의 출력 하나뿐이다. **그 블록만 같은 모양의 Constant 로
바꾼 임시 사본**을 만들어 돌린다 (`W01_H_usb_check.m`):

```matlab
save_system(m0, fullfile(tempdir,'harness.slx'));      % 이름이 바뀐 사본. 원본은 그대로
lh = get_param(jb,'LineHandles');  delete_line(lh.Outport(lh.Outport > 0));
p  = get_param(jb,'Position');     delete_block(jb);
add_block('simulink/Sources/Constant', [tx '/fake axes'], 'Value','ax_test', 'Position', p);
```

축 순서·방향이 다른 가짜 장치 몇 개로 돌려, 화면 조종기 모델과 **자릿수까지 같은지** 본다.
장치를 읽는 부분만 미검증으로 남고, 문서에 **그렇게 적는다** — 출력을 지어내지 않고
판정 기준 표만 둔다.

## 5. 문서의 수

사람이 조작한 실행은 재현되지 않는다. **조작마다 한 번씩 돌리는 확인 스크립트**가 표를 만든다
(`W01_F_button_check`, `W01_G_rc_check`, `W01_H_usb_check`). Pacing 과 실시간 화면은 끄고
(`setModelParameter('EnablePacing','off')`, `setVariable('animate',0,'Workspace',m)`) 정지 상태에서
60 s 유지한 값을 싣는다.

> [!warning] 확인 스크립트에서 `clear` 를 그냥 쓰지 않는다
> MCP 로 돌리면 스크립트는 **기본 작업공간**에서 돈다. 맨 앞의 `clear` 가 기본 작업공간을 비워,
> 기본 작업공간 변수를 읽는 다른 모델(`W01_openloop`, `W01_current`)이 다음 실행에서
> "SampleTime 이 유효하지 않다" 로 멈췄다. 제 변수만 이름으로 지운다: `clear m cfg y …`.
> `vault_check` §17 과 PostToolUse 훅이 이것을 잡는다.
