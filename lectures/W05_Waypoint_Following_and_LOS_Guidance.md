---
type: week
week: 5
title: Week 5 — Waypoint Following and LOS Guidance
date: 2026-09-22
tags: [week, guidance, los, ilos, model-free-tuning, waypoints, otter, simulink]
status: complete
summary: Guidance in front of the Week 4 autopilot, tuned model-free — atan2 against LOS, LOS as a P controller on the cross-track error, waypoint switching, and ILOS as the integral that removes the offset a current leaves
---

# Week 5 · Waypoint Following and LOS Guidance

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
> - The MSS toolbox is not part of the repository. The weeks that simulate the Otter need it at `Tools\MSS` inside the cloned folder.

- **Course**: USV Guidance, Navigation and Control (Graduate)
- **Department**: Autonomous Vehicle System Engineering, Chungnam National University
- **This week**: ① where the heading command comes from: guidance turns a list of waypoints into $\psi_d$ ② line of sight (LOS) as a P controller on the cross-track error, tuned by its look-ahead distance ③ when to move to the next leg ④ a current, and the integral that removes the offset it leaves (ILOS) — all tuned from measurements, with no model of the vessel

> [!important] Prerequisites from the previous week
> - Week 4 tuned a heading autopilot on the Otter. This week puts a guidance law in front of it and does not retune it: the autopilot follows whatever heading it is given.
> - Week 4 §4-4: heading is not course. A vessel in a current points one way and travels another; §5-5 is where that difference costs a path error.
> - From Weeks 2 to 4: P speeds a loop up and leaves an error when something pushes back; I removes that error; the tuning order.

---

## Learning Outcomes

Upon completion of this week, the learner is able to:

1. Compute the cross-track error of a vessel from the two waypoints of a leg, and explain why aiming at a waypoint does not follow the line between waypoints.
2. Write the LOS law, recognise it as a P controller on the cross-track error with gain $1/\Delta$, and choose $\Delta$ from a measured sweep.
3. Choose the switching distance from the corner behaviour it produces on a mission.
4. Predict the offset a cross current leaves under LOS, $\Delta\tan$ of the heading held, and remove it with ILOS.
5. Tune a guidance law by the order $\Delta \to R \to \kappa$, stating the measurement behind each choice.

## Prerequisites and Setup

| Item | Requirement |
|---|---|
| MATLAB | R2024b, with Simulink |
| MSS | `Tools/MSS`, found by `W05_0_setup` through `mss_path` |
| Course folder | `lectures/W05_simulink` |
| Models | **one per experiment** — `W05_C_atan2`, `W05_D_LOS`, `W05_E_switching`, `W05_F_LOS`, `W05_F_ILOS`, `W05_G_tuning` — all generated by `W05_1_build_guidance`, never edited by hand |
| Time | lecture 40 min, laboratory 1 h 20 min |

---

# Part 1 · Principle and experiment, section by section

Every section states what is observed, says what follows from it, and then runs **the experiment that measures it**, on its own model. The numbers quoted in the text are printed by the run a few lines below it.

| Part of a section | What it holds |
|---|---|
| **What is observed** | the effect itself, with the numbers it produces |
| **What follows from it** | numbered lines, one step each, from the geometry of the path to the law |
| **Experiment N-x** | the model, the commands, the output actually obtained, the figure, and a table that reads every feature of the figure back to **the numbered line that predicts it** |

## 5-0. Setting up (10 min)

```matlab
cd lectures/W05_simulink
W05_0_setup
W05_1_build_guidance
```

Expected output:

```
  W05_0_setup
    path      5 waypoints, legs of 60 m
    guidance  Delta = 5 m (P gain 0.200), R_switch = 3 m, kappa = 0.3
    start     20 m east of the path;  current 0 m/s

  built  W05_C_atan2.slx      (overlapping lines: 0)
  built  W05_D_LOS.slx        (overlapping lines: 0)
  built  W05_E_switching.slx  (overlapping lines: 0)
  built  W05_F_LOS.slx        (overlapping lines: 0)
  built  W05_F_ILOS.slx       (overlapping lines: 0)
  built  W05_G_tuning.slx     (overlapping lines: 0)
```

- `W05_0_setup.m` is the only file edited by hand. If it stops in `mss_path`, the MSS toolbox is not at `Tools\MSS`.
- The first line of `W05_0_setup` is `clear`. Run it again whenever a Scope does not match these notes.

## 5-1. What guidance adds

This section answers: where does the heading command come from?

- Weeks 3 and 4 were given their commands by hand: a speed, a heading. A vessel on a mission is given **waypoints** instead, and something must turn them into a heading to steer. That something is **guidance**.
- Guidance is a controller around the heading autopilot. Its output, $\psi_d$, is the autopilot's input; its input is the vessel's position; its error is the distance from the path.

Every model this week has the same four blocks. Each is a MATLAB Function with commented code; double-clicking one shows the equations of this section.

| Block | Input → output | This week |
|---|---|---|
| `guidance` | position → commanded heading $\psi_d$ | the subject: atan2, LOS or ILOS |
| `heading autopilot` | $\psi_d$ and the state → yaw moment $N$ | the gains of Week 4, $K_p = 300$, $K_d = 100$, with P on the wrapped heading error and D on the measured yaw rate — so that the jump in $\psi_d$ at a waypoint switch gives no derivative kick (Week 2 §2-10); not retuned |
| `allocation` | $N$ → two shaft speeds | Week 4 §4-1, with a constant surge force $X_{ff} = 60$ N (about 0.77 m/s) |
| `Otter` | shaft speeds → twelve states | Week 1 |

**The error guidance works on.** The path is a straight leg from waypoint $k$ to waypoint $k{+}1$, in the direction $\pi_p$. Rotating the vessel's position into that direction splits it into how far along the leg it is, $x_e$, and how far off it, $y_e$:

$$
\pi_p = \operatorname{atan2}(E_{k+1} - E_k,\ N_{k+1} - N_k), \qquad
\begin{aligned}
x_e &= \ \ (N - N_k)\cos\pi_p + (E - E_k)\sin\pi_p\\
y_e &= -(N - N_k)\sin\pi_p + (E - E_k)\cos\pi_p
\end{aligned}
$$

