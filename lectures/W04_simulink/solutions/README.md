# Week 4 · Laboratory Solutions

- Reference answers, not the only correct ones. The checker tests the physics, not the diagram.
- Read them after attempting the problem.

---

## Building and checking

```matlab
cd lectures/W04_simulink/solutions
W04_S1_los                   % builds W04_S1.slx — both laws in one model
W04_S_expected               % regenerates the expected-result figures

W04_check(1,'W04_S1')
W04_check(2,'W04_S1')
W04_check(3,'W04_S1')
```

All three pass and `check_overlaps('W04_S1')` is **0**.

```
  W04 problem 1
  pi_p on leg 1                             0.0000  (expected   0.0000 +- 1e-09 rad)  PASS
  settled cross-track error                -0.0306  (expected   0.0000 +- 0.05 m)  PASS
  settled heading command                   0.0038  (expected   0.0000 +- 0.01 rad)  PASS
  it started 18 m off the line             18.0000  (expected  18.0000 +- 0.05 m)  PASS

  W04 problem 2
  LOS   worst |y_e| after 90 s              0.0945 m
  atan2 worst |y_e| after 90 s              3.7812 m
  atan2 still reaches the waypoint          1.4216  (expected   0.0000 +- 6 m)  PASS

  W04 problem 3
  measured crab angle beta_c               22.4615 deg
  settled offset y_e                        3.3011  (expected   3.3074 +- 0.15 m)  PASS
  the prediction Delta tan(beta_c)          3.3074  (expected   3.3011 +- 0.15 m)  PASS
  heading error while offset persists      -0.0036  (expected   0.0000 +- 0.5 deg)  PASS
```

Problem 3 is the one worth pausing on. The prediction $\Delta\tan\beta_c = 3.3074$ m and the measurement $3.3011$ m agree to **six millimetres**, and they do so while the heading error is $-0.004°$. Section 4-7's claim is not an approximation.

---

## The three decisions worth defending

| | The choice | Why the alternative is worse |
|---|---|---|
| **One rotation, both errors** | $x_e^{\,p}$ and $y_e^{\,p}$ from the same matrix product | A distance formula plus a sign test gives $y_e^{\,p}$ and throws $x_e^{\,p}$ away. Section 4-6's switching test needs the along-track coordinate, and computing it separately invites the two to disagree |
| **`atan2` for $\pi_p$, `atan` for the correction** | two different functions on purpose | A leg can point into any quadrant, so $\pi_p$ needs both arguments. The aim-point vector cannot leave the right half-plane of $\{p\}$ because $\Delta > 0$, so the correction does not |
| **The command is not wrapped** | wrapping happens in the autopilot, on the **error** | A wrapped command is harmless here and wrong in general: differentiate it for a feed-forward term and the $2\pi$ jump becomes an impulse |

---

## Why both laws live in one block

The comparison in Problem 2 is only worth making if the plant, the autopilot and the allocation are **bit-for-bit identical** between the two runs. A flag inside one guidance block guarantees that; two models do not.

It is the same reason the lecture's own `W04_guidance.slx` runs four laws through one autopilot bank, and the same reason Week 2 held three controllers in one model.

---

## The measurement window, and why it matters

Problem 2's first draft compared the two laws from $t = 60$ s and the LOS vessel **failed its own check** at $0.44$ m. Nothing was wrong with the model: at $60$ s the LOS vessel is still finishing its approach, so the comparison was between a transient and a steady state.

Moving the window to $t \geq 90$ s — the same window Problem 1 uses — gives $0.09$ m against $3.78$ m.

The general lesson is the one this course applies to its own figures: **a measured number means nothing without the sentence that says what was measured.** Choosing a window that flatters one side is as much an error as computing the wrong quantity.

---

## What is deliberately missing

No waypoint switching, no ILOS, no ALOS. Leg 1 only.

Switching is section 4-6 and needs the along-track error the guidance already computes; the two adaptive laws are sections 4-8 and 4-9. Problem 3 exists to make the reader want them: it ends with a vessel that is holding its commanded heading perfectly and is still $3.3$ m from where it was asked to be.
