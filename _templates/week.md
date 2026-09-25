---
type: week
week: 0
title: Week N — Title
date: 2026-01-01
tags: [week, topic]
status: draft
summary: One line, no full stop
---

# Week N · Title

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
- **This week**: ① … ② … ③ …

> [!important] Before starting
> - What from the previous week must already be working
> - How to verify it in one command

---

## Learning Outcomes

Upon completion of this week, the learner is able to:

1.
2.
3.

## Prerequisites and Setup

| Item | Requirement |
|---|---|
| | |

---

# Part 1 · Principle and experiment, section by section

Every section states what is observed, says what follows from it, and then runs **the experiment that measures it**, on its own model. The numbers quoted in the text are printed by the run a few lines below it.

| Part of a section | What it holds |
|---|---|
| **What is observed** | the effect itself, with the numbers it produces |
| **What follows from it** | numbered lines, one step each |
| **Experiment N-x** | the model, the commands, the output actually obtained, the figure, and a table that reads every feature of the figure back to **the numbered line that predicts it** |

## N-0. Setting up (10 min)

```matlab
cd lectures/WNN_simulink
WNN_0_setup
WNN_1_build_…
```

Expected output:

```
output
```

## N-1. Section title

This section answers: …

**What is observed.** Experiment N-1 …

- the effect, with its numbers

**The result.**

$$
\text{display equation}
$$

| Symbol | Value | Source |
|---|---|---|
| | | |

**Derivation, one line at a time.**

1. …
2. …

![Figure caption](../figures/wNN-name.svg)

| In the figure | Meaning |
|---|---|
| | |

### Experiment N-1 · Title (NN min)

**What it measures.** Line n of the derivation: …

**The model.** `WNN_X_name` — what it holds, and what changes between runs.

**Opening and running.**

```matlab
WNN_0_setup
open_system('WNN_X_name')     % Run — 무엇이 보이는가 / what appears
gain = value;                 % Run — 무엇이 달라지는가 / what changes
WNN_X_script                  % 한 번에 전부 / all of it at once
```

Expected output:

```
output
```

![Simulation result](WNN_simulink/img/WNN_result.png)

**Reading the figure against the derivation.**

| Where to look | What is there | Which line predicts it |
|---|---|---|
| | | |

**What the figure says**

- one sentence

| What to try | What to watch |
|---|---|
| `gain = …;` Run | the measured result of actually running it |

> [!tip] In class
> - **Purpose** —
> - **Point to** —
> - **Ask** — "…" answer
> - **Take away** —

## N-2. Section title

---

# Part 2 · Laboratory run order

The experiments of Part 1 are worked through in order; this table is the index of what was run, for repeating the week at home.

| Experiment | Model | Script | What it shows |
|---|---|---|---|
| N-0 | all of them | `WNN_0_setup`, `WNN_1_build_…` | the parameters, and every model written from code |
| N-1 | `WNN_X_name` | `WNN_X_script` | |

---

# Summary

## Week Summary

| Step | What was done | How it was verified |
|---|---|---|
| 1 | | |

---

## Progress Check

> [!important] Minimum condition for following the next week

### Theory

- [ ] Able to state …

### Laboratory

- [ ] … ran and produced …

### Recorded observations

- [ ]

---

## Assignment N

- **Due**: before the Week N+1 session
- **Submit**: code, results, and a short analysis

### ① Requirements

### ② Verification — mandatory

> [!important] A claim is not a result. Numbers are required, with the averaging window stated

### ③ Analysis (5–10 lines)

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
| | | |

---

## References

### Primary

- Fossen, T. I. *Handbook of Marine Craft Hydrodynamics and Motion Control*, §x.y
- MSS toolbox, `Tools/MSS/...`

### In this course

---

## Next Week

- **Week N+1 — Title**
- What is covered
- What must be prepared
