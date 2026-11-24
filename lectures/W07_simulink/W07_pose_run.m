%W07_POSE_RUN  위치·선수각 제어 모델을 돌리고, 명령과 실제를 그린다.
%              Run the position-and-heading model and draw command against
%              actual.
%
%   사용법 / how to use
%       W07_pose_run                아래 `SEC` 의 절을 차례로 돌린다
%       한 줄을 `%` 로 막으면 그 절이 빠진다 / one % removes one section
%
%   무엇을 보이려는 운항인가 / what the run is for
%       (0, 0) 에서 선수각 0 도로 떠서 (10, 10) 에 선수각 45 도로 **선다.**
%       웨이포인트 추종과 달리 배가 가야 할 방향과 향해야 할 방향이 **다르고**,
%       그래서 세 자유도를 따로 명령할 수 있어야 한다. 추진기 넷이 모두 돌아가는
%       형상이 그것을 할 수 있다는 것이 이 절의 요점이다.
%       The vessel leaves (0, 0) heading 0 deg and comes to rest at (10, 10)
%       heading 45 deg. Unlike waypoint following, where it goes and where it
%       points are different, which is what four tilting units make possible.
%
%   `sim` 을 본문에서 부르는 이유는 `W07_wpt_run` 과 같다 / the same reason as
%   in W07_wpt_run: inside a function the logs would not reach this workspace.
%
%   See also W07_4_BUILD_POSE, W07_PLOT_POSE, W07_PLOT_SAT, W07_WPT_RUN,
%            W07_0_SETUP.

close all;

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root, '_tools'), here);
mss_path();

mdl = 'W07_pose_dp';
assert(isfile(fullfile(here, [mdl '.slx'])), 'W07:noModel', ...
       '%s.slx 가 없다. 먼저 W07_4_build_pose 를 돌린다 / build it first', mdl);

V = W07_vars();
if ~isfolder(fullfile(here, 'img')), mkdir(fullfile(here, 'img')); end
img = fullfile(here, 'img');

push_vars(V);
animate  = 0;
pace     = 0;
W07batch = true;
W07quiet = true;     % StopFcn 의 그림을 끈다. 이 파일이 대신 그린다

%% 돌릴 절 / the sections to run ---------------------------------------------
%     **B 는 기본에서 빠져 있다** (사용자 지시, 2026-11-24). 절 B 는 `sim` 을
%     세 번 더 돌려 혼자 몇 분을 쓰는데, 강의자료에 실리는 그림은 전부 절 A 가
%     낸다. 숫자가 필요하면 아래 `%` 하나를 지운다.
%     Section B is OFF by default: three more sims, minutes of them, while every
%     figure the lecture carries comes out of section A. Delete the one % to
%     bring the table back.
SEC = { ...
    'A'  'from the origin to (10, 10) m at 45 deg, command beside actual'
%   'B'  'the outer-loop gain Kp_pos, swept'
};
want = @(s) any(strcmp(s, SEC(:,1)));

fprintf('\n==== W07 position and heading control, model %s ====\n', mdl);
fprintf('  law %d,  target N %g m  E %g m  psi %g deg,  Kp_pos %g\n', ...
        V.law, V.p_d(1), V.p_d(2), rad2deg(V.psi_set), V.Kp_pos);
