%W07_POSE_RUN  위치·선수각 제어 모델을 돌리고, 명령과 실제를 그린다.
%              Run the position-and-heading model and draw command against
%              actual.
%
%   사용법 / how to use
%       W07_pose_run                명령한 자세까지 한 번 돌고 그림을 저장한다
%                                   one run to the commanded pose, PNGs saved
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

fprintf('\n==== W07 position and heading control, model %s ====\n', mdl);
fprintf('  law %d,  target N %g m  E %g m  psi %g deg,  Kp_pos %g\n', ...
        V.law, V.p_d(1), V.p_d(2), rad2deg(V.psi_set), V.Kp_pos);
fprintf('  speed cap on the outer loop: u %g m/s,  v %g m/s\n', V.u_lim, V.v_lim);

%% 한 번의 위치 제어 — 이 그림이 강의자료에 실린다 --------------------------
%     **`sim` 은 한 번만 부른다** (사용자 지시, 2026-11-25). 바깥 고리 게인
%     `Kp_pos` 를 쓸어 보는 절이 여기 있었으나 지웠다 — `W07_wpt_run` 의
%     $\Delta$ 쓸기와 같은 이유다. 게인을 바꿔 보려면 `W07_0_setup` 에서 고치고
%     다시 돌린다.
%     ONE sim call. A section that swept the outer-loop gain Kp_pos used to
%     stand here and is gone, for the reason the Delta sweep went from
%     W07_wpt_run. To try another gain, change it in W07_0_setup and run again.
set_vars(struct('Kp_pos', V.Kp_pos, 'T_pose', V.T_pose));
%  `sim` 이 도는 동안은 화면에 아무것도 없다. 플랜트가 해석 실행
%  (`coder.extrinsic('otter_tilt4')`)이라 실제 시간은 운항 시간의 몇 배다.
%  그래서 **얼마나 조용할 것인지** 미리 말해 둔다 / say how long the silence is
fprintf('   one run of %g s of motion; no output until it ends\n', V.T_pose);
t0 = tic;
sim(mdl);
fprintf('   the run took %.0f s\n', toc(t0));
W07_plot_pose(fullfile(img, 'W07_pose'));   % 수치는 그 함수가 찍는다 / it prints

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