| Symbol | Quantity | Unit |
|---|---|---|
| $(N_k, E_k)$, $(N_{k+1}, E_{k+1})$ | the two waypoints of the active leg | m |
| $(N, E)$ | the vessel's position, north and east | m |
| $\pi_p$ | the direction of the leg | rad |
| $x_e$ | distance travelled along the leg | m |
| $y_e$ | **cross-track error**: distance off the leg, positive to its right | m |

- The goal of path following is $y_e \to 0$. The rotation gives the same $y_e$ as MSS `crosstrackWpt.m` (`verify_w05_guidance` check 5).

### Experiment 5-1 · The guidance layer on the canvas (10 min)

**What it measures.** Nothing yet: the four blocks of the table above are matched to the canvas, and the rotation that produces $y_e$ is read inside the block that performs it.

**The canvas.** `W05_G_tuning` — the fullest model of the week, read here and measured in Experiment 5-6. Everything except the `guidance` block is Week 4, unchanged and not retuned.

**Opening and running.**

```matlab
W05_0_setup
open_system('W05_G_tuning')        % Run — XY 그래프에 항적이 그려진다 / the track is drawn live
```

- Double-click `guidance` and read the numbered comments: the active leg, the rotation into $(x_e, y_e)$, the switching test of §5-4, and the law of §5-3 and §5-5.
- Double-click `heading autopilot`: the two gains of Week 4 and nothing else. The path does not appear anywhere in it.

![W05_G_tuning: guidance, the Week 4 autopilot, allocation and the Otter, then the Scope, the XY Graph and the log](W05_simulink/img/W05_G_tuning.png)

| In the figure | Meaning |
|---|---|
| `guidance` | the guidance law of §5-3 and §5-5; outputs $\psi_d$, $y_e$, the integral `aux` and the leg number `wp` |
| `heading autopilot` | the Week 4 gains, D on the yaw rate (§5-1), not retuned |
| `allocation`, `Otter` | the thrust split of Week 4 and the vessel |
| Goto `[x]` after the Otter | the twelve states, sent to the guidance, the autopilot and the readouts |
| `readouts` | the headings in degrees and the position, for display only |
| Scope, `track` (XY Graph), `W05log` | the cross-track error and headings; the track, east against north; the log |

> [!tip] In class
> - **Purpose** — show where guidance sits: one block in front of the autopilot of Week 4, which is not touched.
> - **Point to** — double-click `guidance` and read the numbered comments: the leg, the rotation to $y_e$, the switching test, the law.
> - **Ask** — "What does the autopilot know about the path?" Nothing. It follows $\psi_d$; the path lives only in the guidance.
> - **Take away** — guidance is a controller whose output is another controller's command.

## 5-2. Aiming at a point is not following a line

This section answers: why not simply point at the next waypoint?

**What is observed.** The vessel starts 20 m east of a path running north and is steered by the obvious law, $\psi_d = \operatorname{atan2}(E_{k+1} - E,\ N_{k+1} - N)$ — point at the next waypoint:

- halfway to the waypoint it is still $10.75$ m off the path, more than half its starting offset,
- it reaches the path only **at** the waypoint, and then leaves it again on the next leg,
- while the law of §5-3, given the same start, is within $0.04$ m of the path at the same point.

**What follows from it, one line at a time.**

1. `atan2` closes the distance to a **point**. The line it draws is the line from the vessel to the waypoint, and that line is not the path unless the vessel is already on it.
2. The quantity that measures "off the path" is therefore not the distance to the waypoint but the perpendicular distance to the **line**, the cross-track error $y_e$ of §5-1.
3. `atan2` never uses $y_e$, so nothing in it drives $y_e$ to zero: the error falls only as a side effect of arriving, which is why it vanishes exactly at the waypoint and not before.
4. A guidance law that follows a path must take $y_e$ as its input and return a heading that reduces it. That is §5-3, and it makes the law a feedback controller like every other one in this course.
5. On a real mission the waypoints are far apart and the space **between** them is where the vessel is asked to be, so the error of line 1 is the whole mission rather than an approach transient.

Measured by Experiment 5-2, below:

| Law | $y_e$ at 50 m north | at 100 m (the waypoint) | at 150 m |
|---|---|---|---|
| atan2 | 10.75 m | 0.50 m | −0.74 m |
| LOS (§5-3) | −0.04 m | 0.01 m | 0.01 m |

### Experiment 5-2 · Aiming at the waypoint (10 min)

**What it measures.** Lines 1 and 3: how far from the path the obvious law leaves the vessel, at three points along one leg, against the law that uses $y_e$.

**The model.** `W05_C_atan2` — the guidance block switched to the `atan2` law, everything behind it (autopilot, allocation, Otter) exactly as Week 4 left it. The waypoints are set to one straight path north, so that the two laws differ in nothing but their own definition.

**Opening and running.**

```matlab
W05_0_setup
WP_N = [0 100 200 300]'; WP_E = [0 0 0 0]';    % 북쪽으로 곧은 경로 / a straight path north
open_system('W05_C_atan2')         % Run — XY 그래프에서 대각선으로 접근한다 / a diagonal approach
W05_C_aim_at_the_waypoint          % 두 법칙을 나란히 / both laws, side by side
```

Expected output:

```
  W05 Experiment 5-2  aiming at the waypoint against line of sight (start 20 m east of the path)
    law     y_e at N = 50 m   N = 100 m   N = 150 m
    atan2            10.75        0.50       -0.74
    LOS              -0.04        0.01        0.01
```

![Experiment 5-2: atan2 against LOS from 20 m off the path](W05_simulink/img/W05_result_atan2.png)

| In the figure | Meaning |
|---|---|
| left | the two tracks with hull silhouettes; the dashed line is the path, the dot the waypoint at 100 m |
| right | the cross-track error against the distance north |

**Reading the figure against the derivation.**

