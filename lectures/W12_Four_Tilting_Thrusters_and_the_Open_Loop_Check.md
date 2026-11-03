---
type: week
week: 12
title: Week 12 — Four Tilting Thrusters, and the Open-Loop Check
date: 2026-11-03
tags: [week, otter, tilting-thruster, thrust-configuration, open-loop, verification, simulink]
status: draft
summary: Four tilting thrusters replace the Otter's two fixed ones — what the change costs the motion model, what eight hand-given numbers do to the hull, and the three asymmetries that make the symmetric guess wrong
---

# Week 12 · Four Tilting Thrusters, and the Open-Loop Check

> [!note] Recordings of this semester's own classes
> <span style="font-size:0.88em">Every session of this course is recorded as it is given and posted to the playlist below. The written material here is the reference; the recording is the lecture, at the pace it was actually delivered. Use it to review a derivation, or to catch up on a missed week before the laboratory.</span>
>
> | | Where |
> |---|---|
> | **[충남대] 2026 센서신호처리** — this course, recorded live, 2026 | [playlist](https://youtube.com/playlist?list=PLCxINRGlWUrk) |

> [!important] Reference material — read this first
> <span style="font-size:0.88em">The five courses below are **taught by the instructor of this course** and are the assumed background for it. They run from the fundamentals down to the graduate material, so start wherever the gap is. Every frame, symbol and derivation used here is developed in them at length; anyone whose prerequisites are thin should work through them first, then return.</span>
>
> | # | Course | Level | Lang. | Video | Slides and code |
> |---|---|---|---|---|---|
> | 1 | **Control Engineering** (제어공학) — the foundation: transfer functions, feedback, stability, root locus, PID | undergraduate | KO | [playlist](https://youtube.com/playlist?list=PLFaUxNRM4BvJMpF9HZS-Mp8tDv9dTdglk) | [drive](https://drive.google.com/drive/folders/1TNIPDNtS_Iy8li-olka5WJslSXDYf0aT) |
> | 2 | **Control System Design** (제어시스템설계) — design rather than analysis: specifications, loop shaping, discrete implementation | undergraduate | KO | [playlist](https://youtube.com/playlist?list=PLFaUxNRM4BvIGroZ5rgn7x08F7C79d9WZ) | [drive](https://drive.google.com/drive/folders/11m5Xxl_PHJvxgHghLSP-jhCpmRpbvoXh) |
> | 3 | **Advanced Control Engineering** (제어공학특론) — reference frames, the 6-DOF equation of motion, rotation matrices and Euler angles, linearisation and trim, vehicle control design | graduate | EN | [playlist](https://youtube.com/playlist?list=PLFaUxNRM4BvJmvF2ljx4KM5dj1P5jEcw0) | [drive](https://drive.google.com/drive/folders/1GUxbbONl916lNd0ggnFnXrNwNkd13-2-) |
> | 4 | **Sensor Signal Processing and Fusion** (센서신호처리 및 융합) — sensor models, noise, estimation and multi-sensor fusion | graduate | EN | [playlist](https://youtube.com/playlist?list=PLFaUxNRM4BvK-aP2Gdoyp5-AWvMn7Fo8E) | [drive](https://drive.google.com/drive/folders/1MEVJP7TzMcm8w6TZwUjhWJtL34WeNY3u) |
> | 5 | **Capstone Design** (캡스톤디자인) — a vehicle project carried end to end | undergraduate | KO | [playlist](https://youtube.com/playlist?list=PLFaUxNRM4BvLu7L0pDoLzDXTv8mm6rCmj) | [drive](https://drive.google.com/drive/folders/1haIQejlJfrdhtOuof-MpffR9ydVscXZS) |
>
> <span style="font-size:0.88em">**Not fluent in MATLAB or Simulink yet? Do these before Part 2.** Every laboratory in this course is Simulink, and the Onramp courses are free and take a few hours each.</span>
>
> | Tool | Where to start |
> |---|---|
> | MATLAB | [MATLAB Onramp](https://matlabacademy.mathworks.com/kr/details/matlab-onramp/gettingstarted) · [Core MATLAB Skills](https://matlabacademy.mathworks.com/details/core-matlab-skills/lpmlcms) |
> | Simulink | [Simulink Onramp](https://matlabacademy.mathworks.com/kr/details/simulink-onramp/simulink) · instructor's Simulink lectures [part 1](https://youtu.be/a-afHg_fSaU) · [part 2](https://youtu.be/070Yn0Hw5a0) |


> [!tip] Getting the course files, and keeping them current (Windows)
> <span style="font-size:0.88em">The notes, models and scripts are kept in one Git repository that is updated through the semester. Clone it once; before every class, pull. A pull downloads only what has changed since the last one.</span>
>
> | When | Where to run it | Command |
> |---|---|---|
> | once | PowerShell — installs Git for Windows | `winget install --id Git.Git -e` |
> | once | the folder that will hold the course, e.g. `Documents` | `git clone https://github.com/wkyouncnu/Sensor-Signal-Processing-and-Fusion.git` |
> | before every class | inside the cloned folder `Sensor-Signal-Processing-and-Fusion` | `git pull` |
>
> - `git pull` prints `Already up to date.` when nothing has changed, and otherwise lists the files it updated.
> - The repository is private. When Git asks, sign in with the GitHub account the instructor has given access.
> - Experiment on copies, not on the cloned files: copy a week's `WXX_simulink` folder elsewhere first, and a pull can never collide with local edits. If it already has, `git stash`, then `git pull`, then `git stash pop` sets the edits aside, updates, and puts them back.
> - The MSS toolbox is not part of the repository. The weeks that simulate the Otter need it at `Tools\MSS` inside the cloned folder, and `_tools\mss_path.m` finds it there in either release layout — `Tools\MSS\VESSELS\otter.m` in the older releases, or `Tools\MSS\CRAFT\USV\models\otter.m` in the current master.
> - **The two releases are not the same vessel.** The figures printed in these notes were measured with the older layout. Terminal surge speed agrees at 1.0286 m/s, but the current master turns 25.5 % faster under differential thrust, 0.1276 rad/s against 0.1017 rad/s. `mss_path` therefore prefers the older layout when both are present, and warns when only the newer one is available, so a reading that cannot reproduce is announced rather than silent.
> - **A 118 MB folder disappears on the first pull after 2026-10-27.** `lectures\MSS-master` held a copy of MSS until then. It sat outside `Tools\MSS`, so no course script could reach it, and it only made cloning slower. Its removal is expected and is not a fault. Any file kept inside that folder must be moved elsewhere before pulling.


- **Course**: USV Guidance, Navigation and Control (Graduate)
- **Department**: Autonomous Vehicle System Engineering, Chungnam National University
- **This week**: ① a tilting thruster occupies **two** columns of $B$, not one ② the four places `otter.m` must change to carry four of them ③ eight numbers given by hand, and the three asymmetries that make the symmetric guess wrong

> [!important] Before starting
> - Week 3's column rule must be available from memory: a thrust applied at a point contributes one column to $B$, and the rule that builds that column is the only definition of $B$ this course uses.
> - Week 6's change to the motion model must be understood as a change to the **model**, not an addition to its input. `otter_bow.m` carries the bow thrust inside $\boldsymbol{\tau}$; this week does the same thing for four tilting units.
> - Verify both in one command: `cd lectures/W06_simulink; W06_0_setup` must print the three-thruster configuration without error, and `verify_otter_bow` must print `PASS`.

---

## Learning Outcomes

Upon completion of this week, the learner is able to:

1. State the column rule for a thrust applied at $(x_i, y_i)$, and show from it that a fixed thruster occupies one column of $B$ while a tilting thruster occupies two.
2. Write the generalised force of four tilting thrusters as $\boldsymbol{\tau} = B\mathbf{f}$ with $B \in \mathbb{R}^{3\times 8}$, state its rank and the dimension of its null space, and confirm that $\delta_i = 0$ recovers the two-thruster expression of `otter.m` exactly.
3. Identify the four places in `otter.m` that must change to carry four tilting units, and state why the hull hydrodynamics are not among them.
4. Predict the surge force left over when a shaft speed $+n$ is opposed by $-n$, compute the astern speed that cancels it, and confirm both against the measured table.
5. Derive $N = \bar{x}\,Y$ with $\bar{x} = (l_f - l_a)/2$ for four equally tilted thrusters, predict the residual yaw moment of a symmetric sway command to three decimal places, and derive the thrust ratio that removes it.
6. Distinguish a check that the equations are right from a check that the model is wired to those equations, and state why re-integrating the logged inputs outside Simulink is the second of these while a single-instant acceleration comparison is neither.
7. State what this week deliberately leaves out, and why the three measured asymmetries make an allocation necessary rather than optional.

## Prerequisites and Setup

| Item | Requirement |
|---|---|
| MATLAB | R2024b or later, with Simulink |
| MSS toolbox | reachable at `Tools\MSS`; `_tools\mss_path.m` adds it |
| Weeks assumed | Week 3 (the column rule and $B$), Week 5 (saturation and limits), Week 6 (changing the motion model itself) |
| Plant | `_tools\otter_tilt4.m` — `otter.m` with four tilting units, same hull |
| Configuration | `otter_config('quad_tilt')` |
| Model | `W12_openloop.slx`, written by `W12_1_build_openloop.m` |
| Solver | fixed-step `ode4`, $h = 0.02$ s |
| Scope of this week | **open loop only.** No allocation, no controller, no guidance |

---

# Part 1 · Principle and experiment, section by section

Every section states what is observed, says what follows from it, and then runs **the experiment that measures it**, on its own model. The numbers quoted in the text are printed by the run a few lines below it.

| Part of a section | What it holds |
|---|---|
| **What is observed** | the effect itself, with the numbers it produces |
| **What follows from it** | numbered lines, one step each |
| **Experiment 12-x** | the model, the commands, the output actually obtained, the figure, and a table that reads every feature of the figure back to **the numbered line that predicts it** |

## 12-0. Setting up (10 min)

```matlab
cd lectures/W12_simulink
W12_1_build_openloop          % once — writes W12_openloop.slx and img/*.png
W12_0_setup                   % every session — defines every constant
```

`W12_1_build_openloop` prints one line, and both counts must be zero:

```
  W12_openloop   overlaps 0   diagonals 0
```

`W12_0_setup` prints the configuration this week works in:

```
  Week 12  four tilting thrusters, open loop
    thruster stations   x = [+1.50 +1.50 -1.00 -1.00] m
                        y = [-0.395 +0.395 -0.395 +0.395] m
    servo limit         +45 deg,  rate 90 deg/s
    shaft limits        -101.737 .. +103.931 rad/s
    thrust at +-60      +39.888 N ahead, -23.202 N astern   (k_neg/k_pos = 0.5817)
    cancelling astern    -78.670 rad/s, not -60
    B                   3 x 8, rank 3, null space 5
    command             n = [60 60 60 60] rad/s
                    delta = [45 45 45 45] deg
```

Four lines of that block are the week in miniature. The shaft limits are not symmetric, the two thrust coefficients are not equal, $B$ has five more columns than rows, and the astern speed that cancels $+60$ rad/s is not $-60$.

> [!warning] The shaft command is in rad/s, not rpm
> `n_cmd = [60 60 60 60]` is 60 radians per second, about 573 rpm. `otter.m` has always used rad/s and `otter_tilt4.m` keeps that, because the thrust coefficients $k_{pos}$ and $k_{neg}$ are quoted against it. Entering 600 expecting rpm asks for 5730 rpm, and the model saturates it to 103.931 rad/s.

## 12-1. Four thrusters, and a direction that is no longer given

This section answers: what does a tilting thruster change about the allocation matrix, before any allocation is attempted?

**What is observed.** Experiment 12-1 reports that `otter_tilt4` reduces to `otter` when every tilt angle is zero, that its own $\boldsymbol{\tau}$ agrees with $B\mathbf{f}$ to $1.06\times10^{-13}$ over 200 random states, and that $B$ is $3\times 8$ with rank 3.

- the hull has four thrust stations, two at $x_b = +1.50$ m and two at $x_b = -1.00$ m, each $0.395$ m off centreline
- each unit turns through $\pm 45^\circ$ at up to $90^\circ$/s
- eight numbers are commanded; three components of force result

**The result.** A thrust of magnitude $T_i$ applied at $(x_i, y_i)$ along the unit vector $\mathbf{e}_i$ contributes the column

$$
\mathbf{b}_i \;=\; \begin{bmatrix} e_{ix} \\[2pt] e_{iy} \\[2pt] x_i e_{iy} - y_i e_{ix}\end{bmatrix},
\qquad
\mathbf{e}_i \;=\; \begin{bmatrix}\cos\delta_i \\[2pt] \sin\delta_i\end{bmatrix}
$$

and because $\delta_i$ is now commanded rather than fixed, the pair $(T_i, \delta_i)$ carries two independent numbers. Writing them in Cartesian form as $\mathbf{f}_i = T_i\mathbf{e}_i = [\,f_{ix}\;\;f_{iy}\,]^{\mathsf T}$ makes the force linear in the unknowns:

$$
\boldsymbol{\tau} \;=\; \begin{bmatrix} X \\ Y \\ N \end{bmatrix} \;=\; B\,\mathbf{f},
\qquad
\mathbf{f} = \begin{bmatrix} f_{1x} & f_{1y} & \cdots & f_{4x} & f_{4y}\end{bmatrix}^{\mathsf T}
$$

$$
B \;=\;
\begin{bmatrix}
1 & 0 & 1 & 0 & 1 & 0 & 1 & 0 \\
0 & 1 & 0 & 1 & 0 & 1 & 0 & 1 \\
0.395 & 1.5 & -0.395 & 1.5 & 0.395 & -1.0 & -0.395 & -1.0
\end{bmatrix}
$$

| Symbol | Quantity | Value · source |
|---|---|---|
| $x_i$ | longitudinal station of unit $i$ | $+1.50, +1.50, -1.00, -1.00$ m — `otter_config.m:71-73` |
| $y_i$ | transverse station of unit $i$ | $-0.395, +0.395, -0.395, +0.395$ m — same |
| $\delta_i$ | tilt angle, from $x_b$ towards $y_b$ | commanded, clipped to $\pm 45^\circ$ |
| $T_i$ | thrust magnitude of unit $i$ | $k_{pos}n_i\lvert n_i\rvert$ or $k_{neg}n_i\lvert n_i\rvert$ |
| $f_{ix}, f_{iy}$ | body-frame components of that thrust | $T_i\cos\delta_i$, $T_i\sin\delta_i$ |
| $B$ | allocation matrix | $3\times 8$, rank 3 — built by `_tools/otter_B.m` from the column rule |
| $l_f, l_a$ | forward and aft moment arms | $1.50$ m, $1.00$ m — `otter_config.m:72-73` |

**Derivation, one line at a time.**

1. The horizontal force–moment triple produced by a planar force $\mathbf{f} = [\,f_x\;\;f_y\,]^{\mathsf T}$ applied at $(x, y)$ in body axes is $[\,f_x,\;f_y,\;x f_y - y f_x\,]^{\mathsf T}$. This is Week 3's column rule, and it is the only definition of $B$ this course uses.
2. For a **fixed** thruster, $\mathbf{e}_i$ is a constant of the hull. The single unknown is $T_i$, so the rule returns one column, and four fixed thrusters give $B \in \mathbb{R}^{3\times 4}$.
3. For a **tilting** thruster, $\mathbf{e}_i = \mathbf{e}_i(\delta_i)$. The map $(T_i, \delta_i) \mapsto (f_{ix}, f_{iy})$ is the polar-to-Cartesian map, invertible wherever $T_i > 0$, so the unit has two independent degrees of freedom.
4. Applying line 1 to each of $f_{ix}$ and $f_{iy}$ separately gives the two columns $[1, 0, -y_i]^{\mathsf T}$ and $[0, 1, x_i]^{\mathsf T}$. Four units therefore give $B \in \mathbb{R}^{3\times 8}$, as printed above.
5. $B$ has rank 3: rows 1 and 2 are linearly independent by inspection, and row 3 is not a combination of them because $x_i$ and $y_i$ are not all zero. Its null space has dimension $8 - 3 = 5$.
6. Five dimensions of null space mean five independent ways to change the eight numbers without changing the force on the hull. That freedom is what an allocator would spend, and spending it is not this week's subject.
7. Substituting $f_{ix} = T_i\cos\delta_i$ and $f_{iy} = T_i\sin\delta_i$ back into $B\mathbf{f}$ gives the form the motion model actually evaluates:

$$
X = \sum_{i=1}^{4} T_i\cos\delta_i,
\qquad
Y = \sum_{i=1}^{4} T_i\sin\delta_i,
\qquad
N = \sum_{i=1}^{4}\bigl(x_i T_i\sin\delta_i - y_i T_i\cos\delta_i\bigr)
$$

8. Setting every $\delta_i = 0$ kills every sine. $Y$ vanishes, and $N$ reduces to $-\sum y_i T_i$ — the differential-thrust yaw of `otter.m`, with the four stations in place of two. The new model must therefore contain the old one as a special case, and Experiment 12-1 checks exactly that.

![The four stations, the tilt angle, and why one tilting unit owns two columns of B](../figures/w12-tilt-geometry.svg)

| In the figure | Meaning |
|---|---|
| two shaded rectangles | the two pontoons of the $L = 2.0$ m hull, $y_{pont} = 0.395$ m off centreline |
| four numbered circles | the four thrust stations, drawn where they sit on the pontoons |
| four identical arrows | $T_i\mathbf{e}_i$ with all four $\delta_i$ equal; only unit 1 carries the angle annotation |
| $\delta_1$ arc, clockwise from the dashed $\parallel x_b$ line | the sense of a positive tilt: from $x_b$ towards $y_b$ |
| $\tau_N > 0$ arc at the origin, clockwise | a positive yaw moment turns the bow to starboard, because $z_b$ points down |
| $l_f = 1.50$ m dimension reaching past the bow | the **moment arm** of the forward pair, not a place on the hull |
| $l_a = 1.00$ m dimension | the aft arm, which coincides with the transom |

> [!note] Read the arms, not the hull stations
> `otter_config.m` carries $l_f = 1.50$ m on a hull $2.0$ m long, so the forward arm reaches $0.5$ m beyond the bow. It is an arm in the moment balance, and the same constant is shared with Week 6's bow thruster, so it cannot be changed on one side alone. The figure therefore draws the units on the pontoons and shows $l_f$ as a dimension line only.

### Experiment 12-1 · The new model contains the old one (15 min)

**What it measures.** Lines 1, 7 and 8 of the derivation: that the column rule and the trigonometric form agree, and that $\delta = 0$ returns `otter.m`.

**The model.** None. `verify_otter_tilt4` calls `otter_tilt4` and `otter` directly, over 200 random states, so the check is on the equations and not on any wiring.

**Opening and running.**

```matlab
verify_otter_tilt4            % 네 가지 항등식 / four identities
```

Expected output:

```
  verify_otter_tilt4
    stations   x = [+1.50 +1.50 -1.00 -1.00] m
               y = [-0.395 +0.395 -0.395 +0.395] m
    tilt limit +-45 deg each
    B          3 x 8, rank 3, null space 5

  (a) aft pair, delta 0  == otter.m       :  0.00e+00
  (b) fore pair, delta 0 == otter.m       :  0.00e+00
  (c) tau                == otter_B * f   :  1.06e-13
  (d) saturation clamps n AND delta       :  0.00e+00

  thrust at +-60 rad/s   +39.888 N ahead, -23.202 N astern  (k_neg/k_pos = 0.5817)
  cancelling astern speed   -78.670 rad/s   (not -60)
  limits                   -101.737 .. +103.931 rad/s

  PASS  (tol 1e-09, 200 random states)
```

**Reading the output against the derivation.**

| Where to look | What is there | Which line predicts it |
|---|---|---|
| `(a)` and `(b)` | exactly zero, not merely small | line 8 — with $\delta = 0$ the new code evaluates the same arithmetic as `otter.m`, in the same order |
| `(c)` | $1.06\times10^{-13}$ over 200 random states | line 7 — the trigonometric form and $B\mathbf{f}$ are the same expression, differing only in floating-point order |
| `(d)` | zero | the model clips **both** $n$ and $\delta$, so a command outside the envelope is received at the envelope |
| `rank 3, null space 5` | printed, not asserted | lines 5 and 6 |

**What the output says**

- The four-unit model is a strict extension: nothing in it can change the behaviour the first eleven weeks measured.

| What to try | What to watch |
|---|---|
| `verify_otter_tilt4` twice in a row | `(c)` changes in the last digits and `(a)`, `(b)`, `(d)` do not — the random states feed only the $B\mathbf{f}$ comparison |

> [!tip] In class
> - **Purpose** — fix the idea that a tilting unit is two unknowns, not one with a twist.
> - **Point to** — the third row of $B$: the first entry of each pair is $-y_i$, the second is $+x_i$, and the sign difference is the whole of the column rule.
> - **Ask** — "Eight unknowns and three equations. How many solutions?" Five dimensions of them, which is why an allocator is a choice and not a calculation.
> - **Take away** — `otter_tilt4` with $\delta = 0$ **is** `otter`, to the last bit.

## 12-2. What had to change inside the motion model

This section answers: which lines of `otter.m` carry the thruster configuration, and which lines carry the hull?

**What is observed.** `_tools/otter_tilt4.m` is MSS `otter.m` copied and changed in four places, each marked in the file with `% ---- CHANGED (i of 4)`. The four marks sit in the same four places as Week 6's `otter_bow.m`.

- the rigid-body and added-mass matrices, the Coriolis terms, the restoring forces, the linear and cross-flow damping, the nonlinear yaw damping $N_h = N_r(1 + 10\lvert r\rvert)r$ and the kinematics are character-for-character identical
- the hull is the same hull, and the file has to show that

**The result.** Four changes, and nothing else.

| | `otter.m` | `otter_tilt4.m` | Why |
|---|---|---|---|
| 1 · input check | `length(n) ~= 2` | `length(n) ~= 4` and `length(delta) ~= 4`, plus an eighth argument `quad` | the configuration arrives as data, so the stations and tilt limits are not hard-coded in the plant |
| 2 · thruster data | $l_1$, $l_2$ | `px`, `py`, `d_max` read out of `quad`; $l_1$ and $l_2$ no longer used | with four stations a pair of signed arms is not enough; the $(x_i, y_i)$ pairs are written out |
| 3 · thrust loop | `for i = 1:1:2`, $n$ saturated | `for i = 1:1:4`, $n$ **and** $\delta$ saturated | derivation line 3 below — the servo is part of the vessel, not of the controller |
| 4 · the force vector | `tau = [T1+T2  0  0 0 0  -l1*T1-l2*T2]'` | three accumulators filled by the column rule | derivation lines 4 to 6 — rows 1, 2 and 6 all carry every unit |

**Derivation, one line at a time.**

1. The propellers are unchanged. $k_{pos} = 0.02216/2$ and $k_{neg} = 0.01289/2$ stay at the values `otter.m` sets, because the same propeller is fitted four times rather than twice.
2. The shaft limits are therefore also unchanged: $n_{max} = +103.931$ rad/s and $n_{min} = -101.737$ rad/s, derived in `otter.m` from the maximum thrust each way.
3. The tilt servo belongs inside the plant. A servo that refuses $70^\circ$ refuses it whatever asked, so the clip must be in the motion model; a clip placed only in the controller would let a mis-wired command produce a force the vessel cannot make.
4. `otter.m` writes its $\boldsymbol{\tau}$ as a literal six-row vector because two fixed thrusters produce only two of the six rows. With four tilting units every unit contributes to rows 1, 2 and 6 at once, so the literal is replaced by three accumulators.
5. Each pass of the loop evaluates one column of the pair derived in §12-1 line 4, then adds its contribution: $f_x$ into row 1, $f_y$ into row 2, and $x_i f_y - y_i f_x$ into row 6.
6. Rows 3, 4 and 5 stay zero. No thruster on this vessel acts in heave, roll or pitch, and the trim moment that does act in pitch is applied elsewhere in the file, exactly as in `otter.m`.

The third change, with the servo clip in it:

```matlab
% ---- CHANGED (3 of 4) ---------------------------------------------------
% Control forces and moments - with propeller revolution saturation
% 루프가 2 회에서 4 회로 늘고, **각도도 함께 포화된다.** 서보가 ±45 도까지만
% 돌아가므로 그보다 큰 각을 지시해도 모델은 ±45 도로 받는다. 회전수의 포화는
% otter.m 과 같은 줄이다 — 같은 프로펠러이기 때문이다.
% The loop runs four times, and the ANGLE saturates too: the servo turns only to
% +-45 deg, so a larger command is received as +-45 deg. The shaft-speed
% saturation is the same code as otter.m, because they are the same propellers.
Thrust = zeros(4,1);
for i = 1:1:4
    if n(i) > n_max                     % saturation, physical limits
        n(i) = n_max;
    elseif n(i) < n_min
        n(i) = n_min;
    end

    if n(i) > 0
        Thrust(i) = k_pos * n(i)*abs(n(i));   % positive thrust (N)
    else
        Thrust(i) = k_neg * n(i)*abs(n(i));   % negative thrust (N)
    end

    if delta(i) > d_max(i)              % saturation, the tilt servo
        delta(i) = d_max(i);
    elseif delta(i) < -d_max(i)
        delta(i) = -d_max(i);
    end
end
% -------------------------------------------------------------------------
```

The fourth change, which is the column rule written as code:

```matlab
% ---- CHANGED (4 of 4) ---------------------------------------------------
% Control forces and moments
% otter.m:  tau = [T1+T2  0  0 0 0  -l1*T1 - l2*T2]'      <- sway is zero
% here:     every tilting thruster contributes to rows 1, 2 and 6 at once,
%           by the column rule  [e_x ; e_y ; x e_y - y e_x]  with
%           e_i = [cos delta_i ; sin delta_i].
tau_X = 0;
tau_Y = 0;
tau_N = 0;
for i = 1:1:4
    fx = Thrust(i) * cos(delta(i));     % 선체 x 방향 성분 / along body x
    fy = Thrust(i) * sin(delta(i));     % 선체 y 방향 성분 / along body y
    tau_X = tau_X + fx;
    tau_Y = tau_Y + fy;
    tau_N = tau_N + px(i)*fy - py(i)*fx;
end

tau = [tau_X
       tau_Y
       0
       0
       0
       tau_N];
% -------------------------------------------------------------------------
```

| In the code | In the derivation | Note |
|---|---|---|
| `Thrust(i) = k_pos * n(i)*abs(n(i))` | $T_i = k_{pos} n_i \lvert n_i \rvert$ | the signed square; line 1, and the same line `otter.m` has |
| the `if n(i) > 0 … else` branch | $k_{pos}$ ahead, $k_{neg}$ astern | the first of this week's three asymmetries, measured in §12-4 |
| `delta(i) > d_max(i)` | line 3 | clipped inside the plant, so the model can refuse |
| `fx`, `fy` | $T_i\cos\delta_i$, $T_i\sin\delta_i$ | §12-1 line 7 |
| `px(i)*fy - py(i)*fx` | $x_i f_{iy} - y_i f_{ix}$ | §12-1 line 1 — the column rule, third entry |
| rows 3, 4, 5 left at zero | line 6 | heave, roll and pitch carry no thruster |

> [!note] The sway row is no longer structurally zero
> Week 6 made the same point about `otter_bow.m`. A motion model whose $\tau_y$ is identically zero describes an under-actuated vessel, however a sway force is added to it afterwards. The four-unit model earns a non-zero second row from the geometry itself, which is why the eight numbers of §12-3 can be given directly to the plant with no allocator between.

## 12-3. The force eight numbers make

This section answers: given eight numbers by hand, is the resulting force the one the column rule predicts?

**What is observed.** Experiment 12-3 commands six sets of eight numbers and compares two independent computations of $\boldsymbol{\tau}$: the hand formula of §12-1 line 7, and the force measured back out of `otter_tilt4` from the acceleration it produces. The worst disagreement over the six cases is $2.8\times10^{-14}$ N or N·m.

- the six cases are chosen to isolate one effect each, and are reused by §12-4, §12-5 and §12-6
- V6 asks for $70^\circ$, and the table records what the model received

**The result.** The model is driven open loop: eight constants on the canvas, a saturation stage, the plant, and the log.

$$
\boldsymbol{\tau}_{\text{measured}} \;=\; M\bigl(\dot{\mathbf{x}}_{\text{on}} - \dot{\mathbf{x}}_{\text{off}}\bigr)_{1:6}
$$

| Symbol | Quantity | Value · source |
|---|---|---|
| $M$ | $6\times 6$ mass matrix, rigid body plus added mass | from `otter_tilt4` at the same state |
| $\dot{\mathbf{x}}_{\text{on}}$ | acceleration with the commanded $(n, \delta)$ | `otter_tilt4(x, n, delta, …)` |
| $\dot{\mathbf{x}}_{\text{off}}$ | acceleration with $n = 0$ | the same call with the thrust removed |
| residual | $\max\lvert B\mathbf{f} - [X\;Y\;N]^{\mathsf T}\rvert$ | asserted below $10^{-12}$ inside the script |

**Derivation, one line at a time.**

1. The six-row acceleration of the vessel is $\dot{\boldsymbol{\nu}} = M^{-1}(\boldsymbol{\tau} - \mathbf{d}(\boldsymbol{\nu}, \mathbf{x}))$, where $\mathbf{d}$ collects damping, Coriolis and restoring terms. Those terms depend on the state but not on the thrust.
2. Evaluating the same state twice, once with the thrust and once with $n = 0$, therefore differences $\mathbf{d}$ away: $\dot{\boldsymbol{\nu}}_{\text{on}} - \dot{\boldsymbol{\nu}}_{\text{off}} = M^{-1}\boldsymbol{\tau}$.
3. Multiplying back by $M$ recovers $\boldsymbol{\tau}$ exactly, not approximately, because acceleration is affine in the thrust. This is the same argument Week 6 used to show its superposition had been exact.
4. The comparison is run **at rest**, $\mathbf{x} = \mathbf{0}$, so that no state-dependent term can hide a sign error by cancelling it.
5. The tilt command is clipped before it reaches the column rule, so the table prints the clipped angle. A case that asks for more than $45^\circ$ must therefore produce the row of the case that asked for exactly $45^\circ$.

![The open-loop model: eight constants, the saturation stage, the plant, and the log](W12_simulink/img/W12_openloop.png)

| In the figure | Meaning |
|---|---|
| eight Constant blocks, `n1`–`n4` and `delta1`–`delta4` | the eight numbers, given by hand; a student edits only `W12_0_setup` |
| two Mux bars | the four shaft speeds and the four tilt angles gathered into vectors |
| the tan `servo limits` subsystem | the physical envelope, applied before the plant sees anything |
| the green `Otter USV` block | `otter_tilt4`, the same hull as Weeks 1 to 11 |
| the grey `Measurements` block | the log; its first six columns are `[u v r N E psi]`, as in every week |
| the two branches routed below the blocks | the **post-servo** $(n, \delta)$, tapped for the log |

The saturation stage, opened:

![The servo stage: the shaft clip, and the angle clipped before it is rate-limited](W12_simulink/img/W12_openloop_servo.png)

| In the figure | Meaning |
|---|---|
| upper lane, `shaft limit` | the asymmetric clip to $[-101.737, +103.931]$ rad/s |
| lower lane, `servo limit` then `servo rate` | the angle is clipped to $\pm 45^\circ$ **first**, then rate-limited to $90^\circ$/s |
| the two lanes never meet | shaft speed and tilt angle are independent commands |

> [!important] The angle is clipped before it is rate-limited, not after
> Rate-limiting first would let the limiter chase a $70^\circ$ target through the legal range and sit at $45^\circ$ only on arrival, so the recorded angle would depend on how long the run lasted. Clipping first makes the target legal, and the rate limiter then describes only how fast the servo gets there.

### Experiment 12-3 · Six commands, and the force each one makes (20 min)

**What it measures.** Lines 3 and 5: that the force measured out of the plant is the force the column rule predicts, and that the servo clip is visible in the table.

**The model.** `W12_openloop.slx`. Between runs only the eight constants change; the wiring does not.

**Opening and running.**

```matlab
W12_0_setup
open_system('W12_openloop')    % Run — 궤적과 상태량이 뜬다 / the track appears
d_deg = [0 0 0 0]';            % Run — 틸팅 없는 오터 / the Otter of Weeks 1 to 5
d_cmd = deg2rad(d_deg);
W12_V_openloop                 % 여섯 경우 전부 / all six cases, and the tables
```

Expected output, the first of three tables printed by that script:

```
  (1) hand formula against the motion model, at rest

      tau from the hand formula    X = sum Ti cos di
                                   Y = sum Ti sin di
                                   N = sum (xi sin di - yi cos di) Ti
      tau measured out of otter_tilt4's acceleration, same state

    case  n [rad/s] after clip       delta [deg] clipped       X [N]    Y [N]  N [N m]    resid
    -------------------------------------------------------------------------------------------
    V1    [ 60.0  60.0  60.0  60.0]  [   0    0    0    0]   159.552    0.000    0.000  0.0e+00
    V2    [ 60.0 -60.0  60.0 -60.0]  [   0    0    0    0]    33.372    0.000   49.841  7.1e-15
    V3    [ 60.0  60.0  60.0  60.0]  [  45   45   45   45]   112.820  112.820   28.205  2.8e-14
    V4    [ 60.0  60.0 -60.0 -60.0]  [  45   45  -45  -45]    23.598   89.223   51.803  7.1e-15
    V5    [ 60.0  60.0 -78.7 -78.7]  [  45   45  -45  -45]    -0.000  112.820   28.205  1.4e-14
    V6    [ 60.0  60.0  60.0  60.0]  [  45   45   45   45]   112.820  112.820   28.205  2.8e-14
    -------------------------------------------------------------------------------------------
    worst residual 2.8e-14 N or N m over the six cases
```

**Reading the table against the derivation.**

| Where to look | What is there | Which line predicts it |
|---|---|---|
| the `resid` column | at most $2.8\times10^{-14}$ | line 3 — the two computations are the same expression, so only rounding separates them |
| V1, $X = 159.552$ N | $4 \times 39.888$ | §12-1 line 8 with all $\delta_i = 0$: four propellers ahead and nothing else |
| V1, $N = 0.000$ exactly | $\sum y_i T_i = 0$ when all four thrusts are equal | §12-1 line 8 — the $y$ stations cancel in pairs |
| V2, $X = 33.372$ N although $+60$ is opposed by $-60$ | $2(39.888 - 23.202)$ | §12-2 line 1 — $k_{pos} \neq k_{neg}$; §12-4 takes it up |
| V5, the commanded $-78.7$ rad/s | not $-60$ | §12-4 line 4 — the astern speed that actually cancels $+60$ |
| V6 identical to V3 | the `delta` column reads 45, although 70 was asked | line 5, and §12-2 line 3 |

**What the table says**

- The eight numbers reach the hull as the column rule says they will, and nothing in the wiring alters them.

| What to try | What to watch |
|---|---|
| `d_deg = [0 0 0 0]'; d_cmd = deg2rad(d_deg);` then Run | the V1 row: surge only, and the vessel of Weeks 1 to 5 is back |
| `n_cmd = [60 60 73.48 73.48]';` with `d_deg = [45 45 45 45]'` | $X = Y = 141.015$ N and $N = 0.011$ N·m — the yaw-free crab §12-4 line 8 predicts |

> [!tip] In class
> - **Purpose** — separate "the equations are right" from "the vessel does what was wanted".
> - **Point to** — the V2 row. Equal and opposite shaft speeds, and $33.372$ N of surge nobody asked for.
> - **Ask** — "V6 asked for $70^\circ$. Which column shows that it did not get it?" The `delta` column, which prints what the plant received.
> - **Take away** — a residual of $10^{-14}$ says the arithmetic is right; it says nothing about whether the force was the right force.

## 12-4. Three asymmetries that break the symmetric guess

This section answers: why does a command that looks symmetric produce a motion that is not?

**What is observed.** Three separate asymmetries appear in the six rows of table (1), and each one is a property of the vessel rather than of the command.

- the thrust curve: $+60$ rad/s gives $+39.888$ N, $-60$ rad/s gives only $-23.202$ N
- the stations: $l_f = 1.50$ m forward against $l_a = 1.00$ m aft
- the servo: $70^\circ$ asked, $45^\circ$ given

**The result.** Each has a closed form, and each predicts a number in the table.

$$
\underbrace{n_{rev} = -n\sqrt{\frac{k_{pos}}{k_{neg}}} = -78.670\ \text{rad/s}}_{\text{thrust curve}},
\qquad
\underbrace{N = \bar{x}\,Y, \quad \bar{x} = \frac{l_f - l_a}{2} = 0.25\ \text{m}}_{\text{stations}}
$$

| Symbol | Quantity | Value · source |
|---|---|---|
| $k_{pos}$ | thrust coefficient, ahead | $0.02216/2 = 0.011080$ — `otter.m`, unchanged |
| $k_{neg}$ | thrust coefficient, astern | $0.01289/2 = 0.006445$ — same |
| $k_{neg}/k_{pos}$ | the asymmetry ratio | $0.5817$ — printed by `W12_0_setup` |
| $n_{rev}$ | astern speed cancelling $+60$ rad/s | $-78.670$ rad/s — measured in table (1), row V5 |
| $\bar{x}$ | longitudinal centroid of the four stations | $0.25$ m |
| $N$ | residual yaw of a four-unit symmetric tilt | $+28.205$ N·m — table (1), row V3 |

**Derivation, one line at a time.**

1. The thrust of one propeller is the signed square $T = k n\lvert n\rvert$, with $k = k_{pos}$ for $n \geq 0$ and $k = k_{neg}$ for $n < 0$. Both coefficients are positive, and $k_{neg} < k_{pos}$ because a propeller designed to push ahead is less efficient in reverse.
2. Running one unit at $+n$ and another at $-n$ therefore leaves a surge force rather than cancelling: $T(+n) + T(-n) = (k_{pos} - k_{neg})n^2$.
3. For V2, two units ahead and two astern at $n = 60$ rad/s, this gives $2(k_{pos} - k_{neg})(60)^2 = 2 \times 0.004635 \times 3600 = 33.372$ N, the measured V2 surge. The vessel asked for a pure yaw and got a yaw with a push.
4. Setting $k_{pos}n^2 + k_{neg}n_{rev}\lvert n_{rev}\rvert = 0$ with $n_{rev} < 0$ gives $n_{rev} = -n\sqrt{k_{pos}/k_{neg}} = -60 \times 1.3112 = -78.670$ rad/s. That is the number V5 commands, and its $X$ column reads $-0.000$.
5. The second asymmetry needs no thrust curve at all. Give all four units the same thrust $T$ at the same angle $\delta$, so that $f_{ix} = f_x$ and $f_{iy} = f_y$ for every $i$. Then

$$
N \;=\; \sum_i \bigl(x_i f_y - y_i f_x\bigr) \;=\; f_y\sum_i x_i \;-\; f_x\sum_i y_i
$$

6. The second sum is zero: the stations are in port–starboard pairs, so $\sum y_i = 0$ and the $f_x$ contributions cancel. The first sum is not zero: $\sum x_i = 2l_f - 2l_a = 1.0$ m, so $N = 2(l_f - l_a)f_y$.
7. Dividing by $Y = 4f_y$ puts it in the form that explains itself: $N = \bar{x}Y$ with $\bar{x} = \tfrac14\sum x_i = (l_f - l_a)/2 = 0.25$ m. Four equal forces are one force acting at the centroid of the four stations, and that centroid is $0.25$ m ahead of $o_b$. With $Y = 112.820$ N this is $N = 112.820 \times 0.25 = 28.205$ N·m, the V3 and V5 reading.
8. The condition that removes it follows from the same sum with the bow pair at $T_f$ and the stern pair at $T_a$, all at $\lvert\delta\rvert = 45^\circ$: $\sum x_i T_i = 3.0T_f - 2.0T_a = 0$, hence $T_a = 1.5T_f$. With $T_f = 39.888$ N this needs $T_a = 59.832$ N, that is $n_a = \sqrt{59.832/k_{pos}} = 73.48$ rad/s. Running it leaves $N = 0.011$ N·m and a measured yaw rate of $0.003$ deg/s.
9. The third asymmetry is the servo, and it is not a sign or a ratio but a wall. $\delta$ is clipped before the column rule sees it, so the force is computed from $45^\circ$ whatever was asked. A command of $70^\circ$ and a command of $45^\circ$ are the same command to this vessel.
10. All three together are the argument for an allocator. Each one means that the eight numbers a person would guess from symmetry are not the eight numbers that produce the wanted force, and solving for them by hand — as line 8 did, for one condition — does not scale to three conditions and a changing state.

![Why four equal commands yaw: four unequal arms, and one force off the origin](../figures/w12-why-symmetry-yaws.svg)

| In the figure | Meaning |
|---|---|
| cell (a), four numbered units with identical arrows | V3: every unit at $n_i = 60$ rad/s and $\delta_i = +45^\circ$, so $f_x = f_y = 28.205$ N |
| the four orange numbers beside the units | each unit's own moment $x_i f_y - y_i f_x$, in N·m; they sum to $+28.205$ |
| cell (a) caption | derivation lines 5 and 6 — the $f_x$ terms cancel, the $f_y$ terms do not |
| cell (b), one thick arrow from a dot | the same four forces summed: $X = Y = 112.820$ N at the centroid |
| the $\bar{x} = 0.25$ m dimension | line 7 — the centroid is ahead of $o_b$, which is the whole of the effect |
| the clockwise arc at the origin, $N = 28.205$ N·m | the yaw that offset leaves |

> [!warning] Four equal commands are not a pure sway
> This is the week's single most useful number. A symmetric sway command on this hull leaves $28.205$ N·m of yaw, and no amount of care in the command removes it, because the asymmetry is in the geometry. Line 8 gives the thrust ratio that does remove it, at the cost of a surge the command did not ask for either.

### Experiment 12-4 · The three asymmetries, measured (20 min)

**What it measures.** Lines 3, 4, 7, 8 and 9, each against a row of table (1).

**The model.** The same `W12_openloop.slx`. `W12_tab_track` prints the three asymmetries below the third table, from the same six runs.

**Opening and running.**

```matlab
W12_V_openloop                 % 표 셋을 전부 찍는다 / all three tables
```

Expected output, the block printed below table (3):

```
      the three asymmetries this week turns on
        thrust curve   +60 rad/s gives +39.888 N, -60 rad/s gives -23.202 N
                       so V2 keeps +33.372 N of surge it did not ask for,
                       and the astern speed that cancels +60 is -78.670 rad/s
        the stations   l_f = 1.50 m forward, l_a = 1.00 m aft, so the four
                       tilted thrusters of V3 leave +28.205 N m of yaw on an
                       otherwise clean crab
        the servo      V6 asks for 70 deg and is given 45 deg, so its row
                       of table (1) is V3's row exactly
```

**Reading the output against the derivation.**

| Where to look | What is there | Which line predicts it |
|---|---|---|
| `+33.372 N of surge` | the V2 $X$ column | line 3 — $2(k_{pos} - k_{neg})n^2$ |
| `-78.670 rad/s` | the V5 command | line 4 — $-n\sqrt{k_{pos}/k_{neg}}$ |
| `+28.205 N m of yaw` | the V3 and V5 $N$ column | line 7 — $\bar{x}Y$ with $\bar{x} = 0.25$ m |
| `given 45 deg` | the V6 `delta` column | line 9 |

**What the output says**

- Every asymmetry was predicted before it was measured, and each prediction names the constant it comes from.

| What to try | What to watch |
|---|---|
| `n_cmd = [60 60 73.48 73.48]'` with `d_deg = [45 45 45 45]'` | $N = 0.011$ N·m and $r = 0.003$ deg/s — line 8's ratio, confirmed |
| `d_deg = [90 90 90 90]'`, expecting a pure sway | the table returns V3's row. The servo refuses the extra $45^\circ$, so this is line 9 and not a sway |

> [!tip] In class
> - **Purpose** — show that the obstacle to commanding this vessel is the vessel, not the arithmetic.
> - **Point to** — cell (b) of the figure: one arrow, offset $0.25$ m, and the yaw follows from the offset alone.
> - **Ask** — "Which of the three would disappear if the hull were symmetric fore and aft?" Only the second. The thrust curve and the servo are properties of the hardware.
> - **Take away** — $\bar{x} = (l_f - l_a)/2 = 0.25$ m, and $N = \bar{x}Y$.

## 12-5. The track those forces produce

This section answers: does the vessel go where eight hand-chosen numbers send it?

**What is observed.** Experiment 12-5 runs each of the six cases for 30 s from rest and reads four quantities at the end. V1 runs straight at $2.057$ m/s; V5 crabs at $74.28^\circ$; V6 lies exactly on V3.

- the readings are taken at $t = 30$ s, by when all six have settled
- the crab angle is $\beta = \operatorname{atan2}(v, u)$ and the speed is $U = \sqrt{u^2 + v^2}$
- turn radius is $U/\lvert r\rvert$, reported as `straight` when $\lvert r\rvert < 10^{-4}$ rad/s

**The result.** A force held constant in body axes produces a steady body-frame velocity, and a steady velocity with a steady yaw rate is a circle.

$$
U = \sqrt{u^2 + v^2},
\qquad
\beta = \operatorname{atan2}(v, u),
\qquad
R = \frac{U}{\lvert r \rvert}
$$

| Symbol | Quantity | Value · source |
|---|---|---|
| $U$ | total speed over the water | read at $t = 30$ s |
| $\beta$ | crab angle, body $x$ to the velocity | positive to starboard |
| $R$ | radius of the steady turn | $U/\lvert r\rvert$; infinite when $r = 0$ |
| $T_{final}$ | run length for these readings | 30 s, set inside `W12_tab_reint` |

**Derivation, one line at a time.**

1. With $(n, \delta)$ held constant, $\boldsymbol{\tau}$ is constant in body axes, so the body-frame equation $M\dot{\boldsymbol{\nu}} + \mathbf{d}(\boldsymbol{\nu}) = \boldsymbol{\tau}$ is autonomous and settles on an equilibrium $\boldsymbol{\nu}^\star$ where damping balances thrust.
2. That equilibrium is reached in a few seconds for surge and sway, and in rather longer for yaw, because the nonlinear yaw damping $N_h = N_r(1 + 10\lvert r\rvert)r$ stiffens as $r$ grows.
3. At equilibrium the body-frame velocity is fixed but the heading is not: $\dot\psi = r \neq 0$ rotates the velocity in the Earth frame, which traces a circle of radius $U/\lvert r\rvert$.
4. The crab angle $\beta$ is a property of that equilibrium, not of the command. V3's force stands at $45^\circ$ in body axes, yet the hull crabs at only $22.15^\circ$, because sway damping on this hull is far larger than surge damping.
5. A case with $r = 0$ therefore runs straight in the direction $\beta$, and V1 is the only such case: $\beta = 0$, $R$ infinite.
6. V6 must trace V3's circle exactly, since §12-4 line 9 showed the two commands reach the plant identically. Drawing V6 dashed on top of V3 makes the coincidence visible rather than hidden by overdrawing.

### Experiment 12-5 · Six tracks from six commands (20 min)

**What it measures.** Lines 3 to 6: that each command settles, that the settled state is a circle or a straight line, and that V6 and V3 coincide.

**The model.** The same `W12_openloop.slx`, run six times at $T_{final} = 30$ s. `W12_plot` draws the figure, and is also the model's `StopFcn`, so the same code produces the figure on screen and the figure printed here.

**Opening and running.**

```matlab
W12_V_openloop                 % 여섯 번 돌리고 그림을 저장한다 / six runs, one figure
```

Expected output, the third table:

```
  (3) the motion those forces produce

      every value is read at t = 30 s, by when all six have settled

    case   U [m/s]  crab [deg]   r [deg/s]  turn radius [m]
    -----------------------------------------------------------
    V1       2.057        0.00       0.000         straight
    V2       0.390      -19.79      15.418             1.45
    V3       1.766       22.15       7.333            13.80
    V4       0.834       45.41      12.600             3.79
    V5       0.747       74.28       7.589             5.64
    V6       1.766       22.15       7.333            13.80
    -----------------------------------------------------------

      how each row is read
        V1   pure surge, the Otter of Weeks 1 to 5
        V2   turns, but drifts ahead while turning
        V3   force at 45 deg, hull crabs at 22, and yaws: l_f is not l_a
        V4   mostly sway, surge not yet cancelled
        V5   surge cancelled by the shaft speed, yaw still there
        V6   identical to V3: the servo refused the extra 25 deg
```

![Six commands: surge, sway and yaw rate on the left, and the tracks at 1:1 on the right](W12_simulink/img/W12_result_openloop.png)

**Reading the figure against the derivation.**

| Where to look | What is there | Which line predicts it |
|---|---|---|
| all four state panels, after about 10 s | flat lines | line 1 — a constant body force has a steady-state body velocity |
| the $r$ panel, V2 at $15.418$ deg/s | the largest yaw rate of the six, from the smallest speed | line 2 and §12-4 line 3 — V2 is nearly a pure couple |
| the $\psi$ panel | straight ramps, unwrapped; nothing in this model wraps it | line 3 — constant $r$ |
| the track panel, V1 | a straight line, hulls evenly spaced | line 5 |
| the track panel, V5 | a wide arc with the hull visibly across its own path | line 4 — $\beta = 74.28^\circ$, the vessel is almost sideways |
| V3 solid under V6 dashed | one curve, two labels | line 6 |
| V3's crab of $22.15^\circ$ against a force at $45^\circ$ | the hull does not follow the force direction | line 4 — sway damping, not the command |

**What the figure says**

- Eight numbers given by hand produce exactly the motion the column rule and the damping predict, and in no case the motion a symmetric reading of the command would suggest.

| What to try | What to watch |
|---|---|
| `T_final = 120; animate = 1;` then Run | the hull drawn along the circle; V3 closes its $13.80$ m circle in about 49 s |
| `n_cmd = [60 -60 60 -60]'; d_cmd = zeros(4,1);` then Run | V2's $1.45$ m circle — tighter than the vessel is long |

> [!tip] In class
> - **Purpose** — connect a force in body axes to a track on the water, with nothing in between.
> - **Point to** — the V5 hull symbols on the track: the bow points well off the direction of travel.
> - **Ask** — "V3's force is at $45^\circ$. Why does the hull crab at only $22^\circ$?" Because sway is damped far harder than surge; the equilibrium is not the force direction.
> - **Take away** — an open-loop command gives a repeatable circle, and a circle is not a mission.

## 12-6. Whether the model is the equations

This section answers: table (1) showed the equations are right — what shows that the Simulink model evaluates those equations?

**What is observed.** Experiment 12-6 re-integrates each of the six 30-s runs outside Simulink, with the same fixed-step `ode4` and the same step, driven at every step by the $(n, \delta)$ the model actually applied. The worst disagreement in position or speed over all six runs is exactly $0.00\mathrm{e}{+}00$.

- the driving signal is the **post-servo** pair read back from the log, not the command
- the heading column disagrees at $5.09\times10^{-14}$ deg, which is the unwrapping, not the dynamics

**The result.** Two different checks, and neither substitutes for the other.

| Check | What it would catch | What it cannot catch |
|---|---|---|
| table (1) — hand formula against `otter_tilt4` | a wrong column, a wrong sign, a wrong arm | a model wired to the wrong signal, a wrong solver, a wrong step |
| table (2) — the model against independent re-integration | wiring, solver, step, saturation order | an error present in `otter_tilt4` itself, which both sides share |

**Derivation, one line at a time.**

1. Table (1) compares two evaluations of the same function at one state. It therefore tests the function and nothing downstream of it.
2. A test of the model must re-run the model's own trajectory from an independent integrator. Writing the integrator by hand, in four lines of Runge–Kutta, removes Simulink from the comparison entirely.
3. The independent run must be given the same input the model received, which is **not** the command: the servo clipped it. Reading $(n, \delta)$ back out of the log, where they are tapped after the saturation stage, supplies the input actually applied.
4. The same fixed-step `ode4` at $h = 0.02$ s must be used. A variable-step solver on one side and a fixed step on the other would disagree at the step-error level and say nothing about the wiring.
5. A single-instant acceleration comparison would not do this job. The log carries 6 of the 12 states — $[u\;v\;r\;N\;E\;\psi]$ — and under sway the missing six, among them $w$, $p$, $q$ and $\phi$, are not zero. An acceleration reconstructed from the logged six would be evaluated at a state the vessel was never in.
6. Re-integration avoids that trap because it never reads the model's state: it starts from the same $\mathbf{x}_0$, which is known in full, and advances its own twelve states.
7. Agreement to $0.00\mathrm{e}{+}00$ in position therefore says the two integrations performed bit-identical arithmetic, which is the strongest statement available: same equations, same inputs, same solver, same step.
8. The heading residual of $5.09\times10^{-14}$ deg is not a dynamics disagreement. The log stores $\psi$ in degrees and the comparison takes the smallest signed angle, so the residual is the cost of two conversions.

### Experiment 12-6 · The model against an integrator written by hand (20 min)

**What it measures.** Lines 3, 4 and 7: that the wiring, the solver and the saturation order are what the equations assume.

**The model.** The same six runs. The comparison lives in `W12_tab_reint`, which calls `otter_tilt4` directly inside its own Runge–Kutta loop.

**Opening and running.**

```matlab
W12_V_openloop                 % 블록 (2) 가 재적분을 한다 / block (2) re-integrates
```

Expected output, the second table:

```
  (2) the Simulink model against the same equations, integrated outside it

      the same fixed-step ode4 and the same step 0.020 s, started from x0,
      driven at every step by the (n, delta) the model actually applied —
      the post-servo values read back from the log

    case   max |dN| [m]  max |dE| [m]  max |dpsi| [deg]  max |du| [m/s]   clip
    ------------------------------------------------------------------------------
    V1        0.00e+00      0.00e+00          0.00e+00        0.00e+00   n 0  d 0
    V2        0.00e+00      0.00e+00          5.09e-14        0.00e+00   n 0  d 0
    V3        0.00e+00      0.00e+00          2.54e-14        0.00e+00   n 0  d 1
    V4        0.00e+00      0.00e+00          5.09e-14        0.00e+00   n 0  d 1
    V5        0.00e+00      0.00e+00          2.54e-14        0.00e+00   n 0  d 1
    V6        0.00e+00      0.00e+00          2.54e-14        0.00e+00   n 0  d 1
    ------------------------------------------------------------------------------
    worst 0.0e+00 m or m/s over the six 30 s runs
```

**Reading the table against the derivation.**

| Where to look | What is there | Which line predicts it |
|---|---|---|
| `max dN`, `max dE`, `max du` | exactly zero, all six runs | line 7 — identical equations, inputs, solver and step |
| `max dpsi` | at most $5.09\times10^{-14}$ deg | line 8 — degree-to-radian conversion, not dynamics |
| the `clip` column, `d 1` on V3 to V6 | the tilt saturation bound during those runs | line 3 — the input re-integrated is the clipped one |
| the `clip` column, `n 0` everywhere | the shaft limit never bound | $60 < 103.931$ and $78.670 < 101.737$ |

**What the table says**

- The Simulink model adds nothing to `otter_tilt4` and loses nothing from it, so every number in §12-3 to §12-5 can be read as a statement about the equations.

| What to try | What to watch |
|---|---|
| `h = 0.05;` then `W12_V_openloop` | still zero. The agreement is between two integrators, so a coarser step moves both together |
| drive the re-integration with `n_cmd` instead of the logged `n` | V3 to V6 stop agreeing, because the command is $70^\circ$ and the plant received $45^\circ$ — line 3 |

> [!tip] In class
> - **Purpose** — separate a check of the equations from a check of the model, and show that this week has both.
> - **Point to** — the `clip` column. The re-integration agrees **because** it was given the clipped input.
> - **Ask** — "Why not just compare accelerations at one instant?" Because the log carries six of twelve states, and the other six are not zero under sway.
> - **Take away** — zero is a stronger result than small, and it is only available when both sides run the same solver on the same input.

---

# Part 2 · Laboratory run order

The experiments of Part 1 are worked through in order; this table is the index of what was run, for repeating the week at home.

| Experiment | Model | Script | What it shows |
|---|---|---|---|
| 12-0 | `W12_openloop` | `W12_1_build_openloop`, `W12_0_setup` | the model written from code, and every constant |
| 12-1 | none | `verify_otter_tilt4` | four identities; $\delta = 0$ returns `otter.m` |
| 12-3 | `W12_openloop` | `W12_V_openloop` → `W12_tab_formula` | table (1) — force against the column rule |
| 12-4 | `W12_openloop` | `W12_V_openloop` → `W12_tab_track` | the three asymmetries, each against a row |
| 12-5 | `W12_openloop` | `W12_V_openloop` → `W12_tab_track` | table (3) and the track figure |
| 12-6 | `W12_openloop` | `W12_V_openloop` → `W12_tab_reint` | table (2) — the model against hand re-integration |

> [!note] One run order, four sections
> Every other week has one script per section. Sections 12-3 to 12-6 share the **same six 30-s runs**: table (1) measures the force at the start of each, table (2) re-integrates the whole of each, and table (3) reads the end of each. Splitting the runs would send the vessel out twenty-four times to produce six trajectories, and the three tables would then be read against runs that are only nominally the same. The runs therefore happen once, in `W12_V_openloop`, and each section's block is a file of its own — `W12_cases` fixes the six commands, `W12_tab_formula` is §12-3, `W12_tab_reint` is §12-6, and `W12_tab_track` is §12-4 and §12-5. The arrow in the table above names the file to open for that section.

---

# Summary

## Week Summary

| Step | What was done | How it was verified |
|---|---|---|
| 1 | $B$ built for four tilting units from the Week 3 column rule | `verify_otter_tilt4` prints $3\times 8$, rank 3, null space 5 |
| 2 | `otter.m` changed in four marked places into `otter_tilt4.m` | identities (a) and (b) exactly zero: $\delta = 0$ reproduces `otter.m` |
| 3 | the trigonometric form checked against $B\mathbf{f}$ | identity (c), $1.06\times10^{-13}$ over 200 random states |
| 4 | an open-loop model built, eight hand constants to the plant | `W12_1_build_openloop` prints overlaps 0, diagonals 0 |
| 5 | the force of six commands measured out of the plant | table (1), worst residual $2.8\times10^{-14}$ N or N·m |
| 6 | the surge left by opposed shaft speeds predicted and cancelled | $33.372$ N predicted and measured; $n_{rev} = -78.670$ rad/s gives $X = -0.000$ |
| 7 | the residual yaw of a symmetric sway derived | $N = \bar{x}Y = 28.205$ N·m, matching V3 and V5 exactly |
| 8 | the thrust ratio that removes that yaw derived and run | $T_a = 1.5T_f$, i.e. $n_a = 73.48$ rad/s: $N = 0.011$ N·m, $r = 0.003$ deg/s |
| 9 | the servo limit shown to act inside the plant | V6 asks $70^\circ$, table (1) records $45^\circ$, and V6 lies on V3 |
| 10 | the six tracks read at $t = 30$ s | table (3): speed, crab, yaw rate and radius |
| 11 | the model checked against an independent integrator | table (2), $0.00\mathrm{e}{+}00$ m and m/s over six 30-s runs |

---

## Progress Check

> [!important] Minimum condition for following the next week

### Theory

- [ ] Able to state the column rule and apply it to one tilting unit, obtaining both of its columns
- [ ] Able to say why $B$ is $3\times 8$ and what the five null-space dimensions mean for an allocator
- [ ] Able to name the four places `otter.m` changes, and say why the damping is not one of them
- [ ] Able to compute $n_{rev} = -n\sqrt{k_{pos}/k_{neg}}$ and explain which asymmetry it answers
- [ ] Able to derive $N = \bar{x}Y$ with $\bar{x} = (l_f - l_a)/2$, and predict $28.205$ N·m without the script
- [ ] Able to say why re-integrating the logged input is a different check from table (1), and why a single-instant acceleration comparison is neither

### Laboratory

- [ ] `verify_otter_tilt4` ran and printed `PASS` with identities (a), (b) and (d) exactly zero
- [ ] `W12_1_build_openloop` ran and printed overlaps 0, diagonals 0
- [ ] `W12_V_openloop` ran and reproduced all three tables
- [ ] A seventh case was commanded by hand from `W12_0_setup`, and its $X$, $Y$ and $N$ were predicted before the run

### Recorded observations

- [ ] The residual yaw measured for a symmetric $45^\circ$ sway command, and the arm it comes from
- [ ] The crab angle of V3, and why it is not $45^\circ$

---

## Assignment 12

- **Due**: before the Week 13 session
- **Submit**: code, results, and a short analysis

### ① Requirements

Three runs, each one eight numbers given by hand in `W12_0_setup`. No allocator, no controller.

1. **Reproduce the yaw-free crab.** Apply §12-4 line 8 to obtain the stern shaft speed that cancels the residual yaw of a $45^\circ$ four-unit sway command. Derive it rather than copying $73.48$ rad/s: show the step from $\sum x_i T_i = 0$ to $T_a = 1.5T_f$ and the conversion to shaft speed, including which thrust coefficient applies and why.
2. **Find a motion that is neither.** Choose eight numbers for which $X = 0$ **and** $N = 0$ while $Y \neq 0$ — a pure sway, with no surge and no yaw. Keep $\delta_i \in \{+45^\circ, -45^\circ\}$ so that only the four shaft speeds are free. State the two linear conditions on $T_1 \ldots T_4$, solve them by hand, convert each $T_i$ to a shaft speed with the correct sign-dependent coefficient, and check every value against the shaft limits before running.
3. **Break it deliberately.** Take the solution of requirement 2 and change one shaft speed by 10 %. Report what appears in $X$, $Y$ and $N$, and say which of the three asymmetries the change exposed.

### ② Verification — mandatory

> [!important] A claim is not a result. Numbers are required, with the averaging window stated

| What to report | How |
|---|---|
| hand-predicted $X$, $Y$, $N$ for each of the three runs | from §12-1 line 7, before running anything |
| measured $X$, $Y$, $N$ | table (1) of `W12_V_openloop`, or the same arithmetic in a script written for the purpose |
| the residual between the two | one number per run, and it must be below $10^{-12}$ |
| $U$, $\beta$ and $r$ at $t = 30$ s | read at $t = 30$ s, as table (3) does; state the instant, not an average |
| the clip flags | whether the shaft or the servo limit bound during the run |

A run whose predicted and measured forces disagree by more than rounding is a mistake in the prediction, not in the model. Find it before reporting.

### ③ Analysis (5–10 lines)

Requirement 2 asked for a pure sway and the vessel can produce one, while requirement 1's command cannot. Explain which freedom made the difference, counting it against the five null-space dimensions of §12-1. Then state what an allocator would have to do that was not done by hand here, and why doing it by hand would not survive a changing demanded force.

### Grading

| Criterion | Weight |
|---|---|
| The model runs and produces the requested output | 25% |
| **Verification performed and numbers reported** | 40% |
| Correctness of the analysis | 25% |
| Readability of the code | 10% |

---

## Troubleshooting

- Only faults that have actually occurred. Hypothetical entries are not included

| Symptom | Cause | Fix |
|---|---|---|
| A tilt of $70^\circ$ or $90^\circ$ produces exactly the $45^\circ$ result | the servo clip inside `otter_tilt4`, §12-2 change 3 | expected. Read the `delta` column of table (1), which prints what the plant received |
| Opposed shaft speeds $\pm 60$ leave a surge force | $k_{neg}/k_{pos} = 0.5817$, §12-4 line 2 | use $n_{rev} = -n\sqrt{k_{pos}/k_{neg}}$, §12-4 line 4 |
| A symmetric four-unit sway command yaws at $7.3$ deg/s | $\bar{x} = 0.25$ m, §12-4 line 7 | expected. Apply the ratio of §12-4 line 8 to cancel it |
| A Constant block shows `-C-` instead of its value | `mss_style` sets Constant width to 55 px, and a longer expression does not fit | keep the Value expression short — the model uses `d_cmd`, not `delta_cmd` |
| `n_cmd = 600` saturates immediately | the command is rad/s, not rpm | 60 rad/s is about 573 rpm; the limit is 103.931 rad/s |
| `W12_V_openloop` runs but no figure appears | the script was called before `W12_0_setup` | run `W12_0_setup` first; it defines `animate`, `pace` and `h` |

---

## References

### Primary

- Fossen, T. I. *Handbook of Marine Craft Hydrodynamics and Motion Control*, §11.2 (thrust allocation and the configuration matrix), §7.3 (manoeuvring models and damping)
- MSS toolbox, `Tools/MSS/VESSELS/otter.m` — the hull, the propeller coefficients and the shaft limits used unchanged
- MSS toolbox, `demoOtterUSVPathFollowingHeadingControl` — the block-level conventions this course's models follow

### In this course

- Week 3 — the column rule, and the only definition of $B$ this course uses
- Week 5 — saturation, and what a limit does to a command
- Week 6 — `otter_bow.m`: changing the motion model rather than adding to its input
- `_tools/otter_tilt4.m` — the four changes, each marked `% ---- CHANGED (i of 4)`
- `_tools/verify_otter_tilt4.m` — the four identities of Experiment 12-1

---

## Next Week

- **Week 13 — Allocation for Four Tilting Thrusters**
- The five null-space dimensions counted in §12-1 are spent: choosing eight numbers that produce a demanded $\boldsymbol{\tau}$, and choosing among the many that do
- What must be prepared: the three asymmetries of §12-4 stated from memory, with the numbers $0.5817$, $0.25$ m and $45^\circ$ attached to the right one
