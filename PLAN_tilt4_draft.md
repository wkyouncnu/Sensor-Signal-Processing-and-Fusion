---
type: plan-draft
title: 기울어지는 추진기 넷과 제어배분 — 계획안
date: 2026-11-03
status: 확인 대기
summary: Otter 를 ±45° 로 기우는 추진기 넷으로 바꾸고 그 과다구동 배분을 가르치는 자료의 계획안. 확인 전까지 강의 .md·.slx·.m 을 만들지 않는다.
---

# 기울어지는 추진기 넷과 제어배분 — 계획안

이 문서는 **계획안이다.** 확인 전까지 강의 `.md`·`.slx`·`.m` 을 만들지 않고 git push 하지 않는다.
확인 후에 §1~§8 이 `PLAN.md` 로 병합되고 이 초안은 삭제된다.

출처는 윤원근 교수 본인의 캡스톤 과제 코드와 그 최종 논문이다.
**코드 내용만 참조하고 이 강의 방식으로 새로 쓴다. 복사하지 않는다** (CLAUDE.md §5 끝문단, SKILL.md §2 규칙 6).

---

## 1. 번호와 자리

### 결론 — **W12 하나 + 새 부록 A2**. 주차를 밀지 않는다.

`PLAN.md` §2 가 이미 자리를 비워 두었다. W01~W10 과 A1 은 완성되어 있고, 남은 것이 둘이다.

| 주차 | 제목 | 현재 상태 |
|---|---|---|
| W11 | Variant A — Aft Azimuth Thrusters | 미착수 |
| W12 | **Variant C — Four Tilting Thrusters, and a Comparison** | 미착수 |

`_tools/otter_config.m` 의 주석도 같은 번호를 쓴다 — `'aft_azimuth'` 는 "11주차", `'quad_tilt'` 는
"±45 도로 기우는 추진기 넷 (12주차)". `plan-design.md` §6 의 환경표도 **Optimization Toolbox 를
W07·W12 에** 이미 배정해 두었다. 즉 이 주제는 **처음부터 W12 자리**이고, 번호를 옮길 필요가 없다.

주차를 미는 작업은 두 단계 절차에 세 개의 지뢰가 딸린 일이다 (`orders-log-4.md` §15-50).
그 일을 할 이유가 없다는 것이 이 계획의 첫 번째 결정이다.

### W11 은 그대로 둔다 — 그것이 W12 의 디딤돌이다

`otter_config('aft_azimuth')` 는 **기우는 추진기 둘**이다. B 는 3×4, 계수 3, 영공간 1 —
과다구동의 **가장 작은 예**다. 자유도가 하나뿐이므로 영공간을 손으로 쓸 수 있고, 각도 한계가
어떻게 비선형 제약이 되는지를 미지수 넷으로 볼 수 있다. 그 다음에 W12 가 미지수 여덟·영공간 다섯으로
넘어간다. 캡스톤 코드에도 `tilt2` 모델이 따로 있어 근거가 된다.

W11 을 건너뛰고 W12 만 쓰면, 학생은 영공간 다섯을 처음부터 마주한다. 권하지 않는다.

### 왜 한 주차로 부족하고, 부록이 하나 더 필요한가

W12 가 실어야 할 것을 세어 보면 절이 아홉이다 (§2). 그 아홉은 **배분 사다리의 본줄기**다 —
최소노름에서 쐐기 QP 까지. 반면 아래 셋은 본줄기가 아니고, 그러나 버릴 수도 없다.

| 내용 | 어디로 | 왜 |
|---|---|---|
| 정확한 비선형 해 (`fmincon` + `nonlcon`) | **A2** | 답은 맞지만 85 ms 다. 왜 못 쓰는지는 계산시간 이야기이고 배분 이야기가 아니다 |
| 능동집합 알고리즘 (Härkegård, QCAT) | **A2** | QP 를 **어떻게 푸는가**. 수치최적화이고, 선택과목 성격이다 |
| 실시간 예산 (Ts=4 ms 대 p99=1.77 ms) | **A2** | 코드생성·임베디드 이야기 |

`A2` 는 CLAUDE.md §2 가 말하는 부록의 정의 그대로다 — "본과정에서 빼낸 심화". `lectures/` 안에
`A2_….md` 로 들어가고 W 다음에 정렬된다. 제목안: **A2 · Solving the Allocation Problem — Active Sets and the Real-Time Budget**.

### 다른 선택지와 그 대가

| 안 | 내용 | 평가 |
|---|---|---|
| **W12 + A2** | 권고안 | 12주 범위 유지, W11 디딤돌 유지, 심화는 부록 |
| W11+W12 둘 다 이 주제 | Variant A 를 버린다 | 디딤돌이 사라지고 `PLAN.md` 의 계획 항목 하나가 없어진다 |
| W12 하나에 전부 | 부록 없음 | 절이 열셋 이상. "쉽게" 가 불가능하다 |

→ **§9 질문 1.**

### 이미 만들어진 것 — 다시 쓰지 않는다

| 있는 것 | 어디 | W12 가 할 일 |
|---|---|---|
| 확장추력벡터 유도, `[1 0; 0 1; -y x]` 두 열 기여, Fossen §12.3.4 인용 | `A1_….md` §A1-4 | **인용하고 넘어간다.** 다시 유도하지 않는다 |
| 네 형상 비교표 (`quad_tilt`: 추진기 4, 열 8, 계수 3, 영공간 5) | 같은 절 + `figures/a1-four-layouts.svg` | 그 표를 §12-2 에서 가리킨다 |
| 열 규칙 하나에서 B 를 유도하는 `otter_B.m` | `_tools/otter_B.m` | 이미 `quad_tilt` 를 지원한다. **고칠 것 없다** |
| `quad_tilt` 형상·`alpha_max=45°`·`alpha_rlim=90°/s` | `_tools/otter_config.m` | 이미 있고, 논문 Table 8 의 ±1.5708 rad/s 와 일치한다 |
| 유사역행렬·최소자승·클리핑 대 스케일링·구속 배분의 **기초** | `W07_….md` §7-2 … §7-8 | W07 은 추진기 둘~넷의 **고정** 배분이다. W12 는 그 위에 각도를 올린다 |

> [!warning] A1 §A1-4 의 주차 번호가 낡았다
> 표는 `quad_tilt` 를 "Week 11" 로, 본문은 "That decision is what Week 7 is for" 로 적는다.
> W12 가 들어가는 날 손으로 고친다 (파일 다섯 군데 이내 — `vault_shift_from.m` 를 쓸 일이 아니다).

---

## 2. 절 구조

`_templates/week.md` 의 골격을 바꾸지 않는다. 아래는 `# Part 1` 안의 절들이다.
절 하나는 넷으로 — What is observed / The result / Derivation / Experiment.

### W12 · Variant C — Four Tilting Thrusters, and a Comparison

