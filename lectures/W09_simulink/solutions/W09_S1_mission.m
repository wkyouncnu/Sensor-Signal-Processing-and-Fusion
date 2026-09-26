function W09_S1_mission(mdl)
%W09_S1_MISSION  9주차 실습의 모범답안 모델을 만든다.
%                Build the reference answer to the Week 9 laboratory.
%
%   >> W09_S1_mission               W09_S1.slx 를 만든다 / creates W09_S1.slx
%
%   한 블록, 두 규칙, 두 판정 / one block, two rules, two tests
%       1번 문제는 규칙 둘이고, 2번 문제는 그 둘 중 첫째가 쓰는 **판정**을 하나
%       더 붙이는 것이다. 3번 문제는 아무것도 만들지 않는다 — 이미 다 있는
%       배를 아홉 번 돌려 재는 것이 전부다.
%       Problem 1 is two rules; Problem 2 adds one more test to the first of
%       them; Problem 3 builds nothing at all and measures the vessel nine times.
%
%   See also W09_CHECK, W09_P1_START, W09_S_EXPECTED.

if nargin < 1 || isempty(mdl), mdl = 'W09_S1'; end

here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week, fullfile(week,'problems'), here);
mss_path();

out = fullfile(here, [mdl '.slx']);
bdclose(mdl);
if isfile(out), delete(out); end

new_system(mdl);
set_param(mdl, 'SolverType','Fixed-step', 'Solver','ode4', ...
               'FixedStep','h', 'StartTime','0', 'StopTime','T_final', ...
               'ReturnWorkspaceOutputs','off');

%  출발 모델과 같은 시험대 / the same bench as the starting model
w09_lab_bench(mdl, 140);

%% ---- 임무 논리 / the mission logic ------------------------------------
blk = [mdl '/mission'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [300 740 560 900]);
set_mlfcn(blk, mission_code(), 'wp', '[1 1]', 'h');
mlfcn_params(blk, {'WP_N','WP_E','R_arrive','T_hold','use_pass','h'});
add_block('simulink/Signal Routing/From', [mdl '/x mission'], 'GotoTag','x', ...
          'Position', [200 810 270 830]);
add_line(mdl, 'x mission/1', 'mission/1', 'autorouting','smart');
MT = {'wp','mode'};
for i = 1:2
    add_block('simulink/Signal Routing/Goto', [mdl '/' MT{i} ' out'], ...
              'GotoTag', MT{i}, 'Position', [610 770+60*(i-1) 680 790+60*(i-1)]);
    add_line(mdl, sprintf('mission/%d', i), [MT{i} ' out/1'], 'autorouting','smart');
end

%% ---- 로그 / the log ----------------------------------------------------
%  로그는 태그에서 받는다. 출력 포트에서 가지를 치면 선이 겹친다 —
%  check_overlaps 가 0 이어야 모델이 끝난 것이다 (CLAUDE.md §5).
%  The log reads the tags rather than branching off the output ports, which
%  would cross a line: check_overlaps must be 0 before a model is finished.
add_block('simulink/Signal Routing/Mux', [mdl '/slog mux'], 'Inputs','2', ...
          'Position', [800 770 805 850]);
for i = 1:2
    add_block('simulink/Signal Routing/From', [mdl '/' MT{i} ' log'], ...
              'GotoTag', MT{i}, 'Position', [700 770+60*(i-1) 770 790+60*(i-1)]);
    add_line(mdl, [MT{i} ' log/1'], sprintf('slog mux/%d', i), 'autorouting','smart');
end
add_block('simulink/Sinks/To Workspace', [mdl '/slog'], ...
          'VariableName','slog', 'SaveFormat','Structure With Time', ...
          'Position', [850 790 920 830]);
add_line(mdl, 'slog mux/1', 'slog/1', 'autorouting','smart');

