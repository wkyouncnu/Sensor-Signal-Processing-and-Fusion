%W07_PLOT_CA  배분 사슬의 결과: **요구한 tau 와 실제로 나온 tau.**
%             The result of the allocation chain: the demand against what the
%             hull actually received.
%
%   `W07_alloc_chain` 의 StopFcn 이 부른다. Run 을 누르면 그림이 뜬다.
%   Called from the StopFcn of W07_alloc_chain, so Run alone draws the figure.
%
%   로그 / the log
%       W07ca_log 는 열이 열이다 / ten columns
%           1      t          [s]
%           2:4    tau_d      요구한 [X Y N]      / the demand
%           5:7    tau_act    실제로 나온 [X Y N] / what the hull received
%           8:10   u v r      선체 속도            / the hull velocities
%
%   See also W07_2_BUILD_ALLOC, W07_SAVE_FIG, W07_CA.

if evalin('base', 'exist(''W07ca_log'', ''var'')') ~= 1
    return
end
L = evalin('base', 'W07ca_log');

% Mux 가 10x1 **행렬** 신호를 내보내므로 To Workspace 의 Array 형식은 시간을
% 세 번째 차원에 둔다 — 10 x 1 x N. 열이 열인 행렬로 돌려 놓는다.
% The Mux output is a 10-by-1 matrix signal, so To Workspace puts time on the
% third dimension (10 x 1 x N). Put it back as N rows of ten columns.
if ndims(L) == 3
    L = permute(L, [3 1 2]);
end
if isempty(L) || size(L, 2) < 10
    return
end

t    = L(:,1);
tau_d = L(:,2:4);
tau_a = L(:,5:7);

here = fileparts(mfilename('fullpath'));
if ~isfolder(fullfile(here, 'img')), mkdir(fullfile(here, 'img')); end

law_name = {'minimum norm', 'weighted minimum norm', ...
            'weighted, folded onto the servo limit', ...
            'servo limit and thrust cap as constraints'};
k = 1;
if evalin('base', 'exist(''law'', ''var'')') == 1
    k = max(1, min(4, round(evalin('base', 'law'))));
end

name = {'X  (N)', 'Y  (N)', 'N  (N m)'};
f = figure('Name', 'W07  allocation chain', 'Color', 'w', ...
           'Position', [100 100 760 620]);

for i = 1:3
    subplot(3,1,i);
    plot(t, tau_d(:,i), 'k--', 'LineWidth', 1.6); hold on;
    plot(t, tau_a(:,i), 'b-',  'LineWidth', 1.2);
    grid on;
    ylabel(name{i});
    if i == 1
        title(sprintf('Demanded and delivered force   --   law %d, %s', ...
                      k, law_name{k}));
        legend('demanded', 'delivered', 'Location', 'best');
    end
    if i == 3, xlabel('time  (s)'); end
end

% 가장 큰 차이가 어디서 났는지 숫자로 / the largest gap, as a number
e = tau_a - tau_d;
fprintf('\n  law %d   %s\n', k, law_name{k});
fprintf('  ------------------------------------------------------------\n');
fprintf('  component      demanded      delivered        max error\n');
for i = 1:3
    [~, j] = max(abs(e(:,i)));
    fprintf('  %-10s  %9.3f     %9.3f     %9.3f  at t = %5.2f s\n', ...
            name{i}, tau_d(j,i), tau_a(j,i), e(j,i), t(j));
end
fprintf('\n');

% 법칙마다 그림을 따로 남긴다 — 넷을 나란히 두고 보는 것이 이 모델의 목적이다
% one figure per law, so the four can be laid side by side
W07_save_fig(f, fullfile(here, 'img', sprintf('W07_alloc_chain_law%d.png', k)));