| Where to look | What is there | Which line predicts it |
|---|---|---|
| left panel, the **straightness** of the atan2 track | a diagonal drawn at the waypoint | line 1: the law aims at a point, and a constant bearing gives a straight run |
| right panel, the atan2 curve at $N = 100$ m | it touches zero, and only there | line 3: the error vanishes on arrival, not before |
| right panel, the atan2 curve **past** the waypoint | it leaves zero again, $-0.74$ m | line 1 on the next leg: a new point, a new diagonal |
| right panel, the LOS curve | on zero within about 20 m and staying there | line 4: a law that is fed $y_e$ drives $y_e$ |
| left panel, the hull silhouettes on the atan2 track | pointing at the waypoint throughout | line 1 again: that heading is exactly what the law asks for |

**What the figure says**

- atan2 draws a straight line to the waypoint and meets the path only there; LOS is on the path within 20 m.

| What to try | What to watch |
|---|---|
| `E0 = 5;` Run | $2.80$ m left at $N = 50$ m instead of $10.75$ — **the same fraction** of the starting offset, $0.56$ against $0.54$. Line 1 is a geometric fault, not a matter of size; LOS leaves $0.02$ m in the same run |
| `WP_N = [0 400]'; WP_E = [0 0]'; E0 = 20;` Run | on one long leg the atan2 track is $10.70$ m off at the halfway point and $5.58$ m off three-quarters of the way: line 5, the error **is** the mission |

> [!tip] In class
> - **Purpose** — show that "go to the waypoint" and "follow the path" are different goals.
> - **Point to** — the blue track cutting diagonally to the waypoint while the orange one turns onto the path at once.
> - **Ask** — "Why is atan2 still 10.75 m off halfway?" It reduces the distance to the waypoint, and the line to the waypoint is not the path.
> - **Take away** — guidance must measure the distance to the line, $y_e$, and act on it.

## 5-3. Line of sight: a P controller on the cross-track error

This section answers: what law brings the vessel onto the line, and what is its one tuning knob?

**The law.** Instead of the waypoint, aim at a point on the path a distance $\Delta$ ahead:

$$
\psi_d = \pi_p - \arctan\!\left(\frac{y_e}{\Delta}\right)
$$

- $\pi_p$ says "line up with the path"; the arctan says "lean towards it, by an angle that grows with how far off the vessel is". On the path, $y_e = 0$ and the vessel simply heads along the leg; far from it, the lean approaches $90°$ and the vessel heads straight at the path.

**It is a P controller.** For errors small against $\Delta$, $\arctan(y_e/\Delta) \approx y_e/\Delta$ (within 1.4 % for $\lvert y_e\rvert \le 0.2\Delta$, `verify_w05_guidance` check 2), and

$$
\psi_d - \pi_p \approx -\frac{1}{\Delta}\, y_e \qquad\Longrightarrow\qquad K_p = \frac{1}{\Delta}
$$

| Symbol | Quantity | Value |
|---|---|---|
| $\Delta$ | look-ahead distance | $5$ m, `W05_0_setup.m` |
| $1/\Delta$ | the P gain: heading correction per metre of error | $0.2$ rad/m |

So $\Delta$ is tuned like $K_p$ in Weeks 2 to 4, backwards: a **smaller** $\Delta$ is a **larger** gain. Measured by Experiment 5-3, below:

| $\Delta$ [m] | $1/\Delta$ | within 1 m after [s] | overshoot [m] | zero crossings |
|---|---|---|---|---|
| 0.5 | 2.000 | 27.7 | 1.35 | 7 |
| 1 | 1.000 | 27.9 | 0.70 | 2 |
| 2.5 | 0.400 | 29.1 | 0.42 | 2 |
| 5 | 0.200 | 32.4 | 0.41 | 2 |
| 10 | 0.100 | 41.7 | 0.41 | 2 |
| 20 | 0.050 | 65.2 | 0.40 | 1 |
| 40 | 0.025 | 118.3 | 0.40 | 1 |

- A large $\Delta$ is slow; a small one overshoots and swings. $\Delta = 5$ m — two to three hull lengths — reaches the path almost as fast as the smallest values without swinging, and is the choice.

### Experiment 5-3 · The look-ahead distance (15 min)

**What it measures.** That $\Delta$ behaves exactly as $1/K_p$: the sweep below is the P sweep of Week 2 §2-6 read backwards, on one long leg so that nothing but the gain is in play.

**The model.** `W05_D_LOS` — the guidance block switched to the LOS law. The waypoints are one 400 m leg, long enough for the transient to finish before any corner.

**Opening and running.**

```matlab
W05_0_setup
WP_N = [0 400]'; WP_E = [0 0]';    % 긴 다리 하나 / one long leg
open_system('W05_D_LOS')           % Run — Delta = 5 m / the chosen value
Delta = 0.5;                       % Run — 지그재그로 다가간다 / it zigzags onto the path
Delta = 40;                        % Run — 한참 걸린다 / it creeps
W05_D_lookahead_distance           % 일곱 값을 한 번에 / all seven values at once
```

Expected output:

```
  W05 Experiment 5-3  LOS, the look-ahead distance  (start 20 m east of the path)
    Delta [m]   P gain 1/Delta   within 1 m after [s]   overshoot [m]   zero crossings
    0.5                  2.000                   27.7            1.35                7
    1                    1.000                   27.9            0.70                2
    2.5                  0.400                   29.1            0.42                2
    5                    0.200                   32.4            0.41                2
    10                   0.100                   41.7            0.41                2
    20                   0.050                   65.2            0.40                1
    40                   0.025                  118.3            0.40                1
```

![Experiment 5-3: the cross-track error for seven look-ahead distances](W05_simulink/img/W05_result_lookahead.png)

| In the figure | Meaning |
|---|---|
| traces | the cross-track error against time from 20 m off the path, one per $\Delta$ |

**Reading the figure against the law.**

