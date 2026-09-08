# Week 2 · Laboratory Solutions

- These are **reference** answers, not the only correct ones. The checker tests the physics, not the diagram.
- Read them after attempting the problem. The scripts explain what to build **and why the alternatives were rejected**.

---

## Building and checking

```matlab
cd lectures/W02_simulink/solutions
W02_S1_speed_loop            % builds W02_S1.slx — all three problems in one model
W02_S_expected               % regenerates the expected-result figures

W02_check(1,'W02_S1')
W02_check(2,'W02_S1')
W02_check(3,'W02_S1')
```

All three pass, and `check_overlaps('W02_S1')` is **0**. The output below is the measured one.

```
  W02 problem 1
  u_ss at X = 50 N                          0.6447  (expected   0.6447 +- 0.005 m/s)  PASS
  u_ss at X = 100 N                         1.2894  (expected   1.2894 +- 0.005 m/s)  PASS
  u_ss at X = 200 N                         2.5788  (expected   2.5788 +- 0.005 m/s)  PASS

  W02 problem 2
  u_ss at Kp = 100                          0.8448  (expected   0.8448 +- 0.005 m/s)  PASS
  u_ss at Kp = 500                          1.2986  (expected   1.2986 +- 0.005 m/s)  PASS
  u_ss at Kp = 2000                         1.4440  (expected   1.4440 +- 0.005 m/s)  PASS

  W02 problem 3
  steady speed with PI                      1.5000  (expected   1.5000 +- 0.005 m/s)  PASS
  steady error with PI                      0.0000  (expected   0.0000 +- 0.005 m/s)  PASS
  overshoot with PI                         8.8327  [%]  (P alone had none)
```

---

## Why one model and not three

The three problems differ only in which parts of the loop are switched on:

| | `loop_closed` | $K_i$ | |
|---|---|---|---|
| Problem 1 | 0 | — | $X$ comes straight from `X_open` |
| Problem 2 | 1 | 0 | proportional only |
| Problem 3 | 1 | > 0 | proportional plus integral |

Three separate models would hide the one fact the week is about: **the plant never changed and the thrust map never changed.** Every difference in the result came from the controller. The lecture's own `W02_surge_control.slx` is arranged the same way, which is why its section scripts can sweep a gain without rebuilding anything.

---

## The three decisions worth defending

| | The choice | Why the alternative is worse |
|---|---|---|
| **Discrete integrator** | Discrete-Time Integrator at sample time `h` | A continuous integrator in a fixed-step model gives a solver-order mismatch. It does not raise an error — it produces a slow drift that looks like a physical effect |
| **Feedback is $u$, state 1** | one Selector, then one line | Feeding back $\sqrt{u^2+v^2}$ agrees here and disagrees in Week 4. A loop written against the wrong signal keeps working until exactly the moment it matters |
| **Feedback is a Goto/From tag** | `u_fb` | Drawn as a line it crosses the whole model backwards and lands on the forward path. `check_overlaps` reported exactly one overlapping pair when it was a line |

---

## The layout trap this model walked into

All three inputs of a Switch block arrive on its **left edge**. Autorouting therefore gives them the same vertical lane, and two of them end up drawn on top of each other — `check_overlaps` found precisely that at $x = 425$.

The fix is `_tools/lane_line.m`, which forces a chosen vertical lane per signal:

```matlab
lane_line(mdl, 'loop_closed', 1, 'loop', 2, 424);
lane_line(mdl, 'X_open',      1, 'loop', 3, 412);
```

This is worth knowing before building any model with a Switch or a multi-input Mux, which is most of the models from Week 4 onward.
