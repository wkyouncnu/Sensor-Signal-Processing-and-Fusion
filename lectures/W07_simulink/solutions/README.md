# Week 7 · Laboratory Solutions

- Reference answers, not the only correct ones. The checker tests the physics, not the diagram — with one structural exception, explained below.
- Read them after attempting the problem.

---

## Building and checking

```matlab
cd lectures/W07_simulink/solutions
W07_S1_notch                 % builds W07_S1.slx — all three problems in one model
W07_S_expected               % regenerates the expected-result figures

W07_check(1,'W07_S1')
W07_check(2,'W07_S1')
W07_check(3,'W07_S1')
```

All three pass and `check_overlaps('W07_S1')` is **0**.

```
  W07 problem 1
    filter        heading std   moment std   moment max   what it filters
    none             1.550 deg       18.86 Nm      70.85 Nm        0.000 deg
    notch            1.042 deg       13.41 Nm      70.85 Nm        2.164 deg
  the wave is in the measurement                 2.865  (expected    3.000 +- 0.3 deg)  PASS
  zeta_n = zeta_d leaves it untouched            0.000  (expected    0.000 +- 1e-06 deg)  PASS
  the notch is actually in the loop                     PASS

  W07 problem 2
    filter        overshoot   rise [s]   settle [s]   phase of H at 1.6 rad/s
    none              0.93 %      1.14        1.72               0.0 deg
    notch             9.07 %      0.86        7.76             -18.5 deg

  W07 problem 3
    controller              mean heading error   mean moment   heading std
    P-D  (Ki = 0)                  3.071 deg        -15.13 Nm      1.198 deg
    PI-D                           0.084 deg        -15.13 Nm      1.191 deg
  the ripple is the same on both                -0.007  (expected    0.000 +- 0.06 deg)  PASS
```

Two rows are worth pausing on. The `what it filters` column is $0.000$ with $\zeta_n = \zeta_d$ — not small, **zero**, because $H(s)$ is then the identity and the transfer function has unity direct feedthrough. And in Problem 3 the two heading standard deviations differ by $0.007°$: the integral removed a $3°$ offset and left the $1.19°$ of wave ripple exactly where it was.

---

## The three decisions worth defending

| | The choice | Why the alternative is worse |
|---|---|---|
| **The rate is filtered too** | two transfer functions, not one | The wave carries $11.64$ deg/s of yaw rate, comparable with what this vessel can produce. Filtering the heading alone leaves most of the disturbance in the loop through the D term, and the moment std barely moves |
| **The filter is switched off by a number** | $\zeta_n = \zeta_d$, never by deleting a block | Two models can differ in ways nobody intended. One model run twice cannot. This is the same argument as Week 5's single guidance block with a law flag, and Week 6's single allocator with `fit_mode` |
| **The integral goes inside the autopilot, after the notch** | it integrates $e$, formed from the **filtered** heading | Integrating the raw error would accumulate the wave. It would still average to nearly zero — but "nearly" is doing work there, and the transient at each saturation would not |

---

## Why $\psi_f$ is logged, and why that is a structural test

Every other check in this course measures an outcome. This one looks at the wiring.

The reason is that a model can contain a correctly built notch that is **not in the loop** — filtered signals computed, logged, and then ignored while the autopilot reads $\psi_m$. Such a model produces the unfiltered numbers, and the only way to distinguish it from a model with no filter at all is to ask what the controller used.

Hence the contract asks for $\psi_f$, and the checker makes two assertions about it that no performance number could make:

- with $\zeta_n = \zeta_d$ it must equal $\psi_m$ to $10^{-6}$ — the filter is the identity, so nothing may be removed;
- with the notch in it must differ measurably — the filter is doing something.

A test of what a signal *is* rather than what it *achieves* is worth one line here because the failure it catches is silent.

---

## The order of the three problems, and why Problem 2 exists

Problem 1 makes the filter look free. Every column of its table improves and nothing was retuned.

Problem 2 exists to refuse that reading. With the sea switched off, the same filter turns a $0.93\,\%$ overshoot into $9.07\,\%$ and a $1.72$ s settling into $7.76$ s. Nothing changed but the day.

The two results are not in tension, and a student who reports only one has not finished. The filter bought $-15.6$ dB at $\omega_0$ and paid $-18.5°$ of phase at $1.6$ rad/s — which is where the vessel is actually steered. Attenuation is bought with phase, and phase is what damping is made of. Week 2 §2-10 paid the same price for the derivative term; this is the second instalment.

The engineering conclusion is in §7-7, not here: **which** of those two days the vessel is to be tuned for is a decision, and the filter's two numbers are where it is written down.

---

## What is deliberately missing

No spectrum estimation, no sweep of $\zeta_d$, no observer.

The width $\zeta_d$ is chosen in §7-7 by the trade Problem 2 measures, and the hour is not long enough to sweep it honestly. The larger absence is the one §9-7 names: this vessel is **given** $\psi$ and $r$ and adds a known wave to them. A real one estimates both from a GNSS receiver and an IMU, and the notch is then one term inside an observer rather than a block in front of a controller — which is the companion course, *Sensor Signal Processing and Fusion*.

What this hour does establish is the question that observer must answer, and it is the question of Problem 3: **not how to make the measurement quiet, but which part of it the controller is supposed to act on.**