| 절 | 제목 | 무엇을 보이고 무엇을 유도하는가 |
|---|---|---|
| **12-0** | Setting up the four-thruster hull | `otter_config('quad_tilt')` 를 열어 형상·한계·B 의 크기를 눈으로 확인한다. 선체는 1~11주차와 **같은 선체**임을 숫자로 보인다 |
| **12-1** | **Two commands that look the same** | **Config1 과 Config2.** 같은 회전수 `[10 10 10 10]`, 각도만 `[90 90 90 90]°` 대 `[90 90 -90 -90]°`. 하나는 배를 옆으로 밀고 하나는 돌린다. 유도는 없다 — **관측만** 한다. 여덟 개의 숫자를 손으로 고를 수 없다는 것이 이 주차의 문제 제기다 |
| **12-2** | **What the controller asks for, and what the hull gets** | 제어기가 내놓는 $\tau_{\text{demand}}$ 가 배분을 지나 $n,\delta$ 가 되고, 선체가 실제로 받는 것이 $\tau_{\text{actual}}$ 이다. **제어배분이란 이 둘을 같게 만드는 일이다.** 사용자의 "Controller design architecture" 두 구조(body 제어 / NED 제어 + 회전)를 그려 회전 블록의 자리를 보이고, 명령 3 개에 미지수 8 개라는 **과다구동**을 센다. 이 절이 정의하는 $\varepsilon_\tau=\tau_{\text{demand}}-\tau_{\text{actual}}$ 이 **남은 일곱 절 전부의 측정값**이다 |
| **12-3** | The matrix that turns eight numbers into three | $\tau=\sum T_i[\cos\delta_i;\sin\delta_i;\cdot]$ 는 $\delta$ 가 코사인 안에 있어 선형 연립방정식이 아니다. 미지수를 $(f_x,f_y)$ 로 바꾸면 $B$ 가 **상수**가 된다 (A1 §A1-4 인용). 열 규칙으로 **B 3×8** 을 만들고 계수 3·영공간 5 를 재며, **같은 배에 서로 다른 세 가지 B 가 돌아다닌다**는 것을 표로 드러내 §12-1 의 수수께끼를 푼다 |
| **12-4** | The answer with no opinion | 라그랑주로 $f=B^{\mathsf T}(BB^{\mathsf T})^{-1}\tau$ 를 유도한다. **한계를 끄면 $\varepsilon_\tau=0$ 이다** — 배분은 끝난 것처럼 보인다. 그런데 $\delta$ 를 그려 보면 ±180° 까지 돈다. **유도가 낳은 측정 가능한 예측**: 서보가 갈 수 없는 각도의 횟수 |
| **12-5** | Telling the solver what is expensive | 가중 최소노름 $H=W^{-1}B^{\mathsf T}(BW^{-1}B^{\mathsf T})^{-1}$ 을 유도한다. $f_y$ 에 큰 가중을 주면 추진기가 앞을 보려 한다. $W$ 를 1→10000 으로 쓸어 **평균 \|δ\| 가 내려가고 총추력이 올라가는** 교환을 잰다. $\varepsilon_\tau$ 는 아직 0 이다 |
| **12-6** | **The motor and the servo say no** | 한계를 켠다 — 모터 출력 제한(추력 포화, $n_{\max}$·$n_{\min}$)과 서보 출력 제한(각도 ±45°, 각속도 90°/s). §12-5 의 답을 **자르고** 그 $n,\delta$ 로 $\tau_{\text{actual}}$ 을 다시 계산하면 **$\varepsilon_\tau\neq 0$ 이 된다.** 처음으로 배분이 실패한다. 결론: **한계는 문제 안에 있어야 한다** |
| **12-7** | Making the violation expensive | 벌점 $\lambda\sum\max(\lvert\delta_i\rvert-\delta_{\max},0)^2$ 를 비용에 더한다. $\lambda$ 를 쓸어 작으면 위반이 남고 크면 조건수가 나빠지는 것을 $\varepsilon_\tau$ 로 보인다. 그리고 `atan2` 때문에 **아직 비선형계획**임을 짚는다 |
| **12-8** | Replacing an angle with two straight lines | $\lvert\delta\rvert\le\delta_{\max}$ 를 $f_x\ge\varepsilon$ 과 $\lvert f_y\rvert\le f_x\tan\delta_{\max}$ 두 **선형** 부등식으로 바꾼다. `atan2` 가 사라지고 문제가 **QP** 가 된다. 쐐기를 그리고, 무엇이 잘려 나갔는지 밝힌다. 예측: 위반이 **정확히 0** 이고 $\varepsilon_\tau$ 가 §12-6 보다 작다 |
| **12-9** | Three allocators, one demand | 유사역행렬 · 벌점 · 쐐기 QP 를 같은 $\tau_{\text{demand}}$ 이력에 돌려 **$\varepsilon_\tau$ 한 자로** 비교한다. 우리 러너의 수치가 합격선이 되고, 논문 Table 10 을 **옆 칸에** 둔다 (치수가 다르므로 — §3 끝) |

`# Part 2` 는 실행 순서 색인 한 표. `# Summary` 이하는 골격 그대로 (Week Summary ·
Progress Check · Assignment 12 · Troubleshooting · References · Next Week).

### A2 · Solving the Allocation Problem — Active Sets and the Real-Time Budget

| 절 | 제목 | 무엇을 보이고 무엇을 유도하는가 |
|---|---|---|
| **A2-1** | The exact answer, and what it costs | 각도 제약을 그대로 둔 비선형계획 (`fmincon`, `nonlcon`). 배분 오차가 $10^{-15}$ N 으로 **정확**하다. 그리고 한 번 푸는 데 걸린 시간을 잰다 |
| **A2-2** | A deadline is a specification | 제어주기 4 ms 와 최대 85 ms 를 나란히 둔다. 평균이 아니라 **p99.5 와 최댓값**으로 판정해야 하는 이유 |
| **A2-3** | Why the redistributed pseudo-inverse is not enough | Härkegård (2002) 의 비판을 유도로 재현한다 — 포화된 축을 고정하고 다시 분배하면 최적이 아닌 점에 머문다 |
| **A2-4** | The active set | 어느 제약이 걸려 있는지 **맞혀 보고 고치는** 반복. 유한 번에 끝나는 이유. 상자 한계로 바꿔 쓰는 QCAT 의 입력 (`umin/umax`, `Wv`, `Wu`, `ud`, `gamma`) |
| **A2-5** | Warm starting | 전 주기의 답에서 시작하면 반복수가 줄어든다. 재는 방법과 그 한계 |

---

## 3. 쉬운 길 — 배분을 어떻게 가르치는가

이것이 사용자의 핵심 요구다. 사다리의 **칸 간격을 한 걸음으로** 유지하는 것이 설계 원칙이다.
"쉽게" 의 판정 기준은 하나다 — **강의자가 소리 내어 읽었을 때 학생이 이해하는가.**
쉬운 것과 얕은 것은 다르므로 **유도의 중간 단계는 줄이지 않는다** (CLAUDE.md §3).

### 출발점 — 수학이 아니라 왕복 한 바퀴

제어배분의 정의를 행렬로 먼저 내밀지 않는다. **질문 하나로 연다.**

> 제어기가 "이만큼의 힘과 모멘트를 내라" 고 요구했다. 추진기들이 실제로 낸 것이 그것과 같은가?

사용자의 "Controller design architecture" 슬라이드가 그 왕복을 이미 그려 놓았다.

```
[u_d, y_d, ψ_d] → Controller → τ_demand → Control Allocation → n, δ → Dynamics → τ_actual
                                   (3개)                        (8개)               (3개)
```

제어기는 **무엇을 원하는지**를 3 개의 수로 말하고, 배분기는 그것을 **기계가 받는 언어**
(추력 넷 + 각도 넷) 로 옮기며, 선체는 그 기계가 실제로 만든 힘을 받는다. 그래서 측정량이 하나 생긴다.

$$\varepsilon_\tau \;=\; \tau_{\text{demand}} - \tau_{\text{actual}}$$

**$\varepsilon_\tau=0$ 이면 배분이 성공한 것이고, 0 이 아니면 그 크기가 곧 배분 오차다.**
이 한 수치를 §12-4 부터 §12-9 까지 **매 절에서 똑같이 재는 것**이 이 주차의 뼈대다.
CLAUDE.md §4-9-1 의 "유도는 측정 가능한 예측을 하나 낳아야 한다" 가 이것으로 충족된다.

> [!important] $\tau_{\text{actual}}$ 은 **되돌려 계산한다** — 제어기 출력을 다시 읽지 않는다
> 시뮬레이션에서 $\tau_{\text{actual}}$ 은 기록된 회전수 $n$ 과 서보각 $\delta$ 를 프로펠러 곡선
> $T=k\,n\lvert n\rvert$ 과 열 규칙으로 되돌려 다시 계산한 값이다. 배분기가 **의도한** 힘을 로깅하면
> 잘못된 역변환이 몰래 통과한다 — `W07_check.m` 이 이미 그 이유로 같은 방식을 쓴다.

