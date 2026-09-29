function W05_animate(N, E, psi_deg, y_e, u, u_d, n, wp, t)
%W05_ANIMATE  모델이 도는 동안 실시간 화면을 그린다.
%             Draw the live view while the model runs.
%
%   모델 안의 Animate 블록이 매 스텝 부른다. 손으로 부를 일은 없다.
%   화면의 내용을 바꾸려면 이 파일이 아니라 `_tools/live_guidance.m` 을 고친다 —
%   유도 주차가 함께 쓰는 파일이다.
%
%   Called at every step by the Animate block inside the model; there is no
%   reason to call it by hand. To change what the live view shows, edit
%   _tools/live_guidance.m, which the guidance weeks share.
%
%   끄는 법 / to switch it off
%       W05_0_setup 에서 `animate = 0`. 캔버스의 Constant 하나가 그 값을 읽는다.
%       그러면 Animate 블록은 아무것도 하지 않는다 — 블록을 빼지 않는다.
%       Set animate = 0 in W05_0_setup; a Constant on the canvas reads it and the
%       Animate block then does nothing. No block is removed.
%
%   현실 시간으로 / in real time
%       `pace = 1` 이면 시뮬레이션을 현실 시간에 맞춰 돌린다 (Simulink 의
%       Simulation Pacing). 0 이면 최대 속도로 돈다. 수업에서 보여 줄 때는 1,
%       수치를 낼 때는 0 이다 — 결과는 같고 걸리는 시간만 다르다.
%       pace = 1 runs the simulation at wall-clock speed; 0 runs it as fast as it
%       can. The results are identical; only the waiting differs.
%
%   축 범위와 갱신 간격은 작업공간에서 읽는다. 보이는 창을 넓히려면 모델이 아니라
%   W05_0_setup 을 고친다 / the limits and the redraw interval come from the
%   workspace, so widening the view is an edit to the setup script, not the model.

o.tag   = 'W05';
o.name  = 'W05 live view  —  guidance, speed and the two shafts';
o.lim   = [base_var('track_Emin', -30), base_var('track_Emax', 140), ...
           base_var('track_Nmin', -30), base_var('track_Nmax', 100)];
o.every = base_var('animate_every', 0.5);
o.wp    = [base_var('WP_N', []), base_var('WP_E', [])];

live_guidance(N, E, psi_deg, y_e, u, u_d, n, wp, t, o);
end