| Where to look | What is there | What it corresponds to |
|---|---|---|
| the **steepness** of each trace at the start | steeper the smaller $\Delta$ is | $K_p = 1/\Delta$: a larger gain pushes harder on the same error |
| the $\Delta = 0.5$ m trace **crossing zero** repeatedly | 7 crossings, overshoot $1.35$ m | too large a gain rings, as in Week 2 §2-6 — here the ringing is a zigzag across the path |
| the $\Delta = 40$ m trace | within 1 m only after $118.3$ s | too small a gain is slow, and $1/40$ is a very small gain |
| the middle traces, $\Delta = 2.5$ to $10$ m | all reach 1 m within 29 to 42 s with the same $0.41$ m of overshoot | the flat part of the trade-off, where the choice is made |
| every trace, once on the path | it stays there | the law has no steady-state error to leave on a straight path with no current — §5-5 is where that changes |

**What the figure says**

- The curves fan out exactly as a P gain sweep does: the small $\Delta$ drops fast and crosses back and forth; the large one creeps.

| What to try | What to watch |
|---|---|
| `Delta = 0.2;` Run | the zigzag never stops: **44** crossings of the path and still $1.20$ m off at the end of the leg. This is a $K_p$ raised past its limit, with the hull's own turn rate as the slow element |
| `Delta = 100;` Run | one crossing and no zigzag at all, but the path is reached only after $286$ s — a gain of $0.01$ rad/m spends the whole leg converging |

> [!tip] In class
> - **Purpose** — recognise a familiar controller in an unfamiliar law.
> - **Point to** — the $\Delta = 0.5$ m trace crossing zero repeatedly; the $\Delta = 40$ m trace still 5 m off after 100 s.
> - **Ask** — "Which way does the gain go when $\Delta$ is halved?" Up: $K_p = 1/\Delta$ doubles.
> - **Take away** — tune $\Delta$ as $K_p$ was tuned: the smallest value that does not swing.

## 5-4. When to move to the next leg

This section answers: at a corner, when does guidance switch to the next leg?

**What is observed.** The same mission is run with five switching distances, and the corners are where the tracks differ:

- with $R = 20$ m the vessel turns early and passes almost $20$ m from the new leg,
- with $R = 1$ m it runs **past** the corner before turning, and sweeps $3.70$ m outside the sharpest one,
- and the mission finishes sooner the larger $R$ is: $305$ s against $364$ s.

**What follows from it, one line at a time.**

1. The switch is a test on the **along-track** coordinate: the guidance moves to the next leg when less than $R$ of the active leg remains, $d - x_e < R$, with $d$ the leg's length. This is the test MSS uses, and it is a distance along the path rather than a circle round the waypoint.
2. **A large $R$ cuts the corner.** At the instant of the switch the vessel is still on the old leg, $R$ before its end, so it is about $R$ away from the new leg — and the new leg is what $y_e$ is now measured against. Hence the largest distance is close to $R$ itself in the last three rows.
3. **A small $R$ carries the vessel past the corner.** The turn begins only at the corner, and the hull cannot turn instantly: at $0.77$ m/s it sweeps outside, $3.70$ m at the $135°$ corner for $R = 1$ m. The sharper the corner, the further it goes.
4. Lines 2 and 3 pull in opposite directions, so the best $R$ is the one whose **worst** corner is smallest — $R = 3$ m, at $2.98$ m.
5. Cutting corners is not wrong in itself; it also finishes sooner. The choice made here is to stay close to the path, and a survey that must cover its lines exactly would choose differently.

Measured by Experiment 5-4, below, on the five-waypoint mission with $\Delta = 5$ m:

| $R$ [m] | largest distance from the new leg at corners 1, 2, 3 [m] | last waypoint reached at [s] |
|---|---|---|
| 1 | 2.06, 2.08, 3.70 | 363.5 |
| 3 | 2.98, 2.98, 2.29 | 352.8 |
| 5 | 4.98, 4.98, 3.53 | 344.0 |
| 10 | 9.97, 9.98, 7.04 | 328.0 |
| 20 | 19.97, 19.98, 14.08 | 305.4 |

### Experiment 5-4 · Waypoint switching (10 min)

**What it measures.** Lines 2, 3 and 4: how far from the new leg each switching distance leaves the vessel at the three corners, and how long the mission then takes.

**The model.** `W05_E_switching` — the LOS law on the full five-waypoint mission, with $\Delta$ fixed at the value Experiment 5-3 chose. Only `R_switch` changes between runs, and the XY Graph shows the corners as they are rounded.

**Opening and running.**

```matlab
W05_0_setup
open_system('W05_E_switching')     % Run — R = 3 m / the chosen value
R_switch = 20;                     % Run — 모퉁이를 크게 자른다 / it cuts the corners wide
R_switch = 1;                      % Run — 모퉁이를 지나쳐서 돈다 / it runs past them
W05_E_waypoint_switching           % 다섯 값을 한 번에 / all five values at once
```

Expected output:

```
  W05 Experiment 5-4  waypoint switching on the mission  (LOS, Delta = 5 m, no current)
    R_switch [m]   largest distance from the new leg at corners 1, 2, 3 [m]   last waypoint at [s]
    1                      2.06   2.08   3.70                                363.5
    3                      2.98   2.98   2.29                                352.8
    5                      4.98   4.98   3.53                                344.0
    10                     9.97   9.98   7.04                                328.0
    20                    19.97  19.98  14.08                                305.4
```

![Experiment 5-4: the mission for five switching distances](W05_simulink/img/W05_result_switching.png)

| In the figure | Meaning |
|---|---|
| coloured tracks | the mission for $R = 1$ to $20$ m; hulls drawn on $R = 3$ m |
| dashed line and dots | the path and its five waypoints |

**Reading the figure against the derivation.**

| Where to look | What is there | Which line predicts it |
|---|---|---|
| the $R = 20$ m track at the first corner | it leaves the leg some $20$ m early | line 2: the switch happens $R$ before the end of the leg |
| the largest-distance columns for $R = 5$, $10$, $20$ | $4.98$, $9.97$, $19.97$ m — each equal to $R$ | line 2 again, in numbers |
| the $R = 1$ m track at the **third** corner | the widest sweep of all, $3.70$ m | line 3: the turn starts at the corner, and the $135°$ corner is the sharpest |
| the $R = 3$ m columns | $2.98$, $2.98$, $2.29$ m — the smallest worst case | line 4: the compromise between the two |
| the last column, top to bottom | $363.5 \to 305.4$ s | line 5: cutting corners shortens the mission |
| the straight parts between corners | every track lies on the path | §5-3: the switching distance decides the corners only |

