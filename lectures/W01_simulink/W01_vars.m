function V = W01_vars(model)
%W01_VARS  Every variable a Week 1 model needs, in one struct.
%
%   V = W01_vars              the open-loop manoeuvre model
%   V = W01_vars('current')   the current model of section E
%
%   Same split as Weeks 2 and 3: W01_0_setup fills the BASE workspace so a
%   student can open the model and press Run; this returns the same numbers as
%   a struct so that run_sim can vary one of them without leaving the
%   workspace in the state of the last run.
%
%   The two models want different simulation lengths and different track
%   windows - one draws an S over 130 m, the other a straight line pushed
%   sideways - so the argument selects which.

if nargin < 1 || isempty(model), model = 'openloop'; end

mss_path();

%  ---- the manoeuvre -------------------------------------------------------
%  straight -> port -> straight -> starboard -> straight. Both propellers run
%  ahead throughout; a turn is a small DIFFERENCE between them, because
%  N = y_p (T_left - T_right).
V.n0      = 60;                 % common shaft speed [rad/s]  -> about 1.03 m/s
V.dn      = 3.5;                % differential [rad/s]        -> about 2.3 deg/s
V.t_phase = [30 60 90 120];     % port 30..60 s, starboard 90..120 s

%  ---- vessel and environment ---------------------------------------------
V.mp     = 25;                  % payload mass [kg]
V.rp     = [0.05 0 -0.35]';     % payload position in {b} [m]
V.V_c    = 0;                   % current speed [m/s]
V.beta_c = 0;                   % current direction [rad from north]
V.x0     = zeros(12,1);

%  ---- simulation ----------------------------------------------------------
V.h       = 0.02;
V.T_final = 150;

%  ---- live view (off; the section scripts plot at the end) ---------------
V.animate = 0;  V.animate_every = 0.5;
V.track_Nmin = -10;  V.track_Nmax = 140;
V.track_Emin = -85;  V.track_Emax =  25;

%  ---- section E: one command, changing water -----------------------------
if strcmpi(model, 'current')
    V = rmfield(V, {'dn','t_phase'});      % nothing steers in that model
    V.V_c     = 0.5;
    V.T_final = 120;
    V.track_Nmin = -20;  V.track_Nmax = 160;
    V.track_Emin = -80;  V.track_Emax =  80;
end
end
