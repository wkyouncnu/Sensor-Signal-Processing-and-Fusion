# Week 4 · Laboratory Solutions

- These are **reference** answers, not the only correct ones. The checker tests the physics, not the diagram.
- Read them after attempting the problems.

---

## Building and checking

```matlab
cd lectures/W04_simulink/solutions
W04_S1_heading_loop          % builds W04_S1.slx — all three problems in one model
W04_S_expected               % regenerates the expected-result figures

W04_check(1,'W04_S1')
W04_check(2,'W04_S1')
W04_check(3,'W04_S1')
```

All three pass and `check_overlaps('W04_S1')` is **0**. The output below is the measured one.

```
  W04 problem 1
  steady error at Kp = 100                  0.0026  (expected   0.0000 +- 0.05 deg)  PASS
     overshoot at Kp = 100                  5.7684  (expected   5.8000 +- 0.5 %)  PASS
  steady error at Kp = 300                  0.0008  (expected   0.0000 +- 0.05 deg)  PASS
     overshoot at Kp = 300                 12.1778  (expected  12.2000 +- 0.5 %)  PASS

  W04 problem 2
  overshoot at Kd = 0                      12.1778  (expected  12.1800 +- 0.5 %)  PASS
  overshoot at Kd = 50                      4.1126  (expected   4.1000 +- 0.5 %)  PASS
  overshoot at Kd = 100                     0.3929  (expected   0.3900 +- 0.5 %)  PASS

  W04 problem 3
  turn WITH the wrap                       19.9997  (expected  20.0000 +- 3 deg)  PASS
  turn WITHOUT the wrap                  -339.9991  (expected -340.0000 +- 12 deg)  PASS
```

---

## The law, and the choices in it

$$
e = \text{ssa}(\psi_d - \psi), \qquad
\tau_N = K_p\,e + K_i\!\int e\,\mathrm{d}t + K_d\,\frac{N_f\,s}{s + N_f}\,e
$$

| | The choice | Why the alternative is worse |
|---|---|---|
| **One model for three problems** | the gains and `use_ssa` are variable names | problem 1 is $K_d = 0$, problem 2 is $K_d > 0$, problem 3 changes only `use_ssa`; the checker sets them, so one model answers all three |
| **The derivative is one Transfer Fcn** | numerator `[Kd*Nf 0]`, denominator `[1 Nf]` | the same `D filter` as Weeks 2 and 3; a pure derivative would turn every sensor jitter and every step corner into a spike (Week 2 §2-10) |
| **The error is wrapped before the gains** | `ssa` in front of the Switch | without it a $20°$ command across the seam is executed as a $340°$ turn; problem 3 measures exactly that |
| **The feedback is a Goto/From tag** | `psi_fb` | a line crossing the whole model backwards lands on the forward path |

---

## Why the error is zero, and why D helps here

- The heading is the running sum of the turn rate: a constant yaw moment makes the heading grow for ever (lecture section C). The plant therefore already contains an integrator, and a proportional controller alone ends at the command. The speed of Week 3 had no such integrator, and P alone always left an error.
- The derivative of a heading error is a turn rate. Resisting it is damping, as on the mass of Week 2. The derivative of a speed error is an acceleration, and resisting that acts like extra mass — which is why the same term made Week 3 worse.

---

## One measurement subtlety in problem 3

The checker reads $\psi$ **unwrapped**, straight from state 12. A wrapped angle cannot tell $+20°$ from $-340°$, because both end at the same physical heading; the quantity the problem is about is the **turn executed**. The two runs command from $t = 0$ so that they start with the same error and differ only in how that error is computed.