### 왜 안 맞는가 — 한계 때문이다. 그리고 그것이 강의의 뼈대다

한계가 없으면 이 주차는 §12-4 에서 끝난다. 의사역행렬 한 줄이면 $\varepsilon_\tau=0$ 이다.
**배분이 어려운 이유는 전부 기계의 한계에서 온다.**

| 한계 | 무엇이 | 값 (Otter · `otter_config('quad_tilt')`) | 어기면 |
|---|---|---|---|
| **모터 출력 제한** | 회전수 상·하한 → 추력 포화 | $n_{\max}=\sqrt{0.5\cdot24.4\cdot9.81/k_{\text{pos}}}$, $n_{\min}$ 은 역방향 | 요구한 크기가 안 나온다 |
| **서보 출력 제한 ①** | 틸팅 각도 범위 | $\lvert\delta_i\rvert\le 45°$ | 요구한 **방향**이 안 나온다 |
| **서보 출력 제한 ②** | 틸팅 각속도 | $\lvert\dot\delta_i\rvert\le 90°/\mathrm{s}$ | 요구한 방향에 **늦게** 도착한다 |

그래서 사다리의 순서가 정해진다. 이것이 강의의 뼈대다.

| | 무엇을 켜는가 | 그 결과 | 절 |
|---|---|---|---|
| 1 | 한계 없음 | 의사역행렬로 $\varepsilon_\tau=0$. **끝난 것처럼 보인다** | 12-4 |
| 2 | 한계 없음 + 가중 | $\varepsilon_\tau=0$ 을 유지하면서 각도를 싸게 만든다 | 12-5 |
| 3 | **한계를 켠다** | 잘라 보면 $\varepsilon_\tau\neq0$. **처음으로 실패한다** | 12-6 |
| 4 | 한계를 비용에 넣는다 | $\varepsilon_\tau$ 가 줄지만 위반이 남는다 | 12-7 |
| 5 | 한계를 **제약**으로 넣는다 | 위반 0, $\varepsilon_\tau$ 최소 | 12-8 |

WLS 와 constrained WLS 는 **한계 때문에 생겨난 것**이지 더 좋은 수학이어서 생긴 것이 아니다.
그 인과를 절 순서가 그대로 보이게 한다.

### 슬라이드의 추진기 셋과 이번 추진기 넷 — 왜 문제가 생기는가

슬라이드는 $n=[n_1,n_2,n_3]$ 으로 미지수 셋이다. 이번 주차는 미지수가 여덟이다.
**미지수가 명령보다 많다는 것(과다구동)이 배분 문제가 생기는 이유**이고, 그 대비를 §12-2 가 표로 둔다.

| | 슬라이드의 구성 (고정 추진기 셋) | 이번 주차 (`quad_tilt`) |
|---|---|---|
| 명령 | $\tau_{\text{demand}}=[\tau_x,\tau_y,\tau_N]$ — **3** | 같다 — **3** |
| 미지수 | $n_1,n_2,n_3$ — **3** | 추력 4 + 각도 4 — **8** (확장벡터로 쓰면 $f\in\mathbb R^8$) |
| $B$ | 3×3 | **3×8** |
| 해의 개수 | $\det B\neq0$ 이면 **정확히 하나** | **무한히 많다** — 영공간 차원 **5** |
| 그래서 하는 일 | 행렬을 **뒤집는다** | 무한한 해 중 **하나를 고른다** → 고르는 기준이 필요하다 |
| 한계가 하는 일 | 답이 한계를 넘으면 **방법이 없다** | 한계 안쪽에서 **다른 해를 찾을 수 있다** |

마지막 줄이 핵심이다. 과다구동은 문제를 만들기도 하지만 **여유를 주기도 한다.**
추진기 셋은 한계에 걸리면 끝이고, 넷은 다른 자세로 같은 $\tau$ 를 낼 수 있다.
6주차(선수추진기 셋, `add_allocation3`) 는 $\det B=0.79$ 로 **뒤집었고**, 이번 주차는 **고른다.**

### 두 제어기 구조 — 회전 블록이 어디에 들어가는가

슬라이드의 두 구조는 **배분기가 body 에서 일한다**는 사실 하나를 말한다.

| | 명령 | 제어기가 내놓는 것 | 회전 블록 | 배분기가 받는 것 |
|---|---|---|---|---|
| 구조 1 | $[u_d,\ y_d^{b},\ \psi_d]$ | $\tau_{\text{demand}}$ (이미 body) | **없다** | $\tau_{\text{demand}}$ |
| 구조 2 | $[x_d^{n},\ y_d^{n},\ \psi_d]$ | $\tau_{\text{demand},n}$ (NED) | $R(\psi)^{\mathsf T}$ | $\tau_{\text{demand},b}$ |

**제어기는 NED 로 생각해도 되지만 배분은 반드시 body 에서 한다** — 추진기가 선체에 붙어 있기
때문이다. 두 구조의 차이는 회전 블록 하나이고, 그 블록이 **배분기 앞**에 있다는 것이 요점이다.
W08(DP)·W09(통합) 이 이미 NED 위치 제어를 다루었으므로 이 절은 **그 둘을 이 그림에 꽂아 넣는다.**

### 넘어야 할 산 — B 가 왜 비선형인가

추진기 하나가 내는 힘은 크기 $T_i$ 와 방향 $\delta_i$ 를 가진다. 몸체 좌표로 쓰면

$$\tau=\sum_{i=1}^{4}\begin{bmatrix}\cos\delta_i\\ \sin\delta_i\\ x_i\sin\delta_i-y_i\cos\delta_i\end{bmatrix}T_i$$

미지수가 $(T_i,\delta_i)$ 여덟 개인데, 그중 넷이 **코사인 안에 들어 있다.** 행렬을 앞에 두고
$\tau=B(\delta)\,u$ 로 써도 $B$ 가 미지수에 의존하므로 선형 연립방정식이 아니다. 최소자승이 안 통한다.

### 건너는 방법 — 미지수를 바꾼다

$f_{ix}=T_i\cos\delta_i$, $f_{iy}=T_i\sin\delta_i$ 를 미지수로 삼으면 (Fossen 2011 §12.3.4,
이미 A1 §A1-4 에 유도되어 있다)

$$\tau=Bf,\qquad B\in\mathbb R^{3\times 8},\qquad f=[f_{1x}\ f_{1y}\ \cdots\ f_{4y}]^{\mathsf T}$$

이고 $B$ 는 **상수**다. 푼 뒤에 되돌린다.

$$\delta_i^\*=\operatorname{atan2}(f_{iy}^\*,f_{ix}^\*),\qquad T_i^\*=\sqrt{f_{ix}^{\*2}+f_{iy}^{\*2}},\qquad n_i^\*=\sqrt{T_i^\*/k}$$

**산 것과 판 것을 한 표로 둔다.** 이 표가 §12-3 의 핵심이고, 이것 하나로 뒤의 다섯 절이 설명된다.

| | 원래 미지수 $(T,\delta)$ | 바꾼 미지수 $f$ |
|---|---|---|
| 평형식 $\tau=\cdots$ | **비선형** | **선형** |
| 추력 한계 $T\le T_{\max}$ | 선형 (상자) | **비선형** — 원 $\sqrt{f_x^2+f_y^2}\le T_{\max}$ |
| 각도 한계 $\lvert\delta\rvert\le\delta_{\max}$ | 선형 (상자) | **비선형** — `atan2` |

비선형이 식에서 **제약으로** 옮겨 갔다. 그래서 뒤의 사다리는 전부 "이 제약을 어떻게 다루는가" 다.

### 사다리 — 한 칸에 한 걸음

