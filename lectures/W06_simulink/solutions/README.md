# Week 6 · Laboratory Solutions

- Reference answers, not the only correct ones. The checker tests the physics, not the diagram.
- Read them after attempting the problem.

---

## Building and checking

```matlab
cd lectures/W06_simulink/solutions
W06_S1_allocation            % builds W06_S1.slx — all three problems in one block
W06_S_expected               % regenerates the expected-result figures

W06_check(1,'W06_S1')
W06_check(2,'W06_S1')
W06_check(3,'W06_S1')
```

All three pass and `check_overlaps('W06_S1')` is **0**.

```
  W06 problem 1
    t [s]   demanded X    N        delivered X    N        T1      T2
       10       100.00   0.00        100.00   0.00    50.00   50.00
       25       100.00  20.00        100.00  20.00    75.32   24.68
       40       100.00 -20.00        100.00 -20.00    24.68   75.32
  leg 2  port thrust T1                         75.316  (expected   75.320 +- 0.05 N)  PASS
  leg 2  starboard thrust T2                    24.684  (expected   24.680 +- 0.05 N)  PASS
  leg 2  the sum T1 + T2                       100.000  (expected  100.000 +- 0.05 N)  PASS

  W06 problem 2
    t [s]   demanded X      N       delivered X      N
       10        100.0   0.00        100.00   0.00
       25       -100.0   0.00       -100.00   0.00
       40          0.0  20.00         -0.00  20.00
       55          0.0 -20.00         -0.00 -20.00
  surge during +yaw (none asked for)            -0.000  (expected    0.000 +- 0.05 N)  PASS
  surge during -yaw (none asked for)            -0.000  (expected    0.000 +- 0.05 N)  PASS

  W06 problem 3
    t [s]   demanded X      N    X/N      clip X      N    X/N     scale X      N    X/N
       10       220.0    0.0     --      220.0    0.0     --       220.0    0.0     --
       25       220.0   50.0   4.40      166.4   28.8   5.77       151.9   34.5   4.40
       40       100.0   50.0   2.00      100.0   50.0   2.00       100.0   50.0   2.00
       55      -220.0    0.0     --     -133.4    0.0     --      -133.4    0.0     --
  leg 2  clip  turns the force,  X/N             5.773  (expected    5.770 +- 0.08 -)  PASS
  leg 2  scale keeps it,         X/N             4.400  (expected    4.400 +- 0.05 -)  PASS
```

The two ratios of Problem 3 are the numbers worth pausing on. Scaling returns $4.400$, which is the demanded ratio to every digit the checker prints — not to within a tolerance, but exactly, because $X$ and $N$ are both linear in $\mathbf{T}$ and one factor multiplies both. Clipping returns $5.773$. The vessel is being turned less than the controller believes, and nothing upstream is told.

---

## The three decisions worth defending

| | The choice | Why the alternative is worse |
|---|---|---|
| **One block, not three** | the square rule, the limit step and the curve are three sections of one function | Three blocks would suggest three things were built. Problem 2 is two lines of Problem 1 made correct, and Problem 3 is one step placed in front of it. The exercise is one map, corrected twice |
| **The limit precedes the curve** | clip or scale the **thrusts**, then invert | The limit is a limit on thrust. Clamping shaft speeds gives the same answer for clipping and the wrong one for scaling: scaling is linear in $T$, and the curve is not |
| **The sign test is on $T$, not on the demand** | `if T(i) >= 0` inside the loop | A demand for pure yaw has $X = 0$ and yet one propeller runs astern. Testing the sign of the demand, or of $X$, leaves that propeller on the wrong coefficient — which is the whole of Problem 2 |

---

## Why the thrusts are not logged

The checker asks for the command and the **shaft speeds**, and recomputes the thrust itself through $T = k\,n\lvert n\rvert$ — the same curve the hull uses.

Logging $T_1$ and $T_2$ directly would have been easier to write and would have made Problem 2 untestable. A model that inverts the curve with $k_{\text{pos}}$ in both directions still *computes* the right thrusts; it simply asks for a shaft speed that does not produce them. The intended thrust and the delivered thrust are different quantities, and they part company precisely where the exercise is.

This is the general form of a rule this course applies to its own figures: **measure what the plant receives, not what the controller meant.**

---

## The order of the three problems

Problem 2 could have been part of Problem 1 — it is, after all, one `if` inside the same loop. It is separate because of what the run shows.

A student who writes $n = \operatorname{sign}(T)\sqrt{\lvert T\rvert/k_{\text{pos}}}$ and tests it going ahead sees a perfect result. Every number in Problem 1 passes with the wrong curve, because every thrust in Problem 1 is positive. The fault appears only when something runs astern, and the worst of it — surge appearing during a pure turn — appears only when **one** propeller of a pair runs astern.

Problem 1 is therefore a test that a wrong model passes, and that is deliberate. It is the situation a sea trial is in.

---

## What is deliberately missing

No pseudo-inverse, no sway row, no constrained least squares. Two demands and two propellers, which is a square problem with one answer.

Sections 6-3, 6-4 and 6-7 are where the problem stops being square: a third demand the hull cannot answer, more thrusters than demands, and a cost function that says which demand matters when not all of them can be met. Problem 3 ends exactly where §6-7 begins — with two rules that both discard part of the demand and **neither of which was asked which part mattered**.