a = Simulink.Annotation([mdl '/note']);
a.Text = strjoin({ ...
'WEEK 9 SOLUTION  -  THE MISSION, AND THE TEST INSIDE IT'
''
'   P1  two rules, and a block with memory so that it can have a clock'
'   P2  the arrival test, which is where the mission was fragile:'
''
'         the circle asks    am I NEAR the waypoint'
'         Week 5 asks        have I gone PAST it'
''
'       A vessel that passes cannot miss a half-plane. The circle is kept as'
'       well, so a vessel that stops short of a waypoint still switches.'
''
'   P3  nothing is built. The vessel is flown nine times, once with each'
'       week removed, and every number comes from one W09_metrics.'}, newline);
a.Position = [300 960 1240 1140];
a.HorizontalAlignment = 'left';
a.BackgroundColor = 'lightBlue';

mss_style(mdl);
save_system(mdl, out);
n = check_overlaps(mdl);
close_system(mdl, 0);
fprintf('\n  built %s   (overlapping lines: %d)\n\n', out, n);
end

% =========================================================================
function C = mission_code()
C = {
'function [wp, mode] = mission(x, WP_N, WP_E, R_arrive, T_hold, use_pass, h)'
'%#codegen'
'%MISSION  임무는 상태기계다. 규칙은 둘뿐이고, 판정은 그 안에 있다.'
'%         A mission is a state machine: two rules, with a test inside one.'
'%'
'%  이 블록은 **기억을 가진다** — 어느 지점으로 가고 있는지(k), 무엇을 하는'
'%  중인지(mode_), 얼마나 오래 붙잡고 있었는지(held). 그래서 고정 스텝 h 로'
'%  이산 실행된다 (set_mlfcn 의 다섯째 인수).'
'%  This block has memory — which waypoint, which mode, how long it has held —'
'%  so it runs at the fixed step h.'
'persistent k mode_ held'
'if isempty(k), k = 1; mode_ = 1; held = 0; end'
'%'
'%  ── 도착 판정 / the arrival test (문제 2) ─────────────────────────────'
'%     원 판정: 지점에 **가까운가**. 빠르게 비스듬히 지나가면 놓칠 수 있고,'
'%     놓치면 색인이 넘어가지 않아 배는 끝난 다리를 영원히 달린다.'
'%     통과 판정(5주차): 지점을 **지났는가**. 다리 방향으로 남은 거리를 재어'
'%     음수가 되면 지난 것이다. 비스듬히 지나가도 반평면은 놓칠 수 없다.'
'%     The circle asks whether the vessel is NEAR the waypoint; a fast, slanted'
'%     pass can miss it, and then the index never advances and the vessel runs'
'%     a completed leg for ever. Week 5''s test asks whether it has gone PAST:'
'%     the distance still to run along the leg, negative once the waypoint is'
'%     behind. A vessel that passes cannot miss a half-plane.'
'%'
'%     둘을 **함께** 둔다. 통과 판정만 두면 지점 앞에서 멈춘 배가 영영 넘어가지'
'%     못한다 / both are kept: with the along-track test alone, a vessel that'
'%     stops short of a waypoint would never switch.'
'd = hypot(WP_N(k) - x(7), WP_E(k) - x(8));'
'if k > 1, N0 = WP_N(k-1);  E0 = WP_E(k-1);  else, N0 = 0;  E0 = 0;  end'
'pi_p   = atan2(WP_E(k) - E0, WP_N(k) - N0);'
'x_left = (WP_N(k) - x(7))*cos(pi_p) + (WP_E(k) - x(8))*sin(pi_p);'
'reached = d < R_arrive || (use_pass ~= 0 && x_left < 0);'
'%'
'%  ── 두 규칙 / the two rules (문제 1) ──────────────────────────────────'
'if mode_ == 1 && reached'
'    mode_ = 2;  held = 0;'
'elseif mode_ == 2'
'    held = held + h;'
'    if held >= T_hold'
'        if k < numel(WP_N), k = k + 1;  mode_ = 1;  else, mode_ = 3; end'
'    end'
'end'
'wp = k;  mode = mode_;'
};
end