CLAUDE.md §4-9-1 의 여덟 단계를 배분 문제로 옮긴 것이 아래다. §4-9-1 은 오차 동역학을
전제하지만 배분은 대수 문제이므로, 대응을 **명시**한다.

| §4-9-1 의 단계 | 배분 문제에서는 | 어느 절 |
|---|---|---|
| ① 오차의 운동방정식 | 배분 오차 $\varepsilon_\tau=\tau_{\text{demand}}-\tau_{\text{actual}}$ 과 해의 영공간 (차원 5) | 12-2 · 12-3 |
| ② 옛 법칙을 넣어 닫기 | 최소노름 $f=B^{\mathsf T}(BB^{\mathsf T})^{-1}\tau$ 를 넣는다 | 12-4 |
| ③ 평형점 | $s=0$ 이 되는 해의 **집합**. 그중 노름 최소인 한 점이 선택된다 | 12-4 |
| ④ 무엇이 참이어야 하는가 | $s=0$ 만으로 부족하다 — $\lvert\delta_i\rvert\le 45°$ 가 **기계의 사실**이다 | 12-4 끝 |
| ⑤ 새 항이 가야 할 값 | $\delta$ 를 작게 하려면 $f_y$ 를 작게 해야 한다 → 비용에 $f^{\mathsf T}Wf$ | 12-5 |
| ⑥ 거기로 보내는 조건 | 가중은 $\delta$ 를 **싸게 만들 뿐 약속하지 않는다** → 제약으로 올려야 한다 | 12-6 · 12-7 |
| ⑦ 작은 신호 읽기 | 작은 $\tau$ 에서 $f_x\to 0$ 이면 `atan2` 가 날뛴다 → $f_x\ge\varepsilon$ | 12-8 |
| ⑧ 한계 | 쐐기가 **무엇을 잘라냈는가** (아래 표) | 12-8 끝 |

### 쐐기 — 각도 하나를 직선 둘로

$f_x>0$ 에서 $\lvert\delta\rvert\le\delta_{\max}\iff\lvert f_y\rvert\le f_x\tan\delta_{\max}$ 다.
이것은 **근사가 아니라 등가**다. 그래서 두 개의 선형 부등식으로 적을 수 있다.

$$\underbrace{f_{ix}\ \ge\ \varepsilon}_{\text{(1) 앞으로만}},\qquad
\underbrace{\ \ \ f_{iy}-f_{ix}\tan\delta_{\max}\le 0\ \ \ }_{\text{(2) 좌현 쪽 한계}},\qquad
\underbrace{-f_{iy}-f_{ix}\tan\delta_{\max}\le 0}_{\text{(3) 우현 쪽 한계}}$$

근사가 들어가는 곳은 **집합 자체**이고, 그것을 숨기지 않고 표로 적는 것이 §12-8 의 마지막이다.

| 버린 것 | 왜 버렸는가 | 대가 |
|---|---|---|
| 거울 쐐기 $\delta\approx180°$ (역추력) | 오목 집합이 되어 QP 가 아니게 된다. 그리고 (1) 이 **부호 뒤집힘을 막는** 것이 설계 의도다 | 뒤로 밀 수 없다. 후진·정지 기동은 모드를 따로 둔다 |
| 원형 추력 한계 $\sqrt{f_x^2+f_y^2}\le T_{\max}$ | QP 의 제약은 다면체여야 한다 | 상자로 바꾸면 **낙관적**(모서리에서 원을 넘는다), 내접 다각형이면 **보수적**. 어느 쪽인지 밝히고 고른다 |

이 두 줄이 "왜 논문이 이것을 approximation 이라 부르는가" 에 대한 답이고, **유도의 한계를
적는다**는 §4-9-1 ⑧ 이 요구하는 것이다.

### 비용함수를 한 번에 내놓지 않는다

논문 Eq (8) 은 항이 셋이다. 셋을 동시에 보여 주면 "갑자기 튀어나온" 것이 된다. 절마다 하나씩 쌓는다.

| 절 | 그 절에서 비용에 더해지는 항 | 왜 그 항이 필요한가 (그 절이 만든 증거) |
|---|---|---|
| 12-4 | $f^{\mathsf T}f$ | 해가 무한히 많다 (영공간 5). 하나를 골라야 한다 |
| 12-5 | $f^{\mathsf T}Wf$, $w_y>w_x$ | 12-4 의 $\delta$ 가 ±180° 까지 돌았다 |
| 12-7 | 벌점 항 | 12-6 에서 자르면 $\tau$ 가 틀어졌다 |
| 12-8 | 여유변수 $s^{\mathsf T}W_v s$ + 변화율 $(f-f_{\text{prev}})^{\mathsf T}W_\Delta(f-f_{\text{prev}})$ | 제약 때문에 $\tau$ 를 못 맞출 때 **어디서 포기할지**를 정해야 하고, 서보가 떨면 안 된다 |

### 치수는 Otter 를 쓴다 — 논문 수치를 합격선으로 쓰지 않는다

