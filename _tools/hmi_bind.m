function hmi_bind(dash, target, param)
%HMI_BIND  Bind a Dashboard block to one parameter of another block.
%
%   hmi_bind([m '/SPEED'], [m '/Drive command/n0'])            binds 'Value'
%   hmi_bind([m '/SPEED'], [m '/Drive command/gain'], 'Gain')
%
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
