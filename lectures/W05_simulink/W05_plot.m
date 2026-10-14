function W05_plot()
%W05_PLOT  Run 을 누르면 이것이 돈다 — 절 스크립트와 같은 그림을 그린다.
%          Called when Run finishes: draws what the section scripts draw.
%
%   모델의 StopFcn 이 이 함수를 부른다 (W05_1_build_guidance). 그래서 **시뮬링크만
%   돌려도** 궤적과 결과가 나온다 — `.m` 을 따로 돌릴 필요가 없다. 절 스크립트는
%   같은 것을 여러 값에 대해 한 번에 할 뿐이다.
%   The model's StopFcn calls this, so running Simulink alone produces the track
%   and the numbers; the section scripts only do the same thing for several
%   values at once.
%
%   그리는 것 / what it draws
%       왼쪽   항적 — 경로·웨이포인트·선체와 선수 방향 (track_ships)
%       오른쪽 ① 횡방향 오차 y_e  ② 명령 선수각과 선수각  ③ **명령 속도와 실제 속도**
%              ④ 좌현·우현 축 회전수  ⑤ 웨이포인트 번호
%   찍는 것 / what it prints
%       다리마다의 |y_e| 평균과 최대, 속도, 그리고 전환이 일어난 시각
%
%   범례 / the legends
%       전환 시각을 긋는 세로선에는 `HandleVisibility','off'` 를 준다. 주지 않으면
%       범례에 data1, data2, data3 이 딸려 들어온다 — 실제로 그렇게 나왔다.
%       The switching lines are drawn with HandleVisibility off; without it they
%       enter the legend as data1, data2, data3, which is what happened once.

%  절 스크립트(W05_read)가 돌리는 중이면 아무것도 하지 않는다. 그때의 로그는 `out`
%  안에 있고 기본 작업공간의 W05log 는 **직전 Run 이 남긴 낡은 것**이다 — 그것을
%  다시 그리면 실제로 돌린 적 없는 그림이 나온다.
%  Do nothing while a section script is running: its log lives inside `out`, and
%  the base-workspace W05log is then whatever the last Run left behind.
if evalin('base', 'exist(''W05batch'', ''var'')'), return; end
if evalin('base', '~exist(''W05log'', ''var'')'), return; end
L = evalin('base', 'W05log');
y = squeeze(L.signals.values);  if size(y,1) < size(y,2), y = y.'; end
t = L.time;
y_e = y(:,1);  psi_d = y(:,2);  psi = y(:,3);  N = y(:,4);  E = y(:,5);
wp  = y(:,7);  u = y(:,8);  nL = y(:,11);  nR = y(:,12);
WP_N = evalin('base','WP_N');  WP_E = evalin('base','WP_E');

%  명령 속도. 속도 루프가 없는 모델에서는 전진력이 상수이므로 명령 속도가 없다 —
%  그럴 때는 선을 긋지 않는다. 따라가지도 않는 점선은 거짓말이기 때문이다.
%  The commanded speed; models without a speed loop push at a constant force and
%  have none, and then no line is drawn.
u_d = NaN;
if ~isempty(find_system(bdroot, 'SearchDepth',1, 'Name','speed loop'))
    u_d = evalin('base', 'u_d');
end

%% 1) 다리마다의 수치 / the numbers, leg by leg
fprintf('\n  %s  —  %g s, Delta = %g m, R_switch = %g m\n', ...
        get_param(bdroot, 'Name'), t(end), evalin('base','Delta'), evalin('base','R_switch'));
fprintf('    leg   from t [s]   |y_e| mean [m]   |y_e| max [m]   u mean [m/s]\n');
for k = 1:max(wp)
    j = wp == k;  if ~any(j), continue; end
    tk = t(j);
    fprintf('     %d      %7.1f        %9.3f       %9.3f      %8.3f\n', ...
            k, tk(1), mean(abs(y_e(j))), max(abs(y_e(j))), mean(u(j)));
