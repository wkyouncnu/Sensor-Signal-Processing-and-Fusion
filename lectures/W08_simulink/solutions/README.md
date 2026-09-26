# Week 8 · Laboratory Solutions

- Reference answers, not the only correct ones. The checker tests the physics, not the diagram.
- Read them after attempting the problem.

---

## Building and checking

```matlab
cd lectures/W08_simulink/solutions
W08_S1_dp                    % builds W08_S1.slx — all three problems in one block
W08_S_expected               % regenerates the expected-result figures

W08_check(1,'W08_S1')
W08_check(2,'W08_S1')
W08_check(3,'W08_S1')
```

All three pass and `check_overlaps('W08_S1')` is **0**.

```
  W08 problem 1
    after 200 s on a fixed heading of 0 deg, in a 0.30 m/s current:
      the vessel is   56.64 m from the station
      it has been carried   56.64 m to the east
      the largest surge force ever asked of it was 0.04 N

  W08 problem 2
    over the last 50 s, with the bow free:
      |e| mean 0.193 m, max 0.294 m
      the bow settles at -90.6 deg;  the current runs towards 90 deg
      surge force 23.0 N;  the drag at 0.30 m/s is 23.3 N

  W08 problem 3
      t =   40.0 s   hold    -> transit   at (N   0.01, E  -0.00)
      t =  101.7 s   transit -> hold      at (N  40.19, E   1.99)
      t =  141.7 s   hold    -> transit   at (N  39.71, E   0.00)
      t =  186.0 s   transit -> hold      at (N  40.83, E  38.20)
      t =  226.0 s   hold    -> done      at (N  39.73, E  39.96)

    hand_over     peak |X| in the first 10 s of the second hold   |e| over that hold
    1                                              43.3 N                0.420 m
    0                                             120.0 N               25.626 m
```

Two numbers are worth pausing on. In Problem 1 the largest surge force **in two hundred seconds** is $0.04$ N — not small, not sluggish, but absent, while the vessel travels $56.64$ m. And in Problem 2 the force it settles on, $23.0$ N, is the drag of this hull at $0.3$ m/s, $23.3$ N. The vessel is not holding still; it is swimming upstream at exactly the speed of the water.

---

## The three decisions worth defending

| | The choice | Why the alternative is worse |
|---|---|---|
| **The PID is solved in NED, not in the body frame** | $f_N$ and $f_E$ first, the projection onto the bow afterwards | A body-frame loop would have the bow's own motion inside the error, and the direction the force is *wanted* in — which is what Problem 2 steers by — would never be computed at all |
| **`psi_last` holds the heading below $e_{\min}$** | the rule stops updating rather than following a vanishing vector | Near the station $\mathbf{f}$ is almost zero and $\operatorname{atan2}$ of two small numbers is noise. Without the guard the bow wanders continually and the vessel never settles |
| **One controller, three conditions** | `vane`, `mode == 1` and `hand_over` are `if`s inside one block | Three controllers would have three integrators, three sets of gains and three chances to differ in something nobody intended. The exercise is one controller that learns about its situation |

---

## Why $\psi_d$ is logged

Problem 2 is about a heading the controller **chooses**, and a vessel can finish a run pointing into a current for reasons that have nothing to do with the rule under test — drag alone will weathervane a hull that is not being steered at all.

Logging $\psi_d$ lets the checker ask a question a position measurement cannot: did the bow go where it was **told**? The test `the bow follows the command` compares the two and expects agreement to $2°$. A model whose weathervane rule is wrong but whose vessel happens to end up beam-on to the flow fails it.

---

## Problem 1 is a correct controller failing, and that is the point

A student who builds Problem 1 and sees the vessel carried $56$ m downstream will look for a mistake. There is none. Every line is right: the error is right, the gains are the ones §8-4 chose, the integral winds up correctly, and the force $\mathbf{f}$ points upstream the entire time.

What fails is the assumption every previous week was allowed to make — that a force asked for is a force delivered. Weeks 3 to 5 commanded surge and yaw, and both are in the range of $\mathbf{B}$. This is the first time the controller asks for something outside it.

The diagnostic worth keeping is the **surge force trace**. A badly tuned loop produces a large demand and a poor result; an underactuated one produces **no demand at all** in the direction that matters, because the projection of the wanted force onto the available direction is zero. Those two failures look identical in the position plot and nothing alike in the force plot.

---

## What the handover really is

The `hand_over` line is three characters of code and it changes the mission from working to not working. It is worth stating what class of bug it belongs to.

Everything else in this controller is a **function of the present**: the error, the velocity, the projection, the heading command. Run it twice from the same state and it produces the same output. The integral is the exception — it is a memory, and at a change of mode it is a memory of a situation that no longer exists.

Anti-windup (Week 2 §2-11) handles the case where the integral remembers more than the actuator can deliver. This is a different case: the integral remembers something that was **true, deliverable and correct**, and has simply stopped being relevant. No saturation logic detects that, because nothing is saturated at the moment the mode changes — the saturation comes afterwards, as the consequence.

The general rule is the one the lecture states: **a controller that is not in charge must not integrate.** Deciding which controller is in charge is the mission's job, so the mission has to tell it.

---

## What is deliberately missing

No cascade sweep, no wave filter, no guidance.

§8-4's sweep of $K_{p,x}$ — which at $120$ N/m makes the vessel turn $2734°$ and never return — would be a fourth problem and the hour has three. The sea of Week 7 is left off so that one effect is studied at a time; the vessel of Week 9 carries both, and §9-3 measures what each is worth on the same mission.

What this hour establishes is the seam Week 9 then tests: a controller, a mission, and the one piece of state that belongs to neither.
