---
name: gnc-lecture-vault
description: 대학원 USV GNC 강의 볼트(GradCourse)에서 강의자료를 만들고 고치고 검증하는 전 과정. 사용자가 "주차 자료 만들어줘", "W0N 만들어줘", "강의자료 고쳐줘", "MD 수정", "PDF 다시 뽑아줘", "수식 넣어줘", "LaTeX", "MathType", "그림 그려줘", "SVG", "블록도 넣어줘", "결과 그래프 넣어줘", "문체 고쳐줘", "지식카드", "README 갱신", "강의계획서", "과제 만들어줘", "볼트 점검" 을 언급하거나, lectures 폴더의 문서를 건드릴 때 반드시 사용하라. Simulink 모델 자체를 만들거나 배치를 정리할 때는 simulink-gnc-models 스킬을 함께 쓴다.
---

# GradCourse 볼트 — 일하는 방식

`GradCourse/` 는 **대학원 USV 유도·항법·제어 강의**다. 선체는 Fossen 의 Otter,
도구는 Simulink 하나, 근거는 MSS 와 Fossen Handbook 이다.
학부 캡스톤 볼트에서 형식과 작업 방식을 가져왔으나, **내용은 새로 쓴다.**

> [!important] 한 문장으로
> **모든 수치는 실행해서 얻고, 모든 블록도와 결과 그래프는 러너가 저장하고,
> MD 를 고쳤으면 PDF 를 다시 뽑는다.**

형식 규칙(폴더 구조·문체·프론트매터·콜아웃)의 **원본은 `CLAUDE.md`** 다. 이 스킬은
그것을 **어떤 순서로 실행하는가**를 담는다. 둘이 어긋나면 `CLAUDE.md` 가 이긴다.

---

## 0. 새 지침이 오면 — 자동으로

> [!important] 사용자가 지침을 주면 묻지 말고 전부 반영한다
> **`references/standing-orders.md` 를 먼저 읽는다.** 지침을 받으면 순서대로:
> 1. 지침을 `standing-orders.md` 에 한 줄로 **추가**
> 2. 해당 규칙 문서를 고친다 (`difficulty` · `results-and-figures` · `figures-svg` · `model-layout` · `lecture-md`)
> 3. `CLAUDE.md` 를 고친다
> 4. **`PLAN.md` 를 고친다** — 볼트 루트에 있다. 계획은 거기 하나뿐이다
> 5. **이미 나간 `.md` 를 전부** 고친다
> 6. **PDF 를 다시 뽑는다** — 이것을 빠뜨리면 학생이 보는 것은 옛날 것이다
> 7. `vault_check.sh` → 0 건

> [!important] 지침이 없어도, 무언가를 만들었으면 셋을 갱신한다
> 모델·절·그림·스크립트를 하나라도 만들었으면 그 작업을 끝내기 전에
> **① `PLAN.md` ② 이 스킬 ③ `CLAUDE.md`** 를 손본다. 나중에 몰아서 하지 않는다.
> → `references/standing-orders.md` §0-1

---

## 0-1. 이 볼트의 특수 조건

이 셋은 캡스톤 볼트와 다르며, 어길 수 없다.

1. **강의자료 본문은 영어, 정식 교재 어조.** 계획·대화·이 스킬 문서는 한국어다.
2. **주차마다 Simulink 실습이 있다.** 실습 없는 주차는 없다.
   그리고 그 주차의 **블록도와 결과 그래프가 `.md` 와 `.pdf` 양쪽에 들어간다**
   → `references/results-and-figures.md`
3. **최대한 쉽게 쓴다.** 한 주에 새 개념 셋, 남는 것은 **부록으로 뺀다.** **쪽수는 세지 않는다.**
   대학원 수업이라는 것이 어렵게 쓰라는 뜻이 아니다 → `references/difficulty.md`

---

## 1. 지시 → 무엇부터 하는가

