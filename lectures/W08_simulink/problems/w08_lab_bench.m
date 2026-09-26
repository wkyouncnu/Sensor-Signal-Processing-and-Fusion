function w08_lab_bench(mdl, x0)
%W08_LAB_BENCH  8주차 실습에 주어지는 부분 — 임무 논리, 배분, 선체, 조류.
%               What the Week 8 laboratory is given: the mission logic, the
%               allocation, the hull and the current.
%
%   w08_lab_bench(mdl, x0)
%
%   왜 임무 논리를 주는가 / why the mission logic is given
%       8주차의 문제는 **제어기**다 — 두 방향의 힘을 요구하고, 이 선체가 낼 수
%       있는 방향으로만 그것을 내는 일. 상태기계는 제어가 아니라 임무의 문제이고
%       (규칙 두 줄이다), 그것을 다시 쓰게 하면 시간이 그쪽으로 간다.
%       The Week 8 problems are about the controller: asking for a force in two
%       directions and delivering it in the one direction this hull can push.
%       The state machine is a mission concern, not a control one — two rules —
%       and rewriting it would spend the hour there.
%
%   주어지는 것 / what is provided
%
%       mission     t, x -> [p_d ; mode], the two rules of 8-5. Tags p_d and mode
%                   mode 1 transit, 2 hold, 3 done. With one waypoint it stays
%                   in hold for ever, which is what Problems 1 and 2 want
%       allocation  Week 6's, unchanged
%       Otter USV   n -> twelve states, swimming in a current. Tag x
%       xlog        the twelve states
%       mlog        [N_d ; E_d ; mode], what the mission asked for
%
%   주어지지 않는 것, 그래서 문제인 것 / what is withheld
%
%       the controller: [p_d, mode, x] -> [X ; N], and the log dlog.
%       Its two outputs come back to the bench as the tags X_ctrl and N_ctrl.
%
%   See also W08_P1_START, W08_CHECK, W08_S1_DP.

%% ---- 임무 논리 / the mission logic ------------------------------------
add_block('simulink/Sources/Clock', [mdl '/clock'], 'Position', [x0 216 x0+20 236]);
blk = [mdl '/mission'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [x0+70 150 x0+280 300]);
set_mlfcn(blk, { ...
'function [p_d, mode] = mission(t, x, WP_N, WP_E, R_arrive, T_hold, h)'
'%#codegen'
'%MISSION  8주차 §8-5 의 상태기계. 규칙은 둘뿐이다.'
'%         The state machine of Week 8 §8-5: two rules only.'
'%'
'%    이동 중이고 목표에 R_arrive 안으로 들어오면  -> 유지, 시계를 0 으로'
'%    유지 중이고 T_hold 가 지나면                -> 다음 지점, 이동으로'
'%'
'%    in transit and inside R_arrive  -> hold, and reset the clock'
'%    in hold and T_hold has passed   -> the next waypoint, and transit'
'%'
'%  웨이포인트가 하나뿐이면 배는 처음부터 유지 모드에 있고 거기 머문다 —'
'%  1·2번 문제가 원하는 것이 그것이다.'
'%  With a single waypoint the vessel starts in hold and stays there, which is'
'%  what Problems 1 and 2 want.'
'persistent k mode_ held'
'if isempty(k), k = 1; mode_ = 1; held = 0; end'
'd = hypot(WP_N(k) - x(7), WP_E(k) - x(8));'
'if mode_ == 1 && d < R_arrive'
'    mode_ = 2;  held = 0;'
'elseif mode_ == 2'
'    held = held + h;'
'    if held >= T_hold'
'        if k < numel(WP_N), k = k + 1;  mode_ = 1;  else, mode_ = 3; end'
'    end'
'end'
'p_d  = [WP_N(k); WP_E(k)];'
'mode = mode_;'}, 'p_d', '[2 1]', 'h');
mlfcn_params(blk, {'WP_N','WP_E','R_arrive','T_hold','h'});
add_line(mdl, 'clock/1', 'mission/1', 'autorouting','smart');
add_block('simulink/Signal Routing/From', [mdl '/x for mission'], 'GotoTag','x', ...
          'Position', [x0-10 260 x0+50 280]);
