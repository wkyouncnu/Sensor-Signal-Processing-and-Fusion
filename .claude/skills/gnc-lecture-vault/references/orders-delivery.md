# 상시 지침 · 설치 · 실습 · 배포

> [!note] 이 파일은 `standing-orders.md` 에서 주제별로 갈라져 나온 것이다
> 전체 색인과 § 번호 지도는 **`standing-orders.md`** 에 있다. 이 파일이 담는 것은 **§8** 다.
> § 번호는 **바꾸지 않았다** — 볼트 전체가 `standing-orders.md §N-M` 으로 가리키므로
> 번호가 곧 주소다. 새 절은 이 파일에 붙이고 **색인에 한 줄 더한다.**

---

## 8. 설치·실습 문서는 "명령 모음" 으로 끝내지 않는다

> 사용자 원문: **"모든 실행 명령 이후에 화면을 캡처해서 넣어줘봐 지금은 명령 모음만
> 있으니까 잘 설치가 되었을 때 어떤 결과가 있을지...알기가 어려워...그리고 설치
> 에러가 났을 경우 어떻게 대처하는지도 추가해줘"** (2026-09-06)

명령만 늘어놓은 문서는 **성공을 확인할 방법을 주지 않는다.** 학생은 명령을 붙여넣고
무언가가 흘러간 뒤에 그것이 맞게 된 것인지 알 수 없다. 명령 하나마다 셋을 붙인다.

| 붙이는 것 | 규칙 |
|---|---|
| **정상 출력** | **실제로 돌려서 받은 것**만 싣는다. 길면 앞뒤를 자르고 `…` 로 줄이되, **글자를 고치지 않는다** |
| **무엇을 보고 성공을 판정하나** | "이 한 줄이 보이면 된 것" 을 한 문장으로. 버전 번호·경로처럼 **기계가 확인할 수 있는 것**으로 |
| **틀어졌을 때** | 증상 → 원인 → 고침 세 칸. 실제로 겪은 것만 (`CLAUDE.md` §3 Troubleshooting 규칙과 같다) |

### 8-0. 실습 문제지·답안지도 **PDF 로 같이 낸다**

> 사용자 원문: **"숙제도 MD 파일만 있는데 PDF로도 변환해서 같은 폴더에 넣어줘"**
> (2026-09-08)

학생이 받는 것은 전부 PDF 가 함께 있어야 한다. 이름이 `README.md` 라도 **폴더 색인이
아니라 배포물**이면 예외가 없다.

```bash
bash _tools/md2pdf.sh lectures/W01_simulink/problems/README.md \
                      lectures/W01_simulink/solutions/README.md
```

`vault_check.sh` 의 `delivered()` 가 이것을 강제한다. 색인용 README 둘만 빼고
(`lectures/README.md`, `lectures/WXX_simulink/README.md`), `problems/` 와
`solutions/` 아래의 README 는 **PDF 쌍 검사와 문체 검사에 함께 걸린다.**

- 그러니 문제지 본문도 영어 정식 어조다. 1·2인칭을 쓰지 않는다 — "Check work at
  any time" 은 되고 "Check your work" 는 안 된다.
- 파일 이름을 `README` 로 두는 이유는 강의 `.md` 가 그 이름으로 링크하고 있고,
  폴더 이름(`problems/`, `solutions/`)이 이미 무엇인지 말해 주기 때문이다.
  대신 **첫 줄 H1 이 제목 노릇을 한다** — PDF 만 따로 받아도 무엇인지 보인다.

### 8-1. 출력을 지어내지 않는다

이것이 이 절의 핵심이다. 그럴듯한 터미널 출력을 상상해서 적는 것은 **틀린 문서를
만드는 가장 빠른 길**이다. 버전 번호 한 자리가 다르면 학생은 자기 환경이 잘못된
줄 안다.