**What the figure says**

- The green track rounds every corner early and wide; the blue one runs past each corner before turning. $R = 3$ m sits between them.

| What to try | What to watch |
|---|---|
| `R_switch = 50;` Run | almost as long as a 60 m leg: the guidance switches as soon as a leg begins, the vessel is never nearer than $49.98$ m to the leg it is supposed to follow, and it reaches the last leg in $146.9$ s by flying the diagonal |
| `Delta = 20; R_switch = 3;` Run | the worst corner grows to $7.93$ m although $R$ has not changed — a gain of $1/20$ cannot pull the vessel onto the new leg quickly, so $\Delta$ and $R$ are read together |

> [!tip] In class
> - **Purpose** — the second tuning knob, set from what the corners look like.
> - **Point to** — the corner at (60, 0), where the tracks spread the most.
> - **Ask** — "Why does the largest distance equal $R$ for large $R$?" At the switch the vessel is on the old leg, $R$ before the corner — $R$ from the new leg.
> - **Take away** — too early cuts, too late overshoots; choose from the worst corner.

## 5-5. A current, and the integral that removes its offset (ILOS)

This section answers: what does LOS do when a current pushes the vessel sideways, and how is it fixed?

**What is observed.** The same LOS law, the same $\Delta$, with a current flowing east across a path running north:

- the vessel settles **parallel to the path but beside it** — $2.107$ m off in a $0.3$ m/s current, and it stays there,
- while pointing $22.8°$ into the current,
- and the offset grows with the current: $0.658$, $1.344$, $2.107$, $3.012$ m.

**What follows from it, one line at a time.**

1. To travel north across an eastward current the vessel must **point** west of north: the crab angle of Week 4 §4-4. Its course is along the path while its heading is not.
2. LOS produces that heading only through $\arctan(y_e/\Delta)$, so it can hold a heading away from $\pi_p$ **only while $y_e \neq 0$**. This is Week 2 §2-6 line 7 once more: a proportional law makes its output out of error alone.
3. In the steady state the heading held equals the heading asked for, $\psi = \psi_d = \pi_p - \arctan(y_e/\Delta)$. Solving for the error,
$$
y_e = \Delta\,\tan(\pi_p - \psi)
$$
4. The offset is therefore **predictable, not mysterious**: it is $\Delta$ times the tangent of the crab angle the current forces. The measurements below match it to the millimetre (`verify_w05_guidance` check 3).
5. Reducing $\Delta$ would shrink the offset, by line 4 — but $\Delta$ was already chosen in §5-3 for the transient, and a smaller one zigzags. Two requirements, one knob: the standing answer of this course is to add the **integral** instead.

Measured by Experiment 5-5a, below, a current flowing east across a path north:

| current [m/s] | $y_e$ left [m] | heading held [deg] | $\Delta\tan(\text{heading})$ [m] |
|---|---|---|---|
| 0.1 | 0.658 | −7.5 | 0.658 |
| 0.2 | 1.344 | −15.0 | 1.344 |
| 0.3 | 2.107 | −22.8 | 2.107 |
| 0.4 | 3.012 | −31.1 | 3.012 |

- The last two columns are line 4: prediction and measurement agree to the millimetre in every row. Heading is not course — the vessel points $22.8°$ into a $0.3$ m/s current and travels due north.

**ILOS adds the integral.** As in Weeks 2 to 4, the cure for the error a P controller leaves is an integral:

$$
\psi_d = \pi_p - \arctan\!\left(\frac{y_e}{\Delta} + \frac{\kappa}{\Delta}\, y_{\text{int}}\right),
\qquad
\dot y_{\text{int}} = \frac{\Delta\, y_e}{\Delta^2 + (y_e + \kappa\, y_{\text{int}})^2}
$$

| Symbol | Quantity | Value |
|---|---|---|
| $y_{\text{int}}$ | the integral state | m·s scaled; starts at 0 |
| $\kappa$ | integral constant; the I gain is $\kappa/\Delta$ | $0.3$, `W05_0_setup.m` |

6. Near the path $\arctan x \approx x$ again, so the law reads $\psi_d - \pi_p \approx -(1/\Delta)\,y_e - (\kappa/\Delta)\,y_{\text{int}}$: **PI on the cross-track error**, with $K_p = 1/\Delta$ from §5-3 and $K_i = \kappa/\Delta$.
7. The integral state therefore does for the current what the integral of Week 3 did for the drag: it holds the crab angle by itself, so that line 2 no longer needs an error to produce one.
8. The denominator $\Delta^2 + (y_e + \kappa y_{\text{int}})^2$ grows with the error, so the state barely integrates while the vessel is far off the path — **anti-windup built into the law**, in place of the back-calculation bolted on in Weeks 2 to 4 (Børhaug, Pavlov and Pettersen, 2008; Fossen, *Handbook*, 2nd ed., §12.3).

Measured by Experiment 5-5b at 0.3 m/s, with $\Delta = 5$ m:

| $\kappa$ | mean $y_e$, last 100 s [m] | overshoot [m] |
|---|---|---|
| LOS ($\kappa = 0$) | 2.107 | 0 |
| 0.1 | 0.009 | 0.03 |
| 0.3 | 0.011 | 1.79 |
| 1 | −0.011 | 4.10 |
| 3 | 0.169 | 6.32 |

- Every $\kappa$ removes the offset — line 7 — and a larger one overshoots more, which is the price of every integral since Week 2. On a single long leg $\kappa = 0.1$ is the cleanest; §5-6 chooses on the mission, where the legs are short and the integral has less time.

### Experiment 5-5a · The offset a current leaves under LOS (7 min)

**What it measures.** Lines 3 and 4: the error LOS settles at in four currents, against $\Delta\tan$ of the heading it holds.

**The model.** `W05_F_LOS` — the LOS law of §5-3 on one straight 400 m leg, long enough for the offset to settle. Only the current changes between runs.

**Opening and running.**

