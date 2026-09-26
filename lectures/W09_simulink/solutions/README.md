# Week 9 · Laboratory Solutions

- Reference answers, not the only correct ones. The checker tests the physics, not the diagram.
- Read them after attempting the problem.

---

## Building and checking

```matlab
cd lectures/W09_simulink/solutions
W09_S1_mission               % builds W09_S1.slx — the mission, with both tests
W09_S_expected               % regenerates the expected-result figures

W09_check(1,'W09_S1')
W09_check(2,'W09_S1')
W09_check(3,'W09_S1')
```

All three pass and `check_overlaps('W09_S1')` is **0**.

```
  W09 problem 1
    leg   transit [s]   speed [m/s]   cross-track at the end [m]   hold [m]
     1         55.5         1.000                0.03             0.433
     2         69.4         1.001                0.25             1.373
     3         62.6         0.998                0.14             0.432
    the modes ran [2 1 2 1 2 3]

  W09 problem 2
    at V_c = 1.3 m/s:
      with the acceptance circle alone   closest pass to waypoint 1  3.67 m
                                         the circle has a radius of  3.00 m
                                         the mission finishes at       --
      with the along-track test of W5    the mission finishes at     291.2

  W09 problem 3
    switch off   week   T [s]   u [m/s]   y_e [m]   dN [N m]   hold [m]
    none          -     277.7     0.999      0.14       1.32      0.746
    use_Ki_u      W3       --     0.725      0.09       1.93      0.940
    use_ssa       W4       --     1.000      0.14      15.96      0.877
    use_Kd        W4    279.6     0.999      0.15       0.89      0.713
    use_ilos      W5    275.2     1.000      0.97       1.23      0.697
    use_pass      W5    277.7     0.999      0.14       1.32      0.746
    use_scale     W6    271.9     1.000      0.06      37.64      1.899
    use_notch     W7    274.9     1.000      0.14       1.80      0.746
    use_vane      W8    258.1     1.001      0.28       5.17      3.681
    hand_over     W8    279.4     1.000      0.14       0.36      0.711
```

The `use_pass` row is identical to the baseline in every column, to every digit printed. That is not a null result: it is a measurement of what the reference conditions **do not test**, and Problem 2 is the condition that does.

---

## The three decisions worth defending

| | The choice | Why the alternative is worse |
|---|---|---|
| **Both arrival tests, joined by `or`** | the circle **and** the along-track test | They fail in opposite situations. A fast slanted pass misses the circle; a vessel that stops short of the waypoint never crosses the half-plane. Either alone leaves a mission that can hang |
| **One block with memory, not three** | `k`, `mode_` and `held` are persistent in one function | Splitting the waypoint index from the mode would let them disagree — and a state machine whose state is in two places is a state machine with two states |
| **The log reads the tags** | `slog` is fed by `From wp` and `From mode`, not branched off the output ports | Three strands down one column overlap, and `check_overlaps` must be 0 before a model is finished (`CLAUDE.md` §5). The same fix was needed in the bench's own `plog` |

---

## Why Problem 3 builds nothing, and is still the hardest

The other eight laboratories in this course end with a model. This one ends with a table, and the work is in making the table mean something.

Two conditions have to hold, and both are easy to break.

**The two runs must differ in one thing.** That is why each week's contribution is a switch inside one model rather than a second model. Two models share nothing by construction: a solver setting, a wave phase, a gain typed twice — any of them can differ, and the difference will be attributed to the week under test. One model run twice cannot differ in anything that was not switched.

**Both runs must be measured the same way.** That is why every number comes from `W09_metrics` and from nowhere else. The temptation in an ablation is to measure each row by whatever shows its effect best — the speed for Week 3, the cross-track for Week 5, the hold for Week 8. A table built that way has nine columns that cannot be read across, and the comparison it appears to offer is not one.

The lecture states the rule as `standing-orders.md` §15-16. It is worth stating the failure it prevents: **an ablation measured inconsistently will always confirm whatever it was arranged to confirm.**

---

## The `ssa` failure, and why it belongs to Problem 3

A student who has built Problems 1 and 2 has a working vessel, and `use_ssa = 0` breaks it completely: $1.09$ revolutions on the third leg, and no mission.

It is worth being precise about where that fault lives, because it is not in the `ssa` line.

- Week 4 derived $\operatorname{ssa}$ on a **step** command and showed why the seam matters. Correct.
- Week 5 chose waypoints by where the survey needed the vessel to go. Also correct.
- Leg 3 of this mission runs due south, at $\pi_p = 180°$ exactly — and $\operatorname{atan2}$ returns $\pi$ on one side of the line and $-\pi$ on the other.

Every piece is right and the composition is not. Neither week could have found it: Week 4's test command never sat on the seam, and Week 5 had no heading loop to break. The `What to try` in the problem sheet moves the last waypoint to $(30, 60)$ and the fault disappears, which is the proof that it was in the seam and not in the block.

This is the class of fault an integration week exists to find, and it is the reason §9-3's table is worth building even though nothing in it is new.

---

## What is deliberately missing

No weather sweep, no realisation spread, no acceptance test.

§9-4 flies the same vessel on five days and §9-6 repeats the reference run under five realisations of one spectrum — both are in the lecture and both would each take an hour. §9-6 in particular is the check that decides whether anything in Problem 3 may be believed: the spread across realisations is $3.4\,\%$, against an ablation effect of a factor of five, so the table stands.

A student who wants the fourth problem should run it: five values of `phase_shift`, the reference mission and `use_vane = 0` at each, and the two bands plotted against one another. If they overlap, Problem 3 measured the day rather than the design — and the way to find out is ten runs and no new model.