- 이 PC 에 **WSL2 + Ubuntu 22.04.5 + ROS 2 Humble + Gazebo Sim 7.9.0 + `~/vrx_ws`**
  가 실제로 있다. 실습 명령의 출력은 **거기서 받아 온다.**

  ```bash
  wsl -d Ubuntu-22.04 -- bash -lc '<명령>'
  ```
- 돌려 볼 수 없는 명령(설치처럼 상태를 바꾸는 것)은 **출력을 만들어 내지 말고**,
  "무엇을 보고 성공을 판정하나" 만 적는다.

### 8-2. GUI 화면은 캡처할 수 없다 — 그림으로 그린다

에이전트는 사용자의 바탕화면·설치 마법사·VS Code 창·Gazebo 창을 **캡처하지 못한다.**
캡처한 척하지 않는다. 대신 둘 중 하나를 쓴다.

| 대상 | 어떻게 |
|---|---|
| 터미널 | **verbatim 출력 상자.** 논문에서는 스크린샷보다 이쪽이 표준이고, 인쇄본에서 훨씬 잘 읽힌다 |
| 설치 마법사 · IDE 창 · 시뮬레이터 창 | **TikZ 개략도.** 어디를 눌러야 하는지 화살표로 짚는다. "스크린샷" 이라고 부르지 않는다 |
| 공개 웹페이지(다운로드 쪽 등) | 브라우저로 **진짜 캡처**할 수 있다 |

사용자가 실물 스크린샷을 원하면 **사용자가 찍어서 넣는다.** 문서에는 파일 이름과
자리를 미리 비워 두고, 무엇을 찍어야 하는지 한 줄로 적어 둔다.

---

### 8-4. 스크립트 없이 도는 모델 — 버튼으로 모는 예제 (2026-09-11)

> 사용자 원문: **"실시간 궤적과 3 자유도 플랏을 유지 하면서 real-time 으로 set pace 넣어서
> 천천히 실행시키고... 버튼으로 직진 후진 좌회전 우회전... 시뮬링크만 돌릴 수 있는 것"**

`W01_interactive.slx` (`W01_F_build_interactive.m`) 가 첫 예다. 다른 주차에 같은 것을
만들 때 그대로 따른다.

