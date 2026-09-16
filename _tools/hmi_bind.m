function hmi_bind(dash, target, param)
%HMI_BIND  Dashboard 블록을 다른 블록의 파라미터 하나에 묶는다.
%          Bind a Dashboard block to one parameter of another block.
%
%   hmi_bind([m '/SPEED'], [m '/Drive command/n0'])            'Value' 에 묶는다
%   hmi_bind([m '/SPEED'], [m '/Drive command/gain'], 'Gain')
%
%   한 번 묶어 두면 Dashboard 블록을 움직이는 것이 그 파라미터를 다시 쓰는 일이
%   된다. 실행 전에도, 실행 중에도 그렇다. 반대로 파라미터에 set_param 을 하면
%   Once bound, moving the Dashboard block rewrites that parameter, during a
%   run as well as before one, and a set_param on the parameter moves the
%   Dashboard block. The binding is saved with the model.
%
%   A Constant driven this way must survive compilation. With block reduction
%   on, a Constant whose only reader is a Terminator is optimised away and can
%   no longer be changed during a run — build interactive models with
%   set_param(m, 'BlockReduction', 'off').

if nargin < 3, param = 'Value'; end
b = Simulink.HMI.ParamSourceInfo;
b.BlockPath = Simulink.BlockPath(target);
b.ParamName = param;
set_param(dash, 'Binding', b);
end