end
sw = t([false; diff(wp) ~= 0]);
if isempty(sw), fprintf('    no waypoint switch in this run\n');
else, fprintf('    switched at %s s\n', strjoin(compose('%.1f', sw(:).'), ', ')); end

%% 2) 그림 / the figure
f = lab_fig(sprintf('%s  —  Run', get_param(bdroot,'Name')), 1100, 620);
subplot(1,2,1); hold on; grid on; axis equal;
plot(WP_E, WP_N, 'k--');
plot(WP_E, WP_N, 'kp', 'MarkerSize', 11, 'MarkerFaceColor', 'k');
plot(E, N, 'Color', [0 0.45 0.74], 'LineWidth', 1.3);
track_ships({[N E psi]}, [0 0.45 0.74], 'Marks', 12);
xlabel('east [m]');  ylabel('north [m]');
%  어느 법칙이 이 항적을 만들었는지 제목에 **파란 글자로** 적는다 (사용자 지시, 2026-10-13).
%  항적만으로는 atan2 와 LOS 를 구별하기 어렵고, 캔버스의 law Constant 는 그림에
%  남지 않는다. 값은 그 Constant 가 읽는 작업공간 변수에서 가져오므로, 스크립트가
%  무엇으로 돌렸든 **실제로 돈 것**이 적힌다.
%  Name the law in the title, in blue: the track alone does not tell atan2 from
%  LOS, and the canvas Constant does not reach the figure. The value is read from
%  the workspace variable that Constant reads, so it names what actually ran.
title({'the track, with the hull and its heading', ...
       ['\color[rgb]{0,0.45,0.74}\bf' law_name()]});

LBL = {'y_e  [m]', '\psi_d , \psi  [deg]', 'u_d , u  [m/s]', 'n_L , n_R  [rad/s]', 'waypoint k'};
for i = 1:5
    ax = subplot(5,2,2*i); hold on; grid on;
    switch i
        case 1
            plot(t, y_e, 'LineWidth', 1.2);
            yline(0, 'k:', 'HandleVisibility','off');
        case 2
            plot(t, psi_d, '--', 'LineWidth', 1.2, 'DisplayName', '\psi_d  commanded');
            plot(t, psi,         'LineWidth', 1.2, 'DisplayName', '\psi  actual');
            legend(ax, 'Location','best', 'AutoUpdate','off', 'FontSize', 7);
        case 3
            %  명령이 먼저, 실제가 위에 / the command first, the actual over it
            if isfinite(u_d)
                yline(u_d, '--', 'Color', [.45 .45 .45], 'LineWidth', 1.3, ...
                      'DisplayName', sprintf('u_d = %.2f m/s  commanded', u_d));
            end
            plot(t, u, 'LineWidth', 1.3, 'DisplayName', 'u  actual');
            legend(ax, 'Location','best', 'AutoUpdate','off', 'FontSize', 7);
        case 4
            plot(t, nL, 'LineWidth', 1.1, 'DisplayName', 'n_L  port');
            plot(t, nR, 'LineWidth', 1.1, 'DisplayName', 'n_R  starboard');
            legend(ax, 'Location','best', 'AutoUpdate','off', 'FontSize', 7);
        case 5
            stairs(t, wp, 'LineWidth', 1.4);
            ylim([0.5 max(wp)+0.5]);  yticks(1:max(wp));
    end
    ylabel(LBL{i});  if i == 5, xlabel('time [s]'); end
    %  전환 시각. 범례에 들어가지 않게 / the switching instants, kept out of the legend
    for s = sw(:).', xline(s, 'Color', [.6 .6 .6], 'HandleVisibility','off'); end
end
end

% ------------------------------------------------------------------------
function s = law_name()
%LAW_NAME  이 그림을 그린 법칙의 이름.
%          The name of the law that drew this figure.
%
%  **모델에게 먼저 묻는다** (2026-10-14). 법칙 하나만 든 모델에는 law 플래그가
%  없으므로 작업공간에서 알아낼 수 없다 — 그러나 유도 서브시스템 안에 그 법칙의
%  블록이 **하나** 서 있고, 블록 이름이 곧 법칙의 이름이다. 둘 이상 들어 있으면
%  고르는 것은 law 플래그이므로 그때는 작업공간을 읽는다.
%  The model is asked first: a model holding one law has no `law` flag, but it has
%  exactly one law block inside the guidance subsystem, and the block's name is the
%  law's name. Where more than one stands there, the flag chooses, so the workspace
%  is read instead.
%
%  둘 다 실패하면 빈 문자열이다 — 틀린 이름보다 없는 편이 낫다.
%  Failing both, the title gets no second line: no name is better than a wrong one.
NAMES = {'atan2  —  aiming at the next waypoint', ...
         'LOS  —  aiming \Delta ahead on the path', ...
         'ILOS  —  LOS with the nonlinear integral', ...
         'ILOS  —  LOS with a plain integral'};
BLOCKS = {'aim at the waypoint', 'LOS', 'ILOS', 'ILOS, plain integral'};
s = '';
try
    held = false(1, 4);
    for i = 1:4
        held(i) = ~isempty(find_system([bdroot '/guidance'], 'SearchDepth',1, ...
                           'LookUnderMasks','all', 'Name', BLOCKS{i}));
    end
    if sum(held) == 1, s = NAMES{find(held)}; return, end
catch
end
try
    v = evalin('base', 'law');
catch
    return
end
i = round(v);
if i >= 1 && i <= numel(NAMES), s = NAMES{i}; else, s = sprintf('law = %g', v); end
end