| 사용자가 이렇게 말하면 | 첫 동작 | 읽을 것 |
|---|---|---|
| "N주차 자료 만들어줘" | `_templates/week.md` 복사. **골격을 바꾸지 않는다** | `references/lecture-md.md` |
| "이 부분 설명 보강해줘" | 대상 독자는 **대학원 1년차** — 학부 제어·동역학은 안다고 가정 | `references/lecture-md.md` |
| "문체 고쳐줘 / AI 같아" | `scripts/vault_check.sh --style` 로 금지 표현부터 센다 | `references/lecture-md.md` §문체 |
| "수식 넣어줘 / MathType 으로" | LaTeX 으로 쓴다. **이미지를 만들지 않는다** | `references/results-and-figures.md` §1 |
| "너무 어려워 / 쉽게 해줘" | 새 개념을 셋으로 줄이고, 남는 것을 **부록으로 뺀다** | `references/difficulty.md` |
| "블록도 / 결과 그래프 넣어줘" | 러너가 `img/` 에 저장하게 하고 `.md` 에서 상대경로로 참조 | `references/results-and-figures.md` §2 |
| "PDF 다시 뽑아줘" | `bash _tools/md2pdf.sh <파일>` — 쪽수·그림·수식까지 확인 | `references/results-and-figures.md` §3 |
| "그림 그려줘" (개념도) | `figures/` 에 SVG. **한 번의 Bash 호출에 하나씩** | `references/figures-svg.md` |
| "모델 만들어줘 / 선 정리해줘" | `build_wXX_models.m` 작성 | 스킬 `simulink-gnc-models` |
| "형상 바꿔줘" (W09~W11) | `_tools/otter_config.m` 에 `cfg` 추가. **선체는 손대지 않는다** | 아래 §3 |
| "주차를 옮기자 / 순서 바꾸자" | 파급 범위를 먼저 나열한다 (문서 4곳 이상) | `references/vault-upkeep.md` |
| "다 끝났나 확인해줘" | `bash .claude/skills/gnc-lecture-vault/scripts/vault_check.sh` | 아래 §5 |

---

## 2. 어길 수 없는 것 일곱

1. **수치는 실행 결과다.** 오차·시간·반경·RMS 를 추정으로 쓰지 않는다.
   반드시 **구간을 명시**한다 ("전 구간" 과 "초기 5초 제외" 는 다른 숫자다).
2. **블록도와 결과 그래프가 `.md` 와 `.pdf` 양쪽에 들어간다.** 주차마다 각각 최소 1장.
   사람이 스크린샷을 찍지 않는다 — 러너가 저장한다.
3. **MD 를 고쳤으면 PDF 를 다시 뽑는다.** 두 파일이 어긋나면 학생이 혼란스러워한다.
4. **강의자료 본문은 영어, 정식 어조.** 1·2인칭 금지, 시점 표현("today") 금지,
   이모지·장식 기호 금지. 비교는 줄글이 아니라 **표**.
5. **`lectures/` 에 내부용 메모를 쓰지 않는다.** 배포되는 문서다.
6. **연구실 MILS 통합모델에서 제어기·유도법칙·배분기를 복사하지 않는다.**
   각 주차 강의에 실린 수식에서 Simulink 로 직접 만든다. 그것이 이 강의의 요점이다.
7. **HTML 슬라이드 덱을 만들지 않는다.** 요청받지 않는 한.

---

## 3. 플랜트는 하나, 형상은 넷

`otter.m` 은 `numel(n) == 2` 를 강제하므로 W09~W11 에 그대로 못 쓴다.
네 번 복사하는 것은 **틀린 답**이다. 파라미터화된 플랜트 하나를 쓴다.

```matlab
cfg = otter_config('base' | 'aft_azimuth' | 'bow_thruster' | 'quad_tilt');
add_otter_plant(mdl, 'Otter plant', pos, cfg);
```

- 선체 유체동역학(`M`, `C_A`, `C_RB`, 교차흐름 감쇠, 복원력, `N_h = N_r(1+10|r|)r`)은
  **네 형상에서 한 글자도 다르지 않다.** 그래야 비교가 정직하다
