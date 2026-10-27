# 계획 · 설계 결정과 환경 (`PLAN.md` §5 · §6)

> [!note] 이 파일은 `PLAN.md` 에서 갈라져 나온 것이다
> 계획의 **원본과 색인은 `PLAN.md`** 다. 이 파일이 담는 것은 §5 **플랜트 구조**
> (`otter_config` · `add_otter_plant` · 추력 배분의 부호 규약) 와 §6 **환경**
> (MATLAB 판·MSS 경로·PDF 도구) 이다. § 번호는 바꾸지 않았다 — 가리키는 쪽이
> `PLAN.md §5` · `§6` 으로 가리키기 때문이다.

---

## 5. 플랜트 구조 — 이 설계의 핵심 결정

`otter.m` 은 `numel(n) == 2` 를 강제하므로 W11~W12 에 그대로 못 쓴다.
네 번 복사하는 것은 **틀린 답**이다. 파라미터화된 플랜트 하나를 쓴다.

```matlab
cfg = otter_config('base' | 'aft_azimuth' | 'bow_thruster' | 'quad_tilt');
add_otter_plant(mdl, 'Otter plant', pos, cfg);
```

- 선체 유체동역학(`M`, `C_A`, `C_RB`, 교차흐름 감쇠, 복원력, $N_h = N_r(1+10|r|)r$)은
  **네 형상에서 한 글자도 다르지 않다.** 그래야 비교가 정직하다
- 바뀌는 것은 `B`, 추진기 개수, 틸팅 여부, 방위각 한계뿐이다

> [!warning] 부호 규약 함정
> 이 프로젝트에는 **정확히 부호가 반대인 `B` 가 둘** 산다 —
> `Lecture/_tools/otter4_B.m` 과 `otter_params.m` 41행. 둘 중 어느 것도 가져오지 않는다.
> **부록 A1 의 열 규칙이 유일한 정의**이며, 모든 `B` 를 `_tools/otter_B.m` 이 거기서 유도한다.
>
> ```
> (x, y) 에 있고 방향이 e 인 추진기의 열 =  [ e_x ; e_y ; x·e_y − y·e_x ]
> ```

---

## 6. 환경

- MATLAB **R2024b** + Simulink (+ Stateflow: W09, Optimization Toolbox: W07·W12)
- MSS 는 `10_연구_USV_MILS/Proj_SHI_USV_MILS/Tools/MSS` — `_tools/mss_path.m` 이 찾는다
- **문서 PDF 파이프라인은 Git Bash + Chrome 뿐이다. pandoc 없음** — `md2pdf.sh` 는
  MathJax 를 브라우저에서 돌린다. 이건 안 바뀐다
- **그림용으로만** TinyTeX 을 넣었다 (2026-09-05, 사용자 승인). `%APPDATA%\TinyTeX`,
  TeX Live 2026 + `pgf`(TikZ) + `standalone` + `dvisvgm`.
  `_tools/tikz2svg.sh` 이 `figures/src/*.tex` → `figures/*.svg` 로 바꾼다.
  **문서 파이프라인은 이것을 쓰지 않는다** — 결과물은 그냥 SVG 라 Chrome 이 읽는다
- 2026-09-05 로 **개념도 20장 전부**가 TikZ 원본을 갖는다. 손으로 쓴 SVG 는 없다.
  3차원 그림의 기하는 MATLAB 이 계산하고(`_tools/w01_euler_R.m`), 사영은 TikZ 가 한다.
  `_tools/svgzoom.sh` 로 잘라 확대해서 라벨 겹침을 확인한다 →
  `results-and-figures.md` §2-8·§2-9
