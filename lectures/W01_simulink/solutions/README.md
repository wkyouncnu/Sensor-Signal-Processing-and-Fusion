# Week 1 · Laboratory Solutions

- These are **reference** answers, not the only correct ones. The checker tests the physics, not the diagram.
- Read them after attempting the problem. Each script explains what to build **and why the alternatives were rejected**, which is the part that does not survive being read backwards from a finished model.

---

## Building and checking all three

```matlab
cd lectures/W01_simulink/solutions
W01_S1_openloop      % builds W01_S1.slx
W01_S2_manoeuvre     % builds W01_S2.slx
W01_S3_current       % builds W01_S3.slx

W01_check(1,'W01_S1')
W01_check(2,'W01_S2')
W01_check(3,'W01_S3')
```

All three pass. The output below is the measured one, not a transcription.

```
  W01 problem 1  —  checking model W01_S1
  terminal surge speed u                    1.0286  (expected   1.0286 +- 0.005 m/s)  PASS
  sway velocity v (must stay zero)          0.0000  (expected   0.0000 +- 1e-06 m/s)  PASS
  yaw rate r (nothing steers)               0.0000  (expected   0.0000 +- 1e-06 deg/s)  PASS

  W01 problem 2  —  checking model W01_S2
  yaw rate in the PORT turn                -2.2952  (expected  -2.2942 +- 0.02 deg/s)  PASS
  yaw rate in the STARBOARD turn            2.2955  (expected   2.2942 +- 0.02 deg/s)  PASS
  heading change, port turn               -70.1965  (expected -70.2000 +- 0.5 deg)  PASS
  heading change, starboard turn           70.6083  (expected  70.6000 +- 0.5 deg)  PASS
  sway v in the port turn                   0.1263  (expected   0.1264 +- 0.005 m/s)  PASS
  sway v in the starboard turn             -0.1262  (expected  -0.1264 +- 0.005 m/s)  PASS

  W01 problem 3  —  checking model W01_S3
  ground speed over the ground              1.1091  (expected   1.1091 +- 0.02 m/s)  PASS
  track direction from North               21.8041  (expected  21.8040 +- 0.3 deg)  PASS
  drift, track minus heading               25.8088  (expected  25.8090 +- 0.3 deg)  PASS
```

---

## What each solution is really teaching

| | The block that matters | The idea it carries |
|---|---|---|
| **S1** | `Constant [n0 ; n0]` | The command is a **2-vector**, and equal entries mean no turn, because $N = y_p(T_{left}-T_{right})$ |
| **S2** | `Reshape → 1-D array` | A MATLAB Function writing `n = [nL; nR]` emits a $2\times1$ **matrix**; the plant tolerates it and the log does not |
| **S3** | none — the canvas is unchanged | A current is a **velocity**, not a force. Forces use $\boldsymbol\nu_r$; position uses $\boldsymbol\nu$ |

---

## The one measurement trap worth knowing about

Problem 3 asks for the angle between the track and the heading. There are two reasonable ways to measure a "track direction", and they disagree by about half a degree on this run:

| Definition | Value |
|---|---|
| direction of the straight line from start to finish | $21.804^\circ$ |
| instantaneous direction of the velocity, averaged over the settled fifth | $22.366^\circ$ |

They differ because **the vessel weathervanes about $4^\circ$ during the run**, so the velocity at the end is not parallel to the net displacement. Section E of the lecture uses the first definition, and so does `W01_check`.

This is not pedantry about conventions. It is the reason a measured number always has to be paired with the sentence that says what was measured — a rule this course applies to its own figures as well.
