function [w, a, phi, k_w] = wave_train(Hs, T0, gamma, N, sigma_deg)
%WAVE_TRAIN  JONSWAP 스펙트럼을 되풀이 가능한 파랑 하나로 만든다.
%            One repeatable realisation of a JONSWAP sea.
%
%   [w, a, phi, k_w] = wave_train(Hs, T0, gamma, N, sigma_deg)
%
%     Hs         유의파고 / significant wave height          [m]
%     T0         첨두주기 / peak period                      [s]
%     gamma      JONSWAP 첨두 계수 / peak enhancement        [-]
%     N          성분 수 / number of components
%     sigma_deg  1차 파랑이 만드는 선수각의 표준편차 / the standard deviation of
%                the wave-induced heading                    [deg]
%
%     w, a, phi  성분의 주파수 [rad/s], 진폭 [m], 위상 [rad]
%     k_w        진폭을 선수각으로 바꾸는 배율 / the scale from wave amplitude to heading
%
%   왜 난수가 아닌가 / why this is not random
%       randn 으로 파랑을 만들면 실행할 때마다 수가 달라지고, 강의에 실은 표를
%       학생이 재현할 수 없다. 스펙트럼에서 진폭을 뽑고 위상을 **정해 두면**
%       같은 스펙트럼의 한 실현을 언제나 똑같이 다시 만들 수 있다. MSS 의
%       waveresponse345 도 같은 방식이다.
%       A sea built from randn gives different numbers on every run, and a table
%       in the notes could not be reproduced. Taking the amplitudes from the
%       spectrum and **fixing** the phases gives one realisation of that spectrum
%       which is always the same. MSS's waveresponse345 does likewise.
%
%   위상은 황금비 수열이다 / the phases are a golden-ratio sequence
%       phi_i = 2 pi frac(i * 0.6180339887). 고르게 퍼지고, 규칙이 짧아 외울 수 있다.
%       Evenly spread, and short enough to state in one line.
%
%   진폭은 스펙트럼에서 / the amplitudes come from the spectrum
%       a_i = sqrt(2 S(w_i) dw),  그 다음 4 sqrt(sum(a^2)/2) = Hs 가 되도록 맞춘다.
%       맞추는 이유는 유한한 격자가 꼬리의 에너지를 놓치기 때문이다 (약 18 %).
%       then scaled so that 4 sqrt(sum(a^2)/2) = Hs exactly, because a finite
%       grid misses the energy in the tails (about 18 % here).

w0  = 2*pi/T0;
w   = linspace(0.35*w0, 3.5*w0, N)';
dw  = w(2) - w(1);
S   = wavespec(7, [Hs w0 gamma], w, 0);        % JONSWAP (MSS)
a   = sqrt(2*S*dw);
a   = a * Hs / (4*sqrt(sum(a.^2)/2));          % 꼬리에서 잃은 몫을 되돌린다 / the tails, put back
phi = 2*pi*mod((1:N)'*0.6180339887, 1);

%  선수각의 표준편차를 맞추는 배율. 위상이 고르면 std(sum a_i sin) = sqrt(sum a^2/2).
%  The scale that gives the wanted standard deviation: for well-spread phases,
%  std(sum a_i sin(.)) = sqrt(sum(a^2)/2).
k_w = sigma_deg / sqrt(sum(a.^2)/2);
end