| 요구 | 방법 | 확인한 것 |
|---|---|---|
| 스크립트 없이 Run | 변수를 **모델 작업공간**에 넣고(`assignin(get_param(m,'ModelWorkspace'),…)`) 모델과 함께 저장 | `Simulink.findVars` 가 전부 `model workspace` 로 해석 |
| 탐색기에서 열어도 경로 | `PostLoadFcn` 이 `get_param(bdroot,'FileName')` 에서 폴더를 얻어 `_tools` 를 얹고 `mss_path` | `_tools` 를 `rmpath` 한 뒤 `load_system` → 되살아남 |
| 버튼 | `simulink_hmi_blocks/Radio Button`. `States` 에 `struct('Value',…,'Label',…)`, 캡션은 `ButtonGroupName` | Constant `mode` 에 묶임, 저장 후 다시 열어도 유지 |
| 슬라이더 | `simulink_hmi_blocks/Slider`. `Limits` 는 `[최소 눈금 최대]`, 눈금 `-1` 은 자동 | — |
| 묶기 | `Simulink.HMI.ParamSourceInfo` 에 `BlockPath` · `ParamName='Value'` 를 넣어 `set_param(dash,'Binding',b)` | — |
| 실시간 | `EnablePacing on`, `PacingRate 1`, `StopTime inf` | — |
| 처음부터 다시 | 캔버스의 **클릭 주석** START(`Simulink.Annotation` 의 `ClickFcn`)가 `W01i_control('start')` 를 부른다 — 돌고 있으면 stop, 완전히 멈출 때까지 기다린 뒤 start. Dashboard 의 Callback Button 은 코드로 넣은 `ClickFcn` 과 글자가 저장 뒤 사라져서 쓰지 않는다(R2024b 확인). 버튼 모양은 **그림 주석**으로 만든다 — 둥근 버튼 PNG 를 `setImage` 로 넣고 `ClickFcn` 을 준다. 그림은 모델 안에 저장된다. 글자 주석은 클릭 콜백이 있으면 배경색이 저장되지 않아(이름 색도 RGB 도) 파란 링크 글씨로만 보인다. Stop 뒤 시작은 t = 0, x0 에서 다시 하므로 배·궤적·그래프가 초기화된다 | 사용자 요청 "중지하고 다시 하면 시작 위치가 초기화" |
| 창 두 개 | 버튼은 모델 창, 그래프는 따로 뜬 figure 다. **겹치면 버튼을 누를 때마다 모델 창이 앞으로 나와 그래프를 가린다.** 사용자는 이것을 "Run 이 안 눌리고 그래프도 안 뜬다" 로 보고했다 — 실제로는 돌고 있었다. START 가 모델을 화면 왼쪽 절반, `W01i_animate` 가 그래프를 오른쪽 절반에 둔다 | 2026-09-11 |
| 조작하는 값은 그린다 | 사용자가 "슬라이더를 움직여도 안 바뀐다" 고 했다. 실제로는 바뀌었다 — 실행 중 `n0` 를 30 으로 바꾸자 다음 스텝부터 로그의 n 이 [30 30] 이었다. **화면에 n 이 없었고**, TURN 은 선회 버튼일 때만 작용하기 때문에 안 보였을 뿐이다. 조작 가능한 입력은 반드시 실시간 화면에 그린다 — `n to live view` 블록이 n 을 넘기고 `W01i_animate` 가 맨 아래 칸에 그린다 | 2026-09-11 |
| 궤적 창 | 경로를 미리 모르므로 창이 배를 **따라가게** 한다 (`W01i_animate.m`). 크기는 고정 — 축척이 바뀌면 선체 그림으로 속도를 가늠할 수 없다 | — |
| 문서의 수 | 사람이 누른 실행은 재현되지 않는다. **버튼마다 한 번씩 돌리는 확인 스크립트**(`W01_F_button_check.m`)가 표를 만든다 | AHEAD 1.0286 = §1-11, ASTERN −0.5983 = $k_{neg}$ 예측 |

**RC 조종기 모델 `W01_rc.slx` (`W01_G_build_rc.m`, 2026-09-11) 에서 확인한 것**