```matlab
W05_0_setup
WP_N = [0 400]'; WP_E = [0 0]'; V_c = 0.3;     % 동쪽으로 0.3 m/s / 0.3 m/s to the east
open_system('W05_F_LOS')           % Run — 경로와 나란히, 2.1 m 옆으로 / parallel, 2.1 m beside it
V_c = 0.4;                         % Run — 더 비스듬히 서고 더 벌어진다 / further off
W05_F_LOS_in_a_current             % 조류 네 가지를 한 번에 / all four currents at once
```

Expected output:

```
  W05 Experiment 5-5a  LOS in a current flowing east  (Delta = 5 m)
    V_c [m/s]   error left [m]   heading held [deg]   Delta*tan(heading) [m]
    0.1                  0.658                 -7.5                    0.658
    0.2                  1.344                -15.0                    1.344
    0.3                  2.107                -22.8                    2.107
    0.4                  3.012                -31.1                    3.012
```

- The last two columns are line 4, to the millimetre in every row. The vessel points $22.8°$ into a $0.3$ m/s current and travels due north — Week 4 §4-4, now costing a path error.

### Experiment 5-5b · The integral that removes it (8 min)

**What it measures.** Line 7: the same current with the integral state switched on, for four values of $\kappa$ — and what each one costs in overshoot.

**The model.** `W05_F_ILOS` — the same guidance block with the integral state of the law above. The black line in the figure is the run of Experiment 5-5a, for comparison.

**Opening and running.**

```matlab
W05_0_setup
WP_N = [0 400]'; WP_E = [0 0]'; V_c = 0.3;
open_system('W05_F_ILOS')          % Run — 같은 조류, 오차가 사라진다 / the same current, no offset
kappa = 1;                         % Run — 더 빨리 없애지만 더 넘어간다 / faster, and past it
W05_F_ILOS_removes_it              % kappa 네 가지를 한 번에 / all four values at once
```

Expected output:

```
  W05 Experiment 5-5b  ILOS at 0.3 m/s  (I gain = kappa / Delta)
    kappa   mean y_e, last 100 s [m]   overshoot [m]   integral state at 400 s
    0.1                        0.009            0.03                    20.95
    0.3                        0.011            1.79                     7.03
    1                         -0.011            4.10                     2.35
    3                          0.169            6.32                    -0.50
```

![Experiment 5-5b: LOS and ILOS in a 0.3 m/s cross current](W05_simulink/img/W05_result_current.png)

| In the figure | Meaning |
|---|---|
| top | the cross-track error: LOS in black, ILOS for four values of $\kappa$ |
| bottom | the integral state of each ILOS run |

**Reading the figure against the derivation.**

| Where to look | What is there | Which line predicts it |
|---|---|---|
| top panel, the black LOS line | flat at $2.107$ m, for ever | lines 2 and 3: the error is what produces the lean, so it cannot go |
| the LOS table, last two columns | equal in all four rows | line 4: $y_e = \Delta\tan$(crab angle) |
| top panel, every coloured trace | reaches zero and stays | line 7: the integral holds the lean instead |
| bottom panel, the states **levelling off** at $20.95$, $7.03$, $2.35$ | different values, same effect | line 6: what matters is the product $(\kappa/\Delta)\,y_{\text{int}}$, so a smaller $\kappa$ needs a larger state |
| top panel, the overshoot at $\kappa = 1$ and $3$ | $4.10$ m and $6.32$ m | the price of every integral since Week 2 §2-8: late correction arrives after it was needed |
| the first seconds of every trace, from 20 m off | no wind-up, no spike | line 8: while $y_e$ is large the denominator is large and the state hardly moves |

**What the figure says**

- LOS settles 2.1 m off the path; every ILOS settles on it, and a larger $\kappa$ gets there by swinging past.

| What to try | What to watch |
|---|---|
| `V_c = 0.5;` on `W05_F_LOS` | $4.234$ m off, holding $-40.3°$ — and $5\tan 40.3° = 4.234$ m: line 4 holds at any current |
| `Delta = 2.5; V_c = 0.3;` on `W05_F_LOS` | half the look-ahead distance halves the offset, $1.054$ m at the same $-22.9°$ heading, exactly as line 4 says. It also sharpens the transient, which is why §5-6 fixes $\Delta$ on the transient and leaves the current to $\kappa$ |

> [!tip] In class
> - **Purpose** — the same story as the P and I of Week 2, now on a path.
> - **Point to** — the black line holding 2.1 m; the integral states levelling off at different values that all produce the same steady lean into the current.
> - **Ask** — "Why does LOS not reach the path, when its heading is exactly what it commanded?" To hold the line across the current, the vessel must point into it, and LOS only commands that while $y_e \ne 0$.
> - **Take away** — a steady push leaves an error under P; the integral removes it.

## 5-6. The tuning order, applied to guidance

This section answers: in what order are the three parameters chosen?

The order of Week 2 §2-12: the proportional part first, the integral only for an error that remains.

| Step | What is chosen | From what measurement | Choice |
|---|---|---|---|
| 1 | $\Delta$, the P gain | Experiment 5-3: fast without swinging on a straight leg | 5 m |
| 2 | $R$, the switching distance | Experiment 5-4: the smallest worst corner | 3 m |
| 3 | $\kappa$, the I gain | Experiment 5-6: the mission in a 0.3 m/s current | below |

Measured by Experiment 5-6, below, mean $\lvert y_e\rvert$ on each leg from 25 s after entering it:

| $\kappa$ | leg 1 | leg 2 | leg 3 | leg 4 | sum of legs 2–4 [m] | last waypoint at [s] |
|---|---|---|---|---|---|---|
| 0 (LOS) | 3.29 | 0.12 | 2.14 | 1.38 | 3.64 | 330.4 |
| 0.1 | 2.04 | 1.22 | 1.33 | 0.55 | 3.10 | 337.0 |
| **0.3** | 2.29 | 0.40 | 0.38 | 0.14 | **0.92** | 338.8 |
| 0.5 | 2.44 | 0.30 | 0.48 | 0.15 | 0.93 | 342.6 |
| 1 | 2.62 | 0.24 | 0.66 | 0.18 | 1.07 | 349.8 |

