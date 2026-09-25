%% W08 · 실험 8-4 — 위치 루프는 얼마나 빨라도 되는가 / Experiment 8-4 — how fast the position loop may be
%
%  이 절이 묻는 것 / the question
%      위치 루프의 게인을 올리면 자리를 더 잘 지키는가?
%      Does a larger position gain hold the station better?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 배를 자리에서 동쪽으로 5 m 밀어 놓고 (선수각을 돌려야만 갚을 수 있는 방향)
%         Kp_x 를 네 값으로 바꿔 가며 돌린다.
%      ② 1 m 안으로 돌아온 시각, 마지막 50 s 의 오차, 선수각의 표준편차,
%         그리고 전체 회전량을 찍는다.
%      ③ 네 항적을 겹쳐 그린다.
%      ① Starts the vessel 5 m east of the station — the direction that can be
%         answered only by turning — and sweeps Kp_x over four values.
%      ② Prints the time to return within 1 m, the error over the last 50 s, the
%         standard deviation of the heading, and how far the vessel turned in all.
%      ③ Plots the four tracks.
%
%  출력에서 볼 것 / what to look for in the output
%      - Kp_x = 30 이 가장 낫다: 30 s 에 돌아오고 0.19 m 에 머문다.
%      - Kp_x = 120 은 **돌아오지 못한다**. 위치 루프가 선수각 루프보다 빨라져,
%        뱃머리가 따라오기 전에 명령이 또 바뀐다 — 2주차 §2-13 의 캐스케이드 규칙.
%      - Kp_x = 30 is the best: back in 30 s and holding 0.19 m.
%      - Kp_x = 120 never returns: the position loop now asks the bow to turn
%        faster than the heading loop can, and the vessel chases its own tail.
%        That is the cascade rule of Week 2 §2-13, measured.
%
%  만드는 것 / produces: img/W08_result_gains.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 옆으로 5 m 밀어 놓고 게인을 바꾼다 / pushed 5 m sideways, four gains
x0 = zeros(12,1);  x0(8) = 5;
KP = [10 30 60 120];  RUN = cell(1, numel(KP));
fprintf('\n  W08 Experiment 8-4  pushed 5 m off station, sideways\n');
fprintf('    Kp_x   back within 1 m [s]   |e| mean last 50 s   psi std [deg]   total turn [deg]\n');
for i = 1:numel(KP)
    R = W08_read('W08_E_cascade', 'Kp_x', KP(i), 'x0', x0, 'T_final', 200);
    RUN{i} = R;  j = R.t > 150;
    k = find(R.e < 1, 1);  t1 = inf;  if ~isempty(k), t1 = R.t(k); end
    turn = sum(abs(diff(unwrap(deg2rad(R.psi)))))*180/pi;
    fprintf('    %4g %18.1f %18.3f m %14.2f %16.0f\n', KP(i), t1, mean(R.e(j)), std(R.psi(j)), turn);
end

%% 2) 네 항적 / the four tracks
f = lab_fig('W08 Exp 8-4  how fast the position loop may be', 1000, 500);
hold on; grid on; axis equal;
for i = 1:numel(KP)
    plot(RUN{i}.E, RUN{i}.N, 'LineWidth', 1.6, 'DisplayName', sprintf('K_{p,x} = %g', KP(i)));
end
plot(0, 0, 'kp', 'MarkerSize', 12, 'MarkerFaceColor', 'k', 'HandleVisibility', 'off');
xlabel('east [m]'); ylabel('north [m]'); legend('Location','northwest');
title('the same push, four position gains: the fastest loop is the one that never arrives');
exportgraphics(f, fullfile(here, 'img', 'W08_result_gains.png'), 'Resolution', 150);