| 요구 | 방법 | 확인한 것 |
|---|---|---|
| 조종기 스틱 모양 | `simulink_hmi_customizable_blocks/Vertical Slider` · `Horizontal Slider`. 어두운 베젤에 빨간 손잡이라 조종기처럼 보인다 | Binding 은 저장 후 유지 |
| 스틱 범위 | Customizable 슬라이더의 범위는 **코드로 바꿀 수 없다** (`ScaleMin`·`Limits` 는 에러 없이 받고 저장 뒤 비어 있다). 0~100 그대로 두고 모델 안 `receiver` 가 −1~+1 로 바꾼다 — 수신기 펄스 1000~2000 µs 와 같은 구조라 오히려 가르치기 좋다 | — |
| 조종기 몸체 | **그림 주석**을 먼저 놓고 슬라이더를 그 위에 얹는다. 주석은 블록 뒤에 그려진다. 영역(area) 주석과 글자 주석의 배경색은 저장 뒤 흰색으로 돌아가므로 쓰지 않는다. 채널 이름·모드별 역할은 **그림 안에** 그린다 (블록 이름은 검은 글씨라 어두운 몸체에서 안 읽힌다) | 렌더해서 확인 |
| 실행 중 변경 | `BlockReduction off`. 켜 두면 Terminator 로만 가는 Constant 가 최적화로 사라져 `set_param` 이 "시뮬레이션 중에는 변경할 수 없다" 로 거부된다 | 끈 뒤 실행 중 50→20, 슬라이더도 따라 움직임 |
| 스프링 | 슬라이더에는 스프링이 없다. `set_param` 으로 Constant 를 바꾸면 **묶인 슬라이더가 따라 움직인다** — CENTRE 버튼이 스로틀이 아닌 채널을 50 으로 되돌린다 | 정지·실행 중 둘 다 확인 |
| 모드 | Mode 1 스로틀 = `RY`, Mode 2 = `LY`, 러더는 두 모드 모두 `LX`. 모드 전환은 모델 안 `Mode 1 or 2` 블록 하나 | 같은 스틱의 두 모드 로그 차이 0 |
| 조종기 블록? | Aerospace Blockset 의 pilot 라이브러리는 **사람 조종사 동특성 모델**(Crossover/Precision/Tustin)뿐이고 화면 조종기는 없다. 실물 USB 조종기(HID)는 Simulink 3D Animation `vrlib/Joystick Input` 으로 읽을 수 있다 — 하드웨어 없이 검증하지 못했으므로 강의에 넣지 않았다 | 라이브러리 목록 |
| 공용 도구 | `_tools/hmi_bind.m` (묶기), `_tools/image_button.m` (그림 버튼). §F·§G 모델이 함께 쓴다 | — |
| 실물 조종기 (§H) | `W01_rc_usb.slx` = `W01_G_build_rc('usb')`. `vrlib/Joystick Input` → `USB receiver`. 조종기는 USB 로 **채널**(AETR 등)을 보낸다 — 모드는 조종기 안에서 적용되므로 모델에 MODE 스위치가 없다. 축 번호·방향은 조종기마다 달라 **CALIBRATE**(`W01_H_usb_setup`)가 "움직여 보라" 고 해서 찾는다 | 장치 없이 모델 생성 가능 (조이스틱 블록은 컴파일 때만 장치를 찾는다) |
| 장치 없이 검증 | 장치에서 오는 것은 축 벡터 하나뿐이다. **그 블록만 Constant 로 바꾼 임시 사본**을 돌린다 (`W01_H_usb_check`). 축 순서·방향이 다른 가짜 조종기로도 §G 경우 7 과 자릿수까지 같다. 장치를 읽는 부분만 미검증이며 **문서에 그렇게 적는다** — 출력을 지어내지 않고 판정 기준 표만 둔다 | 2026-09-11, 조종기 미연결 |
| 장치 없음 · 스로틀 | START 가 먼저 `vrjoystick` 으로 열어 본다. 없으면 창으로 알리고 시작하지 않는다(Simulink 오류 대신). 스로틀이 10 % 넘게 벗어나 있으면 시작하지 않는다 — 실물 조종기의 throttle check | 장치 없이 창 문구와 stopped 상태 확인 |
| 기계로 내린 것 | 확인 스크립트의 맨 `clear` 가 기본 작업공간을 비워 다른 모델이 멈췄다 → **`vault_check` §17** 과 **PostToolUse 훅** `_tools/hook_matlab_rules.sh` (Write · Edit 직후, 어기면 exit 2 로 되돌려 보낸다). `WXX_0_setup.m` 만 예외. 절차 문서는 `simulink-gnc-models/references/interactive-models.md` | 2026-09-11 |
| 모드 그림 | 사용자가 조종기 사진을 보여 주며 "이런 그림도… 너가 만들어서라도". 사진을 싣지 않고 **TikZ 로 다시 그렸다** — `figures/src/w01-rc-modes.tex`. 배에서 쓰는 두 기능만 accent, 나머지 회색 | 2026-09-11 |
| 모델 이름 공유 | 실시간 화면 하나(`W01rc_animate`)를 두 모델이 쓴다. `StartFcn` 이 `setappdata(0,'W01rc_model',bdroot)` 로 자기 이름을 맡기고, 화면이 그 모델 작업공간에서 한계값을 읽는다 | — |

- Dashboard 블록은 `simulink/Dashboard/...` 경로로는 **추가되지 않는다.** 그 이름은
  `open_system('simulink_hmi_blocks')` 를 부르는 껍데기다
- `mss_style` 은 모든 블록의 크기를 바꾸므로 Dashboard 블록은 **그 뒤에** 넣는다