- Leg 1 includes the 20 m start offset and is left out of the comparison. LOS leaves 2.14 m and 1.38 m on the legs that cross the current and almost nothing on leg 2, which runs with it.
- On 60 m legs $\kappa = 0.1$ is too slow. $\kappa = 0.3$ and $0.5$ are nearly equal; Experiment 5-5b showed a larger $\kappa$ overshoots more, so $\kappa = 0.3$.

The result, $\Delta = 5$ m, $R = 3$ m, $\kappa = 0.3$, is the default in `W05_0_setup.m`. No model of the vessel was used; only what the Scope and the track showed.

> [!note] What is left out this week
> The previous version of this week derived the laws in full, proved their stability with Lyapunov functions, and added a third law, ALOS, which estimates the crab angle directly. That material is kept in `W05_simulink/_previous_version/` for reference; nothing in this week's tuning depends on it.

### Experiment 5-6 · The tuning order (15 min)

**What it measures.** Step 3 of the order above, on the mission the guidance is actually for: mean $\lvert y_e\rvert$ leg by leg, in a current, for five values of $\kappa$ — and the time the mission takes.

**The model.** `W05_G_tuning` — ILOS on the five-waypoint mission with $\Delta$ and $R$ already fixed by Experiments 5-3 and 5-4. Only $\kappa$ changes.

**Opening and running.**

```matlab
W05_0_setup
V_c = 0.3; T_final = 450;          % 동쪽 조류 / a current to the east
open_system('W05_G_tuning')        % Run — kappa = 0.3 / the chosen value
kappa = 0;                         % Run — LOS 로 돌아간다 / back to LOS: it runs beside the path
W05_G_tuning_by_hand               % 다섯 값을 다리별로 / all five values, leg by leg
```

Expected output:

```
  W05 Experiment 5-6  the tuning order  (Delta = 5 m, R_switch = 3 m, current 0.3 m/s east)
    kappa   mean |y_e| on legs 1, 2, 3, 4 [m]   sum of legs 2-4 [m]   last waypoint at [s]
    0           3.29   0.12   2.14   1.38                  3.64                  330.4
    0.1         2.04   1.22   1.33   0.55                  3.10                  337.0
    0.3         2.29   0.40   0.38   0.14                  0.92                  338.8
    0.5         2.44   0.30   0.48   0.15                  0.93                  342.6
    1           2.62   0.24   0.66   0.18                  1.07                  349.8
```

![Experiment 5-6: the mission in a 0.3 m/s current, LOS against the tuned ILOS](W05_simulink/img/W05_result_tuning.png)

| In the figure | Meaning |
|---|---|
| blue | LOS: beside each leg that crosses the current |
| orange with hulls | ILOS, $\kappa = 0.3$: on the legs; the hulls point into the current while the track stays on the path |
| arrow | the current, 0.3 m/s towards the east |

**Reading the figure and the table against the three steps.**

| Where to look | What is there | Which step or section it settles |
|---|---|---|
| the blue track beside legs 3 and 4 | $2.14$ m and $1.38$ m of mean error | §5-5 lines 2 to 4: the offset LOS must leave, now on a mission |
| the blue track **on** leg 2 | $0.12$ m only | that leg runs with the current, so there is almost no crab angle to hold |
| the orange track on every leg | $0.40$, $0.38$, $0.14$ m | §5-5 line 7: the integral holds the lean instead |
| the hulls on the orange track | pointing into the current while the track runs along the leg | Week 4 §4-4: heading is not course, seen directly |
| the $\kappa = 0.1$ row | $3.10$ m, barely better than LOS | short legs: the value that was cleanest on 400 m has no time to act on 60 m |
| the last column, $330 \to 350$ s | the mission grows slower as $\kappa$ grows | the integral's swing costs distance as well as accuracy |
| leg 1 in every row | $2.0$ to $3.3$ m, and left out of the sum | it contains the 20 m start offset, which is a transient and not a following error |

**What the figure says**

- The tuned ILOS follows the legs; the hulls show the crab angle it holds to do so.

| What to try | What to watch |
|---|---|
| `kappa = 3;` Run | the swing of Experiment 5-5 now happens at every corner: mean $\lvert y_e\rvert$ after 60 s is $1.18$ m against $0.64$ m at $\kappa = 0.3$, and the last waypoint is reached at $385.9$ s instead of $338.8$ — **both slower and less accurate** |
| `V_c = 0; kappa = 0.3;` Run | with no current there is nothing to find: $0.30$ m against $0.20$ m for LOS, and the same mission time. The integral is insurance, and it is not free |

> [!tip] In class
> - **Purpose** — close the week with the full order on a mission, and see Week 4 §4-4 in the picture.
> - **Point to** — the hull on the southbound leg, pointing west of south while the track runs due south.
> - **Ask** — "Why is $\kappa$ chosen on the mission and not on the long leg of Experiment 5-5b?" Short legs leave little time to integrate; the gain that is best on 400 m is too slow on 60 m.
> - **Take away** — choose each parameter on the task it will face, in the order P, switching, I.

---

# Part 2 · Laboratory run order

The experiments of Part 1 are worked through in order; this table is the index of what was run, for repeating the week at home.

Every example has **its own model**, laid out the same way: `guidance` → `heading autopilot` → `allocation` → `Otter`, each a commented MATLAB Function except the vessel. On the right, **one Scope** (top: cross-track error; bottom: commanded and actual heading) and an **XY Graph** that draws the track while the simulation runs.

| Experiment | Model | Script | What it shows |
|---|---|---|---|
| 5-0 | all of them | `W05_0_setup`, `W05_1_build_guidance` | the parameters, and every model written from code |
| 5-1 | `W05_G_tuning` | — | where guidance sits, and the rotation that gives $y_e$ |
| 5-2 | `W05_C_atan2` | `W05_C_aim_at_the_waypoint` | aiming at the next waypoint |
| 5-3 | `W05_D_LOS` | `W05_D_lookahead_distance` | LOS and the look-ahead distance |
| 5-4 | `W05_E_switching` | `W05_E_waypoint_switching` | the switching distance on a mission |
| 5-5a | `W05_F_LOS` | `W05_F_LOS_in_a_current` | the offset a current leaves under LOS |
| 5-5b | `W05_F_ILOS` | `W05_F_ILOS_removes_it` | the integral that removes it |
| 5-6 | `W05_G_tuning` | `W05_G_tuning_by_hand` | the tuning order on the mission in a current |

