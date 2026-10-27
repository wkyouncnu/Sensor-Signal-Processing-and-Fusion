# `_tools/` — 무엇이 있고 왜 있는가

> [!note] 이 목록은 `CLAUDE.md` 에서 옮겨 온 것이다
> `CLAUDE.md` 는 **모든 세션의 첫 글자부터** 통째로 읽힌다. 그래서 거기에는
> 폴더의 **모양**만 남기고, 공용 스크립트가 무엇이고 왜 있는지는 이 파일로 내렸다
> (2026-10-27). 한 줄도 고치지 않았다 — 아래는 옮긴 그대로다.
>
> 파일이 실제로 있는지는 `ls _tools/` 가 말한다. 이 파일은 **왜 있는지**를 말한다.

---

```
├── _tools/                  md2pdf.sh · pdf-template.html · marked.min.js
│                            mathjax-tex-svg.js · lab_fig.m · mss_path.m
│                            otter_config.m · otter_B.m · add_otter_plant.m
│                            set_mlfcn.m · mlfcn_params.m · draw_ship.m · track_ships.m · ship_marks.m
│                            gnc_chain.m · gnc_colour.m · add_subsys.m · add_measurement.m
│                            add_sum.m · mss_style.m · export_diagram.m
│                            port_xy.m · row_feed.m · lane_line.m · check_overlaps.m
│                            check_diagonals.m · straighten_lines.m · compact_layout.m
│                              (선은 가로·세로만, 빈 복도는 좁힌다 — §15-31)
│                            add_heading_loop.m · add_speed_loop.m
│                              (4·5 주차가 **함께 쓰는** 제어기 서브시스템 — §15-34)
│                            otter_M.m · add_allocation3.m
│                            add_position_loop.m · add_velocity_loop.m
│                            add_position_loop_ned.m · add_velocity_loop_ned.m
│                              (6 주차 위치제어. 선체고정과 NED 가 **포트 이름·수·순서가 같아서**
│                               빌더의 한 가지가 양쪽을 만든다 — §15-52)
│                            ensure_base_vars.m · hmi_bind.m · image_button.m  (대화형 모델)
│                            run_alone.m                            (Run 만 눌러도 돈다 —
│                              InitFcn 이 매 Run 마다 부른다. MSS 경로 · 없는 변수만 채우기 ·
│                              실시간 화면 켜기 · pace. 있는 값은 **덮지 않는다**)
│                            crosstrack_err.m · wp_switch.m · path_plot.m
│                            verify_guidance.m · verify_alos.m        (W05 유도)
│                            run_sim.m · step_metrics.m · recovery_time.m · prop_thrust.m
│                            verify_constants.m · verify_w01_theory.m · live_track.m · base_var.m
│                            live_dash.m · live_guidance.m            (도는 동안의 실시간 화면.
│                              live_guidance 는 유도 주차용 — 왼쪽 경로·웨이포인트·궤적·선체,
│                              오른쪽 y_e · u 와 명령 · n_L 과 n_R · 다리 번호. §15-20)
│                            verify_w02_pid.m                          (W02 PID 입문의 식 8개)
│                            vault_shift_weeks.m                       (주차 번호 일괄 이동, 2026-09-21)
│                            vault_shift_files.sh · vault_shift_from.m  (N 주차부터 한 칸 미루기, 2026-10-26.
│                              .sh 가 파일·폴더를 **git mv** 로 옮기고(내림차순이라 이름이 안 부딪힌다),
│                              .m 이 파일 **안**의 참조를 고친다 — sed 가 아닌 이유는 §4-11)
│                            verify_w03_speed.m                        (W03 모델 없는 속도 튜닝의 수치)
│                            verify_w04_heading.m                      (W04 모델 없는 선수각 튜닝의 식과 수치)
│                            verify_w05_guidance.m                     (W05 모델 없는 유도 튜닝: LOS=P, ILOS=PI)
│                            verify_w06_actuation.m                    (W06 선수추진기: B 의 열·계급, 횡력 한계,
│                              누출, 두 좌표계의 등가성, 포화 모양 둘 — 검사 17 개)
│                            verify_w07_allocation.m                   (W07 제어 배분: pinv(B), 잔차, 자르기 대 비율)
│                            verify_w08_waves.m · wave_train.m         (W08 파랑: 스펙트럼 한 실현, 노치 필터)
│                            verify_w09_dp.m                          (W09 위치제어: B 의 계급, 웨더베인, 임무 상태기계)
│                            verify_w10_integration.m                 (W10 통합: 기준 임무, 절제 둘, 두 종류의 한계, 실현 폭)
│                            vault_runall.m · vault_number_audit.m · verify_review_math.m  (전체 검토:
│                              전 스크립트 실행 → 문서 수치를 실행 로그와 대조 → 검토에서 실은 수치 재현)
│                            vault_rename_tau_u.m · vault_unify_ypont.m · w05_beta_fix.m   (기호 통일 변환기)
│                            git_autopush.sh · hook_matlab_rules.sh  (PostToolUse 훅: 맨 clear 금지)
│                            svg2png.sh · svgzoom.sh                 (렌더해서 눈으로 보기)
│                            md_section.sh                           (강의 .md 에서 한 절만.
│                              `-l` 로 절 목록, 번호로 그 절만, `-n` 으로 줄 범위.
│                              145 KB 를 통째로 읽지 않는다 → standing-orders.md §15-65)
│                            tikz2svg.sh                             (그림 조판. 지금 쓰는 것)
│                            w01_euler_R.m · w05_track_curves.awk     (그림 기하 계산)
│                            w03_prop_curve.m                        (추력 곡선 F = k n|n| 그림의 좌표)
│                            ── 아래는 TikZ 이전의 그림 도구다. 기록으로 남겨 두고
│                               **새 그림에는 쓰지 않는다** (figures/*.svg 20장 전부
│                               figures/src/*.tex 로 옮겼다, 2026-09-05)
│                            tex2svg.sh · labels/ · bdiag.sh
│                            w01_6dof_arcs.awk · w01_euler_geo.awk
│                            w03_pseudo_geo.awk · w03_windup_geo.awk
│                            w03_windup_fig.sh · w05_three_laws.sh
│                            a1_column_geo.awk · a1_layouts_geo.awk
│                            w05_los_geo.awk
```
