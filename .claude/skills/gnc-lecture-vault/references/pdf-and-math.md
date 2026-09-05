# PDF 와 수식

## 1. PDF — 이 한 줄이 전부다

```bash
bash _tools/md2pdf.sh 10-주차별-강의자료/W0*.md
```

- 인터넷 불필요. `_tools/marked.min.js` + `_tools/mathjax-tex-svg.js` 로컬 사본 사용
- 서식 기준은 `_tools/pdf-template.html` 의 `<style>` **하나**
- 성공 시 `[OK] 파일명 NNN KB`, 실패 시 원인까지 출력한다
- 쪽수 확인이 필요하면 그 뒤에

```bash
python -c "import sys,re;d=open(sys.argv[1],'rb').read();print(len(re.findall(rb'/Type\s*/Page[^s]',d)))" 파일.pdf
```

> [!warning] Chrome 은 Windows 실행 파일이라 POSIX 경로를 못 읽는다
> 스크립트가 `cygpath -w` (출력) / `cygpath -m` (입력 URL) 로 변환해 넘긴다.
> Chrome 을 새로 호출하는 코드를 추가할 때도 같이 처리할 것.

### 실패할 때

| 증상 | 원인 | 조치 |
|---|---|---|
| `갱신되지 않음` + `0x20` | PDF 뷰어가 파일을 열고 있음 / Dropbox 동기화 중 | 뷰어를 닫고 재실행. 스크립트가 3회 재시도한다 |
| 수식이 `$…$` 그대로 | MathJax 가 늦게 끝남 | 템플릿의 `data-ready` 와 `--virtual-time-budget` 을 건드리지 말 것 |
| 그림이 빠짐 | 상대경로가 MD 위치 기준이 아님 | 임시 HTML 은 **MD 와 같은 폴더**에 만들어진다. 경로를 그에 맞춘다 |

---

## 2. 수식 — MathType 이 아니라 LaTeX

> [!important] 별도 도구가 필요 없다
> LaTeX 으로 쓰면 **Obsidian · GitHub · PDF 세 곳에서 모두** 렌더된다.
> PDF 는 로컬 MathJax 3 (`tex-svg-full`) 이 SVG 로 조판한다. 이미지 파일을 만들지 않는다.

- 인라인 `$y_e$`
- 블록

```markdown
$$
\psi_{\text{ref}} = \pi_p - \arctan\!\left(\frac{y_e}{\Delta}\right)
$$
```

- 여러 줄은 `aligned`

```markdown
$$
\begin{aligned}
m\,\dot{u} &= X - (X_u + X_{uu}|u|)\,u + m\,v\,r \\
I_z\,\dot{r} &= N - (N_r + N_{rr}|r|)\,r
\end{aligned}
$$
```

### 쓸 때의 판단

| 상황 | 형식 |
|---|---|
| 긴 유도, 기호 정의 | 블록 수식 |
| 코드에 **그대로** 쓰이는 식 | 코드블록 (```matlab) |
| 둘을 섞기 | 하지 않는다. 학생이 어느 쪽을 옮겨 적어야 할지 모른다 |

- 기호를 쓴 뒤에는 **기호 표**를 붙인다 (기호 / 값 / 출처)
- 값의 출처는 파일명까지 적는다 — `wamv_gazebo_dynamics_plugin.xacro`

---

## 3. 템플릿이 하는 일 (고치기 전에 읽을 것)

`pdf-template.html` 의 변환 순서. **순서가 전부다.**

```
1) 코드블록 ``` … ```  →  @C0@ 로 빼둔다
2) 인라인 코드 ` … `   →  @C1@ 로 빼둔다
3) 블록 수식 $$ … $$   →  @M0@ 로 빼둔다
4) 인라인 수식 $ … $   →  @M1@ 로 빼둔다
5) @C…@ 를 코드로 되돌린다
6) marked() 로 마크다운 → HTML
7) @M…@ 를 수식 원문으로 되돌린다 (HTML 이스케이프)
8) MathJax.typesetPromise() → 끝나면 data-ready="1"
```

이 순서 때문에 생기는 좋은 결과 두 가지:

- `$HOME`, `$(pwd)` 가 **수식으로 잡히지 않는다** (1·2단계에서 이미 빠졌으므로)
- `y_e` 의 밑줄이 **강조로 해석되지 않는다** (marked 가 수식을 보지 못하므로)

### 템플릿 지뢰

| 증상 | 원인 | 조치 |
|---|---|---|
| `Can't load "/input/tex/extensions/boldsymbol.js"` | MathJax 축약 빌드는 확장을 원격에서 받는다 | **`tex-svg-full.js`** 를 쓴다 |
| 파일이 갑자기 "binary" 로 잡힘 | Edit 도구가 NUL 문자를 삽입 | `tr -d '\000'` 로 제거 후 재확인 |
| 수식 번호가 붙음 | `tags` 기본값 | 설정이 `tags:"none"` 이다. 바꾸지 말 것 |
| 마커를 찾을 수 없음 | `<!--MDCONTENT-->` `<!--MATHJAXJS-->` `<!--MARKEDJS-->` 중 하나가 사라짐 | 세 마커는 `md2pdf.sh` 가 템플릿을 4등분하는 기준이다. 지우지 말 것 |

---

## 4. Obsidian 쪽 확인

- 수식은 Obsidian 에서도 그대로 보인다. 별도 플러그인 불필요
- 다만 **Obsidian 전용 문법(`![[파일]]`)은 쓰지 않는다** — VSCode·GitHub 에서 깨진다
- 그림은 항상 표준 마크다운 `![설명](../figures/x.svg)`
