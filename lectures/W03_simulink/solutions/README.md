# Week 3 · Laboratory Solutions

- These are **reference** answers, not the only correct ones. The checker tests the physics, not the diagram.
- Read them after attempting the problem.

---

## Building and checking

```matlab
cd lectures/W03_simulink/solutions
W03_S1_heading_loop          % builds W03_S1.slx — all three problems in one model
W03_S_expected               % regenerates the expected-result figures

W03_check(1,'W03_S1')
W03_check(2,'W03_S1')
W03_check(3,'W03_S1')
```

All three pass and `check_overlaps('W03_S1')` is **0**. The output below is the measured one.

```
  W03 problem 1
  steady error at Kp = 30                   0.0362  (expected   0.0000 +- 0.05 deg)  PASS
     overshoot at Kp = 30                  -0.0389  (expected  -0.0100 +- 0.25 %)  PASS
  steady error at Kp = 100                  0.0065  (expected   0.0000 +- 0.05 deg)  PASS
     overshoot at Kp = 100                  0.2400  (expected   0.2400 +- 0.25 %)  PASS
  steady error at Kp = 300                  0.0019  (expected   0.0000 +- 0.05 deg)  PASS
     overshoot at Kp = 300                  1.5261  (expected   1.5300 +- 0.25 %)  PASS

  W03 problem 2
  overshoot at Kd = 0  [%]                 11.7355  (zeta = 0.3265)
  overshoot at Kd = 25  [%]                 4.0964  (zeta = 0.5179)
  overshoot at Kd = 74.9  [%]              -0.0366  (zeta = 0.9000)
  overshoot falls as Kd rises                                        PASS

  W03 problem 3
  turn WITH the wrap                       19.9987  (expected  20.0000 +- 3 deg)  PASS
  turn WITHOUT the wrap                  -339.9969  (expected -340.0000 +- 12 deg)  PASS
```

---

## The law, and the three decisions in it

$$
\tau_N = K_p\,\text{ssa}(\psi_d - \psi) - K_d\,r
$$

| | The choice | Why the alternative is worse |
|---|---|---|
| **The D term feeds back $r$** | one Selector on state 6 | $\mathrm{d}e/\mathrm{d}t$ agrees with $-r$ while $\psi_d$ is constant and disagrees at **every step**, where the command's derivative is an impulse that goes straight into the actuator. Nothing in this model is differentiated |
| **The error is wrapped before the gain** | `ssa` inside the law | Without it a $20°$ command across the seam is executed as a $340°$ turn. Problem 3 measures exactly that |
| **Both feedbacks are Goto/From tags** | `psi_fb`, `r_fb` | Two lines crossing the whole model backwards land on the forward path. `check_overlaps` is the check |

---

## Why the steady error is zero, and why that is not a compliment to the controller

$$
M_{66}\,\ddot\psi + \big(\lvert N_r\rvert + K_d\big)\dot\psi + K_p\,\psi = K_p\,\psi_d
$$

The heading is the integral of the yaw rate, so the plant carries a **free integrator** and the loop is **type 1**. Week 2's plant had none, and no value of $K_p$ could reach the setpoint there.

The same substitution answers Problem 2 without simulating anything: $K_d$ appears **beside the damping coefficient**, so raising it raises $\zeta$ and overshoot falls. In Week 2 the controlled variable was a velocity, its derivative was an acceleration, and the identical term sat beside the **mass**. The term did not change; the axis did.

---

## The layout trap this model walked into

The five constants inside the allocation were laid out at `[90, 60+34i, 150, 84+34i]`. That puts `k_neg`'s centre on $y = 140$ — which is exactly the row the `X_ff` inport feeds along. `check_overlaps` found the two lines drawn on top of each other.

The fix is to offset the ladder so that **no constant's centre lands on an inport row**:

```matlab
'Position', [90 78+34*i 150 102+34*i]
```

The general lesson: when a subsystem has inports at fixed heights and a column of constants beside them, the two ladders have to be interleaved deliberately. Autorouting will not do it, and the diagram looks fine until it is printed.

---

## One measurement subtlety in Problem 3

The checker reads $\psi$ **unwrapped** — straight from state 12, without applying `ssa`. That is deliberate: a wrapped angle cannot tell $+20°$ from $-340°$, because both end at the same physical heading. The quantity the problem is about is the **turn executed**, not the heading reached.

The two runs also command from $t = 0$ rather than stepping at $t = 5$ s. With a step, the two runs are already in different places when it arrives, and the comparison stops being about the wrap.
