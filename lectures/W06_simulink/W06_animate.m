function W06_animate(u, v, r, N, E, psi, t)
%W06_ANIMATE  도는 동안의 실시간 화면 / the live view, while the model runs.
%
%   W06_animate(u, v, r, N, E, psi, t)
%
%   모델의 Animate 블록이 매 스텝 부른다. 그리는 일은 `live_dash` 가 하고 이
%   파일은 **6주차의 설정만** 들고 있다 — 창 이름, 축 범위, 접안점.
%   The model's Animate block calls this every step. live_dash does the drawing;
%   this file holds only the Week 6 settings: window name, axis limits, berth.
%
%   **인자 일곱 개는 `add_measurement` 이 정한다.** Animate 블록을 이 파일이
%   아니라 `_tools/add_measurement`(opts.dash = true) 이 만들고, 그것이 부르는
%   꼴이 `<tag>_animate(u, v, r, N, E, psi, t)` 다. 그래서 명령 선수각 psi_d 는
%   들어오지 않는다 — 선체 위의 명령 방향 광선은 그리지 못한다. 대신 선수각은
%   오른쪽 축에 psi 로 그려지고, 명령값과의 대조는 Run 이 끝난 뒤 W06_plot 의
%   ② 칸이 한다. 광선을 되살리려면 공용 도구 둘(add_measurement · live_dash)을
%   고쳐야 하므로 하지 않는다 (§15-34).
%   THE SEVEN ARGUMENTS ARE add_measurement's CHOICE. The Animate block is built
%   by _tools/add_measurement (opts.dash = true), not here, and it calls
%   <tag>_animate(u, v, r, N, E, psi, t). The commanded heading psi_d therefore
%   does not arrive, so the commanded-heading ray is not drawn on the hull. The
%   heading itself is on the right-hand axis, and the comparison against the
%   command is made after the run by panel 2 of W06_plot. Restoring the ray
%   would mean editing two shared tools, which Section 15-34 forbids.
%
%   psi 는 **라디안**으로 온다 (선택기에서 직접, rad2deg 게인을 지나지 않는다).
%   live_dash 가 안에서 한 번 도로 바꾼다 / psi arrives in RADIANS, straight from
%   the selector and not through the rad2deg gain; live_dash converts it once.
%
%   왜 live_guidance 가 아니라 live_dash 인가
%
%   5주차의 `live_guidance` 는 **유도** 화면이다 — 횡방향 오차 y_e, 다리 번호,
%   웨이포인트 전환이 축으로 들어 있다. 6주차에는 다리가 없다. 보아야 하는 것은
%   **여섯 상태 전부**다: 횡속도 v 가 0 이 아닌 채로 배가 옆으로 가고 있는지,
%   선수각이 접안 각도에 붙어 있는지, 선회율이 0 으로 죽었는지. 그것을 한 창에
%   놓는 것이 `live_dash` 다.
%   Week 5's live_guidance is a GUIDANCE view: cross-track error, leg number,
%   waypoint switching. Week 6 has no legs. What has to be watched is all six
%   states -- whether v is non-zero while the hull translates sideways, whether
%   the heading is holding the berthing angle, whether the yaw rate has died to
%   zero. live_dash puts exactly those in one window.
%
%   축 범위는 작업공간이 정한다 (W06_0_setup 의 track_* 네 개). 접안 구간이
%   0.4 m 단위로 끝나므로 범위를 넓게 두면 마지막 몇 미터가 보이지 않는다.
%   The limits come from the workspace (the four track_* variables): the berthing
%   phase ends to within 0.4 m, and a wide window hides that last stretch.
%
%   See also LIVE_DASH, W06_PLOT, W06_1_BUILD_BOW.

o.tag   = 'W06';
o.name  = 'W06 live view  -  the track, the hull, and the six states';
o.title = 'position  (quay at E = 0,  berth marked)';
o.lim   = [base_var('track_Emin',  -4), base_var('track_Emax', 30), ...
           base_var('track_Nmin',  -8), base_var('track_Nmax', 52)];
o.every = base_var('animate_every', 0.5);

%  표시할 점 둘: 접근점과 접안점. 선체가 그 사이 7 m 를 **옆으로** 가는 것이
%  이 주차의 그림이다 / two marks: the approach point and the berth. The hull
%  crossing those 7 m SIDEWAYS is this week's picture.
o.wp = [base_var('app_N',   40), base_var('app_E',   8.2); ...
        base_var('berth_N', 40), base_var('berth_E', 1.2)];

live_dash(u, v, r, N, E, psi, t, o);
end
