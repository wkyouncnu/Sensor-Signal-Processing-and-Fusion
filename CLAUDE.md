# GradCourse — 형식 계약

대학원 USV 유도·항법·제어 강의. 선체는 Fossen 의 **Otter**, 도구는 **Simulink 하나**,
근거는 **MSS** 와 **Fossen Handbook** 이다.

이 파일은 **형식의 원본**이다. `.claude/skills/gnc-lecture-vault/` 와 어긋나면 **이 파일이 이긴다.**
스킬은 "어떤 순서로 실행하는가", 이 파일은 "무엇이 옳은 모양인가" 를 담는다.

---

## 1. 언어

| 대상 | 언어 |
|---|---|
| `lectures/` 의 강의자료 본문 | **영어, 정식 교재 어조** |
| `PLAN.md`·대화·`.claude/` 스킬 문서·MATLAB 주석 | 한국어 |

영어 본문의 문체 규칙:

- **1·2인칭 금지.** "the learner", "this section" — `you`, `we`, `our`, `let's` 를 쓰지 않는다
- **시점 표현 금지.** "today" 가 아니라 "this week"
- 불릿 중심, 한 불릿에 한 절. **비교는 줄글이 아니라 표**
- 교재 명령형은 옳다: "Verify that…", "Do not…"
- 한 문단에 `**굵게**` 2개까지. 이모지·장식 기호 없음
- **쪽수 제한 없음.** 내용이 정한다 — 사용자가 명시했다

---

## 2. 폴더

