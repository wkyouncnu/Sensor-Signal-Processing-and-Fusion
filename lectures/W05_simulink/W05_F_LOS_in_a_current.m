%% W05 · 실험 5-5a — 조류 속의 LOS / Experiment 5-5a — LOS in a current
%
%  이 절이 묻는 것 / the question
%      옆으로 미는 조류가 있으면 LOS 는 경로에 붙어 있는가?
%      Does LOS hold the line when a current pushes the vessel sideways?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W05_F_LOS 를 동쪽 조류 0.1, 0.2, 0.3, 0.4 m/s 로 한 번씩 돌린다.
%         경로는 북쪽으로 곧은 400 m 한 다리다.
%      ② 남는 횡방향 오차와 그때 유지한 선수각을 찍고, 옆에 Delta*tan(선수각) 을 적는다.
%      ① Runs W05_F_LOS in an eastward current of 0.1, 0.2, 0.3 and 0.4 m/s,
%         on one straight 400 m leg running north.
%      ② Prints the offset left and the heading held, next to Delta*tan(heading).
%
%  출력에서 볼 것 / what to look for in the output
%      - 배는 경로와 나란히, 그러나 옆으로 비켜서 달린다. 오차가 0 이 되지 않는다.
%      - 마지막 두 열이 mm 까지 같다: 남는 오차 = Delta * tan(유지한 선수각).
%      - 조류가 셀수록 더 비스듬히 서고, 오차도 그만큼 커진다.
%      - The vessel settles parallel to the path but beside it; the error does not vanish.
%      - The last two columns agree to the millimetre: the offset is Delta tan(heading).
%      - The stronger the current, the further the bow turns into it and the larger the offset.
%
%  그림은 실험 5-5b 가 그린다 / the figure belongs to Experiment 5-5b

%% 0) 경로와 시나리오 / paths and the scenario
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
L = {'WP_N', [0 400]', 'WP_E', [0 0]', 'T_final', 400};   % 곧은 경로, 400 s / a straight leg, 400 s

%% 1) 조류 네 가지 / four currents
fprintf('\n  W05 Experiment 5-5a  LOS in a current flowing east  (Delta = 5 m)\n');
fprintf('    V_c [m/s]   error left [m]   heading held [deg]   Delta*tan(heading) [m]\n');
for Vc = [0.1 0.2 0.3 0.4]
    R = W05_read('W05_F_LOS', L{:}, 'V_c', Vc);
    %  마지막 값 = 정상상태 / the last sample = the steady state
    fprintf('    %-9g   %14.3f   %18.1f   %22.3f\n', Vc, R.y_e(end), R.psi(end), 5*tand(abs(R.psi(end))));
end
