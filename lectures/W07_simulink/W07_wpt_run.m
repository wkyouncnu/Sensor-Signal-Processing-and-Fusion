%W07_WPT_RUN  웨이포인트 추종 모델을 돌리고, 명령과 실제를 그린다.
%             Run the waypoint-following model and draw command against actual.
%
%   사용법 / how to use
%       W07_wpt_run                 아래 `SEC` 의 절을 차례로 돌린다
%       한 줄을 `%` 로 막으면 그 절이 빠진다 / one % removes one section
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

%% 돌릴 절 / the sections to run ---------------------------------------------
SEC = { ...
    'A'  'the four-leg route, with every command beside what happened'
    'B'  'the lookahead distance Delta, swept over the first two legs'
};
want = @(s) any(strcmp(s, SEC(:,1)));

fprintf('\n==== W07 waypoint following, run from the model %s ====\n', mdl);
fprintf('  law %d,  waypoints %d,  Delta %g m,  R_switch %g m,  u_d %g m/s\n', ...
        V.law, numel(V.WP_N), V.Delta, V.R_switch, V.u_d);
fprintf('  sections: %s\n', strjoin(SEC(:,1).', ', '));

%% A  네 다리를 한 번 — 이 절의 그림이 강의자료에 실린다 --------------------
if want('A')
    hdr('A', 'one run of the whole route');
    set_vars(struct('Delta', V.Delta, 'T_wpt', V.T_wpt));
    sim(mdl);
    W07_plot_wpt(fullfile(img, 'W07_wpt'));    % 수치는 그 함수가 찍는다 / it prints
end

%% B  앞보기 거리 Delta — 무엇이 달라지는가 ---------------------------------
%     Delta 는 "얼마나 앞을 보는가" 다. 작으면 다리에 빨리 붙되 선수각이
%     바쁘고, 크면 조용히 돌되 다리에서 더 벌어진다. 그 교환을 숫자로 본다.
%     Delta is how far ahead the vessel aims: small acquires the leg quickly
%     but works the heading hard, large turns quietly but sits further off.
if want('B')
    hdr('B', 'the lookahead distance, swept');
    D_SWEEP = [2 5 10];
    T_B     = 180;            % 앞의 두 다리까지 / the first two legs only
    SW      = nan(numel(D_SWEEP), 4);
    for i = 1:numel(D_SWEEP)
        set_vars(struct('Delta', D_SWEEP(i), 'T_wpt', T_B));
        sim(mdl);
        SW(i,:) = wstat(D_SWEEP(i));
    end
    fprintf('\n   over %g s, from the instant |y_e| first falls below Delta\n', T_B);
    fprintf('    Delta [m]   |y_e| rms [m]   |y_e| max [m]   |psi err| rms [deg]\n');
    fprintf('   %8.1f %14.3f %15.3f %20.3f\n', SW(:, [1 2 3 4]).');
    fprintf('   Larger Delta turns the vessel less and keeps it further from the leg.\n');
    set_vars(struct('Delta', V.Delta, 'T_wpt', V.T_wpt));
end

fprintf('\n==== done ====\n');

% =========================================================================
function hdr(sec, txt)
fprintf('\n---- %s  %s %s\n', sec, txt, repmat('-', 1, max(0, 56 - numel(txt))));
end

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

% =========================================================================
function s = wstat(D)
%WSTAT  한 번의 운항에서 네 수치만 / four numbers out of one run
%       구간 규칙은 `W07_plot_wpt` 과 **같다** — `|y_e|` 가 처음 Delta 아래로
%       내려간 뒤부터 끝까지다 / the same window rule as W07_plot_wpt
W   = evalin('base', 'W07wpt');
y   = squeeze(W.signals.values);
if size(y,1) < size(y,2), y = y.'; end
y_e = y(:,9);
e   = mod(y(:,6) - y(:,7) + 180, 360) - 180;
k0  = find(abs(y_e) < D, 1, 'first');
if isempty(k0), k0 = 1; end
w   = k0:size(y,1);
s   = [D, sqrt(mean(y_e(w).^2)), max(abs(y_e(w))), sqrt(mean(e(w).^2))];
end