- 바뀌는 것은 `B`, 추진기 개수, 틸팅 여부, 방위각 한계뿐이다

> [!warning] 부호 규약 함정
> 이 프로젝트에는 **정확히 부호가 반대인 `B` 가 둘** 산다 —
> `Lecture/_tools/otter4_B.m` 과 `otter_params.m` 41행.
> 둘 중 어느 것도 가져오지 않는다. **W02 의 열 규칙이 유일한 정의**이며,
> 모든 `B` 를 `_tools/otter_B.m` 이 거기서 유도한다.
>
> ```
> (x, y) 에 있고 방향이 e 인 추진기의 열 =  [ e_x ; e_y ; x·e_y − y·e_x ]
> ```

---

## 4. 작업 루프

새 자료든 수정이든 순서는 같다. **문서가 마지막이다.**

```
1) 자산 확인   MSS · Fossen Handbook 에 이미 있는지 먼저 찾는다
2) 빌더        build_wXX_models.m — 모델을 코드로 만든다. 손으로 그리지 않는다
3) 실행        WXX_run.m — 수치 표를 찍고, img/ 에 블록도와 결과 그래프를 저장한다
4) 문서        MD 에 수식 + 기호표 + 그림 + 실측 수치 + 진도 체크 + 과제 배점
5) 변환        md2pdf.sh → 쪽수·그림·수식 확인
6) 색인        README 표 · Syllabus · 지식카드 갱신
7) 점검        vault_check.sh → 0 건이 합격선
```

> [!warning] 3번을 건너뛰고 4번을 쓰지 않는다
> 이 볼트에서 문서의 숫자는 전부 근거가 있다. 근거가 없으면 그 절을 쓰지 않는다.

---

## 5. 참고 문서

| 파일 | 읽을 때 |
|---|---|
| `references/lecture-md.md` | 주차 자료를 쓰거나 고칠 때마다. 골격·문체·과제 배점 |
| `references/results-and-figures.md` | **수식·블록도·결과 그래프를 넣을 때. 사용자가 못박은 규칙** |
| `references/standing-orders.md` | **가장 먼저. 사용자가 못박은 상시 지침이 전부 여기 있다** |
| `references/difficulty.md` | **주차를 설계할 때마다. 난이도·무엇을 부록으로 뺄지** |
| `references/pdf-and-math.md` | PDF 가 안 나올 때, 템플릿을 고칠 때 |
| `references/figures-svg.md` | 개념도 SVG 를 그릴 때 |
| `references/vault-upkeep.md` | 문서를 추가·이동·개편할 때, 지식카드를 만들 때 |

모델 작업은 **다른 스킬**이다 — `.claude/skills/simulink-gnc-models/`
(배치 정리 `layout.md`, 생성 관용구 `build-models.md`, MSS 규약 `gnc-conventions.md`,
검증 `verify.md`).

---

## 6. 끝내기 전 점검

```bash
bash .claude/skills/gnc-lecture-vault/scripts/vault_check.sh
```

| 항목 | 합격선 |
|---|---|
| MD ↔ PDF 쌍 누락 | 0 |
| PDF 가 MD 보다 오래됨 | 0 |
| 깨진 wikilink | 0 |
| 없는 그림 참조 | 0 |
| 주차별 블록도 PNG · 결과 그래프 PNG | 각 ≥ 1 |
| PNG 가 `.slx` 보다 오래됨 | 0 |
| 블록도 PNG 폭 > 2000 px | 0 |
| 짝이 맞지 않는 `$$` | 0 |
| 금지 표현(you·we·today·이모지 등) | 0 |
| `![[...]]` 임베드 | 0 |
| 미지원 콜아웃(`[!danger]` 등) | 0 |
| 흰 배경 없는 SVG | 0 |

`--style` 만 주면 문체 검사만, `--links` 면 링크·그림만, `--figs` 면 그림·수식 검사만 돈다.
