# Week 4 · Laboratory Problems — build the heading autopilot in Simulink

- Course: USV Guidance, Navigation and Control (Graduate) · Department of Autonomous Vehicle System Engineering
- Time: **one hour**, immediately after the Week 4 lecture hour
- Three problems, in order. Each one adds one branch to the previous answer.

---

## What this hour is for

Week 3 closed a loop around a **speed** and found an error that no gain removed, no ringing, and a derivative term that only hurt. This hour closes the same loop around an **angle** and finds the opposite on all three counts. The difference lies in the axis, not in the controller.

The hull and the control allocation are provided. The loop that decides what yaw moment to demand is the exercise.

---

## Before starting

```matlab
cd lectures/W04_simulink/problems
W04_P1_start                 % creates W04_P1.slx — hull and allocation only
W04_check(1)                 % run this whenever, as often as needed
```

The solver is already set to fixed-step `ode4` at `h = 0.02` s. **Do not change it.**

> [!important] Two requirements on every model
> - A To Workspace block named **`xlog`**, format **`Structure With Time`**, fed by the plant's twelve-state output. The heading is state **12**.
> - The blocks use the variable names `Kp`, `Ki`, `Kd`, `Nf`, `use_ssa`, `psi_step` and `t_step`. The checker sets them; a number typed into a block is not changed by the checker.

---

## Problem 1 · Proportional only (20 minutes)

**Build.** A Step of `psi_step` degrees at `t_step`, converted to radians, the error, `ssa`, one gain, into the allocation's `tau_N`.

```
Step ψ_d [deg] → pi/180 → (+)(−) → ssa → Kp → τ_N → Control allocation → Otter USV
                             ↑                                              ↓
                             └──────────────────  ψ (state 12)  ←──────────┘
```

**Predict before running.** In Week 3, P alone left a speed error at every gain. What error will P leave on the heading, and why?

**Verify.** `W04_check(1)`, a $10°$ step.

| $K_p$ | steady error | overshoot |
|---|---|---|
| $100$ | $0$ | $5.8$ % |
| $300$ | $0$ | $12.2$ % |

**What a correct model produces**

![Problem 1, expected result](img/W04_P1_expected.png)

| Reading the figure | |
|---|---|
| left | both gains arrive at $10°$; the larger one arrives sooner and rings more |
| right | the same runs as error; both go to zero |
| the check | if a trace settles short of $10°$, the feedback is not the heading — the Selector must pick state 12 |

**The point.** The heading is the running sum of the turn rate, so the plant already contains an integrator: the error goes to zero with P alone. Unlike the speed of Week 3, the heading also rings, because the heading, like the position of Week 2, can overshoot.

---

## Problem 2 · The derivative (20 minutes)

**Build.** One more branch: the error through **one Transfer Fcn**, numerator `[Kd*Nf 0]`, denominator `[1 Nf]`, added to the proportional term — the `D filter` of Week 2.

**Predict before running.** In Week 3 the derivative made the speed loop worse. The heading is an angle, like a position. Which way will the overshoot move as $K_d$ rises?

**Verify.** `W04_check(2)`, $K_p = 300$, a $10°$ step.

| $K_d$ | overshoot |
|---|---|
| $0$ | $12.18$ % |
| $50$ | $4.10$ % |
| $100$ | $0.39$ % |

**What a correct model produces**

![Problem 2, expected result](img/W04_P2_expected.png)

| Reading the figure | |
|---|---|
| left | four responses to the same step; the overshoot falls as $K_d$ rises |
| right | the overshoot against $K_d$ |
| the check | if the overshoot rises with $K_d$, the sign of the derivative branch is reversed |

**The point.** On the heading the derivative is a damper again, as on the mass of Week 2. The term did not change between Weeks 3 and 4; the axis did.

---

## Problem 3 · The wrap (20 minutes)

**Build.** A Switch driven by the Constant `use_ssa`: its upper input is the error through `ssa`, a Fcn block with `atan2(sin(u), cos(u))`; its lower input is the raw error.

$$
\text{ssa}(e) = \operatorname{atan2}(\sin e,\ \cos e) \ \in (-\pi,\ \pi]
$$

**Set up the test.** The checker starts the vessel at $\psi = 170°$ and commands $\psi_d = -170°$ from $t = 0$. The two headings are **$20°$ apart**.

**Verify.** `W04_check(3)`, $K_p = 300$, $K_d = 100$.

| | turn executed |
|---|---|
| with the wrap | $+20°$ |
| without it | $-340°$ |

**What a correct model produces**

![Problem 3, expected result](img/W04_P3_expected.png)

| Reading the figure | |
|---|---|
| left | heading, **unwrapped**; one run turns $20°$, the other $340°$ the other way; both end at the same physical heading |
| right | the yaw rates have **opposite sign** for the whole manoeuvre |
| the check | if the two traces are identical, `use_ssa` is not reaching the Switch |

**The point.** Without the wrap the error is computed as $-340°$ and the vessel goes the long way round — seventeen times further, for the same commanded heading.

---

## Marking

| | Weight | What is being marked |
|---|---|---|
| Problem 1 | 30 | `W04_check(1)` passes; why the error is zero is stated in one sentence |
| Problem 2 | 40 | `W04_check(2)` passes; why the derivative damps here and hurt in Week 3 is stated |
| Problem 3 | 30 | `W04_check(3)` passes; the cost of omitting `ssa` is quantified |

---

## If something goes wrong

| Symptom | Cause | Fix |
|---|---|---|
| `The model has no To Workspace block whose variable name is xlog` | the variable name is still `simout` | rename it |
| the heading settles short of the command | the feedback is not state 12 | the Selector index must be 12 |
| the vessel spins continuously | the error sign is reversed | the sum is $\psi_d - \psi$ |
| the overshoot rises with $K_d$ | the derivative branch has the wrong sign | add it with $+$, the error already carries the sign |
| the two Problem 3 traces are identical | `use_ssa` never reaches the Switch | a Constant block with the value `use_ssa`, into the Switch's middle input |
| angles 57 times too large or small | degrees and radians mixed | every angle inside the loop is in radians; convert once, at the command |

Reference answers are in `../solutions/`. Read them **after** attempting the problems.