> [!important] 이 볼트의 위치와 MSS
> 볼트는 `C:\Users\admin\Dropbox\센서신호처리및융합\00_GradCourse_2026\` 에 있다.
> MSS 툴박스(120 MB)는 **여기 없다** — 옆 프로젝트
> `10_연구_USV_MILS/Proj_SHI_USV_MILS/Tools/MSS` 에 있고,
> `_tools/mss_path.m` 이 **찾아서** 경로에 얹는다. 폴더를 세는 코드를 쓰지 않는다.
>
> ```matlab
> addpath(fullfile(root,'_tools'));
> mss_path();          % <- 이것 하나. proj = fileparts(root) 같은 것을 쓰지 않는다
> ```

> [!important] 폴더는 넷뿐이다. 늘리지 않는다
> 빈 폴더를 미리 만들지 않는다. 예전에 `00-admin` · `20-notes` · `40-assets` ·
> `80-assignments` · `90-instructor` 다섯이 **한 파일도 없이** 몇 주를 서 있었고,
> 그것이 볼트를 못 찾게 만든 원인이었다. **내용이 생길 때 폴더를 만든다.**

```
00_GradCourse_2026/
├── PLAN.md                  계획. 무엇을 언제 만드는가 — 맨 위, 이 이름
├── README.md                색인. 무엇이 어디에 있는가
├── CLAUDE.md                형식 계약 (이 파일)
│
├── lectures/                강의자료 전부. 주차와 부록이 한곳에 있다
│   ├── W01_….md / .pdf      주차 — 파일명이 순서다
│   ├── W01_simulink/        그 주차의 모델·러너·img/
│   ├── A1_….md / .pdf       부록 — 본과정에서 빼낸 심화. W 다음에 정렬된다
│   └── A1_simulink/
│
├── figures/                 개념도 SVG (w01-… … w11-…). 러너가 만든 PNG 는 여기 아니다
│   └── src/                 그 SVG 의 TikZ 원본 (*.tex) + gnc-style.tex
│                            `tikz2svg.sh` 이 여기서 ../*.svg 를 만든다
├── _templates/              week.md
├── _tools/                  md2pdf.sh · pdf-template.html · marked.min.js
│                            mathjax-tex-svg.js · lab_fig.m · mss_path.m
│                            otter_config.m · otter_B.m · add_otter_plant.m
│                            set_mlfcn.m · draw_ship.m · track_ships.m · ship_marks.m
│                            gnc_chain.m · gnc_colour.m · add_subsys.m · add_measurement.m
│                            add_sum.m · mss_style.m · export_diagram.m
│                            port_xy.m · row_feed.m · lane_line.m · check_overlaps.m
│                            ensure_base_vars.m
│                            crosstrack_err.m · wp_switch.m · path_plot.m
│                            verify_guidance.m                       (W04 유도)
│                            run_sim.m · step_metrics.m · recovery_time.m · prop_thrust.m
│                            verify_constants.m · live_track.m · base_var.m
│                            git_autopush.sh · svg2png.sh
│                            tex2svg.sh · tikz2svg.sh                (수식·그림 조판)
│                            bdiag.sh                                (블록선도 프리미티브)
│                            labels/                                 (그림 안 수식 배치목록)
│                            w01_6dof_arcs.awk · w01_euler_geo.awk
│                            w02_pseudo_geo.awk · w02_windup_geo.awk
│                            w02_windup_fig.sh · w04_three_laws.sh    (그림 생성)
│                            a1_column_geo.awk · a1_layouts_geo.awk
│                            w04_los_geo.awk                         (그림 계산)
└── .claude/skills/          gnc-lecture-vault · simulink-gnc-models
```

그림이 어디 있는지 헷갈리지 않게, 규칙은 하나다.

| 그림 | 어디에 | 누가 만드나 |
|---|---|---|
| 개념도 (좌표계·기하·배치) | `figures/wNN-….svg` | 손으로 그리거나 `_tools/*.awk` 가 계산 |
| 블록도 · 결과 그래프 | `lectures/WNN_simulink/img/*.png` | **러너가** 저장한다 |

주차 실습 폴더는 항상 같은 모양이다. **강의 절 하나에 스크립트 하나**이고, 파일명이
강의 순서 그대로다. 하나를 돌리면 그 절의 표와 그림만 나온다.

```
lectures/WXX_simulink/
├── WXX_0_setup.m          학생이 고치는 유일한 파일 — 모든 Constant 변수
├── WXX_1_build_<모델>.m   모델을 코드로 생성한다. 손으로 그리지 않는다
├── WXX_C_<절 제목>.m      강의 C 절 — 표 하나와 그림 한둘
├── WXX_D_<절 제목>.m      강의 D 절
├── …                      절이 있는 만큼
├── WXX_vars.m             같은 값을 struct 로. run_sim 이 하나씩 바꿔 쓴다
├── WXX_read.m             로그를 이름 붙은 필드로. 열 번호를 세지 않는다
├── WXX_plot.m             StopFcn 과 절 스크립트가 함께 부르는 플로팅 함수
├── WXX_animate.m          Animate 블록이 매 스텝 부르는 실시간 그리기
├── WXX_*.slx
└── img/                   블록도 PNG + 결과 그래프 PNG
```

> [!important] `.m` 과 `.slx` 이름이 겹치면 안 된다
> `W02_H_antiwindup.m` 과 `W02_H_antiwindup.slx` 가 함께 있으면 MATLAB 이 **모델을 열고**
> 스크립트는 **조용히 아무것도 하지 않는다.** 러너는 `_run` 을 붙인다.

---

## 3. 주차 `.md` 골격

> [!important] H1 바로 다음, 무엇보다 먼저
> 모든 주차·부록 자료의 **첫머리**에 `[!important] Reference material — read this first`
> 콜아웃이 들어간다. **작은 글자로 요약하고 링크로 들어가게** 한다.
> - **사용자 본인의 강의 다섯**, 기초부터 — ① 제어공학(KO) ② 제어시스템설계(KO)
>   ③ 제어공학특론(EN) ④ 센서신호처리 및 융합(EN) ⑤ 캡스톤디자인(KO).
>   각각 YouTube 재생목록 + Google Drive. **"이 강의의 강사가 직접 한 강의"임을 밝힌다**
> - **MATLAB · Simulink Onramp** 와 윤원근 교수 Simulink 강의 2편 —
>   선수 지식이 부족한 사람이 먼저 볼 것
>
> `_templates/week.md` 에 원본이 있으니 복사하면 따라온다. 주차마다 문구를 바꾸지 않는다.
> 자세한 것은 `gnc-lecture-vault/references/standing-orders.md` §1.

`_templates/week.md` 를 복사한다. **골격을 바꾸지 않는다** — 학생이 11주 내내 같은 자리에서
같은 것을 찾게 하는 것이 목적이다.

```
YAML 프론트매터 (type, week, title, date, tags, status, summary)
# Week N · Title
- Course / Department 줄
> [!important] Prerequisites from the previous week
## Learning Outcomes            번호 5~7개, 각각 검증 가능한 형태
## Prerequisites and Setup      표
---
# Part 1 · Theory               ## N-1, N-2, …   그림마다 "reading the figure" 표
# Part 2 · Laboratory           ## A, B, C …     명령 + 정상 출력 + 측정 표
# Summary
## Week Summary                 표: step | what was done | how it was verified
## Progress Check               체크박스, 검증 가능한 형태
## Assignment N                 ① requirements ② verification(필수) ③ analysis + 배점표
## Troubleshooting              표: symptom | cause | fix — 실제로 겪은 것만
## References                   MSS · Fossen Handbook §x.y · 논문
## Next Week
```

콜아웃은 `[!note] [!tip] [!important] [!warning] [!caution] [!info]` 여섯 가지만 쓴다.

---

## 4. 수식과 그림 — 어길 수 없는 것

전체 규칙은 `.claude/skills/gnc-lecture-vault/references/results-and-figures.md` 에 있다.
요약하면:

1. **수식은 LaTeX.** MathType 이미지를 만들지 않는다. PDF 에서 MathJax 3 `tex-svg-full` 이
   **SVG 벡터**로 조판하므로 그것이 곧 MathType 수준의 조판이다
2. 수식을 낸 직후에 **기호 표**(Symbol / Quantity / Value·source)를 붙인다
3. **주차마다 Simulink 블록도 PNG ≥ 1, 결과 그래프 PNG ≥ 1** 이 `.md` 와 `.pdf` 양쪽에 들어간다
4. 그림은 **러너가 저장한다.** 사람이 스크린샷을 찍지 않는다
5. 그림마다 뒤에 **"reading the figure" 표**를 붙인다
6. **그림을 완성하면 렌더해서 눈으로 확인한다.** 라벨 겹침·화살표 방향·기호 일치·부호·잘림.
   수식도 같다 — PDF 로 뽑은 뒤 `$` 가 남았는지, 첨자와 행렬이 깨지지 않았는지 본다.
   **고친 뒤에도 다시 렌더해서 본다.** 한 번으로 끝내지 않는다
6-1. **3차원 그림은 사영을 정해 계산해서 그린다.** 눈대중 금지.
   축 둘레의 모멘트는 **그 축에 수직인 평면 위의 원**이며, 사영한 타원의 **중심이 축선 위**에
   있어야 한다. 축선을 점선으로 타원 중심까지 잇는다. 세 축의 화면 길이는 축소율만큼 달라야 한다.
   계산 스크립트를 `_tools/` 에 남긴다 → `standing-orders.md` §3-2
7. **궤적을 그리는 그림에는 선체와 heading 을 함께 그린다.** 궤적선만으로는 배가 어디를
   향하고 있었는지 알 수 없고, 그 차이가 크랩각이다. `_tools/track_ships.m` 을 쓴다
8. 문서의 모든 수치는 러너 출력까지 추적 가능해야 한다. 추정치를 쓰지 않고,
   평균·RMS 는 **구간을 명시**한다
9. **수식을 떨어뜨리지 않는다.** 절의 첫 수식은 전체 모델(6자유도 → 3자유도)에서
   시작해 **버린 항을 표로 밝히고** 남는 것을 쓴다. 버린 항이 언제 돌아오는지도 한 줄.
   출처(Fossen §번호, `otter.m` 행 번호)를 반드시 적는다 → `standing-orders.md` §3-3
10. **쓴 수식은 검증한다** — 차원 · 극한 · 부호 · 수치(MATLAB 으로 실제 계산) · 출처 대조.
   검증하지 않은 수식은 싣지 않는다. Nomoto 처럼 **이름 붙은 표준 모델을 빼먹지 않는다**.
   계수는 `verify_constants` 가 `otter.m` 과 대조한다 — 유한차분으로 `M(1,1)` 을 재지 않는다
11. **`.md` 안의 LaTeX 은 Edit 도구로만 고친다.** `sed`·`awk`·`perl` 은 역슬래시를 저마다
   다르게 해석해서 수식을 조용히 부순다. 실제로 W01 전체를 한 번 망가뜨렸다
   → `standing-orders.md` §5-1. `\|` 는 노름 ‖·‖ 이므로 절댓값에는 `\lvert`·`\rvert` 를 쓴다

---

## 5. 모델

| 규칙 | |
|---|---|
| **배치** | **MSS 데모와 같은 순서.** 왼쪽에서 오른쪽으로 **command → reference → controller → allocation → plant → measurement**, 각 단계가 **서브시스템**. 좌표를 손으로 쓰지 않고 `gnc_chain` 을 쓴다 → `simulink-gnc-models/references/model-layout.md` |
| 포트 이름 | `In1`/`Out1` 을 그대로 두지 않는다. 포트 이름이 최상위에서 선 옆에 그대로 보인다 |
| 뒤로 가는 선 | 두 개 이하. 각각 이유를 댈 수 있어야 한다 |
| 로깅 | `add_measurement` 가 만든다. 앞 여섯 열은 모든 주차가 같다 — `[u v r N E psi]` |
| 생성 | `build_wXX_models.m` 이 모든 블록·선·주석을 만든다. 손으로 그리지 않는다 |
| 플랜트 | `otter_config(name)` + `add_otter_plant(...)` 하나. 형상 넷이 **같은 선체**를 쓴다 |
| `B` | `otter_B.m` 이 **열 규칙** 하나에서 유도한다. 기존 프로젝트의 `B` 를 가져오지 않는다 |
| 배치 | 좌표를 직접 정한 모델에는 `arrangeSystem` 도 `tidy_layout` 도 걸지 않는다 |
| 주석 | Simulink 주석은 자동 줄바꿈하지 않는다. `strjoin({...}, newline)` 으로 손으로 끊는다 |
| 흐름 | 왼쪽에서 오른쪽으로 **명령 → 플랜트 → 계측** |
| **블록 크기** | **MSS 를 그대로.** Sum 은 `add_sum` 으로 **20×20 원**, 나머지는 `save_system` 직전에 `mss_style(m)` 한 줄. 치수는 MSS 데모에서 측정한 것이다 → `model-layout.md` |
| **서브시스템 안쪽** | 최상위와 같이 **손으로 열을 잡아** 왼쪽→오른쪽. `arrangeSystem` 은 순서를 망가뜨리므로 쓰지 않는다. 서브시스템도 PNG 로 뽑아 눈으로 본다 |
| **겹친 선** | **`check_overlaps(mdl)` 이 0** 이어야 그 모델이 끝난 것이다. 소스를 포트 높이에 맞추는 `row_feed`, 통로에 이름을 붙이는 `lane_line`, 포트 높이를 **읽는** `port_xy` 로 만든다. 행 간격 52 px 이상 → `model-layout.md` |
| 색 | 플랜트 `[0.81 0.93 0.81]` 초록 · 로깅/표시 `[0.93 0.93 0.93]` 회색 |
| 실행 | `set_param(m,'ReturnWorkspaceOutputs','off')` — 없으면 To Workspace 결과가 `out` 에 갇힌다 |
| 자동 그림 | `set_param(m,'StopFcn','WXX_plot;')` — Run 만 눌러도 그림이 뜬다 |
| **주차 스코프** | `add_measurement` 이 `vessel u v r` 과 **`<tag> this week`** 두 개를 만들어 모델과 함께 연다. 앞의 것은 모든 주차가 같고, 뒤의 것은 **그 주차가 추가한 신호**다 — 명령·요구 힘·적분기 상태 |
| 살아 있는 궤적 | Animate 블록 + WXX_animate.m. 궤적만 그리지 말고 선체와 heading 을 함께 그린다 |

연구실 MILS 통합모델에서 **제어기·유도법칙·배분기를 복사하지 않는다.**
각 주차 강의에 실린 수식에서 Simulink 로 직접 만든다. 그것이 이 강의의 요점이다.

---

## 6. 끝내기 전

```bash
matlab -batch "cd lectures/WXX_simulink; WXX_1_build_...; WXX_0_setup"
bash _tools/md2pdf.sh lectures/WXX_*.md
bash .claude/skills/gnc-lecture-vault/scripts/vault_check.sh
bash _tools/git_autopush.sh
```

세 번째 명령이 **전 항목 0 건**이어야 그 주차가 끝난 것이고, 그 뒤에 올린다.
깨진 상태를 기록으로 남기지 않는다.

---

## 7. 기록

이 볼트는 **git 저장소**다. 원격은
`git@github.com:wkyouncnu/Sensor-Signal-Processing-and-Fusion.git`, **private**.

| | |
|---|---|
| 올라가는 것 | `00_GradCourse_2026/` **하나뿐** |
| 올라가지 않는 것 | 상위 폴더 전부 — `강의자료`·`10_연구_USV_MILS`(MSS 120 MB)·`90_보관`(출석부) |
| 언제 | SessionEnd 훅이 `_tools/git_autopush.sh` 를 부른다. 세션 하나에 커밋 하나 |

> [!warning] 범위를 넓히지 않는다
> 상위 폴더에는 **출석부**가 있다. 학생 개인정보이고, 한 번 올라가면 지워도 남는다.
> 범위를 바꾸려면 사용자에게 다시 묻는다 → `gnc-lecture-vault/references/git-and-history.md`