논문의 실선은 선체 1.42 m, $l_f=l_a=0.7$ m, $d=0.21$ m, $k_T=3.64\times10^{-4}$ 이고
이 강의의 Otter 는 $l_f=1.5$, $l_a=1.0$, $y_{\text{pont}}=0.395$, $k=0.02216/2$ 다.
**방법은 논문을 인용하고 수치는 우리 러너가 낸다.** 그래야 CLAUDE.md §4-8 ("문서의 모든 수치는
러너 출력까지 추적 가능") 이 지켜진다. 논문 Table 10 은 §12-9 의 표 **옆 칸**에 "the paper's own
platform" 으로 인용하고, 합격선으로 쓰지 않는다.

---

## 4. Simulink 모델 계획

### `.slx` 셋

| 모델 | 쇠사슬 | 어느 절 |
|---|---|---|
| `W12_C_scenarios.slx` | **command**(8 시나리오 Constant: `n_cmd`, `tilt_cmd`) → **plant**(quad_tilt) → **measurement** | 12-0 · 12-1 |
| `W12_E_allocate.slx` | **command**($\tau$ 이력) → **allocation**(법칙 넷, 플래그) → **thrust & servo**(atan2·sqrt·rate limit) → **plant** → **measurement** | 12-4 … 12-9 |
| `W12_J_mission.slx` | **command**(웨이포인트) → **reference**(LOS) → **controller**(heading + speed) → **allocation** → **plant** → **measurement** | 12-9 |

세 모델 모두 좌→우 `gnc_chain`, 각 단계가 서브시스템, 끝은
`mss_style` → `compact_layout` → `straighten_lines` → `save_system` 이고,
**디스크의 파일로 다시 세어** `check_overlaps` 와 `check_diagonals` 가 **둘 다 0** 이어야 끝이다.

### 배분 블록 — 법칙 넷을 한자리에

CLAUDE.md §5 "알고리즘 선택" 대로 **플래그 입력 하나**(`law = 1,2,3,4`)가 고른다.

| `law` | 법칙 | 캔버스에서 어떻게 보이는가 |
|---|---|---|
| 1 | 최소노름 | **Gain 블록 하나.** 값이 `H_pinv` — 보이는 행렬곱이다 |
| 2 | 가중 최소노름 | **Gain 블록 하나.** 값이 `H_w` (setup 이 계산해 작업공간에 둔다) |
| 3 | 벌점 (soft) | MATLAB Function. 안에서 `quadprog` 를 부른다 |
| 4 | 쐐기 QP | MATLAB Function. 안에서 `quadprog` 를 부른다 |

> [!warning] §5 와의 타협 — 사용자 확인이 필요하다
> §5 는 "제어기는 서브시스템 안의 시뮬링크 블록. MATLAB Function 한 덩어리로 두지 않는다" 다.
> **법칙 1·2 는 그 규칙을 그대로 지킬 수 있다** — 행렬 하나의 Gain 이다. 그러나 3·4 는
> 반복 솔버이므로 블록으로 그릴 수 없다. 넷을 **나란히 놓고 Multiport Switch 가 고르게** 하면
> 학생이 캔버스에서 "1·2 는 곱셈 하나, 3·4 는 푸는 것" 이라는 차이 자체를 읽는다.
> 이것이 §5 의 의도에 맞다고 보지만, 예외를 만드는 일이므로 → **§9 질문 5.**

### 각도를 되돌리는 부분은 블록으로 그린다

`atan2` → `Rate Limiter`(`alpha_rlim`) → `Saturation`(`alpha_max`) → 서보,
`sqrt(f_x²+f_y²)` → 추력 → `prop_thrust` 역함수 → 회전수 → `Saturation`(`n_max`,`n_min`).
**여기가 §12-6 의 "자르기" 가 눈에 보이는 자리**이므로 MATLAB Function 에 숨기지 않는다.

### 플랜트 — 중첩으로 횡력을 더한다

`otter.m` 은 프로펠러 **둘**만 받고 그 $\tau$ 의 둘째 성분은 언제나 0 이다.
`quad_tilt` 는 `B(2,:)≠0` 이므로 `cfg.ext_force = true` 이고, `add_otter_plant` 가 포트를 하나
더 만들어 **중첩으로** 더한다 — 6주차 선수추진기가 이미 쓴 방식이다 (`orders-log-4.md` §15-51).
`otter.m` 을 복사해 고치지 않는다.

### `_tools/` — 무엇을 다시 쓰고 무엇을 만드는가

**그대로 쓴다 (고치지 않는다):**
`otter_config.m` · `otter_B.m` · `otter_M.m` · `add_otter_plant.m` · `add_measurement.m` ·
`add_subsys.m` · `add_sum.m` · `gnc_chain.m` · `mss_style.m` · `compact_layout.m` ·
`straighten_lines.m` · `check_overlaps.m` · `check_diagonals.m` · `port_xy.m` · `row_feed.m` ·
`lane_line.m` · `prop_thrust.m` · `run_sim.m` · `track_ships.m` · `draw_ship.m` ·
`live_dash.m` · `live_track.m` · `add_heading_loop.m` · `add_speed_loop.m` · `add_guidance.m` ·
`step_metrics.m` · `crosstrack_err.m` · `verify_constants.m` · `lab_fig.m` · `export_diagram.m`

**새로 만든다 (다섯):**

| 새 파일 | 하는 일 | 왜 함수로 두는가 |
|---|---|---|
| `add_allocation4.m` | 배분 서브시스템을 만든다. 법칙 넷 + 플래그 + 각도 되돌리기 | `add_allocation3.m`(6주차) 와 같은 자리. W11 의 2-추진기 배분도 이 함수의 `cfg` 분기로 쓴다 |
| `alloc_solve.m` | 법칙 3·4 의 몸통. `quadprog` 호출과 쐐기 제약 조립 | 모델과 절 스크립트가 **같은 코드**를 부른다. 두 벌이면 한쪽만 고쳐진다 |
| `tilt_from_f.m` | $f\to(\delta,T,n)$, 한계와 변화율 포함 | 체커가 강의와 **같은 정의**로 재야 한다 (CLAUDE.md §2) |
| `alloc_metrics.m` | $\tau$ RMS 오차 · 위반 횟수 · 자르기 전 최대 \|δ\| · 추력 변화 · 계산시간 | §12-9 과 `W12_check.m` 과 A2 가 같은 함수로 잰다 |
| `verify_w12_allocation.m` | 수식 검증 — 차원·극한·부호·수치·출처 대조 (CLAUDE.md §4-10) | `verify_w07_allocation.m` 와 같은 자리 |

`_tools/tools.md` 에 다섯 줄을 더한다.

---

## 5. 실습 스크립트 — 파일명까지

**강의 절 하나에 스크립트 하나**, 파일명이 강의 순서다. `.m` 과 `.slx` 의 이름이 겹치지 않는다.

```
lectures/W12_simulink/
├── W12_0_setup.m                  학생이 고치는 유일한 파일 — 모든 Constant 변수
├── W12_1_build_scenarios.m        W12_C_scenarios.slx 를 만든다
├── W12_2_build_allocate.m         W12_E_allocate.slx 를 만든다
├── W12_3_build_mission.m          W12_J_mission.slx 를 만든다
├── W12_C_two_commands.m           12-1  Config1/Config2 — 이 주차의 첫 스크립트
├── W12_D_demand_and_actual.m      12-2  tau_demand -> n,delta -> tau_actual 왕복, 과다구동 세기
├── W12_E_the_matrix.m             12-3  B 3x8, 계수, 영공간, 세 가지 부호 규약 표
├── W12_F_minimum_norm.m           12-4  pinv, 한계 끄고 eps_tau = 0, 각도 위반 횟수
├── W12_G_weighted.m               12-5  H_w 닫힌형, W 쓸기, 각도-에너지 교환
├── W12_H_the_limits.m             12-6  모터·서보 한계를 켠다. 자른 뒤 eps_tau != 0
├── W12_I_penalty.m                12-7  벌점, lambda 쓸기
├── W12_J_the_wedge.m              12-8  쐐기 QP, 위반 0
├── W12_K_three_allocators.m       12-9  셋 비교 + 미션 한 구간
├── W12_fig_wedge.m                쐐기 그림의 계산 (figures/src 로 좌표를 낸다)
├── W12_fig_architecture.m         제어기 구조 그림의 좌표 (figures/src 로)
├── W12_vars.m                     같은 값을 struct 로. run_sim 이 하나씩 바꿔 쓴다
├── W12_read.m                     로그를 이름 붙은 필드로
├── W12_plot.m                     StopFcn 과 절 스크립트가 함께 부른다
├── W12_animate.m                  Animate 블록이 매 스텝 부르는 실시간 그리기
├── W12_C_scenarios.slx
├── W12_E_allocate.slx
├── W12_J_mission.slx
├── img/
├── problems/
│   ├── README.md / .pdf
│   ├── W12_P1_start.m             플랜트만 든 시작 모델을 만든다
│   └── W12_check.m
└── solutions/
    ├── README.md / .pdf
    ├── W12_S1_column_rule.m
    ├── W12_S2_minimum_norm.m
    ├── W12_S3_weighted.m
    ├── W12_S4_wedge.m
    └── W12_S_expected.m
```

```
lectures/A2_simulink/
├── A2_0_setup.m
├── A2_C_exact_answer.m            A2-1  fmincon + nonlcon
├── A2_D_the_deadline.m            A2-2  계산시간 분포, p99 · p99.5 · max
├── A2_E_redistributed.m           A2-3  재분배 유사역행렬이 왜 최적이 아닌가
├── A2_F_active_set.m              A2-4  능동집합 반복, 상자 한계
├── A2_G_warm_start.m              A2-5  전 주기 해에서 시작
├── A2_plot.m
├── A2_read.m
├── A2_vars.m
└── img/
```

절 스크립트의 **실행 줄은 45 줄 이하** (`standing-orders.md` §15-15). `animate` 는 절
스크립트에서 0, `W12_0_setup` 에서 1.

---

## 6. 그림 목록

### `figures/` — 개념도 SVG (TikZ 원본은 `figures/src/w12-*.tex`)

| 파일 | 무엇을 그리나 | 주의 |
|---|---|---|
| **`w12-architecture.svg`** | **제어기 구조 두 가지.** 위 칸: `Controller → τ_demand → Control Allocation → n,δ → Dynamics → τ_actual`. 아래 칸: 그 사이에 `Rotation (NED to Body)` 가 들어간 것. 두 칸 사이에 $\varepsilon_\tau=\tau_{\text{demand}}-\tau_{\text{actual}}$ 되돌림 화살표 | **§12-2 의 그림이고 이 주차에서 가장 먼저 그린다.** 사용자 슬라이드를 **TikZ 로 다시 그린다** — 베끼지 않는다. 칸을 둘로 나눠 같은 사슬을 두 번 그리는 §15-41 의 경우다. 슬라이드의 오타 `τ_acutal` 은 고친다. 신호 이름은 모델의 포트 이름과 **글자까지 같게** 한다 |
| `w12-geometry.svg` | 추진기 넷의 위치와 $l_f$·$l_a$·$y_{\text{pont}}$·$T_i$·$\alpha_i$·$\{b\}$ 축 | 사영을 계산해서 그린다. 회전 방향은 오른손 법칙으로 풀어 주석에 적는다 (§4-6-1, §4-6-2) |
| `w12-three-vs-eight.svg` | 명령 3 개에 미지수 3 개(슬라이드) 대 명령 3 개에 미지수 8 개(이번 주차). 전자는 점 하나, 후자는 5차원 해집합 | §12-2. 해집합을 성실하게 그린다 — 2차원 모식으로 줄여 그리고 "5 차원을 2 차원으로 줄여 그린 것" 이라고 적는다 |
| `w12-limits.svg` | 모터 한계(추력 크기 원)와 서보 한계(각도 부채꼴)가 $(f_x,f_y)$ 평면에서 어디를 막는가 | §12-6. `w12-wedge.svg` 와 같은 축·같은 축척으로 그려 두 그림을 겹쳐 읽게 한다 |
| `w12-two-columns.svg` | 기우는 추진기 하나가 **열 둘**을 내는 이유 | A1 의 `a1-column-rule.svg` 와 기호를 맞춘다 |
| `w12-config1-vs-config2.svg` | 같은 회전수, 다른 각도. **칸을 둘로 나눠 같은 화살표를 두 번** 그린다 | `standing-orders.md` §15-41 의 그 경우다. 합력·합모멘트를 치수선으로 |
| `w12-wedge.svg` | $(f_x,f_y)$ 평면의 허용 쐐기 — $\varepsilon$ 선, 두 각도 선, 원형 추력 한계, 버려진 거울 쐐기 | 좌표는 `W12_fig_wedge.m` 가 계산한다. 눈대중 금지 |
| `w12-null-space.svg` | B 3×8, 계수 3, 영공간 5 를 블록으로 | 숫자는 `W12_E_the_matrix.m` 출력에서 온다 |
| `a2-active-set.svg` | 능동집합 반복 한 스텝 — 맞혀 보고 고치기 | |

본문 폭 **186 mm = 703 px**. `svgzoom.sh` 에 `703/폭` 배율을 주어 확인하고, 그림 안 최소 글자는
`\scriptsize`. **고친 뒤에도 다시 렌더해서 본다.**

### `lectures/W12_simulink/img/` — 러너가 저장한다

| 파일 | 무엇 | 어느 스크립트가 낸다 |
|---|---|---|
| `W12_chain.png` | 최상위 블록도 (셋 다) | `W12_1_…` ~ `W12_3_…` + `export_diagram` |
| `W12_allocation_inside.png` | 배분 서브시스템 안쪽 — 법칙 넷이 나란히 | `W12_2_build_allocate.m` |
| `W12_servo_inside.png` | 각도 되돌리기 안쪽 (atan2 → rate → sat) | 같음 |
| `W12_live_view.png` | 실시간 화면 (선체·heading·추진기 화살표 넷) | `W12_animate.m` |
| `W12_result_config1.png` / `…config2.png` | 두 시나리오의 상태응답과 궤적 | `W12_C_two_commands.m` |
| `W12_result_demand_actual.png` | $\tau_{\text{demand}}$ 와 $\tau_{\text{actual}}$ 세 성분을 겹쳐 그리고, 아래 칸에 $\varepsilon_\tau$ | `W12_D_demand_and_actual.m` — **이 주차의 기준 그림**. 이후 모든 결과 그래프가 같은 아래 칸을 갖는다 |
| `W12_result_pinv_angles.png` | 최소노름이 만든 $\delta$ 이력과 ±45° 선 | `W12_F_minimum_norm.m` |
| `W12_result_weight_sweep.png` | 평균 \|δ\| 대 총추력 교환곡선 | `W12_G_weighted.m` |
| `W12_result_clipping.png` | 한계를 켜고 자른 뒤의 $\varepsilon_\tau$ — **처음으로 0 이 아니다** | `W12_H_the_limits.m` |
| `W12_result_wedge.png` | 쐐기 QP 의 $\delta$ 와 $\varepsilon_\tau$ | `W12_J_the_wedge.m` |
| `W12_result_three.png` | 배분기 셋을 $\varepsilon_\tau$ 하나로 견준다 | `W12_K_three_allocators.m` |
| `W12_result_mission.png` | 미션 한 구간의 궤적 (선체와 heading 함께 — `track_ships.m`) | 같음 |

A2 는 `A2_result_timing.png`(계산시간 분포), `A2_result_exact_vs_qp.png`,
`A2_result_warm_start.png`.

**주차마다 블록도 PNG ≥ 1, 결과 그래프 PNG ≥ 1** 이 `.md` 와 `.pdf` 양쪽에 들어간다 (충족).

### `figures/refs/` — 가져온 그림. 이 볼트가 만든 SVG 와 섞지 않는다

| 파일 | 출처 | 어느 절에 |
|---|---|---|
| **`w12-ref-architecture.png`** | 사용자 슬라이드 **"Controller design architecture"** — 위 칸 `[u_d,y_d,ψ_d] → Controller → τ_demand → Control Allocation → n → Dynamics → τ_acutal`, 아래 칸 `[x_d,y_d,ψ_d] → Controller → Rotation (NED to Body) → Control Allocation → …` | **12-2.** 우리 `w12-architecture.svg` **바로 옆**에 두고 범례표 `\| On the slide \|` 를 붙인다. 대응표가 짚을 것 둘 — ① 슬라이드의 `n=[n_1,n_2,n_3]` 는 추진기 셋이고 이번 주차는 $(n_i,\delta_i)$ 여덟이다 ② 슬라이드 오타 `τ_acutal` 은 우리 그림에서 `τ_actual` 로 고쳤다고 한 줄 적는다. **크기는 손대지 않는다** |
| `w12-ref-four-tilt-config.png` | `TiltProp Configuration parameters_250714.pptx`, "4 Tilt Props Configuration" | 12-0. 기호가 다르므로 **첫 자리에 대응표 하나** ($d_1..d_4$ 대 $l_f,l_a,y_{\text{pont}}$) |
| `w12-ref-two-tilt-bow.png` | 같은 슬라이드 왼쪽, "2 Tilt Props and 1 Bow Thruster" | 12-0. 6주차·11주차와의 관계를 한 줄로 |
| `w12-ref-scenarios.png` | `CNU-SHI SHIFT Mini.pptx` 슬라이드 6 — 8 시나리오 표 | 12-1. 범례표 `\| On the slide \|` 를 붙인다 |
| `w12-ref-chain.png` | 같은 PPT 슬라이드 11 — Guidance → Controller → CA → Dynamics | 12-9 |
| `w12-ref-tilt-range.png` | 같은 PPT 슬라이드 15–19 — Case 1 / Case 2, tilting range | 12-6. ±90° 변형이 실습 문제가 된다 |
| `w12-ref-paper-wedge.png` | 논문 Fig. 4 — 허용 쐐기 | 12-8. 우리 `w12-wedge.svg` **옆에** 두고 기호 대응표 |
| `w12-ref-paper-config.png` | 논문 Fig. 3 — 4-azimuth 배치와 모멘트팔 | 12-2 |
| `w12-ref-paper-alloc-chain.png` | 논문 Fig. 24 — $\tau$, 추진기별 $T$, 변화율 제한된 $\delta$ | 12-9 |
| `a2-ref-paper-table10.png` | 논문 Table 10 — 세 배분기 비교 | A2-2. **표는 이미지로 싣지 않고 전사**하는 것이 원칙이므로 (§4) 이 줄은 LaTeX 전사로 대체할 수 있다 → §9 질문 7 |

> [!warning] 교재·논문의 **수식 쪽은 이미지로 싣지 않는다**
> `standing-orders.md` §15-40. PPT 의 `.wmf` 수식 객체와 논문의 수식은 LaTeX 으로 전사한다.
> 위 목록의 ref 는 모두 **그림과 표**다.

---

## 7. 실습 문제와 합격선

문제마다 **강의 절 스크립트가 실제로 잰 수치**가 합격선이다. 체커는 강의와 **같은 정의**로 잰다 —
`tilt_from_f.m` 과 `alloc_metrics.m` 을 체커도 부른다. 도면이 달라도 물리가 같으면 통과한다.

| 문제 | 학생이 하는 일 | 합격선 | 수치를 내는 스크립트 |
|---|---|---|---|
| **P1** | 열 규칙에서 `quad_tilt` 의 B 를 직접 쓴다 | `otter_B('quad_tilt')` 와 원소별 일치, 허용 $10^{-12}$. 계수 3, 영공간 5 | `W12_E_the_matrix.m` |
| **P2** | 유사역행렬 배분을 모델로 만든다 | ① 한계를 끈 채 $\lVert\varepsilon_\tau\rVert_{\text{RMS}}$ 가 강의값 이하 (사실상 0) ② **각도 위반 횟수가 강의값과 일치** (±2 %) | `W12_F_minimum_norm.m` |
| **P3** | 가중을 넣어 평균 \|δ\| 를 강의가 잰 만큼 낮춘다 | 평균 \|δ\| 가 강의값 이하 **이면서** 총추력 증가가 강의값 이하 — **둘 다**. $\varepsilon_\tau$ 는 여전히 강의값 이하 | `W12_G_weighted.m` |
| **P4** | 쐐기 제약을 세워 QP 로 푼다 | ① 위반 **정확히 0** ② $\lVert\varepsilon_\tau\rVert_{\text{RMS}}$ 가 **자르기(12-6)보다 작고** 강의값 이하 ③ $f_x\ge\varepsilon$ 이 모든 샘플에서 참 | `W12_J_the_wedge.m` |
| **P5** | 제어기와 배분을 붙여 한 구간을 주행한다 | 교차추적오차 RMS · 최종 heading 오차가 강의값 이하. 서보 변화율이 `alpha_rlim` 안 | `W12_K_three_allocators.m` |
| **P6** (심화) | 각도 한계를 ±90° 로 바꾸면 무엇이 달라지는가 | 총추력이 강의값보다 작아진다 **그리고** 쐐기가 더 이상 볼록 하나가 아니다를 보인다 | `W12_H_the_limits.m` |

> [!important] 합격선의 **단위가 하나**다 — $\varepsilon_\tau$
> P2·P3·P4 가 모두 같은 양을 재고, 체커는 **로그의 $n,\delta$ 에서 $\tau_{\text{actual}}$ 을 되돌려 계산**해
> 비교한다. 제어기 출력을 다시 읽으면 배분이 틀려도 통과한다 (`W07_check.m` 에서 겪은 것).
> 그래서 `W12_check.m` 의 첫 줄은 **학생 모델의 배분 블록 출력이 아니라 플랜트 입력**을 집는다.

체커는 `W12_check.m` 하나. `W07_check.m` 의 방식을 따른다 — **의도한 추력이 아니라 기록된
회전수와 서보각을 프로펠러 곡선으로 되돌려** 실제 전달된 힘을 다시 계산한다. 그래야 잘못된 역변환이
몰래 통과하지 못한다.

`problems/README.md`·`solutions/README.md` 는 **배포물이므로 PDF 를 함께 내고 영어 정식
어조**로 쓴다 (1·2인칭 금지). 답안지 README 에는 **실제로 돌린 PASS 출력 그대로**.

---

## 8. 참고문헌

### 논문

| | |
|---|---|
| **주 출처** | Bang, H., Thai, B.-H., Ha, J., Yun, Y., Kim, E.-T., Kim, J., Bae, K., Kim, S., Jeong, J., Ozcan, B., Choi, S., Cha, S., **Youn, W.** (2026). "Design and field validation of a LiDAR-guided autonomous berthing framework for a USV: Integrated mission management and guidance." *Ocean Engineering* **365**, 127141. **DOI 10.1016/j.oceaneng.2026.127141** |
| 인용할 곳 | §2.3 Eq (5)–(11) → 12-3·12-8 · Fig. 3 → 12-2 · Fig. 4 → 12-8 · Table 8 → 12-0 · Table 10 → 12-9·A2-2 · Fig. 24 → 12-9 |
| **선행 논문** | Bang, H., Choi, D., Lee, J., Kim, E.-T., **Youn, W.** (2025). "Development and experimental validation of an autonomous USV berthing system with transition logic for multiple berthing maneuver strategies." *Ocean Engineering* **331**, 121333. **DOI 10.1016/j.oceaneng.2025.121333** |
| **능동집합** | Härkegård, O. (2002). "Efficient Active Set Algorithms for Solving Constrained Least Squares Problems in Aircraft Control Allocation." *Proc. 41st IEEE Conference on Decision and Control*, Las Vegas, NV, paper WeA04-5. DOI **확인 필요** (10.1109/CDC.2002.1184694 로 보이나 미확인 → §9 질문 8) |
| 경유 인용 | Johansen & Fossen (2013) 제어배분 개설 · Sørdalen (1997) 아지무스 배분 · Johansen et al. (2008) · Veksler et al. (2014) — **주 출처가 인용한 것**이므로 그 자리에서 그렇게 밝힌다 |

**유도한 자리에 문헌을 적는다 — 직접 유도한 것이라도** (CLAUDE.md §4-10-1). 절 끝의
References 만으로는 부족하다.

### Fossen Handbook

| 절 | 무엇 | 어디서 쓰나 |
|---|---|---|
| §12.3.4 | 확장추력벡터 (extended thrust vector) | 12-3 (A1 §A1-4 가 이미 인용) |
| §12.3 | 제어배분 일반, 유사역행렬 | 12-4 |
| §12.3.2 | 구속 배분, 최적화 문제로서의 배분 | 12-7 |
| §7.x | Otter 의 3자유도 모델과 버린 항 | 12-0 (W01~W05 가 이미 유도) |

### MSS 함수

| 함수 | 쓰는 곳 |
|---|---|
| `otter.m` | 플랜트. 중첩으로 횡력을 더한다 (§4) |
| `ssa.m` | heading 오차 (12-9) |
| `crosstrackHermiteLOS` / `LOSobserver` | 비교용. 직접 만든 것과 대조만 한다 |
| `demoOtterUSVPathFollowingHeadingControl` | 제어기를 블록으로 그리는 근거 (`standing-orders.md` §15-23) |

### 캡스톤 코드 — **참조하되 복사하지 않는다**

| 파일 | 어디서 참조 |
|---|---|
| `OtterModel_tiltProp/otter_model_tilt4_Scenario_Scripts_Config1.m` · `…Config2.m` | **12-1 의 원본.** 8 시나리오와 두 각도 규약 |
| `OtterModel_tiltProp/CA_methods.m` | 12-4·12-7 의 비교 구조, 가중 $W=\mathrm{diag}([1\ 10\ \cdots])$ |
| `OtterModel_tiltProp/CA_methods_WLS.m` | 12-5 의 닫힌형 $H$ 와 $W$ 쓸기 |
| `OtterModel_tiltProp/CA_methods_Soft_Hard_Contraint_WLS.m` | 12-7 과 A2-1 |
| `OtterModel_tiltProp/otter_model_tilt4_CA_Scripts.m` | 플래그로 법칙을 고르는 구조 (§4) |
| `OtterModel_tiltProp/otter_model_tilt4_CA_qcat_Scripts.m` | A2-4 의 QCAT 입력 |
| `OtterModel_titProp_codeset_250805_BHT/MILS/otter_model_tilt4_Control_Scripts_r2.m` | **최종본 MILS.** 12-9 미션 구간의 이득·웨이포인트·LOS 값 |
| `OtterModel_titProp_codeset_250805_BHT/HILS/` | A2-2 의 코드생성·실시간 예산 이야기 (참조만) |

> [!warning] 최종본에 저자 본인의 TODO 가 남아 있다
> `otter_model_tilt4_Control_Scripts_r2.m` 의
> `N_max = -l1*Thrust_max - l2*Thrust_min + l3*Thrust_max; % should be changed (25.07.11) WKY`.
> 이 강의의 포화 한계는 **그 상수로 계산해 둔 모든 한계를 다시 계산한다**는 규칙
> (CLAUDE.md §5 "한계식", W05 §5-7 의 `N_max` 대 `N_speed`) 을 따라 우리가 새로 유도한다.

---

## 9. 모르는 것과 사용자에게 묻는 것

추측으로 메우지 않는다.

| | 질문 | 권고안 |
|---|---|---|
| **1** | **W12 하나 + 부록 A2** 로 가는가, 아니면 W11 (Variant A — Aft Azimuth) 을 버리고 **W11·W12 둘** 다 이 주제로 쓰는가? | **W12 + A2.** W11 의 2-추진기가 영공간 1 의 디딤돌이고, `otter_config` 와 `PLAN.md` 가 이미 그 번호를 쓰고 있다 |
| **2** | 각도 한계가 **±45°** 인가 **±90°** 인가? 논문 Table 4·8 과 `otter_config.m` 은 ±45° (이유: 케이블 간섭과 추진효율), PPT 는 "Maximum tilting angle = ±90 deg" · "Tilting range (-90 ~ 90)" 다 | **±45° 로 가르치고 ±90° 는 실습 P6** 로 둔다. 논문이 물리적 이유를 적어 두었다 |
| **3** | 치수를 논문 실선(1.42 m, $l_f=l_a=0.7$, $d=0.21$, $k_T=3.64\mathrm{e}{-4}$) 으로 할 것인가, 강의 Otter(2.0 m, 1.5/1.0/0.395) 로 할 것인가? | **Otter.** 1~11주차와 같은 선체여야 비교가 정직하다. 논문 수치는 "the paper's own platform" 으로 옆 칸에 인용 |
| **4** | QP 솔버를 **`quadprog`** (Optimization Toolbox, 이미 배정됨) 로 할 것인가, **QCAT** 를 볼트에 들일 것인가? | `quadprog` 를 본줄기로, QCAT 는 **A2-4 에서 알고리즘만** 설명한다. QCAT 는 외부 코드이고 private 저장소에 넣으려면 라이선스를 확인해야 한다 |
| **5** | 배분 법칙 3·4 가 `quadprog` 를 부르는 **MATLAB Function 블록**이 되는 것을 허용하는가? CLAUDE.md §5 "제어기는 서브시스템 안의 시뮬링크 블록, MATLAB Function 한 덩어리로 두지 않는다" 와 충돌한다 | 법칙 1·2 는 **Gain 하나**로 규칙을 지키고, 3·4 만 Function 으로 두어 넷을 **나란히** 놓는다. 그 대비가 교육적이라고 본다. 규칙에 예외를 만드는 일이므로 허가가 필요하다 |
| **6** | 논문 Fig. 3 · Fig. 4 · Fig. 24 · Table 10 과 PPT 슬라이드를 `figures/refs/` 에 실어도 되는가? 본인 논문이지만 판권은 Elsevier 다 | PPT 는 본인 자료이므로 그대로. **논문 그림은 저자 재사용 조항을 확인**하고, 안 되면 ① Table 10 은 LaTeX 전사 ② Fig. 3·4 는 우리 TikZ 로 다시 그려 "after Bang et al. (2026) Fig. 4" 로 표기 |
| **7** | §6 의 `a2-ref-paper-table10.png` 를 이미지로 둘 것인가, **LaTeX 으로 전사**할 것인가? | **전사.** `standing-orders.md` §15-40 이 수식 쪽을 이미지로 싣지 말라고 하고, 표는 전사해야 셀 비교가 된다 |
| **8** | Härkegård (2002) 의 DOI 를 확정해야 한다 (10.1109/CDC.2002.1184694 로 보이나 미확인). CLAUDE.md §4-10-1 이 "논문은 DOI 까지" 를 요구한다 | 쓰기 전에 확인한다. 확인되지 않으면 DOI 없이 회의록 서지로만 적는다 |
| **9** | 논문 안에 서보 변화율 한계가 두 값으로 적혀 있다 — Table 8·§5.3 은 **±1.5708 rad/s (±90°/s)**, 앞쪽 한 군데는 "±2 rad/s (90°/s)" 다 (내부 불일치) | **1.5708 rad/s** 를 쓴다. 90°/s 와 맞고 `otter_config.m` 의 `alpha_rlim` 과도 같다. 강의에서 이 불일치를 언급하지 않는다 |
| **10** | PPT 의 **"2 Tilt Props and 1 Bow Thruster"** 구성도 다루는가? `otter_config.m` 에 없는 다섯 번째 형상이다 | 다루지 않는다. 12-0 에서 `figures/refs/` 그림으로 **보여 주고 한 줄로 가리키기만** 한다 (6주차 선수추진기 + 11주차 아지무스의 조합이다) |
| **11** | 기말 프로젝트(`PLAN.md` 기말 항목, 미착수)가 이 주차를 쓰는가? | 쓴다고 보고 W12 의 Assignment 를 기말의 디딤돌로 설계한다. 다만 기말 명세는 **이 계획의 범위 밖**이다 |
| **12** | 캡스톤 코드의 Config1/Config2 는 $T_{\text{final}}=20$ s, $T_s=0.02$ s 로 돈다. 이 강의의 시뮬레이션 설정을 그대로 쓸 것인가? | 그대로 쓴다. 다만 플랜트가 연속이므로 **적분기는 연속 `Integrator`** 이고 (사용자 지시 2026-09-29), $T_s$ 는 솔버 출력 간격으로만 쓴다 |

### 모르는 채로 남는 것 — 추측하지 않는다

- 논문 Table 10 의 "steering violations 64,540" 이 **몇 샘플 중** 64,540 인지 본문에 없다. 비율로
  환산해 인용할 수 없으므로 **절대수로만** 인용하고, 우리 러너는 비율까지 낸다.
- `CA_methods.m` 의 `W = diag([1 10 1 10 …])` 와 `otter_model_tilt4_CA_Scripts.m` 의
  `diag([1 100 …])` 와 `CA_methods_Soft_Hard_Contraint_WLS.m` 의 `diag([1 1000 …])` 가 다르다.
  어느 것이 최종 선택인지 코드에 적혀 있지 않다. **우리가 쓸어서 고른다** (§12-5 가 그 쓸기다).
- `alpha_rlim` 이 MILS 최종본에서 `deg2rad(180)*1000` (실질적으로 무제한) 로 설정되어 있다.
  의도인지 디버깅 흔적인지 알 수 없다. 강의는 논문 값 1.5708 rad/s 를 쓴다.

---

## 끝내기 절차 (확인 후)

```bash
matlab -batch "cd lectures/W12_simulink; W12_1_build_scenarios; W12_2_build_allocate; W12_3_build_mission; W12_0_setup"
bash _tools/md2pdf.sh lectures/W12_*.md lectures/A2_*.md
bash _tools/md2pdf.sh lectures/W12_simulink/problems/README.md lectures/W12_simulink/solutions/README.md
bash .claude/skills/gnc-lecture-vault/scripts/vault_check.sh
bash _tools/git_autopush.sh
```

`vault_check.sh` 가 **전 항목 0 건**이어야 끝난 것이다. 그 전에는 올리지 않는다.