- The scripts only repeat what Run already shows, for several values at once, and print the numbers quoted in Part 1.
- Each experiment ends with an **In class** note: purpose, what to point at, a question with its answer, and the sentence to take away.

---

# Summary

## Week Summary

| Step | What was done | How it was verified |
|---|---|---|
| 1 | put a guidance law in front of the Week 4 autopilot | `check_overlaps` 0 in five models; $y_e$ equals MSS `crosstrackWpt` |
| 2 | atan2 against LOS | Experiment 5-2: 10.75 m against 0.04 m halfway to the waypoint |
| 3 | $\Delta$ as the P gain $1/\Delta$ | Experiment 5-3: 118 s at 40 m, swinging at 0.5 m; $\Delta = 5$ m |
| 4 | the switching distance | Experiment 5-4: worst corner 2.98 m at $R = 3$ m |
| 5 | a current and ILOS | Experiments 5-5a and 5-5b: LOS offset $= \Delta\tan$(heading) to the millimetre; ILOS removes it |
| 6 | the tuning order on the mission | Experiment 5-6: $\kappa = 0.3$, legs 2–4 summed 0.92 m against 3.64 m for LOS |

## Progress Check

> [!important] Minimum condition for following Week 6

### Theory

- [ ] Able to compute $y_e$ from two waypoints and a position.
- [ ] Able to explain why LOS is a P controller and which way $\Delta$ moves its gain.
- [ ] Able to predict the LOS offset in a cross current from the heading held.
- [ ] Able to explain what the integral of ILOS does and why its denominator limits windup.

### Laboratory

- [ ] `W05_1_build_guidance` ran and every model reported `overlapping lines: 0`.
- [ ] A parameter was changed in the Command Window and the XY Graph showed the new track.
- [ ] `W05_check(1)`, `(2)` and `(3)` pass on a model built from `W05_P1_start`.

---

## In-class laboratory — build the guidance layer by hand

The second hour of the Week 5 session is spent building the guidance block in Simulink. A complete Week 4 vessel is provided with one input left open: the commanded heading.

```matlab
cd lectures/W05_simulink/problems
W05_P1_start                 % creates W05_P1.slx — a Week 4 vessel, no guidance
W05_check(1)                 % run this whenever, as often as needed
```

| | Problem | Time | The number it must reproduce |
|---|---|---|---|
| 1 | The LOS law on leg 1 | 25 min | $\pi_p = 0$ exactly; $y_e$ from 18 m to 0; $\psi_d \to \pi_p$ |
| 2 | atan2 against LOS, same vessel | 20 min | LOS holds the line; atan2 does not |
| 3 | A current, and the offset that stays | 15 min | settled $y_e = \Delta\tan$ of the crab angle |

- The problem sheet is [`W05_simulink/problems/README.md`](W05_simulink/problems/README.md), and reference answers are in [`W05_simulink/solutions/`](W05_simulink/solutions/README.md).
- Problem 3 ends where §5-5 continues: the integral that removes the offset.

---

## Assignment 5

- **Due**: before the Week 6 session
- **Submit**: the modified `W05_0_setup.m`, the numbers requested below, and two figures

### ① Requirements

Double the legs of the mission (every waypoint coordinate times two, legs of 120 m) and tune $\Delta$, $R$ and $\kappa$ again by the order of §5-6 in a 0.3 m/s current.

### ② Verification — mandatory

> [!important] A claim is not a result. Numbers are required, with the averaging window stated

1. The table of Experiment 5-3 on one 240 m leg with the chosen $\Delta$ and its neighbours.
2. The table of Experiment 5-4 on the new mission.
3. The table of Experiment 5-6 on the new mission, and the $\kappa$ chosen.
4. The LOS offset in the current, next to $\Delta\tan$ of the heading held.

### ③ Analysis (5–10 lines)

Compare the chosen $\kappa$ with 0.3, and explain from the leg length why it moved in that direction.

### Grading

| Criterion | Weight |
|---|---|
| The model runs and produces the requested output | 25% |
| **Verification performed and numbers reported** | 40% |
| Correctness of the analysis | 25% |
| Readability of the code | 10% |

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `W05_0_setup` stops in `mss_path` | the MSS toolbox is not at `Tools\MSS` | place MSS there; see the first page |
| the XY Graph shows nothing | the track is outside its axes | the axes are −20 to 140 m; a custom path needs `set_param(... '/track', 'xmax', ...)` |
| the vessel circles a waypoint | $R$ smaller than the vessel can turn inside | raise `R_switch` |
| `guidance` complains that `WP_N` is undefined | `W05_0_setup` was not run | run it; the guidance block reads the waypoints from the workspace |
| a Scope does not match these notes | a changed variable is still in the workspace | run `W05_0_setup` again |

---

## References

### Primary

- Fossen, T. I. *Handbook of Marine Craft Hydrodynamics and Motion Control*, 2nd ed., Wiley, 2021, §12.3 (line-of-sight guidance and its integral form).
- Børhaug, E., Pavlov, A. and Pettersen, K. Y. "Integral LOS control for path following of underactuated marine surface vessels in the presence of constant ocean currents." *47th IEEE Conference on Decision and Control*, 2008, pp. 4984–4991. DOI: 10.1109/CDC.2008.4739352.
- MSS toolbox, `Tools/MSS/GNC/crosstrackWpt.m` and `ILOSpsi.m`.

### In this course

- Week 2 §2-6 to §2-8 and §2-12: P, I and the tuning order. Week 4 §4-4: heading is not course.
- The previous, model-based version of this week — full derivations, Lyapunov stability and ALOS — is kept in `W05_simulink/_previous_version/`.

---

## Next Week

**Week 6 — Control Allocation.** This week gave the vessel the square allocation of Week 4 and never questioned it. Week 6 asks what happens when there are more actuators than degrees of freedom, when a thruster saturates, and when one fails.
