%W07_WPT_RUN  웨이포인트 추종 모델을 돌리고, 명령과 실제를 그린다.
%             Run the waypoint-following model and draw command against actual.
%
%   사용법 / how to use
%       W07_wpt_run                 네 다리를 한 번 돌고 그림 둘을 저장한다
%                                   one run of the route, two PNGs saved
%
%   이 파일이 하는 일 / what this file does
%       법칙은 모델 안에 있고, 제어기도 모델 안에 있다. 여기서 하는 일은
%       **값을 놓고 `sim` 을 부르고 결과를 그리는 것**뿐이다. 물리를 이 파일에서
%       다시 계산하지 않는다 — 그러면 모델과 어긋날 수 있다.
%       The law and the controllers are in the model. All this file does is
%       place values, call sim and draw. No physics is recomputed here, because
%       a second copy could disagree with the model.
%
%   `sim` 을 본문에서 부르는 이유 / why sim is called from the body
%       `sim` 을 함수 안에서 부르면 To Workspace 블록의 로그가 **그 함수의**
%       작업공간에 생기고, 기본 작업공간에서는 보이지 않는다. 그래서 값을 놓는
%       일만 지역 함수로 두고 `sim` 은 본문에서 부른다.
%       Called inside a function, sim writes its logs into that function's
%       workspace, where nothing else can see them.
%
%   사람이 Simulink 에서 Run 을 눌러도 같은 것이 나온다 / pressing Run works too
%       모델의 StopFcn 이 `W07_plot_wpt` 를 부르고, Animate 블록이
%       `W07wpt_animate` 를 매 스텝 부른다. 이 파일은 그 둘을 조용히 만들고
%       (`W07quiet`·`animate = 0`) 대신 PNG 까지 저장한다.
%       The model's StopFcn draws the same figure and the Animate block draws
%       the live view; this file silences both and saves PNGs instead.
%
%   See also W07_3_BUILD_WPT, W07_PLOT_WPT, W07_PLOT_SAT, W07_POSE_RUN,
%            W07_0_SETUP.

close all;

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root, '_tools'), here);
mss_path();

mdl = 'W07_wpt_los';
assert(isfile(fullfile(here, [mdl '.slx'])), 'W07:noModel', ...
       '%s.slx 가 없다. 먼저 W07_3_build_wpt 를 돌린다 / build it first', mdl);

V = W07_vars();
if ~isfolder(fullfile(here, 'img')), mkdir(fullfile(here, 'img')); end
img = fullfile(here, 'img');

push_vars(V);
animate  = 0;        % 화면을 그리지 않는다 / no live window
pace     = 0;        % 현실 시간으로 기다리지 않는다 / no real-time pacing
W07batch = true;     % run_alone 이 animate 를 올리지 않게 / keep it quiet
W07quiet = true;     % StopFcn 의 그림을 끈다. 이 파일이 대신 그린다

fprintf('\n==== W07 waypoint following, run from the model %s ====\n', mdl);
fprintf('  law %d,  waypoints %d,  Delta %g m,  R_switch %g m,  u_d %g m/s\n', ...
        V.law, numel(V.WP_N), V.Delta, V.R_switch, V.u_d);

%% 네 다리를 한 번 — 이 그림이 강의자료에 실린다 ----------------------------
%     **`sim` 은 한 번만 부른다** (사용자 지시, 2026-11-25). 앞보기 거리
%     $\Delta$ 를 쓸어 보는 절이 여기 있었으나 지웠다. `sim` 을 세 번 더 돌려
%     혼자 몇 분을 쓰는데, 강의자료에 실리는 그림도 표도 전부 이 한 번이 낸다.
%     $\Delta$ 를 바꿔 보려면 `W07_0_setup` 에서 그 값을 고치고 다시 돌린다 —
%     그것이 학생이 실제로 하는 일이고, 쓸기는 그 일을 대신해 주지 않는다.
%     ONE sim call. A section that swept the lookahead distance Delta used to
%     stand here; it cost three more sims and several minutes, and every figure
%     and every number the lecture carries comes out of this single run. To see
%     another Delta, change it in W07_0_setup and run again, which is what the
%     learner does in any case.
set_vars(struct('Delta', V.Delta, 'T_wpt', V.T_wpt));
%  `sim` 이 도는 동안은 화면에 아무것도 없다. 몇 분이 걸리므로, 얼마나
%  기다리는 것인지 **미리** 말해 둔다 / say how long the silence will be
fprintf('   one run of %g s of track; a few minutes, with no output until it ends\n', ...
        V.T_wpt);
t0 = tic;
sim(mdl);
fprintf('   the run took %.0f s\n', toc(t0));
W07_plot_wpt(fullfile(img, 'W07_wpt'));    % 수치는 그 함수가 찍는다 / it prints

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
%PUSH_VARS  `W07_vars` 의 값을 작업공간에 올린다 — 모델이 이 이름들을 읽는다
%           the names the model resolves every Constant against
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
evalin('base', 'clear W07wpt W07wpt_act');
end