add_line(mdl, 'x for mission/1', 'mission/2', 'autorouting','smart');
MT = {'p_d','mode'};
for i = 1:2
    add_block('simulink/Signal Routing/Goto', [mdl '/' MT{i} ' out'], ...
              'GotoTag', MT{i}, 'Position', [x0+320 170+70*(i-1) x0+390 190+70*(i-1)]);
    add_line(mdl, sprintf('mission/%d', i), [MT{i} ' out/1'], 'autorouting','smart');
end

%% ---- 임무가 요구한 것을 기록 / what the mission asked for, logged ------
add_block('simulink/Signal Routing/Mux', [mdl '/mlog mux'], 'Inputs','2', ...
          'Position', [x0+440 160 x0+445 260]);
add_line(mdl, 'mission/1', 'mlog mux/1', 'autorouting','smart');
add_line(mdl, 'mission/2', 'mlog mux/2', 'autorouting','smart');
add_block('simulink/Sinks/To Workspace', [mdl '/mlog'], ...
          'VariableName','mlog', 'SaveFormat','Structure With Time', ...
          'Position', [x0+490 190 x0+560 230]);
add_line(mdl, 'mlog mux/1', 'mlog/1', 'autorouting','smart');

%% ---- 제어기가 낸 것을 모아 배분으로 / the controller's two demands -----
add_block('simulink/Signal Routing/Mux', [mdl '/tau'], 'Inputs','2', ...
          'Position', [x0+660 400 x0+665 480]);
CT = {'X_ctrl','N_ctrl'};
for i = 1:2
    add_block('simulink/Signal Routing/From', [mdl '/' CT{i} ' in'], ...
              'GotoTag', CT{i}, 'Position', [x0+560 405+40*(i-1) x0+630 425+40*(i-1)]);
    add_line(mdl, [CT{i} ' in/1'], sprintf('tau/%d', i), 'autorouting','smart');
end

blk = [mdl '/allocation'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [x0+710 390 x0+900 490]);
set_mlfcn(blk, { ...
'function n = allocation(tau, y_pont, k_pos, k_neg, T_max, T_min)'
'%#codegen'
'%  6주차의 배분 그대로 / the allocation of Week 6, unchanged'
'T1 = tau(1)/2 + tau(2)/(2*y_pont);'
'T2 = tau(1)/2 - tau(2)/(2*y_pont);'
's = 1;'
'if T1 > T_max, s = min(s, T_max/T1); end'
'if T2 > T_max, s = min(s, T_max/T2); end'
'if T1 < T_min, s = min(s, T_min/T1); end'
'if T2 < T_min, s = min(s, T_min/T2); end'
'T1 = s*T1;  T2 = s*T2;'
'k1 = k_pos;  if T1 < 0, k1 = k_neg; end'
'k2 = k_pos;  if T2 < 0, k2 = k_neg; end'
'n = [sign(T1)*sqrt(abs(T1)/k1); sign(T2)*sqrt(abs(T2)/k2)];'}, 'n', '[2 1]');
mlfcn_params(blk, {'y_pont','k_pos','k_neg','T_max','T_min'});
add_line(mdl, 'tau/1', 'allocation/1', 'autorouting','smart');

%% ---- 선체와 로그 / the hull and the state log --------------------------
add_otter_plant(mdl, 'Otter USV', [x0+960 400 x0+1120 480], otter_config('base'));
set_param([mdl '/Otter USV'], 'BackgroundColor', gnc_colour('plant'));
add_line(mdl, 'allocation/1', 'Otter USV/1', 'autorouting','smart');
add_block('simulink/Signal Routing/Goto', [mdl '/x out'], 'GotoTag','x', ...
          'Position', [x0+1160 430 x0+1220 450]);
add_line(mdl, 'Otter USV/1', 'x out/1', 'autorouting','smart');
add_block('simulink/Sinks/To Workspace', [mdl '/xlog'], ...
          'VariableName','xlog', 'SaveFormat','Structure With Time', ...
          'Position', [x0+1160 520 x0+1230 560]);
add_block('simulink/Signal Routing/From', [mdl '/x for log'], 'GotoTag','x', ...
          'Position', [x0+1060 530 x0+1130 550]);
add_line(mdl, 'x for log/1', 'xlog/1', 'autorouting','smart');
end
