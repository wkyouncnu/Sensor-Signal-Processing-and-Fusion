function f = W07_sl_alloc(tau_d, law, B, W_alloc, alpha_lim, Q_tau, eps_reg, ...
                          T_pos, T_neg, n_chord)
%W07_SL_ALLOC  Simulink 의 `law` 상수 하나를 `W07_alloc` 의 법칙 이름으로 바꾼다.
%              Turn the Simulink constant `law` into one of W07_alloc's names.
%
%   f = W07_SL_ALLOC(tau_d, law, B, W_alloc, alpha_lim, Q_tau, eps_reg, ...
%                    T_pos, T_neg, n_chord)
%
%   law   법칙 / the law                     강의 절 / lecture section
%   ---------------------------------------------------------------------
%    1    'pinv'       최소노름              7-8
%                      minimum norm
%    2    'wpinv'      가중 최소노름         7-9
%                      weighted minimum norm
%    3    'clip'       가중 + 각 한계로 접기 7-10
%                      weighted, then folded onto the angle limit
%    4    'wls16cap'   각 한계와 추력 한계를 7-10 · 7-12
%                      둘 다 제약으로 푼다
%                      both limits as constraints
%
%   왜 함수가 하나 더 있는가 / why this wrapper exists
%       배분 법칙 자체는 `W07_alloc` 하나에 들어 있고, 그것은 이름(문자열)으로
%       법칙을 고른다. Simulink 의 Constant 는 숫자만 담으므로 둘 사이에 번호를
%       이름으로 바꾸는 줄이 필요하다. 그 줄을 MATLAB Function 블록 안에 두면
%       학생이 블록을 열었을 때 문자열 셀 배열이 먼저 보이고, 블록의 일인
%       "배분을 부른다" 가 가려진다.
%       The allocation laws live in W07_alloc, which selects one by name. A
%       Simulink Constant carries numbers only, so one line has to map the
%       number onto the name. Keeping that line out of the block leaves the
%       block saying what it does: it calls the allocator.
%
%       같은 이유로 **이 함수는 코드생성 대상이 아니다.** 블록이
%       `coder.extrinsic` 으로 부르고, 돌아오는 f 의 크기를 블록이 미리 못박는다.
%       This function is not compiled: the block calls it extrinsically and
%       declares the width of f in advance.
%
%   See also W07_ALLOC, W07_2_BUILD_ALLOC, W07_CA.

names = {'pinv', 'wpinv', 'clip', 'wls16cap'};
k     = max(1, min(numel(names), round(law)));

P = struct('W',         W_alloc, ...
           'alpha_max', alpha_lim, ...
           'Q',         Q_tau, ...
           'eps_reg',   eps_reg, ...
           'T_pos',     T_pos, ...
           'T_neg',     T_neg, ...
           'n_chord',   n_chord);

f = W07_alloc(B, tau_d(:), names{k}, P);
f = f(:);
end
