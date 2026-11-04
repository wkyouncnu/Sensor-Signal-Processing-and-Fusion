%W12_K_HARDWARE  강의 §12-12 — 벽이 둘이다. 서보 각과 **회전수**.
%                Lecture 12-12: there are two walls, the servo angle and the
%                shaft speed, and the allocator must know about both.
%
%  §12-10 은 서보 벽만 보았다. 추력에도 벽이 있다 — 회전수의 한계가 그것이다.
%  12-10 looked only at the servo wall. The thrust has a wall too: the shaft
%  speed limit, seen through the thrust curve.
%
%  이 절이 묻는 것 / the question
%      배가 **요구한 힘을 받았는가.** 배분기의 장부가 아니라 운동모델에서 잰다
%      Did the hull receive the force that was asked for? Measured out of the
%      motion model, not read off the allocator's own books
%
%  이 스크립트가 하는 일 / what this script does
%      ① 두 캡의 높이를 추력곡선에서 계산한다   T = k n_max^2
%      ② 법칙 넷을 쇠사슬 끝까지 따라간다       `W12_chain`  ->  `W12_tab_chain`
%      ③ 요구한 힘과 받은 힘, 그리고 두 포화를 그린다  ->  `W12_plot_chain`

root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'_tools'));  mss_path();
here = fileparts(mfilename('fullpath'));
cfg  = otter_config('quad_tilt');
B    = cfg.B;
V    = W12_vars;

%% 캡의 높이 — 회전수 한계를 추력으로 옮긴 것 / the caps, in newtons ------------
%  |n| <= n_max  <=>  |T| <= k n_max^2 이므로 회전수 포화는 **추력 캡과 같은 벽**이다.
%  전진과 후진의 k 가 다르므로 캡의 높이가 둘이다.
P.T_pos = cfg.k_pos * cfg.n_max^2;
P.T_neg = cfg.k_neg * cfg.n_min^2;

P.W         = diag(repmat([1 10], 1, 4));
P.alpha_max = cfg.alpha_max(1);
P.Q         = eye(3);
P.eps_reg   = 1e-4;
P.n_chord   = 3;

fprintf('\n=== 12-12  two walls: the servo angle and the shaft speed ===\n\n');
fprintf('  the shaft speed limits are n_max = %+8.2f and n_min = %+8.2f rad/s\n', ...
        cfg.n_max, cfg.n_min);
fprintf('  through T = k n|n| those become the thrust caps\n');
fprintf('      ahead   T <= k_pos n_max^2 = %.3f * %.2f^2 = %8.3f N\n', ...
        cfg.k_pos, cfg.n_max, P.T_pos);
fprintf('      astern  T <= k_neg n_min^2 = %.3f * %.2f^2 = %8.3f N\n', ...
        cfg.k_neg, abs(cfg.n_min), P.T_neg);
fprintf('  the astern cap is %.0f%% of the ahead cap, and that is what binds\n', ...
        100*P.T_neg/P.T_pos);
fprintf('  at delta = 0 the hull can therefore make at most\n');
fprintf('      X = 2 * %.2f + 2 * %.2f = %.2f N\n', ...
        P.T_pos, P.T_neg, 2*P.T_pos + 2*P.T_neg);

%% 법칙 넷을 쇠사슬 끝까지 / four laws, followed to the end of the chain -------
laws = ["wpinv" "clip" "wls16" "wls16cap"];
RR   = W12_tab_chain(B, cfg, V, P, laws);

%% 그림 둘 / the two figures
W12_plot_chain(RR, cfg, here);
