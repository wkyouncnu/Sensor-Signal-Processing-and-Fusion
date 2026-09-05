%% W04 · section G — the current, and the two laws that beat it
%
%      W04_0_setup
%      W04_G_current_and_integral
%
%  A current leaves plain LOS with a PERMANENT cross-track error, and §4-7
%  predicts its size: y_e = Delta tan(beta). ILOS removes it with an integral
%  state; ALOS removes it by estimating the crab angle itself.
%  Produces img/W04_result_current.png

clear V o y k i f pred meas VC B ROW
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W04_guidance.slx')), W04_1_build_guidance; end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V = W04_vars;
V.V_c    = 0.3;
V.beta_c = deg2rad(90);            % on the beam of the first leg

o = run_sim('W04_guidance', V);
y = W04_read(o);
k = y.t >= 0.8*y.t(end);           % the last fifth, clear of the final corner

%% ---- the four laws under one current -----------------------------------
fprintf('\n  W04 section G — a current of %.2f m/s at %.0f deg\n\n', ...
        V.V_c, rad2deg(V.beta_c));
fprintf('    %-8s %14s %14s %14s\n', 'law', 'settled y_e', 'crab [deg]', 'aux state');
fprintf('    %s\n', repmat('-', 1, 56));
for i = 1:4
    fprintf('    %-8s %14.3f %14.2f %14.3f\n', y.name{i}, ...
            mean(y.y_e(k,i)), mean(y.beta(k,i)), mean(y.aux(k,i)));
end

%% ---- the prediction of 4-7, checked ------------------------------------
pred = V.Delta * tand(mean(y.beta(k,2)));
meas = mean(y.y_e(k,2));
fprintf(['\n    THE LOS OFFSET IS PREDICTED, NOT MEASURED AFTERWARDS.\n' ...
         '\n      LOS steers the HEADING onto pi_p - atan(y_e/Delta), but the\n' ...
         '      vessel travels along the COURSE, which is beta off the heading.\n' ...
         '      In steady state the two must balance, so\n' ...
         '\n          atan(y_e / Delta) = beta   ==>   y_e = Delta tan(beta)\n' ...
         '\n      Delta tan(beta) = %.1f x tan(%.2f deg) = %.4f m\n' ...
         '      measured                                = %.4f m\n' ...
         '      difference                              = %.4f m\n'], ...
         V.Delta, mean(y.beta(k,2)), pred, meas, abs(pred-meas));

fprintf(['\n    ILOS AND ALOS BOTH REMOVE IT, AND NOT IN THE SAME WAY.\n' ...
         '\n      ILOS holds an integral state of %.2f. It is a number that\n' ...
         '      makes the arithmetic come out right and means nothing on its own.\n' ...
         '\n      ALOS holds b_hat = %.2f deg against a true crab angle of\n' ...
         '      %.2f deg - a difference of %.2f deg. The state IS the crab\n' ...
         '      angle, so it can be read off, logged, and compared with\n' ...
         '      atan2(v, u) as a check that the loop is doing what it claims.\n'], ...
         mean(y.aux(k,3)), rad2deg(mean(y.aux(k,4))), mean(y.beta(k,4)), ...
         abs(rad2deg(mean(y.aux(k,4))) - mean(y.beta(k,4))));

%% ---- and the same thing swept over current direction -------------------
VC = 0:0.1:0.5;
B  = zeros(numel(VC), 3);
fprintf('\n  sweeping the current speed, all at 90 deg\n\n');
fprintf('    %8s %14s %14s %14s %14s\n', ...
        'V_c', 'crab [deg]', 'LOS y_e', 'predicted', 'ILOS y_e');
fprintf('    %s\n', repmat('-', 1, 70));
for i = 1:numel(VC)
    yy = W04_read(run_sim('W04_guidance', V, 'V_c', VC(i)));
    kk = yy.t >= 0.8*yy.t(end);
    B(i,:) = [mean(yy.beta(kk,2)), mean(yy.y_e(kk,2)), mean(yy.y_e(kk,3))];
    fprintf('    %8.2f %14.2f %14.3f %14.3f %14.3f\n', VC(i), B(i,1), B(i,2), ...
            V.Delta*tand(B(i,1)), B(i,3));
end

%% ---- the figure --------------------------------------------------------
f = lab_fig('W04 G  current', 1250, 470);
COL = [0.85 0.33 0.10; 0 0.45 0.74; 0.47 0.67 0.19; 0.49 0.18 0.56];

subplot(1,3,1);
path_plot(V.WP, V.R_switch, y.trkN, y.trkE, y.trkPsi, COL, y.name, V);
legend('Location','southoutside','NumColumns',2);
title({'four laws, one current', sprintf('%.2f m/s at %.0f deg', V.V_c, rad2deg(V.beta_c))});

