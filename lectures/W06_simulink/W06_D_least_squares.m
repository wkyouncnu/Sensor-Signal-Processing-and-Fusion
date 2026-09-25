%% W06 · 실험 6-3 — 요구가 셋일 때 / Experiment 6-3 — when three things are demanded
%
%  이 절이 묻는 것 / the question
%      낼 수 없는 힘을 요구하면 배분기는 무엇을 하는가?
%      What does an allocator do with a demand the hull cannot produce?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W06_D_pseudo 를 한 번 돌린다. 시간표에 횡력 Y = 30 N 이 들어 있다.
%      ② 구간마다 요구 셋과 전달된 셋을 나란히 찍는다.
%      ③ B 와 그 의사역행렬을 MATLAB 으로 직접 계산해, 블록의 두 줄과 같은지 본다.
%      ④ 요구(점선)와 전달(실선)을 세 성분 모두 그린다.
%      ① Runs W06_D_pseudo once; the timetable asks for a sway force of 30 N.
%      ② Prints the three demanded and the three delivered components, leg by leg.
%      ③ Builds B and pinv(B) in MATLAB and checks them against the block's two lines.
%      ④ Plots all three components, demanded and delivered.
%
%  출력에서 볼 것 / what to look for in the output
%      - Y 는 언제나 0 으로 전달된다. X 와 N 은 그대로다 — 버려진 것은 횡력뿐이다.
%      - pinv(B) 의 가운데 열이 0 이다. 최소자승해는 낼 수 없는 성분을 **그냥 버린다.**
%      - The delivered Y is always zero while X and N are untouched.
%      - The middle column of pinv(B) is zero: least squares simply drops it.
%
%  만드는 것 / produces: img/W06_result_pseudo.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 한 번 돌리고 구간마다 읽는다 / one run, read leg by leg
R = W06_read('W06_D_pseudo');
at = @(f, t) interp1(R.t, R.(f), t);
fprintf('\n  W06 Experiment 6-3  three demands, two propellers\n');
fprintf('    t [s]   demanded X      Y      N     delivered X      Y      N    dropped\n');
for t = [10 20 30 40]
    d = [at('Xd',t) at('Yd',t) at('Nd',t)];  a = [at('Xa',t) at('Ya',t) at('Na',t)];
    fprintf('    %5.0f  %10.1f %6.1f %6.2f  %12.1f %6.1f %6.2f %10.1f\n', t, d, a, norm(d - a));
end

%% 2) B 와 의사역행렬을 직접 / B and its pseudo-inverse, computed here
B = otter_B(otter_config('base'));  Bp = pinv(B);
fprintf('\n    B = [%4.2f %5.2f ; %4.2f %5.2f ; %5.3f %6.3f]   rank %d\n', B', rank(B));
fprintf('    pinv(B) row 1 = [%6.3f %5.3f %7.4f]   the block writes T1 = X/2 + N/(2 y_pont)\n', Bp(1,:));
fprintf('    pinv(B) row 2 = [%6.3f %5.3f %7.4f]   the block writes T2 = X/2 - N/(2 y_pont)\n', Bp(2,:));

%% 3) 세 성분을 모두 그린다 / all three components
f = lab_fig('W06 Exp 6-3  least squares', 1000, 620);
L = {'X  [N]', 'Y  [N]', 'N  [N m]'};  D = {'Xd','Yd','Nd'};  A = {'Xa','Ya','Na'};
for i = 1:3
    subplot(3,1,i); hold on; grid on;
    plot(R.t, R.(D{i}), 'k--', 'LineWidth', 1.6, 'DisplayName', 'demanded');
    plot(R.t, R.(A{i}), 'LineWidth', 2, 'DisplayName', 'delivered');
    ylabel(L{i}); if i == 1, legend('Location','northwest'); title('the sway row of B is zero, so the sway demand is dropped'); end
end
xlabel('time [s]');
exportgraphics(f, fullfile(here, 'img', 'W06_result_pseudo.png'), 'Resolution', 150);