fprintf('  speed cap on the outer loop: u %g m/s,  v %g m/s\n', V.u_lim, V.v_lim);
fprintf('  sections: %s\n', strjoin(SEC(:,1).', ', '));

%% A  한 번의 위치 제어 — 이 절의 그림이 강의자료에 실린다 ------------------
if want('A')
    hdr('A', 'one run to the commanded pose');
    set_vars(struct('Kp_pos', V.Kp_pos, 'T_pose', V.T_pose));
    %  `sim` 이 도는 동안은 화면에 아무것도 없다. 플랜트가 해석 실행
    %  (`coder.extrinsic('otter_tilt4')`)이라 실제 시간은 운항 시간의 몇 배다.
    %  그래서 **얼마나 조용할 것인지** 미리 말해 둔다 / say how long the silence is
    fprintf('   one run of %g s of motion; no output until it ends\n', V.T_pose);
    t0 = tic;
    sim(mdl);
    fprintf('   the run took %.0f s\n', toc(t0));
    W07_plot_pose(fullfile(img, 'W07_pose'));   % 수치는 그 함수가 찍는다 / it prints
end

%% B  바깥 고리 게인 Kp_pos — 무엇이 달라지는가 -----------------------------
%     바깥 고리는 위치 오차를 **속도 명령**으로 바꾼다. 게인이 크면 빨리 가되
%     속도 한계에 더 오래 붙어 있고, 작으면 조용히 가되 늦게 선다. 그 교환을
%     숫자로 본다 — 정착 시간과 지나친 거리.
%     The outer loop turns a position error into a speed command: a high gain
%     arrives sooner but sits on the speed cap, a low one is slower. The table
%     shows the trade as settling time against overshoot.
if want('B')
    hdr('B', 'the outer-loop gain, swept');
    K_SWEEP = [0.15 0.30 0.60];
    SW      = nan(numel(K_SWEEP), 4);
    %  한 줄은 **돌자마자** 찍는다. 표를 끝에서 한 번에 찍으면 그동안 화면이
    %  비어 멎은 것처럼 보이고, 그래서 Ctrl-C 를 누르게 된다 — 그러면 이
    %  스크립트의 끝줄이 돌지 않아 플래그가 남는다 (§15-93)
    %  each row is printed AS IT FINISHES: a table printed only at the end
    %  leaves the screen blank throughout, which reads as a hang and invites
    %  the Ctrl-C that stops the closing line from clearing the flags
    fprintf('\n   settling = the last instant the error leaves the band, +1 sample\n');
    fprintf('   three runs; a row appears as each one ends\n');
    fprintf('    Kp_pos    t to 0.50 m [s]   peak |u| [m/s]   overshoot [m]   took [s]\n');
    for i = 1:numel(K_SWEEP)
        set_vars(struct('Kp_pos', K_SWEEP(i), 'T_pose', V.T_pose));
        t0 = tic;
        sim(mdl);
        SW(i,:) = pstat(K_SWEEP(i));
        fprintf('   %7.2f %16.2f %16.3f %15.3f %11.0f\n', SW(i,:), toc(t0));
    end
    fprintf('   The speed cap is %g m/s: where peak |u| sits on it, the gain is\n', V.u_lim);
    fprintf('   no longer what sets the approach — the cap is.\n');
    set_vars(struct('Kp_pos', V.Kp_pos, 'T_pose', V.T_pose));
end

fprintf('\n==== done ====\n');

%  **플래그를 들고 나가지 않는다.** `W07batch` 와 `W07quiet` 는 이 스크립트가
%  도는 동안만 참이어야 한다. 남겨 두면 그 다음에 사람이 `.slx` 를 열고 Run 을
%  눌렀을 때 `run_alone` 이 실시간 화면을 켜지 않고 StopFcn 이 그림을 내지 않아
%  **아무 창도 뜨지 않는다** — 모델이 고장난 것처럼 보인다 (standing order
%  §15-93). 5·6주차는 `W05_read`·`W06_read` 가 onCleanup 으로 같은 일을 한다.
%  The two flags must be true only while this script runs. Left behind, the
%  next person to open the .slx and press Run gets no live view and no figure
%  at all, because run_alone keeps animate at 0 and the StopFcn returns early.
%  `animate` 와 `pace` 도 함께 지운다. `ensure_base_vars` 는 **없는 변수만**
%  채우므로, 0 으로 남겨 두면 `run_alone` 이 1 로 올리려 해도 그 0 이 이기고
%  실시간 화면이 끝내 뜨지 않는다.
%  animate and pace go too: ensure_base_vars fills only what is MISSING, so a 0
%  left behind outlives run_alone's attempt to raise it and the window stays shut.
clear W07batch W07quiet animate pace

% =========================================================================
function hdr(sec, txt)
fprintf('\n---- %s  %s %s\n', sec, txt, repmat('-', 1, max(0, 56 - numel(txt))));
end

% =========================================================================
function push_vars(V)
%PUSH_VARS  `W07_vars` 의 값을 작업공간에 올린다 / the names the model reads
fn = fieldnames(V);
for i = 1:numel(fn)
    assignin('base', fn{i}, V.(fn{i}));
end
end

% =========================================================================
function set_vars(ov)
%SET_VARS  다음 `sim` 이 쓸 값을 놓고 지난 로그를 지운다 / values, then clear
fn = fieldnames(ov);
for i = 1:numel(fn)
    assignin('base', fn{i}, ov.(fn{i}));
end
evalin('base', 'clear W07pose W07pose_act');
end

% =========================================================================
function s = pstat(K)
%PSTAT  한 번의 운항에서 네 수치만 / four numbers out of one run
%       정착 판정은 `W07_plot_pose` 와 **같다** — 마지막으로 띠를 벗어난 다음
%       표본 / the same settling rule as W07_plot_pose
W = evalin('base', 'W07pose');
t = W.time(:);
y = squeeze(W.signals.values);
if size(y,1) < size(y,2), y = y.'; end
d  = hypot(y(:,7) - y(:,4), y(:,8) - y(:,5));
k  = find(d > 0.50, 1, 'last');
if isempty(k)
    ts = 0;
elseif k == numel(t)
    ts = NaN;
else
    ts = t(k+1);
end
over = max(0, max(hypot(y(:,4), y(:,5))) - hypot(y(end,7), y(end,8)));
s    = [K, ts, max(abs(y(:,1))), over];
end
