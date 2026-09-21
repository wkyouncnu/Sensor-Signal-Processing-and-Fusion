# Week 2 · Laboratory Solutions

- These are **reference** answers, not the only correct ones. The checker tests the response, not the diagram.
- Read them after attempting the problems.

---

## Building and checking

```matlab
cd lectures/W02_simulink/solutions
W02_S1_pid_loop              % builds W02_S1.slx — all three problems in one model
W02_S_expected               % regenerates the expected-result figures

W02_check(1,'W02_S1')
W02_check(2,'W02_S1')
W02_check(3,'W02_S1')
```

All three pass and `check_overlaps('W02_S1')` is **0**. The output below is the measured one.

```
  W02 problem 1
  steady value at Kp = 2                    0.5000  (expected   0.5000 +- 0.005 m)  PASS
     overshoot at Kp = 2                   16.3055  (expected  16.3000 +- 0.5 %)  PASS
  steady value at Kp = 10                   0.8334  (expected   0.8330 +- 0.005 m)  PASS
     overshoot at Kp = 10                  38.7670  (expected  38.8000 +- 0.5 %)  PASS

  W02 problem 2
  built by hand, no PID or Derivative    PASS   (PID blocks 0, Derivative blocks 0)
  overshoot                                 0.1580  (expected   0.1600 +- 0.3 %)  PASS
  inside 1 % of the setpoint after          2.7710  (expected   2.7700 +- 0.1 s)  PASS
  largest force                           129.6013  (expected 129.6000 +- 1.5 N)  PASS

  W02 problem 3
  largest force                             2.5000  (expected   2.5000 +- 1e-06 N)  PASS
  overshoot, Kb = 0                        28.6731  (expected  28.6700 +- 0.5 %)  PASS
  overshoot, Kb = 2                         0.0316  (expected   0.0300 +- 0.3 %)  PASS
  settling (2 %), Kb = 0                    5.5430  (expected   5.5400 +- 0.1 s)  PASS
  settling (2 %), Kb = 2                    3.5610  (expected   3.5600 +- 0.1 s)  PASS
```

---

## One model for three problems

Problem 1 is the finished law with $K_i = K_d = 0$; problem 2 is the finished law with $\tau_{\max}$ large; problem 3 is the finished law. `W02_check` assigns the gains by name, so one model built to the final equation passes all three. Building it once, in full, is the reason the gains must be names rather than numbers.

$$
e = y_d - y,\qquad
u = K_p e + I + d,\qquad
d = N_f(K_d e - x),\ \dot x = d,\qquad
\dot I = K_i e + K_b(\tau - u),\qquad
\tau = \mathrm{sat}(u)
$$

---

## The choices in the answer, and why

| | The choice | Why the alternative is worse |
|---|---|---|
| **The derivative is a loop, not a block** | gain $N_f$ with an integrator in its feedback path | a Derivative block turns the corner of the step into an impulse and every step of sensor noise into a spike (§2-7); the loop form has the ceiling $K_d N_f$ built in |
| **The excess is $\tau - u$, taken after the limit** | a Sum with $\tau$ on its plus input and $u$ on its minus input | taken the other way round the sign is wrong and the "anti-windup" winds the integrator faster; taken before the limit it is always zero |
| **Rows P, D, I from the top** | the integrator's junction at the bottom | the back-calculation line then comes up into it from below without crossing any other line; `check_overlaps` is 0 |
| **The plant sits at the height of the controller's output** | the force enters it on one straight segment | the lines to the plant and to the log would otherwise cross the plant block |

---

## Why problem 2's force is 129.6 N

At the instant of the step the error jumps from 0 to 1 m. The proportional branch jumps to $K_p \cdot 1 = 10$ N. The filtered derivative of a unit jump starts at $K_d N_f = 6 \cdot 20 = 120$ N and decays with time constant $1/N_f = 50$ ms. Together, $130$ N.

The checker measures $129.6$ N, and the $0.4$ N is the solver, not the law. The fourth stage of the `ode4` step that ends at $t = 1$ s already sees the step, so by the first logged sample the filter state has moved by $(h/6)\cdot 120 = 0.02$, and $d = N_f(K_d - x) = 20\,(6 - 0.02) = 119.6$ N. The log confirms $d = 119.6000$ N at $t = 1.0000$ s.

Nothing about the response reveals this number, which is the reason step 5 of the tuning order looks at the force separately (§2-9).

---

## Why the integrator goes negative in problem 3

While the force is on its limit, back-calculation drives the integrator towards the value that makes the demand equal to the limit, $I^\star = \tau_{\max} - P - D + (K_i/K_b)\,e$ (§2-8). Just after the step, $P$ alone is $10$ N against a limit of $2.5$ N, so $I^\star$ is negative, and the integrator follows it down. That is the formula working: the integrator is holding the demand at the limit instead of piling up on top of it.
