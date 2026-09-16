%% A1 · 절 D — 도달 가능 제어 집합
%  A1 · Section D — the attainable control set
%
%  실행 순서 / order of execution
%      A1_0_setup
%      A1_D_attainable_set
%
%  무엇을 그리는가 / what is being drawn
%      선체에 요구할 수 있는 (X, N) 전체이다. 그것은 축 회전수가 만드는 사각형
%      영역을 추력곡선으로 옮기고, 다시 B 로 옮긴 상(image)이다.
%
%      Every (X, N) the hull can be asked for. It is the image of the box of
%      shaft speeds, mapped first through the thrust curve and then through B.
%
%          n 의 상자 --> T = k n|n| --> tau = B T
%
%      출발한 것은 사각형인데 도착한 것은 사각형이 아니다. 추력곡선이 비선형
%      이고 전진과 후진의 계수가 다르기 때문이다. 이 모양을 알아야 어떤 요구가
%      잘려 나갈지 미리 말할 수 있고, 그것이 포화와 안티와인드업으로 이어진다.
%
%      What sets out as a square does not arrive as one, because the thrust
%      curve is nonlinear and the ahead and astern coefficients differ.
%      Knowing the shape is what makes it possible to say in advance which
%      demands will be clipped, which is where saturation and anti-windup
%      begin.
%
%  만드는 것 / what it produces
%      표와 img/A1_result_set.png
%      Tables and img/A1_result_set.png

clear cfg y NG ng N1 N2 T1 T2 Xg Ng kk area_XN nn f
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

cfg = otter_config('base');
y   = cfg.y_pont;

%% ---- sweep the shaft-speed box ----------------------------------------
NG = 121;
ng = linspace(cfg.n_min, cfg.n_max, NG);
[N1, N2] = meshgrid(ng, ng);
T1 = prop_thrust(N1, cfg);
T2 = prop_thrust(N2, cfg);
Xg = T1 + T2;                    % row 1 of B
Ng = y*(T1 - T2);                % row 3 of B.  Row 2 is not computed: it is 0
kk = convhull(Xg(:), Ng(:));
area_XN = polyarea(Xg(kk), Ng(kk));

fprintf('\n  A1 section D — the attainable control set in (X, N)\n\n');
fprintf('    %-30s %14s\n', 'quantity', 'value');
fprintf('    %s\n', repmat('-', 1, 48));
fprintf('    %-30s %14.2f\n', 'max X   [N]',            max(Xg(:)));
fprintf('    %-30s %14.2f\n', 'min X   [N]',            min(Xg(:)));
fprintf('    %-30s %14.2f\n', 'max |N| [N.m]',          max(abs(Ng(:))));
fprintf('    %-30s %14.4f\n', 'ahead / astern ratio',   abs(max(Xg(:))/min(Xg(:))));
fprintf('    %-30s %14.1f\n', 'convex hull area [N^2 m]', area_XN);
fprintf('    %-30s %14.1e\n', 'max |Y| over the whole set', 0);

fprintf(['\n    The set is a plane REGION, never a volume, because Y is not\n' ...
         '    reachable at all. It is also asymmetric fore and aft in the ratio\n' ...
         '    k_pos/k_neg = %.4f, which is a property of the propeller and not\n' ...
         '    of the controller that will later have to live inside this set.\n'], ...
         cfg.k_pos/cfg.k_neg);

%% ---- the figure --------------------------------------------------------
f = lab_fig('A1 D  attainable set', 1150, 430);

subplot(1,3,1); hold on;
nn = linspace(cfg.n_min, cfg.n_max, 400);
plot(nn, prop_thrust(nn, cfg), 'Color',[0 0.45 0.74], 'LineWidth',1.4);
xline(0,'k:'); yline(0,'k:');
xlabel('n  shaft speed [rad/s]'); ylabel('T  thrust, one propeller [N]');
title({'the actuator', sprintf('k_{pos}/k_{neg} = %.4f', cfg.k_pos/cfg.k_neg)});

subplot(1,3,2); hold on;
fill(Xg(kk), Ng(kk), [0.85 0.90 0.96], 'EdgeColor',[0 0.45 0.74], 'LineWidth',1.4);
xline(0,'k:'); yline(0,'k:');
xlabel('X  surge force [N]'); ylabel('N  yaw moment [N\cdotm]');
title({'the attainable control set', sprintf('area %.0f N^2m', area_XN)});

%  Drawn as a LINE and not as a thin filled box: the set has no width at all
%  in Y, and a box two newtons wide would contradict the title.
subplot(1,3,3); hold on;
plot([0 0], [min(Ng(:)) max(Ng(:))], 'Color',[0.75 0.2 0.2], 'LineWidth',3);
plot(0, 0, 'o', 'Color',[0.75 0.2 0.2], 'MarkerFaceColor','w');
xlim([-40 40]); ylim([min(Ng(:))*1.15 max(Ng(:))*1.15]);
xline(0,'k:'); yline(0,'k:');
text(6, max(Ng(:))*0.85, 'width in Y = 0, exactly', 'Color',[0.75 0.2 0.2]);
xlabel('Y  sway force [N]'); ylabel('N  yaw moment [N\cdotm]');
title({'the same set seen along Y', 'a segment, not a region — rank 2'});

sgtitle('A1 D — what this hull can and cannot be asked to do', 'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','A1_result_set.png'), 'Resolution', 150);
fprintf('\n  figure -> img/A1_result_set.png\n\n');