subplot(1,3,2); hold on;
yline(0,'k:','HandleVisibility','off');
for i = 1:4
    plot(y.t, y.y_e(:,i), 'Color', COL(i,:), 'DisplayName', y.name{i});
end
yline(pred, '--', 'Color',[0 0.45 0.74], 'HandleVisibility','off');
%  Placed high and left, where no curve runs: the label must not sit on the
%  line it describes.
text(20, 8.4, sprintf('\\Delta tan\\beta = %.2f m', pred), 'Color',[0 0.45 0.74]);
xlabel('time [s]'); ylabel('y_e  cross-track error [m]');
legend('Location','best');
title({'LOS settles on a PERMANENT offset', 'ILOS and ALOS do not'});

subplot(1,3,3); hold on;
plot(y.t, rad2deg(y.aux(:,4)), 'Color', COL(4,:), 'LineWidth',1.6, ...
     'DisplayName','ALOS  $\hat\beta$');
plot(y.t, y.beta(:,4), '--', 'Color',[0.4 0.4 0.4], 'LineWidth',1.2, ...
     'DisplayName','the true crab angle');
xlabel('time [s]'); ylabel('angle [deg]');
legend('Location','southeast','Interpreter','latex');
title({'the ALOS estimate converges on the crab angle', ...
       sprintf('%.2f deg against %.2f deg', ...
               rad2deg(mean(y.aux(k,4))), mean(y.beta(k,4)))});

sgtitle('W04 G — a current is a permanent offset, unless the law knows about it', ...
        'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W04_result_current.png'), 'Resolution', 150);
fprintf('\n  figure -> img/W04_result_current.png\n\n');


%% ---- the two states, filling up ----------------------------------------
%  강의 4-8-5a · 4-9-6a 의 표. 오토파일럿을 빼고 §4-8-6 의 오차동역학만 적분한다 —
%  "적분기가 어떻게 차오르는가" 를 초 단위로 보여주는 것이 목적이고, 전체 모델의
%  과도응답이 섞이면 그 그림이 흐려진다. 이상적인 그림임을 강의에도 적어 둔다.
fprintf('\n  the two states filling up (kinematics only, no autopilot lag)\n');

bta = deg2rad(15.74);          % section G 가 측정한 크랩각
Uk  = 1.31;                    % 대지속력
hk  = 0.01;  Tk = 0:hk:400;
mark = [0 10 25 50 100 200 400];

ye = 0; yi = 0;  ILO = zeros(numel(Tk),3);
for i = 1:numel(Tk)
    a        = ye + V.kappa*yi;
    ILO(i,:) = [ye, yi, rad2deg(atan(a/V.Delta))];
    ye       = ye + hk*Uk*sin(-atan(a/V.Delta) + bta);
    yi       = yi + hk*V.Delta*ILO(i,1)/(V.Delta^2 + a^2);
end

fprintf('\n  ILOS,  kappa = %g\n', V.kappa);
fprintf('    %8s %12s %12s %14s %14s\n', 't [s]','y_e [m]','y_int [s]','k*y_int [m]','bow tilt [deg]');
fprintf('    %s\n', repmat('-', 1, 66));
for t = mark
    i = round(t/hk)+1;
    fprintf('    %8g %12.3f %12.3f %14.3f %14.2f\n', ...
            t, ILO(i,1), ILO(i,2), V.kappa*ILO(i,2), ILO(i,3));
end
fprintf('    target: kappa*y_int -> Delta*tan(beta) = %.3f m, tilt -> %.2f deg\n', ...
        V.Delta*tan(bta), rad2deg(bta));

ye = 0; bh = 0;  ALO = zeros(numel(Tk),2);
for i = 1:numel(Tk)
    ALO(i,:) = [ye, rad2deg(bh)];
    ye       = ye + hk*Uk*sin(bta - bh - atan(ye/V.Delta));
    bh       = bh + hk*V.gamma*V.Delta*ALO(i,1)/sqrt(V.Delta^2 + ALO(i,1)^2);
end

fprintf('\n  ALOS,  gamma = %g\n', V.gamma);
fprintf('    %8s %12s %14s\n', 't [s]','y_e [m]','b_hat [deg]');
fprintf('    %s\n', repmat('-', 1, 40));
for t = mark
    i = round(t/hk)+1;
    fprintf('    %8g %12.3f %14.2f\n', t, ALO(i,1), ALO(i,2));
end
fprintf('    target: b_hat -> beta = %.2f deg\n', rad2deg(bta));

fprintf(['\n    BOTH STATES DO THE SAME JOB AND MEAN DIFFERENT THINGS.\n' ...
         '    ILOS ends at %.3f - seven and a half SECONDS, a number that\n' ...
         '    means nothing on its own. ALOS ends at %.2f DEGREES, which is\n' ...
         '    the angle the water is pushing the hull through. Both vessels\n' ...
         '    are on the path; only one of them can say why.\n'], ...
         ILO(end,2), ALO(end,2));
